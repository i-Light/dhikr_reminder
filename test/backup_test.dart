import 'dart:convert';

import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/core/storage/backup_file.dart';
import 'package:dhikr_reminder/core/storage/backup_files.dart';
import 'package:dhikr_reminder/core/storage/storage_guard.dart';
import 'package:dhikr_reminder/features/about/about_screen.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _entriesKey = 'dhikr_reminder.dhikr.entries';
const _dhikrSchemaKey = 'dhikr_reminder.dhikr.schema';

String _list(String name, {int amount = 3}) => jsonEncode([
      {'id': 0, 'name': name, 'amount': amount, 'chance': 10, 'dailyGoal': 0},
    ]);

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

String _file(Map<String, Object?> overrides) => jsonEncode({
      'app': 'dhikr_reminder',
      'format': 1,
      'schema': currentStorageSchema,
      'exportedAt': '2026-10-10T08:00:00.000',
      'keys': {_entriesKey: _list('سبحان الله')},
      ...overrides,
    });

class _FakeFiles implements BackupFiles {
  String? saved;
  String? savedName;
  String? toPick;
  bool saveOk = true;

  @override
  Future<bool> save(String fileName, String text) async {
    savedName = fileName;
    saved = text;
    return saveOk;
  }

  @override
  Future<String?> pick() async => toPick;
}

void main() {
  group('the backup file', () {
    test('holds the saved settings, and leaves out what belongs to the device',
        () async {
      final prefs = await _prefs({
        _entriesKey: _list('سبحان الله'),
        'dhikr_reminder.dhikr.reminderIntervalMinutes': 15,
        'dhikr_reminder.library.favourites': ['a', 'b'],
        'dhikr_reminder.history.days': '{"2026-10-09":40}',
        'dhikr_reminder.locale': 'en',
        'dhikr_reminder.requests.install': 'device-secret',
        'dhikr_reminder.autostart.firstRunDone': true,
        'dhikr_reminder.update.auto': false,
        'dhikr_reminder.dhikr.entries.unreadable': 'broken',
        'dhikr_reminder.storage.schema': currentStorageSchema,
        'someone_elses_key': 'x',
      });
      final text = buildBackupFile(prefs, now: DateTime(2026, 10, 10, 8));
      final decoded = jsonDecode(text) as Map<String, dynamic>;

      expect(decoded['app'], 'dhikr_reminder');
      expect(decoded['format'], backupFormat);
      expect(decoded['schema'], currentStorageSchema);
      expect(decoded['exportedAt'], startsWith('2026-10-10T08:00'));
      final keys = (decoded['keys'] as Map).keys.toSet();
      expect(keys, {
        _entriesKey,
        'dhikr_reminder.dhikr.reminderIntervalMinutes',
        'dhikr_reminder.library.favourites',
        'dhikr_reminder.history.days',
      });
    });

    test('reads back what it wrote', () async {
      final prefs = await _prefs({
        _entriesKey: _list('الحمد لله', amount: 33),
        'dhikr_reminder.sound.on': true,
        'dhikr_reminder.library.fontSize': 28.0,
        'dhikr_reminder.library.favourites': ['a'],
      });
      final reading = readBackupFile(buildBackupFile(prefs));
      expect(reading.isOk, isTrue);
      expect(reading.keys!['dhikr_reminder.sound.on'], true);
      expect(reading.keys!['dhikr_reminder.library.fontSize'], 28.0);
      expect(reading.keys!['dhikr_reminder.library.favourites'], ['a']);
    });

    test('refuses what is not a backup of this app', () {
      for (final text in [
        '',
        'not json',
        '[1, 2]',
        jsonEncode({'hello': 'world'}),
        _file({'app': 'another_app'}),
        _file({'format': 'one'}),
        _file({'keys': 'nothing'}),
        _file({'keys': <String, Object>{}}),
        // No dhikr list, or one that is not whole.
        _file({
          'keys': {'dhikr_reminder.sound.on': true},
        }),
        _file({
          'keys': {_entriesKey: 'not a list'},
        }),
        _file({
          'keys': {
            _entriesKey: jsonEncode([
              {'id': 1},
            ]),
          },
        }),
        // A value the settings never hold.
        _file({
          'keys': {
            _entriesKey: _list('x'),
            'dhikr_reminder.sound.on': {'nested': true},
          },
        }),
        'x' * (backupMaxBytes + 1),
      ]) {
        final reading = readBackupFile(text);
        expect(reading.isOk, isFalse, reason: text.length > 80 ? 'big' : text);
        expect(reading.problem, BackupProblem.notABackup);
      }
    });

    test('says so when it comes from a newer version', () {
      expect(
        readBackupFile(_file({'format': backupFormat + 1})).problem,
        BackupProblem.newer,
      );
      expect(
        readBackupFile(_file({'schema': currentStorageSchema + 1})).problem,
        BackupProblem.newer,
      );
    });

    test('ignores device-bound keys even if a file carries them', () {
      final reading = readBackupFile(
        _file({
          'keys': {
            _entriesKey: _list('x'),
            'dhikr_reminder.requests.install': 'other-device',
            'dhikr_reminder.locale': 'en',
            'dhikr_reminder.storage.schema': 99,
          },
        }),
      );
      expect(reading.isOk, isTrue);
      expect(reading.keys!.keys, [_entriesKey]);
    });

    test('puts the file in place of what is saved, and nothing else', () async {
      final prefs = await _prefs({
        _entriesKey: _list('old'),
        'dhikr_reminder.library.favourites': ['gone'],
        'dhikr_reminder.history.days': '{"2026-01-01":5}',
        'dhikr_reminder.requests.install': 'mine',
        'dhikr_reminder.locale': 'en',
      });
      final reading = readBackupFile(
        _file({
          'keys': {
            _entriesKey: _list('new'),
            'dhikr_reminder.sound.on': true,
            'dhikr_reminder.dhikr.reminderIntervalMinutes': 45,
          },
        }),
      );
      await applyBackup(prefs, reading.keys!);

      expect(prefs.getString(_entriesKey), _list('new'));
      expect(prefs.getBool('dhikr_reminder.sound.on'), true);
      expect(prefs.getInt('dhikr_reminder.dhikr.reminderIntervalMinutes'), 45);
      // What the file did not have is gone from the settings...
      expect(prefs.containsKey('dhikr_reminder.library.favourites'), isFalse);
      expect(prefs.containsKey('dhikr_reminder.history.days'), isFalse);
      // ...but this device's own stay.
      expect(prefs.getString('dhikr_reminder.requests.install'), 'mine');
      expect(prefs.getString('dhikr_reminder.locale'), 'en');
    });
  }, skip: !Features.backup);

  group('the Backup section on the About page', () {
    late _FakeFiles files;

    Future<ProviderContainer> open(WidgetTester tester) async {
      // Tall enough that the whole page is on screen.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      files = _FakeFiles();
      final container = ProviderContainer(
        overrides: [backupFilesProvider.overrideWithValue(files)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AboutScreen(version: Future.value('1.0.0 (6)')),
          ),
        ),
      );
      await tester.pump();
      return container;
    }

    testWidgets('"Save a copy" hands the file over with a dated name',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {_entriesKey: _list('سبحان الله')});
      await open(tester);

      await tester.tap(find.byKey(const ValueKey('backup-export')));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 30),
          ));
      await tester.pump();

      expect(files.savedName,
          matches(r'^dhikr-reminder-backup-\d{4}-\d{2}-\d{2}\.json$'));
      expect(readBackupFile(files.saved!).isOk, isTrue);
      expect(find.text('Copy saved'), findsOneWidget);
    });

    testWidgets('a cancelled save says nothing', (tester) async {
      SharedPreferences.setMockInitialValues({_entriesKey: _list('x')});
      await open(tester);
      files.saveOk = false;

      await tester.tap(find.byKey(const ValueKey('backup-export')));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 30),
          ));
      await tester.pump();

      expect(find.text('Copy saved'), findsNothing);
    });

    testWidgets('restoring asks first, then the app shows the restored list',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        _entriesKey: _list('old'),
        _dhikrSchemaKey: 3,
      });
      final container = await open(tester);
      await tester.runAsync(() async {
        container.read(dhikrSettingsProvider);
        while (!container.read(dhikrSettingsProvider).isLoaded) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
      });
      expect(
        container.read(dhikrSettingsProvider).entries.single.name,
        'old',
      );
      files.toPick = _file({
        'keys': {
          _entriesKey: _list('من الملف', amount: 7),
          _dhikrSchemaKey: 3,
        },
      });

      await tester.tap(find.byKey(const ValueKey('backup-import')));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 30),
          ));
      await tester.pumpAndSettle();
      expect(find.text('Replace what is on this device?'), findsOneWidget);

      // Backing out changes nothing.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getString(_entriesKey),
        _list('old'),
      );

      await tester.tap(find.byKey(const ValueKey('backup-import')));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 30),
          ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('backup-replace')));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 60));
        container.read(dhikrSettingsProvider);
        while (!container.read(dhikrSettingsProvider).isLoaded) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
      });
      await tester.pumpAndSettle();

      final entry = container.read(dhikrSettingsProvider).entries.single;
      expect(entry.name, 'من الملف');
      expect(entry.amount, 7);
      expect(find.text('Restored from the file'), findsOneWidget);
    });

    testWidgets('a file that is not a backup is refused with a message',
        (tester) async {
      SharedPreferences.setMockInitialValues({_entriesKey: _list('keep')});
      await open(tester);
      files.toPick = 'hello';

      await tester.tap(find.byKey(const ValueKey('backup-import')));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 30),
          ));
      await tester.pumpAndSettle();

      expect(find.text('That file is not a backup from this app.'),
          findsOneWidget);
      expect(find.text('Replace what is on this device?'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getString(_entriesKey),
        _list('keep'),
      );
    });

    testWidgets('a backup from a newer version is refused with its own message',
        (tester) async {
      SharedPreferences.setMockInitialValues({_entriesKey: _list('keep')});
      await open(tester);
      files.toPick = _file({'format': backupFormat + 1});

      await tester.tap(find.byKey(const ValueKey('backup-import')));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 30),
          ));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'That backup comes from a newer version of the app. Update the app first.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('picking nothing does nothing', (tester) async {
      SharedPreferences.setMockInitialValues({_entriesKey: _list('keep')});
      await open(tester);
      files.toPick = null;

      await tester.tap(find.byKey(const ValueKey('backup-import')));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 30),
          ));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });
  }, skip: !Features.backup);
}
