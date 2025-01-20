import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'ארון יד שנייה';

  @override
  String get welcomeMessage => 'ברוך הבא לארון יד שנייה!';

  @override
  String get home => 'בית';

  @override
  String get explore => 'חיפוש';

  @override
  String get upload => 'העלאה';

  @override
  String get myShop => 'החנות שלי';

  @override
  String get profile => 'פרופיל';

  @override
  String get verifyEmailTitle => 'אימות דואר אלקטרוני';

  @override
  String get verifyEmailMessage => 'דואר אלקטרוני לאימות נשלח לכתובת הדואר שלך. אנא בדוק את הדואר האלקטרוני שלך ואמת את החשבון לפני שתתחבר.';

  @override
  String get ok => 'אישור';

  @override
  String get signInScreenTitle => 'התחברות';

  @override
  String get errorOccurred => 'אירעה שגיאה!';

  @override
  String get signOut => 'התנתקות';

  @override
  String get waitingForAuth => 'ממתין לאימות...';

  @override
  String get persistentNavHome => 'בית';

  @override
  String get persistentNavExplore => 'חיפוש';

  @override
  String get persistentNavUpload => 'העלאה';

  @override
  String get persistentNavMyShop => 'החנות שלי';

  @override
  String get persistentNavProfile => 'פרופיל';

  @override
  String get newUser => 'משתמש חדש';

  @override
  String get loading => 'טוען...';

  @override
  String get email => 'אימייל';

  @override
  String get password => 'סיסמה';

  @override
  String get signIn => 'התחברות';

  @override
  String get signUp => 'הרשמה';

  @override
  String get forgotPassword => 'שכחת סיסמה?';

  @override
  String get submit => 'שלח';

  @override
  String get address => 'כתובת';

  @override
  String get phoneNumber => 'מספר טלפון';

  @override
  String get themeLight => 'תצוגה בהירה';

  @override
  String get themeDark => 'תצוגה כהה';

  @override
  String get changeLanguage => 'שנה שפה';

  @override
  String get settings => 'הגדרות';

  @override
  String get logoutMessage => 'האם אתה בטוח שברצונך להתנתק?';

  @override
  String get logout => 'התנתק';

  @override
  String get recommendedForYou => 'מומלצים בישבילך';

  @override
  String get trendingNow => 'טרנדי עכשיו';

  @override
  String get general => 'כללי';

  @override
  String get darkMode => 'מצב כהה';

  @override
  String get notifications => 'התראות';

  @override
  String get language => 'שפה';

  @override
  String get account => 'חשבון';

  @override
  String get profileSettings => 'הגדרות פרופיל';

  @override
  String get privacySettings => 'הגדרות פרטיות';

  @override
  String get changePassword => 'שנה סיסמא';

  @override
  String get support => 'תמיכה';

  @override
  String get helpFeedback => 'עזרה ומשוב';

  @override
  String get about => 'אודות';

  @override
  String get confirmSignOutMessage => 'האם אתה בטוח שברצונך להתנתק?';

  @override
  String get no => 'לא';

  @override
  String get yes => 'כן';

  @override
  String get uploadItemStep1 => 'העלאת פריט - שלב 1';

  @override
  String get uploadItemStep2 => 'העלאת פריט - שלב 2';

  @override
  String get uploadImages => 'העלה תמונות (עד 6):';

  @override
  String get pickImages => 'בחר תמונות';

  @override
  String get analyzeImages => 'נתח תמונות עם Gemini';

  @override
  String get brand => 'מותג';

  @override
  String get color => 'צבע';

  @override
  String get condition => 'מצב';

  @override
  String get size => 'מידה';

  @override
  String get type => 'סוג';

  @override
  String get description => 'תיאור';

  @override
  String get price => 'מחיר';

  @override
  String get validPrice => 'נדרש מחיר תקף';

  @override
  String get itemUploadSuccess => 'הפריט הועלה בהצלחה!';

  @override
  String errorUploadingItem(Object error) {
    return 'שגיאה בהעלאת הפריט: $error';
  }

  @override
  String get colorRequired => 'חובה להכניס צבע';

  @override
  String get typeRequired => 'סוג מוצר is required';

  @override
  String get sizeRequired => 'חובה להכניס מידה';

  @override
  String get conditionRequired => 'חובה להכניס מצב';

  @override
  String get brandRequired => 'חובה להכניס מותג';

  @override
  String get itemDetails => 'פרטי פריט';

  @override
  String get failedToLoadItem => 'טעינת הפריט נכשלה';

  @override
  String get unknownItem => 'פריט לא ידוע';

  @override
  String get notAvailable => 'לא זמין';

  @override
  String get noDescription => 'לא סופק תיאור.';

  @override
  String get loadingSeller => 'טוען מידע על המוכר...';

  @override
  String get unknownSeller => 'מוכר לא ידוע';

  @override
  String get reviews => 'ביקורות';

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
  String get approve => 'אשר';

  @override
  String get decline => 'דחה';

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
  String get unknownBuyer => 'קונה לא ידוע';

  @override
  String get unknown => 'לא ידוע';

  @override
  String get errorFetchingOrders => 'שגיאה בשליפת הזמנות: ';

  @override
  String get errorUpdatingStatus => 'שגיאה בעדכון הסטטוס: ';

  @override
  String get errorFetchingBuyer => 'שגיאה בשליפת שם הקונה: ';

  @override
  String get errorFetchingImage => 'שגיאה בשליפת תמונת הפריט: ';

  @override
  String get onboardingTitle => 'קבל המלצות טובות יותר על ידי עדכון הפרופיל שלך!';

  @override
  String get defaultUser => 'משתמש';

  @override
  String get errorFetchingUserData => 'שגיאה בשליפת נתוני המשתמש: ';

  @override
  String get profileSubmitted => 'הפרופיל נשלח בהצלחה.';

  @override
  String get age => 'גיל';

  @override
  String get preferredShirtSize => 'גודל חולצה מועדף';

  @override
  String get pantsSize => 'גודל מכנסיים';

  @override
  String get shoeSize => 'גודל נעליים';

  @override
  String get preferredBrands => 'מותגים מועדפים';

  @override
  String get skip => 'דלג';

  @override
  String get sizePreferences => 'העדפות מידות';

  @override
  String get addSize => 'הוסף מידה';

  @override
  String get preferencesSaved => 'העדפות נשמרו בהצלחה!';

  @override
  String get savePreferences => 'שמור העדפות';

  @override
  String get jackets => 'מעילים';

  @override
  String get sweaters => 'סוודרים';

  @override
  String get tShirts => 'חולצות';

  @override
  String get pants => 'מכנסיים';

  @override
  String get shoes => 'נעליים';

  @override
  String get profilePage => 'דף פרופיל';

  @override
  String get userReviews => 'ביקורות משתמשים';

  @override
  String get review => 'ביקורת';

  @override
  String get noContent => 'אין תוכן';

  @override
  String get close => 'סגור';

  @override
  String get failedToLoadUser => 'טעינת נתוני המשתמש נכשלה';

  @override
  String get unknownUser => 'משתמש לא ידוע';

  @override
  String get searchItems => 'חפש פריטים';

  @override
  String get errorLoadingData => 'שגיאה בטעינת הנתונים';

  @override
  String get unknownBrand => 'מותג לא ידוע';
}
