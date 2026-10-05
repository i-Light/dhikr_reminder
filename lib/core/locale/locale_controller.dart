import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localePrefsKey = 'dhikr_reminder.locale';

/// Arabic (Egyptian) is the app's own language; `ar_EG` resolves to the `ar`
/// strings, which are already written in Egyptian dialect.
const _arabic = Locale('ar', 'EG');
const _english = Locale('en');

/// Which language the whole app — settings, library, tray menu, reminder — is
/// shown in. Starts Arabic and remembers the person's choice across launches.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    unawaited(_loadPersisted());
    return _arabic;
  }

  bool get isEnglish => state.languageCode == 'en';

  /// Flips between Arabic and English.
  Future<void> toggle() async {
    state = isEnglish ? _arabic : _english;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localePrefsKey, state.languageCode);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to save the language choice.',
        name: 'dhikr_reminder.locale',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_localePrefsKey) == 'en') state = _english;
    } catch (_) {
      // Keeps the Arabic default.
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
