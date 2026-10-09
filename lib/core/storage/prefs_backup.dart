import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Every key the app saves starts with this, so the backup can take them all
/// without a list that someone forgets to extend.
const _appKeyPrefix = 'dhikr_reminder.';

/// The key whose absence, together with the schema key's, means "this looks
/// like a new install (or a settings file that was lost)".
const _entriesKey = 'dhikr_reminder.dhikr.entries';
const _schemaKey = 'dhikr_reminder.storage.schema';
const _legacySchemaKey = 'dhikr_reminder.dhikr.schema';

/// Copies that are never worth restoring: a damaged list kept aside for a
/// human, which would only bring the damage back.
const _skippedSuffixes = ['.unreadable'];

/// A rolling backup of the saved settings, for Windows, where one damaged or
/// half-written settings file used to lose the dhikr list for good.
///
/// The settings plugin rewrites its whole file on every change and swallows a
/// file it cannot parse. This keeps the last [keep] good copies next to the
/// app's log, each written to a temporary file and renamed into place, so a
/// crash or a power cut mid-write can never leave a half-written backup. If the
/// settings file comes back empty while a copy exists, [restoreIfLost] puts the
/// newest good copy back.
class PrefsBackup {
  PrefsBackup(this.directory, {this.keep = 3});

  /// Where the copies live: `backup.json` (newest), `backup.1.json`, ...
  final Directory directory;
  final int keep;

  File _file(int index) => File(
        '${directory.path}${Platform.pathSeparator}'
        '${index == 0 ? 'backup.json' : 'backup.$index.json'}',
      );

  /// The app's own settings as plain JSON-able values.
  static Map<String, Object> snapshot(SharedPreferences prefs) {
    final keys = <String, Object>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_appKeyPrefix)) continue;
      if (_skippedSuffixes.any(key.endsWith)) continue;
      final value = prefs.get(key);
      if (value != null) keys[key] = value;
    }
    return keys;
  }

  /// Writes [keys] as the newest copy and pushes the older ones down, dropping
  /// the oldest. Does nothing for a snapshot without a dhikr list: such a copy
  /// could never be restored, and would push a good one down for nothing.
  Future<void> save(Map<String, Object> keys) async {
    if (!keys.containsKey(_entriesKey)) return;
    directory.createSync(recursive: true);
    final text = jsonEncode({
      'v': 1,
      'savedAt': DateTime.now().toIso8601String(),
      'keys': keys,
    });
    final temp = File('${_file(0).path}.tmp');
    await temp.writeAsString(text, flush: true);

    // Only a copy that is itself good is worth keeping as an older one.
    for (var i = keep - 1; i >= 1; i--) {
      final from = _file(i - 1);
      if (!from.existsSync()) continue;
      if (i == 1 && _readKeys(from) == null) continue;
      final to = _file(i);
      if (to.existsSync()) to.deleteSync();
      from.renameSync(to.path);
    }
    // Rename over the target: atomic on the same volume.
    temp.renameSync(_file(0).path);
  }

  /// The settings of the newest copy that parses and holds a dhikr list, or
  /// null when there is none.
  Map<String, Object>? newestGood() {
    for (var i = 0; i < keep; i++) {
      final file = _file(i);
      if (!file.existsSync()) continue;
      final keys = _readKeys(file);
      if (keys != null && keys.containsKey(_entriesKey)) return keys;
    }
    return null;
  }

  Map<String, Object>? _readKeys(File file) {
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map || decoded['v'] != 1) return null;
      final keys = decoded['keys'];
      if (keys is! Map || keys.isEmpty) return null;
      return {
        for (final entry in keys.entries)
          if (entry.key is String && entry.value != null)
            entry.key as String: entry.value as Object,
      };
    } catch (_) {
      return null;
    }
  }

  /// Puts the newest good copy back into [prefs] when the settings look lost:
  /// no dhikr list and no schema stamp, which a working install always has
  /// after its first start. Returns whether it restored anything.
  Future<bool> restoreIfLost(SharedPreferences prefs) async {
    final lost = !prefs.containsKey(_entriesKey) &&
        !prefs.containsKey(_schemaKey) &&
        !prefs.containsKey(_legacySchemaKey);
    if (!lost) return false;
    final keys = newestGood();
    if (keys == null) return false;
    for (final entry in keys.entries) {
      final value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is List) {
        await prefs.setStringList(
          entry.key,
          value.whereType<String>().toList(),
        );
      }
    }
    return true;
  }
}
