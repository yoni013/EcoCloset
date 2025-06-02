// ignore: unused_import
import 'package:intl/intl.dart' as intl;
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
  String get errorGeneric => 'An error occurred';

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
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get maxImagesAllowed => 'Maximum 6 images allowed';

  @override
  String get pickImages => 'Pick Images';

  @override
  String get next => 'Next';

  @override
  String get uploadItemStep2 => 'Upload Item - Step 2';

  @override
  String get brand => 'Brand';

  @override
  String get brandRequired => 'Brand is required';

  @override
  String get itemName => 'Item Name';

  @override
  String get itemNameRequired => 'Item name is required';

  @override
  String get color => 'Color';

  @override
  String get colorRequired => 'Color is required';

  @override
  String get condition => 'Condition';

  @override
  String get conditionRequired => 'Condition is required';

  @override
  String get size => 'Size';

  @override
  String get sizeRequired => 'Size is required';

  @override
  String get type => 'Type';

  @override
  String get typeRequired => 'Type is required';

  @override
  String get description => 'Description';

  @override
  String get price => 'Price';

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
  String get uploadItem => 'Upload Item';

  @override
  String get sortByPriceLowToHigh => 'Price (Low to High)';

  @override
  String get sortByPriceHighToLow => 'Price (High to Low)';

  @override
  String get sortByRecommended => 'Recommended';

  @override
  String get sortByNewestFirst => 'Newest First';

  @override
  String get sortByOldestFirst => 'Oldest First';

  @override
  String get forMe => 'For Me';

  @override
  String get search => 'Search...';

  @override
  String get noItemsMatch => 'No items match your search.';

  @override
  String get filter => 'Filter';

  @override
  String get apply => 'Apply';

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
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsAndCondition => 'Terms & Conditions';

  @override
  String get name => 'Name';

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
  String get uploadImages => 'Upload Images (up to 6):';

  @override
  String get analyzeImages => 'Analyze Images with Gemini';

  @override
  String get validPrice => 'Valid price is required';

  @override
  String get itemUploadSuccess => 'Item uploaded successfully!';

  @override
  String get errorUploadingItem => 'Error uploading item';

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
  String get myOrders => 'My Orders';

  @override
  String get incomingOrders => 'Incoming Orders';

  @override
  String get outgoingOrders => 'Outgoing Orders';

  @override
  String get noIncomingOrders => 'No incoming orders found.';

  @override
  String get noOutgoingOrders => 'No outgoing orders found.';

  @override
  String get seller => 'Seller';

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
  String get addSize => 'Add Size';

  @override
  String get preferencesSaved => 'Preferences saved successfully!';

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

  @override
  String get editItem => 'Edit Item';

  @override
  String get thisFieldIsRequired => 'This field is required';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get category => 'Category';

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
  String get cancel => 'Cancel';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get anonymous_reviewer => 'Anonymous Reviewer';

  @override
  String get sizePreferencesInfo => 'Choose the sizes you usually wear to receive better recommendations for items that fit you.';

  @override
  String get sizePreferencesDescription => 'Select your size preferences to get better recommendations.';

  @override
  String get unauthorized => 'Unauthorized';

  @override
  String get unauthorizedAccess => 'Unauthorized Access';

  @override
  String get unauthorizedMessage => 'Your access is unauthorized. Please log in again to continue.';

  @override
  String get itemProperties => 'Item Properties';

  @override
  String get images => 'Images';

  @override
  String get coats => 'Coats';

  @override
  String get newCondition => 'New';

  @override
  String get likeNewCondition => 'Like New';

  @override
  String get goodCondition => 'Good Condition';

  @override
  String get fairCondition => 'Fair Condition';

  @override
  String get delivered => 'Delivered';

  @override
  String get analyzingImages => 'Analyzing Images...';

  @override
  String get orderId => 'Order ID';

  @override
  String get searchHint => 'Search...';

  @override
  String get priceRange => 'Price Range';

  @override
  String select(String label) {
    return 'select $label';
  }

  @override
  String get aiSuggestions => 'AI Suggestions';

  @override
  String get suggestedDescription => 'Suggested Description';

  @override
  String get suggestedPrice => 'Suggested Price';

  @override
  String get viewAISuggestions => 'View AI Suggestions';

  @override
  String get applySuggestions => 'Apply Suggestions';

  @override
  String get suggestionsApplied => 'AI suggestions applied successfully';

  @override
  String get changesSavedSuccessfully => 'Changes saved successfully!';

  @override
  String get errorSavingChanges => 'Error saving changes';

  @override
  String get failedToFetchDropdownData => 'Failed to fetch dropdown data';

  @override
  String get errorProcessingImages => 'Error processing images';

  @override
  String get photo => 'photo';

  @override
  String get photos => 'photos';

  @override
  String get itemNotFound => 'Item not found';

  @override
  String get itemUpdatedSuccessfully => 'Item updated successfully!';

  @override
  String get savingChanges => 'Saving Changes...';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get priceAndAvailability => 'Price & Availability';

  @override
  String get itemIsAvailable => 'Item is currently available for purchase';

  @override
  String get itemIsSoldOut => 'Item is marked as sold out';

  @override
  String get purchaseRequest => 'Purchase Request';

  @override
  String get purchaseRequestSent => 'Purchase request sent! The seller will be notified.';

  @override
  String get cannotPurchaseOwnItem => 'You cannot purchase your own item';

  @override
  String get pleaseLoginToPurchase => 'Please log in to make a purchase';

  @override
  String get errorCreatingPurchaseRequest => 'Error creating purchase request';

  @override
  String get selectAvailableHours => 'Select Available Hours';

  @override
  String get selectPickupTime => 'Select Pickup Time';

  @override
  String get availableTimeSlots => 'Available Time Slots';

  @override
  String get noAvailableTimeSlots => 'No available time slots';

  @override
  String get timeSlotSelected => 'Time slot selected successfully';

  @override
  String get orderAccepted => 'Order Accepted';

  @override
  String get orderDeclined => 'Order Declined';

  @override
  String get acceptOrder => 'Accept Order';

  @override
  String get declineOrder => 'Decline Order';

  @override
  String get reasonForDeclining => 'Reason for declining:';

  @override
  String get declineReasonHint => 'Please explain why you\'re declining this order';

  @override
  String get awaitingSellerResponse => 'Awaiting Seller Response';

  @override
  String get awaitingBuyerTimeSelection => 'Awaiting Buyer Time Selection';

  @override
  String get timeSlotConfirmed => 'Time Slot Confirmed';

  @override
  String get orderCompleted => 'Order Completed';

  @override
  String get orderCancelled => 'Order Cancelled';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get cancelOrderConfirmation => 'Are you sure you want to cancel this order?';

  @override
  String get cancellationReason => 'Cancellation Reason';

  @override
  String get cancellationReasonHint => 'Please explain why you\'re cancelling this order';

  @override
  String get next72Hours => 'Next 72 Hours';

  @override
  String get selectTimeSlots => 'Select Time Slots';

  @override
  String get saveAvailability => 'Save Availability';

  @override
  String get timeSlotUnavailable => 'This time slot is no longer available';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectTime => 'Select Time';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get dayAfterTomorrow => 'Day After Tomorrow';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get pickupAddress => 'Pickup Address';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get buyerInfo => 'Buyer Information';

  @override
  String get sellerInfo => 'Seller Information';

  @override
  String get confirm => 'Confirm';

  @override
  String get tapToView => 'Tap to view';

  @override
  String get newStatus => 'NEW!';

  @override
  String get markAsReadyForPickup => 'Mark as Ready for Pickup';

  @override
  String get acknowledgeTimeSlot => 'Acknowledge Time Slot';

  @override
  String get timeSlotAcknowledged => 'Time slot acknowledged';

  @override
  String get orderMarkedAsReady => 'Order marked as ready for pickup';

  @override
  String get pickupTime => 'Pickup Time';

  @override
  String get refresh => 'Refresh';

  @override
  String get pendingSellerApproval => 'Pending seller approval';

  @override
  String get orderApproved => 'Yay! Your order was approved by the seller, click here to choose your pickup time.';

  @override
  String get sellerNeedsToRespond => 'Please accept or decline this order';

  @override
  String get awaitingTimeSelection => 'Waiting for buyer to select pickup time';

  @override
  String get newPurchaseNotification => 'New purchase request for your item!';

  @override
  String get pendingSeller => 'Pending seller';

  @override
  String get pendingBuyer => 'Pending buyer';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get completed => 'Completed';

  @override
  String get archive => 'Archive';

  @override
  String get archivedItems => 'Archived Items';

  @override
  String get noArchivedItems => 'No archived items found';

  @override
  String get archivedItemsDescription => 'Items that are sold or marked as unavailable';

  @override
  String get archivePosts => 'Archive Posts';

  @override
  String get markAsSold => 'Mark as Sold';

  @override
  String get confirmSale => 'Confirm Sale';

  @override
  String get confirmSaleMessage => 'Have you completed the sale and handed over the item to the buyer?';

  @override
  String get awaitingBuyerConfirmation => 'Awaiting Buyer Confirmation';

  @override
  String get confirmPurchase => 'Confirm Purchase';

  @override
  String get confirmPurchaseMessage => 'Did you receive the item from the seller?';

  @override
  String get writeReview => 'Write a Review';

  @override
  String get reviewOptional => 'Review (Optional)';

  @override
  String get reviewPlaceholder => 'Share your experience with this seller...';

  @override
  String get skipReview => 'Skip Review';

  @override
  String get submitReview => 'Submit Review';

  @override
  String get thankYouForReview => 'Thank you for your review!';

  @override
  String get purchaseConfirmed => 'Purchase confirmed successfully';

  @override
  String get rateYourExperience => 'Rate your experience';

  @override
  String get reviewSubmitted => 'Review submitted successfully';

  @override
  String get sold => 'Sold';

  @override
  String get awaitingBuyerToConfirm => 'Waiting for buyer to confirm receipt';

  @override
  String get confirmReceiptOfItem => 'Please confirm that you received the item';

  @override
  String get sellerMarkedAsSold => 'Seller marked as Sold! Did you receive the item?';

  @override
  String get iReceivedItem => 'I received the item';

  @override
  String get iDidNotReceiveItem => 'I did not receive the item';

  @override
  String get reported => 'Reported';

  @override
  String get issueReported => 'Issue reported successfully';

  @override
  String get tapToConfirmReceipt => 'Tap to confirm receipt or report issue';

  @override
  String get reasonForCancellation => 'Reason for cancellation:';

  @override
  String get noReasonProvided => 'No reason provided';

  @override
  String get enjoyMessage => 'Enjoy :)';

  @override
  String get callBuyer => 'Call Buyer';

  @override
  String get callSeller => 'Call Seller';

  @override
  String get messageBuyer => 'Message Buyer';

  @override
  String get messageSeller => 'Message Seller';

  @override
  String whatsappMessageTemplate(Object brand, Object color, Object itemName, Object size, Object type) {
    return 'Hi! I\'m contacting you regarding the order for: $itemName - $brand $type in $color, size $size.';
  }

  @override
  String get phoneNotAvailable => 'Phone number not available';

  @override
  String get whatsappNotInstalled => 'WhatsApp is not installed on this device';

  @override
  String get cannotOpenDialer => 'Cannot open phone dialer';
}
