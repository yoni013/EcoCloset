/// profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:provider/provider.dart';
import 'package:eco_closet/utils/firestore_cache_provider.dart';
import 'package:eco_closet/widgets/filter_popup.dart';
import 'package:eco_closet/widgets/item_card.dart';
import 'package:eco_closet/utils/image_handler.dart';
import 'package:eco_closet/settings/settings.dart';

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
  Map<String, dynamic> userSizes = {};
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
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('Reviews')
          .where('sellerId', isEqualTo: sellerId)
          // Removed orderBy to avoid Firestore index requirements
          .get();

      // Fetch reviewer names for each review
      List<Map<String, dynamic>> reviewsWithNames = [];
      for (var doc in querySnapshot.docs) {
        var reviewData = doc.data();
        
        // Fetch reviewer name
        String reviewerName = AppLocalizations.of(context).anonymous_reviewer;
        try {
          final reviewerId = reviewData['reviewerId'];
          if (reviewerId != null) {
            final userDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(reviewerId)
                .get();
            reviewerName = userDoc.data()?['name'] ?? AppLocalizations.of(context).anonymous_reviewer;
          }
        } catch (e) {
          debugPrint('Error fetching reviewer name: $e');
        }
        
        // Add reviewer name to review data
        reviewData['reviewerName'] = reviewerName;
        reviewsWithNames.add(reviewData);
      }

      // Sort by createdAt on the client side (newest first)
      reviewsWithNames.sort((a, b) {
        final aTimestamp = a['createdAt'] as Timestamp?;
        final bTimestamp = b['createdAt'] as Timestamp?;
        
        if (aTimestamp == null && bTimestamp == null) return 0;
        if (aTimestamp == null) return 1;
        if (bTimestamp == null) return -1;
        
        return bTimestamp.compareTo(aTimestamp);
      });

      return reviewsWithNames;
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      rethrow; // Re-throw the error so it can be caught by the FutureBuilder
    }
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
                                            '${averageRating.toStringAsFixed(1)} (${num_of_reviewers.toString()})',
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
                child: GestureDetector(
                  onTap: () {
                    // Dismiss keyboard when tapping outside, but don't clear search
                    FocusScope.of(context).unfocus();
                  },
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
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                            if (!isForMeActive) {
                              setState(() {
                                isForMeActive = true;
                              });
                              await _applyForMeFilter();
                            } else {
                              setState(() {
                                isForMeActive = false;
                                userSizes = {}; // Clear user sizes when disabled
                              });
                            }
                          },
                          icon: Icon(
                            Icons.person,
                            color: isForMeActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                          label: Text(
                            AppLocalizations.of(context).forMe,
                            style: TextStyle(
                              color: isForMeActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isForMeActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: isForMeActive 
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceVariant,
                            foregroundColor: isForMeActive
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                child: GestureDetector(
                  onTap: () {
                    // Dismiss keyboard when tapping outside, but don't clear search
                    FocusScope.of(context).unfocus();
                  },
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ItemsGridWidget(
                          key: _itemsGridKey,
                          items: items,
                          searchText: _searchText,
                          isForMeActive: isForMeActive,
                          userSizes: userSizes,
                        ),
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
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {}); // Trigger rebuild to refresh reviews
                            },
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Refresh reviews',
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchSellerReviews(widget.viewedUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading reviews',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No reviews yet',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Reviews from buyers will appear here',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return _buildReviewsList(snapshot.data!);
                      }
                    },
                  ),
                ),
              ],
            ),
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
                        review['reviewerName'] ??
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
                  review['reviewText'] ?? AppLocalizations.of(context).noContent,
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

  Future<Map<String, dynamic>> _fetchUserSizes(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    if (!doc.exists) return {};
    return doc.data()?['Sizes'] ?? {};
  }

  List<Map<String, dynamic>> _filterItemsByMySizes({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> userSizes,
  }) {
    return items.where((item) {
      final itemType = item['Type'] ?? '';
      final itemSize = item['Size'] ?? '';
      if (userSizes.containsKey(itemType)) {
        final preferred = userSizes[itemType];
        return preferred.contains(itemSize);
      } else {
        return true;
      }
    }).toList();
  }

  Future<void> _applyForMeFilter() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final fetchedUserSizes = await _fetchUserSizes(userId);
    setState(() {
      userSizes = fetchedUserSizes;
    });
    // The filtering will be applied in the ItemsGridWidget based on isForMeActive and userSizes
  }

  // Public method to refresh items from external calls
  void refreshItems() {
    _refreshItems();
  }

  // Public method to refresh profile data when reviews are updated
  void refreshProfile() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild of the main profile FutureBuilder
      });
    }
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
        widget.searchText != oldWidget.searchText ||
        widget.isForMeActive != oldWidget.isForMeActive ||
        widget.userSizes != oldWidget.userSizes) {
      currentSearchText = widget.searchText;
      _updateFilteredItems();
    }
  }

  void _updateFilteredItems() {
    List<Map<String, dynamic>> searchFiltered;
    
    if (currentSearchText.isEmpty) {
      searchFiltered = List.from(widget.items);
    } else {
      searchFiltered = widget.items
          .where((item) =>
              (item['item_name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(currentSearchText.toLowerCase()) ||
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

    // Apply "For Me" filtering if active
    if (widget.isForMeActive && widget.userSizes.isNotEmpty) {
      filteredItems = searchFiltered.where((item) {
        final itemType = item['Type'] ?? '';
        final itemSize = item['Size'] ?? '';
        if (widget.userSizes.containsKey(itemType)) {
          final preferred = widget.userSizes[itemType];
          return preferred.contains(itemSize);
        } else {
          return true; // Show items with types not in user preferences
        }
      }).toList();
    } else {
      filteredItems = searchFiltered;
    }
  }

  void updateSearchText(String searchText) {
    currentSearchText = searchText;
    _updateFilteredItems();
    
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
