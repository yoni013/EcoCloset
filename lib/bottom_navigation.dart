import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:eco_closet/pages/homepage.dart';
import 'package:eco_closet/pages/explore_page.dart';
import 'package:eco_closet/pages/my_shop_page.dart';
import 'package:eco_closet/pages/profile_page.dart';
import 'package:eco_closet/pages/upload_page.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;

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
          tab: () => const Homepage(),
          icon: Icons.home,
          title: AppLocalizations.of(context).home,
          navigatorkey: _homeNavigatorKey,
        ),
        PersistentTabItem(
          tab: () => ExplorePage(),
          icon: Icons.search,
          title: AppLocalizations.of(context).explore,
          navigatorkey: _exploreNavigatorKey,
        ),
        PersistentTabItem(
          tab: () => UploadItemPage(),
          icon: Icons.upload,
          title: AppLocalizations.of(context).upload,
          navigatorkey: _uploadNavigatorKey,
        ),
        PersistentTabItem(
          tab: () => const MyOrdersPage(),
          icon: Icons.shopping_cart,
          title: AppLocalizations.of(context).myShop,
          navigatorkey: _shopNavigatorKey,
        ),
        PersistentTabItem(
          tab: () => ProfilePage(
              viewedUserId: FirebaseAuth.instance.currentUser?.uid ?? ''),
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
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: widget.items
            .map((page) => Navigator(
                  key: page.navigatorkey,
                  onGenerateInitialRoutes: (navigator, initialRoute) {
                    return [
                      MaterialPageRoute(builder: (context) => page.tab())
                    ];
                  },
                ))
            .toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedTab,
        onTap: (index) {
          if (_selectedTab == index) {
            // Pop to first route
            widget.items[index].navigatorkey?.currentState?.popUntil((route) => route.isFirst);
            
            // Refresh the current page based on tab index
            final navigatorState = widget.items[index].navigatorkey?.currentState;
            if (navigatorState != null) {
              final context = navigatorState.context;
              
              void visitElements(Element element) {
                // Handle different page types for refresh
                if (index == 0 && element.widget is Homepage) {
                  // Homepage refresh
                  final state = element as StatefulElement;
                  try {
                    (state.state as dynamic).refreshHomepage();
                  } catch (e) {
                    // Ignore if methods don't exist
                  }
                  return;
                } else if (index == 1 && element.widget is ExplorePage) {
                  // Explore page refresh
                  final state = element as StatefulElement;
                  try {
                    (state.state as dynamic).setState(() {});
                  } catch (e) {
                    // Ignore if method doesn't exist
                  }
                  return;
                } else if (index == 2 && element.widget is UploadItemPage) {
                  // Upload page refresh
                  final state = element as StatefulElement;
                  try {
                    (state.state as dynamic).setState(() {});
                  } catch (e) {
                    // Ignore if method doesn't exist
                  }
                  return;
                } else if (index == 3 && element.widget is MyOrdersPage) {
                  // My orders page refresh
                  final state = element as StatefulElement;
                  try {
                    (state.state as dynamic).refreshOrders();
                  } catch (e) {
                    // Ignore if method doesn't exist
                  }
                  return;
                } else if (index == 4 && element.widget is ProfilePage) {
                  // Profile page refresh
                  final state = element as StatefulElement;
                  try {
                    (state.state as dynamic).refreshItems();
                  } catch (e) {
                    // Ignore if method doesn't exist
                  }
                  return;
                }
                element.visitChildElements(visitElements);
              }
              context.visitChildElements(visitElements);
            }
            
            setState(() {});
          } else {
            setState(() {
              _selectedTab = index;
            });
          }
        },
        items: widget.items
            .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon), label: item.title))
            .toList(),
      ),
    );
  }
}

class PersistentTabItem {
  final Widget Function() tab;
  final GlobalKey<NavigatorState>? navigatorkey;
  final String title;
  final IconData icon;

  PersistentTabItem(
      {required this.tab,
      this.navigatorkey,
      required this.title,
      required this.icon});
}
