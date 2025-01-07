/// explore_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'item_page.dart';

class ExplorePage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchAvailableItems() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('Items')
        .where('status', isEqualTo: 'Available')
        .get();
    return querySnapshot.docs.map((doc) {
      var data = doc.data();
      data['id'] = doc.id; // Ensure the document ID is included as a field
      return data;
    }).toList();
  }

  Future<String> fetchImageUrl(dynamic imagePath) async {
    if (imagePath is String && imagePath.isNotEmpty) {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    }
    return ''; // Return an empty string if the imagePath is invalid
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAvailableItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No available items to display'));
          }

          var items = snapshot.data!;

          return Padding(
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
                            builder: (context, imageSnapshot) {
                              if (imageSnapshot.connectionState == ConnectionState.waiting) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: Colors.grey[200],
                                  ),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              } else if (imageSnapshot.hasError || !imageSnapshot.hasData || imageSnapshot.data!.isEmpty) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: Colors.grey[200],
                                  ),
                                  child: Icon(Icons.broken_image),
                                );
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  image: DecorationImage(
                                    image: NetworkImage(imageSnapshot.data!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
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
          );
        },
      ),
    );
  }
}
