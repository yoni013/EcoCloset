/// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/auth_onboarding/authentication.dart';
import 'package:eco_closet/firebase_options.dart';
import 'package:eco_closet/generated/l10n.dart';
import 'package:eco_closet/utils/fetch_item_metadata.dart';
import 'package:eco_closet/utils/firestore_cache_provider.dart';
import 'package:eco_closet/services/order_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eco_closet/providers/theme_provider.dart';
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
      title: 'Eco Closet',
      theme: FlexColorScheme.light(
        scheme: FlexScheme.aquaBlue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        appBarStyle: FlexAppBarStyle.background,
        appBarOpacity: 0.95,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          cardElevation: 0.5,
          thinBorderWidth: 0.5,
          defaultRadius: 12,
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
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: 'Roboto',
      ).toTheme,
      darkTheme: FlexColorScheme.dark(
        scheme: FlexScheme.aquaBlue,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 13,
        appBarStyle: FlexAppBarStyle.background,
        appBarOpacity: 0.90,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 15,
          cardElevation: 1,
          thinBorderWidth: 0.5,
          defaultRadius: 12,
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
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: 'Roboto',
      ).toTheme,
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
