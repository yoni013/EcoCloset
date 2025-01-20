import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Eco Closet';

  @override
  String get welcomeMessage => 'Welcome to Eco Closet!';

  @override
  String get home => 'Home';

  @override
  String get explore => 'Explore';

  @override
  String get upload => 'Upload';

  @override
  String get myShop => 'My Shop';

  @override
  String get profile => 'Profile';

  @override
  String get verifyEmailTitle => 'Verify Your Email';

  @override
  String get verifyEmailMessage => 'A verification email has been sent to your email address. Please check your inbox and verify your email before logging in.';

  @override
  String get ok => 'OK';

  @override
  String get signInScreenTitle => 'Sign In';

  @override
  String get errorOccurred => 'Error occurred!';

  @override
  String get signOut => 'Sign Out';

  @override
  String get waitingForAuth => 'Waiting for authentication...';

  @override
  String get persistentNavHome => 'Home';

  @override
  String get persistentNavExplore => 'Explore';

  @override
  String get persistentNavUpload => 'Upload';

  @override
  String get persistentNavMyShop => 'My Shop';

  @override
  String get persistentNavProfile => 'Profile';

  @override
  String get newUser => 'New User';

  @override
  String get loading => 'Loading...';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get submit => 'Submit';

  @override
  String get address => 'Address';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get themeLight => 'Light Theme';

  @override
  String get themeDark => 'Dark Theme';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get settings => 'Settings';

  @override
  String get logoutMessage => 'Are you sure you want to log out?';

  @override
  String get logout => 'Logout';

  @override
  String get recommendedForYou => 'Recommended for You';

  @override
  String get trendingNow => 'Trending Now';

  @override
  String get general => 'General';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get notifications => 'Notifications';

  @override
  String get language => 'Language';

  @override
  String get account => 'Account';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get changePassword => 'Change Password';

  @override
  String get support => 'Support';

  @override
  String get helpFeedback => 'Help & Feedback';

  @override
  String get about => 'About';

  @override
  String get confirmSignOutMessage => 'Are you sure you want to sign out?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get uploadItemStep1 => 'Upload Item - Step 1';

  @override
  String get uploadItemStep2 => 'Upload Item - Step 2';

  @override
  String get uploadImages => 'Upload Images (up to 6):';

  @override
  String get pickImages => 'Pick Images';

  @override
  String get analyzeImages => 'Analyze Images with Gemini';

  @override
  String get brand => 'Brand';

  @override
  String get color => 'Color';

  @override
  String get condition => 'Condition';

  @override
  String get size => 'Size';

  @override
  String get type => 'Type';

  @override
  String get description => 'Description';

  @override
  String get price => 'Price';

  @override
  String get validPrice => 'Valid price is required';

  @override
  String get itemUploadSuccess => 'Item uploaded successfully!';

  @override
  String errorUploadingItem(Object error) {
    return 'Error uploading item: $error';
  }

  @override
  String get colorRequired => 'Color is required';

  @override
  String get typeRequired => 'Type is required';

  @override
  String get sizeRequired => 'Size is required';

  @override
  String get conditionRequired => 'Condition is required';

  @override
  String get brandRequired => 'Brand is required';

  @override
  String get itemDetails => 'Item Details';

  @override
  String get failedToLoadItem => 'Failed to load item details';

  @override
  String get unknownItem => 'Unknown Item';

  @override
  String get notAvailable => 'N/A';

  @override
  String get noDescription => 'No description provided.';

  @override
  String get loadingSeller => 'Loading seller info...';

  @override
  String get unknownSeller => 'Unknown Seller';

  @override
  String get reviews => 'reviews';

  @override
  String get contactSeller => 'Contact Seller';

  @override
  String get buyNow => 'Buy Now';

  @override
  String get item => 'Item';

  @override
  String get buyer => 'Buyer';

  @override
  String get status => 'Status';

  @override
  String get actions => 'Actions';

  @override
  String get approve => 'Approve';

  @override
  String get decline => 'Decline';

  @override
  String get markAsShipped => 'Mark as Shipped';

  @override
  String get approved => 'Approved';

  @override
  String get declined => 'Declined';

  @override
  String get shipped => 'Shipped';

  @override
  String get pending => 'Pending';

  @override
  String get unknownBuyer => 'Unknown Buyer';

  @override
  String get unknown => 'Unknown';

  @override
  String get errorFetchingOrders => 'Error fetching orders: ';

  @override
  String get errorUpdatingStatus => 'Error updating order status: ';

  @override
  String get errorFetchingBuyer => 'Error fetching buyer name: ';

  @override
  String get errorFetchingImage => 'Error fetching item image: ';

  @override
  String get onboardingTitle => 'Get better recommendations by updating your profile!';

  @override
  String get defaultUser => 'User';

  @override
  String get errorFetchingUserData => 'Error fetching user data: ';

  @override
  String get profileSubmitted => 'Profile submitted successfully.';

  @override
  String get age => 'Age';

  @override
  String get preferredShirtSize => 'Preferred Shirt Size';

  @override
  String get pantsSize => 'Pants Size';

  @override
  String get shoeSize => 'Shoe Size';

  @override
  String get preferredBrands => 'Preferred Brands';

  @override
  String get skip => 'Skip';

  @override
  String get sizePreferences => 'Size Preferences';

  @override
  String get addSize => 'Add Size';

  @override
  String get preferencesSaved => 'Preferences saved successfully!';

  @override
  String get savePreferences => 'Save Preferences';

  @override
  String get jackets => 'Jackets';

  @override
  String get sweaters => 'Sweaters';

  @override
  String get tShirts => 'T-Shirts';

  @override
  String get pants => 'Pants';

  @override
  String get shoes => 'Shoes';

  @override
  String get profilePage => 'Profile Page';

  @override
  String get userReviews => 'User Reviews';

  @override
  String get review => 'Review';

  @override
  String get noContent => 'No content';

  @override
  String get close => 'Close';

  @override
  String get failedToLoadUser => 'Failed to load user data';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get searchItems => 'Search Items';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get unknownBrand => 'Unknown Brand';
}
