/// item_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eco_closet/pages/edit_item_page.dart';
import 'package:eco_closet/utils/translation_metadata.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/pages/profile_page.dart';
import '../generated/l10n.dart';

class ItemPage extends StatelessWidget {
  final String itemId;

  ItemPage({required this.itemId});

  Future<Map<String, dynamic>> fetchItemData() async {
    var documentSnapshot =
        await FirebaseFirestore.instance.collection('Items').doc(itemId).get();
    return documentSnapshot.data() ?? {};
  }

  Future<Map<String, dynamic>> fetchSellerData(String sellerId) async {
    var documentSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(sellerId)
        .get();
    return documentSnapshot.data() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).itemDetails),
        centerTitle: true,
        actions: [

          if (true) //add condition if this is the seller
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditItemPage(
                      itemId: itemId,
                      initialItemData: {}, // send the item's data
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchItemData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context).failedToLoadItem));
          }

          var itemData = snapshot.data!;
          var images = itemData['images'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (images.isEmpty)
                      Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image, size: 48)),
                      )
                    else
                      Container(
                        height: 300,
                        child: PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        itemData['Brand'] ??
                            AppLocalizations.of(context).unknownItem,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\₪${itemData['Price'] ?? AppLocalizations.of(context).notAvailable}',
                        style: const TextStyle(
                            fontSize: 20,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context).condition}: ${TranslationUtils.getCondition(itemData['Condition'], context)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context).size}: ${itemData['Size'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).description,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemData['Description'] ??
                        AppLocalizations.of(context).noDescription,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: (itemData['Tags'] as List<dynamic>?)
                            ?.map((tag) => Chip(label: Text(tag)))
                            .toList() ??
                        [],
                  ),
                  const Divider(height: 32),
                  FutureBuilder<Map<String, dynamic>>(
                    future: fetchSellerData(itemData['seller_id'] ?? ''),
                    builder: (context, sellerSnapshot) {
                      if (sellerSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: const CircularProgressIndicator(),
                          ),
                          title:
                              Text(AppLocalizations.of(context).loadingSeller),
                        );
                      } else if (sellerSnapshot.hasError ||
                          !sellerSnapshot.hasData ||
                          sellerSnapshot.data!.isEmpty) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.person, size: 32),
                          ),
                          title:
                              Text(AppLocalizations.of(context).unknownSeller),
                        );
                      }

                      var sellerData = sellerSnapshot.data!;
                      return ListTile(
                      leading: sellerData['profilePicUrl'] != null && sellerData['profilePicUrl'].isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(sellerData['profilePicUrl']),
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: const Icon(Icons.person, size: 32),
                            ),
                        title: Text(sellerData['name'] ??
                            AppLocalizations.of(context).unknownSeller),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.yellow, size: 16),
                            Text(
                              '${(sellerData['average_rating'] != null) 
                                  ? (sellerData['average_rating'] as num).toStringAsFixed(1) 
                                  : 'N/A'} '
                              '(${sellerData['num_of_reviewers'] ?? 0} ${AppLocalizations.of(context).reviews})',
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                  viewedUserId: itemData['seller_id'] ?? ''),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Contact Seller action
                        },
                        child: Text(AppLocalizations.of(context).contactSeller),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Buy Now action
                        },
                        child: Text(AppLocalizations.of(context).buyNow),
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
