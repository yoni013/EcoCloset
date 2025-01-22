import 'dart:io';

import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

// Reference your utility or metadata fetcher, if needed
// import 'package:eco_closet/utils/fetch_item_metadata.dart';

class UserOnboardingData {
  // Step 1: Personal info
  String? name;
  int? age;
  String? address;
  String? profilePicUrl;
  String? gender;

  // Step 2: Favorite brands
  List<String>? favoriteBrands = [];

  // Step 3: Sizes
  Map<String, Set<String>> userSizes = {
    'Coats': {},
    'Sweaters': {},
    'T-Shirts': {},
    'Pants': {},
    'Shoes': {},
  };

  // Step 4: Notification & Privacy
  bool enablePushNotifications = false;
  bool enableEmailNotifications = false;
  bool enableSmsNotifications = false;
  bool hasAcceptedPrivacyPolicy = false;
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}
class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // This is where we store all onboarding data
  final UserOnboardingData _onboardingData = UserOnboardingData();

  // Hardcode brand list for Step 2 or load from your backend
  final List<String> allBrands = Utils.brands;

  // Hardcode or load available sizes from your metadata for Step 3
  Map<String, List<String>> availableSizes = {
        'Coats': Utils.general_sizes,
        'Pants': Utils.pants_sizes,
        'T-Shirts': Utils.general_sizes,
        'Shoes': Utils.shoe_sizes,
        'Sweaters': Utils.general_sizes
  };

  /// Navigate to the next page, or finish onboarding if last page
  void _nextPage() {
    if (_currentPage == 3) {
      // Last step is index 2 in this example (0=step1,1=step2,2=step3)
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Skip the current step (if allowed) - just move forward
  void _skipStep() {
    _nextPage();
  }

  /// Once completed, update Firestore with the data
  Future<void> _completeOnboarding() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Convert the sets to lists for Firestore
        final Map<String, List<String>> sizesToSave = {};
        _onboardingData.userSizes.forEach((category, sizes) {
          sizesToSave[category] = sizes.toList();
        });

        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .set(
          {
            'name': _onboardingData.name ?? '',
            'age': _onboardingData.age ?? 0,
            'address': _onboardingData.address ?? '',
            'profilePicUrl': _onboardingData.profilePicUrl ?? '',
            'favoriteBrands': _onboardingData.favoriteBrands ?? [],
            'Sizes': sizesToSave,
          },
          SetOptions(merge: true), // merge so we don't overwrite entire doc
        );
      }
      // Navigate to main app flow, or pop
      Navigator.of(context).pop(); // or pushReplacementNamed('/home');
    } catch (e) {
      // Handle error
      debugPrint('Error completing onboarding: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with your FlexTheme-based Scaffold or use your top-level MaterialApp
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // user can't swipe
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          // STEP 1: Personal info
          _Step1PersonalInfo(
            onboardingData: _onboardingData,
            onNext: _nextPage,
          ),
          // STEP 2: Favorite brands
          _Step2FavoriteBrands(
            onboardingData: _onboardingData,
            allBrands: allBrands,
            onNext: _nextPage,
            onSkip: _skipStep,
          ),
          // STEP 3: Sizes
          _Step3Sizes(
            onboardingData: _onboardingData,
            availableSizes: availableSizes,
            onNext: _nextPage,
            onSkip: _skipStep,
          ),
          // Step 4: Notification & Privacy
          _Step4NotificationPrefs(
            onboardingData: _onboardingData,
            onNext: _nextPage,
            onSkip: _skipStep,
          ),
        ],
      ),
    );
  }
}

class _Step1PersonalInfo extends StatefulWidget {
  final UserOnboardingData onboardingData;
  final VoidCallback onNext;

  const _Step1PersonalInfo({
    Key? key,
    required this.onboardingData,
    required this.onNext,
  }) : super(key: key);

  @override
  State<_Step1PersonalInfo> createState() => _Step1PersonalInfoState();
}

class _Step1PersonalInfoState extends State<_Step1PersonalInfo> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  XFile? _pickedImage;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    // If we have existing data, populate
    _nameController.text = widget.onboardingData.name ?? '';
    _ageController.text =
    _ageController.text = widget.onboardingData.age?.toString() ?? '';
    _addressController.text = widget.onboardingData.address ?? '';
    _selectedGender = widget.onboardingData.gender;
    _nameController.addListener(() {
      setState(() {});  // Trigger rebuild when text changes
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

    Future<void> _uploadProfileImage() async {
      // Make sure we have an image and a logged-in user
      if (_pickedImage == null) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create a reference to "profile_pics/{uid}.jpg" in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pics')
          .child('${user.uid}.jpg');

      // Upload the file
      await storageRef.putFile(File(_pickedImage!.path));
      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Store in onboarding data
      setState(() {
        widget.onboardingData.profilePicUrl = downloadUrl;
      });
    }

  void _saveAndNext() {
    if (_formKey.currentState!.validate()) {
      widget.onboardingData.name = _nameController.text.trim();
      widget.onboardingData.age = int.tryParse(_ageController.text.trim());
      widget.onboardingData.address = _addressController.text.trim();
      widget.onboardingData.gender = _selectedGender;
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar for profile image
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _pickedImage != null
                        ? FileImage(File(_pickedImage!.path))
                        : null,
                    child: _pickedImage == null
                        ? const Icon(Icons.camera_alt, size: 50, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Step 1: Personal Info',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final age = int.tryParse(value);
                      if (age == null) {
                        return 'Please enter a valid age';
                      }
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: _genders.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a gender' : null,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _nameController.text.trim().isNotEmpty
                      ? () {
                          _saveAndNext();
                          _uploadProfileImage();
                        }
                      : null, // Disable button if name is empty
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step2FavoriteBrands extends StatefulWidget {
  final UserOnboardingData onboardingData;
  final List<String> allBrands;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Step2FavoriteBrands({
    Key? key,
    required this.onboardingData,
    required this.allBrands,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<_Step2FavoriteBrands> createState() => _Step2FavoriteBrandsState();
}

class _Step2FavoriteBrandsState extends State<_Step2FavoriteBrands> {
  List<String> _selectedBrands = [];

  @override
  void initState() {
    super.initState();
    _selectedBrands = widget.onboardingData.favoriteBrands ?? [];
  }

  void _saveAndNext() {
    widget.onboardingData.favoriteBrands = _selectedBrands;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    // Convert each brand into a MultiSelectItem
    final items = widget.allBrands
        .map((brand) => MultiSelectItem<String>(brand, brand))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text('Step 2: Pick Your Favorite Brands',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: MultiSelectChipField<String?>(
                  items: items,
                  title: const Text('Favorite Brands'),
                  scroll: false,
                  headerColor: Colors.blue.withOpacity(0.5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 1.8),
                  ),
                  selectedChipColor: Colors.blue.withOpacity(0.8),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  initialValue: _selectedBrands,
                  onTap: (selection) {
                    setState(() {
                      _selectedBrands = selection.whereType<String>().toList(); 
                    });
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _saveAndNext, child: const Text('Next'))
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Step3Sizes extends StatefulWidget {
  final UserOnboardingData onboardingData;
  final Map<String, List<String>> availableSizes;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Step3Sizes({
    Key? key,
    required this.onboardingData,
    required this.availableSizes,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<_Step3Sizes> createState() => _Step3SizesState();
}

class _Step3SizesState extends State<_Step3Sizes> {
  late Map<String, Set<String>> userSizes; // local state

  @override
  void initState() {
    super.initState();
    // Copy from the onboarding data model
    userSizes = {
      ...widget.onboardingData.userSizes
    }.map((key, value) => MapEntry(key, {...value}));
  }

  Widget _buildMultiSelectField(String category) {
    final items = widget.availableSizes[category]!
        .map((size) => MultiSelectItem<String>(size, size))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MultiSelectDialogField<String>(
        title: Text(category),
        items: items,
        searchable: true,
        initialValue: userSizes[category]?.toList() ?? [],
        buttonText: Text('Select $category Sizes'),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(4.0),
        ),
        onConfirm: (selectedValues) {
          setState(() {
            userSizes[category] = selectedValues.toSet();
          });
        },
      ),
    );
  }

  void _saveAndNext() {
    // Save back to the onboardingData
    widget.onboardingData.userSizes = userSizes;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.availableSizes.keys.toList();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text('Step 3: Size Preferences',
                style: Theme.of(context).textTheme.headlineSmall),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (ctx, i) {
                  final category = categories[i];
                  return _buildMultiSelectField(category);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: _saveAndNext, child: const Text('Next')),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Step4NotificationPrefs extends StatefulWidget {
  final UserOnboardingData onboardingData;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Step4NotificationPrefs({
    Key? key,
    required this.onboardingData,
    required this.onNext,
    required this.onSkip,
  }) : super(key: key);

  @override
  State<_Step4NotificationPrefs> createState() => _Step4NotificationPrefsState();
}

class _Step4NotificationPrefsState extends State<_Step4NotificationPrefs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Privacy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Push Notifications'),
              value: widget.onboardingData.enablePushNotifications,
              onChanged: (val) {
                setState(() {
                  widget.onboardingData.enablePushNotifications = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Email Notifications'),
              value: widget.onboardingData.enableEmailNotifications,
              onChanged: (val) {
                setState(() {
                  widget.onboardingData.enableEmailNotifications = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable SMS Notifications'),
              value: widget.onboardingData.enableSmsNotifications,
              onChanged: (val) {
                setState(() {
                  widget.onboardingData.enableSmsNotifications = val;
                });
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('I agree to the Privacy Policy'),
              value: widget.onboardingData.hasAcceptedPrivacyPolicy,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    widget.onboardingData.hasAcceptedPrivacyPolicy = val;
                  });
                }
              },
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: widget.onboardingData.hasAcceptedPrivacyPolicy 
                      ? widget.onNext 
                      : null, // Disable button if not accepted
                  child: const Text('Finish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}