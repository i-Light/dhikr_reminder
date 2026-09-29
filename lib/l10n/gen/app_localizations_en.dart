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
  String get settingsDhikrSoundLabel => 'Sound';

  @override
  String get settingsDhikrSoundSubtitle =>
      'Play a sound when a reminder pops up';

  @override
  String get settingsDhikrUseChanceLabel => 'Weighted chance';

  @override
  String get settingsDhikrUseChanceSubtitle =>
      'Off: every dhikr is equally likely. On: set how often each one comes up';

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

  @override
  String get trayOpenApp => 'Open app';

  @override
  String get trayNextDhikr => 'Next dhikr';

  @override
  String trayNextDhikrIn(String time) {
    return 'in $time';
  }

  @override
  String get trayNextDhikrPending => 'Waiting for settings';

  @override
  String get traySoundOn => 'Sound on';

  @override
  String get traySoundOff => 'Sound off';

  @override
  String get trayQuit => 'Close app';

  @override
  String get updateTitle => 'Updates';

  @override
  String get updateSubtitle => 'Keep Dhikr Reminder up to date';

  @override
  String updateVersion(String version) {
    return 'Version $version';
  }

  @override
  String get updateNeverChecked => 'Not checked yet';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateUpToDate => 'You\'re up to date';

  @override
  String updateLastChecked(String time) {
    return 'Last checked $time';
  }

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateAvailableManual =>
      'This copy was not installed with the setup program, so it cannot update itself. Download the new setup from the releases page.';

  @override
  String get updateAvailableAutoOff =>
      'Automatic updates are off. Press Update now to install it.';

  @override
  String updateDownloading(String version) {
    return 'Downloading version $version…';
  }

  @override
  String updateReady(String version) {
    return 'Version $version is ready to install';
  }

  @override
  String get updateReadyHint =>
      'It installs by itself once this window is closed and no reminder is showing.';

  @override
  String updateInstalling(String version) {
    return 'Installing version $version…';
  }

  @override
  String get updateFailed => 'Couldn\'t check for updates';

  @override
  String get updateFailedHint =>
      'Check your connection. It will try again shortly.';

  @override
  String get updateCheckButton => 'Check for updates';

  @override
  String get updateInstallButton => 'Update now';

  @override
  String get updateRestartButton => 'Restart and update';

  @override
  String get updateDownloadPageButton => 'Open download page';

  @override
  String get updateAutoLabel => 'Update automatically';

  @override
  String get updateAutoSubtitle =>
      'Download new versions in the background and install them when the app is idle';
}
