import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/bottom_navigation.dart';
import 'package:eco_closet/auth_onboarding/onboarding_main.dart';
import 'package:eco_closet/auth_onboarding/phone_auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    debugPrint('AuthGate: build method called');

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Handle connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('AuthGate: Waiting for auth state...');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          debugPrint('AuthGate: Error occurred - ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error occurred!'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry by rebuilding the widget
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle no user
        if (!snapshot.hasData) {
          debugPrint('AuthGate: No user logged in, showing PhoneAuthScreen');
          return PhoneAuthScreen(
            onSignedIn: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                debugPrint('AuthGate: User signed in with UID: ${user.uid}');
                await _checkAndCreateUser(context, user);
              }
            },
          );
        }

        // Handle authenticated user - phone numbers are automatically verified
        debugPrint('AuthGate: User is logged in with UID: ${snapshot.data?.uid}');
        _checkAndCreateUser(context, snapshot.data!);

        return PersistentBottomNavPage();
      },
    );
  }

  Future<void> _checkAndCreateUser(BuildContext context, User user) async {
    final userDocRef =
        FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final docSnapshot = await userDocRef.get();

    if (!docSnapshot.exists) {
      debugPrint('User does not exist, creating new user...');

      // Create user data based on authentication method
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'isNewUser': true,
        'created_at': FieldValue.serverTimestamp(),
        'average_rating': 0,
        'seller_reviews': [],
      };

      // Add phone number if available (phone auth)
      if (user.phoneNumber != null) {
        userData['phoneNumber'] = user.phoneNumber;
      }

      // Add email if available (email auth)
      if (user.email != null) {
        userData['email'] = user.email;
      }

      // Add display name if available
      if (user.displayName != null) {
        userData['name'] = user.displayName;
      }

      await userDocRef.set(userData);

      debugPrint('New user created successfully with UID: ${user.uid}');
      _showOnboardingPopup(context, user.uid);
    } else {
      debugPrint('User already exists in Firestore: ${user.uid}');
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
        builder: (context) => OnboardingFlow(),
      );
    });
  }


}

