import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Eco Closet'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Eco Closet!'**
  String get welcomeMessage;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @myShop.
  ///
  /// In en, this message translates to:
  /// **'My Shop'**
  String get myShop;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent to your email address. Please check your inbox and verify your email before logging in.'**
  String get verifyEmailMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @signInScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInScreenTitle;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error occurred!'**
  String get errorOccurred;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @waitingForAuth.
  ///
  /// In en, this message translates to:
  /// **'Waiting for authentication...'**
  String get waitingForAuth;

  /// No description provided for @persistentNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get persistentNavHome;

  /// No description provided for @persistentNavExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get persistentNavExplore;

  /// No description provided for @persistentNavUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get persistentNavUpload;

  /// No description provided for @persistentNavMyShop.
  ///
  /// In en, this message translates to:
  /// **'My Shop'**
  String get persistentNavMyShop;

  /// No description provided for @persistentNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get persistentNavProfile;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get newUser;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @enablePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Push Notifications'**
  String get enablePushNotifications;

  /// No description provided for @enableEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Email Notifications'**
  String get enableEmailNotifications;

  /// No description provided for @enableSmsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable SMS Notifications'**
  String get enableSmsNotifications;

  /// No description provided for @addressSearch.
  ///
  /// In en, this message translates to:
  /// **'Search your location'**
  String get addressSearch;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @currentPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get currentPasswordPlaceholder;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get newPasswordPlaceholder;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNewPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get confirmNewPasswordPlaceholder;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChangedSuccess;

  /// No description provided for @errorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get errorInvalidCredential;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The current password is incorrect.'**
  String get errorWrongPassword;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The new password is too weak.'**
  String get errorWeakPassword;

  /// No description provided for @errorNoCurrentUser.
  ///
  /// In en, this message translates to:
  /// **'No user is currently signed in.'**
  String get errorNoCurrentUser;

  /// No description provided for @errorReauthentication.
  ///
  /// In en, this message translates to:
  /// **'Re-authentication error.'**
  String get errorReauthentication;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get errorGeneric;

  /// No description provided for @errorSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorSomethingWentWrong;

  /// No description provided for @sizePreferences.
  ///
  /// In en, this message translates to:
  /// **'Size Preferences'**
  String get sizePreferences;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

  /// No description provided for @chooseCategories.
  ///
  /// In en, this message translates to:
  /// **'Choose Categories'**
  String get chooseCategories;

  /// No description provided for @categoryDresses.
  ///
  /// In en, this message translates to:
  /// **'Dresses'**
  String get categoryDresses;

  /// No description provided for @shopAll.
  ///
  /// In en, this message translates to:
  /// **'Shop All'**
  String get shopAll;

  /// No description provided for @categoryActivewear.
  ///
  /// In en, this message translates to:
  /// **'Activewear'**
  String get categoryActivewear;

  /// No description provided for @categoryBelts.
  ///
  /// In en, this message translates to:
  /// **'Belts'**
  String get categoryBelts;

  /// No description provided for @categoryCoats.
  ///
  /// In en, this message translates to:
  /// **'Coats'**
  String get categoryCoats;

  /// No description provided for @categoryGloves.
  ///
  /// In en, this message translates to:
  /// **'Gloves'**
  String get categoryGloves;

  /// No description provided for @categoryHats.
  ///
  /// In en, this message translates to:
  /// **'Hats'**
  String get categoryHats;

  /// No description provided for @categoryJeans.
  ///
  /// In en, this message translates to:
  /// **'Jeans'**
  String get categoryJeans;

  /// No description provided for @categoryJumpsuits.
  ///
  /// In en, this message translates to:
  /// **'Jumpsuits'**
  String get categoryJumpsuits;

  /// No description provided for @categoryOveralls.
  ///
  /// In en, this message translates to:
  /// **'Overalls'**
  String get categoryOveralls;

  /// No description provided for @categoryPants.
  ///
  /// In en, this message translates to:
  /// **'Pants'**
  String get categoryPants;

  /// No description provided for @categoryScarves.
  ///
  /// In en, this message translates to:
  /// **'Scarves'**
  String get categoryScarves;

  /// No description provided for @categoryShirts.
  ///
  /// In en, this message translates to:
  /// **'Shirts'**
  String get categoryShirts;

  /// No description provided for @categoryShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get categoryShoes;

  /// No description provided for @categoryShorts.
  ///
  /// In en, this message translates to:
  /// **'Shorts'**
  String get categoryShorts;

  /// No description provided for @categorySkirts.
  ///
  /// In en, this message translates to:
  /// **'Skirts'**
  String get categorySkirts;

  /// No description provided for @categorySleepwear.
  ///
  /// In en, this message translates to:
  /// **'Sleepwear'**
  String get categorySleepwear;

  /// No description provided for @categorySweaters.
  ///
  /// In en, this message translates to:
  /// **'Sweaters'**
  String get categorySweaters;

  /// No description provided for @categorySwimwear.
  ///
  /// In en, this message translates to:
  /// **'Swimwear'**
  String get categorySwimwear;

  /// No description provided for @colorBeige.
  ///
  /// In en, this message translates to:
  /// **'Beige'**
  String get colorBeige;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// No description provided for @colorCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Color'**
  String get colorCustom;

  /// No description provided for @colorGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get colorGold;

  /// No description provided for @colorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get colorGray;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorMaroon.
  ///
  /// In en, this message translates to:
  /// **'Maroon'**
  String get colorMaroon;

  /// No description provided for @colorMulticolor.
  ///
  /// In en, this message translates to:
  /// **'Multicolor'**
  String get colorMulticolor;

  /// No description provided for @colorNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get colorNavy;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get colorSilver;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @conditionNeverUsed.
  ///
  /// In en, this message translates to:
  /// **'Never Used'**
  String get conditionNeverUsed;

  /// No description provided for @conditionUsedOnce.
  ///
  /// In en, this message translates to:
  /// **'Used Once'**
  String get conditionUsedOnce;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get conditionNew;

  /// No description provided for @conditionLikeNew.
  ///
  /// In en, this message translates to:
  /// **'Like New'**
  String get conditionLikeNew;

  /// No description provided for @conditionGentlyUsed.
  ///
  /// In en, this message translates to:
  /// **'Gently Used'**
  String get conditionGentlyUsed;

  /// No description provided for @conditionWornGood.
  ///
  /// In en, this message translates to:
  /// **'Worn (Good Condition)'**
  String get conditionWornGood;

  /// No description provided for @conditionVintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get conditionVintage;

  /// No description provided for @conditionDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged (Repair Needed)'**
  String get conditionDamaged;

  /// No description provided for @selectSizes.
  ///
  /// In en, this message translates to:
  /// **'Select {category} Sizes'**
  String selectSizes(Object category);

  /// No description provided for @uploadItemStep1.
  ///
  /// In en, this message translates to:
  /// **'Upload Item - Step 1'**
  String get uploadItemStep1;

  /// No description provided for @photoTips.
  ///
  /// In en, this message translates to:
  /// **'Tips for better results:\n- Take clear photos, possibly wearing the item.\n- Capture labels or tags clearly.\n'**
  String get photoTips;

  /// No description provided for @mainImageInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap an image to set it as the main image for this item.\nThe first image in the list will be used as the main image.'**
  String get mainImageInstructions;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select From Gallery'**
  String get selectFromGallery;

  /// No description provided for @maxImagesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 6 images allowed.'**
  String get maxImagesAllowed;

  /// No description provided for @pickImages.
  ///
  /// In en, this message translates to:
  /// **'Pick Images'**
  String get pickImages;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @uploadItemStep2.
  ///
  /// In en, this message translates to:
  /// **'Upload Item - Step 2'**
  String get uploadItemStep2;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @brandRequired.
  ///
  /// In en, this message translates to:
  /// **'Brand is required'**
  String get brandRequired;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @colorRequired.
  ///
  /// In en, this message translates to:
  /// **'Color is required'**
  String get colorRequired;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @conditionRequired.
  ///
  /// In en, this message translates to:
  /// **'Condition is required'**
  String get conditionRequired;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @sizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Size is required'**
  String get sizeRequired;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @typeRequired.
  ///
  /// In en, this message translates to:
  /// **'Type is required'**
  String get typeRequired;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @priceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get priceRequired;

  /// No description provided for @priceValidInteger.
  ///
  /// In en, this message translates to:
  /// **'Price must be a valid integer'**
  String get priceValidInteger;

  /// No description provided for @priceGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than 0'**
  String get priceGreaterThanZero;

  /// No description provided for @itemUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item uploaded successfully!'**
  String get itemUploadedSuccess;

  /// No description provided for @verifyYourPrice.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Price'**
  String get verifyYourPrice;

  /// No description provided for @priceVerificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Your price is {ratioPercent}% of the recommended price of {estimated}₪. Do you still want to upload?'**
  String priceVerificationMessage(Object estimated, Object ratioPercent);

  /// No description provided for @changePrice.
  ///
  /// In en, this message translates to:
  /// **'Change Price'**
  String get changePrice;

  /// No description provided for @uploadItem.
  ///
  /// In en, this message translates to:
  /// **'Upload Item'**
  String get uploadItem;

  /// No description provided for @sortByPriceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price (Low to High)'**
  String get sortByPriceLowToHigh;

  /// No description provided for @sortByPriceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price (High to Low)'**
  String get sortByPriceHighToLow;

  /// No description provided for @sortByRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get sortByRecommended;

  /// No description provided for @forMe.
  ///
  /// In en, this message translates to:
  /// **'For Me'**
  String get forMe;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @noItemsMatch.
  ///
  /// In en, this message translates to:
  /// **'No items match your search.'**
  String get noItemsMatch;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @analyzeImagesMetadata.
  ///
  /// In en, this message translates to:
  /// **'Analyze the provided images and extract metadata including brand, color, condition, size, and type.'**
  String get analyzeImagesMetadata;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeDark;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutMessage;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get recommendedForYou;

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trendingNow;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsAndCondition.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndCondition;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get helpFeedback;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @confirmSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmSignOutMessage;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload Images (up to 6):'**
  String get uploadImages;

  /// No description provided for @analyzeImages.
  ///
  /// In en, this message translates to:
  /// **'Analyze Images with Gemini'**
  String get analyzeImages;

  /// No description provided for @validPrice.
  ///
  /// In en, this message translates to:
  /// **'Valid price is required'**
  String get validPrice;

  /// No description provided for @itemUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item uploaded successfully!'**
  String get itemUploadSuccess;

  /// No description provided for @errorUploadingItem.
  ///
  /// In en, this message translates to:
  /// **'Error uploading item: {error}'**
  String errorUploadingItem(Object error);

  /// No description provided for @itemDetails.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get itemDetails;

  /// No description provided for @failedToLoadItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to load item details'**
  String get failedToLoadItem;

  /// No description provided for @unknownItem.
  ///
  /// In en, this message translates to:
  /// **'Unknown Item'**
  String get unknownItem;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescription;

  /// No description provided for @loadingSeller.
  ///
  /// In en, this message translates to:
  /// **'Loading seller info...'**
  String get loadingSeller;

  /// No description provided for @unknownSeller.
  ///
  /// In en, this message translates to:
  /// **'Unknown Seller'**
  String get unknownSeller;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviews;

  /// No description provided for @contactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact Seller'**
  String get contactSeller;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @buyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get buyer;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @markAsShipped.
  ///
  /// In en, this message translates to:
  /// **'Mark as Shipped'**
  String get markAsShipped;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @shipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shipped;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @unknownBuyer.
  ///
  /// In en, this message translates to:
  /// **'Unknown Buyer'**
  String get unknownBuyer;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @incomingOrders.
  ///
  /// In en, this message translates to:
  /// **'Incoming Orders'**
  String get incomingOrders;

  /// No description provided for @outgoingOrders.
  ///
  /// In en, this message translates to:
  /// **'Outgoing Orders'**
  String get outgoingOrders;

  /// No description provided for @noIncomingOrders.
  ///
  /// In en, this message translates to:
  /// **'No incoming orders found.'**
  String get noIncomingOrders;

  /// No description provided for @noOutgoingOrders.
  ///
  /// In en, this message translates to:
  /// **'No outgoing orders found.'**
  String get noOutgoingOrders;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @errorFetchingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error fetching orders: '**
  String get errorFetchingOrders;

  /// No description provided for @errorUpdatingStatus.
  ///
  /// In en, this message translates to:
  /// **'Error updating order status: '**
  String get errorUpdatingStatus;

  /// No description provided for @errorFetchingBuyer.
  ///
  /// In en, this message translates to:
  /// **'Error fetching buyer name: '**
  String get errorFetchingBuyer;

  /// No description provided for @errorFetchingImage.
  ///
  /// In en, this message translates to:
  /// **'Error fetching item image: '**
  String get errorFetchingImage;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Get better recommendations by updating your profile!'**
  String get onboardingTitle;

  /// No description provided for @defaultUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUser;

  /// No description provided for @errorFetchingUserData.
  ///
  /// In en, this message translates to:
  /// **'Error fetching user data: '**
  String get errorFetchingUserData;

  /// No description provided for @profileSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Profile submitted successfully.'**
  String get profileSubmitted;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @preferredShirtSize.
  ///
  /// In en, this message translates to:
  /// **'Preferred Shirt Size'**
  String get preferredShirtSize;

  /// No description provided for @pantsSize.
  ///
  /// In en, this message translates to:
  /// **'Pants Size'**
  String get pantsSize;

  /// No description provided for @shoeSize.
  ///
  /// In en, this message translates to:
  /// **'Shoe Size'**
  String get shoeSize;

  /// No description provided for @preferredBrands.
  ///
  /// In en, this message translates to:
  /// **'Preferred Brands'**
  String get preferredBrands;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @addSize.
  ///
  /// In en, this message translates to:
  /// **'Add Size'**
  String get addSize;

  /// No description provided for @preferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved successfully!'**
  String get preferencesSaved;

  /// No description provided for @jackets.
  ///
  /// In en, this message translates to:
  /// **'Jackets'**
  String get jackets;

  /// No description provided for @sweaters.
  ///
  /// In en, this message translates to:
  /// **'Sweaters'**
  String get sweaters;

  /// No description provided for @tShirts.
  ///
  /// In en, this message translates to:
  /// **'T-Shirts'**
  String get tShirts;

  /// No description provided for @pants.
  ///
  /// In en, this message translates to:
  /// **'Pants'**
  String get pants;

  /// No description provided for @shoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get shoes;

  /// No description provided for @profilePage.
  ///
  /// In en, this message translates to:
  /// **'Profile Page'**
  String get profilePage;

  /// No description provided for @userReviews.
  ///
  /// In en, this message translates to:
  /// **'User Reviews'**
  String get userReviews;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get noContent;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @failedToLoadUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user data'**
  String get failedToLoadUser;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search Items'**
  String get searchItems;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @unknownBrand.
  ///
  /// In en, this message translates to:
  /// **'Unknown Brand'**
  String get unknownBrand;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @thisFieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get thisFieldIsRequired;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @soldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold Out'**
  String get soldOut;

  /// No description provided for @existingImages.
  ///
  /// In en, this message translates to:
  /// **'Existing Images'**
  String get existingImages;

  /// No description provided for @noImagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get noImagesAvailable;

  /// No description provided for @mainImage.
  ///
  /// In en, this message translates to:
  /// **'Main Image'**
  String get mainImage;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @newImages.
  ///
  /// In en, this message translates to:
  /// **'New Images'**
  String get newImages;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @addImages.
  ///
  /// In en, this message translates to:
  /// **'Add Images'**
  String get addImages;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @anonymous_reviewer.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Reviewer'**
  String get anonymous_reviewer;

  /// No description provided for @sizePreferencesInfo.
  ///
  /// In en, this message translates to:
  /// **'Choose the sizes you usually wear to receive better recommendations for items that fit you.'**
  String get sizePreferencesInfo;

  /// No description provided for @sizePreferencesDescription.
  ///
  /// In en, this message translates to:
  /// **'Select your size preferences to get better recommendations.'**
  String get sizePreferencesDescription;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized'**
  String get unauthorized;

  /// No description provided for @unauthorizedAccess.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized Access'**
  String get unauthorizedAccess;

  /// No description provided for @unauthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your access is unauthorized. Please log in again to continue.'**
  String get unauthorizedMessage;

  /// No description provided for @itemProperties.
  ///
  /// In en, this message translates to:
  /// **'Item Properties'**
  String get itemProperties;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @coats.
  ///
  /// In en, this message translates to:
  /// **'Coats'**
  String get coats;

  /// No description provided for @newCondition.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newCondition;

  /// No description provided for @likeNewCondition.
  ///
  /// In en, this message translates to:
  /// **'Like New'**
  String get likeNewCondition;

  /// No description provided for @goodCondition.
  ///
  /// In en, this message translates to:
  /// **'Good Condition'**
  String get goodCondition;

  /// No description provided for @fairCondition.
  ///
  /// In en, this message translates to:
  /// **'Fair Condition'**
  String get fairCondition;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @analyzingImages.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Images...'**
  String get analyzingImages;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'select {label}'**
  String select(String label);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'he': return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
