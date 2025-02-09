import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eco_closet/generated/l10n.dart';


class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Re-authenticate the user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: AppLocalizations.of(context).errorNoCurrentUser,
        );
      }
      
      // (Assuming the user signed up with email/password)
      // If using a different provider (e.g. Google), reauthentication will differ.
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      try {
        // Attempt re-authentication
        await user.reauthenticateWithCredential(cred);
        } on FirebaseAuthException catch (e) {
        // Handle wrong password, etc.
        if (e.code == 'ERROR_INVALID_CREDENTIAL') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).errorInvalidCredential)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? AppLocalizations.of(context).errorReauthentication)),
          );
        }
        return; // Stop execution if re-auth fails
      }
      // 2. Update the password
      await user.updatePassword(newPassword);

      // Optionally sign out the user, forcing them to sign in again.
      // This can be a good security practice in some apps.
      // await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).passwordChangedSuccess)),
      );

      // 3. Go back to the previous screen
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      // Show error to user
      String message = 'An error occurred.';
      if (e.code == 'wrong-password') {
        message = AppLocalizations.of(context).errorWrongPassword;
      } else if (e.code == 'weak-password') {
        message = AppLocalizations.of(context).errorWeakPassword;
      } else if (e.code == 'no-current-user') {
        message = e.message!;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      // Some other error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorSomethingWentWrong)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).update),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Current Password
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).currentPassword,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context).currentPasswordPlaceholder;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // New Password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).newPassword,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context).newPasswordPlaceholder;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm New Password
                TextFormField(
                  controller: _confirmNewPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).confirmNewPassword,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value != _newPasswordController.text) {
                      return AppLocalizations.of(context).confirmNewPasswordPlaceholder;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(AppLocalizations.of(context).changePassword),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
