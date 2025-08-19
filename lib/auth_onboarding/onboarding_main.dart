import 'package:flutter/foundation.dart' show Uint8List;

import 'package:eco_closet/bottom_navigation.dart';
import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:eco_closet/auth_onboarding/authentication.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';



class UserOnboardingData {
  // Step 1: Personal info
  String? name;
  DateTime? birthday;
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
  bool enableAnalytics = false;
  bool enablePersonalizedRecommendations = false;
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
      // Last step is index 3 (0=step1,1=step2,2=step3,3=step4)
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigate to the previous page
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
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
            'enableAnalytics': _onboardingData.enableAnalytics,
            'enablePersonalizedRecommendations': _onboardingData.enablePersonalizedRecommendations,
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
    final theme = Theme.of(context);
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        return;
      },
      child: Theme(
        data: theme.copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: theme.colorScheme.primary,
            selectionColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
            selectionHandleColor: theme.colorScheme.primary,
          ),
        ),
        child: Scaffold(
        appBar: AppBar(
          // Add signout button on first step only
          automaticallyImplyLeading: false,
          leading: _currentPage == 0 
            ? IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final shouldSignOut = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out? Your progress will be lost.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  
                  if (shouldSignOut == true) {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => AuthGate()),
                    );
                  }
                },
                tooltip: 'Sign Out',
              )
            : null,
          // Progress bar as the main content
          title: Column(
            children: [
              const SizedBox(height: 8),
              StepProgressIndicator(
                totalSteps: 4,
                currentStep: _currentPage + 1,
                size: 6,
                selectedColor: theme.colorScheme.primary,
                unselectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                roundedEdges: const Radius.circular(3),
              ),
              const SizedBox(height: 4),
              Text(
                'Step ${_currentPage + 1} of 4',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 1,
          surfaceTintColor: theme.colorScheme.surfaceTint,
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
              onBack: _previousPage,
            ),
            // STEP 3: Sizes
            _Step3Sizes(
              onboardingData: _onboardingData,
              availableSizes: availableSizes,
              onNext: _nextPage,
              onBack: _previousPage,
            ),
            // STEP 4: Notification & Privacy
            _Step4NotificationPrefs(
              onboardingData: _onboardingData,
              onNext: _nextPage,
              onBack: _previousPage,
            ),
          ],
        ),
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
  dynamic _pickedImage; // Can be XFile or CroppedFile
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
    // Show privacy consent dialog before accessing photos
    final hasConsent = await _showPhotoPermissionConsent();
    if (!hasConsent) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Keep high quality for cropping
      );
      
      if (image == null) return; // User cancelled

      // Crop the selected image
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Square crop
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            hidesNavigationBar: false,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(
              width: 520,
              height: 520,
            ),
          ),
        ],
      );

      if (croppedFile == null) return; // User cancelled cropping

      setState(() {
        _pickedImage = croppedFile;
      });
    } catch (e) {
      // Handle errors silently or show a simple message
      debugPrint('Error picking/cropping image: $e');
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

    // Upload the file using bytes for cross-platform compatibility
    late List<int> bytes;
    if (_pickedImage is XFile) {
      bytes = await (_pickedImage as XFile).readAsBytes();
    } else if (_pickedImage is CroppedFile) {
      bytes = await (_pickedImage as CroppedFile).readAsBytes();
    } else {
      return; // Invalid image type
    }
    
    await storageRef.putData(Uint8List.fromList(bytes));

    // Get the download URL and store it
    final downloadUrl = await storageRef.getDownloadURL();
    
    // Store in onboarding data
    setState(() {
      widget.onboardingData.profilePicUrl = downloadUrl;
    });
  }

  /// Age verification - user must be at least 16 years old
  bool _verifyAge(DateTime birthday) {
    final now = DateTime.now();
    final age = now.difference(birthday).inDays / 365.25; // Account for leap years
    return age >= 16;
  }

  /// Show age restriction dialog and exit app
  Future<void> _showAgeRestrictionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Age Restriction'),
          content: const Text(
            'Sorry, you must be at least 16 years old to use EcoCloset. '
            'This is required by our terms of service and applicable laws.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Sign out the user and return to auth screen
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => AuthGate()),
                  (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show photo permission consent dialog
  Future<bool> _showPhotoPermissionConsent() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Photo Access'),
          content: const Text(
            'We need access to your photos to:\n'
            '• Set your profile picture\n'
            '• Upload item photos for listing\n\n'
            'Your photos will only be used for your EcoCloset profile and listings. '
            'We do not access or store other photos from your device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Deny'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Show location data consent dialog
  Future<bool> _showLocationConsent() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Information'),
          content: const Text(
            'We collect your address to:\n'
            '• Help buyers find items near them\n'
            '• Facilitate local meetups for item exchanges\n'
            '• Show approximate distance to items\n\n'
            'Your exact address is only shared with confirmed buyers. '
            'We use your location data responsibly and never sell it to third parties.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );
    return result ?? false;
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

  void _showBirthdayPicker() {
    DateTime tempDate = _birthday ?? DateTime(2000, 1, 1);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    if (_verifyAge(tempDate)) {
                      setState(() {
                        _birthday = tempDate;
                      });
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                      _showAgeRestrictionDialog();
                    }
                  },
                  child: const Text('Done'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumDate: DateTime(1900, 1, 1),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget placesAutoCompleteTextField() {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _addressController,
      decoration: InputDecoration(
        hintText: 'Enter your address (City, Street)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: MaterialStateColor.resolveWith((states) {
          if (states.contains(MaterialState.focused)) {
            return theme.colorScheme.surfaceContainerHighest;
          }
          return theme.colorScheme.surface;
        }),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        prefixIcon: Icon(
          Icons.location_on,
          color: theme.colorScheme.primary,
        ),
      ),
      style: theme.textTheme.bodyLarge,
      onTap: () async {
        // Show location consent when user first taps address field
        if (_addressController.text.isEmpty && widget.onboardingData.address?.isEmpty != false) {
          final hasConsent = await _showLocationConsent();
          if (!hasConsent) {
            // User denied, clear focus
            FocusScope.of(context).unfocus();
            return;
          }
        }
      },
      onChanged: (value) {
        widget.onboardingData.address = value;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                const SizedBox(height: 16),
                // Avatar for profile image
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF006B60).withValues(alpha: 0.2),
                    child: _pickedImage != null
                        ? FutureBuilder<Uint8List>(
                            future: () async {
                              if (_pickedImage is XFile) {
                                return await (_pickedImage as XFile).readAsBytes();
                              } else if (_pickedImage is CroppedFile) {
                                return await (_pickedImage as CroppedFile).readAsBytes();
                              }
                              throw Exception('Invalid image type');
                            }(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return CircleAvatar(
                                  radius: 60,
                                  backgroundImage: MemoryImage(snapshot.data!),
                                );
                              }
                              return const CircularProgressIndicator();
                            },
                          )
                        : const Icon(Icons.camera_alt,
                            size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                // Full Name Field with label above
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Name',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: MaterialStateColor.resolveWith((states) {
                          if (states.contains(MaterialState.focused)) {
                            return theme.colorScheme.surfaceContainerHighest;
                          }
                          return theme.colorScheme.surface;
                        }),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      style: theme.textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Birthday Field with label above
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Birthday',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surface,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _showBirthdayPicker,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _birthday != null
                                  ? DateFormat.yMMMd().format(_birthday!)
                                  : 'Select your birthday',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: _birthday == null 
                                    ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Gender Field with label above
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gender',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surface,
                      ),
                      child: Wrap(
                        spacing: 12,
                        children: _genders.map((gender) {
                          return ChoiceChip(
                            label: Text(gender),
                            selected: _selectedGender == gender,
                            onSelected: (selected) {
                              setState(() {
                                _selectedGender = selected ? gender : null;
                              });
                            },
                            selectedColor: theme.colorScheme.primaryContainer,
                            backgroundColor: theme.colorScheme.surface,
                            labelStyle: TextStyle(
                              color: _selectedGender == gender
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                              fontWeight: _selectedGender == gender
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: _selectedGender == gender
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Address Field with label above
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    placesAutoCompleteTextField(),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _nameController.text.trim().isNotEmpty
                          ? () {
                              _saveAndNext();
                              _uploadProfileImage();
                            }
                          : null, // Disable button if name is empty
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ],
              ),
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
  final VoidCallback onBack;

  const _Step2FavoriteBrands({
    Key? key,
    required this.onboardingData,
    required this.allBrands,
    required this.onNext,
    required this.onBack,
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
    final theme = Theme.of(context);
    // Convert each brand into a MultiSelectItem
    final items = widget.allBrands
        .map((brand) => MultiSelectItem<String>(brand, brand))
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Pick Your Favorite Brands',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '(Optional - Select brands you love shopping from)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: MultiSelectChipField<String?>(
                  items: items,
                  title: const Text('Favorite Brands'),
                  scroll: false,
                  headerColor: theme.colorScheme.primaryContainer,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selectedChipColor: theme.colorScheme.primary,
                  selectedTextStyle: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  initialValue: _selectedBrands,
                  onTap: (selection) {
                    setState(() {
                      _selectedBrands = selection.whereType<String>().toList();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: widget.onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveAndNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step3Sizes extends StatefulWidget {
  final UserOnboardingData onboardingData;
  final Map<String, List<String>> availableSizes;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step3Sizes({
    Key? key,
    required this.onboardingData,
    required this.availableSizes,
    required this.onNext,
    required this.onBack,
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
    final theme = Theme.of(context);
    final items = widget.availableSizes[category]!
        .map((size) => MultiSelectItem<String>(size, size))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MultiSelectDialogField<String>(
        title: Text(
          category,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        items: items,
        searchable: true,
        initialValue: userSizes[category]?.toList() ?? [],
        buttonText: Text(
          'Select $category Sizes',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12.0),
          color: theme.colorScheme.surface,
        ),
        itemsTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        selectedItemsTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: theme.colorScheme.surface,
        checkColor: theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    final categories = widget.availableSizes.keys.toList();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Size Preferences',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '(Optional - Select your clothing sizes)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
            Flexible(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (ctx, i) {
                  final category = categories[i];
                  return _buildMultiSelectField(category);
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: widget.onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveAndNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step4NotificationPrefs extends StatefulWidget {
  final UserOnboardingData onboardingData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step4NotificationPrefs({
    Key? key,
    required this.onboardingData,
    required this.onNext,
    required this.onBack,
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Notifications & Privacy',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Configure your preferences and accept our terms',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
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
            const SizedBox(height: 20),
            // Analytics and Data Usage Section
            Text(
              'Data Usage & Analytics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable Analytics'),
              subtitle: const Text('Help us improve by sharing anonymous usage data'),
              value: widget.onboardingData.enableAnalytics,
              onChanged: (val) {
                setState(() {
                  widget.onboardingData.enableAnalytics = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Personalized Recommendations'),
              subtitle: const Text('Use AI to suggest items based on your preferences'),
              value: widget.onboardingData.enablePersonalizedRecommendations,
              onChanged: (val) {
                setState(() {
                  widget.onboardingData.enablePersonalizedRecommendations = val;
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: widget.onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.onboardingData.hasAcceptedPrivacyPolicy
                      ? widget.onNext
                      : null, // Disable button if not accepted
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Finish',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
