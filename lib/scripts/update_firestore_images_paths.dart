import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Reference Firestore collection
  CollectionReference collection = FirebaseFirestore.instance.collection('Items');

  // Fetch documents
  QuerySnapshot snapshot = await collection.get();

  for (var doc in snapshot.docs) {
    List<dynamic> images = doc['images']; // Get the image paths

    if (images.isNotEmpty) {
      if (images[0].toString().startsWith('items')){
        List<String> downloadUrls = [];

        for (String path in images) {
          try {
            String downloadUrl = await FirebaseStorage.instance.ref(path).getDownloadURL();
            downloadUrls.add(downloadUrl);
          } catch (e) {
            debugPrint('Error fetching URL for $path: $e');
          }
        }

        // Update Firestore document with the new URLs
        await collection.doc(doc.id).update({'images': downloadUrls});
        debugPrint('Updated document ${doc.id} with download URLs.');
      }
    }
  }

  debugPrint('Firestore update completed.');
}
