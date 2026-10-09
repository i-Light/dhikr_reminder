import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
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
  int drains = 0;

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
  }) async {
    scheduled = plan;
    this.interval = interval;
    this.title = title;
    this.closeLabel = closeLabel;
    this.tip = tip;
    this.dayLabel = dayLabel;
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

  @override
  Future<Map<int, int>> drainTaps() async {
    drains++;
    final result = taps;
    taps = const {};
    return result;
  }
}
