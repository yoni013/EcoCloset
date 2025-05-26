/// profile_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eco_closet/utils/image_handler.dart';
import 'package:eco_closet/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eco_closet/pages/item_page.dart';
import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:eco_closet/utils/translation_metadata.dart';
import 'package:eco_closet/widgets/filter_popup.dart';
import 'package:eco_closet/widgets/item_card.dart';

class ProfilePage extends StatefulWidget {
  final String viewedUserId;

  ProfilePage({required this.viewedUserId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Map<String, dynamic>> items = [];
  String _searchText = '';
  bool isForMeActive = false;
  late TextEditingController _searchController;
  bool _isLoading = false;
  final GlobalKey<_ItemsGridWidgetState> _itemsGridKey = GlobalKey<_ItemsGridWidgetState>();
  Map<String, dynamic> filters = {
    'type': null,
    'size': null,
    'brand': null,
    'color': null,
    'condition': null,
    'priceRange': const RangeValues(0, 500),
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    var documentSnapshot =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    return documentSnapshot.data() ?? {};
  }

  Future<List<Map<String, dynamic>>> fetchSellerItems(String sellerId) async {
    var query = FirebaseFirestore.instance
        .collection('Items')
        .where('seller_id', isEqualTo: sellerId)
        .where('status', isEqualTo: 'Available');

    // Apply filters
    if (filters['type'] != null && (filters['type'] as List).isNotEmpty) {
      query = query.where('Type', whereIn: List<String>.from(filters['type']));
    }
    if (filters['size'] != null && (filters['size'] as List).isNotEmpty) {
      query = query.where('Size', whereIn: List<String>.from(filters['size']));
    }
    if (filters['brand'] != null && (filters['brand'] as List).isNotEmpty) {
      query =
          query.where('Brand', whereIn: List<String>.from(filters['brand']));
    }
    if (filters['color'] != null && (filters['color'] as List).isNotEmpty) {
      query =
          query.where('Color', whereIn: List<String>.from(filters['color']));
    }
    if (filters['condition'] != null &&
        (filters['condition'] as List).isNotEmpty) {
      query = query.where('Condition',
          whereIn: List<String>.from(filters['condition']));
    }

    var querySnapshot = await query.get();

    var fetchedItems = querySnapshot.docs.map((doc) {
      var data = doc.data();
      data['image_preview'] = doc['images'][0];
      data['id'] = doc.id;
      return data;
    }).toList();

    // Apply price range filter (done client-side since Firestore has limitations)
    if (filters['priceRange'] != null) {
      fetchedItems = fetchedItems.where((item) {
        final price = (item['Price'] ?? 0).toDouble();
        final range = filters['priceRange'] as RangeValues;
        return price >= range.start && price <= range.end;
      }).toList();
    }

    return fetchedItems;
  }

  void openFiltersPopup() async {
    final sizes = await Utils.sizes;
    final brands = await Utils.brands;
    final types = await Utils.types;
    final colors = await Utils.colors;
    final conditions = await Utils.conditions;

    showDialog(
      context: context,
      builder: (context) => FilterPopup(
        currentFilters: filters,
        onApply: (newFilters) {
          setState(() {
            filters = newFilters;
            _refreshItems();
          });
        },
        sizes: sizes,
        brands: brands,
        types: types,
        colors: colors,
        conditions: conditions,
      ),
    );
  }

  Future<void> _refreshItems() async {
    setState(() {
      _isLoading = true;
    });
    items = await fetchSellerItems(widget.viewedUserId);
    setState(() {
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchSellerReviews(String sellerId) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('Reviews')
        .where('seller_id', isEqualTo: sellerId)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = FirebaseAuth.instance.currentUser?.uid == widget.viewedUserId;
    
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserData(widget.viewedUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context).failedToLoadUser));
          }

          var userData = snapshot.data!;
          var averageRating = (userData['average_rating'] ?? 0).toDouble();
          var num_of_reviewers = (userData['num_of_reviewers'] ?? 0);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Hero(
                              tag: 'profile_${widget.viewedUserId}',
                              child: ImageHandler.buildProfilePicture(
                                profilePicUrl: userData['profilePicUrl'],
                                userId: widget.viewedUserId,
                                radius: 40,
                                fallbackIcon: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData['name'] ??
                                        AppLocalizations.of(context).unknownUser,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userData['address'] ?? 'No address provided',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _showReviewsPopup,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$averageRating (${num_of_reviewers.toString()})',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Only show settings and preferences buttons for own profile
                            if (isOwnProfile) ...[
                              IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const SettingsPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context).searchItems,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          onChanged: (value) {
                            // Update search text without setState to avoid page refresh
                            _searchText = value;
                            // Directly update the grid widget
                            _itemsGridKey.currentState?.updateSearchText(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_alt),
                        onPressed: openFiltersPopup,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          setState(() {
                            isForMeActive = !isForMeActive;
                          });
                        },
                        icon: Icon(
                          Icons.person,
                          color: isForMeActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        label: Text(
                          AppLocalizations.of(context).forMe,
                          style: TextStyle(
                            color: isForMeActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isForMeActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ItemsGridWidget(
                        key: _itemsGridKey,
                        items: items,
                        searchText: _searchText,
                        isForMeActive: isForMeActive,
                        userSizes: const {},
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    items = await fetchSellerItems(widget.viewedUserId);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showReviewsPopup() async {
    var reviews = await fetchSellerReviews(widget.viewedUserId);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).userReviews,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: _buildReviewsList(reviews),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList(List<Map<String, dynamic>> reviews) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        var review = reviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            review['rating'].toDouble().toStringAsFixed(1),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        review['seller_name'] ??
                            AppLocalizations.of(context).anonymous_reviewer,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  review['content'] ?? AppLocalizations.of(context).noContent,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ).animate(delay: (50 * index).ms).fadeIn(
              duration: 600.ms,
              curve: Curves.easeOutQuad,
            ).slideY(
              begin: 0.2,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOutQuad,
            );
      },
    );
  }

  // Public method to refresh items from external calls
  void refreshItems() {
    _refreshItems();
  }
}

class ItemsGridWidget extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String searchText;
  final bool isForMeActive;
  final Map<String, dynamic> userSizes;

  const ItemsGridWidget({
    Key? key,
    required this.items,
    required this.searchText,
    required this.isForMeActive,
    required this.userSizes,
  }) : super(key: key);

  @override
  _ItemsGridWidgetState createState() => _ItemsGridWidgetState();
}

class _ItemsGridWidgetState extends State<ItemsGridWidget> {
  late List<Map<String, dynamic>> filteredItems;
  String currentSearchText = '';

  @override
  void initState() {
    super.initState();
    currentSearchText = widget.searchText;
    _updateFilteredItems();
  }

  @override
  void didUpdateWidget(ItemsGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items ||
        widget.searchText != oldWidget.searchText) {
      currentSearchText = widget.searchText;
      _updateFilteredItems();
    }
  }

  void _updateFilteredItems() {
    if (currentSearchText.isEmpty) {
      filteredItems = List.from(widget.items);
    } else {
      filteredItems = widget.items
          .where((item) =>
              (item['Brand'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(currentSearchText.toLowerCase()) ||
              (item['Type'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(currentSearchText.toLowerCase()) ||
              (item['Color'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(currentSearchText.toLowerCase()))
          .toList();
    }
  }

  void updateSearchText(String searchText) {
    currentSearchText = searchText;
    // Update the filtered items based on the new search text
    if (searchText.isEmpty) {
      filteredItems = List.from(widget.items);
    } else {
      filteredItems = widget.items
          .where((item) =>
              (item['Brand'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(searchText.toLowerCase()) ||
              (item['Type'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(searchText.toLowerCase()) ||
              (item['Color'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(searchText.toLowerCase()))
          .toList();
    }
    
    // Only call setState here - this will only rebuild the grid, not the main page
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return (filteredItems.isEmpty && currentSearchText.isNotEmpty)
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).noItemsMatch,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          )
        : _buildItemsGrid(filteredItems);
  }

  Widget _buildItemsGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ItemCard(
          item: items[index],
          animationIndex: index,
        );
      },
    );
  }
}
