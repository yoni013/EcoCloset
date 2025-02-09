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
    var query = FirebaseFirestore.instance.collection('Items').where('status', isEqualTo: 'Available');

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
              (item['Brand'] ?? '').toString().toLowerCase().contains(_searchText.toLowerCase()) ||
              (item['Type'] ?? '').toString().toLowerCase().contains(_searchText.toLowerCase()) ||
              (item['Color'] ?? '').toString().toLowerCase().contains(_searchText.toLowerCase()))
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
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16.0),
        child: FilterPopup(
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
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get();

    if (!doc.exists) return {};
    return doc.data()?['Sizes'] ?? {};
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text( '${AppLocalizations.of(context).explore} ${TranslationUtils.getCategory(widget.category, context)}',),
        centerTitle: true,
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
                child: Text(AppLocalizations.of(context).sortByPriceLowToHigh,
                    style: TextStyle(
                        fontWeight: sortBy == 'Price (Low to High)'
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'Price (High to Low)',
                child: Text(AppLocalizations.of(context).sortByPriceHighToLow,
                    style: TextStyle(
                        fontWeight: sortBy == 'Price (High to Low)'
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'Recommended',
                child: Text(
                  AppLocalizations.of(context).sortByRecommended,
                  style: TextStyle(
                    fontWeight: sortBy == 'Recommended'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),

            ],
            icon: const Icon(Icons.sort),
          ),
          TextButton(
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
            child: Text(
              AppLocalizations.of(context).forMe,
              style: TextStyle(
                color: isForMeActive
                    ? Colors.brown
                    : Colors.black,
                fontWeight: isForMeActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
            body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).search,
                suffixIcon: const Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() {
                  _searchText = val;
                });
                _filterItemsBySearch();
              },
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : searchFilteredItems.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context).noItemsMatch))
                  : Expanded(
                      child: _buildGridViewOfItems(),
                    ),
        ],
      ),
    );
  }


  Widget _buildGridViewOfItems() {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3 / 4,
          ),
          itemCount: searchFilteredItems.length,
          itemBuilder: (context, index) {
            var item = searchFilteredItems[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemPage(itemId: item['id']),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item['imageUrl'],
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                color: Colors.grey[200],
                              ),
                              child: const Icon(Icons.broken_image),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['Brand'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\₪${item['Price'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
        },
      ),
    );
  }
}

class FilterPopup extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApply;
  final List<String> sizes;
  final List<String> brands;
  final List<String> types;
  final List<String> colors;
  final List<String> conditions;

  const FilterPopup({
    Key? key,
    required this.currentFilters,
    required this.onApply,
    required this.sizes,
    required this.brands,
    required this.types,
    required this.colors,
    required this.conditions,
  }) : super(key: key);

  @override
  _FilterPopupState createState() => _FilterPopupState();
}

class _FilterPopupState extends State<FilterPopup> {
  late Map<String, dynamic> localFilters;

  @override
  void initState() {
    super.initState();
    // Copy from widget.currentFilters into localFilters
    localFilters = {
      'type': List<String>.from(widget.currentFilters['type'] ?? []),
      'size': List<String>.from(widget.currentFilters['size'] ?? []),
      'brand': List<String>.from(widget.currentFilters['brand'] ?? []),
      'color': List<String>.from(widget.currentFilters['color'] ?? []),
      'condition': List<String>.from(widget.currentFilters['condition'] ?? []),
      'priceRange': widget.currentFilters['priceRange'] ?? const RangeValues(0, 300),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).filter)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMultiselectField(
              label: AppLocalizations.of(context).type,
              options: widget.types,
              initialValues: localFilters['type'],
              onConfirm: (values) => localFilters['type'] = values,
              type: 'category',
            ),
            _buildMultiselectField(
              label: AppLocalizations.of(context).size,
              options: widget.sizes,
              initialValues: localFilters['size'],
              onConfirm: (values) => localFilters['size'] = values,
              type: '',
            ),
            _buildMultiselectField(
              label: AppLocalizations.of(context).brand,
              options: widget.brands,
              initialValues: localFilters['brand'],
              onConfirm: (values) => localFilters['brand'] = values,
              type: '',
            ),
            _buildMultiselectField(
              label: AppLocalizations.of(context).color,
              options: widget.colors,
              initialValues: localFilters['color'],
              onConfirm: (values) => localFilters['color'] = values,
              type: 'color',
            ),
            _buildMultiselectField(
              label: AppLocalizations.of(context).condition,
              options: widget.conditions,
              initialValues: localFilters['condition'],
              onConfirm: (values) => localFilters['condition'] = values,
              type: 'condition',
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: localFilters['priceRange'],
              min: 0,
              max: 1000,
              divisions: 100,
              labels: RangeLabels(
                '₪${localFilters['priceRange'].start.round()}',
                '₪${localFilters['priceRange'].end.round()}',
              ),
              onChanged: (range) {
                setState(() {
                  localFilters['priceRange'] = range;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.onApply(localFilters);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context).apply),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiselectField({
    required String label,
    required List<String> options,
    required List<String> initialValues,
    required Function(List<String>) onConfirm,
    required String type,
  }) {
    final items = options.map((option) {
      String translatedOption = option;

      // Apply the correct translation function
      if (type == 'category') {
        translatedOption = TranslationUtils.getCategory(option, context);
      } else if (type == 'color') {
        translatedOption = TranslationUtils.getColor(option, context);
      } else if (type == 'condition') {
        translatedOption = TranslationUtils.getCondition(option, context);
      } else {
        translatedOption = option;
      }

      return MultiSelectItem<String>(option, translatedOption);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: MultiSelectDialogField<String>(
        title: Text(label),
        items: items,
        searchable: true,
        initialValue: initialValues,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        buttonText: Text(label),
        onConfirm: (selectedValues) {
          onConfirm(selectedValues);
        },
      ),
    );
  }
}
