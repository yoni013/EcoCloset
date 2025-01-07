import 'package:eco_closet/pages/upload_page.dart';
import 'package:flutter/material.dart';
import 'package:eco_closet/pages/homepage.dart';
import 'package:eco_closet/pages/explore_page.dart';
import 'package:eco_closet/pages/item_page.dart';
import 'package:eco_closet/pages/profile_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
            initialRoute: '/',
      routes: {
        '/': (context) => AuthGate(),
        '/explore': (context) => ExplorePage(),
        '/item': (context) => ItemPage(itemId: 'exampleId'), // Replace exampleId with a real ID dynamically
        '/profile': (context) => ProfilePage(viewedUserId: FirebaseAuth.instance.currentUser?.uid ?? ''),
        '/upload': (context) => UploadItemPage(),
      },
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

        return HomePage();
      },
    );
  }
}