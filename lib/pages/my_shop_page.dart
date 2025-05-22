import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../generated/l10n.dart';
import 'item_page.dart';
import 'package:eco_closet/utils/translation_metadata.dart';

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
  Future<void> _fetchOrders() async {
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

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      setState(() => isLoading = false);
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
        child: DataTable(
          columns: [
            DataColumn(label: Text(AppLocalizations.of(context).orderId)),
            DataColumn(label: Text(AppLocalizations.of(context).seller)),
            DataColumn(label: Text(AppLocalizations.of(context).item)),
            DataColumn(label: Text(AppLocalizations.of(context).price)),
            DataColumn(label: Text(AppLocalizations.of(context).status)),
          ],
          rows: incomingOrders.map((order) {
            return DataRow(
              cells: [
                DataCell(Text(order['id'])),
                DataCell(Text(order['sellerName'] ?? 'Unknown')),
                DataCell(Text(order['itemName'] ?? 'Unknown')),
                DataCell(Text('\₪${order['price'] ?? '0'}')),
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
              ],
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
        child: DataTable(
          columns: [
            DataColumn(label: Text(AppLocalizations.of(context).orderId)),
            DataColumn(label: Text(AppLocalizations.of(context).buyer)),
            DataColumn(label: Text(AppLocalizations.of(context).item)),
            DataColumn(label: Text(AppLocalizations.of(context).price)),
            DataColumn(label: Text(AppLocalizations.of(context).status)),
            DataColumn(label: Text(AppLocalizations.of(context).actions)),
          ],
          rows: outgoingOrders.map((order) {
            return DataRow(
              cells: [
                DataCell(Text(order['id'])),
                DataCell(Text(order['buyerName'] ?? 'Unknown')),
                DataCell(Text(order['itemName'] ?? 'Unknown')),
                DataCell(Text('\₪${order['price'] ?? '0'}')),
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
                  PopupMenuButton<String>(
                    onSelected: (value) => _updateOrderStatus(order['id'], value),
                    itemBuilder: (context) => [
                      if (order['status'] == 'Pending')
                        PopupMenuItem(
                          value: 'Approved',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context).approve),
                            ],
                          ),
                        ),
                      if (order['status'] == 'Pending')
                        PopupMenuItem(
                          value: 'Declined',
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context).decline),
                            ],
                          ),
                        ),
                      if (order['status'] == 'Approved')
                        PopupMenuItem(
                          value: 'Shipped',
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context).markAsShipped),
                            ],
                          ),
                        ),
                    ],
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
    ).animate().fadeIn(duration: 600.ms);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'shipped':
        return Colors.blue;
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
