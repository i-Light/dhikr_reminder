import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/arabic_text.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/requests/domain/dhikr_request.dart';

/// The limits the app checks before it bothers the service. The service checks
/// all of them again (see server/src/core.mjs); these exist so an honest
/// mistake is caught on the phone, with a clear message, and costs nothing.
const int requestTextMin = 8;
const int requestTextMax = 600;
const int requestSourceMax = 120;
const int requestMaxLines = 12;

/// How many requests may be open at once, and how many may be made in a day.
const int requestMaxOpen = 3;
const int requestMaxPerDay = 5;

/// The shortest gap between two requests.
const Duration requestMinGap = Duration(seconds: 20);

/// How many requests the device remembers; the oldest finished ones go first.
const int requestMaxKept = 40;

/// Why some text cannot be sent as a request.
enum RequestTextProblem { tooShort, tooLong, notArabic, hasLink, repeated }

final RegExp _controls = RegExp(
  '[\\u0000-\\u0009\\u000B-\\u001F\\u007F-\\u009F\\u2028\\u2029'
  '\\u200B-\\u200F\\u202A-\\u202E\\u2066-\\u2069\\uFEFF]',
);
final RegExp _linkLike = RegExp(
  r'[<>`]|https?:|www\.|\w@\w|:\/\/|\{\{|javascript:',
  caseSensitive: false,
);

/// What the person typed with control and bidi characters taken out and the
/// spacing tidied: the form that is checked and sent.
String cleanRequestText(String raw) {
  return raw
      .replaceAll(RegExp(r'\r\n?'), '\n')
      .replaceAll(_controls, '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' ?\n ?'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// Why [cleaned] (already through [cleanRequestText]) cannot be a request, or
/// null when it can.
RequestTextProblem? checkRequestText(String cleaned) {
  final bare = stripTashkeel(cleaned);
  if (bare.length < requestTextMin) return RequestTextProblem.tooShort;
  if (bare.length > requestTextMax ||
      '\n'.allMatches(cleaned).length + 1 > requestMaxLines) {
    return RequestTextProblem.tooLong;
  }
  if (_linkLike.hasMatch(cleaned)) return RequestTextProblem.hasLink;
  final arabic = arabicLetterCount(bare);
  if (arabic < 6 || arabic / letterCount(bare).clamp(1, 1 << 30) < 0.6) {
    return RequestTextProblem.notArabic;
  }
  if (RegExp(r'(.)\1{5,}').hasMatch(bare.replaceAll(RegExp(r'\s+'), ''))) {
    return RequestTextProblem.repeated;
  }
  final symbols = bare.runes
      .where((r) => !RegExp(r'[\p{L}\p{N}\p{M}\s]', unicode: true)
          .hasMatch(String.fromCharCode(r)))
      .length;
  if (symbols / bare.runes.length > 0.4) return RequestTextProblem.repeated;
  return null;
}

/// The source line the person typed, kept short and on one line; null when
/// there is none. A link in it is a problem exactly as in the text.
String? cleanRequestSource(String raw) {
  final cleaned = cleanRequestText(raw).replaceAll('\n', ' ');
  if (cleaned.isEmpty) return null;
  return cleaned.length <= requestSourceMax
      ? cleaned
      : cleaned.substring(0, requestSourceMax);
}

/// Whether [source] would be refused (a link in the source line).
bool requestSourceHasLink(String? source) =>
    source != null && _linkLike.hasMatch(source);

/// The library entry [text] is already in, if it is: the same words, or
/// (for anything longer than a couple of words) the words as a part of one
/// entry or one entry as a part of the words.
DhikrItem? findInLibrary(String text) {
  final wanted = normalizeArabic(text);
  if (wanted.isEmpty) return null;
  final exact = libraryItemForText(text);
  if (exact != null) return exact;
  if (wanted.length < 14) return null;
  for (final item in dhikrLibrary) {
    final have = normalizeArabic(item.text);
    if (have.contains(wanted)) return item;
    if (have.length >= 14 && wanted.contains(have)) return item;
  }
  return null;
}

/// The person's own earlier request for the same words, if there is one that
/// has not been declined.
DhikrRequest? findOwnRequest(String text, Iterable<DhikrRequest> requests) {
  final wanted = normalizeArabic(text);
  for (final request in requests) {
    if (request.status == RequestStatus.declined) continue;
    if (normalizeArabic(request.text) == wanted) return request;
  }
  return null;
}
