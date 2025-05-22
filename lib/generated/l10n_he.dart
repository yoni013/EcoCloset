import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'EcoCloset';

  @override
  String get welcomeMessage => 'Welcome to Eco Closet!';

  @override
  String get home => 'Home';

  @override
  String get explore => 'Explore';

  @override
  String get upload => 'Upload';

  @override
  String get myShop => 'החנות שלי';

  @override
  String get profile => 'פרופיל';

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
  String get loading => 'טוען...';

  @override
  String get email => 'דואר אלקטרוני';

  @override
  String get password => 'סיסמה';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get forgotPassword => 'שכחת סיסמה?';

  @override
  String get submit => 'שליחה';

  @override
  String get address => 'כתובת';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get enablePushNotifications => 'Enable Push Notifications';

  @override
  String get enableEmailNotifications => 'Enable Email Notifications';

  @override
  String get enableSmsNotifications => 'Enable SMS Notifications';

  @override
  String get addressSearch => 'Search your location';

  @override
  String get update => 'Update';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get currentPasswordPlaceholder => 'Please enter your current password';

  @override
  String get newPassword => 'New Password';

  @override
  String get newPasswordPlaceholder => 'Please enter a new password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get confirmNewPasswordPlaceholder => 'Passwords do not match';

  @override
  String get changePassword => 'Change Password';

  @override
  String get passwordChangedSuccess => 'Password changed successfully!';

  @override
  String get errorInvalidCredential => 'Current password is incorrect.';

  @override
  String get errorWrongPassword => 'The current password is incorrect.';

  @override
  String get errorWeakPassword => 'The new password is too weak.';

  @override
  String get errorNoCurrentUser => 'No user is currently signed in.';

  @override
  String get errorReauthentication => 'Re-authentication error.';

  @override
  String get errorGeneric => 'An error occurred.';

  @override
  String get errorSomethingWentWrong => 'Something went wrong.';

  @override
  String get sizePreferences => 'Size Preferences';

  @override
  String get savePreferences => 'Save Preferences';

  @override
  String get chooseCategories => 'Choose Categories';

  @override
  String get categoryDresses => 'Dresses';

  @override
  String get shopAll => 'Shop All';

  @override
  String get categoryActivewear => 'Activewear';

  @override
  String get categoryBelts => 'Belts';

  @override
  String get categoryCoats => 'Coats';

  @override
  String get categoryGloves => 'Gloves';

  @override
  String get categoryHats => 'Hats';

  @override
  String get categoryJeans => 'Jeans';

  @override
  String get categoryJumpsuits => 'Jumpsuits';

  @override
  String get categoryOveralls => 'Overalls';

  @override
  String get categoryPants => 'Pants';

  @override
  String get categoryScarves => 'Scarves';

  @override
  String get categoryShirts => 'Shirts';

  @override
  String get categoryShoes => 'Shoes';

  @override
  String get categoryShorts => 'Shorts';

  @override
  String get categorySkirts => 'Skirts';

  @override
  String get categorySleepwear => 'Sleepwear';

  @override
  String get categorySweaters => 'Sweaters';

  @override
  String get categorySwimwear => 'Swimwear';

  @override
  String get colorBeige => 'Beige';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorCustom => 'Custom Color';

  @override
  String get colorGold => 'Gold';

  @override
  String get colorGray => 'Gray';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorMaroon => 'Maroon';

  @override
  String get colorMulticolor => 'Multicolor';

  @override
  String get colorNavy => 'Navy';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorRed => 'Red';

  @override
  String get colorSilver => 'Silver';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorWhite => 'White';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get conditionNeverUsed => 'Never Used';

  @override
  String get conditionUsedOnce => 'Used Once';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionLikeNew => 'Like New';

  @override
  String get conditionGentlyUsed => 'Gently Used';

  @override
  String get conditionWornGood => 'Worn (Good Condition)';

  @override
  String get conditionVintage => 'Vintage';

  @override
  String get conditionDamaged => 'Damaged (Repair Needed)';

  @override
  String selectSizes(Object category) {
    return 'Select $category Sizes';
  }

  @override
  String get uploadItemStep1 => 'Upload Item - Step 1';

  @override
  String get photoTips => 'Tips for better results:\n- Take clear photos, possibly wearing the item.\n- Capture labels or tags clearly.\n';

  @override
  String get mainImageInstructions => 'Tap an image to set it as the main image for this item.\nThe first image in the list will be used as the main image.';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get selectFromGallery => 'Select From Gallery';

  @override
  String get maxImagesAllowed => 'Maximum 6 images allowed.';

  @override
  String get pickImages => 'Pick Images';

  @override
  String get next => 'הבא';

  @override
  String get uploadItemStep2 => 'Upload Item - Step 2';

  @override
  String get brand => 'מותג';

  @override
  String get brandRequired => 'Brand is required';

  @override
  String get color => 'צבע';

  @override
  String get colorRequired => 'Color is required';

  @override
  String get condition => 'מצב';

  @override
  String get conditionRequired => 'Condition is required';

  @override
  String get size => 'מידה';

  @override
  String get sizeRequired => 'Size is required';

  @override
  String get type => 'סוג';

  @override
  String get typeRequired => 'Type is required';

  @override
  String get description => 'תיאור';

  @override
  String get price => 'מחיר';

  @override
  String get priceRequired => 'Price is required';

  @override
  String get priceValidInteger => 'Price must be a valid integer';

  @override
  String get priceGreaterThanZero => 'Price must be greater than 0';

  @override
  String get itemUploadedSuccess => 'Item uploaded successfully!';

  @override
  String get verifyYourPrice => 'Verify Your Price';

  @override
  String priceVerificationMessage(Object estimated, Object ratioPercent) {
    return 'Your price is $ratioPercent% of the recommended price of $estimated₪. Do you still want to upload?';
  }

  @override
  String get changePrice => 'Change Price';

  @override
  String get uploadItem => 'העלאת פריט';

  @override
  String get sortByPriceLowToHigh => 'Price (Low to High)';

  @override
  String get sortByPriceHighToLow => 'Price (High to Low)';

  @override
  String get sortByRecommended => 'Recommended';

  @override
  String get forMe => 'For Me';

  @override
  String get search => 'חיפוש';

  @override
  String get noItemsMatch => 'No items match your search.';

  @override
  String get filter => 'סינון';

  @override
  String get apply => 'החל';

  @override
  String get analyzeImagesMetadata => 'Analyze the provided images and extract metadata including brand, color, condition, size, and type.';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get themeLight => 'Light Theme';

  @override
  String get themeDark => 'Dark Theme';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get settings => 'הגדרות';

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
  String get darkMode => 'מצב כהה';

  @override
  String get notifications => 'התראות';

  @override
  String get language => 'שפה';

  @override
  String get account => 'חשבון';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsAndCondition => 'Terms & Conditions';

  @override
  String get name => 'שם';

  @override
  String get support => 'תמיכה';

  @override
  String get helpFeedback => 'Help & Feedback';

  @override
  String get about => 'אודות';

  @override
  String get confirmSignOutMessage => 'Are you sure you want to sign out?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get uploadImages => 'Upload Images (up to 6):';

  @override
  String get analyzeImages => 'Analyze Images with Gemini';

  @override
  String get validPrice => 'Valid price is required';

  @override
  String get itemUploadSuccess => 'Item uploaded successfully!';

  @override
  String errorUploadingItem(Object error) {
    return 'Error uploading item: $error';
  }

  @override
  String get itemDetails => 'פרטי פריט';

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
  String get contactSeller => 'צור קשר עם המוכר';

  @override
  String get buyNow => 'קנה עכשיו';

  @override
  String get item => 'פריט';

  @override
  String get buyer => 'קונה';

  @override
  String get status => 'סטטוס';

  @override
  String get actions => 'פעולות';

  @override
  String get approve => 'אישור';

  @override
  String get decline => 'דחייה';

  @override
  String get markAsShipped => 'סמן כנשלח';

  @override
  String get approved => 'אושר';

  @override
  String get declined => 'נדחה';

  @override
  String get shipped => 'נשלח';

  @override
  String get pending => 'ממתין';

  @override
  String get unknownBuyer => 'Unknown Buyer';

  @override
  String get unknown => 'Unknown';

  @override
  String get myOrders => 'ההזמנות שלי';

  @override
  String get incomingOrders => 'הזמנות נכנסות';

  @override
  String get outgoingOrders => 'הזמנות יוצאות';

  @override
  String get noIncomingOrders => 'אין הזמנות נכנסות';

  @override
  String get noOutgoingOrders => 'אין הזמנות יוצאות';

  @override
  String get seller => 'מוכר';

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
  String get skip => 'דלג';

  @override
  String get addSize => 'Add Size';

  @override
  String get preferencesSaved => 'Preferences saved successfully!';

  @override
  String get jackets => 'Jackets';

  @override
  String get sweaters => 'סוודרים';

  @override
  String get tShirts => 'חולצות';

  @override
  String get pants => 'מכנסיים';

  @override
  String get shoes => 'נעליים';

  @override
  String get profilePage => 'Profile Page';

  @override
  String get userReviews => 'User Reviews';

  @override
  String get review => 'Review';

  @override
  String get noContent => 'No content';

  @override
  String get close => 'סגור';

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

  @override
  String get editItem => 'עריכת פריט';

  @override
  String get itemName => 'Item Name';

  @override
  String get thisFieldIsRequired => 'This field is required';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get category => 'קטגוריה';

  @override
  String get available => 'Available';

  @override
  String get soldOut => 'Sold Out';

  @override
  String get existingImages => 'Existing Images';

  @override
  String get noImagesAvailable => 'No images available';

  @override
  String get mainImage => 'Main Image';

  @override
  String get image => 'Image';

  @override
  String get newImages => 'New Images';

  @override
  String get none => 'None';

  @override
  String get addImages => 'Add Images';

  @override
  String get cancel => 'ביטול';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get anonymous_reviewer => 'Anonymous Reviewer';

  @override
  String get sizePreferencesInfo => 'בחר את המידות שאתה לובש בדרך כלל כדי לקבל המלצות טובות יותר על פריטים שמתאימים לך';

  @override
  String get sizePreferencesDescription => 'בחר את ההעדפות שלך למידות כדי לקבל המלצות טובות יותר';

  @override
  String get unauthorized => 'לא מורשה';

  @override
  String get unauthorizedAccess => 'גישה לא מורשית';

  @override
  String get unauthorizedMessage => 'הגישה שלך לא מורשית. אנא התחבר שוב כדי להמשיך';

  @override
  String get itemProperties => 'מאפייני פריט';

  @override
  String get images => 'תמונות';

  @override
  String get coats => 'מעילים';

  @override
  String get newCondition => 'חדש';

  @override
  String get likeNewCondition => 'כמו חדש';

  @override
  String get goodCondition => 'מצב טוב';

  @override
  String get fairCondition => 'מצב הוגן';

  @override
  String get delivered => 'נמסר';

  @override
  String get analyzingImages => '...מנתח תמונות';

  @override
  String get orderId => 'מספר הזמנה';

  @override
  String get searchHint => 'חפש...';

  @override
  String get priceRange => 'טווח מחירים';

  @override
  String select(String label) {
    return 'בחר $label';
  }

  @override
  String get aiSuggestions => 'הצעות בינה מלאכותית';

  @override
  String get suggestedDescription => 'תיאור מוצע';

  @override
  String get suggestedPrice => 'מחיר מוצע';

  @override
  String get viewAISuggestions => 'צפה בהצעות בינה מלאכותית';

  @override
  String get applySuggestions => 'החל הצעות';

  @override
  String get suggestionsApplied => 'ההצעות הוחלו בהצלחה';
}
