import 'package:flutter/material.dart';
// Remove Firebase AI import since we're not using it anymore
// import 'dart:convert';

class ContentModerationService {
  static final ContentModerationService _instance = ContentModerationService._internal();
  factory ContentModerationService() => _instance;
  ContentModerationService._internal();

  // List of inappropriate keywords for basic filtering
  static const List<String> _prohibitedWords = [
    // Add common inappropriate words
    'illegal', 'stolen', 'fake', 'replica', 'counterfeit',
    // Hebrew equivalents
    'לא חוקי', 'גנוב', 'מזויף', 'חיקוי', 'זיוף',
    
    // Hate speech examples (add more as needed)
    'hate', 'discriminat', 'racist', 'sexist',
    // Hebrew equivalents
    'שנאה', 'אפליה', 'גזעני', 'מיזוגני',
    
    // Adult content
    'adult', 'sexual', 'explicit', 'porn',
    // Hebrew equivalents
    'מבוגרים', 'מיני', 'מפורש', 'פורנוגרפיה',
    
    // Violence
    'violence', 'weapon', 'dangerous',
    // Hebrew equivalents
    'אלימות', 'נשק', 'מסוכן',
    
    // Scam related
    'scam', 'fraud', 'cheat', 'steal',
    // Hebrew equivalents
    'הונאה', 'רמאות', 'רמייה', 'גניבה',
    
    // Personal info sharing
    'phone', 'email', 'address', 'contact me at',
    // Hebrew equivalents
    'טלפון', 'אימייל', 'כתובת', 'צור קשר',
  ];

  /// Basic keyword filtering for item descriptions
  ModerationResult basicTextModeration(String text) {
    if (text.trim().isEmpty) {
      // Allow empty descriptions
      return ModerationResult(
        isApproved: true,
        reason: null,
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

  /// Content moderation using basic filtering
  Future<ModerationResult> moderateContent({
    required String description,
    required String itemName,
    String? category,
  }) async {
    // Validate inputs
    if (itemName.trim().isEmpty) {
      return ModerationResult(
        isApproved: true,
        reason: null,
      );
    }

    // If description is empty, approve without text checks
    if (description.trim().isEmpty) {
      debugPrint('✅ No description provided; skipping text moderation.');
      return ModerationResult(isApproved: true, reason: null, flaggedContent: []);
    }

    // Use basic filtering for fast moderation
    final result = basicTextModeration(description);
    
    debugPrint('✅ Content moderation completed: ${result.isApproved ? 'APPROVED' : 'REJECTED'}');
    return result;
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
