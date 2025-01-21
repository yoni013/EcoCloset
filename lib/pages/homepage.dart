import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  Future<String> fetchImageUrl(dynamic imagePath) async {
    if (imagePath is String) {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } else {
      throw TypeError();
    }
  }

  Widget buildItemCard(Map<String, dynamic> item) {
    final imageUrl =
        item['images'] != null && (item['images'] as List).isNotEmpty
            ? fetchImageUrl(item['images'][0])
            : null;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<String>(
                future: imageUrl,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Image.network(snapshot.data!, fit: BoxFit.cover);
                },
                )
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
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Recommended for You',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Trending Now',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
