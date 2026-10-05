import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';

/// A [ReminderOverlay] that remembers what it was asked to do.
class FakeOverlay implements ReminderOverlay {
  FakeOverlay({this.allowed = false, this.taps = const {}});

  bool allowed;
  Map<int, int> taps;

  List<PlannedReminder>? scheduled;
  String? title;
  String? closeLabel;
  String? tip;
  int cancels = 0;
  int permissionRequests = 0;
  int drains = 0;

  @override
  Future<bool> canDraw() async => allowed;

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<void> schedule(
    List<PlannedReminder> plan, {
    required String title,
    required String closeLabel,
    required String tip,
  }) async {
    scheduled = plan;
    this.title = title;
    this.closeLabel = closeLabel;
    this.tip = tip;
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
