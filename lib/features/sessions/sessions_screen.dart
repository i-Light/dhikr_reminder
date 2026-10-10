import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/features/library/application/favourites_controller.dart';
import 'package:dhikr_reminder/features/sessions/session_progress.dart';
import 'package:dhikr_reminder/features/sessions/session_runner.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
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

    final progress = ref.watch(sessionProgressProvider);
    final today = dhikrDayKey(ref.watch(dhikrStatsClockProvider)());

    // The dhikr of [kind] counted through today.
    int doneIn(SessionKind kind) {
      final done = progress.doneIn(kind, today);
      return sessionItems(kind, wird).where((i) => done.contains(i.id)).length;
    }

    void start(SessionKind kind) {
      final saved = ref.read(dhikrSettingsProvider).entries;
      final items = sessionItems(kind, wird);
      final done = progress.doneIn(kind, today);
      // Carries on at the first dhikr not counted through; from the top when
      // they all are (or none is).
      var from = items.indexWhere((i) => !done.contains(i.id));
      if (from < 0) from = 0;
      ref.read(sessionRunProvider.notifier).start(
            kind,
            [
              for (final item in items)
                sessionEntry(item, saved, ownCounts: kind == SessionKind.wird),
            ],
            startIndex: from,
          );
    }

    Widget row({
      required Key key,
      required IconData icon,
      required String title,
      required SessionKind kind,
      String? emptyNote,
    }) {
      final total = sessionItems(kind, wird).length;
      final done = doneIn(kind);
      final finished = total > 0 && done >= total;
      final started = done > 0 && !finished;
      const green = Color(0xFF2FBF8A);
      final String subtitle;
      if (total == 0 && emptyNote != null) {
        subtitle = emptyNote;
      } else if (finished) {
        subtitle = l10n.sessionAllDone;
      } else if (started) {
        subtitle = l10n.sessionDoneCount(done, total);
      } else {
        subtitle = l10n.sessionCount(total);
      }
      return Card(
        key: ValueKey('${(key as ValueKey<String>).value}-row'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
          child: Row(
            spacing: 12,
            children: [
              Icon(
                finished ? Icons.check_circle_rounded : icon,
                color: finished ? green : theme.colorScheme.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: finished
                            ? green
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // How far along, once there is any: a bar that fills as the
                    // dhikr are counted through.
                    if (done > 0) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        key: ValueKey('${key.value}-progress'),
                        value: (done / total).clamp(0.0, 1.0),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(999),
                        color: finished ? green : theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
              FilledButton.tonal(
                key: key,
                onPressed: total == 0 ? null : () => start(kind),
                child: Text(
                  finished
                      ? l10n.sessionAgain
                      : started
                          ? l10n.sessionContinue
                          : l10n.sessionStart,
                ),
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
                  kind: SessionKind.morning,
                ),
                const SizedBox(height: 12),
                row(
                  key: const ValueKey('session-evening'),
                  icon: Icons.nights_stay_outlined,
                  title: l10n.sessionEvening,
                  kind: SessionKind.evening,
                ),
                if (Features.wird) ...[
                  const SizedBox(height: 12),
                  row(
                    key: const ValueKey('session-wird'),
                    icon: Icons.star_outline_rounded,
                    title: l10n.sessionWird,
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
