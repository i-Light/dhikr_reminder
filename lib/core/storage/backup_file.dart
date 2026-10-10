import 'dart:convert';

import 'package:dhikr_reminder/core/storage/prefs_backup.dart';
import 'package:dhikr_reminder/core/storage/storage_guard.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shape of the backup file, for anyone who needs to read or move one:
///
/// ```json
/// {
///   "app": "dhikr_reminder",
///   "format": 1,
///   "schema": 3,
///   "exportedAt": "2026-10-10T08:30:00.000",
///   "keys": { "dhikr_reminder.dhikr.entries": "[...]", ... }
/// }
/// ```
///
/// `keys` is the app's saved settings as they are on disk (the dhikr list, the
/// interval, quiet hours, the day's counts, the history, the stars, the library
/// view options). `format` is raised only if this layout changes, `schema` is
/// the app's storage schema ([currentStorageSchema]) at the time it was written.
const backupFormat = 1;
const _appMarker = 'dhikr_reminder';

/// A file bigger than this is not a backup of this app.
const backupMaxBytes = 2 * 1024 * 1024;

const _entriesKey = 'dhikr_reminder.dhikr.entries';

/// What belongs to this device and not to the person, so it is neither saved
/// into a backup nor put back from one: the anonymous id of the request service
/// (a second device must not share it), the start-with-Windows choice, the
/// updater's choices, the language, and the storage stamp (set by whoever last
/// converted the data, never copied).
const _deviceBoundPrefixes = [
  'dhikr_reminder.requests.',
  'dhikr_reminder.autostart.',
  'dhikr_reminder.update.',
  'dhikr_reminder.shell.',
];
const _deviceBoundKeys = {
  'dhikr_reminder.locale',
  storageSchemaKey,
};

bool _portable(String key) =>
    key.startsWith('dhikr_reminder.') &&
    !key.endsWith('.unreadable') &&
    !_deviceBoundKeys.contains(key) &&
    !_deviceBoundPrefixes.any(key.startsWith);

/// The backup file's text for what is saved now.
String buildBackupFile(SharedPreferences prefs, {DateTime? now}) {
  final keys = PrefsBackup.snapshot(prefs)
    ..removeWhere((key, _) => !_portable(key));
  return const JsonEncoder.withIndent('  ').convert({
    'app': _appMarker,
    'format': backupFormat,
    'schema': currentStorageSchema,
    'exportedAt': (now ?? DateTime.now()).toIso8601String(),
    'keys': keys,
  });
}

/// Why a file cannot be restored.
enum BackupProblem {
  /// Not a backup of this app, or damaged.
  notABackup,

  /// Made by a newer version of the app, which this one cannot read safely.
  newer,
}

/// What [readBackupFile] found: the settings to put back, or why not.
class BackupReading {
  const BackupReading.ok(Map<String, Object> this.keys) : problem = null;
  const BackupReading.problem(BackupProblem this.problem) : keys = null;

  final Map<String, Object>? keys;
  final BackupProblem? problem;

  bool get isOk => keys != null;
}

/// Checks [text] is a backup this build can restore, without touching anything.
BackupReading readBackupFile(String text) {
  const bad = BackupReading.problem(BackupProblem.notABackup);
  if (text.length > backupMaxBytes) return bad;
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    return bad;
  }
  if (decoded is! Map || decoded['app'] != _appMarker) return bad;
  final format = decoded['format'];
  final schema = decoded['schema'];
  if (format is! int || schema is! int || format < 1 || schema < 1) return bad;
  if (format > backupFormat || schema > currentStorageSchema) {
    return const BackupReading.problem(BackupProblem.newer);
  }
  final raw = decoded['keys'];
  if (raw is! Map) return bad;

  final keys = <String, Object>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || !_portable(key)) continue;
    final ok = value is String ||
        value is bool ||
        value is int ||
        value is double ||
        (value is List && value.every((item) => item is String));
    if (!ok) return bad;
    keys[key] = value as Object;
  }
  // The dhikr list is what a backup is for: it has to be there and be whole.
  final entries = keys[_entriesKey];
  if (entries is! String) return bad;
  final parsed = parseSavedEntries(entries);
  if (!parsed.wholeListOk || parsed.skipped > 0) return bad;
  return BackupReading.ok(keys);
}

/// Puts [keys] (from [readBackupFile]) in place of what is saved. The new
/// values are written first and what the file does not have is removed after,
/// so a failure partway leaves a mix of the two and never nothing.
Future<void> applyBackup(
  SharedPreferences prefs,
  Map<String, Object> keys,
) async {
  await PrefsBackup.writeKeys(prefs, keys);
  for (final key in prefs.getKeys().toList()) {
    if (_portable(key) && !keys.containsKey(key)) await prefs.remove(key);
  }
}
