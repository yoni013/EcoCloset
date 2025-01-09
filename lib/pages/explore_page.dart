/// explore_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'item_page.dart';

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
    'priceRange': RangeValues(0, 1000),
  };

  Future<void> fetchFilteredItems() async {
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

    var querySnapshot = await query.get();

    var fetchedItems = await Future.wait(querySnapshot.docs.map((doc) async {
      var data = doc.data();
      data['id'] = doc.id;
      if (data['images'] is List && data['images'].isNotEmpty) {
        data['imageUrl'] = await fetchImageUrl(data['images'][0]);
      } else {
        data['imageUrl'] = '';
      }
      return data;
    }).toList());

    setState(() {
      items = fetchedItems;
      applySorting();
    });
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

  void openFiltersPopup() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FilterPopup(
          currentFilters: filters,
          onApply: (newFilters) {
            setState(() {
              filters = newFilters;
              fetchFilteredItems();
            });
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchFilteredItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: openFiltersPopup,
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
          ? Center(child: CircularProgressIndicator())
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
                                ? Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      image: DecorationImage(
                                        image: NetworkImage(item['imageUrl']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
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

  FilterPopup({required this.currentFilters, required this.onApply});

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
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: InputDecoration(labelText: 'Type'),
            items: ['Tops', 'Bottoms', 'Accessories', 'Shoes', 'Outerwear'].map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              currentFilters['type'] = value;
            },
          ),
          DropdownButtonFormField<String>(
            value: selectedSize,
            decoration: InputDecoration(labelText: 'Size'),
            items: ['XS', 'S', 'M', 'L', 'XL'].map((size) {
              return DropdownMenuItem(
                value: size,
                child: Text(size),
              );
            }).toList(),
            onChanged: (value) {
              currentFilters['size'] = value;
            },
          ),
          DropdownButtonFormField<String>(
            value: selectedBrand,
            decoration: InputDecoration(labelText: 'Brand'),
            items: ['Nike', 'Adidas', 'Zara', 'H&M', 'Other'].map((brand) {
              return DropdownMenuItem(
                value: brand,
                child: Text(brand),
              );
            }).toList(),
            onChanged: (value) {
              currentFilters['brand'] = value;
            },
          ),
          DropdownButtonFormField<String>(
            value: selectedColor,
            decoration: InputDecoration(labelText: 'Color'),
            items: ['Red', 'Blue', 'Green', 'Black', 'White', 'Other'].map((color) {
              return DropdownMenuItem(
                value: color,
                child: Text(color),
              );
            }).toList(),
            onChanged: (value) {
              currentFilters['color'] = value;
            },
          ),
          DropdownButtonFormField<String>(
            value: selectedCondition,
            decoration: InputDecoration(labelText: 'Condition'),
            items: ['New', 'Like New', 'Used', 'Fair'].map((condition) {
              return DropdownMenuItem(
                value: condition,
                child: Text(condition),
              );
            }).toList(),
            onChanged: (value) {
              currentFilters['condition'] = value;
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
