import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadUserTheme() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (userId.isEmpty) return;

      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      if (userDoc.exists && userDoc.data()?.containsKey('dark_theme') == true) {
        final isDarkTheme = userDoc.data()?['dark_theme'] ?? false;
        _themeMode = isDarkTheme ? ThemeMode.dark : ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system; // Default to system theme if field is missing
      }
      notifyListeners();
    } catch (e) {
      print('Error loading user theme: $e');
    }
  }

  Future<void> updateUserTheme(bool isDark) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (userId.isEmpty) return;

      await FirebaseFirestore.instance.collection('Users').doc(userId).set(
        {'dark_theme': isDark},
        SetOptions(merge: true), // Merge to avoid overwriting other fields
      );

      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      print('Error updating user theme: $e');
    }
  }
}