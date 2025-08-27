import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import 'item_page.dart';
import 'package:beged/utils/translation_metadata.dart';
import 'package:beged/services/order_notification_service.dart';
import '../widgets/time_availability_selector.dart';
import '../widgets/buyer_time_selector.dart';
import '../services/communication_service.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({Key? key}) : super(key: key);

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // We store two lists of orders: incoming (I'm buyer) and outgoing (I'm seller)
  List<Map<String, dynamic>> incomingOrders = [];
  List<Map<String, dynamic>> outgoingOrders = [];

  // Scroll controllers for each table:
  final ScrollController _incomingScrollController = ScrollController();

  final ScrollController _outgoingScrollController = ScrollController();

  // Track whether we show the "Scroll to top" button.
  bool _showIncomingScrollUp = false;
  bool _showOutgoingScrollUp = false;

  bool isLoading = true;
  
  // Add listener for order changes
  OrderNotificationService? _orderNotificationService;

  @override
  void initState() {
    super.initState();
    // 2 tabs: Incoming & Outgoing
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrders();

    // Listen to vertical scroll controllers so we know when to display the "go up" button
    _incomingScrollController.addListener(() {
      if (_incomingScrollController.position.pixels > 50 &&
          !_showIncomingScrollUp && mounted) {
        setState(() => _showIncomingScrollUp = true);
      } else if (_incomingScrollController.position.pixels < 50 &&
          _showIncomingScrollUp && mounted) {
        setState(() => _showIncomingScrollUp = false);
      }
    });
    _outgoingScrollController.addListener(() {
      if (_outgoingScrollController.position.pixels > 50 &&
          !_showOutgoingScrollUp && mounted) {
        setState(() => _showOutgoingScrollUp = true);
      } else if (_outgoingScrollController.position.pixels < 50 &&
          _showOutgoingScrollUp && mounted) {
        setState(() => _showOutgoingScrollUp = false);
      }
    });

    // Setup order notification service listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _orderNotificationService = Provider.of<OrderNotificationService>(context, listen: false);
        _orderNotificationService?.addListener(_onOrdersChanged);
        _orderNotificationService?.startListening(); // Start listening once
      } catch (e) {
        debugPrint('OrderNotificationService not available: $e');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incomingScrollController.dispose();
    _outgoingScrollController.dispose();
    _orderNotificationService?.removeListener(_onOrdersChanged);
    super.dispose();
  }

  // Callback when orders change
  void _onOrdersChanged() {
    if (mounted) {
      _fetchOrders();
    }
  }

  // ----- Firestore fetching -----

  /// Fetch a user's "Name" from "Users" collection by userId
  Future<String> fetchUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      return userDoc.data()?['name'] ?? AppLocalizations.of(context).unknown;
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      return AppLocalizations.of(context).unknown;
    }
  }

  /// Fetch a user's phone number from "Users" collection by userId
  Future<String?> fetchUserPhone(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      return userDoc.data()?['phoneNumber'] ?? userDoc.data()?['phone'];
    } catch (e) {
      debugPrint('Error fetching user phone: $e');
      return null;
    }
  }

  /// Check if communication buttons should be shown based on order status and user role
  bool shouldShowCommunicationButtons(Map<String, dynamic> order, bool isBuyerView) {
    final status = order['status'];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) return false;
    
    // For sellers: show buttons after they accept the order (status != 'pending_seller')
    if (!isBuyerView && currentUserId == order['sellerId']) {
      return status != 'pending_seller' && 
             !['cancelled', 'declined', 'completed', 'reported'].contains(status);
    }
    
    // For buyers: show buttons after seller accepts the order
    if (isBuyerView && currentUserId == order['buyerId']) {
      return !['pending_seller', 'cancelled', 'declined', 'completed', 'reported'].contains(status);
    }
    
    return false;
  }

  /// Incoming Orders => current user is the Buyer
  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Fetch incoming orders
      final incomingSnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('buyerId', isEqualTo: userId)
          .get();

      // Fetch outgoing orders
      final outgoingSnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('sellerId', isEqualTo: userId)
          .get();

      // Process incoming orders
      incomingOrders = await Future.wait(
        incomingSnapshot.docs.map((doc) async {
          final data = doc.data();
          final sellerName = await fetchUserName(data['sellerId']);
          return {
            ...data,
            'id': doc.id,
            'sellerName': sellerName,
          };
        }),
      );

      // Process outgoing orders
      outgoingOrders = await Future.wait(
        outgoingSnapshot.docs.map((doc) async {
          final data = doc.data();
          final buyerName = await fetchUserName(data['buyerId']);
          return {
            ...data,
            'id': doc.id,
            'buyerName': buyerName,
          };
        }),
      );

      // Sort both lists by createdAt in descending order (most recent first)
      incomingOrders.sort((a, b) {
        final aCreatedAt = a['createdAt'] as Timestamp?;
        final bCreatedAt = b['createdAt'] as Timestamp?;
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        return bCreatedAt.compareTo(aCreatedAt);
      });

      outgoingOrders.sort((a, b) {
        final aCreatedAt = a['createdAt'] as Timestamp?;
        final bCreatedAt = b['createdAt'] as Timestamp?;
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        return bCreatedAt.compareTo(aCreatedAt);
      });

      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // (Optional) function if you want to update status
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .update({'status': newStatus});
      await _fetchOrders();
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  // Enhanced function to handle order actions
  Future<void> _handleOrderAction(String orderId, String action, Map<String, dynamic> order) async {
    try {
      switch (action) {
        case 'Accept':
          await _acceptOrder(orderId, order);
          break;
        case 'Decline':
          await _declineOrder(orderId);
          break;
        case 'SetAvailability':
          await _setTimeAvailability(orderId);
          break;
        case 'SelectTime':
          await _selectPickupTime(orderId, order);
          break;
        case 'MarkAsSold':
          await _markAsSold(orderId, order);
          break;
        case 'ConfirmReceipt':
          await _showBuyerReceiptConfirmation(order);
          break;
        case 'ConfirmItemReceipt':
          await _confirmItemReceipt(order);
          break;
        case 'ReportIssue':
          await _reportIssue(order);
          break;
        case 'Cancel':
          await _cancelOrder(orderId);
          break;
        default:
          await _updateOrderStatus(orderId, action);
      }
    } catch (e) {
      debugPrint('Error handling order action: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _acceptOrder(String orderId, Map<String, dynamic> order) async {
    // Get seller's address from Users collection
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.uid)
        .get();
    
    final sellerAddress = userDoc.data()?['address'] ?? '';

    await FirebaseFirestore.instance
        .collection('Orders')
        .doc(orderId)
        .update({
      'sellerAddress': sellerAddress,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Navigate to time availability selector
    _setTimeAvailability(orderId);
  }

  Future<void> _declineOrder(String orderId) async {
    String? declineReason;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).declineOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).reasonForDeclining),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                declineReason = value;
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).declineReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              // Get order data to retrieve item ID
              final orderDoc = await FirebaseFirestore.instance
                  .collection('Orders')
                  .doc(orderId)
                  .get();
              
              final orderData = orderDoc.data();
              final itemId = orderData?['itemId'];

              await FirebaseFirestore.instance
                  .collection('Orders')
                  .doc(orderId)
                  .update({
                'status': 'declined',
                'declineReason': declineReason ?? '',
                'updatedAt': FieldValue.serverTimestamp(),
              });

              // Reset item status back to Available
              if (itemId != null) {
                await FirebaseFirestore.instance
                    .collection('Items')
                    .doc(itemId)
                    .update({'status': 'Available'});
              }

              Navigator.of(context).pop();
              await _fetchOrders();
            },
            child: Text(AppLocalizations.of(context).decline),
          ),
        ],
      ),
    );
  }

  Future<void> _setTimeAvailability(String orderId) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TimeAvailabilitySelector(
          orderId: orderId,
          onTimeSlotsSaved: (timeSlots) {
            _fetchOrders(); // Refresh the orders
          },
        ),
      ),
    );
  }

  Future<void> _selectPickupTime(String orderId, Map<String, dynamic> order) async {
    final availableTimeSlots = List<Map<String, dynamic>>.from(
      order['availableTimeSlots'] ?? []
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BuyerTimeSelector(
          orderId: orderId,
          availableTimeSlots: availableTimeSlots,
          onTimeSlotSelected: (selectedTimeSlot) {
            _fetchOrders(); // Refresh the orders
          },
        ),
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    String? cancellationReason;
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).cancelOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).cancelOrderConfirmation),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                cancellationReason = value;
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).cancellationReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).no),
          ),
          ElevatedButton(
            onPressed: () {
              confirmed = true;
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context).yes),
          ),
        ],
      ),
    );

    if (confirmed) {
      // Get order data to retrieve item ID
      final orderDoc = await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .get();
      
      final orderData = orderDoc.data();
      final itemId = orderData?['itemId'];

      // Update order status to cancelled
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .update({
        'status': 'cancelled',
        'cancellationReason': cancellationReason ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reset item status back to Available
      if (itemId != null) {
        await FirebaseFirestore.instance
            .collection('Items')
            .doc(itemId)
            .update({'status': 'Available'});
      }

      await _fetchOrders();
    }
  }

  Future<void> _markAsSold(String orderId, Map<String, dynamic> order) async {
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmSale),
        content: Text(AppLocalizations.of(context).confirmSaleMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              confirmed = true;
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );

    if (confirmed) {
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .update({
        'status': 'sold',
        'sellerConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update item status to sold
      final itemId = order['itemId'];
      if (itemId != null) {
        await FirebaseFirestore.instance
            .collection('Items')
            .doc(itemId)
            .update({'status': 'Sold'});
      }

      await _fetchOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).sold),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _showReviewDialog(Map<String, dynamic> order) async {
    int rating = 5;
    String reviewText = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context).writeReview),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).rateYourExperience),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => reviewText = value,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).reviewPlaceholder,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, size: 16),
                  const SizedBox(width: 4),
                  Text(AppLocalizations.of(context).skipReview),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _submitReview(order, rating, reviewText);
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).submitReview),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(Map<String, dynamic> order, int rating, String reviewText) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final reviewData = {
        'reviewerId': currentUser.uid,
        'sellerId': order['sellerId'],
        'orderId': order['id'],
        'itemId': order['itemId'],
        'rating': rating,
        'reviewText': reviewText.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add review to Reviews collection
      await FirebaseFirestore.instance.collection('Reviews').add(reviewData);

      // Update seller's rating
      await _updateSellerRating(order['sellerId'], rating);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).reviewSubmitted),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _updateSellerRating(String sellerId, int newRating) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(sellerId)
          .get();

      final userData = userDoc.data() ?? {};
      final currentRating = userData['average_rating'] ?? 0.0;
      final numReviewers = userData['num_of_reviewers'] ?? 0;

      // Calculate new average rating
      final totalRating = (currentRating * numReviewers) + newRating;
      final newNumReviewers = numReviewers + 1;
      final newAverageRating = totalRating / newNumReviewers;

      // Update user's rating data
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(sellerId)
          .update({
        'average_rating': newAverageRating,
        'num_of_reviewers': newNumReviewers,
      });
    } catch (e) {
      debugPrint('Error updating seller rating: $e');
    }
  }

  Future<void> _showBuyerReceiptConfirmation(Map<String, dynamic> order) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).confirmPurchase),
        content: Text(AppLocalizations.of(context).sellerMarkedAsSold),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Report issue - change status to reported
              await _reportIssue(order);
            },
            child: Text(AppLocalizations.of(context).iDidNotReceiveItem),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Confirm receipt - show review dialog
              await _confirmItemReceipt(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(AppLocalizations.of(context).iReceivedItem),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmItemReceipt(Map<String, dynamic> order) async {
    // Update order status to completed (final state)
    await FirebaseFirestore.instance
        .collection('Orders')
        .doc(order['id'])
        .update({
      'status': 'completed',
      'buyerConfirmedReceiptAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _fetchOrders();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).purchaseConfirmed),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );

    // Show review dialog
    _showReviewDialog(order);
  }

  Future<void> _reportIssue(Map<String, dynamic> order) async {
    // Update order status to reported
    await FirebaseFirestore.instance
        .collection('Orders')
        .doc(order['id'])
        .update({
      'status': 'reported',
      'issueReportedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _fetchOrders();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).issueReported),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showOrderActions(Map<String, dynamic> order, List<PopupMenuEntry<String>> menuItems) {
    if (menuItems.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).actions,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...menuItems.map((item) {
              if (item is PopupMenuItem<String>) {
                return ListTile(
                  leading: (item.child as Row).children[0] as Icon,
                  title: Text(((item.child as Row).children[2] as Text).data!),
                  onTap: () {
                    Navigator.pop(context);
                    _handleOrderAction(order['id'], item.value!, order);
                  },
                );
              }
              return const SizedBox.shrink();
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ------------------ BUILD INCOMING TABLE ------------------
  Widget _buildIncomingOrdersTable() {
    if (incomingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noIncomingOrders,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms);
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        controller: _incomingScrollController,
        child: Column(
          children: incomingOrders.map((order) {
            return InkWell(
              onTap: () => _showOrderActions(order, _buildBuyerActionMenu(order)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Item image (not clickable for actions)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemPage(itemId: order['itemId']),
                              ),
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            child: order['itemImage'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: order['itemImage'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Theme.of(context).colorScheme.surfaceVariant,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 30,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      size: 30,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Order details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Seller name (first row)
                              Text(
                                order['sellerName'] ?? 'Unknown',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Item name (second row)
                              Text(
                                order['itemName'] ?? 'Unknown Item',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Price and status (third row)
                              Row(
                                children: [
                                  Text(
                                    '\₪${(order['price'] ?? 0).toInt()}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(order['status']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        TranslationUtils.getOrderStatus(order['status'], context),
                                        style: TextStyle(
                                          color: _getStatusColor(order['status']),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Communication buttons
                        _buildCommunicationButtons(order, true),
                      ],
                    ),
                    // Message section (shows process steps, time slots, cancellation reasons, etc.)
                    const SizedBox(height: 12),
                    _buildMessageSection(order, isBuyerView: true),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ------------------ BUILD OUTGOING TABLE ------------------
  Widget _buildOutgoingOrdersTable() {
    if (outgoingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noOutgoingOrders,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms);
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        controller: _outgoingScrollController,
        child: Column(
          children: outgoingOrders.map((order) {
            return InkWell(
              onTap: () => _showOrderActions(order, _buildOrderActionMenu(order)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Item image (not clickable for actions)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemPage(itemId: order['itemId']),
                              ),
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            child: order['itemImage'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: order['itemImage'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Theme.of(context).colorScheme.surfaceVariant,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 30,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      size: 30,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Order details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Buyer name (first row)
                              Text(
                                order['buyerName'] ?? 'Unknown',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Item name (second row)
                              Text(
                                order['itemName'] ?? 'Unknown Item',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Price and status (third row)
                              Row(
                                children: [
                                  Text(
                                    '\₪${(order['price'] ?? 0).toInt()}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(order['status']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        TranslationUtils.getOrderStatus(order['status'], context),
                                        style: TextStyle(
                                          color: _getStatusColor(order['status']),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Communication buttons
                        _buildCommunicationButtons(order, false),
                      ],
                    ),
                    // Message section (shows process steps, time slots, cancellation reasons, etc.)
                    const SizedBox(height: 12),
                    _buildMessageSection(order, isBuyerView: false),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildMessageSection(Map<String, dynamic> order, {bool isBuyerView = false}) {
    final selectedTimeSlot = order['selectedTimeSlot'];
    final status = order['status'];
    
    // Check status first - cancelled and declined orders should show reasons, not time slots
    if (status == 'cancelled') {
      final cancellationReason = order['cancellationReason'] ?? '';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              size: 16,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).orderCancelled,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).reasonForCancellation,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cancellationReason.isNotEmpty 
                        ? cancellationReason 
                        : AppLocalizations.of(context).noReasonProvided,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade600,
                      fontStyle: cancellationReason.isNotEmpty 
                          ? FontStyle.italic 
                          : FontStyle.normal,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (status == 'declined') {
      final declineReason = order['declineReason'] ?? '';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.thumb_down_outlined,
              size: 16,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).orderDeclined,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).reasonForDeclining,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    declineReason.isNotEmpty 
                        ? declineReason 
                        : AppLocalizations.of(context).noReasonProvided,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade600,
                      fontStyle: declineReason.isNotEmpty 
                          ? FontStyle.italic 
                          : FontStyle.normal,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (status == 'reported') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.report_problem,
              size: 16,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).reported,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'completed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.celebration,
              size: 16,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).enjoyMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'sold') {
      if (isBuyerView) {
        // For buyers - show waiting for your confirmation message
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notification_important,
                size: 16,
                color: Colors.purple.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).confirmReceiptOfItem,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).tapToConfirmReceipt,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.purple.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        // For sellers - show that item was marked as sold, waiting for buyer approval
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 16,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).sold,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).awaitingBuyerToConfirm,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }
    // Now check for time slots and other statuses
    else if (selectedTimeSlot != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).timeSlotConfirmed,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    selectedTimeSlot['formatted'] ?? '-',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (status == 'pending_buyer') {
      if (isBuyerView) {
        // For buyers - clickable to select time
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to time selection for buyer
              _selectPickupTime(order['id'], order);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).orderApproved,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // For sellers - just informational
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 16,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).awaitingTimeSelection,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    } else if (status == 'pending_seller') {
      if (isBuyerView) {
        // For buyers - show that they're waiting for seller approval
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 16,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).pendingSellerApproval,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        // For sellers - show that they need to respond
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.pending_actions,
                size: 16,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).sellerNeedsToRespond,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    } else if (status == 'confirmed' || status == 'Purchase Confirmed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).timeSlotConfirmed,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'awaiting_buyer_confirmation') {
      if (isBuyerView) {
        // For buyers - just informational
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 16,
                color: Colors.teal.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).awaitingBuyerToConfirm,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        // For sellers - just informational
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 16,
                color: Colors.teal.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).awaitingBuyerToConfirm,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '-',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
  }

  List<PopupMenuEntry<String>> _buildOrderActionMenu(Map<String, dynamic> order) {
    List<PopupMenuEntry<String>> menuItems = [];

    switch (order['status']) {
      case 'pending_seller':
        menuItems.addAll([
          PopupMenuItem(
            value: 'Accept',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).acceptOrder),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'Decline',
            child: Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).declineOrder),
              ],
            ),
          ),
        ]);
        break;
      case 'pending_buyer':
        // Show message that we're waiting for buyer
        break;
      case 'confirmed':
      case 'Purchase Confirmed':
        menuItems.add(
          PopupMenuItem(
            value: 'MarkAsSold',
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).markAsSold),
              ],
            ),
          ),
        );
        break;
    }

    // Add cancel option for active orders, but not for pending_seller (sellers should accept/decline)
    if (!['cancelled', 'completed', 'declined', 'pending_seller', 'sold'].contains(order['status'])) {
      menuItems.add(
        PopupMenuItem(
          value: 'Cancel',
          child: Row(
            children: [
              Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).cancelOrder),
            ],
          ),
        ),
      );
    }

    return menuItems;
  }

  List<PopupMenuEntry<String>> _buildBuyerActionMenu(Map<String, dynamic> order) {
    List<PopupMenuEntry<String>> menuItems = [];

    switch (order['status']) {
      case 'pending_buyer':
        menuItems.add(
          PopupMenuItem(
            value: 'SelectTime',
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).selectPickupTime),
              ],
            ),
          ),
        );
        break;
      case 'sold':
        menuItems.addAll([
          PopupMenuItem(
            value: 'ConfirmItemReceipt',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).iReceivedItem),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'ReportIssue',
            child: Row(
              children: [
                Icon(
                  Icons.report_problem,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).iDidNotReceiveItem),
              ],
            ),
          ),
        ]);
        break;
    }

    // Add cancel option for all active orders (buyers can cancel anytime)
    if (!['cancelled', 'completed', 'declined', 'sold', 'reported'].contains(order['status'])) {
      menuItems.add(
        PopupMenuItem(
          value: 'Cancel',
          child: Row(
            children: [
              Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).cancelOrder),
            ],
          ),
        ),
      );
    }

    return menuItems;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending_seller':
        return Colors.orange;
      case 'approved':
      case 'pending_buyer':
        return Colors.blue;
      case 'confirmed':
      case 'time_slot_confirmed':
      case 'purchase confirmed':
      case 'ready_for_pickup':
        return Colors.blue;
      case 'awaiting_buyer_confirmation':
        return Colors.teal;
      case 'sold':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'reported':
        return Colors.red;
      case 'declined':
      case 'cancelled':
        return Colors.red;
      case 'shipped':
      case 'awaiting_seller_response':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  // ------------------ MAIN BUILD ------------------
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            // Custom tab bar without AppBar
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                dividerColor: Colors.transparent,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: -16.0, vertical: -8.0),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(
                    height: 60,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    text: AppLocalizations.of(context).buyer,
                  ),
                  Tab(
                    height: 60,
                    icon: const Icon(Icons.store_outlined),
                    text: AppLocalizations.of(context).seller,
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context).loading,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms)
                  : TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildIncomingOrdersTable(),
                        _buildOutgoingOrdersTable(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Public method to refresh orders from external calls
  Future<void> refreshOrders() async {
    await _fetchOrders();
  }

  /// Fetch item details from Items collection
  Future<Map<String, String>> fetchItemDetails(String? itemId) async {
    if (itemId == null || itemId.isEmpty) {
      return {
        'brand': 'Unknown Brand',
        'type': 'Unknown Type', 
        'color': 'Unknown Color',
        'size': 'Unknown Size',
      };
    }

    try {
      final itemDoc = await FirebaseFirestore.instance
          .collection('Items')
          .doc(itemId)
          .get();
      
      if (itemDoc.exists) {
        final data = itemDoc.data()!;
        
        final result = {
          'brand': data['Brand']?.toString() ?? 'Unknown Brand',
          'type': data['Type']?.toString() ?? 'Unknown Type',
          'color': data['Color']?.toString() ?? 'Unknown Color',
          'size': data['Size']?.toString() ?? 'Unknown Size',
        };
        
        return result;
      }
    } catch (e) {
      debugPrint('Error fetching item details: $e');
    }
    
    return {
      'brand': 'Unknown Brand',
      'type': 'Unknown Type',
      'color': 'Unknown Color',
      'size': 'Unknown Size',
    };
  }

  /// Build communication buttons (phone and WhatsApp)
  Widget _buildCommunicationButtons(Map<String, dynamic> order, bool isBuyerView) {
    if (!shouldShowCommunicationButtons(order, isBuyerView)) {
      return const SizedBox.shrink();
    }

    final targetUserId = isBuyerView ? order['sellerId'] : order['buyerId'];
    final itemName = order['itemName'] ?? 'Unknown Item';
    final itemId = order['itemId'];

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        fetchUserPhone(targetUserId),
        fetchItemDetails(itemId),
      ]),
      builder: (context, snapshot) {
        final phoneNumber = snapshot.data?[0] as String?;
        final itemDetails = snapshot.data?[1] as Map<String, String>? ?? {
          'brand': 'Unknown Brand',
          'type': 'Unknown Type',
          'color': 'Unknown Color',
          'size': 'Unknown Size',
        };
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Phone call button
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => CommunicationService.makePhoneCall(context, phoneNumber),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.phone,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ),
            ),
            // WhatsApp button
            Container(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => CommunicationService.openWhatsAppChat(
                    context,
                    phoneNumber,
                    itemName,
                    itemDetails['brand']!,
                    itemDetails['type']!,
                    itemDetails['color']!,
                    itemDetails['size']!,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.message,
                      size: 16,
                      color: const Color(0xFF25D366),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
