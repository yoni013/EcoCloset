import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Utils {
  static List<String> brands = [];
  static List<String> sizes = [];
  static List<String> conditions = [];
  static List<String> types = [];
  static List<String> colors = [];

  static Future<void> loadMetadata() async {
    final String jsonString = await rootBundle.loadString('assets/items_metadata_lists.json');
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);

    brands = List<String>.from(jsonData['brands']);
    sizes = List<String>.from(jsonData['sizes']);
    conditions = List<String>.from(jsonData['conditions']);
    types = List<String>.from(jsonData['types']);
    colors = List<String>.from(jsonData['colors']);
  }
}
