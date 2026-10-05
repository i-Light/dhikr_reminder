import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get appTitle;

  /// No description provided for @splashDescription.
  ///
  /// In en, this message translates to:
  /// **'A gentle dhikr reminder that lives in your tray.'**
  String get splashDescription;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A dhikr pops up every few minutes — tap it out, then get back to work.'**
  String get homeSubtitle;

  /// No description provided for @commonTestReminder.
  ///
  /// In en, this message translates to:
  /// **'Show a reminder now'**
  String get commonTestReminder;

  /// No description provided for @settingsDhikrTitle.
  ///
  /// In en, this message translates to:
  /// **'Azkar Settings'**
  String get settingsDhikrTitle;

  /// No description provided for @settingsDhikrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the zikr reminders frequency, volume, add, and remove azkar'**
  String get settingsDhikrSubtitle;

  /// No description provided for @settingsDhikrIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder interval'**
  String get settingsDhikrIntervalLabel;

  /// No description provided for @settingsDhikrIntervalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How often a reminder pops up, in minutes'**
  String get settingsDhikrIntervalSubtitle;

  /// No description provided for @settingsDhikrSoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsDhikrSoundLabel;

  /// No description provided for @settingsDhikrSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play a sound when a reminder pops up'**
  String get settingsDhikrSoundSubtitle;

  /// No description provided for @settingsDhikrUseChanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Weighted chance'**
  String get settingsDhikrUseChanceLabel;

  /// No description provided for @settingsDhikrUseChanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off: every dhikr is equally likely. On: set how often each one comes up'**
  String get settingsDhikrUseChanceSubtitle;

  /// No description provided for @settingsDhikrNameColumn.
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get settingsDhikrNameColumn;

  /// No description provided for @settingsDhikrAmountColumn.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get settingsDhikrAmountColumn;

  /// No description provided for @settingsDhikrChanceColumn.
  ///
  /// In en, this message translates to:
  /// **'Chance'**
  String get settingsDhikrChanceColumn;

  /// No description provided for @settingsDhikrChanceExplainer.
  ///
  /// In en, this message translates to:
  /// **'Chance is a weight, not a percentage. An entry at 6 comes up twice as often as one at 3 — nothing more. Give every entry the same number and they are equally likely; set one to 0 and it never comes up at all. A single entry at 1 with everything else muted still comes up every time, because there is nothing else to compare it against.'**
  String get settingsDhikrChanceExplainer;

  /// No description provided for @settingsDhikrSaved.
  ///
  /// In en, this message translates to:
  /// **'Azkar changes has been saved.'**
  String get settingsDhikrSaved;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @dhikrReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Dhikr reminder'**
  String get dhikrReminderTitle;

  /// No description provided for @dhikrReminderTouchEverywhereTip.
  ///
  /// In en, this message translates to:
  /// **'Touch anywhere to count'**
  String get dhikrReminderTouchEverywhereTip;

  /// No description provided for @trayOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open app'**
  String get trayOpenApp;

  /// No description provided for @trayNextDhikr.
  ///
  /// In en, this message translates to:
  /// **'Next dhikr'**
  String get trayNextDhikr;

  /// No description provided for @trayNextDhikrIn.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String trayNextDhikrIn(String time);

  /// No description provided for @trayNextDhikrPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for settings'**
  String get trayNextDhikrPending;

  /// No description provided for @traySoundOn.
  ///
  /// In en, this message translates to:
  /// **'Sound on'**
  String get traySoundOn;

  /// No description provided for @traySoundOff.
  ///
  /// In en, this message translates to:
  /// **'Sound off'**
  String get traySoundOff;

  /// No description provided for @trayPause.
  ///
  /// In en, this message translates to:
  /// **'Pause for 1 hour'**
  String get trayPause;

  /// No description provided for @trayResume.
  ///
  /// In en, this message translates to:
  /// **'Resume reminders'**
  String get trayResume;

  /// No description provided for @trayPausedUntil.
  ///
  /// In en, this message translates to:
  /// **'Paused until {time}'**
  String trayPausedUntil(String time);

  /// No description provided for @settingsAutostartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with Windows'**
  String get settingsAutostartTitle;

  /// No description provided for @settingsAutostartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open quietly in the tray when you sign in.'**
  String get settingsAutostartSubtitle;

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Close app'**
  String get trayQuit;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updateTitle;

  /// No description provided for @updateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Dhikr up to date'**
  String get updateSubtitle;

  /// No description provided for @updateVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String updateVersion(String version);

  /// No description provided for @updateNeverChecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get updateNeverChecked;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get updateUpToDate;

  /// No description provided for @updateLastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked {time}'**
  String updateLastChecked(String time);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateAvailable(String version);

  /// No description provided for @updateAvailableManual.
  ///
  /// In en, this message translates to:
  /// **'This copy was not installed with the setup program, so it cannot update itself. Download the new setup from the releases page.'**
  String get updateAvailableManual;

  /// No description provided for @updateAvailableAutoOff.
  ///
  /// In en, this message translates to:
  /// **'Automatic updates are off. Press Update now to install it.'**
  String get updateAvailableAutoOff;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading version {version}…'**
  String updateDownloading(String version);

  /// No description provided for @updateReady.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready to install'**
  String updateReady(String version);

  /// No description provided for @updateReadyHint.
  ///
  /// In en, this message translates to:
  /// **'It installs by itself once this window is closed and no reminder is showing.'**
  String get updateReadyHint;

  /// No description provided for @updateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing version {version}…'**
  String updateInstalling(String version);

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates'**
  String get updateFailed;

  /// No description provided for @updateFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Check your connection. It will try again shortly.'**
  String get updateFailedHint;

  /// No description provided for @updateCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheckButton;

  /// No description provided for @updateInstallButton.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateInstallButton;

  /// No description provided for @updateRestartButton.
  ///
  /// In en, this message translates to:
  /// **'Restart and update'**
  String get updateRestartButton;

  /// No description provided for @updateDownloadPageButton.
  ///
  /// In en, this message translates to:
  /// **'Open download page'**
  String get updateDownloadPageButton;

  /// No description provided for @updateAutoLabel.
  ///
  /// In en, this message translates to:
  /// **'Update automatically'**
  String get updateAutoLabel;

  /// No description provided for @updateAutoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download new versions in the background and install them when the app is idle'**
  String get updateAutoSubtitle;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @statSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get statSession;

  /// No description provided for @statToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statToday;

  /// No description provided for @homeNextReminder.
  ///
  /// In en, this message translates to:
  /// **'Next reminder'**
  String get homeNextReminder;

  /// No description provided for @homeCountedToday.
  ///
  /// In en, this message translates to:
  /// **'Counted today'**
  String get homeCountedToday;

  /// No description provided for @homeCountedSession.
  ///
  /// In en, this message translates to:
  /// **'This session'**
  String get homeCountedSession;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how often a dhikr reaches you, and which ones.'**
  String get notifSubtitle;

  /// No description provided for @notifScheduleSection.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get notifScheduleSection;

  /// No description provided for @notifIntervalTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me every'**
  String get notifIntervalTitle;

  /// No description provided for @notifIntervalMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String notifIntervalMinutes(int minutes);

  /// No description provided for @notifSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get notifSoundTitle;

  /// No description provided for @notifSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play a sound when a reminder arrives'**
  String get notifSoundSubtitle;

  /// No description provided for @notifPriorityTitle.
  ///
  /// In en, this message translates to:
  /// **'Favour some dhikr'**
  String get notifPriorityTitle;

  /// No description provided for @notifPrioritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Give each dhikr its own weight so some come up more often'**
  String get notifPrioritySubtitle;

  /// No description provided for @notifMySection.
  ///
  /// In en, this message translates to:
  /// **'My dhikr'**
  String get notifMySection;

  /// No description provided for @notifAddDhikr.
  ///
  /// In en, this message translates to:
  /// **'Add dhikr'**
  String get notifAddDhikr;

  /// No description provided for @notifEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No dhikr yet'**
  String get notifEmptyTitle;

  /// No description provided for @notifEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add the dhikr you want to be reminded of.'**
  String get notifEmptyHint;

  /// No description provided for @notifEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit dhikr'**
  String get notifEditTitle;

  /// No description provided for @notifNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New dhikr'**
  String get notifNewTitle;

  /// No description provided for @notifNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Dhikr text'**
  String get notifNameLabel;

  /// No description provided for @notifAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Repetitions'**
  String get notifAmountLabel;

  /// No description provided for @notifRepeatCount.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String notifRepeatCount(int count);

  /// No description provided for @notifFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'How often it comes up'**
  String get notifFrequencyLabel;

  /// No description provided for @notifFrequencyNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get notifFrequencyNever;

  /// No description provided for @notifFrequencyValue.
  ///
  /// In en, this message translates to:
  /// **'{value} of 10'**
  String notifFrequencyValue(int value);

  /// No description provided for @notifFrequencyHint.
  ///
  /// In en, this message translates to:
  /// **'A weight, not a percentage: 6 comes up twice as often as 3. 0 means never.'**
  String get notifFrequencyHint;

  /// No description provided for @notifDeleted.
  ///
  /// In en, this message translates to:
  /// **'Dhikr deleted'**
  String get notifDeleted;

  /// No description provided for @notifUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get notifUndo;

  /// No description provided for @notifNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Write the dhikr first'**
  String get notifNameRequired;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @notifGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get notifGoalTitle;

  /// No description provided for @notifGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Aim for a number of dhikr each day and see today\'s progress'**
  String get notifGoalSubtitle;

  /// No description provided for @notifGoalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} a day'**
  String notifGoalCount(int count);

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Dhikr Library'**
  String get navLibrary;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Dhikr Library'**
  String get libraryTitle;

  /// No description provided for @librarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search every dhikr and dua, and filter by group.'**
  String get librarySubtitle;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search azkar and duas…'**
  String get librarySearchHint;

  /// No description provided for @librarySearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get librarySearchClear;

  /// No description provided for @libraryResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String libraryResultsCount(int count);

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches your search'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try another word, or clear the filters.'**
  String get libraryEmptyHint;

  /// No description provided for @libraryEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get libraryEmptyAction;

  /// No description provided for @libraryQuickSettings.
  ///
  /// In en, this message translates to:
  /// **'Quick settings'**
  String get libraryQuickSettings;

  /// No description provided for @libraryTashkeelLabel.
  ///
  /// In en, this message translates to:
  /// **'Show tashkeel'**
  String get libraryTashkeelLabel;

  /// No description provided for @libraryTashkeelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the vowel marks on the letters'**
  String get libraryTashkeelSubtitle;

  /// No description provided for @libraryFontSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get libraryFontSizeLabel;

  /// No description provided for @libraryFontIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase font size'**
  String get libraryFontIncrease;

  /// No description provided for @libraryFontDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease font size'**
  String get libraryFontDecrease;

  /// No description provided for @libraryFontValue.
  ///
  /// In en, this message translates to:
  /// **'{size} px'**
  String libraryFontValue(int size);

  /// No description provided for @libraryClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get libraryClose;

  /// No description provided for @libraryFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by group'**
  String get libraryFilterTitle;

  /// No description provided for @libraryFilterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick one or more groups; with none picked, everything shows'**
  String get libraryFilterSubtitle;

  /// No description provided for @libraryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryFilterAll;

  /// No description provided for @libraryFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get libraryFilterClear;

  /// No description provided for @libraryFilterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String libraryFilterCount(int count);

  /// No description provided for @tagMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get tagMorning;

  /// No description provided for @tagEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar'**
  String get tagEvening;

  /// No description provided for @tagAfterPrayer.
  ///
  /// In en, this message translates to:
  /// **'After-prayer adhkar'**
  String get tagAfterPrayer;

  /// No description provided for @tagTasabih.
  ///
  /// In en, this message translates to:
  /// **'Tasabih'**
  String get tagTasabih;

  /// No description provided for @tagSleep.
  ///
  /// In en, this message translates to:
  /// **'Before sleep'**
  String get tagSleep;

  /// No description provided for @tagWaking.
  ///
  /// In en, this message translates to:
  /// **'On waking'**
  String get tagWaking;

  /// No description provided for @tagPrayer.
  ///
  /// In en, this message translates to:
  /// **'In prayer'**
  String get tagPrayer;

  /// No description provided for @tagJawamiDuas.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive duas'**
  String get tagJawamiDuas;

  /// No description provided for @tagPropheticDuas.
  ///
  /// In en, this message translates to:
  /// **'Prophetic duas'**
  String get tagPropheticDuas;

  /// No description provided for @tagQuranicDuas.
  ///
  /// In en, this message translates to:
  /// **'Quranic duas'**
  String get tagQuranicDuas;

  /// No description provided for @tagProphetsDuas.
  ///
  /// In en, this message translates to:
  /// **'Duas of the prophets'**
  String get tagProphetsDuas;

  /// No description provided for @tagMisc.
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous'**
  String get tagMisc;

  /// No description provided for @tagAdhan.
  ///
  /// In en, this message translates to:
  /// **'Adhan adhkar'**
  String get tagAdhan;

  /// No description provided for @tagMosque.
  ///
  /// In en, this message translates to:
  /// **'Mosque adhkar'**
  String get tagMosque;

  /// No description provided for @tagWudu.
  ///
  /// In en, this message translates to:
  /// **'Wudu adhkar'**
  String get tagWudu;

  /// No description provided for @tagHome.
  ///
  /// In en, this message translates to:
  /// **'Home adhkar'**
  String get tagHome;

  /// No description provided for @tagKhalaa.
  ///
  /// In en, this message translates to:
  /// **'Washroom adhkar'**
  String get tagKhalaa;

  /// No description provided for @tagFood.
  ///
  /// In en, this message translates to:
  /// **'Food adhkar'**
  String get tagFood;

  /// No description provided for @tagHajjUmrah.
  ///
  /// In en, this message translates to:
  /// **'Hajj & Umrah adhkar'**
  String get tagHajjUmrah;

  /// No description provided for @tagKhatmQuran.
  ///
  /// In en, this message translates to:
  /// **'Finishing the Quran'**
  String get tagKhatmQuran;

  /// No description provided for @tagVirtueOfDua.
  ///
  /// In en, this message translates to:
  /// **'Virtue of dua'**
  String get tagVirtueOfDua;

  /// No description provided for @tagVirtueOfDhikr.
  ///
  /// In en, this message translates to:
  /// **'Virtue of dhikr'**
  String get tagVirtueOfDhikr;

  /// No description provided for @tagVirtueOfSuras.
  ///
  /// In en, this message translates to:
  /// **'Virtue of the surahs'**
  String get tagVirtueOfSuras;

  /// No description provided for @tagVirtueOfQuran.
  ///
  /// In en, this message translates to:
  /// **'Virtue of the Quran'**
  String get tagVirtueOfQuran;

  /// No description provided for @tagAsmaAllah.
  ///
  /// In en, this message translates to:
  /// **'The 99 names of Allah'**
  String get tagAsmaAllah;

  /// No description provided for @tagDuasForDeceased.
  ///
  /// In en, this message translates to:
  /// **'Duas for the deceased'**
  String get tagDuasForDeceased;

  /// No description provided for @tagRuqyah.
  ///
  /// In en, this message translates to:
  /// **'Ruqyah'**
  String get tagRuqyah;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
