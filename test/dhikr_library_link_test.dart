import 'dart:convert';

import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _entriesKey = 'dhikr_reminder.dhikr.entries';
const _schemaKey = 'dhikr_reminder.dhikr.schema';

/// A container whose settings have been read from the mocked preferences.
Future<ProviderContainer> _loaded(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.listen(dhikrSettingsProvider, (_, __) {});
  for (var i = 0; i < 200; i++) {
    if (container.read(dhikrSettingsProvider).isLoaded) break;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(container.read(dhikrSettingsProvider).isLoaded, isTrue);
  // Let the write-back that a migration starts land.
  await Future<void>.delayed(const Duration(milliseconds: 5));
  return container;
}

DhikrItem _someItem({int? count}) => dhikrLibrary.firstWhere(
      (i) => i.isRemindable && (count == null || i.count == count),
    );

void main() {
  group('libraryItemForText', () {
    test('finds an entry by its words, whatever the vowels or kashida', () {
      final item = libraryItemForText('سُبْحَانَ اللَّهِ');
      expect(item, isNotNull);
      expect(stripTashkeel(item!.text).trim(), 'سبحان الله');
    });

    test('finds nothing for words the library does not have', () {
      expect(libraryItemForText('كلام ليس من الأذكار'), isNull);
    });

    test('libraryItemById returns the same entry', () {
      final item = dhikrLibrary.first;
      expect(libraryItemById(item.id), same(item));
      expect(libraryItemById('nope'), isNull);
    });
  });

  group('linkEntriesToLibrary', () {
    test('ties a typed dhikr to its library entry and takes its words', () {
      final linked = linkEntriesToLibrary(const [
        DhikrEntry(id: 1, name: 'سُبْحَانَ اللَّهِ', amount: 9, dailyGoal: 50),
      ]);

      final item = libraryItemForText('سبحان الله')!;
      expect(linked.single.libraryId, item.id);
      expect(linked.single.name, item.text);
      // What the person set is theirs and stays.
      expect(linked.single.amount, 9);
      expect(linked.single.dailyGoal, 50);
    });

    test('leaves a dhikr that is not in the library as it is', () {
      const custom = DhikrEntry(id: 2, name: 'ذكر كتبته بنفسي');
      expect(linkEntriesToLibrary(const [custom]).single, custom);
    });

    test('refreshes the words of an entry that already has a link', () {
      final item = _someItem();
      final linked = linkEntriesToLibrary([
        DhikrEntry(id: 3, name: 'an older wording', libraryId: item.id),
      ]);

      expect(linked.single.name, item.text);
      expect(linked.single.libraryId, item.id);
    });

    test('keeps an entry whose link this version does not know', () {
      const kept = DhikrEntry(id: 4, name: 'نص', libraryId: 'from-the-future');
      expect(linkEntriesToLibrary(const [kept]).single, kept);
    });
  });

  group('loading the saved list', () {
    test('a fresh install seeds five dhikr, all linked to the library',
        () async {
      final container = await _loaded(const {});
      final entries = container.read(dhikrSettingsProvider).entries;

      expect(entries, hasLength(5));
      for (final entry in entries) {
        expect(libraryItemById(entry.libraryId ?? ''), isNotNull,
            reason: entry.name);
        expect(entry.name, libraryItemById(entry.libraryId!)!.text);
      }
    });

    test('a list from before the library took over is linked and saved back',
        () async {
      final container = await _loaded({
        _schemaKey: 2,
        _entriesKey: jsonEncode([
          {'id': 5, 'name': 'سُبْحَانَ اللَّهِ', 'amount': 3, 'chance': 10},
          {'id': 6, 'name': 'ذكر كتبته بنفسي', 'amount': 4, 'chance': 7},
        ]),
      });

      final entries = container.read(dhikrSettingsProvider).entries;
      expect(entries[0].libraryId, libraryItemForText('سبحان الله')!.id);
      expect(entries[0].amount, 3);
      expect(entries[1].libraryId, isNull);
      expect(entries[1].name, 'ذكر كتبته بنفسي');
      expect(entries[1].amount, 4);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(_schemaKey), 3);
      final saved = jsonDecode(prefs.getString(_entriesKey)!) as List;
      expect((saved[0] as Map)['libraryId'], entries[0].libraryId);
      expect((saved[1] as Map).containsKey('libraryId'), isFalse);
    });

    test('a list that is already linked is not changed', () async {
      final item = _someItem();
      final container = await _loaded({
        _schemaKey: 3,
        _entriesKey: jsonEncode([
          {
            'id': 1,
            'name': item.text,
            'amount': 2,
            'chance': 10,
            'libraryId': item.id,
          },
        ]),
      });

      final entry = container.read(dhikrSettingsProvider).entries.single;
      expect(entry.libraryId, item.id);
      expect(entry.amount, 2);
    });
  });

  group('adding from the library', () {
    test('adds a linked entry with the count the sources give', () async {
      final container = await _loaded(const {});
      final notifier = container.read(dhikrSettingsProvider.notifier);
      final item = _someItem(count: 3);

      final entry = await notifier.addFromLibrary(item);

      expect(entry.libraryId, item.id);
      expect(entry.name, item.text);
      expect(entry.amount, 3);
      final entries = container.read(dhikrSettingsProvider).entries;
      expect(entries.last, entry);
      expect(container.read(addedLibraryIdsProvider), contains(item.id));
    });

    test('uses the count it is given instead', () async {
      final container = await _loaded(const {});
      final notifier = container.read(dhikrSettingsProvider.notifier);

      final entry = await notifier.addFromLibrary(_someItem(), amount: 11);

      expect(entry.amount, 11);
    });

    test('keeps the count within bounds', () async {
      final container = await _loaded(const {});
      final notifier = container.read(dhikrSettingsProvider.notifier);

      final entry = await notifier.addFromLibrary(_someItem(), amount: 100000);

      expect(entry.amount, dhikrAmountMax);
    });

    test('adding the same entry twice does not duplicate it', () async {
      final container = await _loaded(const {});
      final notifier = container.read(dhikrSettingsProvider.notifier);
      final item = _someItem();

      final first = await notifier.addFromLibrary(item);
      final second = await notifier.addFromLibrary(item);

      expect(second, first);
      expect(
        container
            .read(dhikrSettingsProvider)
            .entries
            .where((e) => e.libraryId == item.id),
        hasLength(1),
      );
    });

    test('an added entry survives a restart', () async {
      final container = await _loaded(const {});
      final item = _someItem();
      await container
          .read(dhikrSettingsProvider.notifier)
          .addFromLibrary(item, amount: 5);

      final prefs = await SharedPreferences.getInstance();
      final again = await _loaded({
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      });

      final entry = again
          .read(dhikrSettingsProvider)
          .entries
          .firstWhere((e) => e.libraryId == item.id);
      expect(entry.amount, 5);
    });

    test('removes an entry by its library id', () async {
      final container = await _loaded(const {});
      final notifier = container.read(dhikrSettingsProvider.notifier);
      final item = _someItem();
      await notifier.addFromLibrary(item);

      await notifier.removeLibraryItem(item.id);

      expect(container.read(addedLibraryIdsProvider), isNot(contains(item.id)));
    });

    test('changes the count of an added entry', () async {
      final container = await _loaded(const {});
      final notifier = container.read(dhikrSettingsProvider.notifier);
      final item = _someItem();
      await notifier.addFromLibrary(item);

      await notifier.setLibraryItemAmount(item.id, 21);

      expect(notifier.entryForLibraryItem(item.id)!.amount, 21);
    });
  });

  group('DhikrEntry', () {
    test('compares by value and survives a JSON round trip', () {
      const entry = DhikrEntry(
        id: 1,
        name: 'نص',
        amount: 4,
        chance: 6,
        dailyGoal: 100,
        libraryId: 'dabc',
      );

      expect(DhikrEntry.fromJson(entry.toJson()), entry);
      expect(entry.copyWith(amount: 5), isNot(entry));
      expect(entry.copyWith(), entry);
      expect(entry.hashCode, entry.copyWith().hashCode);
    });

    test('leaves the link out of its JSON when it has none', () {
      expect(
        const DhikrEntry(id: 1, name: 'نص').toJson().containsKey('libraryId'),
        isFalse,
      );
    });
  });
}
