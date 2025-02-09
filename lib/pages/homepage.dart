import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

      final allItems = querySnapshot.docs.map((doc) => doc.data()).toList();
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
        // .orderBy('views', descending: true)
        .limit(5)
        .get();

    if (mounted) {
      setState(() {
        trendingItems = querySnapshot.docs.map((doc) => doc.data()).toList();
        isLoading = false;
      });
    }
  }

  Widget buildItemCard(Map<String, dynamic> item) {
    final imageUrl = item['images'] != null && (item['images'] as List).isNotEmpty
                      ? item['images'][0]
                      : null;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item['Brand'] ?? 'Unknown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '\₪${item['Price'] ?? 'N/A'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Home"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      AppLocalizations.of(context).recommendedForYou,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) =>
                          buildItemCard(filteredItems[index]),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      AppLocalizations.of(context).trendingNow,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: trendingItems.length,
                      itemBuilder: (context, index) =>
                          buildItemCard(trendingItems[index]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
