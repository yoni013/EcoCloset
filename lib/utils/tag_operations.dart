import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/tag_service.dart';
import '../models/tag_model.dart';

class TagOperations {
  static final TagService _tagService = TagService();

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
} 