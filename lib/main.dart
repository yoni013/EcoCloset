/// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/firebase_options.dart';
import 'package:eco_closet/pages/onboarding_page.dart';
import 'package:eco_closet/utils/firestore_cache_provider.dart';
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
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
              PhoneAuthProvider(),
            ],
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) async {
                print('AuthGate: User signed in with UID: ${state.user?.uid}');
                await _handleUserVerification(context, state.user!);
              }),
            ],
          );
        }

        print('AuthGate: User is logged in with UID: ${snapshot.data?.uid}');
        _checkAndCreateUser(context, snapshot.data!);

        return PersistentBottomNavPage();
      },
    );
  }

  Future<void> _handleUserVerification(BuildContext context, User user) async {
    final providers = user.providerData.map((p) => p.providerId).toList();

    if (providers.contains('phone')) {
      // User signed in with phone, send SMS verification
      print('AuthGate: User signed in with phone number');
      await _checkAndCreateUser(context, user);
    } else if (providers.contains('password') && !(user.emailVerified)) {
      // User signed in with email but not verified
      await user.sendEmailVerification();
      _showVerificationMessage(context, 'email');
      FirebaseAuth.instance.signOut();
    } else if (providers.contains('phone') && providers.contains('password')) {
      // Both phone and email used for sign-in
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        _showVerificationMessage(context, 'both');
      }
      await _checkAndCreateUser(context, user);
    } else {
      await _checkAndCreateUser(context, user);
    }
  }

  Future<void> _checkAndCreateUser(BuildContext context, User user) async {
    final userDocRef =
        FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final docSnapshot = await userDocRef.get();

    if (!docSnapshot.exists) {
      print('User does not exist, creating new user...');

      await userDocRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
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
        barrierDismissible: false,
        builder: (context) => OnboardingForm(userId: userId),
      );
    });
  }

  void _showVerificationMessage(BuildContext context, String method) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String message;
      if (method == 'email') {
        message =
            'A verification email has been sent. Please check your inbox.';
      } else if (method == 'phone') {
        message = 'A verification code has been sent to your phone number.';
      } else {
        message =
            'Verification emails and SMS have been sent. Please check your inbox and phone.';
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Verify Your Account'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut();
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
          title: 'Home',
          navigatorkey: _homeNavigatorKey,
        ),
        PersistentTabItem(
          tab: ExplorePage(),
          icon: Icons.search,
          title: 'Explore',
          navigatorkey: _exploreNavigatorKey,
        ),
        PersistentTabItem(
          tab: UploadItemPage(),
          icon: Icons.upload,
          title: 'Upload',
          navigatorkey: _uploadNavigatorKey,
        ),
        PersistentTabItem(
          tab: MyShopPage(),
          icon: Icons.shop,
          title: 'My Shop',
          navigatorkey: _shopNavigatorKey,
        ),
        PersistentTabItem(
          tab: ProfilePage(
              viewedUserId: FirebaseAuth.instance.currentUser?.uid ?? ""),
          icon: Icons.person,
          title: 'Profile',
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
