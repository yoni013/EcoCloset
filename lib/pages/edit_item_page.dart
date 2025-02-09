import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Example: If you need localization, import your localizations
import '../generated/l10n.dart';

class EditItemPage extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> initialItemData;

  const EditItemPage({
    Key? key,
    required this.itemId,
    required this.initialItemData,
  }) : super(key: key);

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _formKey = GlobalKey<FormState>();

  // We will store the updated fields here
  late TextEditingController _brandController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  String? _condition;
  bool _isAvailable = true; // For availability status

  // If you have categories or types:
  String? _category;
  List<String> _possibleCategories = ['Tops', 'Pants', 'Shoes']; // Example

  // We also need to manage images
  List<String> _remoteImages = []; // Existing URLs
  List<XFile> _newImages = []; // Newly selected local images
  final ImagePicker _picker = ImagePicker();

  // A helper function to get the user id
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    // Pre-fill from widget.initialItemData
    _brandController =
        TextEditingController(text: widget.initialItemData['Brand'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialItemData['Description'] ?? '');
    _priceController =
        TextEditingController(text: '${widget.initialItemData['Price'] ?? ''}');
    _condition = widget.initialItemData['Condition'] ?? 'Used'; 
    _isAvailable =
        (widget.initialItemData['status'] ?? 'Available') == 'Available';

    // If there's a category or a type
    _category = widget.initialItemData['Category'] ?? null;

    // The existing remote images from Firestore
    final images = widget.initialItemData['images'];
    if (images != null && images is List) {
      _remoteImages = images.cast<String>();
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Pick an image from camera or gallery
  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage(
      imageQuality: 50,
    );
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        // Append new images
        _newImages.addAll(pickedFiles);
      });
    }
  }

  /// Remove a remote image
  void _removeRemoteImage(int index) {
    setState(() {
      _remoteImages.removeAt(index);
    });
  }

  /// Remove a newly added local image
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  /// Move a remote image to the front (main image)
  void _makeRemoteImageMain(int index) {
    setState(() {
      final image = _remoteImages.removeAt(index);
      _remoteImages.insert(0, image);
    });
  }

  /// Move a local image to the front (main image)
  void _makeNewImageMain(int index) {
    setState(() {
      final image = _newImages.removeAt(index);
      _newImages.insert(0, image);
    });
  }

  /// Submit updated data to Firestore
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Price logic (old price vs new price)
    final newPrice = double.tryParse(_priceController.text.trim()) ?? 0;
    final oldPriceValue = widget.initialItemData['oldPrice'];
    final currentPriceValue =
        (widget.initialItemData['Price'] is num) ? widget.initialItemData['Price'].toDouble() : null;

    double? updatedOldPrice;
    if (currentPriceValue != null) {
      // If new price is lower than the current price, we set oldPrice to the current price (if it isn't already higher)
      if (newPrice < currentPriceValue) {
        // If oldPrice doesn't exist or is less than currentPrice, set it
        if (oldPriceValue == null || (oldPriceValue is num && oldPriceValue < currentPriceValue)) {
          updatedOldPrice = currentPriceValue;
        } else {
          // If oldPrice is already bigger, keep it
          updatedOldPrice = oldPriceValue;
        }
      } else {
        // If the user increased the price or kept it the same, you may decide to clear the old price or keep it
        // For example, let's clear oldPrice if the price is now higher
        if (newPrice > currentPriceValue) {
          updatedOldPrice = null; 
        } else {
          // same price
          updatedOldPrice = oldPriceValue; 
        }
      }
    }

    // Start a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1) If new images exist, upload them first to Firebase Storage
      List<String> newlyUploadedUrls = [];
      for (XFile img in _newImages) {
        final fileName = 'items/${widget.itemId}/${DateTime.now().millisecondsSinceEpoch}_${img.name}';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(File(img.path));
        final downloadUrl = await ref.getDownloadURL();
        newlyUploadedUrls.add(downloadUrl);
      }

      // 2) Combine remote and newly uploaded images
      // Make sure the order is maintained with the "main" images at index 0
      List<String> finalImageList = [..._remoteImages, ...newlyUploadedUrls];

      // 3) Prepare the data to update in Firestore
      // Only the seller should be able to do this, so we can add a check or assume this page is only accessible if user is the seller
      final updateData = {
        'Brand': _brandController.text.trim(),
        'Description': _descriptionController.text.trim(),
        'Price': newPrice,
        'Condition': _condition ?? 'Used',
        'Category': _category,
        'images': finalImageList,
        'status': _isAvailable ? 'Available' : 'Sold Out',
      };

      // If we have a computed oldPrice
      if (updatedOldPrice != null) {
        updateData['oldPrice'] = updatedOldPrice;
      } else {
        // Optionally remove oldPrice field if you want
        updateData['oldPrice'] = FieldValue.delete();
      }

      // 4) Update Firestore
      await FirebaseFirestore.instance
          .collection('Items')
          .doc(widget.itemId)
          .update(updateData);

      Navigator.of(context, rootNavigator: true).pop(); // remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!')),
      );

      Navigator.pop(context); // pop EditItemPage
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // We can only allow this page if the currentUser is the seller
    final sellerId = widget.initialItemData['seller_id'];
    if (currentUserId == null || currentUserId != sellerId) {
      // If you want to handle unauthorized access more gracefully:
      return Scaffold(
        appBar: AppBar(
          title: const Text('Unauthorized'),
        ),
        body: const Center(
          child: Text('You do not have permission to edit this item.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).editItem),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Item name / Brand
                TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).itemName,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context).thisFieldIsRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description (multiline)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).description,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).price,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context).thisFieldIsRequired;
                    }
                    final double? d = double.tryParse(value);
                    if (d == null || d <= 0) {
                      return AppLocalizations.of(context).invalidPrice;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).category,
                  ),
                  value: _category,
                  items: _possibleCategories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _category = val;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context).thisFieldIsRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Condition (dropdown)
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).condition,
                  ),
                  value: _condition,
                  items: <String>['New', 'Like New', 'Used', 'Refurbished']
                      .map((cond) => DropdownMenuItem(value: cond, child: Text(cond)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _condition = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Availability toggle
                SwitchListTile(
                  title: Text(_isAvailable
                      ? AppLocalizations.of(context).available
                      : AppLocalizations.of(context).soldOut),
                  value: _isAvailable,
                  onChanged: (bool value) {
                    setState(() {
                      _isAvailable = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Existing images (remote) with ability to reorder, remove, set main
                Text(
                  AppLocalizations.of(context).existingImages,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_remoteImages.isEmpty)
                  Text(AppLocalizations.of(context).noImagesAvailable)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _remoteImages.length,
                    itemBuilder: (context, index) {
                      final imageUrl = _remoteImages[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () => _makeRemoteImageMain(index),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (ctx, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (ctx, url, err) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                          title: Text(index == 0
                              ? AppLocalizations.of(context).mainImage
                              : AppLocalizations.of(context).image),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeRemoteImage(index),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),

                // Newly added local images
                Text(
                  AppLocalizations.of(context).newImages,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _newImages.isEmpty
                    ? Text(AppLocalizations.of(context).none)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _newImages.length,
                        itemBuilder: (context, index) {
                          final XFile file = _newImages[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: GestureDetector(
                                onTap: () => _makeNewImageMain(index),
                                child: SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Image.file(File(file.path), fit: BoxFit.cover),
                                ),
                              ),
                              title: Text(index == 0
                                  ? AppLocalizations.of(context).mainImage
                                  : AppLocalizations.of(context).image),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeNewImage(index),
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 16),

                // Button to pick more images
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context).addImages),
                ),
                const SizedBox(height: 24),

                // Buttons: Cancel, Save
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // discard changes
                      },
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: Text(AppLocalizations.of(context).saveChanges),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
