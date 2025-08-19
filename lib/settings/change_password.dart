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
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorNoCurrentUser)),
      );
      return;
    }

    // Check if user authenticated with phone
    bool isPhoneUser = user.providerData.any((info) => info.providerId == 'phone');
    
    if (isPhoneUser) {
      // Show message that password change is not available for phone auth users
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changes are not available for phone authentication users.'),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    // Original password change logic would go here for email users
    // For now, show that this feature is disabled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password changes are currently disabled. Please contact support if needed.'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
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
      ),
    );
  }
}
