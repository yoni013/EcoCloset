/// firestore_cache_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCacheProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _ttl = const Duration(minutes: 360);

  Map<String, dynamic> get cache => _cache;

  bool _isCacheValid(String cacheKey) {
    if (!_cacheTimestamps.containsKey(cacheKey)) return false;
    final cachedTime = _cacheTimestamps[cacheKey]!;
    return DateTime.now().difference(cachedTime) < _ttl;
  }

  /// Fetches a collection with optional query filtering and caches the result.
  Future<List<Map<String, dynamic>>> fetchCollection(
    String cacheKey,
    Query<Map<String, dynamic>> query,
  ) async {
    if (_cache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final querySnapshot = await query.get();
      final data = querySnapshot.docs.map((doc) {
        final docData = doc.data();
        docData['id'] = doc.id;
        return docData;
      }).toList();

      _cache[cacheKey] = data;
      _cacheTimestamps[cacheKey] = DateTime.now();
      notifyListeners();

      return data;
    } catch (e) {
      debugPrint('Error fetching collection: $e');
      return [];
    }
  }

  /// Fetches a single document and caches the result.
  Future<Map<String, dynamic>?> fetchDocument(
    String cacheKey,
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    if (_cache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();

      if (data != null) {
        _cache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now(); 
        notifyListeners();
      }

      return data;
    } catch (e) {
      debugPrint('Error fetching document: $e');
      return null;
    }
  }

  /// Fetches a collection without any query and caches the result.
  Future<List<Map<String, dynamic>>> fetchCollectionDirect(
    String collectionPath,
  ) async {
    if (_cache.containsKey(collectionPath) && _isCacheValid(collectionPath)) {
      return _cache[collectionPath];
    }

    try {
      final querySnapshot = await _firestore.collection(collectionPath).get();
      final data = querySnapshot.docs.map((doc) {
        final docData = doc.data();
        docData['id'] = doc.id; 
        return docData;
      }).toList();

      _cache[collectionPath] = data;
      _cacheTimestamps[collectionPath] = DateTime.now();
      notifyListeners();

      return data;
    } catch (e) {
      debugPrint('Error fetching collection: $e');
      return [];
    }
  }

  /// Fetches a single document by its path and caches the result.
  Future<Map<String, dynamic>?> fetchDocumentDirect(
    String documentPath,
  ) async {
    if (_cache.containsKey(documentPath) && _isCacheValid(documentPath)) {
      return _cache[documentPath];
    }

    try {
      final docSnapshot = await _firestore.doc(documentPath).get();
      final data = docSnapshot.data();

      if (data != null) {
        _cache[documentPath] = data;
        _cacheTimestamps[documentPath] = DateTime.now(); // Update timestamp
        notifyListeners();
      }

      return data;
    } catch (e) {
      debugPrint('Error fetching document: $e');
      return null;
    }
  }

  /// Clears a specific cache entry.
  void clearCache(String cacheKey) {
    _cache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
    notifyListeners();
  }

  /// Clears all cached entries.
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    notifyListeners();
  }
}
