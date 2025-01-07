/// upload_item_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_vertexai/firebase_vertexai.dart';


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

  Future<void> _fetchDropdownData() async {
    try {
      final brandsSnapshot = await FirebaseFirestore.instance.collection('Clothes_Brands').get();
      final colorsSnapshot = await FirebaseFirestore.instance.collection('Colors').get();
      final conditionsSnapshot = await FirebaseFirestore.instance.collection('Condition').get();
      final sizesSnapshot = await FirebaseFirestore.instance.collection('Clothes_Sizes').get();

      setState(() {
        _brands = brandsSnapshot.docs.map((doc) => doc['name'] as String).toList();
        _colors = colorsSnapshot.docs.map((doc) => doc['name'] as String).toList();
        _conditions = conditionsSnapshot.docs.map((doc) => doc['name'] as String).toList();
        _sizes = sizesSnapshot.docs.map((doc) => doc['Symbol'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch dropdown data: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _pickImages() async {
    final pickedImages = await _picker.pickMultiImage();
    setState(() {
        _images = pickedImages;
    });
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
              onPressed: _images.isNotEmpty
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _StepTwoForm(
                            images: _images,
                            brands: _brands,
                            colors: _colors,
                            conditions: _conditions,
                            sizes: _sizes,
                          ),
                        ),
                      )
                  : null,
              child: Text('Continue to Step 2'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                    final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');
                    // Provide a prompt that contains text
                    final prompt = [Content.text('Write a story about a magic backpack. using 5 words')];

                    // To generate text output, call generateContent with the text input
                    final response = await model.generateContent(prompt);
                    print(response.text);
                  },
              child: Text('generate short story'),
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

  _StepTwoForm({
    required this.images,
    required this.brands,
    required this.colors,
    required this.conditions,
    required this.sizes,
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
    final Map<String, dynamic> formData = {
      'Brand': null,
      'Color': null,
      'Condition': null,
      'Size': null,
      'Description': '',
      'Price': '',
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
                  onChanged: (value) => formData['Size'] = value,
                  decoration: InputDecoration(labelText: 'Size'),
                  validator: (value) => value == null ? 'Size is required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  onChanged: (value) => formData['Description'] = value,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Description is required' : null,
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
