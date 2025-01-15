import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
      final buyerDoc = await FirebaseFirestore.instance.collection('Users').doc(buyerId).get();
      return buyerDoc.data()?['Name'] ?? 'Unknown Buyer';
    } catch (e) {
      print('Error fetching buyer name: $e');
      return 'Unknown Buyer';
    }
  }

Future<String?> fetchItemImage(String itemId) async {
  try {
    final itemDoc = await FirebaseFirestore.instance.collection('Items').doc(itemId).get();
    final List<dynamic>? images = itemDoc.data()?['images'];
    if (images != null && images.isNotEmpty) {
      final String imagePath = images[0];
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    }
    return null;
  } catch (e) {
    print('Error fetching item image: $e');
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
          "FinalPrice": "\$${(data['FinalPrice'] ?? 0).toStringAsFixed(2)}",
          "Status": data['Status'] ?? "Pending",
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
      print("Error fetching orders: $e");
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .update({'Status': status});
      fetchOrders();
    } catch (e) {
      print("Error updating order status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Shop")
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: MediaQuery.of(context).size.width, // Make table full width
          columns: [
            DataColumn(label: Text("Item")),
            DataColumn(label: Text("Buyer")),
            DataColumn(label: Text("Price")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Actions")),
          ],
          rows: orders.map((order) {
            return DataRow(cells: [
              DataCell(order["ItemImage"] != null
                  ? GestureDetector(
                      onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemPage(itemId: order['ItemID']),
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
              DataCell(Text(order["BuyerName"] ?? "Unknown Buyer")),
              DataCell(Text(order["FinalPrice"] ?? "\$0.00")),
              DataCell(Text(order["Status"] ?? "Unknown")),
              DataCell(PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'approve') {
                    updateOrderStatus(order["actions"], "Approved");
                  } else if (value == 'decline') {
                    updateOrderStatus(order["actions"], "Declined");
                  } else if (value == 'shipped') {
                    updateOrderStatus(order["actions"], "Shipped");
                  }
                },
                itemBuilder: (context) {
                  final List<PopupMenuEntry<String>> options = [];
                  if (order["Status"] == "Pending") {
                    options.add(PopupMenuItem(value: "approve", child: Text("Approve")));
                    options.add(PopupMenuItem(value: "decline", child: Text("Decline")));
                  } else if (order["Status"] == "Approved") {
                    options.add(PopupMenuItem(value: "shipped", child: Text("Mark as Shipped")));
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
