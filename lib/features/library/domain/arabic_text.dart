/// Arabic text helpers shared by the library's search, by matching a saved
/// dhikr to its library entry, by the request guards and by the generator in
/// `tool/`.
///
/// Pure Dart on purpose (no Flutter import), so `dart run tool/...` can use it.
library;

/// The Arabic diacritics (tashkeel): harakat, tanwin, shadda, superscript
/// alef, and the Quranic annotation marks. [stripTashkeel] removes them.
///
/// Deliberately *not* including U+0640 (tatweel/kashida): that is a letter
/// elongation, not a vowel, so removing it would change how a word is
/// spelled rather than just how it is vocalised. [normalizeArabic] removes it
/// separately, where only the letters matter.
final RegExp _tashkeelPattern = RegExp(
  '['
  '\u0610-\u061A' // honorifics and Quranic signs
  '\u064B-\u065F' // harakat, tanwin, shadda, sukun, etc.
  '\u0670' // superscript alef
  '\u06D6-\u06DC' // Quranic pause/annotation marks
  '\u06DF-\u06E6' // more Quranic marks, incl. the small waw and yeh
  '\u06E7-\u06E8'
  '\u06EA-\u06ED'
  ']',
);

/// Characters that take up no room on screen and only get in the way of
/// comparing text: tatweel, zero-width characters, and the bidi controls that
/// copied-and-pasted Arabic carries around.
final RegExp _invisiblePattern = RegExp(
  '[\u0640\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]',
);

final RegExp _alefVariants = RegExp('[\u0623\u0625\u0622\u0671]');
final RegExp _arabicIndicDigits = RegExp('[\u0660-\u0669\u06F0-\u06F9]');
final RegExp _notLetterOrDigit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
final RegExp _letterPattern = RegExp(r'\p{L}', unicode: true);

/// [text] with every diacritic removed: the "show tashkeel" toggle's off
/// state. A pure formatting change, the letters themselves are untouched, so
/// the same word reads the same, just without its vowels.
String stripTashkeel(String text) => text.replaceAll(_tashkeelPattern, '');

/// [text] reduced to what is being said, for comparing and searching: no
/// diacritics, tatweel or bidi marks; the different alefs, alef maqsura and
/// yeh, teh marbuta and heh, and the hamza carriers folded together;
/// Arabic-Indic digits turned into plain ones; every run of punctuation and
/// whitespace collapsed into one space.
///
/// Two spellings of the same dhikr come out identical, whether they were
/// written with vowels, with kashida, or with the other teh marbuta spelling.
String normalizeArabic(String text) {
  var out = stripTashkeel(text).replaceAll(_invisiblePattern, '');
  out = out
      .replaceAll(_alefVariants, '\u0627')
      .replaceAll('\u0649', '\u064A') // alef maqsura -> yeh
      .replaceAll('\u0629', '\u0647') // teh marbuta -> heh
      .replaceAll('\u0624', '\u0648') // waw with hamza -> waw
      .replaceAll('\u0626', '\u064A'); // yeh with hamza -> yeh
  out = out.replaceAllMapped(_arabicIndicDigits, (m) {
    final unit = m[0]!.codeUnitAt(0);
    final base = unit >= 0x06F0 ? 0x06F0 : 0x0660;
    return String.fromCharCode(0x30 + unit - base);
  });
  return out.toLowerCase().replaceAll(_notLetterOrDigit, ' ').trim();
}

/// How many diacritics [text] carries.
int tashkeelCount(String text) => _tashkeelPattern.allMatches(text).length;

/// How many Arabic letters [text] holds (diacritics and punctuation are not
/// counted).
int arabicLetterCount(String text) {
  var count = 0;
  for (final unit in text.runes) {
    if ((unit >= 0x0621 && unit <= 0x064A) ||
        (unit >= 0x0671 && unit <= 0x06D3)) {
      count++;
    }
  }
  return count;
}

/// How many letters of any script [text] holds.
int letterCount(String text) => _letterPattern.allMatches(text).length;
