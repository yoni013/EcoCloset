import 'package:eco_closet/utils/translation_metadata.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'item_page.dart';
import 'package:provider/provider.dart';
import 'package:eco_closet/utils/firestore_cache_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eco_closet/widgets/filter_popup.dart';
import 'package:eco_closet/widgets/item_card.dart';

class CategoryItemsPage extends StatefulWidget {
  final String category;
  CategoryItemsPage({required this.category});

  @override
  _CategoryItemsPageState createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<CategoryItemsPage> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> searchFilteredItems = [];
  bool _isLoading = false;
  String sortBy = 'Price (Low to High)';
  String _searchText = '';
  bool isForMeActive = false;
  Map<String, dynamic> filters = {
    'type': null,
    'size': null,
    'brand': null,
    'color': null,
    'condition': null,
    'priceRange': const RangeValues(0, 500),
  };

  late FirestoreCacheProvider cacheProvider;

  @override
  void initState() {
    super.initState();
    setState(() {
      filters['type'] = widget.category.isNotEmpty ? [widget.category] : null;
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
    // if (filters['priceRange'] != null) {
    //   query = query.where(
    //     'Price',
    //     isGreaterThanOrEqualTo: filters['priceRange'].start,
    //     isLessThanOrEqualTo: filters['priceRange'].end,
    //   );
    // }

    final cacheKey = 'filtered_items_${filters.toString()}';
    var fetchedItems = await cacheProvider.fetchCollection(cacheKey, query);

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
    }
  }

  void _filterItemsBySearch() {
    setState(() {
      searchFilteredItems = items
          .where((item) =>
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
    });
  }

  void applySorting() {
    setState(() {
      if (sortBy == 'Price (Low to High)') {
        items.sort((a, b) => (a['Price'] ?? 0).compareTo(b['Price'] ?? 0));
      } else if (sortBy == 'Price (High to Low)') {
        items.sort((a, b) => (b['Price'] ?? 0).compareTo(a['Price'] ?? 0));
      } else if (sortBy == 'Recommended') {
        items.sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
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
            fetchFilteredItems(cacheProvider);
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

  List<Map<String, dynamic>> _filterItemsByMySizes({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> userSizes,
  }) {
    return searchFilteredItems.where((item) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppLocalizations.of(context).explore} ${TranslationUtils.getCategory(widget.category, context)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => openFiltersPopup(cacheProvider),
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
            ],
            icon: const Icon(Icons.sort),
          ),
          TextButton.icon(
            onPressed: () async {
              if (!isForMeActive) {
                final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                final userSizes = await _fetchUserSizes(userId);
                final refined = _filterItemsByMySizes(
                  items: items,
                  userSizes: userSizes,
                );
                setState(() {
                  searchFilteredItems = refined;
                  isForMeActive = true;
                });
              } else {
                await fetchFilteredItems(cacheProvider);
                setState(() {
                  isForMeActive = false;
                });
              }
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).search,
                  hintText: AppLocalizations.of(context).searchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchText = val;
                  });
                  _filterItemsBySearch();
                },
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
