import 'package:dhikr_reminder/features/notifications/presentation/notifications_screen.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester,
    {String lang = 'en'}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: NotificationsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  for (final lang in ['en', 'ar']) {
    testWidgets('renders in $lang without overflowing', (tester) async {
      await _pump(tester, lang: lang);
      expect(tester.takeException(), isNull);
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });
  }

  testWidgets('adding a dhikr saves it straight away', (tester) async {
    final container = await _pump(tester);
    final before = container.read(dhikrSettingsProvider).entries.length;

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('dhikr-name-field')),
      'سبحان الله',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final entries = container.read(dhikrSettingsProvider).entries;
    expect(entries.length, before + 1);
    expect(entries.last.name, 'سبحان الله');
  });

  testWidgets('an empty dhikr cannot be saved', (tester) async {
    final container = await _pump(tester);
    final before = container.read(dhikrSettingsProvider).entries.length;

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Write the dhikr first'), findsOneWidget);
    expect(container.read(dhikrSettingsProvider).entries.length, before);
  });

  testWidgets('deleting offers undo', (tester) async {
    final container = await _pump(tester);
    final before = container.read(dhikrSettingsProvider).entries.length;

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(container.read(dhikrSettingsProvider).entries.length, before - 1);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(container.read(dhikrSettingsProvider).entries.length, before);
  });

  testWidgets('an interval shortcut applies at once', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();

    expect(container.read(dhikrSettingsProvider).intervalMinutes, 15);
  });

  testWidgets('a daily goal is set inside the dhikr editor', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('dhikr-name-field')),
      'goal dhikr',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('dhikr-goal-switch')));
    await tester.tap(find.byKey(const ValueKey('dhikr-goal-switch')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('300'));
    await tester.tap(find.text('300'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = container
        .read(dhikrSettingsProvider)
        .entries
        .firstWhere((e) => e.name == 'goal dhikr');
    expect(saved.dailyGoal, 300);
  });

  testWidgets('a dhikr has no daily goal unless one is switched on',
      (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('dhikr-name-field')),
      'plain dhikr',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = container
        .read(dhikrSettingsProvider)
        .entries
        .firstWhere((e) => e.name == 'plain dhikr');
    expect(saved.dailyGoal, 0);
  });
}
