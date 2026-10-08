import 'package:dhikr_reminder/features/library/domain/arabic_text.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeArabic', () {
    test('drops vowels, kashida and bidi marks', () {
      expect(normalizeArabic('اللَّهُمَّ'), 'اللهم');
      expect(normalizeArabic('اللهـم'), 'اللهم');
      expect(normalizeArabic('قبل${String.fromCharCode(0x200F)} الوضوء'), 'قبل الوضوء');
    });

    test('folds the spellings of alef, yeh and teh marbuta together', () {
      expect(normalizeArabic('أعوذ إلهي آمن ٱلله'), 'اعوذ الهي امن الله');
      expect(normalizeArabic('على الكرسى'), 'علي الكرسي');
      expect(normalizeArabic('رحمة'), normalizeArabic('رحمه'));
      expect(normalizeArabic('مؤمن'), 'مومن');
      expect(normalizeArabic('فضائل'), 'فضايل');
    });

    test('turns Arabic-Indic digits into plain ones', () {
      expect(normalizeArabic('البقرة: ٢٥٥'), 'البقره 255');
    });

    test('collapses punctuation and spacing into single spaces', () {
      expect(normalizeArabic('  الله ،  لا  إله... إلا الله  '), 'الله لا اله الا الله');
    });

    test('gives two spellings of one dhikr the same result', () {
      expect(
        normalizeArabic('اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ'),
        normalizeArabic('اللهـم أنت ربـي لا إله إلا أنت.'),
      );
    });

    test('leaves an empty or symbol-only string empty', () {
      expect(normalizeArabic(''), '');
      expect(normalizeArabic(' ... ، ! '), '');
    });
  });

  group('counting', () {
    test('arabicLetterCount counts letters, not marks or punctuation', () {
      expect(arabicLetterCount('اللَّهُ، أكبر!'), 8);
      expect(arabicLetterCount('abc 123'), 0);
    });

    test('letterCount counts letters of any script', () {
      expect(letterCount('abc 123 دد'), 5);
    });

    test('tashkeelCount counts the vowel marks', () {
      expect(tashkeelCount('اللَّهُ'), 3);
      expect(tashkeelCount('الله'), 0);
    });
  });

  group('DhikrItem.matchesQuery', () {
    const item = DhikrItem(
      id: 'x',
      text: 'الله لا إلـه إلا هو الحي القيوم',
      reference: 'آية الكرسى - البقرة 255',
      description: 'من قالها حين يصبح أجير من الجن',
    );

    test('finds text whatever the spelling of the query', () {
      expect(item.matchesQuery('إله'), isTrue);
      expect(item.matchesQuery('اله'), isTrue);
      expect(item.matchesQuery('اللَّهُ'), isTrue);
    });

    test('finds a reference by its Arabic-Indic number', () {
      expect(item.matchesQuery('٢٥٥'), isTrue);
      expect(item.matchesQuery('الكرسي'), isTrue);
    });

    test('needs every word, in any order', () {
      expect(item.matchesQuery('القيوم الحي'), isTrue);
      expect(item.matchesQuery('القيوم الرحيم'), isFalse);
    });

    test('a query of punctuation alone matches everything', () {
      expect(item.matchesQuery(' ... '), isTrue);
    });
  });

  group('DhikrItem.isRemindable', () {
    test('needs a count and a short enough text', () {
      expect(const DhikrItem(id: 'a', text: 'سبحان الله').isRemindable, isTrue);
      expect(
        const DhikrItem(id: 'a', text: 'سبحان الله', count: 0).isRemindable,
        isFalse,
      );
      expect(
        DhikrItem(id: 'a', text: 'ا' * (dhikrReminderMaxChars + 1))
            .isRemindable,
        isFalse,
      );
      expect(
        DhikrItem(id: 'a', text: 'ا' * dhikrReminderMaxChars).isRemindable,
        isTrue,
      );
    });

    test('reading material about dhikr is never a reminder', () {
      expect(
        const DhikrItem(
          id: 'a',
          text: 'قصير',
          tags: <DhikrTag>[DhikrTag.virtueOfDua],
        ).isRemindable,
        isFalse,
      );
    });
  });
}
