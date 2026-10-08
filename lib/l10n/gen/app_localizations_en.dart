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
      'A dhikr pops up every few minutes. Tap it out, then get back to what you were doing.';

  @override
  String get commonTestReminder => 'Show a reminder now';

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
  String get updateChecking => 'Checking for updates...';

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
    return 'Downloading version $version...';
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
    return 'Installing version $version...';
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
  String get updatePlayTitle => 'Updates come from Google Play';

  @override
  String get updatePlayHint =>
      'Keep automatic updates on in Google Play and new versions install by themselves.';

  @override
  String get updateOpenPlayButton => 'Open Google Play';

  @override
  String get navSettings => 'Settings';

  @override
  String get statToday => 'Today\'s dhikr';

  @override
  String get homeNextReminder => 'Next reminder';

  @override
  String get homePauseShort => 'Pause 1 h';

  @override
  String get homeResumeShort => 'Resume';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifSubtitle =>
      'Choose how often a dhikr reaches you, and which ones.';

  @override
  String get notifIntervalTitle => 'Remind me every';

  @override
  String get notifSettingsTitle => 'Reminder settings';

  @override
  String get notifSummaryEqual => 'Every dhikr is equally likely';

  @override
  String get notifSummaryWeighted => 'Dhikr come up by their priority';

  @override
  String notifIntervalMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get notifSoundTitle => 'Sound';

  @override
  String get notifSoundSubtitle => 'Play a sound when a reminder arrives';

  @override
  String get notifPriorityTitle => 'Dhikr priority';

  @override
  String get notifPrioritySubtitle => 'Set how often each one comes up';

  @override
  String get notifMySection => 'My dhikr';

  @override
  String get notifAddDhikr => 'Add dhikr';

  @override
  String get notifEmptyTitle => 'No dhikr yet';

  @override
  String get notifEmptyHint =>
      'Pick the dhikr you want to be reminded of from the library.';

  @override
  String get notifEditTitle => 'Edit dhikr';

  @override
  String get notifAmountLabel => 'Repetitions';

  @override
  String notifRepeatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return '$_temp0';
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
  String get commonCancel => 'Cancel';

  @override
  String get commonAllow => 'Allow';

  @override
  String get notifGoalTitle => 'Daily goal';

  @override
  String get notifGoalSubtitle => 'Set the daily target count';

  @override
  String notifGoalCount(int count) {
    return '$count a day';
  }

  @override
  String notifGoalProgress(int done, int goal) {
    return 'Today $done of $goal';
  }

  @override
  String get commonClose => 'Close';

  @override
  String get overlayPromptTitle => 'Show reminders over other apps?';

  @override
  String get overlayPromptBody =>
      'Allow \"Display over other apps\" so each reminder appears right on top of whatever you are using. Without it, reminders arrive as ordinary notifications.';

  @override
  String get overlayPromptLater => 'Not now';

  @override
  String get overlayPreviewHint =>
      'This is what you will see next. Find Dhikr in the list and turn its switch on, then come back to the app. If the list is long, Dhikr may be at the bottom, or use the search button at the top.';

  @override
  String get overlayPreviewScreenTitle => 'Display over other apps';

  @override
  String get overlayMissingTitle => 'Reminders can\'t show over other apps';

  @override
  String get overlayMissingBody =>
      'Right now each reminder is only a small notification that is easy to miss. Allow this so it appears right in front of you.';

  @override
  String get batteryPromptTitle => 'Keep reminders running';

  @override
  String get batteryPromptBody =>
      'To save battery, your phone can stop Dhikr in the background, and then reminders stop coming. Allow it to keep running, then tap Allow in the window that appears.';

  @override
  String get batteryMissingTitle => 'Reminders may stop after a while';

  @override
  String get batteryMissingBody =>
      'Your phone limits Dhikr in the background, so reminders can stop coming until you open the app again. Allow it to keep running.';

  @override
  String get bugReportTitle => 'Report a bug';

  @override
  String get bugReportSubtitle =>
      'Something not working right? Tell us what happened.';

  @override
  String get bugReportDialogTitle => 'Report a bug';

  @override
  String get bugReportDescriptionLabel => 'What went wrong?';

  @override
  String get bugReportDescriptionHint =>
      'Describe what you did, what you expected, and what happened instead.';

  @override
  String get bugReportDetailsNote =>
      'The app version and your phone or PC model are added to the report. It opens in your browser so you can review it before sending.';

  @override
  String get bugReportOpen => 'Open report';

  @override
  String get bugReportEmpty => 'Write what went wrong first';

  @override
  String get bugReportOpenFailed =>
      'Could not open the browser, so the report was copied. Paste it into a new issue on GitHub.';

  @override
  String get navLibrary => 'Dhikr Library';

  @override
  String get libraryTitle => 'Dhikr Library';

  @override
  String get librarySubtitle =>
      'Search every dhikr and dua, and filter by group.';

  @override
  String get librarySearchHint => 'Search azkar and duas...';

  @override
  String get librarySearchClear => 'Clear search';

  @override
  String libraryResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmptyTitle => 'Nothing matches your search';

  @override
  String get libraryEmptyHint => 'Try another word, or clear the filters.';

  @override
  String get libraryEmptyAction => 'Clear filters';

  @override
  String get libraryQuickSettings => 'Settings and filters';

  @override
  String get libraryTashkeelLabel => 'Show tashkeel';

  @override
  String get libraryTashkeelSubtitle => 'Show the vowel marks on the letters';

  @override
  String get libraryHideAddedLabel => 'Hide what I already have';

  @override
  String get libraryHideAddedSubtitle =>
      'Dhikr already in your reminders are left out of the list';

  @override
  String get libraryHidingAdded => 'Without mine';

  @override
  String get libraryAddUiShow => 'Show the add buttons';

  @override
  String get libraryAddUiHide => 'Hide the add buttons';

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
      'Pick one or more groups. With none picked, everything shows.';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryFilterClear => 'Clear filters';

  @override
  String libraryFilterCount(int count) {
    return '$count selected';
  }

  @override
  String get libraryAddButton => 'Add to reminders';

  @override
  String get libraryAddedButton => 'In your reminders';

  @override
  String get libraryAddConfirm => 'Add';

  @override
  String get libraryAddedNote =>
      'This dhikr is in your reminders and comes up with the rest.';

  @override
  String get libraryAddRepeatsLabel => 'How many times will you say it?';

  @override
  String libraryRecommendedCount(int count) {
    return 'In the sources: $count';
  }

  @override
  String get libraryRemoveButton => 'Remove from reminders';

  @override
  String get libraryAddedSnack => 'Added to your reminders';

  @override
  String get libraryRemovedSnack => 'Removed from your reminders';

  @override
  String get libraryReadOnlyNote =>
      'For reading only, it cannot be added to reminders';

  @override
  String get libraryAddHintTitle => 'Pick the dhikr you want to add';

  @override
  String get libraryAddHintBody =>
      'Tap \"Add to reminders\" under any dhikr and it joins your list.';

  @override
  String get libraryAddHintBack => 'Back to notifications';

  @override
  String get requestsTitle => 'My requests';

  @override
  String get requestsSubtitle =>
      'Follow how the dhikr you asked for are going.';

  @override
  String get requestTileTitle => 'Cannot find the dhikr you want?';

  @override
  String get requestTileBody =>
      'Send it to us and we will review it and add it if it fits.';

  @override
  String get requestTileButton => 'Request a dhikr';

  @override
  String get requestEmptyAction => 'Request it';

  @override
  String get requestSheetTitle => 'Request a dhikr';

  @override
  String get requestSheetIntro =>
      'Write the dhikr as it is narrated and we will review it before adding it. Only this text is sent, nothing about you.';

  @override
  String get requestTextLabel => 'Dhikr text';

  @override
  String get requestTextHint => 'Write the whole dhikr in Arabic';

  @override
  String get requestSourceLabel => 'Source (if you know it)';

  @override
  String get requestSourceHint => 'For example: narrated by al-Bukhari';

  @override
  String get requestSend => 'Send request';

  @override
  String get requestSending => 'Sending...';

  @override
  String get requestProblemTooShort =>
      'That is too short, write the whole dhikr.';

  @override
  String requestProblemTooLong(int max) {
    return 'That is too long. The limit is $max characters.';
  }

  @override
  String get requestProblemNotArabic => 'Write the dhikr in Arabic.';

  @override
  String get requestProblemHasLink =>
      'Links and unusual symbols are not allowed here.';

  @override
  String get requestProblemRepeated =>
      'Too many repeated characters, check what you wrote.';

  @override
  String requestProblemTooManyOpen(int count) {
    return 'You already have $count requests waiting. Wait until one of them is done.';
  }

  @override
  String get requestProblemDailyLimit =>
      'You have reached today\'s limit. Try again tomorrow.';

  @override
  String requestProblemTooSoon(int seconds) {
    return 'Wait $seconds seconds before the next request.';
  }

  @override
  String get requestProblemBusy =>
      'The service is busy. Try again in a little while.';

  @override
  String get requestProblemRejected =>
      'We could not accept that. Check the text and try again.';

  @override
  String get requestExistsTitle => 'We already have this dhikr';

  @override
  String get requestExistsBody => 'This may be the one you want:';

  @override
  String get requestExistsShow => 'Show it in the library';

  @override
  String get requestExistsSendAnyway => 'Not it, send my request';

  @override
  String get requestOwnTitle => 'You already requested this';

  @override
  String get requestOwnBody => 'You can follow it in My requests.';

  @override
  String get requestOwnShow => 'Open My requests';

  @override
  String get requestSentTitle => 'Request received';

  @override
  String get requestSentBody =>
      'Thank you for contributing. We will review it and add it if it fits. You can follow it in My requests.';

  @override
  String get requestDuplicateBody =>
      'Others asked for this dhikr too, so we added you to them. Thank you for your patience.';

  @override
  String get requestQueuedTitle => 'Request saved';

  @override
  String get requestQueuedBody =>
      'There is no connection right now. It will be sent as soon as you are back online.';

  @override
  String get requestSentOk => 'OK';

  @override
  String get requestsEmptyTitle => 'No requests yet';

  @override
  String get requestsEmptyBody =>
      'If a dhikr is not in the library, request it and follow it here.';

  @override
  String get requestsRefresh => 'Refresh';

  @override
  String get requestsNewButton => 'New request';

  @override
  String get requestStatusQueued => 'Waiting for a connection';

  @override
  String get requestStatusPending => 'Received, waiting for review';

  @override
  String get requestStatusInProgress => 'We are working on it';

  @override
  String get requestStatusDone => 'Added';

  @override
  String get requestStatusDeclined => 'Not added';

  @override
  String get requestNoteQueued => 'It will be sent when you are back online.';

  @override
  String get requestNotePending =>
      'Thank you for your patience. We will review it and the answer will appear here.';

  @override
  String get requestNoteInProgress =>
      'Thank you for waiting. This dhikr is being reviewed and prepared right now.';

  @override
  String get requestNoteDone =>
      'Thank you for your contribution. This dhikr is now in the library.';

  @override
  String get requestNoteDoneLater =>
      'Thank you for your contribution. This dhikr is ready and will reach you in the next update.';

  @override
  String requestNoteDoneVersion(String version) {
    return 'Thank you for your contribution. This dhikr will reach you in version $version.';
  }

  @override
  String get requestNoteDuplicate =>
      'This dhikr is already in the library. Try searching for it with another word. Thank you for caring.';

  @override
  String get requestNoteUnclear =>
      'We could not be sure of the text. You are welcome to send it again, written clearly with its source. Thank you.';

  @override
  String get requestNoteNotSuitable =>
      'This request does not fit the library right now. Thank you for caring, and may Allah accept it from you.';

  @override
  String get requestNoteOther =>
      'We could not add this one this time. Thank you for caring.';

  @override
  String requestVotes(int count) {
    return '$count people asked for this';
  }

  @override
  String get requestShowInLibrary => 'Show it in the library';

  @override
  String get requestRemove => 'Remove from the list';

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
  String get tagDuasForDeceased => 'Duas for the deceased';

  @override
  String get tagRuqyah => 'Ruqyah';
}
