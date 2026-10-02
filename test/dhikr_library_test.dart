import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A container with the library provider built and its one fire-and-forget
/// prefs read already landed, so nothing is left writing to a disposed
/// notifier when the test ends.
Future<ProviderContainer> _libraryContainer() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final container = ProviderContainer();
  container.read(dhikrLibraryProvider);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stripTashkeel', () {
    test('drops the vowel marks and keeps the letters', () {
      expect(stripTashkeel('اللَّهُ أَكْبَرُ'), 'الله أكبر');
    });

    test('leaves unvocalised text alone', () {
      expect(stripTashkeel('بسم الله'), 'بسم الله');
    });
  });

  group('DhikrItem matching', () {
    const item = DhikrItem(
      id: 'x',
      text: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
      subtitle: 'يُقال حين يصبح',
      reference: 'البقرة: ٢٥٥',
      description: 'آية الكرسي',
      tags: <DhikrTag>[DhikrTag.morning, DhikrTag.quranicDuas],
    );

    test('a blank query matches everything', () {
      expect(item.matchesQuery(''), isTrue);
      expect(item.matchesQuery('   '), isTrue);
    });

    test('a query matches the text tashkeel-insensitively', () {
      expect(item.matchesQuery('الله'), isTrue);
      expect(item.matchesQuery('إله'), isTrue);
    });

    test('a query also looks at the subtitle, reference and description', () {
      expect(item.matchesQuery('البقرة'), isTrue);
      expect(item.matchesQuery('آية'), isTrue);
      expect(item.matchesQuery('يصبح'), isTrue);
    });

    test('a query that is nowhere in the entry does not match', () {
      expect(item.matchesQuery('زبد البحر'), isFalse);
    });

    test('no selected tags means no tag filter', () {
      expect(item.matchesTags(const <DhikrTag>{}), isTrue);
    });

    test('one shared tag is enough', () {
      expect(item.matchesTags(const <DhikrTag>{DhikrTag.quranicDuas}), isTrue);
      expect(
        item.matchesTags(const <DhikrTag>{DhikrTag.food, DhikrTag.morning}),
        isTrue,
      );
      expect(item.matchesTags(const <DhikrTag>{DhikrTag.food}), isFalse);
    });
  });

  group('the library data', () {
    test('is not empty', () {
      expect(dhikrLibrary, isNotEmpty);
    });

    test('has a unique id per entry', () {
      final ids = dhikrLibrary.map((entry) => entry.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('has no empty text', () {
      for (final item in dhikrLibrary) {
        expect(item.text.trim(), isNotEmpty, reason: item.id);
      }
    });

    test('gives every tag at least one entry', () {
      for (final tag in DhikrTag.values) {
        expect(
          dhikrLibrary.any((item) => item.tags.contains(tag)),
          isTrue,
          reason: 'no entry carries $tag',
        );
      }
    });

    test('never stores a blank reference', () {
      for (final item in dhikrLibrary.where((e) => e.reference != null)) {
        expect(item.reference!.trim(), isNotEmpty, reason: item.id);
      }
    });
  });

  group('DhikrLibraryNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      container = await _libraryContainer();
      addTearDown(container.dispose);
    });

    test('starts unfiltered, vocalised, at the default size', () {
      final view = container.read(dhikrLibraryProvider);
      expect(view.query, isEmpty);
      expect(view.selectedTags, isEmpty);
      expect(view.showTashkeel, isTrue);
      expect(view.fontSize, dhikrLibraryFontDefault);
      expect(view.hasTagFilter, isFalse);
      expect(container.read(filteredDhikrProvider).length, dhikrLibrary.length);
    });

    test('a tag filter narrows the list to entries carrying it', () {
      container.read(dhikrLibraryProvider.notifier).toggleTag(DhikrTag.ruqyah);
      final filtered = container.read(filteredDhikrProvider);
      expect(filtered, isNotEmpty);
      expect(filtered.every((i) => i.tags.contains(DhikrTag.ruqyah)), isTrue);
      expect(filtered.length, lessThan(dhikrLibrary.length));
    });

    test('a second tag widens the list back out', () {
      final notifier = container.read(dhikrLibraryProvider.notifier);
      notifier.toggleTag(DhikrTag.ruqyah);
      final oneTag = container.read(filteredDhikrProvider).length;
      notifier.toggleTag(DhikrTag.food);
      expect(container.read(filteredDhikrProvider).length, greaterThan(oneTag));
    });

    test('tapping the same tag again removes it', () {
      final notifier = container.read(dhikrLibraryProvider.notifier);
      notifier.toggleTag(DhikrTag.ruqyah);
      notifier.toggleTag(DhikrTag.ruqyah);
      expect(container.read(dhikrLibraryProvider).selectedTags, isEmpty);
      expect(container.read(filteredDhikrProvider).length, dhikrLibrary.length);
    });

    test('a query filters on top of the tags', () {
      final notifier = container.read(dhikrLibraryProvider.notifier);
      notifier.toggleTag(DhikrTag.morning);
      notifier.updateQuery('الفلق');
      final filtered = container.read(filteredDhikrProvider);
      expect(filtered, isNotEmpty);
      expect(filtered.every((i) => i.matchesQuery('الفلق')), isTrue);
    });

    test('the font size steps and clamps at both ends', () async {
      final notifier = container.read(dhikrLibraryProvider.notifier);
      for (var i = 0; i < 100; i++) {
        await notifier.stepFontSize(1);
      }
      expect(container.read(dhikrLibraryProvider).fontSize, dhikrLibraryFontMax);
      for (var i = 0; i < 100; i++) {
        await notifier.stepFontSize(-1);
      }
      expect(container.read(dhikrLibraryProvider).fontSize, dhikrLibraryFontMin);
    });

    test('the tashkeel toggle flips', () async {
      final notifier = container.read(dhikrLibraryProvider.notifier);
      await notifier.toggleTashkeel();
      expect(container.read(dhikrLibraryProvider).showTashkeel, isFalse);
      await notifier.toggleTashkeel();
      expect(container.read(dhikrLibraryProvider).showTashkeel, isTrue);
    });
  });
}
