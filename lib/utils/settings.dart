import 'package:eco_closet/auth_onboarding/authentication.dart';
import 'package:eco_closet/generated/l10n.dart';
import 'package:eco_closet/main.dart';
import 'package:eco_closet/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
                  ),
                  _CustomListTile(
                    title: AppLocalizations.of(context).language,
                    icon: Icons.language_outlined,
                    trailing: DropdownButton<Locale>(
                      value: localeProvider.locale,
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
                  ),
                  _CustomListTile(
                    title: AppLocalizations.of(context).privacySettings,
                    icon: Icons.privacy_tip_outlined,
                  ),
                  _CustomListTile(
                    title: AppLocalizations.of(context).changePassword,
                    icon: Icons.lock_reset,
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
                  ),
                  _CustomListTile(
                    title: AppLocalizations.of(context).about,
                    icon: Icons.info_outline_rounded,
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
