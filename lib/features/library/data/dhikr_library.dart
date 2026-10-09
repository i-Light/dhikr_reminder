import 'package:dhikr_reminder/features/library/data/dhikr_english_data.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library_data.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_transliteration_data.dart';
import 'package:dhikr_reminder/features/library/domain/arabic_text.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_english.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

/// The azkar library's content, in the order the unfiltered list shows it.
///
/// Generated, not written by hand: `dart run tool/generate_library.dart` builds
/// `dhikr_library_data.dart` from the scraped file in `tool/data/`. It is plain
/// `const` data rather than a database or a JSON asset, so the library
/// screen's search and tag filter walk an in-memory list with nothing to parse
/// and nothing to load asynchronously.
const List<DhikrItem> dhikrLibrary = dhikrLibraryData;

final Map<String, DhikrItem> _byId = <String, DhikrItem>{
  for (final item in dhikrLibrary) item.id: item,
};

final Map<String, DhikrItem> _byNormalizedText = () {
  final map = <String, DhikrItem>{};
  for (final item in dhikrLibrary) {
    map.putIfAbsent(normalizeArabic(item.text), () => item);
  }
  return map;
}();

/// The library entry with [id], or null when this version of the app has none
/// (an id saved by a newer or older release).
DhikrItem? libraryItemById(String id) => _byId[id];

/// What goes under the Arabic of the library entry [id] in English: its
/// transliteration, or, for the entries that are explanations and not something
/// to say, their English translation. Null when it has neither (anything this
/// version of the app does not know).
String? libraryTransliteration(String? id) {
  if (id == null) return null;
  return dhikrTransliterations[id] ?? dhikrEnglishData[id]?.text;
}

/// The English lead-in, source and note of the library entry [id], or null when
/// it has none of them.
DhikrEnglish? libraryEnglish(String? id) =>
    id == null ? null : dhikrEnglishData[id];

final Expando<String> _englishSearchText = Expando<String>('english search');

String _latinKey(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r"[\u2018\u2019'`\-]"), '')
    .replaceAll(RegExp('[^a-z0-9\\u0600-\\u06FF]+'), ' ')
    .trim();

/// Whether [item] satisfies [query] in English: every word of the query has to
/// appear in its transliteration, English lead-in, source or note. Apostrophes
/// and hyphens are ignored, so "subhanallah" finds "Subhan-Allah".
bool libraryMatchesEnglishQuery(DhikrItem item, String query) {
  final needle = _latinKey(query);
  if (needle.isEmpty) return true;
  final haystack = _englishSearchText[item] ??= _latinKey(
    [
      libraryTransliteration(item.id) ?? '',
      libraryEnglish(item.id)?.subtitle ?? '',
      libraryEnglish(item.id)?.reference ?? '',
      libraryEnglish(item.id)?.description ?? '',
    ].join(' '),
  );
  return needle.split(' ').every(haystack.contains);
}

/// The library entry whose words are [text], whatever its vowels, kashida or
/// punctuation, or null when nothing in the library says exactly that.
DhikrItem? libraryItemForText(String text) =>
    _byNormalizedText[normalizeArabic(text)];

/// Whether the library's text is vowelled, so that the "show tashkeel" switch
/// has something to switch. A handful of Quranic marks in otherwise bare text
/// does not count: about one entry in twenty has to be properly vocalised.
final bool libraryHasTashkeel = () {
  var vocalised = 0;
  for (final item in dhikrLibrary) {
    final letters = arabicLetterCount(item.text);
    if (letters > 0 && tashkeelCount(item.text) / letters >= 0.3) vocalised++;
  }
  return vocalised * 20 >= dhikrLibrary.length;
}();
