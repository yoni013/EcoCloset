import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Utils {
  static List<String> brands = [];
  static List<String> sizes = [];
  static List<String> general_sizes = [];
  static List<String> pants_sizes = [];
  static List<String> shoe_sizes = [];
  static List<String> conditions = [];
  static List<String> types = [];
  static List<String> colors = [];

  static Future<void> loadMetadata() async {
    final String jsonString = await rootBundle.loadString('assets/items_metadata_lists.json');
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);

    brands = List<String>.from(jsonData['brands']);
    sizes = Set<String>.from([
      ...jsonData['general_sizes'] as List<dynamic>,
      ...jsonData['pants_sizes'] as List<dynamic>,
      ...jsonData['shoe_sizes'] as List<dynamic>,
    ]).toList();
    general_sizes = List<String>.from(jsonData['general_sizes']);
    pants_sizes = List<String>.from(jsonData['pants_sizes']);
    shoe_sizes = List<String>.from(jsonData['shoe_sizes']);
    conditions = List<String>.from(jsonData['conditions']);
    types = List<String>.from(jsonData['types']);
    colors = List<String>.from(jsonData['colors']);
  }
}
