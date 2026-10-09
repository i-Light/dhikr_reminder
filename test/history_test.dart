import 'dart:convert';

import 'package:dhikr_reminder/features/history/history.dart';
import 'package:dhikr_reminder/features/history/history_screen.dart';
import 'package:dhikr_reminder/features/settings/presentation/home_screen.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _daysKey = 'dhikr_reminder.history.days';
final _today = DateTime(2026, 10, 9);

String _key(int back) => dayKeyBack(_today, back);

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  group('the arithmetic', () {
    test('day keys count calendar days, across a month and a year', () {
      expect(dayKeyBack(DateTime(2026, 3, 1), 1), '2026-02-28');
      expect(dayKeyBack(DateTime(2026, 1, 1), 1), '2025-12-31');
    });

    test('totals over days include today and stop at the window', () {
      final totals = {_key(0): 10, _key(6): 5, _key(7): 100};
      expect(totalOverDays(totals, _today, 7), 15);
      expect(totalOverDays(totals, _today, 8), 115);
    });

    test('the streak counts days in a row ending today', () {
      final totals = {_key(0): 1, _key(1): 4, _key(2): 9, _key(4): 3};
      expect(streakDays(totals, _today), 3);
    });

    test('a day that has not started counting does not break the run', () {
      final totals = {_key(1): 4, _key(2): 9};
      expect(streakDays(totals, _today), 2);
    });

    test('a missed day ends it, and there is no streak from nothing', () {
      expect(streakDays({_key(2): 4, _key(3): 4}, _today), 0);
      expect(streakDays({}, _today), 0);
    });

    test('only the last 400 days are kept', () {
      final totals = {_key(0): 1, _key(399): 2, _key(400): 3, _key(900): 4};
      final kept = pruned(totals, _today);
      expect(kept.keys, containsAll([_key(0), _key(399)]));
      expect(kept.keys, isNot(contains(_key(400))));
      expect(kept.keys, isNot(contains(_key(900))));
    });

    test('damaged saved totals are skipped, never fatal', () {
      expect(decodeTotals(null), isEmpty);
      expect(decodeTotals('not json'), isEmpty);
      expect(decodeTotals('[1,2]'), isEmpty);
      expect(
        decodeTotals('{"2026-10-09":5,"junk":3,"2026-10-08":"x","2026-10-07":0}'),
        {'2026-10-09': 5},
      );
    });
  });

  group('the saved totals', () {
    test('a count is added to its day and remembered', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(historyProvider);
      await _settle();

      container.read(historyProvider.notifier).add('2026-10-09', 3);
      container.read(historyProvider.notifier).add('2026-10-09', 2);
      await _settle();

      expect(container.read(historyProvider), {'2026-10-09': 5});
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString(_daysKey)!), {'2026-10-09': 5});
    });

    test('earlier days are read back and added to', () async {
      SharedPreferences.setMockInitialValues({
        _daysKey: jsonEncode({'2026-10-08': 7, '2026-10-09': 1}),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(historyProvider);
      await _settle();

      container.read(historyProvider.notifier).add('2026-10-09', 4);

      expect(container.read(historyProvider)['2026-10-08'], 7);
      expect(container.read(historyProvider)['2026-10-09'], 5);
    });

    test('a count made before the saved totals arrive is not lost', () async {
      SharedPreferences.setMockInitialValues({
        _daysKey: jsonEncode({'2026-10-09': 10}),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // No wait: the load has not finished.
      container.read(historyProvider.notifier).add('2026-10-09', 2);
      await _settle();

      expect(container.read(historyProvider)['2026-10-09'], 12);
    });

    test('every tap the app counts lands in the history', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [dhikrStatsClockProvider.overrideWithValue(() => _today)],
      );
      addTearDown(container.dispose);
      container.read(historyProvider);
      await _settle();

      final stats = container.read(dhikrStatsProvider.notifier);
      stats.recordTap(1);
      stats.recordTaps(2, 5);
      await _settle();

      expect(container.read(historyProvider)[_key(0)], 6);
    });
  });

  group('the History page', () {
    Future<ProviderContainer> pump(
      WidgetTester tester, {
      Map<String, int> totals = const {},
      Locale locale = const Locale('en'),
    }) async {
      SharedPreferences.setMockInitialValues({
        if (totals.isNotEmpty) _daysKey: jsonEncode(totals),
      });
      final container = ProviderContainer(
        overrides: [dhikrStatsClockProvider.overrideWithValue(() => _today)],
      );
      addTearDown(container.dispose);
      container.read(historyProvider);
      await tester.runAsync(_settle);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('says so, kindly, when nothing has been counted',
        (tester) async {
      await pump(tester);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(HistoryScreen)));
      expect(find.text(l10n.historyEmpty), findsOneWidget);
      expect(find.byKey(const ValueKey('history-streak')), findsNothing);
    });

    for (final lang in ['en', 'ar']) {
      testWidgets('shows today, the totals and the run in $lang',
          (tester) async {
        await pump(
          tester,
          locale: Locale(lang),
          totals: {
            _key(0): 30,
            _key(1): 20,
            _key(2): 10,
            _key(15): 5,
            _key(40): 40,
          },
        );
        final l10n =
            AppLocalizations.of(tester.element(find.byType(HistoryScreen)));

        expect(
          tester.widget<Text>(find.byKey(const ValueKey('history-today'))).data,
          '30',
        );
        expect(find.text(l10n.historyStreak(3)), findsOneWidget);
        expect(find.text('60'), findsOneWidget); // last 7 days
        expect(find.text('65'), findsOneWidget); // last 30 days
        expect(find.text('105'), findsOneWidget); // in total
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the days-in-a-row line can be switched off and stays off',
        (tester) async {
      final container = await pump(tester, totals: {_key(0): 5, _key(1): 5});
      expect(find.byKey(const ValueKey('history-streak')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('history-streak-switch')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('history-streak')), findsNothing);
      expect(container.read(showStreakProvider), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dhikr_reminder.history.showStreak'), isFalse);
    });

    testWidgets('never says anything about a missed day', (tester) async {
      await pump(tester, totals: {_key(3): 8});
      final l10n =
          AppLocalizations.of(tester.element(find.byType(HistoryScreen)));
      // A gap is a short bar and no streak line, with no words about it.
      expect(find.byKey(const ValueKey('history-streak')), findsNothing);
      expect(find.textContaining('miss'), findsNothing);
      expect(find.textContaining('lost'), findsNothing);
      expect(find.text(l10n.historyEmpty), findsNothing);
    });
  });

  testWidgets('the home page has one row that opens the History page',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      _daysKey: jsonEncode({_key(0): 12}),
    });
    final container = ProviderContainer(
      overrides: [dhikrStatsClockProvider.overrideWithValue(() => _today)],
    );
    addTearDown(container.dispose);
    container.read(historyProvider);
    await tester.runAsync(_settle);
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Today: 12'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('history-row')));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);

    // The home page's tickers must be gone before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
