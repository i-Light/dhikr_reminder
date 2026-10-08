import 'package:dhikr_reminder/features/settings/presentation/home_screen.dart';
import 'package:dhikr_reminder/features/settings/presentation/widgets/bug_report_card.dart';
import 'package:dhikr_reminder/features/settings/presentation/widgets/update_card.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, String lang) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              HijriDateCard(clock: () => DateTime(2025, 6, 26)),
              const Expanded(child: HomeScreen()),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the Hijri date in Arabic', (tester) async {
    await _pump(tester, 'ar');
    final text = tester
        .widget<Text>(find.byKey(const ValueKey('hijri-date')).first)
        .data!;
    expect(text, contains('١٤٤٧'));
    expect(text, endsWith('هـ'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the Hijri date in English', (tester) async {
    await _pump(tester, 'en');
    final text = tester
        .widget<Text>(find.byKey(const ValueKey('hijri-date')).first)
        .data!;
    expect(text, contains('1447'));
    expect(text, endsWith('AH'));
    expect(tester.takeException(), isNull);
  });

  group('the settings page', () {
    testWidgets('has no counters: neither the session nor the day',
        (tester) async {
      await _pump(tester, 'en');

      expect(find.text('This session'), findsNothing);
      expect(find.text('Counted today'), findsNothing);
      expect(find.byIcon(Icons.restart_alt), findsNothing);
      expect(find.byIcon(Icons.bolt), findsNothing);
    });

    testWidgets('has no test button: it moved to the notifications page',
        (tester) async {
      await _pump(tester, 'en');

      expect(find.text('Show a reminder now'), findsNothing);
    });

    testWidgets('puts the pause button on the same line as the timer',
        (tester) async {
      await _pump(tester, 'en');

      final button = tester.getRect(find.byKey(const ValueKey('pause-button')));
      final label = tester.getRect(find.text('Next reminder'));
      // One line: the button's middle is level with the timer's block.
      expect((button.center.dy - label.center.dy).abs(), lessThan(40));
      expect(button.left, greaterThan(label.right));
    });

    testWidgets('pauses, and offers to resume', (tester) async {
      await _pump(tester, 'en');

      expect(find.text('Pause 1 h'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pause-button')));
      await tester.pump();

      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Pause 1 h'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('pause-button')));
      await tester.pump();
      expect(find.text('Pause 1 h'), findsOneWidget);
    });

    testWidgets('keeps the report button near the top, not at the bottom',
        (tester) async {
      await _pump(tester, 'en');

      final report = tester.getTopLeft(find.byType(BugReportCard)).dy;
      final next = tester.getTopLeft(find.text('Next reminder')).dy;
      final update = tester.getTopLeft(find.byType(UpdateCard)).dy;
      expect(report, greaterThan(next));
      expect(report, lessThan(update));
    });

    for (final lang in ['en', 'ar']) {
      testWidgets('renders in $lang on a narrow phone without overflowing',
          (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: HomeScreen()),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('pause-button')), findsOneWidget);
      });
    }
  });
}
