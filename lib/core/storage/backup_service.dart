import 'dart:async';

import 'package:dhikr_reminder/core/logging/app_logger.dart';
import 'package:dhikr_reminder/core/storage/prefs_backup.dart';
import 'package:dhikr_reminder/core/storage/storage_guard.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this start put the settings back from a backup because the settings
/// file was lost or damaged. Overridden once in `main`; the home page says so
/// in a single line, once.
final restoredFromBackupProvider = Provider<bool>((ref) => false);

/// Before anything reads the settings: checks they are not newer than this
/// build, and (on Windows, where one damaged file used to lose everything)
/// restores them from the newest good backup if they are gone. Returns whether
/// it restored.
Future<bool> prepareStorage({required bool keepBackups}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    var restored = false;
    final backup = keepBackups ? _backupFor() : null;
    if (backup != null) {
      restored = await backup.restoreIfLost(prefs);
      if (restored) AppLogger.note('Settings restored from a backup.');
    }
    StorageGuard.check(prefs);
    return restored;
  } catch (error, stack) {
    AppLogger.write('Storage', error, stack);
    return false;
  }
}

PrefsBackup? _backupFor() {
  final dir = AppLogger.file?.parent;
  return dir == null ? null : PrefsBackup(dir);
}

/// Keeps the rolling backup current while the app runs: a few seconds after the
/// dhikr list, the settings or the counts change (changes come in bursts, so
/// it waits for quiet), one copy is written. Nothing runs between changes.
void startPrefsBackup(ProviderContainer container) {
  final backup = _backupFor();
  if (backup == null) return;
  Timer? pending;
  void schedule() {
    pending?.cancel();
    pending = Timer(const Duration(seconds: 8), () async {
      try {
        if (!StorageGuard.canWrite) return;
        final prefs = await SharedPreferences.getInstance();
        await backup.save(PrefsBackup.snapshot(prefs));
      } catch (error, stack) {
        AppLogger.write('Backup', error, stack);
      }
    });
  }

  container.listen(dhikrSettingsProvider, (previous, next) {
    // Only a real, loaded state is worth keeping: never the seed defaults.
    if (next.isLoaded) schedule();
  });
  container.listen(dhikrStatsProvider, (_, __) => schedule());
}
