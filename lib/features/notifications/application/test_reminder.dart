import 'package:dhikr_reminder/features/library/application/transliteration_controller.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "show me one now" button's action. On a phone with "display over other
/// apps" allowed it shows the same floating card a real reminder does;
/// otherwise the in-app one.
Future<void> showTestReminder(BuildContext context, WidgetRef ref) async {
  final entry = ref.read(activeDhikrReminderProvider.notifier).testEntry();
  if (entry == null) return;
  await showReminderFor(context, ref, entry);
}

/// Shows [entry] as a reminder right now, counted like any other: the floating
/// card on a phone that allows it, the in-app one otherwise, the card window on
/// Windows. This is also "Count now" in the library: the counter is the
/// reminder card the person already knows, so there is nothing new to learn.
Future<void> showReminderFor(
  BuildContext context,
  WidgetRef ref,
  DhikrEntry entry,
) async {
  final reminders = ref.read(activeDhikrReminderProvider.notifier);
  if (ref.read(appPlatformProvider).usesNotifications) {
    final l10n = AppLocalizations.of(context);
    final overlay = ref.read(reminderOverlayProvider);
    // The card reads whether to hide the Arabic when it appears; make sure it
    // reads what the settings say now.
    await overlay.setArabicHidden(
      !ref.read(dhikrSettingsProvider).overlayShowArabic,
    );
    final shown = await overlay.showNow(
      dhikrId: entry.id,
      text: entry.name,
      amount: entry.amount,
      goal: entry.dailyGoal,
      translit: ref.read(showTransliterationProvider)
          ? entry.transliteration ?? ''
          : '',
      title: l10n.dhikrReminderTitle,
      closeLabel: l10n.commonClose,
      tip: l10n.dhikrReminderTouchEverywhereTip,
      dayLabel: l10n.statToday,
    );
    if (shown) return;
  }
  reminders.show(entry);
}
