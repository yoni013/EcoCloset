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

  int getActiveFiltersCount() {
    return filters.values.where((value) => value != null).length;
  }

  @override
  Widget build(BuildContext context) {
    final cacheProvider = Provider.of<FirestoreCacheProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Explore',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.black,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter and Sort Buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // Handle filter action
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt, size: 20, color: Colors.black),
                        SizedBox(
                            width: 4), // Reduced space between icon and text
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 6),
                        if (getActiveFiltersCount() > 0)
                          CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: 10,
                            child: Text(
                              '${getActiveFiltersCount()}',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Vertical divider
                Container(
                  height: 20,
                  width: 1,
                  color: Colors.black.withOpacity(0.5),
                ),

                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // Handle sort action
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_vert, size: 20, color: Colors.black),
                        SizedBox(width: 4),
                        Text(
                          'Sort',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: items.isEmpty
                ? FutureBuilder(
                    future: fetchFilteredItems(cacheProvider),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (items.isEmpty) {
                        return Center(
                          child: Text('No items found.',
                              style: TextStyle(fontSize: 18)),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 images in a row
                        crossAxisSpacing: 0, // Minimal spacing between columns
                        mainAxisSpacing: 0, // Minimal spacing between rows
                        childAspectRatio:
                            12 / 16, // Adjust aspect ratio for better alignment
                      ),
                      itemBuilder: (context, index) {
                        var item = items[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ItemPage(itemId: item['id']),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12.0)),
                                    child: CachedNetworkImage(
                                      imageUrl: item['imageUrl'] ?? '',
                                      placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.broken_image, size: 80),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                                Container(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['Brand'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color:
                                                  Colors.black.withOpacity(0.8),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '\₪${item['Price'] ?? 'N/A'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.black.withOpacity(0.8),
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
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchFilteredItems(FirestoreCacheProvider cacheProvider) async {
    var query = FirebaseFirestore.instance
        .collection('Items')
        .where('status', isEqualTo: 'Available');
    var fetchedItems =
        await cacheProvider.fetchCollection('items_cache', query);

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
      });
    }
  }

  Future<String> fetchImageUrl(dynamic imagePath) async {
    if (imagePath is String && imagePath.isNotEmpty) {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    }
    return '';
  }
}
