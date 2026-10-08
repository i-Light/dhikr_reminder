import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/core/window/app_logo.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone's counterpart of the floating reminder card: a full-screen,
/// tap-anywhere counter shown over the app while a reminder is active (opened
/// by tapping its notification).
///
/// Reaching the target is handled by `DhikrReminderHost`, which dismisses the
/// reminder a moment after completion, exactly as on Windows.
class MobileReminderScreen extends ConsumerWidget {
  const MobileReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminder = ref.watch(activeDhikrReminderProvider);
    if (reminder == null) return const SizedBox.shrink();
    final stats = ref.watch(dhikrStatsProvider);

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notifier = ref.read(activeDhikrReminderProvider.notifier);
    final palette = DhikrPalette.forState(isComplete: reminder.isComplete);
    final progress = reminder.hasTarget
        ? (reminder.count / reminder.entry.amount).clamp(0.0, 1.0)
        : null;
    const textColor = Color(0xFFF6E7C8);

    return Material(
      color: const Color(0xFF1B140B),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: palette.cardOpacity,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: palette.cardFill),
            ),
          ),
          SafeArea(
            child: InkWell(
              key: const ValueKey('mobile-reminder-tap-area'),
              onTap: reminder.isComplete
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      notifier.increment();
                    },
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const AppLogo(size: 28, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.dhikrReminderTitle,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: palette.accent),
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          onPressed: notifier.dismiss,
                          icon: Icon(Icons.close, color: palette.accent),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            reminder.entry.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontSize: 34,
                              height: 1.7,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress ?? 1,
                            strokeWidth: 8,
                            color: palette.accent,
                            backgroundColor: palette.progressTrack,
                          ),
                          Center(
                            child: reminder.isComplete
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 64,
                                    color: palette.accent,
                                  )
                                : Text(
                                    reminder.hasTarget
                                        ? '${reminder.count} / ${reminder.entry.amount}'
                                        : '${reminder.count}',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(color: palette.accent),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // This dhikr's own count for the day, in the dhikr's colour.
                    if (reminder.entry.dailyGoal > 0) ...[
                      DhikrStatChip(
                        label: l10n.statToday,
                        value: stats.forToday(
                          dhikrDayKey(ref.watch(dhikrStatsClockProvider)()),
                          reminder.entry.id,
                        ),
                        goal: reminder.entry.dailyGoal,
                        color: textColor,
                        fontSize: 18,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      l10n.dhikrReminderTouchEverywhereTip,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
