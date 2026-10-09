import 'package:flutter/foundation.dart';

/// What to put on screen for one dhikr: its Arabic text, a transliteration
/// under it, or both. At least one of the two is always there.
@immutable
class DhikrDisplay {
  const DhikrDisplay({this.arabic, this.transliteration})
      : assert(arabic != null || transliteration != null);

  /// The Arabic text, or null when it was switched off and the transliteration
  /// stands alone.
  final String? arabic;

  /// The Latin-letter pronunciation, or null when it is off or this dhikr has
  /// none.
  final String? transliteration;

  bool get hasArabic => arabic != null;
  bool get hasTransliteration => transliteration != null;

  @override
  bool operator ==(Object other) =>
      other is DhikrDisplay &&
      other.arabic == arabic &&
      other.transliteration == transliteration;

  @override
  int get hashCode => Object.hash(arabic, transliteration);
}

/// Works out what a card shows for a dhikr, given the two switches.
///
/// The Arabic switch only ever hides the Arabic, never the transliteration. It
/// cannot leave a card empty either: a dhikr with no transliteration (or with
/// the transliteration switched off) keeps its Arabic whatever the Arabic
/// switch says.
DhikrDisplay resolveDhikrDisplay({
  required String arabic,
  required String? transliteration,
  required bool showTransliteration,
  required bool showArabic,
}) {
  final latin = showTransliteration &&
          transliteration != null &&
          transliteration.trim().isNotEmpty
      ? transliteration.trim()
      : null;
  return DhikrDisplay(
    arabic: showArabic || latin == null ? arabic : null,
    transliteration: latin,
  );
}
