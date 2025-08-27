/// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beged/auth_onboarding/authentication.dart';
import 'package:beged/firebase_options.dart';
import 'package:beged/generated/l10n.dart';
import 'package:beged/utils/fetch_item_metadata.dart';
import 'package:beged/utils/firestore_cache_provider.dart';
import 'package:beged/services/order_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:beged/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with persistence enabled
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable offline persistence for Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Load metadata with error handling
  try {
    await Utils.loadMetadata();
    debugPrint('✅ Metadata loaded successfully:');
    debugPrint('Brands: ${Utils.brands.length}');
    debugPrint('Sizes: ${Utils.sizes.length}');
    debugPrint('Conditions: ${Utils.conditions.length}');
  } catch (e) {
    debugPrint('❌ Error loading metadata: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirestoreCacheProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadUserTheme()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => OrderNotificationService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      locale: localeProvider.locale, // Default language
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: 'BeGeD',
      theme: FlexColorScheme.light(
        scheme: FlexScheme.aquaBlue,
        useMaterial3: true,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 8,
        appBarStyle: FlexAppBarStyle.material,
        appBarOpacity: 0.95,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 12,
          defaultRadius: 16,
          thickBorderWidth: 1.0,
          thinBorderWidth: 0.5,
          elevatedButtonSchemeColor: SchemeColor.primary,
          elevatedButtonSecondarySchemeColor: SchemeColor.onPrimary,
          outlinedButtonOutlineSchemeColor: SchemeColor.primary,
          toggleButtonsSchemeColor: SchemeColor.primary,
          segmentedButtonSchemeColor: SchemeColor.primary,
          bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarSelectedIconSchemeColor: SchemeColor.primary,
          navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
          navigationRailSelectedIconSchemeColor: SchemeColor.primary,
          inputDecoratorSchemeColor: SchemeColor.secondary,
          cardElevation: 1,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: 'Roboto',
      ).toTheme,
      darkTheme: FlexColorScheme.dark(
        scheme: FlexScheme.aquaBlue,
        useMaterial3: true,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 20, // Increased for darker backgrounds
        appBarStyle: FlexAppBarStyle.material,
        appBarOpacity: 0.90,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 25, // Increased for better contrast
          defaultRadius: 16,
          thickBorderWidth: 1.0,
          thinBorderWidth: 0.5,
          elevatedButtonSchemeColor: SchemeColor.primary,
          elevatedButtonSecondarySchemeColor: SchemeColor.onPrimary,
          outlinedButtonOutlineSchemeColor: SchemeColor.primary,
          toggleButtonsSchemeColor: SchemeColor.primary,
          segmentedButtonSchemeColor: SchemeColor.primary,
          bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarSelectedIconSchemeColor: SchemeColor.primary,
          navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
          navigationRailSelectedIconSchemeColor: SchemeColor.primary,
          inputDecoratorSchemeColor: SchemeColor.secondary,
          cardElevation: 1,
          // Fix floating label behavior
          inputDecoratorIsFilled: true,
          inputDecoratorFillColor: Colors.black12, // Darker background for text fields
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorRadius: 12,
          inputDecoratorUnfocusedHasBorder: true,
          inputDecoratorFocusedHasBorder: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: 'Roboto',
      ).toTheme.copyWith(
        // Additional customizations to disable floating labels
        inputDecorationTheme: FlexColorScheme.dark(
          scheme: FlexScheme.aquaBlue,
          useMaterial3: true,
          subThemesData: const FlexSubThemesData(
            inputDecoratorIsFilled: true,
            inputDecoratorFillColor: Colors.black12,
            inputDecoratorBorderType: FlexInputBorderType.outline,
            inputDecoratorRadius: 12,
          ),
        ).toTheme.inputDecorationTheme.copyWith(
          floatingLabelBehavior: FloatingLabelBehavior.never, // Disable floating labels
          fillColor: Colors.black26, // Even darker fill for better contrast
          filled: true,
        ),
      ),
      themeMode: context.watch<ThemeProvider>().themeMode,
      home: AuthGate(),
    );
  }
}

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isLoaded = false;

  Locale get locale => _locale;

  Future<void> _loadLocale() async {
    if (_isLoaded) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['locale'] != null) {
        _locale = Locale(doc.data()?['locale']);
      }
    } catch (e) {
      debugPrint('Error fetching locale: $e');
    } finally {
      _isLoaded = true;
    }
  }

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .update({'locale': newLocale.languageCode}).catchError((e) {
          debugPrint('Error updating locale: $e');
        });
      }
      notifyListeners();
    }
  }

  LocaleProvider() {
    _loadLocale();
  }
}
