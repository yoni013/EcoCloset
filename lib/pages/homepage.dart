import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/widgets/item_card.dart';
import 'package:eco_closet/widgets/show_more_card.dart';
import 'package:eco_closet/pages/explore_category_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final Map<String, Set<String>> userSizes = {
    "Coats": {},
    "Pants": {},
    "Shirts": {},
    "Shoes": {},
    "Sweaters": {}
  };

  List<Map<String, dynamic>> filteredItems = [];
  List<Map<String, dynamic>> trendingItems = [];
  List<Map<String, dynamic>> infiniteScrollItems = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreItems = true;
  DocumentSnapshot? lastDocument;
  final int itemsPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchUserSizesAndItems();
    fetchTrendingItems();
    fetchInfiniteScrollItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMoreItems) {
        fetchInfiniteScrollItems();
      }
    }
  }

  Future<void> fetchUserSizesAndItems() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    if (userDoc.exists && userDoc.data()?.containsKey('Sizes') == true) {
      final sizes = (userDoc.data()?['Sizes'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          value is List<dynamic>
              ? Set<String>.from(value.map((e) => e.toString()))
              : <String>{},
        ),
      );

      if (mounted) {
        setState(() {
          userSizes.addAll(sizes);
        });
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Items')
          .where('status', isEqualTo: 'Available')
          .get();

      final allItems = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Ensure image_preview is set for ItemCard compatibility
        if (data['images'] != null && (data['images'] as List).isNotEmpty) {
          data['image_preview'] = data['images'][0];
        }
        return data;
      }).toList();
      if (mounted) {
        setState(() {
          filteredItems = allItems.where((item) {
            final itemType = item['Type'] as String?;
            final itemSize = item['Size'] as String?;
            if (itemType != null && itemSize != null) {
              return userSizes[itemType]?.contains(itemSize) ?? false;
            }
            return false;
          }).toList();
        });
      }
    }
  }

  Future<void> fetchTrendingItems() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Items')
        .where('status', isEqualTo: 'Available')
        // .orderBy('views', descending: true)
        .limit(5)
        .get();

    if (mounted) {
      setState(() {
        trendingItems = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          // Ensure image_preview is set for ItemCard compatibility
          if (data['images'] != null && (data['images'] as List).isNotEmpty) {
            data['image_preview'] = data['images'][0];
          }
          return data;
        }).toList();
        isLoading = false;
      });
    }
  }

  Future<void> fetchInfiniteScrollItems() async {
    if (isLoadingMore) return;
    
    setState(() {
      isLoadingMore = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('Items')
        .where('status', isEqualTo: 'Available')
        .limit(itemsPerPage);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    final querySnapshot = await query.get();

    if (mounted) {
      setState(() {
        final newItems = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          // Ensure image_preview is set for ItemCard compatibility
          if (data['images'] != null && (data['images'] as List).isNotEmpty) {
            data['image_preview'] = data['images'][0];
          }
          return data;
        }).toList();

        if (lastDocument == null) {
          // Initial load
          infiniteScrollItems = newItems;
        } else {
          // Append new items
          infiniteScrollItems.addAll(newItems);
        }

        isLoadingMore = false;
        
        if (querySnapshot.docs.length < itemsPerPage) {
          hasMoreItems = false;
        } else if (querySnapshot.docs.isNotEmpty) {
          lastDocument = querySnapshot.docs.last;
        }
      });
    }
  }

  // Public method to refresh the homepage data
  Future<void> refreshHomepage() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        infiniteScrollItems.clear();
        lastDocument = null;
        hasMoreItems = true;
        isLoadingMore = false;
      });
      await fetchUserSizesAndItems();
      await fetchTrendingItems();
      await fetchInfiniteScrollItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await refreshHomepage();
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Text(
                          AppLocalizations.of(context).recommendedForYou,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      SizedBox(
                        height: 320,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredItems.isEmpty ? 0 : (filteredItems.length >= 3 ? 4 : filteredItems.length),
                          itemBuilder: (context, index) {
                            if (index == 3 || (index == filteredItems.length && filteredItems.length < 3)) {
                              // Show "Show More" card as 4th item or after all items if less than 3
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.4,
                                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ShowMoreCard(
                                  title: "Show More",
                                  subtitle: "See all recommended items",
                                  animationIndex: index,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CategoryItemsPage(
                                          category: '', // Empty category for "Shop All"
                                          initialForMeActive: true,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                            
                            // Show only first 3 items
                            if (index < 3 && index < filteredItems.length) {
                              // Ensure image_preview is set for ItemCard compatibility
                              final item = Map<String, dynamic>.from(filteredItems[index]);
                              if (item['images'] != null && (item['images'] as List).isNotEmpty) {
                                item['image_preview'] = item['images'][0];
                              }
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.4,
                                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ItemCard(
                                  item: item,
                                  animationIndex: index,
                                ),
                              );
                            }
                            
                            // This should not happen with the current logic, but return empty container as fallback
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Text(
                          AppLocalizations.of(context).trendingNow,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      SizedBox(
                        height: 320,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          scrollDirection: Axis.horizontal,
                          itemCount: trendingItems.length > 3 ? 4 : trendingItems.length,
                          itemBuilder: (context, index) {
                            if (index == 3 && trendingItems.length > 3) {
                              // Show "Show More" card as 4th item
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.4,
                                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ShowMoreCard(
                                  title: "Show More",
                                  subtitle: "See all trending items",
                                  animationIndex: index,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CategoryItemsPage(
                                          category: '', // Empty category for "Shop All"
                                          initialSortBy: 'Recommended',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                            
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              margin: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ItemCard(
                                item: trendingItems[index],
                                animationIndex: index,
                              ),
                            );
                          },
                        ),
                      ),
                      // Infinite Scroll Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Text(
                          'Explore More',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      // Grid view for infinite scroll items
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: infiniteScrollItems.length + (hasMoreItems ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == infiniteScrollItems.length) {
                              // Loading indicator at the end
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            return ItemCard(
                              item: infiniteScrollItems[index],
                              animationIndex: index,
                            );
                          },
                        ),
                      ),
                      // Extra padding at the bottom
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
