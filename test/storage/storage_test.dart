import 'dart:convert';
import 'dart:io';

import 'package:dhikr_reminder/core/storage/prefs_backup.dart';
import 'package:dhikr_reminder/core/storage/storage_guard.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _entries = 'dhikr_reminder.dhikr.entries';
const _interval = 'dhikr_reminder.dhikr.reminderIntervalMinutes';

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<ProviderContainer> _loaded() async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(dhikrSettingsProvider);
  while (!container.read(dhikrSettingsProvider).isLoaded) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return container;
}

void main() {
  tearDown(StorageGuard.reset);

  group('StorageGuard', () {
    test('a fresh install may write', () async {
      StorageGuard.check(await _prefs({}));
      expect(StorageGuard.canWrite, isTrue);
    });

    test('settings from the same or an older build may be written', () async {
      StorageGuard.check(
        await _prefs({storageSchemaKey: currentStorageSchema}),
      );
      expect(StorageGuard.canWrite, isTrue);
      StorageGuard.check(await _prefs({_entries: '[]'}));
      expect(StorageGuard.canWrite, isTrue);
    });

    test('settings from a newer build are read but never written', () async {
      final prefs = await _prefs({
        storageSchemaKey: currentStorageSchema + 1,
        _entries: '[{"id":1,"name":"kept","futureField":true}]',
      });
      StorageGuard.check(prefs);
      expect(StorageGuard.canWrite, isFalse);

      final container = await _loaded();
      expect(container.read(dhikrSettingsProvider).entries.single.name, 'kept');
      await container.read(dhikrSettingsProvider.notifier).updateInterval(45);

      // The change is on screen, the file is untouched.
      expect(container.read(dhikrSettingsProvider).intervalMinutes, 45);
      final after = await SharedPreferences.getInstance();
      expect(after.getInt(_interval), isNull);
      expect(after.getString(_entries), contains('futureField'));
    });
  });

  group('migration', () {
    test(
      'the original 0-100 chance scale is converted once, and stamped',
      () async {
        await _prefs({
          _entries: '[{"id":1,"name":"a","chance":100,"amount":0}]',
        });
        StorageGuard.check(await SharedPreferences.getInstance());
        final container = await _loaded();
        final entry = container.read(dhikrSettingsProvider).entries.single;
        expect(entry.chance, 10);
        expect(entry.amount, dhikrAmountMin);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(storageSchemaKey), currentStorageSchema);
        // A second load must not divide again.
        final again = await _loaded();
        expect(again.read(dhikrSettingsProvider).entries.single.chance, 10);
      },
    );
  });

  group('PrefsBackup', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('dhikr_backup'));
    tearDown(() => dir.deleteSync(recursive: true));

    Map<String, Object> keys(String name) => {
          _entries: '[{"id":1,"name":"$name"}]',
          storageSchemaKey: currentStorageSchema,
        };

    test('keeps the last three copies, newest first', () async {
      final backup = PrefsBackup(dir);
      for (final name in ['one', 'two', 'three', 'four']) {
        await backup.save(keys(name));
      }
      String nameIn(String file) => jsonDecode(
            File('${dir.path}/$file').readAsStringSync(),
          )['keys'][_entries] as String;
      expect(nameIn('backup.json'), contains('four'));
      expect(nameIn('backup.1.json'), contains('three'));
      expect(nameIn('backup.2.json'), contains('two'));
      expect(File('${dir.path}/backup.3.json').existsSync(), isFalse);
      expect(File('${dir.path}/backup.json.tmp').existsSync(), isFalse);
    });

    test('a snapshot without a dhikr list is not worth keeping', () async {
      final backup = PrefsBackup(dir);
      await backup.save({storageSchemaKey: 3});
      expect(File('${dir.path}/backup.json').existsSync(), isFalse);
    });

    test('restores the newest good copy when the settings are gone', () async {
      final backup = PrefsBackup(dir);
      await backup.save(keys('older'));
      await backup.save(keys('newer'));
      // The newest copy is damaged (a disk fault): the one before it is used.
      File('${dir.path}/backup.json').writeAsStringSync('{"v":1,"keys":');

      final prefs = await _prefs({});
      expect(await backup.restoreIfLost(prefs), isTrue);
      expect(prefs.getString(_entries), contains('older'));
    });

    test('never touches settings that are there', () async {
      final backup = PrefsBackup(dir);
      await backup.save(keys('backup'));
      final prefs = await _prefs({_entries: '[{"id":1,"name":"live"}]'});
      expect(await backup.restoreIfLost(prefs), isFalse);
      expect(prefs.getString(_entries), contains('live'));
    });

    test('with no copy there is nothing to restore', () async {
      expect(await PrefsBackup(dir).restoreIfLost(await _prefs({})), isFalse);
    });

    test(
      'the snapshot holds the app keys and skips a damaged list kept aside',
      () async {
        final prefs = await _prefs({
          _entries: '[]',
          '$_entries.unreadable': 'broken',
          'flutter.other': 'x',
          'dhikr_reminder.library.fontSize': 22.0,
        });
        final snapshot = PrefsBackup.snapshot(prefs);
        expect(
          snapshot.keys,
          containsAll([_entries, 'dhikr_reminder.library.fontSize']),
        );
        expect(snapshot.keys, isNot(contains('$_entries.unreadable')));
      },
    );
  });
}
