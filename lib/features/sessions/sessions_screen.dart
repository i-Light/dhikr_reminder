import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/features/library/application/favourites_controller.dart';
import 'package:dhikr_reminder/features/sessions/session_runner.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The morning azkar, the evening azkar and, when something is starred, "my
/// wird": three rows, each with one Start button. The reminder card does the
/// rest, one dhikr after another.
///
/// Reached from the folded reminder settings on the Notifications page, so
/// nothing is added to a page that is already open all the time.
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final wird =
        Features.wird ? ref.watch(favouriteItemsProvider) : const <Never>[];

    void start(SessionKind kind) {
      final saved = ref.read(dhikrSettingsProvider).entries;
      final items = sessionItems(kind, wird);
      ref.read(sessionRunProvider.notifier).start(kind, [
        for (final item in items)
          sessionEntry(item, saved, ownCounts: kind == SessionKind.wird),
      ]);
    }

    Widget row({
      required Key key,
      required IconData icon,
      required String title,
      required int count,
      required SessionKind kind,
      String? emptyNote,
    }) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
          child: Row(
            spacing: 12,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      count == 0 && emptyNote != null
                          ? emptyNote
                          : l10n.sessionCount(count),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                key: key,
                onPressed: count == 0 ? null : () => start(kind),
                child: Text(l10n.sessionStart),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Text(
                  l10n.sessionsSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                row(
                  key: const ValueKey('session-morning'),
                  icon: Icons.wb_sunny_outlined,
                  title: l10n.sessionMorning,
                  count: sessionItems(SessionKind.morning, wird).length,
                  kind: SessionKind.morning,
                ),
                const SizedBox(height: 12),
                row(
                  key: const ValueKey('session-evening'),
                  icon: Icons.nights_stay_outlined,
                  title: l10n.sessionEvening,
                  count: sessionItems(SessionKind.evening, wird).length,
                  kind: SessionKind.evening,
                ),
                if (Features.wird) ...[
                  const SizedBox(height: 12),
                  row(
                    key: const ValueKey('session-wird'),
                    icon: Icons.star_outline_rounded,
                    title: l10n.sessionWird,
                    count: sessionItems(SessionKind.wird, wird).length,
                    kind: SessionKind.wird,
                    emptyNote: l10n.sessionWirdEmpty,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
