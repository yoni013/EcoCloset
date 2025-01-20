import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../generated/l10n.dart';
import 'item_page.dart';

class MyShopPage extends StatefulWidget {
  @override
  _MyShopPageState createState() => _MyShopPageState();
}

class _MyShopPageState extends State<MyShopPage> {
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<String> fetchBuyerName(String buyerId) async {
    try {
      final buyerDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(buyerId)
          .get();
      return buyerDoc.data()?['Name'] ??
          AppLocalizations.of(context).unknownBuyer;
    } catch (e) {
      print(AppLocalizations.of(context).errorFetchingBuyer + e.toString());
      return AppLocalizations.of(context).unknownBuyer;
    }
  }

  Future<String?> fetchItemImage(String itemId) async {
    try {
      final itemDoc = await FirebaseFirestore.instance
          .collection('Items')
          .doc(itemId)
          .get();
      final List<dynamic>? images = itemDoc.data()?['images'];
      if (images != null && images.isNotEmpty) {
        final String imagePath = images[0];
        return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
      }
      return null;
    } catch (e) {
      print(AppLocalizations.of(context).errorFetchingImage + e.toString());
      return null;
    }
  }

  Future<void> fetchOrders() async {
    final sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (sellerId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('SellerID', isEqualTo: sellerId)
          .get();

      final List<Map<String, dynamic>> fetchedOrders = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final buyerName = await fetchBuyerName(data['BuyerID'] ?? '');
        final itemImage = await fetchItemImage(data['ItemID'] ?? '');
        fetchedOrders.add({
          "BuyerName": buyerName,
          "FinalPrice": "\₪${(data['FinalPrice'] ?? 0).toStringAsFixed(2)}",
          "Status": data['Status'] ?? AppLocalizations.of(context).pending,
          "ItemImage": itemImage,
          "ItemID": data['ItemID'],
          "actions": doc.id,
        });
      }
      if (mounted) {
        setState(() {
          orders = fetchedOrders;
        });
      }
    } catch (e) {
      print(AppLocalizations.of(context).errorFetchingOrders + e.toString());
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .update({
        'Status': status,
      });
      fetchOrders();
    } catch (e) {
      print(AppLocalizations.of(context).errorUpdatingStatus + e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).myShop)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: MediaQuery.of(context).size.width,
          columns: [
            DataColumn(label: Text(AppLocalizations.of(context).item)),
            DataColumn(label: Text(AppLocalizations.of(context).buyer)),
            DataColumn(label: Text(AppLocalizations.of(context).price)),
            DataColumn(label: Text(AppLocalizations.of(context).status)),
            DataColumn(label: Text(AppLocalizations.of(context).actions)),
          ],
          rows: orders.map((order) {
            return DataRow(cells: [
              DataCell(order["ItemImage"] != null
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ItemPage(itemId: order['ItemID']),
                          ),
                        );
                      },
                      child: Image.network(
                        order["ItemImage"],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.image_not_supported)),
              DataCell(Text(order["BuyerName"] ??
                  AppLocalizations.of(context).unknownBuyer)),
              DataCell(Text(order["FinalPrice"] ?? "₪0.00")),
              DataCell(Text(
                  order["Status"] ?? AppLocalizations.of(context).unknown)),
              DataCell(PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'approve') {
                    updateOrderStatus(order["actions"],
                        AppLocalizations.of(context).approved);
                  } else if (value == 'decline') {
                    updateOrderStatus(order["actions"],
                        AppLocalizations.of(context).declined);
                  } else if (value == 'shipped') {
                    updateOrderStatus(
                        order["actions"], AppLocalizations.of(context).shipped);
                  }
                },
                itemBuilder: (context) {
                  final List<PopupMenuEntry<String>> options = [];
                  if (order["Status"] == AppLocalizations.of(context).pending) {
                    options.add(PopupMenuItem(
                        value: "approve",
                        child: Text(AppLocalizations.of(context).approve)));
                    options.add(PopupMenuItem(
                        value: "decline",
                        child: Text(AppLocalizations.of(context).decline)));
                  } else if (order["Status"] ==
                      AppLocalizations.of(context).approved) {
                    options.add(PopupMenuItem(
                        value: "shipped",
                        child:
                            Text(AppLocalizations.of(context).markAsShipped)));
                  }
                  return options;
                },
                icon: Icon(Icons.more_vert),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
