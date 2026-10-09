import 'package:flutter/foundation.dart';

/// The English wording of one library entry's surroundings: everything about a
/// dhikr except the dhikr itself, which stays in Arabic (with its
/// transliteration under it).
///
/// Every field is optional. A missing one means "keep the Arabic": the entry has
/// none of that part, or the Arabic is the dhikr (see [dhikrLeadInPhrases]).
@immutable
class DhikrEnglish {
  const DhikrEnglish({
    this.subtitle,
    this.reference,
    this.description,
    this.text,
  });

  /// The lead-in above the dhikr ("Morning and evening", "Dua of Yunus").
  final String? subtitle;

  /// Where the dhikr comes from ("Al-Baqarah 255", "Narrated by Bukhari").
  final String? reference;

  /// The note about the dhikr: its virtue, when it is said.
  final String? description;

  /// The whole text in English, for the entries that are explanations rather
  /// than something to say (the virtue of a surah, the manners of ruqyah). It
  /// takes the place a transliteration has under a dhikr.
  final String? text;
}

/// The two phrases that lead many entries in. They are dhikr themselves, so
/// they are never translated: shown in Arabic while the Arabic is on, and as
/// their pronunciation when it is off.
const Map<String, String> dhikrLeadInPhrases = <String, String>{
  'بسم الله الرحمن الرحيم': 'Bismillahir-rahmanir-rahim',
  'أعوذ بالله من الشيطان الرجيم': "A'udhu billahi minash-shaytanir-rajim",
};

/// [leadIn] ready to show: with the Arabic switched off, the phrases in
/// [dhikrLeadInPhrases] give way to their pronunciation, so no Arabic is left on
/// the card.
String leadInFor(String leadIn, {required bool showArabic}) {
  if (showArabic) return leadIn;
  var result = leadIn;
  dhikrLeadInPhrases.forEach((arabic, latin) {
    result = result.replaceAll(arabic, latin);
  });
  return result;
}
