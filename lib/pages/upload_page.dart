import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:eco_closet/utils/get_recommended_price.dart';
import 'package:eco_closet/utils/translation_metadata.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';
import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/upload_with_tags.dart';
import '../pages/item_page.dart';

class UploadItemPage extends StatefulWidget {
  @override
  _UploadItemPageState createState() => _UploadItemPageState();
}

class _UploadItemPageState extends State<UploadItemPage> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  /// Dropdown data
  List<String> _brands = [];
  List<String> _colors = [];
  List<String> _conditions = [];
  List<String> _sizes = [];
  List<String> _types = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final brandsSnapshot = await Utils.brands;
      final colorsSnapshot = await Utils.colors;
      final conditionsSnapshot = await Utils.conditions;
      final sizesSnapshot = await Utils.sizes;
      final typesSnapshot = await Utils.types;

      setState(() {
        _brands = brandsSnapshot;
        _colors = colorsSnapshot;
        _conditions = conditionsSnapshot;
        _sizes = sizesSnapshot;
        _types = typesSnapshot;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).failedToFetchDropdownData}: $e')),
      );
    }
  }

  Future<void> _pickImageSource() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context).takePhoto),
              onTap: () async {
                Navigator.pop(context);
                if (_images.length >= 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            AppLocalizations.of(context).maxImagesAllowed)),
                  );
                  return;
                }
                
                try {
                  final XFile? cameraImage = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 50,
                    maxWidth: 1920,
                    maxHeight: 1080,
                  );
                  
                  if (cameraImage != null) {
                    setState(() {
                      if (_images.length < 6) {
                        _images.add(cameraImage);
                      }
                    });
                  } else {
                    // User cancelled camera
                    debugPrint('Camera cancelled by user');
                  }
                } catch (e) {
                  debugPrint('Error taking photo: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error taking photo: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context).selectFromGallery),
              onTap: () async {
                Navigator.pop(context);
                
                try {
                  final pickedImages = await _picker.pickMultiImage(
                    imageQuality: 50,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    // You can pick multiple images here; limit them to 6
                    limit: 6 - _images.length, // Only allow remaining slots
                  );
                  
                  if (pickedImages.isNotEmpty) {
                    setState(() {
                      for (var img in pickedImages) {
                        if (_images.length < 6) {
                          _images.add(img);
                        } else {
                          break;
                        }
                      }
                    });
                  } else {
                    // User cancelled gallery selection
                    debugPrint('Gallery selection cancelled by user');
                  }
                } catch (e) {
                  debugPrint('Error selecting from gallery: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error selecting images: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final XFile item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  Future<Map<String, dynamic>> _callGemini() async {
    try {
      // Define the JSON schema for structured output
      final jsonSchema = Schema.object(properties: {
        'item_name': Schema.string(description: 'A descriptive name for the item (2-4 words)'),
        'Brand': Schema.string(description: 'Brand of the item, or empty string if unknown'),
        'Color': Schema.string(description: 'Color of the item'),
        'Condition': Schema.string(description: 'Condition of the item'),
        'Size': Schema.string(description: 'Size of the item'),
        'Type': Schema.string(description: 'Type of the item - one of: Activewear,Belts,Coats,Dresses,Gloves,Hats,Jeans,Jumpsuits,Overalls,Pants,Scarves,Shirts,Shoes,Shorts,Skirts,Sleepwear,Sweaters,Swimwear'),
      });

      // Initialize the Gemini Developer API backend service using Firebase AI Logic
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        // Configure for structured JSON output
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: jsonSchema,
        ),
      );

      // Convert images to Content objects
      List<Content> contentParts = [];
      
      // Add images as content parts
      for (var image in _images) {
        final bytes = await File(image.path).readAsBytes();
        contentParts.add(Content.inlineData('image/jpeg', bytes));
      }

      // Add the text prompt
      contentParts.add(Content.text('''
        Analyze the provided images of the clothing item and extract the following metadata:
        1. Generate a descriptive item name (2-4 words) that captures the essence of the item (e.g., "Blue Denim Jacket", "Red Summer Dress", "Black Running Shoes")
        2. Identify the brand if visible on tags or labels
        3. Determine the exact color(s)
        4. Assess the condition based on visible wear, stains, or damage
        5. Identify the size from tags or labels
        6. Determine the type of clothing item
        
        For the item name, create something descriptive and appealing that a buyer would find attractive. Focus on key visual features like color, style, or distinctive characteristics.
        Focus on accuracy and provide specific details when possible.
      '''));

      // Generate content using Firebase AI Logic
      final response = await model.generateContent(contentParts);
      
      debugPrint('Gemini Response: ${response.text}');

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No response from Gemini');
      }

      // Parse the structured JSON response
      var decoded = jsonDecode(response.text!) as Map<String, dynamic>;

      // Validate and clean up the response
      return {
        'item_name': decoded['item_name']?.toString() ?? '',
        'Brand': decoded['Brand']?.toString() ?? '',
        'Color': decoded['Color']?.toString() ?? '',
        'Condition': decoded['Condition']?.toString() ?? '',
        'Size': decoded['Size']?.toString() ?? '',
        'Type': decoded['Type']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint('Error in Gemini analysis: $e');
      throw Exception('${AppLocalizations.of(context).errorProcessingImages}: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context).photoTips,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontStyle: FontStyle.italic,
                        ),
                  ).animate().fadeIn(duration: 600.ms),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).mainImageInstructions,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: _images.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context).pickImages,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 600.ms)
                          : Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.drag_handle,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Drag to reorder images',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ReorderableListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _images.length,
                                    onReorder: _onReorder,
                                    proxyDecorator: (child, index, animation) {
                                      return AnimatedBuilder(
                                        animation: animation,
                                        builder: (BuildContext context, Widget? child) {
                                          final double animValue = Curves.easeInOut.transform(animation.value);
                                          final double elevation = lerpDouble(0, 6, animValue)!;
                                          final double scale = lerpDouble(1, 1.02, animValue)!;
                                          return Transform.scale(
                                            scale: scale,
                                            child: Card(
                                              elevation: elevation,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: child,
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final image = _images[index];
                                      return Card(
                                        key: ValueKey(image.path),
                                        elevation: 0,
                                        margin: const EdgeInsets.only(right: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Container(
                                          width: 160,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              // Image preview
                                              Image.file(
                                                File(image.path),
                                                fit: BoxFit.cover,
                                              ),
                                              // Main image badge
                                              if (index == 0)
                                                Positioned(
                                                  top: 8,
                                                  left: 8,
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
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              // Drag handle
                                              Positioned(
                                                bottom: 8,
                                                left: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surface
                                                        .withOpacity(0.8),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.drag_handle,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                              // Remove button
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close),
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    foregroundColor: Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                  ),
                                                  onPressed: () => _removeImage(index),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ).animate(delay: (50 * index).ms)
                                          .fadeIn(
                                            duration: 600.ms,
                                            curve: Curves.easeOutQuad,
                                          )
                                          .slideX(
                                            begin: 0.2,
                                            end: 0,
                                            duration: 600.ms,
                                            curve: Curves.easeOutQuad,
                                          ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImageSource,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: Text(AppLocalizations.of(context).pickImages),
                            style: ElevatedButton.styleFrom(
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
                            onPressed: _images.isNotEmpty
                                ? () async {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const CircularProgressIndicator(),
                                            const SizedBox(height: 16),
                                            Text(
                                              AppLocalizations.of(context)
                                                  .analyzingImages,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );

                                    try {
                                      final metadata = await _callGemini();
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();

                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => _StepTwoForm(
                                            images: _images,
                                            brands: _brands,
                                            colors: _colors,
                                            conditions: _conditions,
                                            sizes: _sizes,
                                            types: _types,
                                            prefilledData: metadata,
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        setState(() {});
                                      }
                                    } catch (e) {
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('${AppLocalizations.of(context).errorProcessingImages}: $e'),
                                          backgroundColor:
                                              Theme.of(context).colorScheme.error,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(AppLocalizations.of(context).next),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutQuad,
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTwoForm extends StatelessWidget {
  final List<XFile> images;
  final List<String> brands;
  final List<String> colors;
  final List<String> conditions;
  final List<String> sizes;
  final List<String> types;
  final Map<String, dynamic> prefilledData;

  _StepTwoForm({
    required this.images,
    required this.brands,
    required this.colors,
    required this.conditions,
    required this.sizes,
    required this.types,
    required this.prefilledData,
  });

  /// Finds a matching string in [list] that equals [value] (ignoring case),
  /// returns `null` if no match found.
  String? _findIgnoreCase(List<String> list, String? value) {
    if (value == null) return null;
    final normalizedValue = value.trim().toLowerCase();
    for (final item in list) {
      if (item.trim().toLowerCase() == normalizedValue) {
        return item; // Return the actual string from the list
      }
    }
    return null;
  }

  /// Upload item details (with images) to Firestore using new tagging system
  Future<String?> _uploadItemToFirebase(
    Map<String, dynamic> formData,
    BuildContext context,
  ) async {
    try {
      // Use the centralized upload function with proper tagging
      final itemId = await UploadWithTags.uploadItemWithTags(
        images: images,
        formData: formData,
        context: context,
      );

      debugPrint('✅ Item uploaded successfully with ID: $itemId');
      return itemId;

    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    // Use the helper to find a match ignoring case
    final matchedBrand = _findIgnoreCase(brands, prefilledData['Brand']);
    final matchedColor = _findIgnoreCase(colors, prefilledData['Color']);
    final matchedCondition =
        _findIgnoreCase(conditions, prefilledData['Condition']);
    final matchedSize = _findIgnoreCase(sizes, prefilledData['Size']);
    final matchedType = _findIgnoreCase(types, prefilledData['Type']);

    // Initialize formData from possibly matched values
    final Map<String, dynamic> formData = {
      'item_name': '', // New field for item name
      'Brand': matchedBrand,
      'Color': matchedColor,
      'Condition': matchedCondition,
      'Size': matchedSize,
      'Type': matchedType,
      'Description': prefilledData['Description'] ?? '',
      'Price': prefilledData['EstimatedPrice'] ?? '',
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Item Name (Text field)
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).itemName),
                    maxLength: 50, // Character limit
                    onChanged: (value) => formData['item_name'] = value,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? AppLocalizations.of(context).itemNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Brand (Autocomplete)
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return brands.where((option) => option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      formData['Brand'] = selection;
                    },
                    initialValue: TextEditingValue(
                      text: formData['Brand'] ?? '',
                    ),
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).brand),
                        validator: (value) => value == null || value.isEmpty
                            ? AppLocalizations.of(context).brandRequired
                            : null,
                        onChanged: (value) {
                          formData['Brand'] =
                              value; // Update formData on text change
                        },
                        onFieldSubmitted: (value) {
                          formData['Brand'] = value;
                          onFieldSubmitted(); // Trigger any additional submission logic
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Color (Autocomplete)
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      final translatedColors = colors
                          .map((color) =>
                              TranslationUtils.getColor(color, context))
                          .toList();
                      return translatedColors.where((translatedColor) =>
                          translatedColor
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      formData['Color'] = colors.firstWhere(
                          (color) =>
                              TranslationUtils.getColor(color, context) ==
                              selection,
                          orElse: () => selection);
                    },
                    initialValue: TextEditingValue(
                      text: formData['Color'] != null
                          ? TranslationUtils.getColor(
                              formData['Color']!, context) // Show localized color
                          : '',
                    ),
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).color),
                        validator: (value) => value == null || value.isEmpty
                            ? AppLocalizations.of(context).colorRequired
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Condition (Dropdown)
                  DropdownButtonFormField<String>(
                    items: conditions
                        .map((condition) => DropdownMenuItem(
                              value: condition,
                              child: Text(TranslationUtils.getCondition(
                                  condition, context)),
                            ))
                        .toList(),
                    value: formData['Condition'],
                    onChanged: (value) => formData['Condition'] = value,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).condition),
                    validator: (value) => value == null
                        ? AppLocalizations.of(context).conditionRequired
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Size (Dropdown)
                  DropdownButtonFormField<String>(
                    items: sizes
                        .map((size) => DropdownMenuItem(
                              value: size,
                              child: Text(size),
                            ))
                        .toList(),
                    value: formData['Size'],
                    onChanged: (value) => formData['Size'] = value,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).size),
                    validator: (value) => value == null
                        ? AppLocalizations.of(context).sizeRequired
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Type (Dropdown)
                  DropdownButtonFormField<String>(
                    items: types
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                  TranslationUtils.getCategory(type, context)),
                            ))
                        .toList(),
                    value: formData['Type'],
                    onChanged: (value) => formData['Type'] = value,
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).type),
                    validator: (value) => value == null
                        ? AppLocalizations.of(context).typeRequired
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).description),
                    maxLines: 3,
                    initialValue: formData['Description'],
                    onChanged: (value) => formData['Description'] = value,
                  ),
                  const SizedBox(height: 16),

                  // Price
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).price),
                    keyboardType: TextInputType.number,
                    initialValue: formData['Price'].toString(),
                    onChanged: (value) {
                      formData['Price'] = int.tryParse(value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context).priceRequired;
                      }
                      final intValue = int.tryParse(value);
                      if (intValue == null) {
                        return AppLocalizations.of(context).priceValidInteger;
                      }
                      if (intValue <= 0) {
                        return AppLocalizations.of(context).priceGreaterThanZero;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Submit
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final estimated = estimateItemValue(
                          formData['Brand'] ?? 'Unknown',
                          formData['Condition'] ?? 'New',
                          formData['Type'] ?? 'T-Shirts',
                        );
                        final ratioPercent =
                            ((formData['Price'] / estimated) * 100).round();

                        if (ratioPercent > 120) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                  AppLocalizations.of(context).verifyYourPrice),
                              content: Text(
                                AppLocalizations.of(context)
                                    .priceVerificationMessage(
                                        ratioPercent, estimated),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                      AppLocalizations.of(context).changePrice),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    
                                    // Store dialog context for reliable dismissal
                                    BuildContext? dialogContext;
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) {
                                        dialogContext = context;
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      },
                                    );
                                    
                                    try {
                                      final itemId = await _uploadItemToFirebase(
                                          formData, context);
                                      
                                      // Dismiss dialog using stored context if available, fallback to rootNavigator
                                      if (dialogContext != null && dialogContext!.mounted) {
                                        Navigator.of(dialogContext!).pop();
                                      } else if (context.mounted) {
                                        Navigator.of(context, rootNavigator: true).pop();
                                      }
                                      
                                      // Only proceed with UI updates if context is still valid
                                      if (context.mounted && itemId != null) {
                                        // Clear images only after successful upload
                                        images.clear();
                                        
                                        // Show success message and navigate to item page
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  AppLocalizations.of(context)
                                                      .itemUploadedSuccess)),
                                        );
                                        
                                        // Navigate to the item page using root navigator
                                        Navigator.of(context, rootNavigator: true).push(
                                          MaterialPageRoute(
                                            builder: (context) => ItemPage(itemId: itemId),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Dismiss dialog using stored context if available, fallback to rootNavigator
                                      if (dialogContext != null && dialogContext!.mounted) {
                                        Navigator.of(dialogContext!).pop();
                                      } else if (context.mounted) {
                                        Navigator.of(context, rootNavigator: true).pop();
                                      }
                                      
                                      // Only show error message if context is still valid
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text('${AppLocalizations.of(context).errorUploadingItem}: $e')),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                      AppLocalizations.of(context).uploadItem),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // If ratioPercent <= 120, just upload the item directly with a loading screen
                          BuildContext? dialogContext;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              dialogContext = context;
                              return const Center(child: CircularProgressIndicator());
                            },
                          );

                          try {
                            final itemId = await _uploadItemToFirebase(formData, context);
                            
                            // Dismiss dialog using stored context if available, fallback to rootNavigator
                            if (dialogContext != null && dialogContext!.mounted) {
                              Navigator.of(dialogContext!).pop();
                            } else if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                            }
                            
                            // Only proceed with UI updates if context is still valid
                            if (context.mounted && itemId != null) {
                              // Clear images only after successful upload
                              images.clear();
                              
                              // Show success message and navigate to item page
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(AppLocalizations.of(context)
                                        .itemUploadedSuccess)),
                              );
                              
                              // Navigate to the item page using root navigator
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => ItemPage(itemId: itemId),
                                ),
                              );
                            }
                          } catch (e) {
                            // Dismiss dialog using stored context if available, fallback to rootNavigator
                            if (dialogContext != null && dialogContext!.mounted) {
                              Navigator.of(dialogContext!).pop();
                            } else if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                            }
                            
                            // Only show error message if context is still valid
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${AppLocalizations.of(context).errorUploadingItem}: $e')),
                              );
                            }
                          }
                        }
                      }
                    },
                    child: Text(AppLocalizations.of(context).submit),
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
