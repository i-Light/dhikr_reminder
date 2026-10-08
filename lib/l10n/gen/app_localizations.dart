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
  /// **'A dhikr pops up every few minutes. Tap it out, then get back to what you were doing.'**
  String get homeSubtitle;

  /// No description provided for @commonTestReminder.
  ///
  /// In en, this message translates to:
  /// **'Show a reminder now'**
  String get commonTestReminder;

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
  /// **'Checking for updates...'**
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
  /// **'Downloading version {version}...'**
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
  /// **'Installing version {version}...'**
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

  /// No description provided for @updatePlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates come from Google Play'**
  String get updatePlayTitle;

  /// No description provided for @updatePlayHint.
  ///
  /// In en, this message translates to:
  /// **'Keep automatic updates on in Google Play and new versions install by themselves.'**
  String get updatePlayHint;

  /// No description provided for @updateOpenPlayButton.
  ///
  /// In en, this message translates to:
  /// **'Open Google Play'**
  String get updateOpenPlayButton;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @statToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s dhikr'**
  String get statToday;

  /// No description provided for @homeNextReminder.
  ///
  /// In en, this message translates to:
  /// **'Next reminder'**
  String get homeNextReminder;

  /// No description provided for @homePauseShort.
  ///
  /// In en, this message translates to:
  /// **'Pause 1 h'**
  String get homePauseShort;

  /// No description provided for @homeResumeShort.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeResumeShort;

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

  /// No description provided for @notifIntervalTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me every'**
  String get notifIntervalTitle;

  /// No description provided for @notifSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder settings'**
  String get notifSettingsTitle;

  /// No description provided for @notifSummaryEqual.
  ///
  /// In en, this message translates to:
  /// **'Every dhikr is equally likely'**
  String get notifSummaryEqual;

  /// No description provided for @notifSummaryWeighted.
  ///
  /// In en, this message translates to:
  /// **'Dhikr come up by their priority'**
  String get notifSummaryWeighted;

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
  /// **'Dhikr priority'**
  String get notifPriorityTitle;

  /// No description provided for @notifPrioritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set how often each one comes up'**
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
  /// **'Pick the dhikr you want to be reminded of from the library.'**
  String get notifEmptyHint;

  /// No description provided for @notifEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit dhikr'**
  String get notifEditTitle;

  /// No description provided for @notifAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Repetitions'**
  String get notifAmountLabel;

  /// No description provided for @notifRepeatCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{once} other{{count} times}}'**
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

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get commonAllow;

  /// No description provided for @notifGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get notifGoalTitle;

  /// No description provided for @notifGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the daily target count'**
  String get notifGoalSubtitle;

  /// No description provided for @notifGoalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} a day'**
  String notifGoalCount(int count);

  /// No description provided for @notifGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'Today {done} of {goal}'**
  String notifGoalProgress(int done, int goal);

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @overlayPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Show reminders over other apps?'**
  String get overlayPromptTitle;

  /// No description provided for @overlayPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Allow \"Display over other apps\" so each reminder appears right on top of whatever you are using. Without it, reminders arrive as ordinary notifications.'**
  String get overlayPromptBody;

  /// No description provided for @overlayPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get overlayPromptLater;

  /// No description provided for @overlayPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'This is what you will see next. Find Dhikr in the list and turn its switch on, then come back to the app. If the list is long, Dhikr may be at the bottom, or use the search button at the top.'**
  String get overlayPreviewHint;

  /// No description provided for @overlayPreviewScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Display over other apps'**
  String get overlayPreviewScreenTitle;

  /// No description provided for @overlayMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders can\'t show over other apps'**
  String get overlayMissingTitle;

  /// No description provided for @overlayMissingBody.
  ///
  /// In en, this message translates to:
  /// **'Right now each reminder is only a small notification that is easy to miss. Allow this so it appears right in front of you.'**
  String get overlayMissingBody;

  /// No description provided for @batteryPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep reminders running'**
  String get batteryPromptTitle;

  /// No description provided for @batteryPromptBody.
  ///
  /// In en, this message translates to:
  /// **'To save battery, your phone can stop Dhikr in the background, and then reminders stop coming. Allow it to keep running, then tap Allow in the window that appears.'**
  String get batteryPromptBody;

  /// No description provided for @batteryMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders may stop after a while'**
  String get batteryMissingTitle;

  /// No description provided for @batteryMissingBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone limits Dhikr in the background, so reminders can stop coming until you open the app again. Allow it to keep running.'**
  String get batteryMissingBody;

  /// No description provided for @bugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get bugReportTitle;

  /// No description provided for @bugReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Something not working right? Tell us what happened.'**
  String get bugReportSubtitle;

  /// No description provided for @bugReportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get bugReportDialogTitle;

  /// No description provided for @bugReportDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get bugReportDescriptionLabel;

  /// No description provided for @bugReportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you did, what you expected, and what happened instead.'**
  String get bugReportDescriptionHint;

  /// No description provided for @bugReportDetailsNote.
  ///
  /// In en, this message translates to:
  /// **'The app version and your phone or PC model are added to the report. It opens in your browser so you can review it before sending.'**
  String get bugReportDetailsNote;

  /// No description provided for @bugReportOpen.
  ///
  /// In en, this message translates to:
  /// **'Open report'**
  String get bugReportOpen;

  /// No description provided for @bugReportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write what went wrong first'**
  String get bugReportEmpty;

  /// No description provided for @bugReportOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the browser, so the report was copied. Paste it into a new issue on GitHub.'**
  String get bugReportOpenFailed;

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
  /// **'Search azkar and duas...'**
  String get librarySearchHint;

  /// No description provided for @librarySearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get librarySearchClear;

  /// No description provided for @libraryResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
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
  /// **'Settings and filters'**
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

  /// No description provided for @libraryHideAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide what I already have'**
  String get libraryHideAddedLabel;

  /// No description provided for @libraryHideAddedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dhikr already in your reminders are left out of the list'**
  String get libraryHideAddedSubtitle;

  /// No description provided for @libraryHidingAdded.
  ///
  /// In en, this message translates to:
  /// **'Without mine'**
  String get libraryHidingAdded;

  /// No description provided for @libraryAddUiShow.
  ///
  /// In en, this message translates to:
  /// **'Show the add buttons'**
  String get libraryAddUiShow;

  /// No description provided for @libraryAddUiHide.
  ///
  /// In en, this message translates to:
  /// **'Hide the add buttons'**
  String get libraryAddUiHide;

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
  /// **'Pick one or more groups. With none picked, everything shows.'**
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

  /// No description provided for @libraryAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add to reminders'**
  String get libraryAddButton;

  /// No description provided for @libraryAddedButton.
  ///
  /// In en, this message translates to:
  /// **'In your reminders'**
  String get libraryAddedButton;

  /// No description provided for @libraryAddConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get libraryAddConfirm;

  /// No description provided for @libraryAddedNote.
  ///
  /// In en, this message translates to:
  /// **'This dhikr is in your reminders and comes up with the rest.'**
  String get libraryAddedNote;

  /// No description provided for @libraryAddRepeatsLabel.
  ///
  /// In en, this message translates to:
  /// **'How many times will you say it?'**
  String get libraryAddRepeatsLabel;

  /// No description provided for @libraryRecommendedCount.
  ///
  /// In en, this message translates to:
  /// **'In the sources: {count}'**
  String libraryRecommendedCount(int count);

  /// No description provided for @libraryRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove from reminders'**
  String get libraryRemoveButton;

  /// No description provided for @libraryAddedSnack.
  ///
  /// In en, this message translates to:
  /// **'Added to your reminders'**
  String get libraryAddedSnack;

  /// No description provided for @libraryRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Removed from your reminders'**
  String get libraryRemovedSnack;

  /// No description provided for @libraryReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'For reading only, it cannot be added to reminders'**
  String get libraryReadOnlyNote;

  /// No description provided for @libraryAddHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the dhikr you want to add'**
  String get libraryAddHintTitle;

  /// No description provided for @libraryAddHintBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add to reminders\" under any dhikr and it joins your list.'**
  String get libraryAddHintBody;

  /// No description provided for @libraryAddHintBack.
  ///
  /// In en, this message translates to:
  /// **'Back to notifications'**
  String get libraryAddHintBack;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get requestsTitle;

  /// No description provided for @requestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow how the dhikr you asked for are going.'**
  String get requestsSubtitle;

  /// No description provided for @requestTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot find the dhikr you want?'**
  String get requestTileTitle;

  /// No description provided for @requestTileBody.
  ///
  /// In en, this message translates to:
  /// **'Send it to us and we will review it and add it if it fits.'**
  String get requestTileBody;

  /// No description provided for @requestTileButton.
  ///
  /// In en, this message translates to:
  /// **'Request a dhikr'**
  String get requestTileButton;

  /// No description provided for @requestEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Request it'**
  String get requestEmptyAction;

  /// No description provided for @requestSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a dhikr'**
  String get requestSheetTitle;

  /// No description provided for @requestSheetIntro.
  ///
  /// In en, this message translates to:
  /// **'Write the dhikr as it is narrated and we will review it before adding it. Only this text is sent, nothing about you.'**
  String get requestSheetIntro;

  /// No description provided for @requestTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Dhikr text'**
  String get requestTextLabel;

  /// No description provided for @requestTextHint.
  ///
  /// In en, this message translates to:
  /// **'Write the whole dhikr in Arabic'**
  String get requestTextHint;

  /// No description provided for @requestSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source (if you know it)'**
  String get requestSourceLabel;

  /// No description provided for @requestSourceHint.
  ///
  /// In en, this message translates to:
  /// **'For example: narrated by al-Bukhari'**
  String get requestSourceHint;

  /// No description provided for @requestSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get requestSend;

  /// No description provided for @requestSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get requestSending;

  /// No description provided for @requestProblemTooShort.
  ///
  /// In en, this message translates to:
  /// **'That is too short, write the whole dhikr.'**
  String get requestProblemTooShort;

  /// No description provided for @requestProblemTooLong.
  ///
  /// In en, this message translates to:
  /// **'That is too long. The limit is {max} characters.'**
  String requestProblemTooLong(int max);

  /// No description provided for @requestProblemNotArabic.
  ///
  /// In en, this message translates to:
  /// **'Write the dhikr in Arabic.'**
  String get requestProblemNotArabic;

  /// No description provided for @requestProblemHasLink.
  ///
  /// In en, this message translates to:
  /// **'Links and unusual symbols are not allowed here.'**
  String get requestProblemHasLink;

  /// No description provided for @requestProblemRepeated.
  ///
  /// In en, this message translates to:
  /// **'Too many repeated characters, check what you wrote.'**
  String get requestProblemRepeated;

  /// No description provided for @requestProblemTooManyOpen.
  ///
  /// In en, this message translates to:
  /// **'You already have {count} requests waiting. Wait until one of them is done.'**
  String requestProblemTooManyOpen(int count);

  /// No description provided for @requestProblemDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'You have reached today\'s limit. Try again tomorrow.'**
  String get requestProblemDailyLimit;

  /// No description provided for @requestProblemTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Wait {seconds} seconds before the next request.'**
  String requestProblemTooSoon(int seconds);

  /// No description provided for @requestProblemBusy.
  ///
  /// In en, this message translates to:
  /// **'The service is busy. Try again in a little while.'**
  String get requestProblemBusy;

  /// No description provided for @requestProblemRejected.
  ///
  /// In en, this message translates to:
  /// **'We could not accept that. Check the text and try again.'**
  String get requestProblemRejected;

  /// No description provided for @requestExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'We already have this dhikr'**
  String get requestExistsTitle;

  /// No description provided for @requestExistsBody.
  ///
  /// In en, this message translates to:
  /// **'This may be the one you want:'**
  String get requestExistsBody;

  /// No description provided for @requestExistsShow.
  ///
  /// In en, this message translates to:
  /// **'Show it in the library'**
  String get requestExistsShow;

  /// No description provided for @requestExistsSendAnyway.
  ///
  /// In en, this message translates to:
  /// **'Not it, send my request'**
  String get requestExistsSendAnyway;

  /// No description provided for @requestOwnTitle.
  ///
  /// In en, this message translates to:
  /// **'You already requested this'**
  String get requestOwnTitle;

  /// No description provided for @requestOwnBody.
  ///
  /// In en, this message translates to:
  /// **'You can follow it in My requests.'**
  String get requestOwnBody;

  /// No description provided for @requestOwnShow.
  ///
  /// In en, this message translates to:
  /// **'Open My requests'**
  String get requestOwnShow;

  /// No description provided for @requestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request received'**
  String get requestSentTitle;

  /// No description provided for @requestSentBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you for contributing. We will review it and add it if it fits. You can follow it in My requests.'**
  String get requestSentBody;

  /// No description provided for @requestDuplicateBody.
  ///
  /// In en, this message translates to:
  /// **'Others asked for this dhikr too, so we added you to them. Thank you for your patience.'**
  String get requestDuplicateBody;

  /// No description provided for @requestQueuedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request saved'**
  String get requestQueuedTitle;

  /// No description provided for @requestQueuedBody.
  ///
  /// In en, this message translates to:
  /// **'There is no connection right now. It will be sent as soon as you are back online.'**
  String get requestQueuedBody;

  /// No description provided for @requestSentOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get requestSentOk;

  /// No description provided for @requestsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get requestsEmptyTitle;

  /// No description provided for @requestsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'If a dhikr is not in the library, request it and follow it here.'**
  String get requestsEmptyBody;

  /// No description provided for @requestsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get requestsRefresh;

  /// No description provided for @requestsNewButton.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get requestsNewButton;

  /// No description provided for @requestStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a connection'**
  String get requestStatusQueued;

  /// No description provided for @requestStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Received, waiting for review'**
  String get requestStatusPending;

  /// No description provided for @requestStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'We are working on it'**
  String get requestStatusInProgress;

  /// No description provided for @requestStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get requestStatusDone;

  /// No description provided for @requestStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get requestStatusDeclined;

  /// No description provided for @requestNoteQueued.
  ///
  /// In en, this message translates to:
  /// **'It will be sent when you are back online.'**
  String get requestNoteQueued;

  /// No description provided for @requestNotePending.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your patience. We will review it and the answer will appear here.'**
  String get requestNotePending;

  /// No description provided for @requestNoteInProgress.
  ///
  /// In en, this message translates to:
  /// **'Thank you for waiting. This dhikr is being reviewed and prepared right now.'**
  String get requestNoteInProgress;

  /// No description provided for @requestNoteDone.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your contribution. This dhikr is now in the library.'**
  String get requestNoteDone;

  /// No description provided for @requestNoteDoneLater.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your contribution. This dhikr is ready and will reach you in the next update.'**
  String get requestNoteDoneLater;

  /// No description provided for @requestNoteDoneVersion.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your contribution. This dhikr will reach you in version {version}.'**
  String requestNoteDoneVersion(String version);

  /// No description provided for @requestNoteDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This dhikr is already in the library. Try searching for it with another word. Thank you for caring.'**
  String get requestNoteDuplicate;

  /// No description provided for @requestNoteUnclear.
  ///
  /// In en, this message translates to:
  /// **'We could not be sure of the text. You are welcome to send it again, written clearly with its source. Thank you.'**
  String get requestNoteUnclear;

  /// No description provided for @requestNoteNotSuitable.
  ///
  /// In en, this message translates to:
  /// **'This request does not fit the library right now. Thank you for caring, and may Allah accept it from you.'**
  String get requestNoteNotSuitable;

  /// No description provided for @requestNoteOther.
  ///
  /// In en, this message translates to:
  /// **'We could not add this one this time. Thank you for caring.'**
  String get requestNoteOther;

  /// No description provided for @requestVotes.
  ///
  /// In en, this message translates to:
  /// **'{count} people asked for this'**
  String requestVotes(int count);

  /// No description provided for @requestShowInLibrary.
  ///
  /// In en, this message translates to:
  /// **'Show it in the library'**
  String get requestShowInLibrary;

  /// No description provided for @requestRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from the list'**
  String get requestRemove;

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
