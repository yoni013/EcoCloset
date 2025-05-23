import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../generated/l10n.dart';
import '../utils/fetch_item_metadata.dart';
import '../utils/translation_metadata.dart';

class EditItemPage extends StatefulWidget {
  final String itemId;

  const EditItemPage({
    Key? key,
    required this.itemId,
  }) : super(key: key);

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  late TextEditingController _brandController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  // Form data
  String? _selectedColor;
  String? _selectedCondition;
  String? _selectedSize;
  String? _selectedType;
  bool _isAvailable = true;

  // Dropdown data
  List<String> _brands = [];
  List<String> _colors = [];
  List<String> _conditions = [];
  List<String> _sizes = [];
  List<String> _types = [];

  // Image management
  List<String> _remoteImages = [];
  List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();

  // Loading and validation states
  bool _isLoading = true;
  bool _isDataLoaded = false;
  Map<String, dynamic>? _itemData;

  // Helper to get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    _brandController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Load dropdown data and item data concurrently
  Future<void> _loadInitialData() async {
    try {
      // Load metadata if not already loaded
      if (Utils.brands.isEmpty) {
        await Utils.loadMetadata();
      }

      // Load dropdown data and item data concurrently
      await Future.wait([
        _fetchDropdownData(),
        _fetchItemData(),
      ]);

      setState(() {
        _isLoading = false;
        _isDataLoaded = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorGeneric}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Fetch dropdown data from Utils
  Future<void> _fetchDropdownData() async {
    _brands = Utils.brands;
    _colors = Utils.colors;
    _conditions = Utils.conditions;
    _sizes = Utils.sizes;
    _types = Utils.types;
  }

  /// Fetch complete item data from Firestore
  Future<void> _fetchItemData() async {
    final doc = await FirebaseFirestore.instance
        .collection('Items')
        .doc(widget.itemId)
        .get();

    if (!doc.exists) {
      throw Exception(AppLocalizations.of(context).itemNotFound);
    }

    _itemData = doc.data()!;
    
    // Pre-fill form fields
    _brandController.text = _itemData?['Brand'] ?? '';
    _descriptionController.text = _itemData?['Description'] ?? '';
    _priceController.text = '${_itemData?['Price'] ?? ''}';
    
    _selectedColor = _itemData?['Color'];
    _selectedCondition = _itemData?['Condition'];
    _selectedSize = _itemData?['Size'];
    _selectedType = _itemData?['Type'];
    _isAvailable = (_itemData?['status'] ?? 'Available') == 'Available';

    // Handle existing images
    final images = _itemData?['images'];
    if (images != null && images is List) {
      _remoteImages = images.cast<String>();
    }
  }

  /// Pick new images from camera or gallery
  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context).takePhoto),
              onTap: () async {
                Navigator.pop(context);
                if (_getTotalImagesCount() >= 6) {
                  _showMaxImagesError();
                  return;
                }
                final XFile? cameraImage = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 50,
                );
                if (cameraImage != null) {
                  setState(() {
                    _newImages.add(cameraImage);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context).selectFromGallery),
              onTap: () async {
                Navigator.pop(context);
                final availableSlots = 6 - _getTotalImagesCount();
                if (availableSlots <= 0) {
                  _showMaxImagesError();
                  return;
                }
                
                final List<XFile>? pickedFiles = await _picker.pickMultiImage(
                  imageQuality: 50,
                  limit: availableSlots,
                );
                
                if (pickedFiles != null && pickedFiles.isNotEmpty) {
                  setState(() {
                    _newImages.addAll(pickedFiles);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  int _getTotalImagesCount() => _remoteImages.length + _newImages.length;

  void _showMaxImagesError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).maxImagesAllowed)),
    );
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

  /// Helper function to find matching dropdown value ignoring case
  String? _findIgnoreCase(List<String> list, String? value) {
    if (value == null) return null;
    final normalizedValue = value.trim().toLowerCase();
    for (final item in list) {
      if (item.trim().toLowerCase() == normalizedValue) {
        return item;
      }
    }
    return null;
  }

  /// Save all changes to Firestore
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Price validation and old price logic
    final newPrice = double.tryParse(_priceController.text.trim()) ?? 0;
    final oldPriceValue = _itemData?['oldPrice'];
    final currentPriceValue = (_itemData?['Price'] is num)
        ? (_itemData?['Price'] as num).toDouble()
        : null;

    double? updatedOldPrice;
    if (currentPriceValue != null) {
      if (newPrice < currentPriceValue) {
        if (oldPriceValue == null ||
            (oldPriceValue is num && oldPriceValue < currentPriceValue)) {
          updatedOldPrice = currentPriceValue;
        } else {
          updatedOldPrice = oldPriceValue;
        }
      } else if (newPrice > currentPriceValue) {
        updatedOldPrice = null; // Clear old price if price increased
      } else {
        updatedOldPrice = oldPriceValue; // Keep existing if same price
      }
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).savingChanges,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );

    try {
      // Upload new images to Firebase Storage
      List<String> newlyUploadedUrls = [];
      for (XFile img in _newImages) {
        final fileName = 'items/${widget.itemId}/${DateTime.now().millisecondsSinceEpoch}_${img.name}';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(File(img.path));
        final downloadUrl = await ref.getDownloadURL();
        newlyUploadedUrls.add(downloadUrl);
      }

      // Combine remote and newly uploaded images
      List<String> finalImageList = [..._remoteImages, ...newlyUploadedUrls];

      // Prepare update data
      final updateData = {
        'Brand': _brandController.text.trim(),
        'Color': _selectedColor,
        'Condition': _selectedCondition,
        'Size': _selectedSize,
        'Type': _selectedType,
        'Description': _descriptionController.text.trim(),
        'Price': newPrice,
        'images': finalImageList,
        'status': _isAvailable ? 'Available' : 'Sold Out',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Handle old price
      if (updatedOldPrice != null) {
        updateData['oldPrice'] = updatedOldPrice;
      } else {
        updateData['oldPrice'] = FieldValue.delete();
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('Items')
          .doc(widget.itemId)
          .update(updateData);

      Navigator.of(context, rootNavigator: true).pop(); // Remove loading
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).itemUpdatedSuccessfully),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true); // Return to previous page with success result
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Remove loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorSavingChanges}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildBrandAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _brands.where((option) => option
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        _brandController.text = selection;
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        // Sync the autocomplete controller with our main controller
        textEditingController.text = _brandController.text;
        textEditingController.selection = _brandController.selection;
        
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).brand,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            prefixIcon: const Icon(Icons.search),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).brandRequired;
            }
            return null;
          },
          onChanged: (value) {
            _brandController.text = value;
          },
          onFieldSubmitted: (value) {
            _brandController.text = value;
            onFieldSubmitted();
          },
        );
      },
    );
  }

  Widget _buildColorAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        final translatedColors = _colors
            .map((color) => TranslationUtils.getColor(color, context))
            .toList();
        return translatedColors.where((translatedColor) => translatedColor
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        // Find the original color value
        _selectedColor = _colors.firstWhere(
          (color) => TranslationUtils.getColor(color, context) == selection,
          orElse: () => selection,
        );
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        // Set initial value as translated color
        if (_selectedColor != null) {
          textEditingController.text = TranslationUtils.getColor(_selectedColor!, context);
        }
        
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).color,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            prefixIcon: const Icon(Icons.palette),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context).colorRequired;
            }
            return null;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).editItem),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isDataLoaded || _itemData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).editItem),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).errorGeneric,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Authorization check
    final sellerId = _itemData?['seller_id'];
    if (currentUserId == null || currentUserId != sellerId) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).unauthorized,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).unauthorizedAccess,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).unauthorizedMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).editItem,
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).basicInformation,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildBrandAutocomplete(),
                          const SizedBox(height: 16),
                          _buildColorAutocomplete(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).description,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.description),
                            ),
                            maxLines: 3,
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

                  // Item Properties Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).itemProperties,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).type,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.category),
                            ),
                            value: _selectedType,
                            items: _types
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(TranslationUtils.getCategory(type, context)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedType = val;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context).typeRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).size,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.straighten),
                            ),
                            value: _selectedSize,
                            items: _sizes
                                .map((size) => DropdownMenuItem(
                                      value: size,
                                      child: Text(size),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedSize = val;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context).sizeRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).condition,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.verified),
                            ),
                            value: _selectedCondition,
                            items: _conditions
                                .map((condition) => DropdownMenuItem(
                                      value: condition,
                                      child: Text(TranslationUtils.getCondition(condition, context)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCondition = val;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context).conditionRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutQuad,
                      ),
                  const SizedBox(height: 16),

                  // Price and Availability Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).priceAndAvailability,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).price,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              prefixText: '₪ ',
                              prefixIcon: const Icon(Icons.monetization_on),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context).priceRequired;
                              }
                              final double? d = double.tryParse(value);
                              if (d == null || d <= 0) {
                                return AppLocalizations.of(context).priceGreaterThanZero;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text(
                              _isAvailable
                                  ? AppLocalizations.of(context).available
                                  : AppLocalizations.of(context).soldOut,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            subtitle: Text(
                              _isAvailable
                                  ? AppLocalizations.of(context).itemIsAvailable
                                  : AppLocalizations.of(context).itemIsSoldOut,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            value: _isAvailable,
                            onChanged: (bool value) {
                              setState(() {
                                _isAvailable = value;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutQuad,
                      ),
                  const SizedBox(height: 16),

                  // Images Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context).images,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Chip(
                                label: Text('${_getTotalImagesCount()}/6'),
                                backgroundColor: _getTotalImagesCount() >= 6
                                    ? Theme.of(context).colorScheme.errorContainer
                                    : Theme.of(context).colorScheme.primaryContainer,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_remoteImages.isEmpty && _newImages.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context).noImagesAvailable,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_remoteImages.isNotEmpty) ...[
                                  Text(
                                    AppLocalizations.of(context).existingImages,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1,
                                    ),
                                    itemCount: _remoteImages.length,
                                    itemBuilder: (context, index) {
                                      final imageUrl = _remoteImages[index];
                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Card(
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: index == 0
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (ctx, url) => Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceVariant,
                                                child: const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              ),
                                              errorWidget: (ctx, url, err) => Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceVariant,
                                                child: Icon(
                                                  Icons.error,
                                                  color: Theme.of(context).colorScheme.error,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (index == 0)
                                            Positioned(
                                              top: 4,
                                              left: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  AppLocalizations.of(context).mainImage,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: IconButton(
                                              icon: const Icon(Icons.close),
                                              style: IconButton.styleFrom(
                                                backgroundColor: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                foregroundColor: Theme.of(context)
                                                    .colorScheme
                                                    .error,
                                                padding: const EdgeInsets.all(4),
                                              ),
                                              onPressed: () => _removeRemoteImage(index),
                                            ),
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => _makeRemoteImageMain(index),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                                if (_newImages.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context).newImages,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1,
                                    ),
                                    itemCount: _newImages.length,
                                    itemBuilder: (context, index) {
                                      final file = _newImages[index];
                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Card(
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: _remoteImages.isEmpty && index == 0
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: Image.file(
                                              File(file.path),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          if (_remoteImages.isEmpty && index == 0)
                                            Positioned(
                                              top: 4,
                                              left: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  AppLocalizations.of(context).mainImage,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: IconButton(
                                              icon: const Icon(Icons.close),
                                              style: IconButton.styleFrom(
                                                backgroundColor: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                foregroundColor: Theme.of(context)
                                                    .colorScheme
                                                    .error,
                                                padding: const EdgeInsets.all(4),
                                              ),
                                              onPressed: () => _removeNewImage(index),
                                            ),
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => _makeNewImageMain(index),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _getTotalImagesCount() < 6 ? _pickImages : null,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: Text(AppLocalizations.of(context).addImages),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutQuad,
                      ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
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
                          onPressed: _saveChanges,
                          icon: const Icon(Icons.save),
                          label: Text(AppLocalizations.of(context).saveChanges),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutQuad,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
