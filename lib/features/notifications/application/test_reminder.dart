import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "show me one now" button's action. On a phone with "display over other
/// apps" allowed it shows the same floating card a real reminder does;
/// otherwise the in-app one.
Future<void> showTestReminder(BuildContext context, WidgetRef ref) async {
  final reminders = ref.read(activeDhikrReminderProvider.notifier);
  final entry = reminders.testEntry();
  if (entry == null) return;
  if (ref.read(appPlatformProvider).usesNotifications) {
    final l10n = AppLocalizations.of(context);
    final shown = await ref.read(reminderOverlayProvider).showNow(
          dhikrId: entry.id,
          text: entry.name,
          amount: entry.amount,
          goal: entry.dailyGoal,
          title: l10n.dhikrReminderTitle,
          closeLabel: l10n.commonClose,
          tip: l10n.dhikrReminderTouchEverywhereTip,
          dayLabel: l10n.statToday,
        );
    if (shown) return;
  }
  reminders.show(entry);
}
