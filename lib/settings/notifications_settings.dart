import 'package:eco_closet/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _enablePushNotifications = false;
  bool _enableEmailNotifications = false;
  bool _enableSmsNotifications = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  /// Fetches the current notification settings from Firestore.
  Future<void> _loadNotificationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle the case when no user is logged in.
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final docRef =
          FirebaseFirestore.instance.collection('Users').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        setState(() {
          _enablePushNotifications = data?['enablePushNotifications'] ?? false;
          _enableEmailNotifications = data?['enableEmailNotifications'] ?? false;
          _enableSmsNotifications = data?['enableSmsNotifications'] ?? false;
          _isLoading = false;
        });
      } else {
        // If the document does not exist, initialize with default values.
        await docRef.set({
          'enablePushNotifications': false,
          'enableEmailNotifications': false,
          'enableSmsNotifications': false,
        });
        setState(() {
          _enablePushNotifications = false;
          _enableEmailNotifications = false;
          _enableSmsNotifications = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Optionally, handle errors here (e.g., show an error message)
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Updates a single setting in Firestore immediately.
  Future<void> _updateSetting(String field, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('Users').doc(user.uid);
      await docRef.update({field: value});
    } catch (e) {
      // Optionally, you can handle errors here (e.g., revert the switch value or show a snackbar)
      debugPrint('Error updating $field: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).notificationSettings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(AppLocalizations.of(context).enablePushNotifications),
                  value: _enablePushNotifications,
                  onChanged: (bool newValue) {
                    setState(() {
                      _enablePushNotifications = newValue;
                    });
                    _updateSetting('enablePushNotifications', newValue);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context).enableEmailNotifications),
                  value: _enableEmailNotifications,
                  onChanged: (bool newValue) {
                    setState(() {
                      _enableEmailNotifications = newValue;
                    });
                    _updateSetting('enableEmailNotifications', newValue);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context).enableSmsNotifications),
                  value: _enableSmsNotifications,
                  onChanged: (bool newValue) {
                    setState(() {
                      _enableSmsNotifications = newValue;
                    });
                    _updateSetting('enableSmsNotifications', newValue);
                  },
                ),
              ],
            ),
    );
  }
}
