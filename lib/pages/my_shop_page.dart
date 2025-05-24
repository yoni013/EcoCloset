import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../generated/l10n.dart';
import 'item_page.dart';
import 'package:eco_closet/utils/translation_metadata.dart';
import '../widgets/time_availability_selector.dart';
import '../widgets/buyer_time_selector.dart';

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
  final ScrollController _incomingHorizontalController = ScrollController();

  final ScrollController _outgoingScrollController = ScrollController();
  final ScrollController _outgoingHorizontalController = ScrollController();

  // Track whether we show the "Scroll to top" button.
  bool _showIncomingScrollUp = false;
  bool _showOutgoingScrollUp = false;

  bool isLoading = true;

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incomingScrollController.dispose();
    _incomingHorizontalController.dispose();
    _outgoingScrollController.dispose();
    _outgoingHorizontalController.dispose();
    super.dispose();
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
        case 'AcknowledgeTime':
          await _acknowledgeTimeSlot(orderId);
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
      'status': 'awaiting_seller_response',
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
              await FirebaseFirestore.instance
                  .collection('Orders')
                  .doc(orderId)
                  .update({
                'status': 'declined',
                'declineReason': declineReason ?? '',
                'updatedAt': FieldValue.serverTimestamp(),
              });
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
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .update({
        'status': 'cancelled',
        'cancellationReason': cancellationReason ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _fetchOrders();
    }
  }

  Future<void> _acknowledgeTimeSlot(String orderId) async {
    await FirebaseFirestore.instance
        .collection('Orders')
        .doc(orderId)
        .update({
      'lastAction': 'seller_acknowledged',
      'sellerAcknowledgedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).timeSlotAcknowledged),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );

    await _fetchOrders();
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
        child: SingleChildScrollView(
          controller: _incomingHorizontalController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text(AppLocalizations.of(context).item)),
              DataColumn(label: Text(AppLocalizations.of(context).seller)),
              DataColumn(label: Text(AppLocalizations.of(context).price)),
              DataColumn(label: Text(AppLocalizations.of(context).status)),
              DataColumn(label: Text(AppLocalizations.of(context).pickupTime)),
              DataColumn(label: Text(AppLocalizations.of(context).actions)),
            ],
            rows: incomingOrders.map((order) {
              return DataRow(
                cells: [
                  DataCell(
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
                        width: 40,
                        height: 40,
                        child: order['itemImage'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: order['itemImage'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.image,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                  ),
                  DataCell(Text(order['sellerName'] ?? 'Unknown')),
                  DataCell(Text('\₪${(order['price'] ?? 0).toInt()}')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        TranslationUtils.getOrderStatus(order['status'], context),
                        style: TextStyle(
                          color: _getStatusColor(order['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    _buildPickupTimeCell(order),
                  ),
                  DataCell(
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleOrderAction(order['id'], value, order),
                      itemBuilder: (context) => _buildBuyerActionMenu(order),
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
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
        child: SingleChildScrollView(
          controller: _outgoingHorizontalController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text(AppLocalizations.of(context).item)),
              DataColumn(label: Text(AppLocalizations.of(context).buyer)),
              DataColumn(label: Text(AppLocalizations.of(context).price)),
              DataColumn(label: Text(AppLocalizations.of(context).status)),
              DataColumn(label: Text(AppLocalizations.of(context).pickupTime)),
              DataColumn(label: Text(AppLocalizations.of(context).actions)),
            ],
            rows: outgoingOrders.map((order) {
              return DataRow(
                cells: [
                  DataCell(
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
                        width: 40,
                        height: 40,
                        child: order['itemImage'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: order['itemImage'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.image,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                  ),
                  DataCell(Text(order['buyerName'] ?? 'Unknown')),
                  DataCell(Text('\₪${(order['price'] ?? 0).toInt()}')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        TranslationUtils.getOrderStatus(order['status'], context),
                        style: TextStyle(
                          color: _getStatusColor(order['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    _buildPickupTimeCell(order),
                  ),
                  DataCell(
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleOrderAction(order['id'], value, order),
                      itemBuilder: (context) => _buildOrderActionMenu(order),
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPickupTimeCell(Map<String, dynamic> order) {
    final selectedTimeSlot = order['selectedTimeSlot'];
    final lastAction = order['lastAction'];
    final isNewBuyerAction = lastAction == 'buyer_selected_time';
    
    if (selectedTimeSlot != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isNewBuyerAction 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: isNewBuyerAction 
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNewBuyerAction ? Icons.notification_important : Icons.schedule,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    isNewBuyerAction ? AppLocalizations.of(context).newStatus : AppLocalizations.of(context).timeSlotConfirmed.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              selectedTimeSlot['formatted'] ?? 'N/A',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: isNewBuyerAction ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (isNewBuyerAction)
              Text(
                AppLocalizations.of(context).timeSlotSelected,
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      );
    } else if (order['status'] == 'awaiting_buyer_time_selection') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 12,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).loading.replaceAll('...', ''),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              AppLocalizations.of(context).awaitingBuyerTimeSelection,
              style: TextStyle(
                fontSize: 9,
                color: Colors.orange.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else if (order['status'] == 'time_slot_confirmed') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          AppLocalizations.of(context).timeSlotConfirmed,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '-',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
  }

  List<PopupMenuEntry<String>> _buildOrderActionMenu(Map<String, dynamic> order) {
    List<PopupMenuEntry<String>> menuItems = [];

    switch (order['status']) {
      case 'Pending':
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
      case 'awaiting_seller_response':
        menuItems.add(
          PopupMenuItem(
            value: 'SetAvailability',
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).selectAvailableHours),
              ],
            ),
          ),
        );
        break;
      case 'time_slot_confirmed':
        break;
    }

    // Add acknowledge action for new buyer confirmations
    if (order['lastAction'] == 'buyer_selected_time') {
      menuItems.add(
        PopupMenuItem(
          value: 'AcknowledgeTime',
          child: Row(
            children: [
              Icon(
                Icons.visibility,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).acknowledgeTimeSlot),
            ],
          ),
        ),
      );
    }

    // Add cancel option for all active orders
    if (!['cancelled', 'completed', 'declined'].contains(order['status'])) {
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
      case 'awaiting_buyer_time_selection':
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
    }

    // Add cancel option for all active orders
    if (!['cancelled', 'completed', 'declined'].contains(order['status'])) {
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
        return Colors.orange;
      case 'approved':
      case 'awaiting_buyer_time_selection':
        return Colors.blue;
      case 'time_slot_confirmed':
      case 'ready_for_pickup':
        return Colors.green;
      case 'declined':
      case 'cancelled':
        return Colors.red;
      case 'shipped':
      case 'awaiting_seller_response':
        return Colors.indigo;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ------------------ MAIN BUILD ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).myOrders,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
            tooltip: AppLocalizations.of(context).refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_bag_outlined),
              text: AppLocalizations.of(context).incomingOrders,
            ),
            Tab(
              icon: const Icon(Icons.store_outlined),
              text: AppLocalizations.of(context).outgoingOrders,
            ),
          ],
        ),
      ),
      body: Container(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final controller = _tabController.index == 0
              ? _incomingScrollController
              : _outgoingScrollController;
          controller.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: const Icon(Icons.arrow_upward),
      ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
            begin: 0.2,
            end: 0,
            duration: 600.ms,
            curve: Curves.easeOutQuad,
          ),
    );
  }
}
