/// item_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:eco_closet/pages/edit_item_page.dart';
import 'package:eco_closet/utils/translation_metadata.dart';
import 'package:eco_closet/widgets/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/pages/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../generated/l10n.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eco_closet/utils/image_handler.dart';
import 'package:provider/provider.dart';
import 'package:eco_closet/services/order_notification_service.dart';
import 'package:eco_closet/services/content_moderation_service.dart';

class ItemPage extends StatefulWidget {
  final String itemId;

  ItemPage({required this.itemId});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  late Future<Map<String, dynamic>> _itemDataFuture;
  bool _isPurchaseRequestSent = false;

  @override
  void initState() {
    super.initState();
    _itemDataFuture = fetchItemData();
    _checkItemStatus();
  }

  Future<Map<String, dynamic>> fetchItemData() async {
    var documentSnapshot =
        await FirebaseFirestore.instance.collection('Items').doc(widget.itemId).get();
    return documentSnapshot.data() ?? {};
  }

  Future<Map<String, dynamic>> fetchSellerData(String sellerId) async {
    var documentSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(sellerId)
        .get();
    return documentSnapshot.data() ?? {};
  }

  Future<void> _checkItemStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Check if there's already a pending order for this item by this user
      final orderQuery = await FirebaseFirestore.instance
          .collection('Orders')
          .where('itemId', isEqualTo: widget.itemId)
          .where('buyerId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending_seller')
          .limit(1)
          .get();

      if (orderQuery.docs.isNotEmpty) {
        setState(() {
          _isPurchaseRequestSent = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking item status: $e');
    }
  }

  void _openFullScreenViewer(List<dynamic> images, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullScreenImageViewer(
          images: images.cast<String>(),
          initialIndex: index,
          heroTag: 'item_${widget.itemId}_$index',
        ),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        opaque: false,
        barrierColor: Colors.transparent,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.8;
          const end = 1.0;
          const curve = Curves.easeOutCubic;

          var scaleAnimation = Tween(begin: begin, end: end).animate(
            CurvedAnimation(parent: animation, curve: curve),
          );

          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          );

          return ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPurchaseConfirmation(Map<String, dynamic> itemData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Purchase'),
          content: const Text('Are you sure? Seller will be notified'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _createPurchaseRequest(itemData);
    }
  }

  Future<void> _createPurchaseRequest(Map<String, dynamic> itemData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseLoginToPurchase),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Set button state to loading
    setState(() {
      _isPurchaseRequestSent = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create the order in Firestore
      await FirebaseFirestore.instance.collection('Orders').add({
        'buyerId': currentUser.uid,
        'sellerId': itemData['seller_id'],
        'itemId': widget.itemId,
        'itemName': itemData['item_name'] ?? 'Unknown Item',
        'price': itemData['Price'] ?? 0,
        'status': 'pending_seller',
        'createdAt': FieldValue.serverTimestamp(),
        'sellerAddress': '', // Will be filled when seller accepts
        'availableTimeSlots': [],
        'selectedTimeSlot': null,
        'buyerMessage': '',
        'sellerMessage': '',
        'declineReason': null,
        'cancellationReason': null,
        'itemImage': (itemData['images'] as List?)?.isNotEmpty == true 
            ? itemData['images'][0] 
            : null,
      });

      // Update item status to "Pending Seller"
      await FirebaseFirestore.instance
          .collection('Items')
          .doc(widget.itemId)
          .update({'status': 'Pending Seller'});

      // Send push notification to seller if enabled
      await _sendPushNotificationToSeller(itemData['seller_id']);

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Refresh notification service to update my_shop page automatically
      try {
        final orderService = Provider.of<OrderNotificationService>(context, listen: false);
        orderService.notifyOrdersChanged(); // Manually trigger notification for immediate update
      } catch (e) {
        debugPrint('OrderNotificationService not available: $e');
      }

      // Show success popup dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Amazing!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'The seller was notified that you want to buy this item, now wait for him to mark the hours he is available for you to come and pick it up',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Cool'),
            ),
          ],
        ),
      );

    } catch (e) {
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      
      // Reset button state
      setState(() {
        _isPurchaseRequestSent = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).errorCreatingPurchaseRequest}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _sendPushNotificationToSeller(String sellerId) async {
    try {
      // Check if seller has push notifications enabled
      final sellerDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(sellerId)
          .get();
      
      final sellerData = sellerDoc.data();
      if (sellerData != null && sellerData['enablePushNotifications'] == true) {
        // Here you would implement the actual push notification sending
        // For now, we'll just log it since the actual implementation would require
        // Firebase Cloud Functions or a backend service
        debugPrint('Would send push notification to seller: $sellerId');
        debugPrint('Notification: New purchase request for your item!');
        
        // You could also store a notification in Firestore for the seller
        await FirebaseFirestore.instance.collection('Notifications').add({
          'userId': sellerId,
          'title': 'New purchase request for your item!',
          'message': 'A buyer is interested in your item',
          'type': 'purchase_request',
          'itemId': widget.itemId,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      // Don't throw error as this is not critical for the purchase flow
    }
  }

  void _refreshItemData() {
    setState(() {
      _itemDataFuture = fetchItemData();
    });
    _checkItemStatus();
  }

  /// Show report dialog for inappropriate content
  Future<void> _showReportDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final reasons = [
      'Inappropriate content',
      'Fake or counterfeit item',
      'Misleading description',
      'Offensive language',
      'Spam or scam',
      'Other'
    ];

    String? selectedReason;
    final TextEditingController detailsController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report Item'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why are you reporting this item?'),
                const SizedBox(height: 16),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
                if (selectedReason == 'Other') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Please specify',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedReason != null
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedReason != null) {
      try {
        await ContentModerationService().reportContent(
          itemId: widget.itemId,
          reporterId: currentUser.uid,
          reason: selectedReason!,
          additionalDetails: selectedReason == 'Other' 
              ? detailsController.text.trim()
              : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your report. We will review it shortly.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _itemDataFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && currentUserId != null) {
                final isOwner = snapshot.data!['seller_id'] == currentUserId;
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show report button for non-owners
                    if (!isOwner)
                      IconButton(
                        icon: const Icon(Icons.flag),
                        onPressed: () => _showReportDialog(),
                        tooltip: 'Report inappropriate content',
                      ),
                    // Show edit button for owners
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditItemPage(
                                itemId: widget.itemId,
                              ),
                            ),
                          );
                          
                          // Refresh the item data if the edit was successful
                          if (result != null && result['needsRefresh'] == true) {
                            _refreshItemData();
                          }
                        },
                      ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _itemDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context).failedToLoadItem));
          }

          var itemData = snapshot.data!;
          var images = itemData['images'] as List<dynamic>? ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    if (images.isEmpty)
                      Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Stack(
                          children: [
                            PageView.builder(
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    _openFullScreenViewer(images, index);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: Hero(
                                      tag: 'item_${widget.itemId}_$index',
                                      child: CachedNetworkImage(
                                        imageUrl: images[index],
                                        fit: BoxFit.cover,
                                        httpHeaders: kIsWeb ? const {
                                          'Access-Control-Allow-Origin': '*',
                                        } : null,
                                        placeholder: (context, url) => Container(
                                          color: Theme.of(context).colorScheme.surfaceVariant,
                                          child: const Center(child: CircularProgressIndicator()),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: Theme.of(context).colorScheme.surfaceVariant,
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Image counter (if more than one image)
                            if (images.length > 1)
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    images.length == 1 
                                        ? '1 ${AppLocalizations.of(context).photo}'
                                        : '${images.length} ${AppLocalizations.of(context).photos}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.surface.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                itemData['item_name'] ??
                                    itemData['Brand'] ??
                                    AppLocalizations.of(context).unknownItem,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '\₪${itemData['Price'] ?? AppLocalizations.of(context).notAvailable}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 600.ms).slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutQuad,
                        ),
                        
                        // Brand - Type subtitle
                        if (itemData['Brand'] != null && itemData['Brand'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              itemData['Brand'],
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        FutureBuilder<Map<String, dynamic>>(
                          future: fetchSellerData(itemData['seller_id'] ?? ''),
                          builder: (context, sellerSnapshot) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (itemData['Condition'] != null)
                                  _buildInfoChip(
                                    context,
                                    Icons.check_circle_outline,
                                    TranslationUtils.getCondition(itemData['Condition'], context),
                                  ),
                                if (itemData['Size'] != null && itemData['Size'].toString().isNotEmpty)
                                  _buildInfoChip(
                                    context,
                                    Icons.straighten,
                                    itemData['Size'],
                                  ),
                                if (sellerSnapshot.hasData && 
                                    sellerSnapshot.data!['address'] != null &&
                                    sellerSnapshot.data!['address'].toString().isNotEmpty)
                                  _buildInfoChip(
                                    context,
                                    Icons.location_on_outlined,
                                    sellerSnapshot.data!['address'],
                                  ),
                              ],
                            );
                          },
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutQuad,
                        ),
                        
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context).description,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          itemData['Description'] ??
                              AppLocalizations.of(context).noDescription,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutQuad,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: (itemData['Tags'] as List<dynamic>?)
                                  ?.map((tag) => Chip(
                                        label: Text(tag),
                                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                        labelStyle: TextStyle(
                                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        ),
                                      ))
                                  .toList() ??
                              [],
                        ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutQuad,
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: fetchSellerData(itemData['seller_id'] ?? ''),
                            builder: (context, sellerSnapshot) {
                              if (sellerSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: CircularProgressIndicator(),
                                  ),
                                  title: Text(AppLocalizations.of(context).loading),
                                );
                              } else if (sellerSnapshot.hasError ||
                                  !sellerSnapshot.hasData ||
                                  sellerSnapshot.data!.isEmpty) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    child: Icon(
                                      Icons.person,
                                      size: 32,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  title: Text(AppLocalizations.of(context).unknownSeller),
                                );
                              }

                              var sellerData = sellerSnapshot.data!;
                              return ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: ImageHandler.buildProfilePicture(
                                  profilePicUrl: sellerData['profilePicUrl'],
                                  userId: itemData['seller_id'] ?? '',
                                  radius: 24,
                                  fallbackIcon: Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                title: Text(
                                  sellerData['name'] ??
                                      AppLocalizations.of(context).unknownSeller,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(sellerData['average_rating'] != null) 
                                          ? (sellerData['average_rating'] as num).toStringAsFixed(1) 
                                          : 'N/A'} '
                                      '(${sellerData['num_of_reviewers'] ?? 0} ${AppLocalizations.of(context).reviews})',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfilePage(
                                          viewedUserId: itemData['seller_id'] ?? ''),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutQuad,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isPurchaseRequestSent ? null : () {
                            _showPurchaseConfirmation(itemData);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: _isPurchaseRequestSent 
                                ? Theme.of(context).colorScheme.surfaceVariant
                                : null,
                            foregroundColor: _isPurchaseRequestSent 
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_isPurchaseRequestSent) ...[
                                const Icon(Icons.shopping_cart_outlined),
                                const SizedBox(width: 8),
                              ] else ...[
                                const Icon(Icons.hourglass_empty_rounded),
                                const SizedBox(width: 8),
                              ],
                              Text(_isPurchaseRequestSent 
                                  ? 'Almost yours! Waiting for seller...'
                                  : AppLocalizations.of(context).buyNow),
                            ],
                          ),
                        ).animate().fadeIn(delay: 1000.ms, duration: 600.ms).slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutQuad,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
