import 'dart:async';
import 'dart:developer' as developer;

import 'package:dhikr_reminder/core/locale/locale_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _transliterationPrefsKey = 'dhikr_reminder.library.transliteration';

/// The person's own answer to "show the transliteration?", or null while they
/// have not given one. It is set from the library's settings popup and read by
/// the library cards and the reminder cards alike.
///
/// Null is kept apart from false on purpose: with no answer the app follows the
/// language (see [showTransliterationProvider]), and only an answer the person
/// gave sticks across a change of language.
class TransliterationChoiceNotifier extends Notifier<bool?> {
  @override
  bool? build() {
    unawaited(_loadPersisted());
    return null;
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(_transliterationPrefsKey);
      // A choice made while the read was still pending wins over the old one.
      if (stored != null && state == null) state = stored;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load the transliteration choice; following the language.',
        name: 'dhikr_reminder.library',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> choose(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_transliterationPrefsKey, value);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to persist the transliteration choice.',
        name: 'dhikr_reminder.library',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final transliterationChoiceProvider =
    NotifierProvider<TransliterationChoiceNotifier, bool?>(
  TransliterationChoiceNotifier.new,
);

/// Whether dhikr are shown with a transliteration under the Arabic.
///
/// On by default in English, off by default in Arabic, until the person picks
/// one in the library settings.
final showTransliterationProvider = Provider<bool>((ref) {
  final chosen = ref.watch(transliterationChoiceProvider);
  if (chosen != null) return chosen;
  return ref.watch(localeProvider).languageCode == 'en';
});
