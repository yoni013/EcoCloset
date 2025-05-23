import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    categoryLocalized,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MultiSelectDialogField<String>(
              title: Text(categoryLocalized),
              items: items,
              searchable: true,
              initialValue: userSizes[category]?.toList() ?? [],
              buttonText: Text(
                AppLocalizations.of(context).selectSizes(categoryLocalized),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              buttonIcon: const Icon(Icons.arrow_drop_down),
              selectedItemsTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              searchTextStyle: Theme.of(context).textTheme.bodyLarge,
              itemsTextStyle: Theme.of(context).textTheme.bodyLarge,
              chipDisplay: MultiSelectChipDisplay(
                chipColor: Theme.of(context).colorScheme.primaryContainer,
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onConfirm: (List<String> selectedValues) {
                setState(() {
                  userSizes[category] = selectedValues.toSet();
                });
              },
            ),
          ],
        ),
      ),
    ).animate(delay: (50 * availableSizes.keys.toList().indexOf(category)).ms).fadeIn(
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        ).slideY(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuad,
        );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Coats':
        return Icons.checkroom;
      case 'Sweaters':
        return Icons.dry_cleaning;
      case 'T-Shirts':
        return Icons.checkroom_outlined;
      case 'Pants':
        return Icons.accessibility_new;
      case 'Shoes':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).sizePreferences,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).loading,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms)
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context).sizePreferencesInfo,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context).sizePreferencesDescription,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(
                              begin: 0.2,
                              end: 0,
                              duration: 600.ms,
                              curve: Curves.easeOutQuad,
                            ),
                        const SizedBox(height: 16),
                        ...availableSizes.keys.map((category) {
                          return Column(
                            children: [
                              _buildMultiselectField(category),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                            label: Text(AppLocalizations.of(context).cancel),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await updateUserSizes();
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: Text(AppLocalizations.of(context).savePreferences),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutQuad,
                      ),
                ],
              ),
      ),
    );
  }
}
