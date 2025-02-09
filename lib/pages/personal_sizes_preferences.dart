import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import 'package:eco_closet/utils/fetch_item_metadata.dart';

import 'package:eco_closet/generated/l10n.dart';

class PersonalSizesPreferences extends StatefulWidget {
  const PersonalSizesPreferences({Key? key}) : super(key: key);

  @override
  _PersonalSizesPreferencesState createState() =>
      _PersonalSizesPreferencesState();
}

class _PersonalSizesPreferencesState extends State<PersonalSizesPreferences> {
  // Map of category -> selected sizes (Set of strings for each category)
  final Map<String, Set<String>> userSizes = {
    'Coats': {},
    'Sweaters': {},
    'T-Shirts': {},
    'Pants': {},
    'Shoes': {},
  };

  // Map of category -> available sizes (List of possible sizes)
  Map<String, List<String>> availableSizes = {
    'Coats': [],
    'Sweaters': [],
    'T-Shirts': [],
    'Pants': [],
    'Shoes': [],
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSizes();
  }

  /// Fetch sizes from metadata and user document
  Future<void> fetchSizes() async {
    await Utils.loadMetadata(); // Load your metadata (size lists) first

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();

    setState(() {
      // Load available sizes from the Utils class
      availableSizes = {
        'Coats': Utils.general_sizes,
        'Pants': Utils.pants_sizes,
        'T-Shirts': Utils.general_sizes,
        'Shoes': Utils.shoe_sizes,
        'Sweaters': Utils.general_sizes
      };

      // If user document exists and has "Sizes" field, populate userSizes
      if (userDoc.exists && userDoc.data()?.containsKey('Sizes') == true) {
        final Map<String, dynamic> sizesMap =
            userDoc.data()?['Sizes'] as Map<String, dynamic>;
        sizesMap.forEach((key, value) {
          // Ensure we convert the stored list to a Set<String>
          userSizes[key] = (value is List) ? Set<String>.from(value) : {};
        });
      }
      isLoading = false;
    });
  }

  /// Updates user sizes in Firestore
  Future<void> updateUserSizes() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      // Convert each Set<String> to a List<String> before saving
      final sizesToSave = userSizes.map(
        (key, value) => MapEntry(key, value.toList()),
      );

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update({'Sizes': sizesToSave});
    }
  }

  /// Builds a MultiSelectDialogField for a given category
  Widget _buildMultiselectField(String category) {
    // Convert each available size into a MultiSelectItem for the dialog
    final items = availableSizes[category]!
        .map((size) => MultiSelectItem<String>(size, size))
        .toList();
    
    final categoryLocalized = {
      'Coats': AppLocalizations.of(context).categoryCoats,
      'Sweaters': AppLocalizations.of(context).categorySweaters,
      'T-Shirts': AppLocalizations.of(context).categoryShirts,
      'Pants': AppLocalizations.of(context).categoryPants,
      'Shoes': AppLocalizations.of(context).categoryShoes,
    }[category] ?? category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: MultiSelectDialogField<String>(
        title: Text(categoryLocalized),
        // The list of items to display in the multi-select dialog
        items: items,
        // Show a search bar in the dialog (optional)
        searchable: true,
        // Pre-select currently chosen sizes
        initialValue: userSizes[category]?.toList() ?? [],
        // How the field looks on the main form
        buttonText: Text(AppLocalizations.of(context).selectSizes(categoryLocalized)),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        onConfirm: (List<String> selectedValues) {
          setState(() {
            userSizes[category] = selectedValues.toSet();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).sizePreferences),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: availableSizes.keys.map((category) {
                      return _buildMultiselectField(category);
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await updateUserSizes();
                      Navigator.pop(
                          context); // <-- Returns to the previous screen
                    },
                    child: Text(AppLocalizations.of(context).savePreferences),
                  ),
                )
              ],
            ),
    );
  }
}
