import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../utils/fix_profile_urls.dart';

Future<void> main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Starting profile picture URL migration...');
  
  // First, migrate any users with the old field name
  await ProfileUrlFixer.migrateProfilePhotoURLField();
  
  // Then, fix any broken URLs
  await ProfileUrlFixer.fixAllProfileUrls();
  
  debugPrint('Profile picture URL migration completed.');
} 