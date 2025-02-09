import 'package:eco_closet/auth_onboarding/authentication.dart';
import 'package:eco_closet/settings/change_password.dart';
import 'package:eco_closet/settings/notifications_settings.dart';
import 'package:eco_closet/settings/profile_settings_page.dart';
import 'package:eco_closet/generated/l10n.dart';
import 'package:eco_closet/main.dart';
import 'package:eco_closet/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

    Future<void> _showPrivacyDialog(BuildContext context) async {
    final privacyText = await rootBundle.loadString('assets/privacy_policy.txt');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(child: Text(privacyText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTermsDialog(BuildContext context) async {
    final termsText = await rootBundle.loadString('assets/terms_and_conditions.txt');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: SingleChildScrollView(child: Text(termsText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            children: [
              _SingleSection(
                title: AppLocalizations.of(context).general,
                children: [
                  _CustomListTile(
                    title: AppLocalizations.of(context).darkMode,
                    icon: Icons.dark_mode_outlined,
                    trailing: Switch(
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (value) {
                        context.read<ThemeProvider>().updateUserTheme(value);
                      },
                    ),
                  ),
                  _CustomListTile(
                    title: AppLocalizations.of(context).notifications,
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
                      );
                    },
                  ),
                  _CustomListTile(
                    title: AppLocalizations.of(context).language,
                    icon: Icons.language_outlined,
                    trailing: DropdownButton<Locale>(
                      value: (localeProvider.locale.languageCode == 'he' || localeProvider.locale.languageCode == 'en') 
                              ? localeProvider.locale 
                              : const Locale('en'),
                      onChanged: (Locale? newLocale) {
                        if (newLocale != null) {
                          localeProvider.setLocale(newLocale);
                        }
                      },
                      items: AppLocalizations.supportedLocales
                          .map((Locale locale) {
                        return DropdownMenuItem(
                          value: locale,
                          child: Text(
                            locale.languageCode == 'en'
                                ? 'English'
                                : 'עברית', // Add more if needed
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const Divider(),
              _SingleSection(
                title: AppLocalizations.of(context).account,
                children: [
                  _CustomListTile(
                    title: AppLocalizations.of(context).profileSettings,
                    icon: Icons.person_outline_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
                      );
                    },
                  ),
                  // Privacy Button
                  _CustomListTile(
                    title: AppLocalizations.of(context).privacyPolicy,
                    icon: Icons.privacy_tip_outlined,
                    onTap: () => _showPrivacyDialog(context),
                  ),
                  // Terms & Conditions Button
                  _CustomListTile(
                    title: AppLocalizations.of(context).termsAndCondition,
                    icon: Icons.policy_outlined,
                    onTap: () => _showTermsDialog(context),
                  ),
                  _CustomListTile(
                    title: AppLocalizations.of(context).changePassword,
                    icon: Icons.lock_reset,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                      );
                    },
                  ),
                ],
              ),
              const Divider(),
              _SingleSection(
                title: AppLocalizations.of(context).support,
                children: [
                  _CustomListTile(
                    title: AppLocalizations.of(context).helpFeedback,
                    icon: Icons.help_outline_rounded,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context).helpFeedback),
                            content: const Text('Feel free to contact us using one of the emails: ariel4216@gmail.com, yoni013@gmail.com'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(AppLocalizations.of(context).ok),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  _CustomListTile(
                    title: AppLocalizations.of(context).about,
                    icon: Icons.info_outline_rounded,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context).about),
                            content: const Text('Ariel Porath and Yonathan Eliav, just two regular guys trying to make the world a better place.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(AppLocalizations.of(context).ok),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  _CustomListTile(
                    title: AppLocalizations.of(context).signOut,
                    icon: Icons.exit_to_app_rounded,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context).signOut),
                            content: Text(AppLocalizations.of(context)
                                .confirmSignOutMessage),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(AppLocalizations.of(context).no),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) => AuthGate()),
                                    (route) => false,
                                  );
                                },
                                child: Text(AppLocalizations.of(context).yes),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _CustomListTile({
    Key? key,
    required this.title,
    required this.icon,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SingleSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SingleSection({
    Key? key,
    this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ),
        Column(
          children: children,
        ),
      ],
    );
  }
}
