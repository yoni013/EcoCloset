import 'dart:io';

import 'package:eco_closet/bottom_navigation.dart';
import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class UserOnboardingData {
  // Step 1: Personal info
  String? name;
  DateTime? birthday;
  String? address;
  String? profilePicUrl;
  String? gender;
  double? latitude;
  double? longitude;

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

        await FirebaseFirestore.instance.collection('Users').doc(user.uid).set(
          {
            'name': _onboardingData.name ?? '',
            'age': _onboardingData.birthday ?? DateTime.now(),
            'address': _onboardingData.address ?? '',
            'profilePicUrl': _onboardingData.profilePicUrl ?? '',
            'favoriteBrands': _onboardingData.favoriteBrands ?? [],
            'Sizes': sizesToSave,
            'isNewUser': false,
            'enablePushNotifications': _onboardingData.enablePushNotifications,
            'enableEmailNotifications':
                _onboardingData.enableEmailNotifications,
            'enableSmsNotifications': _onboardingData.enableSmsNotifications,
            'location': (_onboardingData.latitude != null &&
                    _onboardingData.longitude != null)
                ? GeoPoint(
                    _onboardingData.latitude!, _onboardingData.longitude!)
                : null,
          },
          SetOptions(merge: true),
        );
      }
      // Navigate to main app flow, or pop
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PersistentBottomNavPage()),
      );
    } catch (e) {
      // Handle error
      debugPrint('Error completing onboarding: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          // Remove the default back/leading button
          automaticallyImplyLeading: false,
          title: const Text('Onboarding'),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // prevents swiping
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
            ),
            // STEP 3: Sizes
            _Step3Sizes(
              onboardingData: _onboardingData,
              availableSizes: availableSizes,
              onNext: _nextPage,
            ),
            // STEP 4: Notification & Privacy
            _Step4NotificationPrefs(
              onboardingData: _onboardingData,
              onNext: _nextPage,
            ),
          ],
        ),
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
  final _addressController = TextEditingController();
  DateTime? _birthday = DateTime.now(); // Store birthday as DateTime
  XFile? _pickedImage;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    // If we have existing data, populate
    _nameController.text = widget.onboardingData.name ?? '';
    _birthday = widget.onboardingData.birthday ?? DateTime(2000, 1, 1);
    _addressController.text = widget.onboardingData.address ?? '';
    _selectedGender = widget.onboardingData.gender;
    _nameController.addListener(() {
      setState(() {}); // Trigger rebuild when text changes
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
    final String imageName = 'profile_pics/${user.uid}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child(imageName);

    // Upload the file
    await storageRef.putFile(File(_pickedImage!.path));

    // Get the download URL and store it
    final downloadUrl = await storageRef.getDownloadURL();
    
    // Store in onboarding data
    setState(() {
      widget.onboardingData.profilePicUrl = downloadUrl;
    });
  }

  void _saveAndNext() {
    if (_formKey.currentState!.validate()) {
      widget.onboardingData.name = _nameController.text.trim();
      widget.onboardingData.birthday = _birthday;
      widget.onboardingData.address = _addressController.text.trim();
      widget.onboardingData.gender = _selectedGender;
      widget.onNext();
    }
  }

  Widget placesAutoCompleteTextField() {
    return GooglePlaceAutoCompleteTextField(
      // Connect this to our address controller
      textEditingController: _addressController,
      googleAPIKey:
          'AIzaSyB9vjhEDF4fRZ6x_Qy73Xgwhrb2GQjBjK8', // Replace with your valid key
      inputDecoration: const InputDecoration(
        hintText: 'Search your location',
      ),
      debounceTime: 400,
      // Restrict or broaden countries as needed
      countries: const ['il'], // example: "in", "fr", etc.
      isLatLngRequired: true,
      getPlaceDetailWithLatLng: (Prediction prediction) {
        // This callback provides lat and lng directly from the prediction
        debugPrint(
            'placeDetails lat: ${prediction.lat}, lng: ${prediction.lng}');
        // Save lat/lng in the onboarding data for future distance calculations
        if (prediction.lat != null && prediction.lng != null) {
          double? lat = double.tryParse(prediction.lat!);
          double? lng = double.tryParse(prediction.lng!);

          if (lat != null && lng != null) {
            widget.onboardingData.latitude = lat;
            widget.onboardingData.longitude = lng;
          }
        }
      },
      itemClick: (Prediction prediction) {
        // When user taps a prediction in the dropdown,
        // set the text and move the cursor to the end.
        _addressController.text = prediction.description ?? '';
        _addressController.selection = TextSelection.fromPosition(
          TextPosition(offset: prediction.description?.length ?? 0),
        );
        // If you need to store textual address immediately, do it here
        widget.onboardingData.address = prediction.description;
      },

      // Optional customization of how each row in the suggestion list is built
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

      // Show a cross/clear button in the widget
      isCrossBtnShown: true,
    );
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
                        ? const Icon(Icons.camera_alt,
                            size: 50, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Step 1: Personal Info',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Full Name',
                      floatingLabelBehavior: FloatingLabelBehavior.always),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Birthday'),
                  trailing: Text(
                    _birthday != null
                        ? "${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}"
                        : 'Select your birthday',
                    style: TextStyle(
                        color: _birthday == null ? Colors.grey : Colors.black),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000, 1, 1),
                      firstDate: DateTime(1900, 1, 1),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        _birthday = pickedDate;
                      });
                    }
                  },
                ),
                const Divider(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 50,
                      children: _genders.map((gender) {
                        return ChoiceChip(
                          label: Text(gender),
                          selected: _selectedGender == gender,
                          onSelected: (selected) {
                            setState(() {
                              _selectedGender = selected ? gender : null;
                            });
                          },
                          selectedColor: Theme.of(context)
                              .textSelectionTheme
                              .selectionColor,
                          labelStyle: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight: _selectedGender == gender
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedGender == gender
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const Divider(),
                placesAutoCompleteTextField(),
                const Divider(),
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

  const _Step2FavoriteBrands({
    Key? key,
    required this.onboardingData,
    required this.allBrands,
    required this.onNext,
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
                ElevatedButton(
                    onPressed: _saveAndNext, child: const Text('Next'))
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

  const _Step3Sizes({
    Key? key,
    required this.onboardingData,
    required this.availableSizes,
    required this.onNext,
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
    userSizes = {...widget.onboardingData.userSizes}
        .map((key, value) => MapEntry(key, {...value}));
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

  const _Step4NotificationPrefs({
    Key? key,
    required this.onboardingData,
    required this.onNext,
  }) : super(key: key);

  @override
  State<_Step4NotificationPrefs> createState() =>
      _Step4NotificationPrefsState();
}

class _Step4NotificationPrefsState extends State<_Step4NotificationPrefs> {
  Future<void> _showPrivacyPolicy() async {
    try {
      final String privacyPolicyText =
          await rootBundle.loadString('assets/privacy_policy.txt');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Privacy Policy'),
            content: SingleChildScrollView(
              child: Text(privacyPolicyText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Handle any file loading errors here
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'Could not load the privacy policy. Please contact +972-528783610 urgently.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  /// Method to load and show the Terms & Conditions
  Future<void> _showTermsAndConditions() async {
    try {
      final String termsText =
          await rootBundle.loadString('assets/terms_and_conditions.txt');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Terms & Conditions'),
            content: SingleChildScrollView(
              child: Text(termsText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Handle any file loading errors here
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'Could not load the terms and conditions. Please contact +972-528783610 urgently.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text('Step 4: Notifications & Privacy',
                style: Theme.of(context).textTheme.headlineSmall),
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
              title: RichText(
                text: TextSpan(
                  text: 'I agree to the ',
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _showPrivacyPolicy,
                    ),
                    const TextSpan(text: ' & '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _showTermsAndConditions,
                    ),
                  ],
                ),
              ),
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
