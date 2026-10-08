// Turns the scraped azkar file into the app's library data.
//
// The scraped file (tool/data/zekrel_scraped.json) is a list of sections, each
// one `[title, entry, entry, ...]`, where an entry has `subtitle`, `text`,
// `reference`, `benefit` and `count`. This file cleans every field, folds the
// same dhikr that appears in two sections (the morning and the evening ones)
// into one entry carrying both tags, and writes the result as Dart.
//
// Pure Dart with no Flutter import, so `dart run tool/generate_library.dart`
// can use it and test/tool/library_builder_test.dart can check it.
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dhikr_reminder/features/library/domain/arabic_text.dart';

/// The group each section of the scraped file becomes, by the section's title
/// (normalised, so its vowels and spelling do not matter). A title that is not
/// here stops the build: a new section needs a decision, not a silent guess.
const Map<String, String> sectionTags = <String, String>{
  'اذكار الصباح': 'morning',
  'اذكار المساء': 'evening',
  'اذكار بعد السلام من الصلاه المفروضه': 'afterPrayer',
  'تسابيح': 'tasabih',
  'اذكار النوم والاحلام': 'sleep',
  'اذكار الاستيقاظ من النوم': 'waking',
  'اذكار الصلاه': 'prayer',
  'جوامع الدعاء': 'jawamiDuas',
  'ادعيه النبي صلي الله عليه وسلم': 'propheticDuas',
  'الادعيه القرانيه': 'quranicDuas',
  'ادعيه الانبياء من القران الكريم': 'prophetsDuas',
  'اذكار متفرقه': 'misc',
  'اذكار عند سماع الاذان': 'adhan',
  'اذكار المسجد': 'mosque',
  'اذكار الوضوء': 'wudu',
  'اذكار دخول وخروج المنزل': 'home',
  'اذكار دخول وخروج الخلاء': 'khalaa',
  'اذكار الطعام والشراب والضيف': 'food',
  'اذكار الحج والعمره': 'hajjUmrah',
  'دعاء ختم القران الكريم': 'khatmQuran',
  'فضل الدعاء': 'virtueOfDua',
  'فضل الذكر': 'virtueOfDhikr',
  'فضائل السور': 'virtueOfSuras',
  'فضائل القران': 'virtueOfQuran',
  'ادعيه للميت': 'duasForDeceased',
  'الرقيه الشرعيه من القران والسنه': 'ruqyah',
};

final Map<String, String> _tagByNormalizedTitle = <String, String>{
  for (final entry in sectionTags.entries)
    normalizeArabic(entry.key): entry.value,
};

/// Groups whose entries are a quoted dua, quotation marks and all, in the
/// source. The marks are dropped; the dua is not speech inside a sentence.
const Set<String> _quotedDuaTags = <String>{'quranicDuas', 'prophetsDuas'};

/// One entry as the library holds it.
class BuiltItem {
  BuiltItem({
    required this.id,
    required this.text,
    required this.count,
    required this.tags,
    this.subtitle,
    this.reference,
    this.description,
  });

  final String id;
  final String text;
  final int count;
  final List<String> tags;
  String? subtitle;
  String? reference;
  String? description;
}

/// Everything [buildLibrary] produced, and what it noticed on the way.
class BuildReport {
  BuildReport({
    required this.items,
    required this.rawCount,
    required this.merged,
    required this.conflicts,
  });

  final List<BuiltItem> items;

  /// Entries in the scraped file, before the same dhikr in two sections was
  /// folded into one.
  final int rawCount;

  /// How many entries were folded into an earlier one.
  final int merged;

  /// Merged entries whose two sources disagreed about a field, and which won.
  final List<String> conflicts;
}

final RegExp _invisible = RegExp(
  '[\\u0640\\u200B-\\u200F\\u202A-\\u202E\\u2066-\\u2069\\uFEFF]',
);

/// [raw] as it should be shown: no kashida or bidi marks, `*` list markers
/// turned into line breaks, one space between words, and the spacing of Arabic
/// punctuation set right (no space before a comma or colon).
String cleanText(String raw) {
  var s = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  s = s.replaceAll(_invisible, '');
  s = s.replaceAll(RegExp(r'\s*\*\s*'), '\n');
  s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
  s = s.replaceAll(RegExp(r' ?\n ?'), '\n');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  s = s.replaceAllMapped(
    RegExp(r'[ \t]+([،؛؟!:.,;])'),
    (m) => m[1]!,
  );
  s = s.replaceAllMapped(
    RegExp(r'([ء-يٱ-ۓ\)\]]),'),
    (m) => '${m[1]}،',
  );
  return s.trim();
}

/// A lead-in line: [cleanText], without the full stop the source ends it with
/// and without quotation marks around the whole of it.
String cleanSubtitle(String raw) {
  var s = cleanText(raw).replaceAll(RegExp(r'[\s.]+$'), '');
  if (s.length > 1 && s.startsWith('"') && s.endsWith('"')) {
    s = s.substring(1, s.length - 1).trim();
  }
  return s;
}

/// A source line without the brackets and dots the scraper left around it:
/// `. [البقرة - 201].` becomes `البقرة - 201`. The card puts the brackets back.
String cleanReference(String raw) {
  var s = cleanText(raw);
  s = s.replaceAll(RegExp(r'^[\s.]+'), '').replaceAll(RegExp(r'[\s.]+$'), '');
  if (s.startsWith('[') && s.endsWith(']')) {
    s = s.substring(1, s.length - 1).trim();
  }
  return s;
}

String _unquote(String s) {
  var out = s.replaceAll(RegExp(r'"\s+"'), '\n');
  if (out.length > 1 &&
      out.startsWith('"') &&
      out.endsWith('"') &&
      out.indexOf('"', 1) == out.length - 1) {
    out = out.substring(1, out.length - 1).trim();
  }
  return out.replaceAll(RegExp(r' *\n *'), '\n');
}

/// The id of an entry: a short hash of the words and the count, so it does not
/// move when the list is reordered or something is added in the middle.
String itemId(String text, int count) {
  final digest = sha1.convert(utf8.encode('${normalizeArabic(text)}|$count'));
  return 'd${digest.toString().substring(0, 10)}';
}

/// Parses the scraped file. It is a run of `[...]` arrays separated by commas
/// but not wrapped in an outer one, so that is added when it does not parse as
/// it is.
List<List<dynamic>> parseScraped(String source) {
  final text = source.replaceFirst('﻿', '').trim();
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    final withoutTrailingComma =
        text.endsWith(',') ? text.substring(0, text.length - 1) : text;
    decoded = jsonDecode('[$withoutTrailingComma]');
  }
  if (decoded is! List) {
    throw const FormatException('The scraped file is not a list of sections.');
  }
  return [
    for (final section in decoded)
      if (section is List) section,
  ];
}

/// Builds the library from the sections of the scraped file.
BuildReport buildLibrary(List<List<dynamic>> sections) {
  final byKey = <String, BuiltItem>{};
  final ordered = <BuiltItem>[];
  final conflicts = <String>[];
  var rawCount = 0;
  var merged = 0;

  for (final section in sections) {
    final title = section.first as String;
    final tag = _tagByNormalizedTitle[normalizeArabic(title)];
    if (tag == null) {
      throw FormatException('No group is set for the section "$title".');
    }

    for (final raw in section.skip(1)) {
      final entry = (raw as Map).cast<String, dynamic>();
      rawCount++;

      var text = cleanText(entry['text'] as String? ?? '');
      var subtitle = cleanSubtitle(entry['subtitle'] as String? ?? '');
      var reference = cleanReference(entry['reference'] as String? ?? '');
      var description = cleanText(entry['benefit'] as String? ?? '');
      final count =
          int.tryParse((entry['count'] as String? ?? '1').trim()) ?? 1;

      if (_quotedDuaTags.contains(tag)) text = _unquote(text);

      // "اللهم" is the first word of the dua, split off by the scraper.
      if (subtitle == 'اللهم') {
        text = '$subtitle $text';
        subtitle = '';
      }

      // In these two groups the scraper put something else in `benefit`.
      if (tag == 'propheticDuas' && description.isNotEmpty) {
        reference = cleanReference(description);
        description = '';
      } else if (tag == 'prophetsDuas' && description.isNotEmpty) {
        subtitle = cleanSubtitle(description)
            .replaceAll('علية', 'عليه');
        description = '';
      }

      if (text.isEmpty) {
        throw FormatException('An entry in "$title" has no text.');
      }

      final key = '${normalizeArabic(text)}|$count';
      final existing = byKey[key];
      if (existing != null) {
        merged++;
        if (!existing.tags.contains(tag)) existing.tags.add(tag);
        existing.subtitle =
            _pick(existing.subtitle, subtitle, 'subtitle', text, conflicts);
        existing.reference =
            _pick(existing.reference, reference, 'reference', text, conflicts);
        existing.description = _pick(
          existing.description,
          description,
          'description',
          text,
          conflicts,
        );
        continue;
      }

      final item = BuiltItem(
        id: itemId(text, count),
        text: text,
        count: count,
        tags: <String>[tag],
        subtitle: subtitle.isEmpty ? null : subtitle,
        reference: reference.isEmpty ? null : reference,
        description: description.isEmpty ? null : description,
      );
      byKey[key] = item;
      ordered.add(item);
    }
  }

  return BuildReport(
    items: ordered,
    rawCount: rawCount,
    merged: merged,
    conflicts: conflicts,
  );
}

String? _pick(
  String? kept,
  String incoming,
  String field,
  String text,
  List<String> conflicts,
) {
  if (incoming.isEmpty) return kept;
  if (kept == null || kept.isEmpty) return incoming;
  if (normalizeArabic(kept) != normalizeArabic(incoming)) {
    conflicts.add('$field differs for "${_preview(text)}": kept "$kept", '
        'dropped "$incoming"');
  }
  return kept;
}

String _preview(String text) =>
    text.length <= 40 ? text : '${text.substring(0, 40)}...';

String _literal(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n');
  return "'$escaped'";
}

/// The Dart source of the library: one `const` list.
String emitDart(List<BuiltItem> items) {
  final out = StringBuffer()
    ..writeln('// GENERATED CODE, DO NOT EDIT BY HAND.')
    ..writeln('//')
    ..writeln('// Written by `dart run tool/generate_library.dart` from')
    ..writeln('// tool/data/zekrel_scraped.json.')
    ..writeln()
    ..writeln(
      "import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';",
    )
    ..writeln()
    ..writeln('const List<DhikrItem> dhikrLibraryData = <DhikrItem>[');
  for (final item in items) {
    out
      ..writeln('  DhikrItem(')
      ..writeln('    id: ${_literal(item.id)},')
      ..writeln('    text: ${_literal(item.text)},');
    if (item.subtitle != null) {
      out.writeln('    subtitle: ${_literal(item.subtitle!)},');
    }
    if (item.reference != null) {
      out.writeln('    reference: ${_literal(item.reference!)},');
    }
    if (item.description != null) {
      out.writeln('    description: ${_literal(item.description!)},');
    }
    if (item.count != 1) out.writeln('    count: ${item.count},');
    out
      ..writeln(
        '    tags: <DhikrTag>[${item.tags.map((t) => 'DhikrTag.$t').join(', ')}],',
      )
      ..writeln('  ),');
  }
  out.writeln('];');
  return out.toString();
}
