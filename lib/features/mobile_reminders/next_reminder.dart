import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When the next reminder arrives, as the phone's alarms really hold it. On a
/// phone Dart is not what fires reminders, so an in-process countdown would be
/// a guess; this asks the native side instead. Null on any other platform (the
/// desktop scheduler has its own countdown) and when nothing is armed.
class NextReminderNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    if (ref.read(appPlatformProvider).usesNotifications) {
      Future.microtask(refresh);
    }
    return null;
  }

  Future<void> refresh() async {
    if (!ref.read(appPlatformProvider).usesNotifications) return;
    final next = await ref.read(reminderOverlayProvider).nextReminderAt();
    if (ref.mounted) state = next;
  }
}

final nextReminderProvider = NotifierProvider<NextReminderNotifier, DateTime?>(
  NextReminderNotifier.new,
);
