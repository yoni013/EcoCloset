/// profile_page.dart
import 'package:eco_closet/main.dart';
import 'package:eco_closet/pages/homepage.dart';
import 'package:eco_closet/pages/my_shop_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eco_closet/pages/item_page.dart';

class ProfilePage extends StatefulWidget {
  final String viewedUserId;

  ProfilePage({required this.viewedUserId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Widget? _itemsWidget;

  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    var documentSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    return documentSnapshot.data() ?? {};
  }

  Future<List<Map<String, dynamic>>> fetchSellerItems(String sellerId) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('Items')
        .where('seller_id', isEqualTo: sellerId)
        .get();

    return querySnapshot.docs.map((doc) {
      var data = doc.data();
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

  Future<String> fetchImageUrl(dynamic imagePath) async {
    if (imagePath is String) {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } else {
      throw TypeError();
    }
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
            leading: Icon(Icons.star, color: Colors.yellow),
            title: Text(review['title'] ?? 'Review'),
            subtitle: Text(review['content'] ?? 'No content'),
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
        title: Text('User Reviews'),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildReviewsList(reviews),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.shop),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MyShopPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => AuthGate()));
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserData(widget.viewedUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Failed to load user data'));
          }

          var userData = snapshot.data!;
          var imageUrlFuture = fetchImageUrl(userData['pic']);
          var averageRating = (userData['average_rating'] ?? 0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: imageUrlFuture,
                      builder: (context, imageSnapshot) {
                        if (imageSnapshot.connectionState == ConnectionState.waiting) {
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            child: CircularProgressIndicator(),
                          );
                        } else if (imageSnapshot.hasError || !imageSnapshot.hasData) {
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            child: Icon(Icons.person, size: 50),
                          );
                        }

                        return CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(imageSnapshot.data!),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      userData['Name'] ?? 'Unknown User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showReviewsPopup,
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow, size: 20),
                          SizedBox(width: 4),
                          Text(
                            '$averageRating',
                            style: TextStyle(
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
              Divider(height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Items',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // Implement filtering logic here
                  },
                ),
              ),
              Divider(height: 1, thickness: 1),
              Expanded(
                child: FutureBuilder<Widget>(
                  future: _buildItemsWidget(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading data'));
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3 / 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        var item = items[index];
        var images = item['images'] as List<dynamic>?;
        var imageUrlFuture = images != null && images.isNotEmpty
            ? fetchImageUrl(images[0])
            : Future.value('');

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
                  child: FutureBuilder<String>(
                    future: imageUrlFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return Image.network(snapshot.data!, fit: BoxFit.cover);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item['Brand'] ?? 'Unknown',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
