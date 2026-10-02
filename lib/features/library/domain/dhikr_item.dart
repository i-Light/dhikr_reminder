import 'package:flutter/foundation.dart';

/// Every group/tag an azkar entry can belong to — the buttons the library's
/// filter popup is a gallery of.
///
/// The emoji is the tag's identity in that gallery: a word-less, script-less
/// marker that renders the same on Windows (Segoe UI Emoji) and on Android/
/// iOS, so a button reads at a glance whatever the locale. The Arabic label
/// next to it comes from `AppLocalizations` — see `dhikrTagLabel` in the
/// presentation layer, which keeps this enum free of any l10n dependency.
///
/// An entry may carry more than one tag (e.g. an ayah that belongs to both
/// the morning adhkar and the Quranic-dua collection); [DhikrItem.tags] is
/// the list, and a filter matches if *any* of the selected tags is on it.
enum DhikrTag {
  morning('🌅'),
  evening('🌇'),
  afterPrayer('🧎'),
  tasabih('📿'),
  sleep('🌙'),
  waking('☀️'),
  prayer('🤲'),
  jawamiDuas('✨'),
  propheticDuas('🕊️'),
  quranicDuas('📖'),
  prophetsDuas('🌟'),
  misc('🗂️'),
  adhan('🔊'),
  mosque('🕌'),
  wudu('💧'),
  home('🏠'),
  khalaa('🚪'),
  food('🍽️'),
  hajjUmrah('🕋'),
  khatmQuran('📗'),
  virtueOfDua('💫'),
  virtueOfDhikr('💚'),
  virtueOfSuras('📜'),
  virtueOfQuran('📚'),
  asmaAllah('🌈'),
  duasForDeceased('🤍'),
  ruqyah('🛡️');

  const DhikrTag(this.emoji);

  /// The pictograph shown on the tag's filter button.
  final String emoji;
}

/// The Arabic diacritics (tashkeel) — harakat, tanwin, shadda, superscript
/// alef, and the Quranic annotation marks — stripped by [stripTashkeel].
///
/// Deliberately *not* including U+0640 (tatweel/kashida): that is a letter
/// elongation, not a vowel, so removing it would change how a word is
/// spelled rather than just how it is vocalised.
final RegExp _tashkeelPattern = RegExp(
  '['
  '\u0610-\u061A' // honorifics and Quranic signs
  '\u064B-\u065F' // harakat, tanwin, shadda, sukun, etc.
  '\u0670' // superscript alef
  '\u06D6-\u06DC' // Quranic pause/annotation marks
  '\u06DF-\u06E4'
  '\u06E7-\u06E8'
  '\u06EA-\u06ED'
  ']',
);

/// [text] with every [DhikrTag]-relevant diacritic removed — the "show
/// tashkeel" toggle's off state. A pure formatting change: the letters
/// themselves are untouched, so the same word reads the same, just without
/// its vowels.
String stripTashkeel(String text) => text.replaceAll(_tashkeelPattern, '');

/// One entry in the azkar library: the dhikr text itself, plus up to three
/// optional layers around it (see the field docs) and the tags that place it
/// in the filter gallery.
///
/// Immutable and `const`-constructible so the whole dataset
/// (`data/dhikr_library.dart`) can be a compile-time `const` list — no parse
/// cost on first open, and the search/filter over it is a plain list walk.
@immutable
class DhikrItem {
  const DhikrItem({
    required this.id,
    required this.text,
    this.subtitle,
    this.reference,
    this.description,
    this.tags = const <DhikrTag>[],
  });

  /// Stable across edits of the dataset, so a widget key and any future
  /// bookmark/persistence survive the list being reordered or added to.
  final String id;

  /// The dhikr itself, fully vocalised. Rendered as-is with tashkeel on, and
  /// through [stripTashkeel] with it off.
  final String text;

  /// A short lead-in above the text (e.g. "تُقال ثلاثاً" or the occasion a
  /// dhikr belongs to). Optional — most entries have none.
  final String? subtitle;

  /// Where the text comes from when it is a specific ayah or a named source
  /// — "البقرة: ٢٥٥", "رواه البخاري". Rendered at the end of the text as grey
  /// text in square brackets (the caller adds the brackets).
  final String? reference;

  /// An optional note *about* the dhikr — its virtue, when it is said, what
  /// it answers — below the text. Distinct from [subtitle], which leads in.
  final String? description;

  /// The groups this entry belongs to. Empty is allowed and simply means the
  /// entry only ever shows up unfiltered.
  final List<DhikrTag> tags;

  bool get hasReference => reference != null && reference!.trim().isNotEmpty;

  /// Whether this entry should be shown for [active] tags. An empty [active]
  /// set means "no filter" and matches everything; otherwise the entry
  /// matches if it shares at least one tag with the selection.
  bool matchesTags(Set<DhikrTag> active) {
    if (active.isEmpty) return true;
    return tags.any(active.contains);
  }

  /// Whether this entry satisfies a free-text [query] — matched
  /// tashkeel-insensitively against the text, subtitle, reference and
  /// description, so typing `الله` finds a vocalised `اللَّه`, and a surah
  /// name finds every ayah that cites it. A blank query matches everything.
  bool matchesQuery(String query) {
    final needle = stripTashkeel(query.trim());
    if (needle.isEmpty) return true;
    final haystack = stripTashkeel(
      [text, subtitle ?? '', reference ?? '', description ?? ''].join(' '),
    );
    return haystack.contains(needle);
  }
}
