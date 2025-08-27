import 'package:flutter/foundation.dart' show Uint8List;
import 'package:beged/generated/l10n.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:beged/utils/fetch_item_metadata.dart';

import 'package:beged/utils/image_handler.dart';


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



  // Currently selected brand names
  List<String> _selectedBrands = [];

  // To hold picked image file
  XFile? _profileImage;
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
      _profileImage = pickedFile;
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
        final bytes = await _profileImage!.readAsBytes();
        await ref.putData(bytes);
        photoURL = await ref.getDownloadURL();
      }

      // Update in Firestore. Include lat/lng if you wish.
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        if (_nameController.text != _original_name) 'name': _nameController.text.trim(),
        if (_addressController.text != _original_address) 'address': _addressController.text.trim(),
        if (_selectedBrands != _original_brands) 'likedBrands': _selectedBrands,
        if (photoURL != null && should_update_photo!) 'profilePicUrl': photoURL,

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

  // Simple text field for address input
  Widget placesAutoCompleteTextField() {
    return TextFormField(
      controller: _addressController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).address,
        hintText: 'Enter your full address (City, Street, etc.)',
        prefixIcon: const Icon(Icons.location_on),
        border: const OutlineInputBorder(),
      ),
      maxLines: 2,
      validator: (value) => 
          value == null || value.isEmpty ? 'Please enter your address' : null,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
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
                                  ? FutureBuilder<Uint8List>(
                                      future: _profileImage!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const Center(child: CircularProgressIndicator());
                                      },
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
      ),
    );
  }
}
