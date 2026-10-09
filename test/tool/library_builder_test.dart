import 'dart:io';

import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/library_builder.dart';

const _tatweel = 'ـ';
final _rlm = String.fromCharCode(0x200F);

Map<String, String> _entry({
  String subtitle = '',
  required String text,
  String reference = '',
  String benefit = '',
  String count = '01',
}) =>
    {
      'subtitle': subtitle,
      'text': text,
      'reference': reference,
      'benefit': benefit,
      'count': count,
    };

void main() {
  group('cleanText', () {
    test('removes kashida and bidi marks', () {
      expect(cleanText('اللهـم$_rlm إنـي'), 'اللهم إني');
    });

    test('fixes the spacing of Arabic punctuation', () {
      expect(cleanText('الله ، لا إله ، إلا هو .'), 'الله، لا إله، إلا هو.');
      expect(cleanText('قال : ادعو'), 'قال: ادعو');
    });

    test('turns an ASCII comma after an Arabic letter into an Arabic one', () {
      expect(cleanText('بارك لنا فيه, وزدنا منه'), 'بارك لنا فيه، وزدنا منه');
    });

    test('turns star markers into line breaks', () {
      expect(cleanText('* أولا * ثانيا'), 'أولا\nثانيا');
      expect(cleanText('رحمة * اللهم'), 'رحمة\nاللهم');
    });

    test('collapses spaces and blank lines', () {
      expect(cleanText('  كلمة   كلمة  '), 'كلمة كلمة');
      expect(cleanText('أ\n\n\n\nب'), 'أ\n\nب');
    });
  });

  group('cleanReference', () {
    test('strips the brackets and dots the scraper left', () {
      expect(cleanReference('[آية الكرسى - البقرة 255].'),
          'آية الكرسى - البقرة 255');
      expect(cleanReference('. [البقرة - 201].'), 'البقرة - 201');
      expect(cleanReference('رواه مسلم (1084) عن أبي هريرة.'),
          'رواه مسلم (1084) عن أبي هريرة');
      expect(cleanReference(''), '');
    });
  });

  group('cleanSubtitle', () {
    test('drops the final full stop and the quotes around the line', () {
      expect(cleanSubtitle('"واذكروا الله في أيام معدودات ".'),
          'واذكروا الله في أيام معدودات');
    });
  });

  group('buildLibrary', () {
    List<List<dynamic>> sections(List<List<dynamic>> s) => s;

    test('merges the same dhikr from two sections into one with both tags', () {
      final report = buildLibrary(sections([
        [
          'أذكار الصباح',
          _entry(text: 'اللهـم أنت ربي', benefit: 'فضل', count: '03'),
        ],
        [
          'أذكار المساء',
          _entry(text: 'اللهم أنت ربي.', count: '03'),
        ],
      ]));

      expect(report.rawCount, 2);
      expect(report.merged, 1);
      expect(report.items, hasLength(1));
      expect(report.items.single.tags, ['morning', 'evening']);
      expect(report.items.single.description, 'فضل');
      expect(report.items.single.count, 3);
    });

    test(
        'keeps the same words apart when they are said a different number '
        'of times', () {
      final report = buildLibrary(sections([
        ['تسابيح', _entry(text: 'سبحان الله', count: '100')],
        ['أذكار النوم والأحلام', _entry(text: 'سبحان الله', count: '33')],
      ]));

      expect(report.items, hasLength(2));
      expect(report.items.map((i) => i.id).toSet(), hasLength(2));
    });

    test('puts a split-off "اللهم" back at the start of the dua', () {
      final report = buildLibrary(sections([
        [
          'جوامع الدعاء',
          _entry(subtitle: 'اللهم', text: 'اغفر لي ذنوبي'),
        ],
      ]));

      expect(report.items.single.text, 'اللهم اغفر لي ذنوبي');
      expect(report.items.single.subtitle, isNull);
    });

    test('moves the source of a prophetic dua from benefit to reference', () {
      final report = buildLibrary(sections([
        [
          'أدعية النَّبِيِّ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ',
          _entry(
              text: 'اللهم اغفر لي', benefit: 'رواه البخاري (834) عن أبي بكر.'),
        ],
      ]));

      expect(report.items.single.reference, 'رواه البخاري (834) عن أبي بكر');
      expect(report.items.single.description, isNull);
    });

    test('turns the prophet named in benefit into the lead-in', () {
      final report = buildLibrary(sections([
        [
          'أدعية الأنبياء من القرآن الكريم',
          _entry(
            text: '"ربنا ظلمنا أنفسنا"',
            reference: '. [الأعراف - 23].',
            benefit: 'آدم علية السلام.',
          ),
        ],
      ]));

      final item = report.items.single;
      expect(item.text, 'ربنا ظلمنا أنفسنا');
      expect(item.subtitle, 'آدم عليه السلام');
      expect(item.reference, 'الأعراف - 23');
      expect(item.tags, ['prophetsDuas']);
    });

    test('splits several quoted duas onto lines and drops the quotes', () {
      final report = buildLibrary(sections([
        [
          'الْأدْعِيَةُ القرآنية',
          _entry(text: '"رب اغفر لي" " رب إني أعوذ بك"'),
        ],
      ]));

      expect(report.items.single.text, 'رب اغفر لي\nرب إني أعوذ بك');
    });

    test('a count of 00 stays 00 so the entry reads as not countable', () {
      final report = buildLibrary(sections([
        ['فضل الدعاء', _entry(text: 'الدعاء هو العبادة', count: '00')],
      ]));

      expect(report.items.single.count, 0);
    });

    test('stops at a section it has no group for', () {
      expect(
        () => buildLibrary(sections([
          ['قسم جديد', _entry(text: 'نص')],
        ])),
        throwsFormatException,
      );
    });

    test('stops at an entry with no words', () {
      expect(
        () => buildLibrary(sections([
          ['تسابيح', _entry(text: ' * ')],
        ])),
        throwsFormatException,
      );
    });

    test('ids depend on the words and the count, not on the position', () {
      final a = buildLibrary(sections([
        ['تسابيح', _entry(text: 'سبحان الله'), _entry(text: 'الله أكبر')],
      ]));
      final b = buildLibrary(sections([
        ['تسابيح', _entry(text: 'الله أكبر'), _entry(text: 'سبحان الله')],
      ]));

      expect(a.items.first.id, b.items.last.id);
      expect(a.items.last.id, b.items.first.id);
      expect(a.items.first.id, matches(RegExp(r'^d[0-9a-f]{10}$')));
    });
  });

  group('parseScraped', () {
    test('reads a run of arrays that is not wrapped in an outer one', () {
      final parsed =
          parseScraped('[\n "أ",\n {"text": "ب"}\n],\n[\n "ج"\n],\n');
      expect(parsed, hasLength(2));
      expect(parsed.first.first, 'أ');
    });

    test('reads a file that already is one array of sections', () {
      final parsed = parseScraped('[["أ", {"text": "ب"}], ["ج"]]');
      expect(parsed, hasLength(2));
    });
  });

  group('emitDart', () {
    test('escapes quotes, dollar signs, backslashes and line breaks', () {
      final report = buildLibrary([
        [
          'تسابيح',
          _entry(text: "it's \$5 \\ done\nnext"),
        ],
      ]);
      final source = emitDart(report.items);

      expect(source, contains(r"it\'s \$5 \\ done\nnext"));
    });

    test('leaves out fields an entry does not have', () {
      final report = buildLibrary([
        ['تسابيح', _entry(text: 'سبحان الله')],
      ]);
      final source = emitDart(report.items);

      expect(source, isNot(contains('subtitle:')));
      expect(source, isNot(contains('reference:')));
      expect(source, isNot(contains('description:')));
      expect(source, isNot(contains('count:')));
      expect(source, contains('DhikrTag.tasabih'));
    });

    test('says it is generated', () {
      expect(emitDart(const []), contains('GENERATED CODE'));
    });
  });

  group('the shipped library', () {
    test('is exactly what the generator makes of the scraped file', () {
      final scraped = File('tool/data/zekrel_scraped.json').readAsStringSync();
      final expected = emitDart(buildLibrary(parseScraped(scraped)).items);
      final shipped = File('lib/features/library/data/dhikr_library_data.dart')
          .readAsStringSync()
          .replaceAll('\r\n', '\n');

      // The shipped file is run through `dart format`, which only moves
      // whitespace and adds trailing commas, so compare without those.
      String bare(String source) => source
          .replaceAll(RegExp(r',(?=\s*[)\]])'), '')
          .replaceAll(RegExp(r'\s+'), '');

      expect(
        bare(shipped),
        bare(expected),
        reason: 'Run: dart run tool/generate_library.dart',
      );
    });

    test('has no kashida, bidi marks, star markers or loose spacing', () {
      for (final item in dhikrLibrary) {
        for (final field in [
          item.text,
          item.subtitle ?? '',
          item.reference ?? '',
          item.description ?? '',
        ]) {
          expect(field.contains(_tatweel), isFalse, reason: item.id);
          expect(field.contains(_rlm), isFalse, reason: item.id);
          expect(field.contains('*'), isFalse, reason: item.id);
          expect(field.contains('  '), isFalse, reason: item.id);
          expect(field, field.trim(), reason: item.id);
          expect(RegExp(' [،؛:]').hasMatch(field), isFalse, reason: item.id);
        }
      }
    });

    test('shows references without the brackets the card adds', () {
      for (final item in dhikrLibrary.where((i) => i.hasReference)) {
        expect(item.reference!.startsWith('['), isFalse, reason: item.id);
        expect(item.reference!.endsWith(']'), isFalse, reason: item.id);
        expect(item.reference!.endsWith('.'), isFalse, reason: item.id);
      }
    });

    test('keeps both the short dhikr and the long reading', () {
      final remindable = dhikrLibrary.where((i) => i.isRemindable).length;
      expect(remindable, greaterThan(150));
      expect(remindable, lessThan(dhikrLibrary.length));
      expect(dhikrLibrary.any((i) => i.count == 0), isTrue);
    });
  });
}
