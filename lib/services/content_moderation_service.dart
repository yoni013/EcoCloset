import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';

class ContentModerationService {
  static final ContentModerationService _instance = ContentModerationService._internal();
  factory ContentModerationService() => _instance;
  ContentModerationService._internal();

  // List of inappropriate keywords for basic filtering
  static const List<String> _prohibitedWords = [
    // Add common inappropriate words
    'illegal', 'stolen', 'fake', 'replica', 'counterfeit',
    // Hate speech examples (add more as needed)
    'hate', 'discriminat', 'racist', 'sexist',
    // Adult content
    'adult', 'sexual', 'explicit', 'porn',
    // Violence
    'violence', 'weapon', 'dangerous',
    // Scam related
    'scam', 'fraud', 'cheat', 'steal',
    // Personal info sharing
    'phone', 'email', 'address', 'contact me at',
  ];

  /// Basic keyword filtering for item descriptions
  ModerationResult basicTextModeration(String text) {
    if (text.trim().isEmpty) {
      return ModerationResult(
        isApproved: false,
        reason: 'Description cannot be empty',
        flaggedContent: [],
      );
    }

    final lowerText = text.toLowerCase();
    List<String> flaggedWords = [];

    for (String word in _prohibitedWords) {
      if (lowerText.contains(word.toLowerCase())) {
        flaggedWords.add(word);
      }
    }

    // Check for suspicious patterns
    if (_containsPersonalInfo(lowerText)) {
      flaggedWords.add('personal_information');
    }

    if (_containsSpamPattern(lowerText)) {
      flaggedWords.add('spam_pattern');
    }

    return ModerationResult(
      isApproved: flaggedWords.isEmpty,
      reason: flaggedWords.isNotEmpty 
          ? 'Content contains inappropriate or prohibited words: ${flaggedWords.join(', ')}'
          : null,
      flaggedContent: flaggedWords,
    );
  }

  /// AI-powered content moderation using Gemini
  Future<ModerationResult> aiContentModeration({
    required String description,
    required String itemName,
    String? category,
  }) async {
    const int maxRetries = 2;
    int retryCount = 0;
    
    // First do basic filtering
    final basicResult = basicTextModeration(description);
    if (!basicResult.isApproved) {
      return basicResult;
    }

    while (retryCount < maxRetries) {
      try {
        debugPrint('🛡️ AI moderation attempt ${retryCount + 1}/$maxRetries');
        
        // Validate inputs
        if (description.trim().isEmpty || itemName.trim().isEmpty) {
          return ModerationResult(
            isApproved: false,
            reason: 'Invalid input: empty description or item name',
            flaggedContent: ['invalid_input'],
          );
        }

        // Use Gemini AI for advanced moderation
        final model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.0-flash',
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            maxOutputTokens: 1024,
            temperature: 0.1, // Lower temperature for more consistent results
          ),
        );

        final prompt = '''
Analyze this clothing item listing for inappropriate content. Check for:
1. Hate speech or discriminatory language
2. Adult or explicit content
3. Violence or dangerous items
4. Scam or fraud indicators
5. Fake or counterfeit items
6. Personal information sharing (phone, email, address)
7. Items that violate marketplace policies

Item Name: $itemName
Description: $description
Category: ${category ?? 'clothing'}

Return JSON with:
{
  "is_appropriate": boolean,
  "confidence": number (0-1),
  "reason": "explanation if inappropriate",
  "flagged_categories": ["list", "of", "issues"]
}
''';

        final response = await model.generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 15));
        
        if (response.text == null || response.text!.isEmpty) {
          throw Exception('Empty response from AI moderation service');
        }

        final result = jsonDecode(response.text!);
        
        // Validate AI response structure
        if (!result.containsKey('is_appropriate')) {
          throw Exception('Invalid AI response format: missing is_appropriate field');
        }
        
        final moderationResult = ModerationResult(
          isApproved: result['is_appropriate'] ?? false,
          reason: result['reason'],
          flaggedContent: List<String>.from(result['flagged_categories'] ?? []),
          confidence: (result['confidence'] ?? 0.0).toDouble(),
        );
        
        debugPrint('✅ AI moderation successful: ${moderationResult.isApproved ? 'APPROVED' : 'REJECTED'}');
        return moderationResult;

      } catch (e) {
        debugPrint('🚨 AI moderation error (attempt ${retryCount + 1}): $e');
        
        retryCount++;
        if (retryCount < maxRetries) {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
    }
    
    debugPrint('❌ AI moderation failed after $maxRetries attempts. Using basic moderation result.');
    return basicResult;
  }

  /// Check if text contains personal information patterns
  bool _containsPersonalInfo(String text) {
    // Look for phone number patterns
    final phonePattern = RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b');
    if (phonePattern.hasMatch(text)) return true;

    // Look for email patterns
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    if (emailPattern.hasMatch(text)) return true;

    // Look for contact phrases
    final contactPhrases = ['contact me', 'call me', 'text me', 'whatsapp', 'telegram'];
    for (String phrase in contactPhrases) {
      if (text.contains(phrase)) return true;
    }

    return false;
  }

  /// Check for spam patterns
  bool _containsSpamPattern(String text) {
    // Check for excessive capital letters
    final capitals = text.replaceAll(RegExp(r'[^A-Z]'), '');
    if (capitals.length > text.length * 0.5) return true;

    // Check for excessive punctuation
    final punctuation = text.replaceAll(RegExp(r'[^!?.]'), '');
    if (punctuation.length > text.length * 0.3) return true;

    // Check for repeated characters
    final repeatedPattern = RegExp(r'(.)\1{3,}');
    if (repeatedPattern.hasMatch(text)) return true;

    return false;
  }

  /// Report inappropriate content
  Future<void> reportContent({
    required String itemId,
    required String reporterId,
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      // In a real implementation, you'd save this to Firestore
      // For now, just log it
      debugPrint('Content reported - Item: $itemId, Reporter: $reporterId, Reason: $reason');
      
      // You could add this to a 'Reports' collection in Firestore
      // await FirebaseFirestore.instance.collection('Reports').add({
      //   'itemId': itemId,
      //   'reporterId': reporterId,
      //   'reason': reason,
      //   'additionalDetails': additionalDetails,
      //   'status': 'pending',
      //   'createdAt': FieldValue.serverTimestamp(),
      // });
      
    } catch (e) {
      debugPrint('Error reporting content: $e');
    }
  }
}

class ModerationResult {
  final bool isApproved;
  final String? reason;
  final List<String> flaggedContent;
  final double? confidence;

  ModerationResult({
    required this.isApproved,
    this.reason,
    this.flaggedContent = const [],
    this.confidence,
  });

  @override
  String toString() {
    return 'ModerationResult(approved: $isApproved, reason: $reason, flagged: $flaggedContent)';
  }
}
