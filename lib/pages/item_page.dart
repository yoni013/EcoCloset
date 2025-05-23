/// item_page.dart
import 'package:cached_network_image/cached_network_image.dart';
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

class ItemPage extends StatefulWidget {
  final String itemId;

  ItemPage({required this.itemId});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  int _currentImageIndex = 0;

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
            future: fetchItemData(),
            builder: (context, snapshot) {
              if (snapshot.hasData && 
                  currentUserId != null && 
                  snapshot.data!['seller_id'] == currentUserId) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditItemPage(
                          itemId: widget.itemId,
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchItemData(),
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
                              onPageChanged: (index) {
                                _currentImageIndex = index;
                              },
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
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              context,
                              Icons.check_circle_outline,
                              TranslationUtils.getCondition(itemData['Condition'], context),
                            ),
                            _buildInfoChip(
                              context,
                              Icons.straighten,
                              itemData['Size'] ?? 'N/A',
                            ),
                          ],
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
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Contact Seller action
                                },
                                icon: const Icon(Icons.message_outlined),
                                label: Text(AppLocalizations.of(context).contactSeller),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Buy Now action
                                },
                                icon: const Icon(Icons.shopping_cart_outlined),
                                label: Text(AppLocalizations.of(context).buyNow),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
