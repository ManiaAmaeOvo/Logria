import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_metadata.dart';
import '../../../core/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import 'user_manual_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.database,
    required this.locale,
    required this.onLocaleChanged,
  });
  final AppDatabase database;
  final Locale? locale;
  final ValueChanged<Locale?> onLocaleChanged;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Locale? _locale = widget.locale;
  bool _saving = false;
  Future<void> _selectLocale(Locale? locale) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.database
          .into(widget.database.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              keyName: 'app.locale',
              value: locale?.languageCode ?? 'system',
              updatedAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      widget.onLocaleChanged(locale);
      setState(() => _locale = locale);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.saveFailed('$error')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _open(String url) async {
    try {
      if (await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      /* Provide clipboard fallback if no browser is installed. */
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.linkCopiedFallback),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/branding/logria-icon.png',
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Logria',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              'v${AppMetadata.version} (${AppMetadata.build})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.appTagline,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l.appIntroduction),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l.userManual),
              subtitle: Text(l.userManualHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManualPage()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.language, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final (locale, label) in [
                  (null, l.systemDefault),
                  (const Locale('en'), l.english),
                  (const Locale('zh'), l.chinese),
                ])
                  ListTile(
                    leading: Icon(
                      _locale == locale
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _locale == locale
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(label),
                    enabled: !_saving,
                    onTap: () => _selectLocale(locale),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.softwareDetails,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.code_outlined),
                  title: Text(l.developers),
                  subtitle: const Text(
                    '${AppMetadata.author} · ${AppMetadata.collaborator}',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l.developerProfile),
                  subtitle: const Text('github.com/ManiaAmaeOvo'),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => _open(AppMetadata.githubProfile),
                ),
                ListTile(
                  leading: const Icon(Icons.source_outlined),
                  title: Text(l.sourceCode),
                  subtitle: const Text('ManiaAmaeOvo/Logria'),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => _open(AppMetadata.repository),
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(l.privacyTitle),
                  subtitle: Text(l.privacySummary),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.firstReleaseScope),
                  subtitle: Text(l.firstReleaseScopeHint),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l.openSourceLicenses),
                  subtitle: const Text(AppMetadata.license),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Logria',
                    applicationVersion: AppMetadata.version,
                    applicationLegalese: '© 2026 ManiaAmaeOvo · MIT License',
                    applicationIcon: Image.asset(
                      'assets/branding/logria-icon.png',
                      width: 64,
                      height: 64,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
