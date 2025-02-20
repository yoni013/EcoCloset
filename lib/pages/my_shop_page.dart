import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../generated/l10n.dart';
import 'item_page.dart';

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

  @override
  void initState() {
    super.initState();
    // 2 tabs: Incoming & Outgoing
    _tabController = TabController(length: 2, vsync: this);
    fetchIncomingOrders();
    fetchOutgoingOrders();

    // Listen to vertical scroll controllers so we know when to display the "go up" button
    _incomingScrollController.addListener(() {
      if (_incomingScrollController.position.pixels > 50 &&
          !_showIncomingScrollUp) {
        setState(() => _showIncomingScrollUp = true);
      } else if (_incomingScrollController.position.pixels < 50 &&
          _showIncomingScrollUp) {
        setState(() => _showIncomingScrollUp = false);
      }
    });
    _outgoingScrollController.addListener(() {
      if (_outgoingScrollController.position.pixels > 50 &&
          !_showOutgoingScrollUp) {
        setState(() => _showOutgoingScrollUp = true);
      } else if (_outgoingScrollController.position.pixels < 50 &&
          _showOutgoingScrollUp) {
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
  Future<void> fetchIncomingOrders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('BuyerID', isEqualTo: userId)
          .get();

      final List<Map<String, dynamic>> fetched = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final sellerId = data['SellerID'] as String? ?? '';
        final itemId = data['ItemID'] as String? ?? '';
        final price = data['FinalPrice'] ?? 0;
        final status = data['Status'] ?? 'Pending';

        final sellerName = await fetchUserName(sellerId);
        final itemImageUrl = doc['Preview'];

        fetched.add({
          'orderId': doc.id,
          'itemImage': itemImageUrl,
          'sellerName': sellerName,
          'price': price,
          'status': status,
          'itemId': itemId,
        });
      }

      if (mounted) {
        setState(() {
          incomingOrders = fetched;
        });
      }
    } catch (e) {
      debugPrint('Error fetching incoming orders: $e');
    }
  }

  /// Outgoing Orders => current user is the Seller
  Future<void> fetchOutgoingOrders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('SellerID', isEqualTo: userId)
          .get();

      final List<Map<String, dynamic>> fetched = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final buyerId = data['BuyerID'] as String? ?? '';
        final itemId = data['ItemID'] as String? ?? '';
        final price = data['FinalPrice'] ?? 0;
        final status = data['Status'] ?? 'Pending';

        final buyerName = await fetchUserName(buyerId);
        final itemImageUrl = doc['Preview'];

        fetched.add({
          'orderId': doc.id,
          'itemImage': itemImageUrl,
          'buyerName': buyerName,
          'price': price,
          'status': status,
          'itemId': itemId,
        });
      }

      if (mounted) {
        setState(() {
          outgoingOrders = fetched;
        });
      }
    } catch (e) {
      debugPrint('Error fetching outgoing orders: $e');
    }
  }

  // (Optional) function if you want to update status
  Future<void> updateOrderStatus(
      String orderId, String newStatus, bool incoming) async {
    try {
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .update({'Status': newStatus});
      incoming ? fetchIncomingOrders() : fetchOutgoingOrders();
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  // ------------------ BUILD INCOMING TABLE ------------------
  Widget _buildIncomingOrdersTable() {
    // "Incoming" = I am the buyer
    // In real code, you'd fetch from Firestore or similar
    if (incomingOrders.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noIncomingOrders));
    }

    // Wrapping in a Stack so we can position a "Scroll Up" button
    return Stack(
      children: [
        // Scrollable DataTable2
        DataTable2(
          // Attach controllers for vertical & horizontal scroll
          scrollController: _incomingScrollController,
          horizontalScrollController: _incomingHorizontalController,

          // Sizing
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 600,

          // Define columns
          columns: [
            DataColumn2(
                label: Text(AppLocalizations.of(context).item), size: ColumnSize.S, fixedWidth: 50),
            DataColumn2(
                label: Text(AppLocalizations.of(context).seller), size: ColumnSize.S, fixedWidth: 100),
            DataColumn2(
                label: Text(AppLocalizations.of(context).price),
                numeric: true,
                size: ColumnSize.S,
                fixedWidth: 100),
            DataColumn2(
                label: Text(AppLocalizations.of(context).status), size: ColumnSize.S, fixedWidth: 100),
          ],

          // Generate rows from data
          rows: incomingOrders.map((order) {
            final itemImage = order['itemImage'] as String?;
            final sellerName = order['sellerName'] as String;
            final price = order['price'] as num;
            final status = order['status'] as String;

            return DataRow(cells: [
              DataCell(
                GestureDetector(
                  onTap: () {
                    // Open ItemPage when tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemPage(itemId: order['itemId']),
                      ),
                    );
                  },
                  child: itemImage != null && itemImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: itemImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.image_not_supported),
                ),
              ),
              DataCell(Text(sellerName)),
              DataCell(Text('\₪${price.toStringAsFixed(0)}')),
              DataCell(Text(status)),
            ]);
          }).toList(),
        ),
        // Optional: "Scroll up" button in bottom-right
        if (_showIncomingScrollUp)
          Positioned(
            right: 16,
            bottom: 16,
            child: OutlinedButton(
              onPressed: () {
                _incomingScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.grey[800]),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              child: const Text('↑ Go Up ↑'),
            ),
          ),
      ],
    );
  }

  // ------------------ BUILD OUTGOING TABLE ------------------
  Widget _buildOutgoingOrdersTable() {
    // "Outgoing" = I am the seller
    if (outgoingOrders.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noOutgoingOrders));
    }

    return Stack(
      children: [
        DataTable2(
          scrollController: _outgoingScrollController,
          horizontalScrollController: _outgoingHorizontalController,
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 600,
          columns: [
            DataColumn2(
                label: Text(AppLocalizations.of(context).item), size: ColumnSize.S, fixedWidth: 50),
            DataColumn2(
                label: Text(AppLocalizations.of(context).buyer), size: ColumnSize.S, fixedWidth: 80),
            DataColumn2(
                label: Text(AppLocalizations.of(context).price),
                numeric: true,
                size: ColumnSize.S,
                fixedWidth: 50),
            DataColumn2(
                label: Text(AppLocalizations.of(context).status), size: ColumnSize.S, fixedWidth: 80),
            DataColumn2(
                label: Text(AppLocalizations.of(context).actions), size: ColumnSize.S, fixedWidth: 70),
          ],
          rows: outgoingOrders.map((order) {
            final itemImage = order['itemImage'] as String?;
            final buyerName = order['buyerName'] as String;
            final price = order['price'] as num;
            final status = order['status'] as String;

            return DataRow(cells: [
              DataCell(
                GestureDetector(
                  onTap: () {
                    // Open ItemPage when tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemPage(itemId: order['itemId']),
                      ),
                    );
                  },
                  child: itemImage != null && itemImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: itemImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.image_not_supported),
                ),
              ),
              DataCell(Text(buyerName)),
              DataCell(Text('\₪${price.toStringAsFixed(0)}')),
              DataCell(Text(status)),
              DataCell(PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'approve') {
                    updateOrderStatus(order['orderId'], 'Approved', false);
                  } else if (value == 'decline') {
                    updateOrderStatus(order['orderId'], 'Declined', false);
                  } else if (value == 'shipped') {
                    updateOrderStatus(order['orderId'], 'Shipped', false);
                  }
                },
                itemBuilder: (context) {
                  final List<PopupMenuEntry<String>> options = [];
                  if (order['status'] == 'Pending') {
                    options.add(const PopupMenuItem(
                        value: 'approve', child: Text('Approve')));
                    options.add(const PopupMenuItem(
                        value: 'decline', child: Text('Decline')));
                  } else if (order['Status'] == 'Approved') {
                    options.add(const PopupMenuItem(
                        value: 'shipped', child: Text('Mark as Shipped')));
                  }
                  return options;
                },
                icon: const Icon(Icons.more_vert),
              )),
            ]);
          }).toList(),
        ),
        // Optional "Scroll up" button
        if (_showOutgoingScrollUp)
          Positioned(
            right: 16,
            bottom: 16,
            child: OutlinedButton(
              onPressed: () {
                _outgoingScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.grey[800]),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              child: const Text('↑ Go Up ↑'),
            ),
          ),
      ],
    );
  }

  // ------------------ MAIN BUILD ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).myOrders),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context).incomingOrders),
            Tab(text: AppLocalizations.of(context).outgoingOrders),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1) INCOMING ORDERS
          _buildIncomingOrdersTable(),

          // 2) OUTGOING ORDERS
          _buildOutgoingOrdersTable(),
        ],
      ),
    );
  }
}
