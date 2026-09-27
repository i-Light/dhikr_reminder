// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dhikr Reminder';

  @override
  String get homeSubtitle =>
      'A dhikr pops up every few minutes — tap it out, then get back to work.';

  @override
  String get commonTestReminder => 'Show a reminder now';

  @override
  String get settingsDhikrTitle => 'Azkar Settings';

  @override
  String get settingsDhikrSubtitle =>
      'Change the zikr reminders frequency, volume, add, and remove azkar';

  @override
  String get settingsDhikrIntervalLabel => 'Reminder interval';

  @override
  String get settingsDhikrIntervalSubtitle =>
      'How often a reminder pops up, in minutes';

  @override
  String get settingsDhikrNameColumn => 'Dhikr';

  @override
  String get settingsDhikrAmountColumn => 'Amount';

  @override
  String get settingsDhikrChanceColumn => 'Chance';

  @override
  String get settingsDhikrChanceExplainer =>
      'Chance is a weight, not a percentage. An entry at 6 comes up twice as often as one at 3 — nothing more. Give every entry the same number and they are equally likely; set one to 0 and it never comes up at all. A single entry at 1 with everything else muted still comes up every time, because there is nothing else to compare it against.';

  @override
  String get settingsDhikrSaved => 'Azkar changes has been saved.';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get dhikrReminderTitle => 'Dhikr reminder';

  @override
  String get dhikrReminderTouchEverywhereTip => 'Touch anywhere to count';
}
