// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dhikr';

  @override
  String get splashDescription =>
      'A gentle dhikr reminder that lives in your tray.';

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
  String get trayPause => 'Pause for 1 hour';

  @override
  String get trayResume => 'Resume reminders';

  @override
  String trayPausedUntil(String time) {
    return 'Paused until $time';
  }

  @override
  String get settingsAutostartTitle => 'Start with Windows';

  @override
  String get settingsAutostartSubtitle =>
      'Open quietly in the tray when you sign in.';

  @override
  String get trayQuit => 'Close app';

  @override
  String get updateTitle => 'Updates';

  @override
  String get updateSubtitle => 'Keep Dhikr up to date';

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

  @override
  String get navSettings => 'Settings';

  @override
  String get statSession => 'Session';

  @override
  String get statToday => 'Today';

  @override
  String get homeNextReminder => 'Next reminder';

  @override
  String get homeCountedToday => 'Counted today';

  @override
  String get homeCountedSession => 'This session';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifSubtitle =>
      'Choose how often a dhikr reaches you, and which ones.';

  @override
  String get notifScheduleSection => 'Schedule';

  @override
  String get notifIntervalTitle => 'Remind me every';

  @override
  String notifIntervalMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get notifSoundTitle => 'Sound';

  @override
  String get notifSoundSubtitle => 'Play a sound when a reminder arrives';

  @override
  String get notifPriorityTitle => 'Favour some dhikr';

  @override
  String get notifPrioritySubtitle =>
      'Give each dhikr its own weight so some come up more often';

  @override
  String get notifMySection => 'My dhikr';

  @override
  String get notifAddDhikr => 'Add dhikr';

  @override
  String get notifEmptyTitle => 'No dhikr yet';

  @override
  String get notifEmptyHint => 'Add the dhikr you want to be reminded of.';

  @override
  String get notifEditTitle => 'Edit dhikr';

  @override
  String get notifNewTitle => 'New dhikr';

  @override
  String get notifNameLabel => 'Dhikr text';

  @override
  String get notifAmountLabel => 'Repetitions';

  @override
  String notifRepeatCount(int count) {
    return '$count times';
  }

  @override
  String get notifFrequencyLabel => 'How often it comes up';

  @override
  String get notifFrequencyNever => 'Never';

  @override
  String notifFrequencyValue(int value) {
    return '$value of 10';
  }

  @override
  String get notifFrequencyHint =>
      'A weight, not a percentage: 6 comes up twice as often as 3. 0 means never.';

  @override
  String get notifDeleted => 'Dhikr deleted';

  @override
  String get notifUndo => 'Undo';

  @override
  String get notifNameRequired => 'Write the dhikr first';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get notifGoalTitle => 'Daily goal';

  @override
  String get notifGoalSubtitle =>
      'Aim for a number of dhikr each day and see today\'s progress';

  @override
  String notifGoalCount(int count) {
    return '$count a day';
  }

  @override
  String get navLibrary => 'Dhikr Library';

  @override
  String get libraryTitle => 'Dhikr Library';

  @override
  String get librarySubtitle =>
      'Search every dhikr and dua, and filter by group.';

  @override
  String get librarySearchHint => 'Search azkar and duas…';

  @override
  String get librarySearchClear => 'Clear search';

  @override
  String libraryResultsCount(int count) {
    return '$count entries';
  }

  @override
  String get libraryEmptyTitle => 'Nothing matches your search';

  @override
  String get libraryEmptyHint => 'Try another word, or clear the filters.';

  @override
  String get libraryEmptyAction => 'Clear filters';

  @override
  String get libraryQuickSettings => 'Quick settings';

  @override
  String get libraryTashkeelLabel => 'Show tashkeel';

  @override
  String get libraryTashkeelSubtitle => 'Show the vowel marks on the letters';

  @override
  String get libraryFontSizeLabel => 'Font size';

  @override
  String get libraryFontIncrease => 'Increase font size';

  @override
  String get libraryFontDecrease => 'Decrease font size';

  @override
  String libraryFontValue(int size) {
    return '$size px';
  }

  @override
  String get libraryClose => 'Close';

  @override
  String get libraryFilterTitle => 'Filter by group';

  @override
  String get libraryFilterSubtitle =>
      'Pick one or more groups; with none picked, everything shows';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryFilterClear => 'Clear filters';

  @override
  String libraryFilterCount(int count) {
    return '$count selected';
  }

  @override
  String get tagMorning => 'Morning adhkar';

  @override
  String get tagEvening => 'Evening adhkar';

  @override
  String get tagAfterPrayer => 'After-prayer adhkar';

  @override
  String get tagTasabih => 'Tasabih';

  @override
  String get tagSleep => 'Before sleep';

  @override
  String get tagWaking => 'On waking';

  @override
  String get tagPrayer => 'In prayer';

  @override
  String get tagJawamiDuas => 'Comprehensive duas';

  @override
  String get tagPropheticDuas => 'Prophetic duas';

  @override
  String get tagQuranicDuas => 'Quranic duas';

  @override
  String get tagProphetsDuas => 'Duas of the prophets';

  @override
  String get tagMisc => 'Miscellaneous';

  @override
  String get tagAdhan => 'Adhan adhkar';

  @override
  String get tagMosque => 'Mosque adhkar';

  @override
  String get tagWudu => 'Wudu adhkar';

  @override
  String get tagHome => 'Home adhkar';

  @override
  String get tagKhalaa => 'Washroom adhkar';

  @override
  String get tagFood => 'Food adhkar';

  @override
  String get tagHajjUmrah => 'Hajj & Umrah adhkar';

  @override
  String get tagKhatmQuran => 'Finishing the Quran';

  @override
  String get tagVirtueOfDua => 'Virtue of dua';

  @override
  String get tagVirtueOfDhikr => 'Virtue of dhikr';

  @override
  String get tagVirtueOfSuras => 'Virtue of the surahs';

  @override
  String get tagVirtueOfQuran => 'Virtue of the Quran';

  @override
  String get tagAsmaAllah => 'The 99 names of Allah';

  @override
  String get tagDuasForDeceased => 'Duas for the deceased';

  @override
  String get tagRuqyah => 'Ruqyah';
}
