import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ProfileUrlFixer {
  /// Fix all broken profile picture URLs in the Users collection
  static Future<void> fixAllProfileUrls() async {
    try {
      final usersCollection = FirebaseFirestore.instance.collection('Users');
      final querySnapshot = await usersCollection.get();
      
      int fixedCount = 0;
      int totalCount = querySnapshot.docs.length;
      
      debugPrint('Starting to fix profile URLs for $totalCount users');
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final userId = doc.id;
        final profilePicUrl = data['profilePicUrl'] as String?;
        
        if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
          try {
            // Try to get a fresh download URL
            String? newUrl = await _refreshProfileUrl(userId, profilePicUrl);
            
            if (newUrl != null && newUrl != profilePicUrl) {
              // Update the document with the new URL
              await usersCollection.doc(userId).update({
                'profilePicUrl': newUrl,
              });
              fixedCount++;
              debugPrint('Fixed profile URL for user $userId');
            }
          } catch (e) {
            debugPrint('Could not fix profile URL for user $userId: $e');
          }
        }
      }
      
      debugPrint('Fixed $fixedCount out of $totalCount profile URLs');
    } catch (e) {
      debugPrint('Error fixing profile URLs: $e');
    }
  }
  
  /// Try to refresh a single user's profile URL
  static Future<String?> _refreshProfileUrl(String userId, String oldUrl) async {
    try {
      // First, try the standard path for this user
      final standardRef = FirebaseStorage.instance.ref().child('profile_pics/$userId.jpg');
      try {
        return await standardRef.getDownloadURL();
      } catch (e) {
        // If standard path doesn't work, try to extract path from old URL
        return await _extractAndRefreshFromUrl(oldUrl);
      }
    } catch (e) {
      debugPrint('Error refreshing profile URL for user $userId: $e');
      return null;
    }
  }
  
  /// Extract storage path from URL and get fresh download URL
  static Future<String?> _extractAndRefreshFromUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Find the object path (after 'o/')
      int oIndex = pathSegments.indexOf('o');
      if (oIndex == -1 || oIndex + 1 >= pathSegments.length) {
        return null;
      }
      
      // Get the encoded path and decode it
      final encodedPath = pathSegments[oIndex + 1];
      final decodedPath = Uri.decodeFull(encodedPath);
      
      // Get a fresh download URL
      final ref = FirebaseStorage.instance.ref().child(decodedPath);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error extracting and refreshing URL: $e');
      return null;
    }
  }
  
  /// Fix URLs for users who have inconsistent field names
  static Future<void> migrateProfilePhotoURLField() async {
    try {
      final usersCollection = FirebaseFirestore.instance.collection('Users');
      final querySnapshot = await usersCollection.get();
      
      int migratedCount = 0;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final profilePhotoURL = data['profilePhotoURL'] as String?;
        final profilePicUrl = data['profilePicUrl'] as String?;
        
        // If user has profilePhotoURL but not profilePicUrl, migrate it
        if (profilePhotoURL != null && profilePhotoURL.isNotEmpty && 
            (profilePicUrl == null || profilePicUrl.isEmpty)) {
          
          await usersCollection.doc(doc.id).update({
            'profilePicUrl': profilePhotoURL,
            'profilePhotoURL': FieldValue.delete(), // Remove the old field
          });
          
          migratedCount++;
          debugPrint('Migrated profilePhotoURL to profilePicUrl for user ${doc.id}');
        }
      }
      
      debugPrint('Migrated $migratedCount users from profilePhotoURL to profilePicUrl');
    } catch (e) {
      debugPrint('Error migrating profilePhotoURL field: $e');
    }
  }
} 