import 'package:shared_preferences/shared_preferences.dart';

/// The version of everything the app keeps in its saved settings, as one
/// number. Raised whenever the stored shape changes in a way old data has to be
/// converted through (see [migrateStorage]).
///
/// 1 was the original 0-100 chance scale; 2 the 0-10 scale; 3 added the link
/// from a saved dhikr to its library entry.
const currentStorageSchema = 3;

/// Where that number is saved.
const storageSchemaKey = 'dhikr_reminder.storage.schema';

/// The schema key the dhikr list kept before there was a global one.
const _legacyDhikrSchemaKey = 'dhikr_reminder.dhikr.schema';
const _legacyDhikrEntriesKey = 'dhikr_reminder.dhikr.entries';

/// Decides, once per run, whether this build may write the saved settings.
///
/// If the settings were last written by a NEWER build (the person went back to
/// an older version), this one does not understand all of them, and writing
/// would rewrite the file and drop what it does not know. So it reads what it
/// can and writes nothing: [canWrite] stays false until the next start of a
/// build that understands them.
abstract final class StorageGuard {
  static bool _canWrite = true;

  /// False when the saved settings are newer than this build.
  static bool get canWrite => _canWrite;

  /// Reads the stored schema and records the verdict. Cheap, and safe to call
  /// more than once. It never writes: the stamp is made by whoever has just
  /// converted the data (see `DhikrSettingsNotifier`), so it cannot claim a
  /// conversion that has not happened yet.
  static void check(SharedPreferences prefs) {
    _canWrite = storedSchemaOf(prefs) <= currentStorageSchema;
  }

  /// For tests: forget the verdict.
  static void reset() => _canWrite = true;
}

/// The schema the saved settings were written with. A fresh install has none
/// and counts as current; data from before the global key falls back to the
/// dhikr list's own number, and to 1 when only the list itself is there.
int storedSchemaOf(SharedPreferences prefs) {
  final global = prefs.getInt(storageSchemaKey);
  if (global != null) return global;
  final legacy = prefs.getInt(_legacyDhikrSchemaKey);
  if (legacy != null) return legacy;
  return prefs.containsKey(_legacyDhikrEntriesKey) ? 1 : currentStorageSchema;
}
