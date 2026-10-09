import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _entriesKey = 'dhikr_reminder.dhikr.entries';
const _nextIdKey = 'dhikr_reminder.dhikr.nextId';

Future<ProviderContainer> _load(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(dhikrSettingsProvider);
  while (!container.read(dhikrSettingsProvider).isLoaded) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  return container;
}

void main() {
  group('parseSavedEntries', () {
    test('reads a good list', () {
      final parsed = parseSavedEntries(
        '[{"id":1,"name":"a","amount":3,"chance":5,"dailyGoal":0}]',
      );
      expect(parsed.entries.single.name, 'a');
      expect(parsed.skipped, 0);
      expect(parsed.wholeListOk, isTrue);
    });

    test('skips one malformed entry and keeps the rest', () {
      final parsed = parseSavedEntries(
        '[{"id":1,"name":"a"},{"id":"x"},42,{"id":3,"name":"c"}]',
      );
      expect(parsed.entries.map((e) => e.id), [1, 3]);
      expect(parsed.skipped, 2);
      expect(parsed.wholeListOk, isTrue);
    });

    test('text cut short is not a list', () {
      final parsed = parseSavedEntries('[{"id":1,"name":"a"},{"id":2,"na');
      expect(parsed.entries, isEmpty);
      expect(parsed.wholeListOk, isFalse);
    });
  });

  group('loading the saved list', () {
    test('a malformed entry does not lose the others', () async {
      final container = await _load({
        _entriesKey: '[{"id":1,"name":"keep me"},{"oops":true}]',
      });
      final entries = container.read(dhikrSettingsProvider).entries;
      expect(entries.map((e) => e.name), ['keep me']);
      // The original is kept aside, not overwritten.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_entriesKey), contains('oops'));
      expect(
        prefs.getString('dhikr_reminder.dhikr.entries.unreadable'),
        contains('oops'),
      );
    });

    test(
      'a corrupt list never writes the defaults over the saved text',
      () async {
        const broken = '[{"id":1,"name":"a"},{"id":2,';
        final container = await _load({_entriesKey: broken});
        expect(container.read(dhikrSettingsProvider).entries, isNotEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(_entriesKey), broken);
        expect(
          prefs.getString('dhikr_reminder.dhikr.entries.unreadable'),
          broken,
        );
      },
    );

    test(
      'new ids start above the largest saved one, whatever the counter says',
      () async {
        final container = await _load({
          _entriesKey: '[{"id":41,"name":"a"}]',
          _nextIdKey: 2,
        });
        expect(container.read(dhikrSettingsProvider.notifier).allocateId(), 42);
      },
    );
  });
}
