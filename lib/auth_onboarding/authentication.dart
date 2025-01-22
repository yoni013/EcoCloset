import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_closet/bottom_navigation.dart';
import 'package:eco_closet/auth_onboarding/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    debugPrint('AuthGate: build method called');

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('AuthGate: Waiting for auth state...');
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('AuthGate: Error occurred - ${snapshot.error}');
          return const Center(child: Text('Error occurred!'));
        }

        if (!snapshot.hasData) {
          debugPrint('AuthGate: No user logged in, showing SignInScreen');

          return SignInScreen(
            providers: [
              EmailAuthProvider(),
            ],
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) async {
                debugPrint('AuthGate: User signed in with UID: ${state.user?.uid}');

                if (!(state.user?.emailVerified ?? false)) {
                  await state.user?.sendEmailVerification();
                  _showVerificationMessage(context);
                  FirebaseAuth.instance.signOut(); // Log out the user until email is verified
                } else {
                  await _checkAndCreateUser(context, state.user!);
                }
              }),
            ],
          );
        }

        if (snapshot.hasData && !(snapshot.data?.emailVerified ?? false)) {
          debugPrint('AuthGate: Email not verified, signing out...');
          FirebaseAuth.instance.signOut();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showVerificationMessage(context);
          });
          return const Center(child: CircularProgressIndicator());
        }

        debugPrint('AuthGate: User is logged in with UID: ${snapshot.data?.uid}');
        _checkAndCreateUser(context, snapshot.data!);

        return PersistentBottomNavPage();
      },
    );
  }

  Future<void> _checkAndCreateUser(BuildContext context, User user) async {
    if (!user.emailVerified) {
      debugPrint('User email is not verified. Cannot proceed.');
      return;
    }

    final userDocRef =
        FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final docSnapshot = await userDocRef.get();

    if (!docSnapshot.exists) {
      debugPrint('User does not exist, creating new user...');

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

  void _showVerificationMessage(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevent the user from dismissing without action
        builder: (context) => AlertDialog(
          title: const Text('Verify Your Email'),
          content: const Text(
            'A verification email has been sent to your email address. '
            'Please check your inbox and verify your email before logging in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut(); // Ensure they sign out
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }
}

