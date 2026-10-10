import 'dart:async';

import 'package:dhikr_reminder/core/storage/backup_file.dart';
import 'package:dhikr_reminder/core/storage/backup_files.dart';
import 'package:dhikr_reminder/core/storage/storage_guard.dart';
import 'package:dhikr_reminder/features/history/history.dart';
import 'package:dhikr_reminder/features/library/application/favourites_controller.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Save a copy" and "Restore from a file": the saved dhikr list, counts and
/// settings in one file the person keeps wherever they like.
///
/// On the About page, one tap deeper than the settings, so the pages that are
/// open every day show nothing more.
class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final name = 'dhikr-reminder-backup-${dhikrDayKey(now)}.json';
    final saved = await ref
        .read(backupFilesProvider)
        .save(name, buildBackupFile(prefs, now: now));
    if (!saved) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.backupSaved)));
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) => messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));

    final text = await ref.read(backupFilesProvider).pick();
    if (text == null) return;
    // Settings written by a newer build are read, never rewritten: nothing may
    // be put back over them either.
    final reading = StorageGuard.canWrite
        ? readBackupFile(text)
        : const BackupReading.problem(BackupProblem.newer);
    final keys = reading.keys;
    if (keys == null) {
      say(
        reading.problem == BackupProblem.newer
            ? l10n.backupNewerFile
            : l10n.backupBadFile,
      );
      return;
    }
    if (!context.mounted) return;
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupRestoreTitle),
        content: Text(l10n.backupRestoreBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const ValueKey('backup-replace'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.backupRestoreConfirm),
          ),
        ],
      ),
    );
    if (replace != true) return;

    await applyBackup(await SharedPreferences.getInstance(), keys);
    // Everything that read the old values reads again, so the app shows the
    // restored ones without a restart.
    ref
      ..invalidate(dhikrSettingsProvider)
      ..invalidate(dhikrStatsProvider)
      ..invalidate(historyProvider)
      ..invalidate(showStreakProvider)
      ..invalidate(dhikrLibraryProvider)
      ..invalidate(favouritesProvider);
    say(l10n.backupRestored);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.backupTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.backupSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('backup-export'),
              onPressed: () => unawaited(_export(context, ref)),
              icon: const Icon(Icons.save_alt_outlined),
              label: Text(l10n.backupExport),
            ),
            OutlinedButton.icon(
              key: const ValueKey('backup-import'),
              onPressed: () => unawaited(_import(context, ref)),
              icon: const Icon(Icons.restore_outlined),
              label: Text(l10n.backupImport),
            ),
          ],
        ),
      ],
    );
  }
}
