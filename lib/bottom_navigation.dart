import 'package:beged/generated/l10n.dart';
import 'package:beged/services/order_notification_service.dart';
import 'package:beged/widgets/notification_badge.dart';
import 'package:flutter/material.dart';
import 'package:beged/pages/homepage.dart';
import 'package:beged/pages/tag_based_explore_page.dart';
import 'package:beged/pages/my_shop_page.dart';
import 'package:beged/pages/profile_page.dart';
import 'package:beged/pages/upload_page.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:provider/provider.dart';

/// Minimal controller to allow programmatic tab switching and cross-tab navigation
class BottomNavController {
  // Access to the scaffold/state to switch tabs and access tab navigators
  static final GlobalKey<_PersistentBottomBarScaffoldState> scaffoldKey =
      GlobalKey<_PersistentBottomBarScaffoldState>();

  static void switchToTab(int index) {
    scaffoldKey.currentState?.switchToTab(index);
  }

  static NavigatorState? homeNavigator() {
    final state = scaffoldKey.currentState;
    if (state == null) return null;
    return state.widget.items[0].navigatorkey?.currentState;
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
      key: BottomNavController.scaffoldKey,
      items: [
        PersistentTabItem(
          tab: () => const Homepage(),
          icon: Icons.home,
          title: AppLocalizations.of(context).home,
          navigatorkey: _homeNavigatorKey,
        ),
        PersistentTabItem(
          tab: () => TagBasedExplorePage(),
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
  void initState() {
    super.initState();
    
    // Initialize the notification service once when the scaffold is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final orderService = Provider.of<OrderNotificationService>(context, listen: false);
        orderService.startListening();
        debugPrint('PersistentBottomBarScaffold: OrderNotificationService initialized');
      } catch (e) {
        debugPrint('Error initializing OrderNotificationService: $e');
      }
    });
  }

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
      bottomNavigationBar: Consumer<OrderNotificationService>(
        builder: (context, orderService, child) {
          // Just listen for notification count changes - initialization happens in initState
          
          return BottomNavigationBar(
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
                      if (element is StatefulElement) {
                        try {
                          (element.state as dynamic).refreshHomepage();
                        } catch (e) {
                          // Ignore if methods don't exist
                        }
                      }
                      return;
                    } else if (index == 1 && element.widget is TagBasedExplorePage) {
                      // Explore page is StatelessWidget, no refresh needed
                      return;
                    } else if (index == 2 && element.widget is UploadItemPage) {
                      // Upload page refresh
                      if (element is StatefulElement) {
                        try {
                          (element.state as dynamic).setState(() {});
                        } catch (e) {
                          // Ignore if method doesn't exist
                        }
                      }
                      return;
                    } else if (index == 3 && element.widget is MyOrdersPage) {
                      // My orders page refresh
                      if (element is StatefulElement) {
                        try {
                          (element.state as dynamic).refreshOrders();
                        } catch (e) {
                          // Ignore if method doesn't exist
                        }
                      }
                      return;
                    } else if (index == 4 && element.widget is ProfilePage) {
                      // Profile page refresh
                      if (element is StatefulElement) {
                        try {
                          (element.state as dynamic).refreshItems();
                        } catch (e) {
                          // Ignore if method doesn't exist
                        }
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
            items: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              
              // Add notification badge to My Shop tab (index 3)
              Widget iconWidget = Icon(item.icon);
              if (index == 3) {
                iconWidget = NotificationBadge(
                  count: orderService.pendingOrdersCount,
                  child: Icon(item.icon),
                );
              }
              
              return BottomNavigationBarItem(
                icon: iconWidget,
                label: item.title,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // Programmatically switch tabs
  void switchToTab(int index) {
    if (!mounted) return;
    setState(() {
      _selectedTab = index;
    });
    // Ensure the target tab is popped to its root when switching
    widget.items[index].navigatorkey?.currentState
        ?.popUntil((route) => route.isFirst);
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
