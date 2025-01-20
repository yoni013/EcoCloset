/// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/firebase_options.dart';
import 'package:eco_closet/generated/l10n.dart';
import 'package:eco_closet/pages/onboarding_page.dart';
import 'package:eco_closet/utils/firestore_cache_provider.dart';
import 'package:eco_closet/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:eco_closet/pages/homepage.dart';
import 'package:eco_closet/pages/explore_page.dart';
import 'package:eco_closet/pages/my_shop_page.dart';
import 'package:eco_closet/pages/profile_page.dart';
import 'package:eco_closet/pages/upload_page.dart';
import 'package:eco_closet/providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirestoreCacheProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadUserTheme()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
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
        scheme: FlexScheme.espresso,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 15,
        appBarStyle: FlexAppBarStyle.background,
        appBarOpacity: 0.95,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          cardElevation: 1,
          thinBorderWidth: 1.0,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: 'Roboto',
      ).toTheme,
      darkTheme: FlexColorScheme.dark(
        scheme: FlexScheme.espresso,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 20,
        appBarStyle: FlexAppBarStyle.material,
        appBarOpacity: 0.90,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 25,
          cardElevation: 2,
          thinBorderWidth: 1.0,
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
  Locale _locale = Locale('en'); // Default locale

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
    }
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('AuthGate: build method called');

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('AuthGate: Waiting for auth state...');
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('AuthGate: Error occurred - ${snapshot.error}');
          return Center(child: Text('Error occurred!'));
        }

        if (!snapshot.hasData) {
          print('AuthGate: No user logged in, showing SignInScreen');

          return SignInScreen(
            providers: [
              EmailAuthProvider(),
            ],
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) async {
                print('AuthGate: User signed in with UID: ${state.user?.uid}');

                if (!(state.user?.emailVerified ?? false)) {
                  await state.user?.sendEmailVerification();
                  _showVerificationMessage(context);
                  FirebaseAuth.instance
                      .signOut(); // Log out the user until email is verified
                } else {
                  await _checkAndCreateUser(context, state.user!);
                }
              }),
            ],
          );
        }

        if (snapshot.hasData && !(snapshot.data?.emailVerified ?? false)) {
          print('AuthGate: Email not verified, signing out...');
          FirebaseAuth.instance.signOut();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showVerificationMessage(context);
          });
          return Center(child: CircularProgressIndicator());
        }

        print('AuthGate: User is logged in with UID: ${snapshot.data?.uid}');
        _checkAndCreateUser(context, snapshot.data!);

        return PersistentBottomNavPage();
      },
    );
  }

  Future<void> _checkAndCreateUser(BuildContext context, User user) async {
    if (!user.emailVerified) {
      print('User email is not verified. Cannot proceed.');
      return;
    }

    final userDocRef =
        FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final docSnapshot = await userDocRef.get();

    if (!docSnapshot.exists) {
      print('User does not exist, creating new user...');

      await userDocRef.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? 'New User',
        'isNewUser': true,
        'profile_picture': user.photoURL ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'average_rating': 0,
        'seller_reviews': [],
      });

      print('New user created successfully with UID: ${user.uid}');
      _showOnboardingPopup(context, user.uid);
    } else {
      print('User already exists in Firestore: ${user.uid}');
      if (docSnapshot.data()?['isNewUser'] == true) {
        _showOnboardingPopup(context, user.uid);
      }
    }
  }

  void _showOnboardingPopup(BuildContext context, String userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent closing without submission
        builder: (context) => OnboardingForm(userId: userId),
      );
    });
  }

  void _showVerificationMessage(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevent the user from dismissing without action
        builder: (context) => AlertDialog(
          title: Text('Verify Your Email'),
          content: Text(
            'A verification email has been sent to your email address. '
            'Please check your inbox and verify your email before logging in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut(); // Ensure they sign out
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    });
  }
}

class PersistentBottomNavPage extends StatelessWidget {
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  final _exploreNavigatorKey = GlobalKey<NavigatorState>();
  final _profileNavigatorKey = GlobalKey<NavigatorState>();
  final _uploadNavigatorKey = GlobalKey<NavigatorState>();
  final _shopNavigatorKey = GlobalKey<NavigatorState>();

  PersistentBottomNavPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PersistentBottomBarScaffold(
      items: [
        PersistentTabItem(
          tab: Homepage(),
          icon: Icons.home,
          title: AppLocalizations.of(context).home,
          navigatorkey: _homeNavigatorKey,
        ),
        PersistentTabItem(
          tab: ExplorePage(),
          icon: Icons.search,
          title: AppLocalizations.of(context).explore,
          navigatorkey: _exploreNavigatorKey,
        ),
        PersistentTabItem(
          tab: UploadItemPage(),
          icon: Icons.upload,
          title: AppLocalizations.of(context).upload,
          navigatorkey: _uploadNavigatorKey,
        ),
        PersistentTabItem(
          tab: MyShopPage(),
          icon: Icons.shop,
          title: AppLocalizations.of(context).myShop,
          navigatorkey: _shopNavigatorKey,
        ),
        PersistentTabItem(
          tab: ProfilePage(
              viewedUserId: FirebaseAuth.instance.currentUser?.uid ?? ""),
          icon: Icons.person,
          title: AppLocalizations.of(context).profile,
          navigatorkey: _profileNavigatorKey,
        ),
      ],
    );
  }
}

class PersistentBottomBarScaffold extends StatefulWidget {
  final List<PersistentTabItem> items;

  const PersistentBottomBarScaffold({Key? key, required this.items})
      : super(key: key);

  @override
  State<PersistentBottomBarScaffold> createState() =>
      _PersistentBottomBarScaffoldState();
}

class _PersistentBottomBarScaffoldState
    extends State<PersistentBottomBarScaffold> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (shouldPop, result) {
        if (shouldPop &&
            (widget.items[_selectedTab].navigatorkey?.currentState?.canPop() ??
                false)) {
          widget.items[_selectedTab].navigatorkey?.currentState?.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedTab,
          children: widget.items
              .map((page) => Navigator(
                    key: page.navigatorkey,
                    onGenerateInitialRoutes: (navigator, initialRoute) {
                      return [
                        MaterialPageRoute(builder: (context) => page.tab)
                      ];
                    },
                  ))
              .toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          items: widget.items
              .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon), label: item.title))
              .toList(),
        ),
      ),
    );
  }
}

class PersistentTabItem {
  final Widget tab;
  final GlobalKey<NavigatorState>? navigatorkey;
  final String title;
  final IconData icon;

  PersistentTabItem(
      {required this.tab,
      this.navigatorkey,
      required this.title,
      required this.icon});
}
