import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'dart:convert';

class UploadItemPage extends StatefulWidget {
  @override
  _UploadItemPageState createState() => _UploadItemPageState();
}

class _UploadItemPageState extends State<UploadItemPage> {
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  List<String> _brands = [];
  List<String> _colors = [];
  List<String> _conditions = [];
  List<String> _sizes = [];
  List<String> _types = [];

  Future<void> _fetchDropdownData() async {
    try {
      final brandsSnapshot = await FirebaseFirestore.instance.collection('Clothes_Brands').get();
      final colorsSnapshot = await FirebaseFirestore.instance.collection('Colors').get();
      final conditionsSnapshot = await FirebaseFirestore.instance.collection('Condition').get();
      final sizesSnapshot = await FirebaseFirestore.instance.collection('Clothes_Sizes').get();
      final typesSnapshot = await FirebaseFirestore.instance.collection('item_types').get();

      setState(() {
        _brands = brandsSnapshot.docs.map((doc) => doc['name'].toString().toLowerCase()).toList();
        _colors = colorsSnapshot.docs.map((doc) => doc['name'].toString().toLowerCase()).toList();
        _conditions = conditionsSnapshot.docs.map((doc) => doc['name'].toString().toLowerCase()).toList();
        _sizes = sizesSnapshot.docs.map((doc) => doc['Symbol'].toString().toLowerCase()).toList();
        _types = typesSnapshot.docs.map((doc) => doc['name'].toString().toLowerCase()).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch dropdown data: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> _callGemini() async {
    final jsonSchema = Schema.object(
      properties: {
        "Brand": Schema.string(description: "Brand of the item, or null if unknown"),
        "Color": Schema.string(description: "Color of the item"),
        "Condition": Schema.string(description: "Condition of the item: new, almost new, used, etc."),
        "Size": Schema.string(description: "Size of the item, or 'Medium' if uncertain"),
        "Type": Schema.string(description: "Type of the item: T-shirt, pants, coat, etc."),
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
      'Analyze the provided images and extract metadata including brand, color, condition, size, and type.',
    );

    final content = [Content.multi([...imageParts, prompt])];

    final response = await model.generateContent(content);

    try {
      var decoded = jsonDecode(response.text!.toLowerCase()) as Map<String, dynamic>;
      print(decoded);
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
    final pickedImages = await _picker.pickMultiImage(limit: 6, imageQuality: 75);
    setState(() {
      _images = pickedImages;
    });
  }

  Future<void> _processImagesWithGemini() async {
    try {
      final metadata = await _callGemini();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing images with Gemini: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Item - Step 1'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload Images (up to 6):'),
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
                            onPressed: () => setState(() => _images.remove(image)),
                          ),
                        ],
                      ))
                  .toList(),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickImages,
              child: Text('Pick Images'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _images.isNotEmpty ? _processImagesWithGemini : null,
              child: Text('Analyze Images with Gemini'),
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

  Future<void> _uploadItemToFirebase(Map<String, dynamic> formData) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in.');
    }

    List<String> imageUrls = [];
    for (var image in images) {
      final ref = FirebaseStorage.instance.ref().child('items/${image.name}');
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    await FirebaseFirestore.instance.collection('Items').add({
      ...formData,
      'images': imageUrls,
      'seller_id': userId,
      'status': 'Available',
    });
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    print(colors);
    print(prefilledData);
    final Map<String, dynamic> formData = {
      'Brand': brands.contains(prefilledData['brand']) ? prefilledData['brand'] : null,
      'Color': colors.contains(prefilledData['color']) ? prefilledData['color'] : null,
      'Condition': conditions.contains(prefilledData['condition']) ? prefilledData['condition'] : null,
      'Size': sizes.contains(prefilledData['size']) ? prefilledData['size'] : null,
      'Type': types.contains(prefilledData['type']) ? prefilledData['type'] : null,
      'Description': prefilledData['description'] ?? '',
      'Price': prefilledData['price'] ?? 20,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Item - Step 2'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  items: brands
                      .map((brand) => DropdownMenuItem(
                            value: brand,
                            child: Text(brand),
                          ))
                      .toList(),
                  value: formData['Brand'],
                  onChanged: (value) => formData['Brand'] = value,
                  decoration: InputDecoration(labelText: 'Brand'),
                  validator: (value) => value == null ? 'Brand is required' : null,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  items: colors
                      .map((color) => DropdownMenuItem(
                            value: color,
                            child: Text(color),
                          ))
                      .toList(),
                  value: formData['Color'],
                  onChanged: (value) => formData['Color'] = value,
                  decoration: InputDecoration(labelText: 'Color'),
                  validator: (value) => value == null ? 'Color is required' : null,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  items: conditions
                      .map((condition) => DropdownMenuItem(
                            value: condition,
                            child: Text(condition),
                          ))
                      .toList(),
                  value: formData['Condition'],
                  onChanged: (value) => formData['Condition'] = value,
                  decoration: InputDecoration(labelText: 'Condition'),
                  validator: (value) => value == null ? 'Condition is required' : null,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  items: sizes
                      .map((size) => DropdownMenuItem(
                            value: size,
                            child: Text(size),
                          ))
                      .toList(),
                  value: formData['Size'],
                  onChanged: (value) => formData['Size'] = value,
                  decoration: InputDecoration(labelText: 'Size'),
                  validator: (value) => value == null ? 'Size is required' : null,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  items: types
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  value: formData['Type'],
                  onChanged: (value) => formData['Type'] = value,
                  decoration: InputDecoration(labelText: 'Type'),
                  validator: (value) => value == null ? 'Type is required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  onChanged: (value) => formData['Description'] = value,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => formData['Price'] = value,
                  validator: (value) =>
                      value == null || double.tryParse(value) == null
                          ? 'Valid price is required'
                          : null,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await _uploadItemToFirebase(formData);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Item uploaded successfully!')),
                        );
                        Navigator.popUntil(context, (route) => route.isFirst);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error uploading item: $e')),
                        );
                      }
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
