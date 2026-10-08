import 'package:dhikr_reminder/features/library/data/dhikr_library_data.dart';
import 'package:dhikr_reminder/features/library/domain/arabic_text.dart';
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
