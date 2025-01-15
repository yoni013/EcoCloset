/// explore_page.dart
import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'item_page.dart';
import 'package:provider/provider.dart';
import 'package:eco_closet/utils/firestore_cache_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExplorePage extends StatefulWidget {
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<Map<String, dynamic>> items = [];
  String sortBy = 'Price (Low to High)';
  Map<String, dynamic> filters = {
    'type': null,
    'size': null,
    'brand': null,
    'color': null,
    'condition': null,
    'priceRange': RangeValues(0, 300),
  };

  Future<void> fetchFilteredItems(FirestoreCacheProvider cacheProvider) async {
    var query = FirebaseFirestore.instance.collection('Items').where('status', isEqualTo: 'Available');

    if (filters['type'] != null) {
      query = query.where('Type', isEqualTo: filters['type']);
    }
    if (filters['size'] != null) {
      query = query.where('Size', isEqualTo: filters['size']);
    }
    if (filters['brand'] != null) {
      query = query.where('Brand', isEqualTo: filters['brand']);
    }
    if (filters['color'] != null) {
      query = query.where('Color', isEqualTo: filters['color']);
    }
    if (filters['condition'] != null) {
      query = query.where('Condition', isEqualTo: filters['condition']);
    }

    final cacheKey = 'filtered_items_${filters.toString()}';
    var fetchedItems = await cacheProvider.fetchCollection(cacheKey, query);

    fetchedItems = await Future.wait(fetchedItems.map((data) async {
      if (data['images'] is List && data['images'].isNotEmpty) {
        data['imageUrl'] = await fetchImageUrl(data['images'][0]);
      } else {
        data['imageUrl'] = '';
      }
      return data;
    }).toList());

    if (mounted) {
      setState(() {
        items = fetchedItems;
        applySorting();
      });
    }
  }

  Future<String> fetchImageUrl(dynamic imagePath) async {
    if (imagePath is String && imagePath.isNotEmpty) {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    }
    return '';
  }

  void applySorting() {
    setState(() {
      if (sortBy == 'Price (Low to High)') {
        items.sort((a, b) => (a['Price'] ?? 0).compareTo(b['Price'] ?? 0));
      } else if (sortBy == 'Price (High to Low)') {
        items.sort((a, b) => (b['Price'] ?? 0).compareTo(a['Price'] ?? 0));
      } else if (sortBy == 'Most Viewed') {
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

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FilterPopup(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cacheProvider = Provider.of<FirestoreCacheProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Explore'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
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
                child: Text('Price (Low to High)',
                    style: TextStyle(
                        fontWeight: sortBy == 'Price (Low to High)'
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'Price (High to Low)',
                child: Text('Price (High to Low)',
                    style: TextStyle(
                        fontWeight: sortBy == 'Price (High to Low)'
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'Most Viewed',
                child: Text('Most Viewed',
                    style: TextStyle(
                        fontWeight: sortBy == 'Most Viewed'
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
            ],
            icon: Icon(Icons.sort),
          ),
        ],
      ),
      body: items.isEmpty
          ? FutureBuilder(
              future: fetchFilteredItems(cacheProvider),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No items match your filters.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index];

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
                                    placeholder: (context, url) => CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => Icon(Icons.broken_image),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      color: Colors.grey[200],
                                    ),
                                    child: Icon(Icons.broken_image),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['Brand'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '\₪${item['Price'] ?? 'N/A'}',
                                  style: TextStyle(
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
            ),
    );
  }
}

class FilterPopup extends StatelessWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApply;
  final List<String> sizes;
  final List<String> brands;
  final List<String> types;
  final List<String> colors;
  final List<String> conditions;

  FilterPopup({
    required this.currentFilters, 
    required this.onApply,
    required this.sizes,
    required this.brands,
    required this.types,
    required this.colors,
    required this.conditions,
    });

  @override
  Widget build(BuildContext context) {
    String? selectedType = currentFilters['type'];
    String? selectedSize = currentFilters['size'];
    String? selectedBrand = currentFilters['brand'];
    String? selectedColor = currentFilters['color'];
    String? selectedCondition = currentFilters['condition'];
    RangeValues priceRange = currentFilters['priceRange'] ?? RangeValues(0, 1000);

    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return types;
              }
              return types.where((type) =>
                  type.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            initialValue: TextEditingValue(text: selectedType ?? ''),
            onSelected: (String selection) {
              currentFilters['type'] = selection;
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(labelText: 'Type'),
              );
            },
          ),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return sizes;
              }
              return sizes.where((size) =>
                  size.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            initialValue: TextEditingValue(text: selectedSize ?? ''),
            onSelected: (String selection) {
              currentFilters['size'] = selection;
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(labelText: 'Size'),
              );
            },
          ),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return brands;
              }
              return brands.where((brand) =>
                  brand.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            initialValue: TextEditingValue(text: selectedBrand ?? ''),
            onSelected: (String selection) {
              currentFilters['brand'] = selection;
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(labelText: 'Brand'),
              );
            },
          ),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return colors;
              }
              return colors.where((color) =>
                  color.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            initialValue: TextEditingValue(text: selectedColor ?? ''),
            onSelected: (String selection) {
              currentFilters['color'] = selection;
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(labelText: 'Color'),
              );
            },
          ),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return conditions;
              }
              return conditions.where((condition) =>
                  condition.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            initialValue: TextEditingValue(text: selectedCondition ?? ''),
            onSelected: (String selection) {
              currentFilters['condition'] = selection;
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(labelText: 'Condition'),
              );
            },
          ),
          RangeSlider(
            values: priceRange,
            min: 0,
            max: 1000,
            divisions: 100,
            labels: RangeLabels(
              '₪${priceRange.start.round()}',
              '₪${priceRange.end.round()}',
            ),
            onChanged: (range) {
              currentFilters['priceRange'] = range;
            },
          ),
          Spacer(),
          ElevatedButton(
            onPressed: () {
              onApply(currentFilters);
              Navigator.pop(context);
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }
}
