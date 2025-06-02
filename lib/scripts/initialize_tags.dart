import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../services/tag_service.dart';

/// One-time script to initialize tags in Firestore
/// Run this once to populate your Tags collection
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print('🏷️ Starting tag initialization...');
  
  try {
    final tagService = TagService();
    await tagService.initialize();
    
    print('📋 Loaded master tags');
    
    // Initialize tags in Firestore
    await tagService.initializeTagsInFirestore();
    
    print('✅ Tags initialized successfully in Firestore!');
    print('🎯 You can now start using the tagging system');
    
  } catch (e) {
    print('❌ Error initializing tags: $e');
  }
  
  print('🏁 Tag initialization completed');
} 