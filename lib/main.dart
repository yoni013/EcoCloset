/// main.dart
import 'package:eco_closet/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:eco_closet/pages/homepage.dart';
import 'package:eco_closet/pages/explore_page.dart';
import 'package:eco_closet/pages/my_shop_page.dart';
import 'package:eco_closet/pages/profile_page.dart';
import 'package:eco_closet/pages/upload_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
            ],
          );
        }
        return PersistentBottomNavPage();
      },
    );
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
          tab: HomePage(),
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
          tab: ProfilePage(viewedUserId: FirebaseAuth.instance.currentUser?.uid ?? ""),
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

  const PersistentBottomBarScaffold({Key? key, required this.items}) : super(key: key);

  @override
  State<PersistentBottomBarScaffold> createState() => _PersistentBottomBarScaffoldState();
}

class _PersistentBottomBarScaffoldState extends State<PersistentBottomBarScaffold> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (shouldPop, result) {
        if (shouldPop &&
            (widget.items[_selectedTab].navigatorkey?.currentState?.canPop() ?? false)) {
          widget.items[_selectedTab].navigatorkey?.currentState?.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedTab,
          children: widget.items.map((page) => Navigator(
                key: page.navigatorkey,
                onGenerateInitialRoutes: (navigator, initialRoute) {
                  return [MaterialPageRoute(builder: (context) => page.tab)];
                },
              )).toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          items: widget.items.map((item) => BottomNavigationBarItem(
              icon: Icon(item.icon), label: item.title)).toList(),
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

  PersistentTabItem({required this.tab, this.navigatorkey, required this.title, required this.icon});
}
