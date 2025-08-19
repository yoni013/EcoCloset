import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/tag_model.dart';

/// Custom exception for AI service errors with retry information
class AIServiceException implements Exception {
  final String message;
  final bool isRetryable;
  final String? details;
  
  const AIServiceException(
    this.message, {
    this.isRetryable = true,
    this.details,
  });
  
  @override
  String toString() => 'AIServiceException: $message${details != null ? ' ($details)' : ''}';
}

class TagService {
  static final TagService _instance = TagService._internal();
  factory TagService() => _instance;
  TagService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for master tags
  Map<String, List<String>> _masterTags = {};
  List<Tag> _allTags = [];
  
  /// Initialize the tag service and load master tags
  Future<void> initialize() async {
    await _loadMasterTags();
    await _loadActiveTags();
  }

  /// Load master tags from assets
  Future<void> _loadMasterTags() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/master_tags.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      
      _masterTags = jsonData.map((key, value) => MapEntry(
        key,
        List<String>.from(value),
      ));
    } catch (e) {
      debugPrint('Error loading master tags: $e');
    }
  }

  /// Load active tags from Firestore
  Future<void> _loadActiveTags() async {
    try {
      final querySnapshot = await _firestore
          .collection('Tags')
          .where('isActive', isEqualTo: true)
          .get();
      
      _allTags = querySnapshot.docs
          .map((doc) => Tag.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading active tags: $e');
    }
  }

  /// Get all master tags flattened into a single list
  List<String> get allMasterTags {
    return _masterTags.values
        .expand((tagList) => tagList)
        .toSet()
        .toList();
  }

  /// Get master tags by category
  List<String> getMasterTagsByCategory(String category) {
    return _masterTags[category] ?? [];
  }

  /// Initialize tags in Firestore from master list (run once)
  Future<void> initializeTagsInFirestore() async {
    try {
      final batch = _firestore.batch();
      
      for (final category in _masterTags.keys) {
        for (final tagName in _masterTags[category]!) {
          // Check if tag already exists
          final existingTag = await _firestore
              .collection('Tags')
              .where('name', isEqualTo: tagName)
              .limit(1)
              .get();
          
          if (existingTag.docs.isEmpty) {
            final docRef = _firestore.collection('Tags').doc();
            final tag = Tag(
              id: docRef.id,
              name: tagName,
              category: category,
              createdAt: DateTime.now(),
              isActive: true,
              usageCount: 0,
            );
            
            batch.set(docRef, tag.toMap());
          }
        }
      }
      
      await batch.commit();
      debugPrint('Tags initialized in Firestore successfully');
    } catch (e) {
      debugPrint('Error initializing tags in Firestore: $e');
      rethrow;
    }
  }

  /// Download image from URL and return bytes
  Future<Uint8List?> _downloadImageBytes(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading image from $imageUrl: $e');
      return null;
    }
  }

  /// Analyze item images and metadata to generate relevant tags using Gemini
  Future<List<String>> generateTagsWithGemini({
    required List<String> imageUrls,
    required Map<String, dynamic> itemMetadata,
  }) async {
    const int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        debugPrint('🤖 AI Tagging attempt ${retryCount + 1}/$maxRetries');
        
        // Validate inputs
        if (imageUrls.isEmpty) {
          throw Exception('No images provided for AI analysis');
        }
        
        // Prepare the prompt for Gemini
        final prompt = _buildGeminiPrompt(itemMetadata);
        
        // Create content parts with timeout handling
        List<Content> contentParts = [];
        
        // Add images by downloading them with timeout
        for (final imageUrl in imageUrls) {
          try {
            final imageBytes = await _downloadImageBytes(imageUrl)
                .timeout(const Duration(seconds: 10));
            if (imageBytes != null) {
              contentParts.add(Content.inlineData('image/jpeg', imageBytes));
            }
          } catch (imageError) {
            debugPrint('⚠️ Failed to download image $imageUrl: $imageError');
            // Continue with other images instead of failing completely
          }
        }
        
        if (contentParts.isEmpty) {
          throw Exception('Failed to download any images for analysis');
        }
        
        // Add text prompt
        contentParts.add(Content.text(prompt));

        // Get Firebase AI model with error checking
        final model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.0-flash',
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            maxOutputTokens: 2048,
            temperature: 0.7,
          ),
        );

        // Generate content with timeout
        final response = await model.generateContent(contentParts)
            .timeout(const Duration(seconds: 30));
        
        if (response.text == null || response.text!.isEmpty) {
          throw AIServiceException('Empty response from Gemini AI', isRetryable: true);
        }

        // Parse the response to extract tags
        final selectedTags = _parseGeminiResponse(response.text!);
        
        if (selectedTags.isEmpty) {
          throw AIServiceException('No valid tags extracted from AI response', isRetryable: false);
        }
        
        debugPrint('✅ AI tagging successful: ${selectedTags.length} tags generated');
        return selectedTags;
        
      } on AIServiceException catch (e) {
        debugPrint('🚨 AI Service Error (attempt ${retryCount + 1}): ${e.message}');
        
        if (!e.isRetryable || retryCount >= maxRetries - 1) {
          debugPrint('❌ AI tagging failed permanently. Using fallback method.');
          return _generateBasicTags(itemMetadata);
        }
        
        retryCount++;
        // Exponential backoff: 2^retry seconds
        await Future.delayed(Duration(seconds: (1 << retryCount)));
        
      } catch (e) {
        debugPrint('💥 Unexpected error in AI tagging (attempt ${retryCount + 1}): $e');
        
        retryCount++;
        if (retryCount >= maxRetries) {
          debugPrint('❌ Max retries exceeded. Using fallback method.');
          return _generateBasicTags(itemMetadata);
        }
        
        // Wait before retry
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    
    // Should never reach here, but just in case
    debugPrint('⚠️ AI tagging exhausted all retries. Using fallback method.');
    return _generateBasicTags(itemMetadata);
  }

  /// Build comprehensive prompt for Gemini
  String _buildGeminiPrompt(Map<String, dynamic> itemMetadata) {
    final brand = itemMetadata['Brand'] ?? 'Unknown';
    final type = itemMetadata['Type'] ?? 'Unknown';
    final color = itemMetadata['Color'] ?? 'Unknown';
    final condition = itemMetadata['Condition'] ?? 'Unknown';
    final size = itemMetadata['Size'] ?? 'Unknown';
    final description = itemMetadata['Description'] ?? '';
    
    final allTags = allMasterTags.join(', ');
    
    return '''
    Analyze the provided images and item metadata to select the most relevant tags from the master list below.
    
    Item Details:
    - Brand: $brand
    - Type: $type
    - Color: $color
    - Condition: $condition
    - Size: $size
    - Description: $description
    
    Master Tag List:
    $allTags
    
    Instructions:
    1. Look at the images carefully to understand the item's style, fit, material, pattern, and overall aesthetic
    2. Consider the brand personality and target demographic
    3. Think about what occasions this item would be suitable for
    4. Consider the item's functionality and special features
    5. Select 8-15 most relevant tags from the master list above
    6. Focus on tags that would help users discover this item through search and filtering
    7. Include a mix of style, occasion, material, and trend tags where applicable
    
    Respond with a JSON object in this exact format:
    {
      "selected_tags": ["tag1", "tag2", "tag3", ...],
      "confidence_scores": {
        "tag1": 0.95,
        "tag2": 0.87,
        ...
      }
    }
    
    Only include tags that exist in the master list provided above.
    ''';
  }

  /// Parse Gemini response to extract tags
  List<String> _parseGeminiResponse(String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }
      
      final jsonString = jsonMatch.group(0)!;
      final jsonData = jsonDecode(jsonString);
      
      final selectedTags = List<String>.from(jsonData['selected_tags'] ?? []);
      
      // Validate that all tags exist in master list
      final validTags = selectedTags
          .where((tag) => allMasterTags.contains(tag))
          .toList();
      
      return validTags;
    } catch (e) {
      debugPrint('Error parsing Gemini response: $e');
      return [];
    }
  }

  /// Fallback tag generation based on basic metadata
  List<String> _generateBasicTags(Map<String, dynamic> itemMetadata) {
    List<String> tags = [];
    
    // Add style tags based on type
    final type = itemMetadata['Type']?.toString().toLowerCase() ?? '';
    if (type.contains('dress')) {
      tags.addAll(['elegant', 'feminine', 'formal']);
    } else if (type.contains('jean')) {
      tags.addAll(['casual', 'denim', 'everyday']);
    } else if (type.contains('shirt')) {
      tags.addAll(['versatile', 'classic', 'work']);
    }
    
    // Add color mood tags
    final color = itemMetadata['Color']?.toString().toLowerCase() ?? '';
    if (['black', 'white', 'gray', 'beige'].contains(color)) {
      tags.add('neutral');
    } else if (['red', 'pink', 'orange', 'yellow'].contains(color)) {
      tags.add('warm-colors');
    } else if (['blue', 'green', 'purple'].contains(color)) {
      tags.add('cool-colors');
    }
    
    // Add condition-based tags
    final condition = itemMetadata['Condition']?.toString().toLowerCase() ?? '';
    if (condition.contains('new') || condition.contains('never used')) {
      tags.add('new-arrival');
    } else if (condition.contains('vintage')) {
      tags.add('vintage');
    }
    
    return tags.where((tag) => allMasterTags.contains(tag)).toList();
  }

  /// Add tags to an item
  Future<void> addTagsToItem({
    required String itemId,
    required List<String> tagNames,
    Map<String, double>? confidenceScores,
  }) async {
    try {
      // Get tag IDs from tag names
      final tagIds = <String>[];
      final relevanceScores = <String, double>{};
      
      for (final tagName in tagNames) {
        final tag = _allTags.firstWhere(
          (t) => t.name == tagName,
          orElse: () => throw Exception('Tag not found: $tagName'),
        );
        tagIds.add(tag.id);
        
        if (confidenceScores != null && confidenceScores.containsKey(tagName)) {
          relevanceScores[tag.id] = confidenceScores[tagName]!;
        }
      }
      
      // Update item document with tags
      await _firestore.collection('Items').doc(itemId).update({
        'tags': tagIds,
        'tagRelevanceScores': relevanceScores,
        'lastTaggedAt': FieldValue.serverTimestamp(),
      });
      
      // Update tag usage counts
      final batch = _firestore.batch();
      for (final tagId in tagIds) {
        final tagRef = _firestore.collection('Tags').doc(tagId);
        batch.update(tagRef, {
          'usageCount': FieldValue.increment(1),
        });
      }
      await batch.commit();
      
    } catch (e) {
      debugPrint('Error adding tags to item: $e');
      rethrow;
    }
  }

  /// Record user interaction with tags (for analytics)
  Future<void> recordUserTagInteraction({
    required String itemId,
    required List<String> tagIds,
    required InteractionType interactionType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      final batch = _firestore.batch();
      
      for (final tagId in tagIds) {
        final interactionRef = _firestore.collection('UserTagInteractions').doc();
        final interaction = UserTagInteraction(
          id: interactionRef.id,
          userId: userId,
          tagId: tagId,
          itemId: itemId,
          type: interactionType,
          timestamp: DateTime.now(),
          metadata: metadata,
        );
        
        batch.set(interactionRef, interaction.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error recording user tag interaction: $e');
    }
  }

  /// Get items by tags (for filtering)
  Future<List<Map<String, dynamic>>> getItemsByTags({
    required List<String> tagNames,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // Get tag IDs from tag names
      final tagIds = <String>[];
      for (final tagName in tagNames) {
        final tag = _allTags.firstWhere(
          (t) => t.name == tagName,
          orElse: () => throw Exception('Tag not found: $tagName'),
        );
        tagIds.add(tag.id);
      }
      
      // Query items that contain any of these tags
      Query query = _firestore
          .collection('Items')
          .where('status', isEqualTo: 'Available')
          .where('tags', arrayContainsAny: tagIds)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Ensure image_preview is set for ItemCard compatibility
        if (data['images'] != null && (data['images'] as List).isNotEmpty) {
          data['image_preview'] = data['images'][0];
        }
        
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting items by tags: $e');
      return [];
    }
  }

  /// Get user's tag preferences based on interaction history
  Future<Map<String, double>> getUserTagPreferences(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('UserTagInteractions')
          .where('userId', isEqualTo: userId)
          .get();
      
      final tagScores = <String, double>{};
      
      for (final doc in querySnapshot.docs) {
        final interaction = UserTagInteraction.fromMap(doc.data(), doc.id);
        
        // Weight different interaction types
        double weight = 1.0;
        switch (interaction.type) {
          case InteractionType.purchase:
            weight = 5.0;
            break;
          case InteractionType.like:
            weight = 3.0;
            break;
          case InteractionType.view:
            weight = 1.0;
            break;
          case InteractionType.search:
            weight = 2.0;
            break;
          case InteractionType.filter:
            weight = 2.5;
            break;
        }
        
        tagScores[interaction.tagId] = (tagScores[interaction.tagId] ?? 0.0) + weight;
      }
      
      return tagScores;
    } catch (e) {
      debugPrint('Error getting user tag preferences: $e');
      return {};
    }
  }

  /// Get recommended items based on user's tag preferences
  Future<List<Map<String, dynamic>>> getRecommendedItems({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final tagPreferences = await getUserTagPreferences(userId);
      
      if (tagPreferences.isEmpty) {
        // Fallback to trending items if no preferences
        return await _getTrendingItems(limit);
      }
      
      // Get top preferred tags
      final topTags = tagPreferences.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      
      final topTagIds = topTags
          .take(10)
          .map((entry) => entry.key)
          .toList();
      
      // Get items with preferred tags
      final query = _firestore
          .collection('Items')
          .where('status', isEqualTo: 'Available')
          .where('tags', arrayContainsAny: topTagIds)
          .limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Ensure image_preview is set for ItemCard compatibility
        if (data['images'] != null && (data['images'] as List).isNotEmpty) {
          data['image_preview'] = data['images'][0];
        }
        
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting recommended items: $e');
      return [];
    }
  }

  /// Get trending items (fallback for recommendations)
  Future<List<Map<String, dynamic>>> _getTrendingItems(int limit) async {
    try {
      final query = _firestore
          .collection('Items')
          .where('status', isEqualTo: 'Available')
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Ensure image_preview is set for ItemCard compatibility
        if (data['images'] != null && (data['images'] as List).isNotEmpty) {
          data['image_preview'] = data['images'][0];
        }
        
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting trending items: $e');
      return [];
    }
  }

  /// Search items by tag names (for search functionality)
  Future<List<Map<String, dynamic>>> searchItemsByTags({
    required String searchQuery,
    int limit = 20,
  }) async {
    try {
      // Find tags that match the search query
      final matchingTags = _allTags
          .where((tag) => 
            tag.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            tag.synonyms.any((synonym) => 
              synonym.toLowerCase().contains(searchQuery.toLowerCase())))
          .map((tag) => tag.id)
          .toList();
      
      if (matchingTags.isEmpty) {
        return [];
      }
      
      // Get items with matching tags
      final query = _firestore
          .collection('Items')
          .where('status', isEqualTo: 'Available')
          .where('tags', arrayContainsAny: matchingTags)
          .limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Ensure image_preview is set for ItemCard compatibility
        if (data['images'] != null && (data['images'] as List).isNotEmpty) {
          data['image_preview'] = data['images'][0];
        }
        
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error searching items by tags: $e');
      return [];
    }
  }

  /// Get all available tags for filtering UI
  List<Tag> get availableTags => _allTags;

  /// Get tags by category for filtering UI
  List<Tag> getTagsByCategory(String category) {
    return _allTags.where((tag) => tag.category == category).toList();
  }
} 