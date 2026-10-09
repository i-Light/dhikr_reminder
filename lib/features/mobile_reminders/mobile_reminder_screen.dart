import 'package:dhikr_reminder/core/toast/dhikr_fit_text.dart';
import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/core/window/app_logo.dart';
import 'package:dhikr_reminder/features/library/application/transliteration_controller.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_display.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
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
    final showTransliteration = ref.watch(showTransliterationProvider);
    final display = resolveDhikrDisplay(
      arabic: reminder.entry.name,
      transliteration: reminder.entry.transliteration,
      showTransliteration: showTransliteration,
      showArabic: ref.watch(
        dhikrSettingsProvider.select((s) => s.overlayShowArabic),
      ),
    );
    // The same button as the desktop card's: English only, and only where there
    // is a transliteration to read in the Arabic's place.
    final canToggleArabic =
        showTransliteration && reminder.entry.transliteration != null;

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
                        if (canToggleArabic) ...[
                          DhikrArabicToggleButton(
                            arabicShown: display.hasArabic,
                            color: palette.accent,
                            size: 32,
                            tooltip: display.hasArabic
                                ? l10n.dhikrReminderHideArabic
                                : l10n.dhikrReminderShowArabic,
                            onPressed: () => ref
                                .read(dhikrSettingsProvider.notifier)
                                .updateOverlayShowArabic(!display.hasArabic),
                          ),
                          const SizedBox(width: 8),
                        ],
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
                        child:
                            _ReminderText(display: display, color: textColor),
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

/// The dhikr on this screen: the Arabic at one size, scrolling when it is long;
/// and, when there is a transliteration, the Arabic with it under, or alone
/// when the Arabic is switched off, sized together to the room there is (the
/// same fitting the desktop card uses) so the Latin letters are never pushed
/// off the bottom of a long dhikr.
class _ReminderText extends StatelessWidget {
  const _ReminderText({required this.display, required this.color});

  final DhikrDisplay display;
  final Color color;

  static const _arabicSize = 34.0;
  static const _aloneSize = 30.0;

  @override
  Widget build(BuildContext context) {
    final arabicStyle = TextStyle(
      fontFamily: 'NotoSansArabic',
      height: 1.7,
      color: color,
    );
    if (!display.hasTransliteration) {
      return SingleChildScrollView(
        child: Text(
          display.arabic!,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: arabicStyle.copyWith(fontSize: _arabicSize),
        ),
      );
    }

    final latinStyle = TextStyle(
      height: 1.4,
      color: display.hasArabic ? color.withValues(alpha: 0.85) : color,
    );
    return DhikrFitStack(
      gap: 12,
      // As big as the old fixed size and no bigger, whatever the room.
      maxFontSize: display.hasArabic ? _arabicSize : _aloneSize,
      minFillRatio: 1,
      blocks: [
        if (display.hasArabic)
          DhikrFitBlock(
            block: DhikrTextBlock(
              text: display.arabic!,
              style: arabicStyle,
              textDirection: TextDirection.rtl,
            ),
            builder: (context, fontSize) => Text(
              display.arabic!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              textScaler: TextScaler.noScaling,
              style: arabicStyle.copyWith(fontSize: fontSize),
            ),
          ),
        DhikrFitBlock(
          block: DhikrTextBlock(
            text: display.transliteration!,
            style: latinStyle,
            textDirection: TextDirection.ltr,
            scale: display.hasArabic ? kTransliterationRatio : 1,
            minFontSize: display.hasArabic ? kTransliterationMinFontSize : 14,
          ),
          builder: (context, fontSize) => Text(
            display.transliteration!,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            textScaler: TextScaler.noScaling,
            style: latinStyle.copyWith(fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}
