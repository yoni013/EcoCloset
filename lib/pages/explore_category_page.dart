import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beged/utils/fetch_item_metadata.dart';
import 'package:provider/provider.dart';
import 'package:beged/utils/firestore_cache_provider.dart';
import 'package:beged/generated/l10n.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:beged/widgets/filter_popup.dart';
import 'package:beged/widgets/item_card.dart';
import '../services/tag_service.dart';

class CategoryItemsPage extends StatefulWidget {
  final String category;
  final String? initialSortBy;
  final bool? initialForMeActive;
  final String? categoryKey;
  
  CategoryItemsPage({
    required this.category,
    this.initialSortBy,
    this.initialForMeActive,
    this.categoryKey,
  });

  @override
  _CategoryItemsPageState createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<CategoryItemsPage> {
  final TagService _tagService = TagService();
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> searchFilteredItems = [];
  bool _isLoading = false;
  String sortBy = 'Newest First';
  String _searchText = '';
  bool isForMeActive = false;
  Map<String, dynamic> filters = {
    'type': null,
    'size': null,
    'brand': null,
    'color': null,
    'condition': null,
    'priceRange': const RangeValues(0, 1000),
  };

  late FirestoreCacheProvider cacheProvider;

  @override
  void initState() {
    super.initState();
    setState(() {
      if (widget.categoryKey == 'shoes') {
        filters['type'] = ['Shoes'];
      } else if (widget.categoryKey == 'accessories') {
        filters['type'] = ['Accessories', 'Bags', 'Jewelry', 'Hats'];
      } else if (widget.category.isNotEmpty) {
        filters['type'] = [widget.category];
      }
      
      if (widget.initialSortBy != null) {
        sortBy = widget.initialSortBy!;
      }
      if (widget.initialForMeActive != null) {
        isForMeActive = widget.initialForMeActive!;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cacheProvider = Provider.of<FirestoreCacheProvider>(context, listen: false);
    fetchFilteredItems(cacheProvider);
  }

  Future<void> fetchFilteredItems(FirestoreCacheProvider cacheProvider) async {
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> fetchedItems = [];
      
      if (widget.categoryKey != null) {
        if (widget.categoryKey == 'new-arrivals') {
          // Special handling for new arrivals - filter by createdAt in last 48 hours
          final now = DateTime.now();
          final twoDaysAgo = now.subtract(const Duration(hours: 48));
          
          // Get all available items with a simple query (no compound index needed)
          var query = FirebaseFirestore.instance
              .collection('Items')
              .where('status', isEqualTo: 'Available');
          
          final cacheKey = 'new_arrivals_check';
          var allItems = await cacheProvider.fetchCollection(cacheKey, query);
          
          // Filter by createdAt on the client side
          fetchedItems = allItems.where((item) {
            final createdAt = item['createdAt'] as Timestamp?;
            if (createdAt == null) {
              return false;
            }
            
            final createdDate = createdAt.toDate();
            return createdDate.isAfter(twoDaysAgo);
          }).toList();
          
          // Sort by createdAt descending (newest first)
          fetchedItems.sort((a, b) {
            final aCreatedAt = a['createdAt'] as Timestamp?;
            final bCreatedAt = b['createdAt'] as Timestamp?;
            if (aCreatedAt == null && bCreatedAt == null) return 0;
            if (aCreatedAt == null) return 1;
            if (bCreatedAt == null) return -1;
            return bCreatedAt.compareTo(aCreatedAt);
          });
          
          // Apply traditional filters on top of time-based results
          fetchedItems = _applyTraditionalFilters(fetchedItems);
        } else {
          final categoryTags = _getTagsForCategory(widget.categoryKey!);
          if (categoryTags.isNotEmpty) {
            await _tagService.initialize();
            fetchedItems = await _tagService.getItemsByTags(
              tagNames: categoryTags,
              limit: 200,
            );
            
            fetchedItems = _applyTraditionalFilters(fetchedItems);
          } else {
            fetchedItems = await _fetchWithTraditionalFilters(cacheProvider);
          }
        }
      } else {
        fetchedItems = await _fetchWithTraditionalFilters(cacheProvider);
      }

      fetchedItems = await Future.wait(fetchedItems.map((data) async {
        if (data['images'] is List && data['images'].isNotEmpty) {
          data['imageUrl'] = data['images'][0];
        } else {
          data['imageUrl'] = '';
        }
        return data;
      }).toList());

      if (mounted) {
        setState(() {
          items = fetchedItems;
          _filterItemsBySearch();
          applySorting();
          _isLoading = false;
        });
        
        if (isForMeActive) {
          await _applyForMeFilter();
        }
      }
    } catch (e) {
      debugPrint('Error fetching items: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWithTraditionalFilters(FirestoreCacheProvider cacheProvider) async {
    var query = FirebaseFirestore.instance
        .collection('Items')
        .where('status', isEqualTo: 'Available');

    if (filters['type'] != null && (filters['type'] as List).isNotEmpty) {
      query = query.where('Type', whereIn: List<String>.from(filters['type']));
    }
    if (filters['size'] != null && (filters['size'] as List).isNotEmpty) {
      query = query.where('Size', whereIn: List<String>.from(filters['size']));
    }
    if (filters['brand'] != null && (filters['brand'] as List).isNotEmpty) {
      query = query.where('Brand', whereIn: List<String>.from(filters['brand']));
    }
    if (filters['color'] != null && (filters['color'] as List).isNotEmpty) {
      query = query.where('Color', whereIn: List<String>.from(filters['color']));
    }
    if (filters['condition'] != null && (filters['condition'] as List).isNotEmpty) {
      query = query.where('Condition', whereIn: List<String>.from(filters['condition']));
    }

    final cacheKey = 'filtered_items_${filters.toString()}';
    return await cacheProvider.fetchCollection(cacheKey, query);
  }

  List<String> _getTagsForCategory(String categoryKey) {
    switch (categoryKey) {
      case 'summer':
        return [
          // Season tags
          'summer', 'lightweight', 'breathable', 'airy', 'cooling',
          'sun-protection', 'quick-dry', 'moisture-wicking',
          // Occasion tags
          'vacation', 'travel', 'resort', 'beach', 'casual', 'everyday', 
          'weekend', 'relaxed', 'comfortable',
          // Material tags
          'linen', 'cotton',
          // Style tags
          'trendy', 'clean', 'simple', 'modern',
          // Fit tags
          'loose-fit', 'flowing', 'cropped',
          // Functionality tags
          'versatile', 'comfortable', 'breathable'
        ];
        
      case 'activewear':
        return [
          // Style tags
          'sporty', 'athletic', 'active', 'performance',
          // Occasion tags  
          'gym', 'workout', 'fitness', 'yoga', 'running', 'sports',
          // Season/functionality tags
          'moisture-wicking', 'breathable',
          // Functionality tags
          'comfortable', 'durable', 'versatile'
        ];
        
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _applyTraditionalFilters(List<Map<String, dynamic>> items) {
    return items.where((item) {
      if (filters['type'] != null && (filters['type'] as List).isNotEmpty) {
        final itemType = item['Type'] as String?;
        if (itemType == null || !(filters['type'] as List).contains(itemType)) {
          return false;
        }
      }
      
      if (filters['size'] != null && (filters['size'] as List).isNotEmpty) {
        final itemSize = item['Size'] as String?;
        if (itemSize == null || !(filters['size'] as List).contains(itemSize)) {
          return false;
        }
      }
      
      if (filters['brand'] != null && (filters['brand'] as List).isNotEmpty) {
        final itemBrand = item['Brand'] as String?;
        if (itemBrand == null || !(filters['brand'] as List).contains(itemBrand)) {
          return false;
        }
      }
      
      if (filters['color'] != null && (filters['color'] as List).isNotEmpty) {
        final itemColor = item['Color'] as String?;
        if (itemColor == null || !(filters['color'] as List).contains(itemColor)) {
          return false;
        }
      }
      
      if (filters['condition'] != null && (filters['condition'] as List).isNotEmpty) {
        final itemCondition = item['Condition'] as String?;
        if (itemCondition == null || !(filters['condition'] as List).contains(itemCondition)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _filterItemsBySearch() {
    setState(() {
      var filteredItems = items
          .where((item) =>
              (item['item_name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              (item['Brand'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              (item['Type'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              (item['Color'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()))
          .toList();
      
      searchFilteredItems = filteredItems;
    });
  }

  void applySorting() {
    setState(() {
      if (sortBy == 'Price (Low to High)') {
        items.sort((a, b) => (a['Price'] ?? 0).compareTo(b['Price'] ?? 0));
        searchFilteredItems.sort((a, b) => (a['Price'] ?? 0).compareTo(b['Price'] ?? 0));
      } else if (sortBy == 'Price (High to Low)') {
        items.sort((a, b) => (b['Price'] ?? 0).compareTo(a['Price'] ?? 0));
        searchFilteredItems.sort((a, b) => (b['Price'] ?? 0).compareTo(a['Price'] ?? 0));
      } else if (sortBy == 'Recommended') {
        items.sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
        searchFilteredItems.sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
      } else if (sortBy == 'Newest First') {
        items.sort((a, b) {
          final aCreatedAt = a['createdAt'] as Timestamp?;
          final bCreatedAt = b['createdAt'] as Timestamp?;
          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;
          return bCreatedAt.compareTo(aCreatedAt);
        });
        searchFilteredItems.sort((a, b) {
          final aCreatedAt = a['createdAt'] as Timestamp?;
          final bCreatedAt = b['createdAt'] as Timestamp?;
          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;
          return bCreatedAt.compareTo(aCreatedAt);
        });
      } else if (sortBy == 'Oldest First') {
        items.sort((a, b) {
          final aCreatedAt = a['createdAt'] as Timestamp?;
          final bCreatedAt = b['createdAt'] as Timestamp?;
          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;
          return aCreatedAt.compareTo(bCreatedAt);
        });
        searchFilteredItems.sort((a, b) {
          final aCreatedAt = a['createdAt'] as Timestamp?;
          final bCreatedAt = b['createdAt'] as Timestamp?;
          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;
          return aCreatedAt.compareTo(bCreatedAt);
        });
      }
    });
  }

  void openFiltersPopup(FirestoreCacheProvider cacheProvider) async {
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
          });
          fetchFilteredItems(cacheProvider);
        },
        sizes: sizes,
        brands: brands,
        types: types,
        colors: colors,
        conditions: conditions,
      ),
    );
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

  Future<Map<String, dynamic>> _fetchUserSizes(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    if (!doc.exists) return {};
    return doc.data()?['Sizes'] ?? {};
  }

  Future<void> _applyForMeFilter() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userSizes = await _fetchUserSizes(userId);
    final refined = _filterItemsByMySizes(
      items: searchFilteredItems,
      userSizes: userSizes,
    );
    if (mounted) {
      setState(() {
        searchFilteredItems = refined;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context).searchHint,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchText = val;
                            });
                            _filterItemsBySearch();
                            
                            if (isForMeActive) {
                              _applyForMeFilter();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_alt),
                        onPressed: () => openFiltersPopup(cacheProvider),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          setState(() {
                            sortBy = value;
                            applySorting();
                          });
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'Price (Low to High)',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: sortBy == 'Price (Low to High)'
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).sortByPriceLowToHigh,
                                  style: TextStyle(
                                    fontWeight: sortBy == 'Price (Low to High)'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: sortBy == 'Price (Low to High)'
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'Price (High to Low)',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: sortBy == 'Price (High to Low)'
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).sortByPriceHighToLow,
                                  style: TextStyle(
                                    fontWeight: sortBy == 'Price (High to Low)'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: sortBy == 'Price (High to Low)'
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'Recommended',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: sortBy == 'Recommended'
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).sortByRecommended,
                                  style: TextStyle(
                                    fontWeight: sortBy == 'Recommended'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: sortBy == 'Recommended'
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'Newest First',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: sortBy == 'Newest First'
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).sortByNewestFirst,
                                  style: TextStyle(
                                    fontWeight: sortBy == 'Newest First'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: sortBy == 'Newest First'
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'Oldest First',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: sortBy == 'Oldest First'
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).sortByOldestFirst,
                                  style: TextStyle(
                                    fontWeight: sortBy == 'Oldest First'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: sortBy == 'Oldest First'
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.sort,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
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
                            });
                            _filterItemsBySearch();
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
                ).animate().fadeIn(duration: 600.ms).slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOutQuad,
                    ),
                _isLoading
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
                              style:
                                  Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms)
                    : searchFilteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context).noItemsMatch,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 600.ms)
                        : Expanded(
                            child: _buildGridViewOfItems(),
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridViewOfItems() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3 / 4,
        ),
        itemCount: searchFilteredItems.length,
        itemBuilder: (context, index) {
          return ItemCard(
            item: searchFilteredItems[index],
            animationIndex: index,
          );
        },
      ),
    );
  }
}
