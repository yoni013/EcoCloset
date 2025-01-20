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

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

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

  /// No description provided for @uploadItemStep1.
  ///
  /// In en, this message translates to:
  /// **'Upload Item - Step 1'**
  String get uploadItemStep1;

  /// No description provided for @uploadItemStep2.
  ///
  /// In en, this message translates to:
  /// **'Upload Item - Step 2'**
  String get uploadItemStep2;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload Images (up to 6):'**
  String get uploadImages;

  /// No description provided for @pickImages.
  ///
  /// In en, this message translates to:
  /// **'Pick Images'**
  String get pickImages;

  /// No description provided for @analyzeImages.
  ///
  /// In en, this message translates to:
  /// **'Analyze Images with Gemini'**
  String get analyzeImages;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

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

  /// No description provided for @colorRequired.
  ///
  /// In en, this message translates to:
  /// **'Color is required'**
  String get colorRequired;

  /// No description provided for @typeRequired.
  ///
  /// In en, this message translates to:
  /// **'Type is required'**
  String get typeRequired;

  /// No description provided for @sizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Size is required'**
  String get sizeRequired;

  /// No description provided for @conditionRequired.
  ///
  /// In en, this message translates to:
  /// **'Condition is required'**
  String get conditionRequired;

  /// No description provided for @brandRequired.
  ///
  /// In en, this message translates to:
  /// **'Brand is required'**
  String get brandRequired;

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

  /// No description provided for @sizePreferences.
  ///
  /// In en, this message translates to:
  /// **'Size Preferences'**
  String get sizePreferences;

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

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

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
