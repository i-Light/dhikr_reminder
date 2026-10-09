import 'package:dhikr_reminder/core/window/app_logo.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Where the app says what it is made from: the version, where the dhikr come
/// from and how to report a mistake, the privacy promise in one line, the font
/// licences, and the open-source licence page. Opened from one quiet link at
/// the bottom of the settings page, so nothing here competes with the reminders.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, this.version});

  /// Overridden in tests; otherwise read from the package.
  final Future<String>? version;

  static Future<String> _readVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version} (${info.buildNumber})';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget paragraph(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            text,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.7),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const Center(child: AppLogo(size: 64)),
                const SizedBox(height: 8),
                Center(
                  child: FutureBuilder<String>(
                    future: version ?? _readVersion(),
                    builder: (context, snapshot) => Text(
                      (snapshot.data ?? '').isEmpty
                          ? ''
                          : l10n.aboutVersion(snapshot.data!),
                      style: theme.textTheme.labelLarge?.copyWith(color: muted),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                paragraph(l10n.aboutSources),
                paragraph(l10n.aboutPrivacy),
                paragraph(l10n.aboutFonts),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: l10n.appTitle,
                    ),
                    icon: const Icon(Icons.description_outlined),
                    label: Text(l10n.aboutLicenses),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
