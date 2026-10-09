import 'package:dhikr_reminder/features/history/history.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the person has counted: today, the last seven days as small bars, three
/// totals and, if they want it, how many days in a row. All of it is on the
/// device. Nothing here compares, rewards or scolds: a quiet day is just a short
/// bar.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final totals = ref.watch(historyProvider);
    final today = ref.watch(dhikrStatsClockProvider)();
    final showStreak = ref.watch(showStreakProvider);
    final muted = theme.colorScheme.onSurfaceVariant;

    final todayTotal = totals[dayKeyBack(today, 0)] ?? 0;
    final streak = streakDays(totals, today);

    Widget stat(String label, int value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              Text(
                '$value',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyRowTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (totals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.historyEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  )
                else ...[
                  Center(
                    child: Text(
                      '$todayTotal',
                      key: const ValueKey('history-today'),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      l10n.historyToday,
                      style: theme.textTheme.labelLarge?.copyWith(color: muted),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _WeekBars(totals: totals, today: today),
                  const SizedBox(height: 20),
                  stat(l10n.historyLast7, totalOverDays(totals, today, 7)),
                  stat(l10n.historyLast30, totalOverDays(totals, today, 30)),
                  stat(
                    l10n.historyTotal,
                    totals.values.fold(0, (sum, value) => sum + value),
                  ),
                  if (showStreak && streak > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.historyStreak(streak),
                      key: const ValueKey('history-streak'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
                const Divider(height: 32),
                SwitchListTile(
                  key: const ValueKey('history-streak-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.historyStreakSwitch),
                  value: showStreak,
                  onChanged: ref.read(showStreakProvider.notifier).set,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The last seven days as bars, oldest on the left of the reading direction,
/// each as tall as its total is compared with the busiest of the seven.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.totals, required this.today});

  final Map<String, int> totals;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final days = [
      for (var back = 6; back >= 0; back--)
        DateTime(today.year, today.month, today.day - back),
    ];
    final values = [for (final day in days) totals[dhikrDayKey(day)] ?? 0];
    final busiest = values.fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: busiest == 0
                              ? 0.04
                              : (values[i] / busiest).clamp(0.04, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: i == days.length - 1
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const SizedBox(width: double.infinity),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.narrowWeekdays[days[i].weekday % 7],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
