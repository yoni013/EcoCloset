import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../generated/l10n.dart';
import '../models/tag_model.dart';
import '../widgets/enhanced_filter_popup.dart';
import '../widgets/item_card.dart';
import '../utils/tag_operations.dart';

class TagBasedCategoryPage extends StatefulWidget {
  final String categoryKey;
  final String categoryName;
  final List<Tag> tags;

  const TagBasedCategoryPage({
    Key? key,
    required this.categoryKey,
    required this.categoryName,
    required this.tags,
  }) : super(key: key);

  @override
  State<TagBasedCategoryPage> createState() => _TagBasedCategoryPageState();
}

class _TagBasedCategoryPageState extends State<TagBasedCategoryPage> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> searchFilteredItems = [];
  bool _isLoading = false;
  String sortBy = 'Recommended';
  String _searchText = '';
  bool isForMeActive = false;
  
  Map<String, dynamic> filters = {
    'tags': <String, List<String>>{},
    'type': <String>[],
    'size': <String>[],
    'brand': <String>[],
    'color': <String>[],
    'condition': <String>[],
    'priceRange': const RangeValues(0, 1000),
  };

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _fetchItems();
  }

  void _initializeFilters() {
    if (widget.categoryKey != 'all') {
      // Set initial filter to this category's tags
      filters['tags'] = {
        widget.categoryKey: widget.tags.map((tag) => tag.name).toList(),
      };
    }
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> fetchedItems;
      
      if (widget.categoryKey == 'all') {
        // For "Browse All", get all available items
        final query = FirebaseFirestore.instance
            .collection('Items')
            .where('status', isEqualTo: 'Available')
            .limit(50);
        
        final querySnapshot = await query.get();
        fetchedItems = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          if (data['images'] != null && (data['images'] as List).isNotEmpty) {
            data['image_preview'] = data['images'][0];
          }
          return data;
        }).toList();
      } else {
        // For specific categories, filter by tags
        final tagNames = widget.tags.map((tag) => tag.name).toList();
        if (tagNames.isNotEmpty) {
          fetchedItems = await TagOperations.getItemsByTags(
            tagNames: tagNames,
            limit: 50,
          );
        } else {
          fetchedItems = [];
        }
      }

      setState(() {
        items = fetchedItems;
        _filterItemsBySearch();
        _applySorting();
        _isLoading = false;
      });

      // Apply "For Me" filter if active
      if (isForMeActive) {
        await _applyForMeFilter();
      }
    } catch (e) {
      debugPrint('Error fetching items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyTagFilters() async {
    setState(() => _isLoading = true);
    
    try {
      // Collect all selected tag names from filters
      final selectedTagNames = <String>[];
      final tagFilters = filters['tags'] as Map<String, List<String>>;
      
      for (final tagList in tagFilters.values) {
        selectedTagNames.addAll(tagList);
      }

      List<Map<String, dynamic>> fetchedItems;
      
      if (selectedTagNames.isNotEmpty) {
        fetchedItems = await TagOperations.getItemsByTags(
          tagNames: selectedTagNames,
          limit: 50,
        );
      } else if (widget.categoryKey == 'all') {
        // If no tags selected but we're in "all", show all items
        final query = FirebaseFirestore.instance
            .collection('Items')
            .where('status', isEqualTo: 'Available')
            .limit(50);
        
        final querySnapshot = await query.get();
        fetchedItems = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          if (data['images'] != null && (data['images'] as List).isNotEmpty) {
            data['image_preview'] = data['images'][0];
          }
          return data;
        }).toList();
      } else {
        fetchedItems = [];
      }

      // Apply additional filters (type, size, etc.)
      fetchedItems = _applyAdditionalFilters(fetchedItems);

      setState(() {
        items = fetchedItems;
        _filterItemsBySearch();
        _applySorting();
        _isLoading = false;
      });

      if (isForMeActive) {
        await _applyForMeFilter();
      }
    } catch (e) {
      debugPrint('Error applying tag filters: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _applyAdditionalFilters(List<Map<String, dynamic>> items) {
    var filteredItems = items;

    // Apply type filter
    final selectedTypes = filters['type'] as List<String>;
    if (selectedTypes.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        final itemType = item['Type']?.toString() ?? '';
        return selectedTypes.contains(itemType);
      }).toList();
    }

    // Apply size filter
    final selectedSizes = filters['size'] as List<String>;
    if (selectedSizes.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        final itemSize = item['Size']?.toString() ?? '';
        return selectedSizes.contains(itemSize);
      }).toList();
    }

    // Apply brand filter
    final selectedBrands = filters['brand'] as List<String>;
    if (selectedBrands.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        final itemBrand = item['Brand']?.toString() ?? '';
        return selectedBrands.contains(itemBrand);
      }).toList();
    }

    // Apply color filter
    final selectedColors = filters['color'] as List<String>;
    if (selectedColors.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        final itemColor = item['Color']?.toString() ?? '';
        return selectedColors.contains(itemColor);
      }).toList();
    }

    // Apply condition filter
    final selectedConditions = filters['condition'] as List<String>;
    if (selectedConditions.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        final itemCondition = item['Condition']?.toString() ?? '';
        return selectedConditions.contains(itemCondition);
      }).toList();
    }

    // Apply price range filter
    final priceRange = filters['priceRange'] as RangeValues;
    filteredItems = filteredItems.where((item) {
      final price = (item['Price'] ?? 0).toDouble();
      return price >= priceRange.start && price <= priceRange.end;
    }).toList();

    return filteredItems;
  }

  void _filterItemsBySearch() {
    setState(() {
      searchFilteredItems = items.where((item) {
        if (_searchText.isEmpty) return true;
        
        final searchLower = _searchText.toLowerCase();
        return (item['item_name']?.toString().toLowerCase().contains(searchLower) ?? false) ||
               (item['Brand']?.toString().toLowerCase().contains(searchLower) ?? false) ||
               (item['Type']?.toString().toLowerCase().contains(searchLower) ?? false) ||
               (item['Color']?.toString().toLowerCase().contains(searchLower) ?? false);
      }).toList();
    });
  }

  void _applySorting() {
    setState(() {
      switch (sortBy) {
        case 'Price (Low to High)':
          items.sort((a, b) => (a['Price'] ?? 0).compareTo(b['Price'] ?? 0));
          break;
        case 'Price (High to Low)':
          items.sort((a, b) => (b['Price'] ?? 0).compareTo(a['Price'] ?? 0));
          break;
        case 'Newest First':
          items.sort((a, b) {
            final aCreatedAt = a['createdAt'] as Timestamp?;
            final bCreatedAt = b['createdAt'] as Timestamp?;
            if (aCreatedAt == null && bCreatedAt == null) return 0;
            if (aCreatedAt == null) return 1;
            if (bCreatedAt == null) return -1;
            return bCreatedAt.compareTo(aCreatedAt);
          });
          break;
        case 'Oldest First':
          items.sort((a, b) {
            final aCreatedAt = a['createdAt'] as Timestamp?;
            final bCreatedAt = b['createdAt'] as Timestamp?;
            if (aCreatedAt == null && bCreatedAt == null) return 0;
            if (aCreatedAt == null) return 1;
            if (bCreatedAt == null) return -1;
            return aCreatedAt.compareTo(bCreatedAt);
          });
          break;
        case 'Recommended':
        default:
          // For recommended, items are already in a good order from the query
          break;
      }
    });
  }

  Future<void> _applyForMeFilter() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userSizes = await _fetchUserSizes(userId);
    final refined = _filterItemsByMySizes(
      items: searchFilteredItems,
      userSizes: userSizes,
    );
    setState(() {
      searchFilteredItems = refined;
    });
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
      }
      return true;
    }).toList();
  }

  Future<Map<String, dynamic>> _fetchUserSizes(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['Sizes'] ?? {};
      }
    } catch (e) {
      debugPrint('Error fetching user sizes: $e');
    }
    return {};
  }

  void _openFiltersPopup() {
    showDialog(
      context: context,
      builder: (context) => EnhancedFilterPopup(
        initialFilters: filters,
        onFiltersChanged: (newFilters) {
          setState(() {
            filters = newFilters;
          });
          _applyTagFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: Text(
                            widget.categoryName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Search and filter row
                    Row(
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
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, 
                                horizontal: 12,
                              ),
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
                          onPressed: _openFiltersPopup,
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            setState(() {
                              sortBy = value;
                              _applySorting();
                            });
                          },
                          itemBuilder: (context) => [
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
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(
                begin: 0.2,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutQuad,
              ),

              // Content
              Expanded(
                child: _isLoading
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          ).animate().fadeIn(duration: 600.ms)
                        : Padding(
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
                                final item = searchFilteredItems[index];
                                
                                // Record view interaction
                                TagOperations.recordItemInteraction(
                                  itemId: item['id'],
                                  interactionType: 'view',
                                );
                                
                                return ItemCard(
                                  item: item,
                                  animationIndex: index,
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 