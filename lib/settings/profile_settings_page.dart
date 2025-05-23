import 'dart:io';
import 'package:eco_closet/generated/l10n.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:eco_closet/utils/image_handler.dart';


class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  // For lat/lng
  double? _latitude;
  double? _longitude;

  // Currently selected brand names
  List<String> _selectedBrands = [];

  // To hold picked image file
  File? _profileImage;
  String? _profilePhotoUrl; 

  // To hold original user values
  String? _original_name;
  String? _original_address;
  List<String>? _original_brands;
  bool? should_update_photo;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Load existing user data from Firestore, if available
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // No logged-in user

      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _addressController.text = data['address'] ?? '';
        _original_name = _nameController.text;
        _original_address = _addressController.text;
        if (data['favoriteBrands'] != null) {
          _selectedBrands = List<String>.from(data['favoriteBrands']);
          _original_brands = _selectedBrands;
        }
        // If you stored latitude/longitude previously, fetch them:
        if (data['latitude'] != null) {
          _latitude = data['latitude'];
        }
        if (data['longitude'] != null) {
          _longitude = data['longitude'];
        }
        if (data['profilePicUrl'] != null) {
          _profilePhotoUrl = data['profilePicUrl'];
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Pick profile image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _profileImage = File(pickedFile.path);
    });
    should_update_photo = true;
  }

  /// Update profile data in Firestore
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user currently signed in.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Upload image if one was picked
      String? photoURL;
      if (_profileImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pics')
            .child('${user.uid}.jpg');
        await ref.putFile(_profileImage!);
        photoURL = await ref.getDownloadURL();
      }

      // Update in Firestore. Include lat/lng if you wish.
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        if (_nameController.text != _original_name) 'name': _nameController.text.trim(),
        if (_addressController.text != _original_address) 'address': _addressController.text.trim(),
        if (_selectedBrands != _original_brands) 'likedBrands': _selectedBrands,
        if (photoURL != null && should_update_photo!) 'profilePicUrl': photoURL,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Use the provided code snippet to build the Google Place autocomplete field
  Widget placesAutoCompleteTextField() {
    return GooglePlaceAutoCompleteTextField(
      textEditingController: _addressController,
      googleAPIKey: 'AIzaSyB9vjhEDF4fRZ6x_Qy73Xgwhrb2GQjBjK8',
      inputDecoration: InputDecoration(
        labelText: AppLocalizations.of(context).address,
        hintText: AppLocalizations.of(context).addressSearch,
      ),
      debounceTime: 400,
      // Restrict or broaden countries as needed
      countries: const ['il'], // example: "in", "fr", "us", etc.
      isLatLngRequired: true,
      getPlaceDetailWithLatLng: (Prediction prediction) {
        debugPrint('placeDetails lat: ${prediction.lat}, lng: ${prediction.lng}');
        // Save lat/lng locally for potential storage in Firestore
        if (prediction.lat != null && prediction.lng != null) {
          final lat = double.tryParse(prediction.lat!);
          final lng = double.tryParse(prediction.lng!);
          if (lat != null && lng != null) {
            _latitude = lat;
            _longitude = lng;
          }
        }
      },
      itemClick: (Prediction prediction) {
        // Set the text in the address controller
        _addressController.text = prediction.description ?? '';
        _addressController.selection = TextSelection.fromPosition(
          TextPosition(offset: prediction.description?.length ?? 0),
        );
        _addressController.text = prediction.description?.substring(0, prediction.description!.lastIndexOf(',')) ?? '';
      },
      itemBuilder: (context, index, Prediction prediction) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.location_on),
              const SizedBox(width: 7),
              Expanded(
                child: Text(prediction.description ?? ''),
              ),
            ],
          ),
        );
      },
      isCrossBtnShown: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prepare MultiSelect items from Utils.brands
    final items = Utils.brands
        .map((brand) => MultiSelectItem<String>(brand, brand))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).profileSettings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: ClipOval(
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: _profileImage != null
                                // If a new image is picked, display it immediately.
                                ? Image.file(
                                    _profileImage!,
                                    fit: BoxFit.cover,
                                  )
                                : _profilePhotoUrl != null
                                    // Otherwise, if a URL exists, display the network image.
                                    ? ImageHandler.buildCachedNetworkImage(
                                        imageUrl: _profilePhotoUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.person, size: 50),
                                      )
                                    // If neither exists, show an icon prompting the user to add a photo.
                                    : const Icon(Icons.add_a_photo, size: 40),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).name,
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? AppLocalizations.of(context).name : null,
                    ),
                    const SizedBox(height: 16),

                    // Address (Google Places Autocomplete)
                    placesAutoCompleteTextField(),
                    const SizedBox(height: 24),

                    // Favorite Brands - in a fixed-size scroll area
                    SizedBox(
                      height: 300, // Fixed height
                      child: SingleChildScrollView(
                        child: MultiSelectChipField<String?>(
                          items: items,
                          title: Text(AppLocalizations.of(context).preferredBrands),
                          scroll: false,
                          headerColor: Colors.blue.withOpacity(0.5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 1.8),
                          ),
                          selectedChipColor: Colors.blue.withOpacity(0.8),
                          selectedTextStyle: const TextStyle(color: Colors.white),
                          initialValue: _selectedBrands, // prefill if any
                          onTap: (selection) {
                            setState(() {
                              // Keep non-null strings
                              _selectedBrands =
                                  selection.whereType<String>().toList();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // "Next" Button
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text(AppLocalizations.of(context).update),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
