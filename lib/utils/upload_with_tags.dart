import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/tag_service.dart';
import '../services/content_moderation_service.dart';
import '../models/tag_model.dart';

class UploadWithTags {
  static final TagService _tagService = TagService();
  static final ContentModerationService _moderationService = ContentModerationService();
  
  /// Enhanced upload function that includes automatic tagging
  static Future<String?> uploadItemWithTags({
    required List<XFile> images,
    required Map<String, dynamic> formData,
    required BuildContext context,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in.');
      }

      // Step 1: Content moderation
      debugPrint('🛡️ Moderating content...');
      final description = formData['Description'] ?? '';
      final itemName = formData['item_name'] ?? '';
      final category = formData['Type'] ?? '';
      
      final moderationResult = await _moderationService.aiContentModeration(
        description: description,
        itemName: itemName,
        category: category,
      );

      if (!moderationResult.isApproved) {
        throw Exception('Content moderation failed: ${moderationResult.reason}');
      }
      debugPrint('✅ Content approved for upload');

      // Step 2: Upload images to Firebase Storage
      debugPrint('📸 Uploading images...');
      List<String> imagePaths = [];
      for (var image in images) {
        final String imageName = 'items/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final ref = FirebaseStorage.instance.ref().child(imageName);
        
        // Use bytes for cross-platform compatibility (works on web and mobile)
        final bytes = await image.readAsBytes();
        await ref.putData(bytes).timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            throw Exception('Image upload timed out. Please check your internet connection.');
          },
        );
        
        final url = await ref.getDownloadURL().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Failed to get download URL. Please try again.');
          },
        );
        imagePaths.add(url);
      }

      // Step 3: Create the item document in Firestore
      debugPrint('💾 Creating item document...');
      final itemRef = await FirebaseFirestore.instance.collection('Items').add({
        ...formData,
        'images': imagePaths,
        'seller_id': userId,
        'status': 'Available',
        'createdAt': FieldValue.serverTimestamp(),
        'moderation_status': 'approved', // Mark as approved by moderation
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Failed to save item data. Please try again.');
        },
      );

      final itemId = itemRef.id;

      // Step 4: Generate tags using Gemini AI
      // debugPrint('🏷️ Generating tags with AI...');
      // try {
      //   await _tagService.initialize();
        
      //   final generatedTags = await _tagService.generateTagsWithGemini(
      //     imageUrls: imagePaths,
      //     itemMetadata: formData,
      //   );

      //   if (generatedTags.isNotEmpty) {
      //     debugPrint('🎯 Generated ${generatedTags.length} tags: ${generatedTags.join(", ")}');
          
      //     // Step 5: Add tags to the item
      //     await _tagService.addTagsToItem(
      //       itemId: itemId,
      //       tagNames: generatedTags,
      //     );
          
      //     debugPrint('✅ Tags added successfully!');
      //   } else {
      //     debugPrint('⚠️ No tags were generated, item uploaded without tags');
      //   }
      // } catch (tagError) {
      //   debugPrint('⚠️ Tag generation failed: $tagError');
      //   debugPrint('📦 Item uploaded successfully without tags');
      // }

      return itemId;

    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      rethrow;
    }
  }

  /// Add tags to an existing item
  static Future<void> addTagsToExistingItem({
    required String itemId,
    required List<String> imageUrls,
    required Map<String, dynamic> itemMetadata,
  }) async {
    try {
      debugPrint('🏷️ Adding tags to existing item: $itemId');
      
      await _tagService.initialize();
      
      final generatedTags = await _tagService.generateTagsWithGemini(
        imageUrls: imageUrls,
        itemMetadata: itemMetadata,
      );

      if (generatedTags.isNotEmpty) {
        await _tagService.addTagsToItem(
          itemId: itemId,
          tagNames: generatedTags,
        );
        
        debugPrint('✅ Tags added to existing item: ${generatedTags.join(", ")}');
      }
    } catch (e) {
      debugPrint('❌ Failed to add tags to existing item: $e');
      rethrow;
    }
  }

  /// Record user interaction for analytics
  static Future<void> recordItemInteraction({
    required String itemId,
    required String interactionType, // 'view', 'like', 'purchase', etc.
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get item tags
      final itemDoc = await FirebaseFirestore.instance
          .collection('Items')
          .doc(itemId)
          .get();
      
      if (itemDoc.exists) {
        final itemData = itemDoc.data()!;
        final tagIds = List<String>.from(itemData['tags'] ?? []);
        
        if (tagIds.isNotEmpty) {
          await _tagService.recordUserTagInteraction(
            itemId: itemId,
            tagIds: tagIds,
            interactionType: _mapInteractionType(interactionType),
            metadata: metadata,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to record interaction: $e');
    }
  }

  static InteractionType _mapInteractionType(String type) {
    switch (type.toLowerCase()) {
      case 'view':
        return InteractionType.view;
      case 'like':
        return InteractionType.like;
      case 'purchase':
        return InteractionType.purchase;
      case 'search':
        return InteractionType.search;
      case 'filter':
        return InteractionType.filter;
      default:
        return InteractionType.view;
    }
  }

  /// Get recommended items for a user
  static Future<List<Map<String, dynamic>>> getRecommendedItems({
    required String userId,
    int limit = 20,
  }) async {
    try {
      await _tagService.initialize();
      return await _tagService.getRecommendedItems(
        userId: userId,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Failed to get recommended items: $e');
      return [];
    }
  }

  /// Search items by tags
  static Future<List<Map<String, dynamic>>> searchByTags({
    required String searchQuery,
    int limit = 20,
  }) async {
    try {
      await _tagService.initialize();
      return await _tagService.searchItemsByTags(
        searchQuery: searchQuery,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Failed to search by tags: $e');
      return [];
    }
  }

  /// Get items by specific tags (for filtering)
  static Future<List<Map<String, dynamic>>> getItemsByTags({
    required List<String> tagNames,
    int limit = 20,
  }) async {
    try {
      await _tagService.initialize();
      return await _tagService.getItemsByTags(
        tagNames: tagNames,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Failed to get items by tags: $e');
      return [];
    }
  }
} 