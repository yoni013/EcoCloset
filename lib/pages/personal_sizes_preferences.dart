import 'package:flutter/material.dart';
import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../generated/l10n.dart';

class PersonalSizesPreferences extends StatefulWidget {
  const PersonalSizesPreferences({Key? key}) : super(key: key);

  @override
  _PersonalSizesPreferencesState createState() =>
      _PersonalSizesPreferencesState();
}

class _PersonalSizesPreferencesState extends State<PersonalSizesPreferences> {
  final Map<String, Set<String>> userSizes = {
    "Coats": {},
    "Sweaters": {},
    "T-Shirts": {},
    "Pants": {},
    "Shoes": {}
  };
  Map<String, List<String>> availableSizes = {
    "Coats": [],
    "Sweaters": [],
    "T-Shirts": [],
    "Pants": [],
    "Shoes": []
  };
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSizes();
  }

  Future<void> fetchSizes() async {
    await Utils.loadMetadata();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    setState(() {
      availableSizes = {
        "Coats": Utils.general_sizes,
        "Pants": Utils.pants_sizes,
        "T-Shirts": Utils.general_sizes,
        "Shoes": Utils.shoe_sizes,
        "Sweaters": Utils.general_sizes
      };
      if (userDoc.exists && userDoc.data()?.containsKey('Sizes') == true) {
        userSizes.addAll(
          (userDoc.data()?['Sizes'] as Map<String, dynamic>).map(
            (key, value) =>
                MapEntry(key, value is List ? Set<String>.from(value) : {}),
          ),
        );
      }
      isLoading = false;
    });
  }

  Future<void> updateUserSizes() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isNotEmpty) {
      final sizesToSave =
          userSizes.map((key, value) => MapEntry(key, value.toList()));
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update({'Sizes': sizesToSave});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).preferencesSaved)),
      );
    }
  }

  void modifySize(String category, String size, {required bool add}) {
    setState(() {
      add ? userSizes[category]?.add(size) : userSizes[category]?.remove(size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).sizePreferences)),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: availableSizes.keys.map((category) {
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Wrap(
                                spacing: 6.0,
                                children: userSizes[category]!
                                    .map((size) => Chip(
                                          label: Text(size,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                          deleteIcon:
                                              const Icon(Icons.close, size: 16),
                                          onDeleted: () => modifySize(
                                              category, size,
                                              add: false),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 6.0),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context).addSize,
                                  labelStyle:
                                      Theme.of(context).textTheme.bodySmall,
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                ),
                                items: availableSizes[category]!
                                    .map((size) => DropdownMenuItem(
                                          value: size,
                                          child: Text(size,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                        ))
                                    .toList(),
                                onChanged: (value) => value != null
                                    ? modifySize(category, value, add: true)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onPressed: updateUserSizes,
                    child: Text(AppLocalizations.of(context).savePreferences),
                  ),
                )
              ],
            ),
    );
  }
}
