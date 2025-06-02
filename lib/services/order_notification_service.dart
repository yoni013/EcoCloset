import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class OrderNotificationService extends ChangeNotifier {
  static final OrderNotificationService _instance = OrderNotificationService._internal();
  factory OrderNotificationService() => _instance;
  OrderNotificationService._internal();

  int _pendingOrdersCount = 0;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  StreamSubscription<QuerySnapshot>? _allOrdersSubscription;
  bool _isListening = false;
  String? _currentUserId;

  int get pendingOrdersCount => _pendingOrdersCount;

  void startListening() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (!_isListening) {
        debugPrint('OrderNotificationService: No user logged in');
      }
      return;
    }

    // Only start listening if we're not already listening or if the user has changed
    if (_isListening && _currentUserId == userId) {
      return; // Already listening for this user
    }

    // Stop any existing listeners
    if (_isListening) {
      stopListening();
    }

    debugPrint('OrderNotificationService: Starting to listen for user $userId');
    _currentUserId = userId;
    _isListening = true;
    _startPendingOrdersListener(userId);
    _startAllOrdersListener(userId);
  }

  void _startPendingOrdersListener(String userId) {
    // Cancel existing subscription if any
    _ordersSubscription?.cancel();
    
    // Reset count when starting fresh
    if (_pendingOrdersCount != 0) {
      _pendingOrdersCount = 0;
      notifyListeners();
    }

    // Listen to orders where current user needs to take action
    _ordersSubscription = FirebaseFirestore.instance
        .collection('Orders')
        .where(Filter.or(
          Filter('sellerId', isEqualTo: userId),
          Filter('buyerId', isEqualTo: userId),
        ))
        .snapshots()
        .listen((snapshot) {
      int count = 0;
      List<String> actionableOrders = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final sellerId = data['sellerId'] as String?;
        final buyerId = data['buyerId'] as String?;
        final itemName = data['itemName'] ?? 'Unknown Item';
        
        // Count orders that need seller attention
        if (sellerId == userId) {
          if (status == 'pending_seller' || 
              status == 'confirmed' || 
              status == 'Purchase Confirmed') {
            count++;
            actionableOrders.add('Seller action needed for "$itemName" (status: $status)');
          }
        }
        
        // Count orders that need buyer attention
        if (buyerId == userId) {
          if (status == 'pending_buyer' || status == 'sold') {
            count++;
            actionableOrders.add('Buyer action needed for "$itemName" (status: $status)');
          }
        }
      }
      
      // Only log when count actually changes or when there are actionable orders
      if (_pendingOrdersCount != count) {
        debugPrint('OrderNotificationService: Updated count from $_pendingOrdersCount to $count');
        if (count > 0) {
          for (String order in actionableOrders) {
            debugPrint('  - $order');
          }
        }
        _pendingOrdersCount = count;
        notifyListeners();
      }
    });
  }

  void _startAllOrdersListener(String userId) {
    // Cancel existing subscription if any
    _allOrdersSubscription?.cancel();

    // Listen to all orders where current user is buyer or seller
    _allOrdersSubscription = FirebaseFirestore.instance
        .collection('Orders')
        .where(Filter.or(
          Filter('buyerId', isEqualTo: userId),
          Filter('sellerId', isEqualTo: userId),
        ))
        .snapshots()
        .listen((snapshot) {
      // Notify listeners that orders have changed
      // This will trigger my_shop_page to refresh
      // Only log occasionally to avoid spam
      notifyListeners();
    });
  }

  void stopListening() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _allOrdersSubscription?.cancel();
    _allOrdersSubscription = null;
    _isListening = false;
    _currentUserId = null;
    debugPrint('OrderNotificationService: Stopped listening');
  }

  // Method to manually trigger refresh (useful for immediate updates)
  void notifyOrdersChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
} 