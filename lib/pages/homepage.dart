/// homepage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'item_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to the Marketplace!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Featured Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Items').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var items = snapshot.data!.docs;
                  return Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        var item = items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Chip(
                            label: Text(item['Type'] ?? 'Unknown'),
                            backgroundColor: Colors.blue.shade100,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              Divider(height: 32, thickness: 1),
              Text(
                'Recommended for You',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Items').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var items = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var item = items[index];
                      var images = item['images'] as List<dynamic>?;
                      var imageUrl = images != null && images.isNotEmpty ? images[0] : '';
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemPage(itemId: item.id),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: FutureBuilder<String>(
                              future: FirebaseStorage.instance.ref(imageUrl).getDownloadURL(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshot.hasError || !snapshot.hasData) {
                                  return Icon(Icons.image_not_supported);
                                } else {
                                  return CircleAvatar(
                                    backgroundImage: NetworkImage(snapshot.data!),
                                  );
                                }
                              },
                            ),
                            title: Text(item['Brand'] ?? 'Unknown'),
                            subtitle: Text(item['Description'] ?? 'No description'),
                            trailing: Text('\₪${item['Price'] ?? 'N/A'}'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/explore');
                },
                child: Text('Explore'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/upload');
                },
                child: Text('Upload'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: Text('Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
