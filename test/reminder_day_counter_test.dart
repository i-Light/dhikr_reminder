import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Today's day key, the way the card works it out.
String get _today => dhikrDayKey(DateTime.now());

Future<void> _pump(
  WidgetTester tester, {
  required DhikrEntry entry,
  required DhikrStats stats,
  String locale = 'en',
}) async {
  // The size the reminder window ships at.
  tester.view.physicalSize = const Size(1120, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DhikrReminderSurface(
          reminder: ActiveDhikrReminder(entry: entry),
          stats: stats,
          onTap: () {},
          onDismiss: () {},
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  const withGoal =
      DhikrEntry(id: 1, name: 'سبحان الله', amount: 3, dailyGoal: 100);
  const other = DhikrEntry(id: 2, name: 'الحمد لله', amount: 3, dailyGoal: 50);
  const plain = DhikrEntry(id: 3, name: 'الله أكبر', amount: 3);

  testWidgets('has no session counter, whatever has been counted',
      (tester) async {
    await _pump(
      tester,
      entry: withGoal,
      stats: DhikrStats(day: _today, byDhikr: const {1: 12, 2: 7}),
    );

    expect(find.text('Session'), findsNothing);
    expect(find.byType(DhikrStatChip), findsOneWidget);
  });

  testWidgets("shows this dhikr's own day count against its goal",
      (tester) async {
    await _pump(
      tester,
      entry: withGoal,
      stats: DhikrStats(day: _today, byDhikr: const {1: 42, 2: 7}),
    );

    expect(find.text('42 / 100'), findsOneWidget);
    expect(find.text("Today's dhikr"), findsOneWidget);
  });

  testWidgets('counts each dhikr on its own', (tester) async {
    final stats = DhikrStats(day: _today, byDhikr: const {1: 42, 2: 7});

    await _pump(tester, entry: other, stats: stats);

    expect(find.text('7 / 50'), findsOneWidget);
    expect(find.text('42 / 100'), findsNothing);
  });

  testWidgets('a dhikr with no goal has no day counter', (tester) async {
    await _pump(
      tester,
      entry: plain,
      stats: DhikrStats(day: _today, byDhikr: const {3: 9}),
    );

    expect(find.byType(DhikrStatChip), findsNothing);
  });

  testWidgets("yesterday's count is not shown as today's", (tester) async {
    await _pump(
      tester,
      entry: withGoal,
      stats: const DhikrStats(day: '2001-01-01', byDhikr: {1: 99}),
    );

    expect(find.text('0 / 100'), findsOneWidget);
  });

  testWidgets("is in the dhikr's own colour, not the gold accent",
      (tester) async {
    await _pump(
      tester,
      entry: withGoal,
      stats: DhikrStats(day: _today, byDhikr: const {1: 5}),
    );

    final chip = tester.widget<DhikrStatChip>(find.byType(DhikrStatChip));
    final theme = Theme.of(tester.element(find.byType(DhikrReminderSurface)));
    final dhikrColor =
        theme.textTheme.displayLarge?.color ?? theme.colorScheme.onSurface;
    expect(chip.color, dhikrColor);
    expect(chip.color, isNot(DhikrPalette.forState(isComplete: false).accent));
    expect(chip.color, isNot(DhikrPalette.forState(isComplete: true).accent));
  });

  testWidgets('keeps its colour when the card turns green on completion',
      (tester) async {
    const entry = withGoal;
    await tester.binding.setSurfaceSize(const Size(1120, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.physicalSize = const Size(1120, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> show(bool complete) => tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DhikrReminderSurface(
                reminder: ActiveDhikrReminder(
                  entry: entry,
                  count: complete ? entry.amount : 0,
                ),
                stats: DhikrStats(day: _today, byDhikr: const {1: 5}),
                onTap: () {},
                onDismiss: () {},
              ),
            ),
          ),
        );

    await show(false);
    await tester.pump(const Duration(milliseconds: 600));
    final before =
        tester.widget<DhikrStatChip>(find.byType(DhikrStatChip)).color;
    await show(true);
    await tester.pump(const Duration(milliseconds: 600));
    final after =
        tester.widget<DhikrStatChip>(find.byType(DhikrStatChip)).color;

    expect(after, before);
  });

  testWidgets('renders in Arabic without overflowing', (tester) async {
    await _pump(
      tester,
      entry: withGoal,
      stats: DhikrStats(day: _today, byDhikr: const {1: 42}),
      locale: 'ar',
    );

    expect(find.text('ذكر النهارده'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
