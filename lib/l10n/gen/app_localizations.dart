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
  /// **'Dhikr Reminder'**
  String get appTitle;

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
  /// **'Keep Dhikr Reminder up to date'**
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
