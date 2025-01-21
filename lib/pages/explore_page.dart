import 'package:eco_closet/pages/explore_category_page.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Sweaters', 'image': 'assets/images/sweaters.png'},
      {'name': 'Coats', 'image': 'assets/images/coats.png'},
      {'name': 'Dresses', 'image': 'assets/images/dresses.png'},
      {'name': 'T-Shirts', 'image': 'assets/images/shirts.png'},
      {'name': 'Pants',  'image': 'assets/images/pants.png'},
      {'name': 'Shoes',  'image': 'assets/images/shoes.png'},
      {'name': '',  'image': 'assets/images/all.png'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Categories')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoryItemsPage(category: cat['name']!),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      child: Image.asset(
                        cat['image']!,
                        fit: BoxFit.fitHeight,
                        width: 90,
                        height: 95,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name
                    Expanded(
                      child: Text(
                        (cat['name'] != null && cat['name']!.isNotEmpty) ? cat['name']! : 'Shop All',
                        style: Theme.of(context).textTheme.titleLarge
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            );
          },
        ),
      )
    );
  }
}
