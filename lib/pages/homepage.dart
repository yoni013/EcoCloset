import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Add navigation to item details
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Center(
                              child: CircularProgressIndicator(),
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
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\₪${item['Price'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['Type'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Home",
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
                        itemBuilder: (context, index) =>
                            buildItemCard(filteredItems[index]),
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
                        itemBuilder: (context, index) =>
                            buildItemCard(trendingItems[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
