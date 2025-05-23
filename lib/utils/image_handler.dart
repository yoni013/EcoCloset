import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageHandler {
  /// Refresh a Firebase Storage URL when it's expired or invalid
  static Future<String?> refreshFirebaseStorageUrl(String oldUrl) async {
    try {
      // Extract the storage path from the URL
      final uri = Uri.parse(oldUrl);
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
      print('Error refreshing Firebase Storage URL: $e');
      return null;
    }
  }

  /// Update user's profile picture URL in Firestore with a fresh URL
  static Future<bool> refreshUserProfilePicUrl(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return false;
      
      final data = userDoc.data()!;
      final oldUrl = data['profilePicUrl'] as String?;
      
      if (oldUrl == null || oldUrl.isEmpty) return false;
      
      final newUrl = await refreshFirebaseStorageUrl(oldUrl);
      if (newUrl == null) return false;
      
      // Update Firestore with the new URL
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update({'profilePicUrl': newUrl});
      
      return true;
    } catch (e) {
      print('Error refreshing user profile pic URL: $e');
      return false;
    }
  }

  /// Custom CachedNetworkImage widget with automatic error recovery
  static Widget buildCachedNetworkImage({
    required String imageUrl,
    required BoxFit fit,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
    String? userId, // Optional: for profile pics that can be refreshed
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: placeholder ?? (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) {
        // If it's a 403 error and we have a userId, try to refresh the URL
        if (error.toString().contains('403') && userId != null) {
          return FutureBuilder<bool>(
            future: refreshUserProfilePicUrl(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasData && snapshot.data == true) {
                // URL was refreshed, try to reload the image
                return CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: fit,
                  placeholder: placeholder ?? (context, url) => const CircularProgressIndicator(),
                  errorWidget: errorWidget ?? (context, url, error) => const Icon(Icons.person, size: 50),
                );
              } else {
                // Fallback to error widget
                return errorWidget != null ? errorWidget(context, url, error) : const Icon(Icons.person, size: 50);
              }
            },
          );
        }
        
        // For non-403 errors or when no userId is provided
        return errorWidget != null ? errorWidget(context, url, error) : const Icon(Icons.image_not_supported, size: 50);
      },
    );
  }

  /// Handle profile picture loading with automatic retry for 403 errors
  static Widget buildProfilePicture({
    required String? profilePicUrl,
    required String userId,
    double radius = 24,
    Widget? fallbackIcon,
  }) {
    if (profilePicUrl == null || profilePicUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: fallbackIcon ?? const Icon(Icons.person),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: ClipOval(
        child: buildCachedNetworkImage(
          imageUrl: profilePicUrl,
          fit: BoxFit.cover,
          userId: userId,
          errorWidget: (context, url, error) => fallbackIcon ?? const Icon(Icons.person),
        ),
      ),
    );
  }
} 