import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eco_closet/pages/item_page.dart';
import 'package:eco_closet/widgets/item_card.dart';

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserSizesAndItems();
    fetchTrendingItems();
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

  // Public method to refresh the homepage data
  Future<void> refreshHomepage() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
      await fetchUserSizesAndItems();
      await fetchTrendingItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          AppLocalizations.of(context).home,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await fetchUserSizesAndItems();
                await fetchTrendingItems();
              },
              child: SingleChildScrollView(
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
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
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
                        itemCount: trendingItems.length,
                        itemBuilder: (context, index) {
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
                  ],
                ),
              ),
            ),
    );
  }
}
