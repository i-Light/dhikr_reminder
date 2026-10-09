import 'package:dhikr_reminder/core/locale/locale_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app is in English. Everything the library says around a dhikr
/// (its lead-in, its source, its note) is then in English, and every dhikr
/// comes with its transliteration under the Arabic.
final isEnglishProvider = Provider<bool>(
  (ref) => ref.watch(localeProvider).languageCode == 'en',
);

/// Whether dhikr are shown with a transliteration under the Arabic.
///
/// There is no switch for it: in English it is always on, in Arabic it is
/// never there. The switches the person does have only hide the Arabic, and
/// only exist in English (see `resolveDhikrDisplay`).
final showTransliterationProvider = Provider<bool>(
  (ref) => ref.watch(isEnglishProvider),
);
