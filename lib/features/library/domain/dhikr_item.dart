import 'package:dhikr_reminder/features/library/domain/arabic_text.dart';
import 'package:flutter/foundation.dart';

export 'package:dhikr_reminder/features/library/domain/arabic_text.dart'
    show stripTashkeel;

/// Every group/tag an azkar entry can belong to: the buttons the library's
/// filter popup is a gallery of.
///
/// The emoji is the tag's identity in that gallery: a word-less, script-less
/// marker that renders the same on Windows (Segoe UI Emoji) and on Android/
/// iOS, so a button reads at a glance whatever the locale. The Arabic label
/// next to it comes from `AppLocalizations`, see `dhikrTagLabel` in the
/// presentation layer, which keeps this enum free of any l10n dependency.
///
/// An entry may carry more than one tag (the same dhikr is said in the morning
/// and in the evening); [DhikrItem.tags] is the list, and a filter matches if
/// *any* of the selected tags is on it.
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
  duasForDeceased('🤍'),
  ruqyah('🛡️');

  const DhikrTag(this.emoji);

  /// The pictograph shown on the tag's filter button.
  final String emoji;
}

/// Groups that are reading material about dhikr, not something to say, so an
/// entry carrying one can be read in the library but never becomes a reminder.
const Set<DhikrTag> _readingOnlyTags = <DhikrTag>{
  DhikrTag.virtueOfDua,
  DhikrTag.virtueOfDhikr,
  DhikrTag.virtueOfSuras,
  DhikrTag.virtueOfQuran,
};

/// The longest text that still fits a reminder card on a phone at a size that
/// can be read. Longer entries stay in the library for reading.
const int dhikrReminderMaxChars = 500;

/// The search text of each item, normalised once. [DhikrItem] is `const`, so
/// the cache lives beside it.
final Expando<String> _searchText = Expando<String>('dhikr search text');

/// One entry in the azkar library: the dhikr text itself, plus up to three
/// optional layers around it (see the field docs) and the tags that place it
/// in the filter gallery.
///
/// Immutable and `const`-constructible so the whole dataset
/// (`data/dhikr_library_data.dart`) can be a compile-time `const` list: no
/// parse cost on first open, and the search/filter over it is a plain list
/// walk.
@immutable
class DhikrItem {
  const DhikrItem({
    required this.id,
    required this.text,
    this.subtitle,
    this.reference,
    this.description,
    this.count = 1,
    this.tags = const <DhikrTag>[],
  });

  /// Stable across edits of the dataset, so a reminder that points at this
  /// entry keeps pointing at it after the list is reordered or added to. Made
  /// from the words of the dhikr (see `tool/generate_library.dart`), never from
  /// its position.
  final String id;

  /// The dhikr itself.
  final String text;

  /// A short lead-in above the text (the occasion a dhikr belongs to, or whose
  /// dua it is). Optional, most entries have none.
  final String? subtitle;

  /// Where the text comes from when it is a specific ayah or a named source:
  /// "البقرة - 201", "رواه البخاري". Rendered at the end of the text as grey
  /// text in square brackets (the caller adds the brackets).
  final String? reference;

  /// An optional note *about* the dhikr: its virtue, when it is said, what it
  /// answers. Shown below the text, apart from [subtitle], which leads in.
  final String? description;

  /// How many times it is said, as the sources give it. 0 marks reading
  /// material that is not said at all and so cannot be counted.
  final int count;

  /// The groups this entry belongs to. Empty is allowed and simply means the
  /// entry only ever shows up unfiltered.
  final List<DhikrTag> tags;

  bool get hasReference => reference != null && reference!.trim().isNotEmpty;

  /// Whether this entry can be added to the reminders: something to say and
  /// count, short enough for the reminder card.
  bool get isRemindable =>
      count > 0 &&
      text.length <= dhikrReminderMaxChars &&
      !tags.any(_readingOnlyTags.contains);

  /// Whether this entry should be shown for [active] tags. An empty [active]
  /// set means "no filter" and matches everything; otherwise the entry
  /// matches if it shares at least one tag with the selection.
  bool matchesTags(Set<DhikrTag> active) {
    if (active.isEmpty) return true;
    return tags.any(active.contains);
  }

  /// Whether this entry satisfies a free-text [query]. Matching ignores
  /// vowels, kashida, punctuation and the usual spelling variants (see
  /// [normalizeArabic]) and looks at the text, subtitle, reference and
  /// description, so typing `الله` finds `اللَّه`, `رحمه` finds `رحمة`, and a
  /// surah name finds every ayah that cites it. Every word of the query has to
  /// appear, in any order. A blank query matches everything.
  bool matchesQuery(String query) {
    final needle = normalizeArabic(query);
    if (needle.isEmpty) return true;
    final haystack = _searchText[this] ??= normalizeArabic(
      [text, subtitle ?? '', reference ?? '', description ?? ''].join(' '),
    );
    return needle.split(' ').every(haystack.contains);
  }
}
