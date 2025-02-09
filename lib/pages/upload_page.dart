import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:eco_closet/utils/get_recommended_price.dart';
import 'package:eco_closet/utils/translation_metadata.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'dart:convert';
import 'package:eco_closet/generated/l10n.dart';

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
        SnackBar(content: Text('Failed to fetch dropdown data: $e')),
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
                    SnackBar(content: Text(AppLocalizations.of(context).maxImagesAllowed)),
                  );
                  return;
                }
                final XFile? cameraImage = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 50,
                );
                if (cameraImage != null) {
                  setState(() {
                    if (_images.length < 6) {
                      _images.add(cameraImage);
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context).selectFromGallery),
              onTap: () async {
                Navigator.pop(context);
                final pickedImages = await _picker.pickMultiImage(
                  imageQuality: 50,
                  // You can pick multiple images here; limit them to 6
                  limit: 6,
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
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _makeImageMain(int index) {
    setState(() {
      final tappedImage = _images.removeAt(index);
      _images.insert(0, tappedImage);
    });
  }

  Future<Map<String, dynamic>> _callGemini() async {
    final jsonSchema = Schema.object(
      properties: {
        'Brand': Schema.string(description: 'Brand of the item, or null if unknown'),
        'Color': Schema.string(description: 'Color of the item'),
        'Condition': Schema.string(description: 'Condition of the item'),
        'Size': Schema.string(description: 'Size of the item'),
        'Type': Schema.string(description: 'Type of the item in plural'),
      },
    );

    final model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-1.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: jsonSchema,
      ),
    );

    List<InlineDataPart> imageParts = [];
    for (var image in _images) {
      final bytes = await File(image.path).readAsBytes();
      imageParts.add(InlineDataPart('image/jpeg', bytes));
    }

    final prompt = TextPart(
      '''Analyze the provided images and extract metadata including brand, color, condition, size, and type.''',
    );

    final content = [Content.multi([...imageParts, prompt])];

    final response = await model.generateContent(content);
    debugPrint(response.text);

    try {
      var decoded = jsonDecode(response.text!) as Map<String, dynamic>;
      return decoded;
    } catch (e) {
      throw Exception('Failed to parse response from Gemini: ${response.text}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).uploadItemStep1),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tips
            Text(
              AppLocalizations.of(context).photoTips,
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).mainImageInstructions,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            // Images in a Grid
            Expanded(
              child: GridView.builder(
                itemCount: _images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final image = _images[index];
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      GestureDetector(
                        onTap: () => _makeImageMain(index),
                        child: AspectRatio(
                          aspectRatio: 3 / 4, // Force a portrait box
                          child: Container(
                            color: Colors.grey[300],
                            child: Image.file(
                              File(image.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _images.removeAt(index);
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickImageSource,
              child: Text(AppLocalizations.of(context).pickImages),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
            onPressed: _images.isNotEmpty
                ? () async {
                    // 1) Show a loading screen while calling Gemini
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final metadata = await _callGemini();

                      // Hide the loading dialog
                      Navigator.of(context, rootNavigator: true).pop();

                      // 2) Navigate to Step2 and wait for the result
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

                      // 3) If Step2 returned true => images cleared, rebuild Step1
                      if (result == true) {
                        setState(() {
                          // `_images` is already empty, but we need to rebuild
                        });
                      }
                    } catch (e) {
                      // Hide the loading dialog if an error occurs
                      Navigator.of(context, rootNavigator: true).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error processing images with Gemini: $e')),
                      );
                    }
                  }
                : null,
              child: Text(AppLocalizations.of(context).next),
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

  /// Upload item details (with images) to Firestore
  Future<void> _uploadItemToFirebase(
    Map<String, dynamic> formData,
    BuildContext context,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in.');
    }

    // Upload images to Firebase Storage in order
    List<String> imagePaths = [];
    for (var image in images) {
      final String imageName = 'items/${image.name}';
      final ref = FirebaseStorage.instance.ref().child(imageName);
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      imagePaths.add(url);
    }

    // Create the document in Firestore
    await FirebaseFirestore.instance.collection('Items').add({
      ...formData,
      'images': imagePaths, // The first in the list is "main"
      'seller_id': userId,
      'status': 'Available',
    });
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    // Use the helper to find a match ignoring case
    final matchedBrand = _findIgnoreCase(brands, prefilledData['Brand']);
    final matchedColor = _findIgnoreCase(colors, prefilledData['Color']);
    final matchedCondition = _findIgnoreCase(conditions, prefilledData['Condition']);
    final matchedSize = _findIgnoreCase(sizes, prefilledData['Size']);
    final matchedType = _findIgnoreCase(types, prefilledData['Type']);

    // Initialize formData from possibly matched values
    final Map<String, dynamic> formData = {
      'Brand': matchedBrand,
      'Color': matchedColor,
      'Condition': matchedCondition,
      'Size': matchedSize,
      'Type': matchedType,
      'Description': '',
      'Price': '',
    };

    return Scaffold(
      appBar: AppBar(
      title: Text(AppLocalizations.of(context).uploadItemStep2),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
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
                      decoration: InputDecoration(labelText: AppLocalizations.of(context).brand),
                      validator: (value) =>
                          value == null || value.isEmpty ? AppLocalizations.of(context).brandRequired : null,
                      onChanged: (value) {
                        formData['Brand'] = value; // Update formData on text change
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
                    final translatedColors = colors.map((color) => TranslationUtils.getColor(color, context)).toList();
                    return translatedColors.where((translatedColor) =>
                        translatedColor.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    formData['Color'] = colors.firstWhere(
                      (color) => TranslationUtils.getColor(color, context) == selection,
                      orElse: () => selection);
                  },
                  initialValue: TextEditingValue(
                    text: formData['Color'] != null
                      ? TranslationUtils.getColor(formData['Color']!, context) // Show localized color
                      : '',
                  ),
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context).color),
                      validator: (value) =>
                        value == null || value.isEmpty ? AppLocalizations.of(context).colorRequired : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Condition (Dropdown)
                DropdownButtonFormField<String>(
                  items: conditions
                      .map((condition) => DropdownMenuItem(
                            value: condition,
                            child: Text(TranslationUtils.getCondition(condition, context)),
                          ))
                      .toList(),
                  value: formData['Condition'],
                  onChanged: (value) => formData['Condition'] = value,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).condition),
                  validator: (value) => value == null ? AppLocalizations.of(context).conditionRequired : null,
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
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).size),
                  validator: (value) => value == null ? AppLocalizations.of(context).sizeRequired : null,
                ),
                const SizedBox(height: 16),

                // Type (Dropdown)
                DropdownButtonFormField<String>(
                  items: types
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(TranslationUtils.getCategory(type, context)),
                          ))
                      .toList(),
                  value: formData['Type'],
                  onChanged: (value) => formData['Type'] = value,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).type),
                  validator: (value) => value == null ? AppLocalizations.of(context).typeRequired : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                decoration: InputDecoration(labelText: AppLocalizations.of(context).description),
                  maxLines: 3,
                  initialValue: formData['Description'],
                  onChanged: (value) => formData['Description'] = value,
                ),
                const SizedBox(height: 16),

                // Price
                TextFormField(
                decoration: InputDecoration(labelText: AppLocalizations.of(context).price),
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
                      final ratioPercent = ((formData['Price'] / estimated) * 100).round();

                      if (ratioPercent > 120) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context).verifyYourPrice),
                            content: Text(
                              AppLocalizations.of(context).priceVerificationMessage(ratioPercent, estimated),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(AppLocalizations.of(context).changePrice),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) =>
                                        const Center(child: CircularProgressIndicator()),
                                  );
                                  try {
                                    await _uploadItemToFirebase(formData, context);
                                    images.clear();
                                    if (context.mounted) {
                                      Navigator.of(context, rootNavigator: true).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(AppLocalizations.of(context).itemUploadedSuccess)),
                                      );
                                      Navigator.pop(context, true);
                                    }
                                  } catch (e) {
                                    Navigator.of(context, rootNavigator: true).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error uploading item: $e')),
                                    );
                                  }
                                },
                                child: Text(AppLocalizations.of(context).uploadItem),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // If ratioPercent <= 120, just upload the item directly with a loading screen
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          await _uploadItemToFirebase(formData, context);
                          images.clear();
                          Navigator.of(context, rootNavigator: true).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).itemUploadedSuccess)),
                          );
                          Navigator.pop(context, true);
                        } catch (e) {
                          Navigator.of(context, rootNavigator: true).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error uploading item: $e')),
                          );
                        }
                      }
                    }
                  },
                child: Text(AppLocalizations.of(context).submit),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}