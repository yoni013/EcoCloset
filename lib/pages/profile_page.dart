/// profile_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eco_closet/pages/personal_sizes_preferences.dart';
import 'package:eco_closet/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/pages/item_page.dart';

import 'package:eco_closet/generated/l10n.dart';

class ProfilePage extends StatefulWidget {
  final String viewedUserId;

  ProfilePage({required this.viewedUserId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Widget? _itemsWidget;

  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    var documentSnapshot =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    return documentSnapshot.data() ?? {};
  }

  Future<List<Map<String, dynamic>>> fetchSellerItems(String sellerId) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('Items')
        .where('seller_id', isEqualTo: sellerId)
        .get();

    return querySnapshot.docs.map((doc) {
      var data = doc.data();
      data['image_preview'] = doc['images'][0];
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchSellerReviews(String sellerId) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('Reviews')
        .where('seller_id', isEqualTo: sellerId)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<Widget> _buildItemsWidget() async {
    if (_itemsWidget != null) return _itemsWidget!;

    var items = await fetchSellerItems(widget.viewedUserId);
    _itemsWidget = _buildItemsGrid(items);
    return _itemsWidget!;
  }

  Widget _buildReviewsList(List<Map<String, dynamic>> reviews) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        var review = reviews[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 24),
                Text(
                  review['rating']
                      .toDouble()
                      .toStringAsFixed(1), // Convert int to float format
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                ),
              ],
            ),
            title: Text(
                review['content'] ?? AppLocalizations.of(context).noContent),
            subtitle: Text(review['seller_name'] ??
                AppLocalizations.of(context).anonymous_reviewer),
          ),
        );
      },
    );
  }

  Future<void> _showReviewsPopup() async {
    var reviews = await fetchSellerReviews(widget.viewedUserId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).userReviews),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildReviewsList(reviews),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).profilePage),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.room_preferences),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PersonalSizesPreferences(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserData(widget.viewedUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context).failedToLoadUser));
          }

          var userData = snapshot.data!;
          var averageRating = (userData['average_rating'] ?? 0).toDouble();
          var num_of_reviewers = (userData['num_of_reviewers'] ?? 0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: userData['profilePicUrl'] != null &&
                              userData['profilePicUrl'].isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: userData['profilePicUrl'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.person, size: 50),
                              ),
                            )
                          : const Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData['name'] ??
                          AppLocalizations.of(context).unknownUser,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData['address'] ?? 'No address provided',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showReviewsPopup,
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.yellow, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '$averageRating (${num_of_reviewers.toString()})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).searchItems,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // Implement filtering logic here
                  },
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: FutureBuilder<Widget>(
                  future: _buildItemsWidget(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text(
                              AppLocalizations.of(context).errorLoadingData));
                    }
                    return snapshot.data!;
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemsGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                borderRadius: BorderRadius.circular(8.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: item['images'] != null && item['images'].isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item['images'][0],
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey),
                        )
                      : const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 50, color: Colors.grey),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(item['Brand'] ??
                      AppLocalizations.of(context).unknownBrand),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
