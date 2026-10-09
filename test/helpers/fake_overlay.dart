import 'package:dhikr_reminder/core/quiet_hours.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_health.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';

/// A [ReminderOverlay] that remembers what it was asked to do.
class FakeOverlay implements ReminderOverlay {
  FakeOverlay({this.allowed = false, this.taps = const {}});

  bool allowed;
  Map<int, int> taps;

  List<PlannedReminder>? scheduled;
  Duration? interval;
  String? title;
  String? closeLabel;
  String? tip;
  String? dayLabel;
  int cancels = 0;
  String? shownNow;
  String? shownNowTranslit;
  bool? arabicHidden;
  bool? arabicHiddenOnCard;
  int? shownNowGoal;
  String? todayDay;
  Map<int, int>? todayCounts;
  int todayPushes = 0;
  int permissionRequests = 0;
  int notificationPermissionRequests = 0;
  int drains = 0;
  DateTime? pausedUntil;
  QuietHours quiet = const QuietHours();

  /// The dhikr a tapped notification asked the app to open, until it is taken.
  int? openDhikrId;

  /// What the native alarms would say is next.
  DateTime? nextAt;

  @override
  Future<bool> canDraw() async => allowed;

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<void> schedule(
    List<PlannedReminder> plan, {
    required Duration interval,
    required String title,
    required String closeLabel,
    required String tip,
    required String dayLabel,
    DateTime? pausedUntil,
    QuietHours quiet = const QuietHours(),
  }) async {
    this.pausedUntil = pausedUntil;
    this.quiet = quiet;
    scheduled = plan;
    this.interval = interval;
    this.title = title;
    this.closeLabel = closeLabel;
    this.tip = tip;
    this.dayLabel = dayLabel;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    notificationPermissionRequests++;
    return true;
  }

  @override
  Future<int?> takeOpenDhikr() async {
    final id = openDhikrId;
    openDhikrId = null;
    return id;
  }

  @override
  Future<DateTime?> nextReminderAt() async => nextAt;

  /// What the phone says about whether reminders are getting through.
  ReminderHealth? healthNow;
  int appLaunchSettingsOpened = 0;
  int notificationSettingsOpened = 0;

  @override
  Future<ReminderHealth?> health() async => healthNow;

  @override
  Future<bool> openAppLaunchSettings() async {
    appLaunchSettingsOpened++;
    return true;
  }

  @override
  Future<bool> openNotificationSettings() async {
    notificationSettingsOpened++;
    return true;
  }

  @override
  Future<bool> showNow({
    required int dhikrId,
    required String text,
    required int amount,
    required int goal,
    required String title,
    required String closeLabel,
    required String tip,
    required String dayLabel,
    String translit = '',
  }) async {
    if (!allowed) return false;
    shownNow = text;
    shownNowTranslit = translit;
    shownNowGoal = goal;
    return true;
  }

  @override
  Future<void> setToday(String day, Map<int, int> counts) async {
    todayPushes++;
    todayDay = day;
    todayCounts = counts;
  }

  @override
  Future<void> setArabicHidden(bool hidden) async {
    arabicHidden = hidden;
    arabicHiddenOnCard = null;
  }

  @override
  Future<bool?> takeArabicHidden() async {
    final result = arabicHiddenOnCard;
    arabicHiddenOnCard = null;
    return result;
  }

  @override
  Future<void> cancel() async => cancels++;

  /// The words last handed over for the widget, tiles and notification buttons.
  Map<String, String>? surfaceLabels;

  /// A pause set from a tile: null for none, 0 for lifted, else epoch millis.
  int? pauseChange;

  /// The page a shortcut asked for.
  String? openTab;

  @override
  Future<void> setSurfaceLabels(Map<String, String> labels) async {
    surfaceLabels = labels;
  }

  @override
  Future<int?> takePauseChange() async {
    final change = pauseChange;
    pauseChange = null;
    return change;
  }

  @override
  Future<String?> takeOpenTab() async {
    final tab = openTab;
    openTab = null;
    return tab;
  }

  @override
  Future<Map<int, int>> drainTaps() async {
    drains++;
    final result = taps;
    taps = const {};
    return result;
  }
}
