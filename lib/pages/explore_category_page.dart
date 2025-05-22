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
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16.0),
                            ),
                            child: item['imageUrl'] != null &&
                                    item['imageUrl'].isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item['imageUrl'],
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant,
                                      ),
                                      child: const Icon(Icons.broken_image),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                    ),
                                    child: const Icon(Icons.broken_image),
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\₪${item['Price'] ?? 'N/A'}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['Brand'] ?? 'Unknown',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['Type'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: (50 * index).ms)
                  .fadeIn(
                    duration: 600.ms,
                    curve: Curves.easeOutQuad,
                  )
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutQuad,
                  ));
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
      'priceRange':
          widget.currentFilters['priceRange'] ?? const RangeValues(0, 300),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).filter,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        elevation: 0,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).priceRange,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutQuad,
                  ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: Text(AppLocalizations.of(context).cancel),
                      style: OutlinedButton.styleFrom(
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
                        widget.onApply(localFilters);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: Text(AppLocalizations.of(context).apply),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutQuad,
                  ),
            ],
          ),
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
      if (type == 'category') {
        translatedOption = TranslationUtils.getCategory(option, context);
      } else if (type == 'color') {
        translatedOption = TranslationUtils.getColor(option, context);
      } else if (type == 'condition') {
        translatedOption = TranslationUtils.getCondition(option, context);
      }
      return MultiSelectItem<String>(option, translatedOption);
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            MultiSelectDialogField<String>(
              title: Text(label),
              items: items,
              searchable: true,
              initialValue: initialValues,
              buttonText: Text(
                AppLocalizations.of(context).select(label),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              buttonIcon: const Icon(Icons.arrow_drop_down),
              selectedItemsTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              searchTextStyle: Theme.of(context).textTheme.bodyLarge,
              itemsTextStyle: Theme.of(context).textTheme.bodyLarge,
              chipDisplay: MultiSelectChipDisplay(
                chipColor: Theme.of(context).colorScheme.primaryContainer,
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onConfirm: onConfirm,
            ),
          ],
        ),
      ),
    )
        .animate(delay: (50 * options.indexOf(options.first)).ms)
        .fadeIn(
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        )
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        );
  }
}
