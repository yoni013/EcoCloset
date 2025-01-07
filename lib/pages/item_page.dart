/// item_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:eco_closet/pages/profile_page.dart';

class ItemPage extends StatelessWidget {
  final String itemId;

  ItemPage({required this.itemId});

  Future<Map<String, dynamic>> fetchItemData() async {
    var documentSnapshot = await FirebaseFirestore.instance.collection('Items').doc(itemId).get();
    return documentSnapshot.data() ?? {};
  }

  Future<Map<String, dynamic>> fetchSellerData(String sellerId) async {
    var documentSnapshot = await FirebaseFirestore.instance.collection('Users').doc(sellerId).get();
    return documentSnapshot.data() ?? {};
  }

  Future<List<String>> fetchImageUrls(List<dynamic> imagePaths) async {
    return Future.wait(imagePaths.map((path) => FirebaseStorage.instance.ref(path).getDownloadURL()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Details'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchItemData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Failed to load item details'));
          }

          var itemData = snapshot.data!;
          var images = itemData['images'] as List<dynamic>? ?? [];
          var imageUrlsFuture = fetchImageUrls(images);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<List<String>>(
                    future: imageUrlsFuture,
                    builder: (context, imageSnapshot) {
                      if (imageSnapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (imageSnapshot.hasError || !imageSnapshot.hasData || imageSnapshot.data!.isEmpty) {
                        return Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: Center(child: Icon(Icons.broken_image, size: 48)),
                        );
                      }

                      return Container(
                        height: 300,
                        child: PageView.builder(
                          itemCount: imageSnapshot.data!.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              imageSnapshot.data![index],
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        itemData['Brand'] ?? 'Unknown Item',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\₪${itemData['Price'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Condition: ${itemData['Condition'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    itemData['Description'] ?? 'No description provided.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: (itemData['Tags'] as List<dynamic>?)?.map((tag) => Chip(label: Text(tag))).toList() ?? [],
                  ),
                  Divider(height: 32),
                  FutureBuilder<Map<String, dynamic>>(
                    future: fetchSellerData(itemData['seller_id'] ?? ''),
                    builder: (context, sellerSnapshot) {
                      if (sellerSnapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: CircularProgressIndicator(),
                          ),
                          title: Text('Loading seller info...'),
                        );
                      } else if (sellerSnapshot.hasError || !sellerSnapshot.hasData || sellerSnapshot.data!.isEmpty) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Icon(Icons.person, size: 32),
                          ),
                          title: Text('Unknown Seller'),
                        );
                      }

                      var sellerData = sellerSnapshot.data!;
                      return ListTile(
                        leading: FutureBuilder<String>(
                          future: FirebaseStorage.instance.ref(sellerData['pic']).getDownloadURL(),
                          builder: (context, imageSnapshot) {
                            if (imageSnapshot.connectionState == ConnectionState.waiting) {
                              return CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: CircularProgressIndicator(),
                              );
                            } else if (imageSnapshot.hasError || !imageSnapshot.hasData) {
                              return CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: Icon(Icons.person, size: 32),
                              );
                            }
                            return CircleAvatar(
                              backgroundImage: NetworkImage(imageSnapshot.data!),
                            );
                          },
                        ),
                        title: Text(sellerData['Name'] ?? 'Unknown Seller'),
                        subtitle: Row(
                          children: [
                            Icon(Icons.star, color: Colors.yellow, size: 16),
                            Text(' ${sellerData['Rating'] ?? 'N/A'} (100 reviews)'),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(viewedUserId: itemData['seller_id'] ?? ''),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Contact Seller action
                        },
                        child: Text('Contact Seller'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Buy Now action
                        },
                        child: Text('Buy Now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
