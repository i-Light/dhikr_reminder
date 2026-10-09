import 'package:dhikr_reminder/features/mobile_reminders/background_access.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_permission_dialog.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_health.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// On a phone, one red card for each thing the reminders need and the person
/// has not allowed: showing over other apps, and running in the background.
/// Two more appear only when they are true: notifications are off with no card
/// allowed either (reminders could not be seen at all), and reminders have
/// stopped coming (the phone is closing the app).
///
/// They stay for as long as the permission is missing, however many times the
/// start-up pop-up was dismissed, because without them reminders either look
/// like easy-to-miss notifications or stop coming altogether. Nothing is shown
/// where nothing is missing (and on Windows, which needs neither).
class SetupRequirementCards extends ConsumerWidget {
  const SetupRequirementCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appPlatformProvider).usesNotifications) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    // Unknown (still asking the phone) counts as fine: a card that flashes up
    // and goes is worse than one that appears a moment late.
    final overlayAllowed = ref.watch(overlayAllowedProvider).value ?? true;
    final backgroundAllowed =
        ref.watch(backgroundAllowedProvider).value ?? true;
    final health = ref.watch(reminderHealthProvider).value;
    final invisible = (health?.notificationsBlocked ?? false) && !overlayAllowed;
    final stopped = health?.stopped ?? false;
    if (overlayAllowed && backgroundAllowed && !invisible && !stopped) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        spacing: 12,
        children: [
          if (!overlayAllowed)
            _RequirementCard(
              key: const ValueKey('requirement-overlay'),
              icon: Icons.layers_outlined,
              title: l10n.overlayMissingTitle,
              body: l10n.overlayMissingBody,
              onFix: () => askForOverlayPermission(context, ref),
            ),
          if (!backgroundAllowed)
            _RequirementCard(
              key: const ValueKey('requirement-background'),
              icon: Icons.battery_alert_outlined,
              title: l10n.batteryMissingTitle,
              body: l10n.batteryMissingBody,
              onFix: ref.read(backgroundAllowedProvider.notifier).request,
            ),
          if (invisible)
            _RequirementCard(
              key: const ValueKey('requirement-notifications'),
              icon: Icons.notifications_off_outlined,
              title: l10n.notifBlockedTitle,
              body: l10n.notifBlockedBody,
              actionLabel: l10n.commonOpenSettings,
              onFix: () =>
                  ref.read(reminderOverlayProvider).openNotificationSettings(),
            ),
          // Only once the background permission is in place: with it missing
          // the card above is the cause and the fix.
          if (stopped && backgroundAllowed)
            _RequirementCard(
              key: const ValueKey('requirement-stopped'),
              icon: Icons.notifications_paused_outlined,
              title: l10n.remindersStoppedTitle,
              body: l10n.remindersStoppedBody,
              actionLabel: l10n.commonOpenSettings,
              onFix: () =>
                  ref.read(reminderOverlayProvider).openAppLaunchSettings(),
            ),
        ],
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onFix,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onFix;

  /// The button's words; "Allow" when not given.
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.error, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Icon(icon, color: scheme.error),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: onFix,
                // The card's own two colours swapped: light on the dark red of
                // the dark theme, dark on the pale red of the light one.
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.onErrorContainer,
                  foregroundColor: scheme.errorContainer,
                ),
                child: Text(
                  actionLabel ?? AppLocalizations.of(context).commonAllow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
