import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:eco_closet/utils/get_recommended_price.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'dart:convert';

import '../generated/l10n.dart';

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
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                if (_images.length >= 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Maximum 6 images allowed.')),
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
              title: const Text('Select From Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final pickedImages = await _picker.pickMultiImage(
                  imageQuality: 50,
                  limit: 6
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
        AppLocalizations.of(context).brand:
            Schema.string(description: "Brand of the item, or null if unknown"),
        AppLocalizations.of(context).color: Schema.string(
            description: "Color of the item: White, Black, Multicolor"),
        AppLocalizations.of(context).condition: Schema.string(
            description:
                "Condition of the item: Never Used, New, Gently Used, etc."),
        AppLocalizations.of(context).size:
            Schema.string(description: "Size of the item, null if uncertain"),
        AppLocalizations.of(context).type: Schema.string(
            description:
                "Type of the item in plural: T-shirts, pants, coats, etc."),
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

    final content = [
      Content.multi([...imageParts, prompt])
    ];

    final response = await model.generateContent(content);

    try {
      var decoded = jsonDecode(response.text!) as Map<String, dynamic>;
      return decoded;
    } catch (e) {
      throw Exception('Failed to parse response from Gemini: ${response.text}');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _pickImages() async {
    final pickedImages =
        await _picker.pickMultiImage(limit: 6, imageQuality: 75);
    setState(() {
      _images = pickedImages;
    });
  }

  Future<void> _processImagesWithGemini() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final metadata = await _callGemini();
      Navigator.of(context, rootNavigator: true).pop();

      Navigator.push(
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
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing images with Gemini: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).uploadItemStep1),
        title: const Text('Upload Item - Step 1'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(AppLocalizations.of(context).uploadImages),
            SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: _images
                  .map((image) => Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(
                            File(image.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                setState(() => _images.remove(image)),
                          ),
                        ],
                      ))
                  .toList(),
            // Tips
            Text(
              'Tips for better results:\n'
              '- Take clear photos, possibly wearing the item.\n'
              '- Capture labels or tags clearly.\n',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap an image to set it as the main image for this item.\n'
              'The first image in the list will be used as the main image.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            // Images in a bigger Grid, portrait aspect ratio
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
                        onTap: () => _makeImageMain(index), // Move tapped to front
                        child: AspectRatio(
                          aspectRatio: 3 / 4, // Force a portrait box
                          child: Container(
                            color: Colors.grey[300],
                            child: Image.file(
                              File(image.path),
                              fit: BoxFit.contain, // center if square or wide
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
              child: const Text('Pick Images (Max 6)'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _images.isNotEmpty ? _processImagesWithGemini : null,
              child: Text(AppLocalizations.of(context).analyzeImages),
              child: const Text('Next'),
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
      imagePaths.add(imageName);
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
    String? warningMessage;


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
        title: const Text('Upload Item - Step 2'),
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
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).brand),
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context).brandRequired
                          : null,
                      decoration: const InputDecoration(labelText: 'Brand'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Brand is required' : null,
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
                    return colors.where((option) => option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    formData['Color'] = selection;
                  },
                  initialValue: TextEditingValue(
                    text: formData['Color'] ?? '',
                  ),
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'Color'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Color is required' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Condition (Dropdown)
                DropdownButtonFormField<String>(
                  items: conditions
                      .map((condition) => DropdownMenuItem(
                            value: condition,
                            child: Text(condition),
                          ))
                      .toList(),
                  value: formData['Condition'],
                  onChanged: (value) => formData['Condition'] = value,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  validator: (value) => value == null ? 'Condition is required' : null,
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
                  decoration: const InputDecoration(labelText: 'Size'),
                  validator: (value) => value == null ? 'Size is required' : null,
                ),
                const SizedBox(height: 16),

                // Type (Dropdown)
                DropdownButtonFormField<String>(
                  items: types
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  value: formData['Type'],
                  onChanged: (value) => formData['Type'] = value,
                  decoration: const InputDecoration(labelText: 'Type'),
                  validator: (value) => value == null ? 'Type is required' : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  initialValue: formData['Description'],
                  onChanged: (value) => formData['Description'] = value,
                ),
                const SizedBox(height: 16),

                // Price
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  initialValue: formData['Price'].toString(),
                  onChanged: (value) {
                    formData['Price'] = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price is required';
                    }
                    final intValue = int.tryParse(value);
                    if (intValue == null) {
                      return 'Price must be a valid integer';
                    }
                    if (intValue <= 0) {
                      return 'Price must be greater than 0';
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
                      final price = int.tryParse(formData['Price']) ?? 0;
                      final ratioPercent = ((price / estimated) * 100).round();

                      if (ratioPercent > 120) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Verify Your Price'),
                            content: Text(
                              'Your price is $ratioPercent% of the recommended price of $estimated₪. Do you still want to upload?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Change Price'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  try {
                                    await _uploadItemToFirebase(formData, context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Item uploaded successfully!')),
                                    );
                                    Navigator.popUntil(context, (route) => route.isFirst);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error uploading item: $e')),
                                    );
                                  }
                                },
                                child: const Text('Upload Item'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // If ratioPercent <= 120, just upload the item directly
                        try {
                          await _uploadItemToFirebase(formData, context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Item uploaded successfully!')),
                          );
                          Navigator.popUntil(context, (route) => route.isFirst);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error uploading item: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Submit'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}