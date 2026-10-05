import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/notifications/presentation/notifications_screen.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_overlay.dart';

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

  testWidgets('a new dhikr starts at 3 repetitions', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('dhikr-name-field')),
      'three',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = container
        .read(dhikrSettingsProvider)
        .entries
        .firstWhere((e) => e.name == 'three');
    expect(saved.amount, 3);
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

  group('the show-over-other-apps card', () {
    Future<FakeOverlay> pumpAs(
      WidgetTester tester,
      PlatformKind kind, {
      required bool allowed,
    }) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final overlay = FakeOverlay(allowed: allowed);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPlatformProvider.overrideWithValue(AppPlatform(kind)),
            reminderOverlayProvider.overrideWithValue(overlay),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: NotificationsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return overlay;
    }

    testWidgets('asks for the permission on Android until it is granted',
        (tester) async {
      final overlay =
          await pumpAs(tester, PlatformKind.android, allowed: false);

      expect(find.text('Show over other apps'), findsOneWidget);
      await tester.tap(find.text('Allow'));
      await tester.pump();

      expect(overlay.permissionRequests, 1);
    });

    testWidgets('is gone once the permission is granted', (tester) async {
      await pumpAs(tester, PlatformKind.android, allowed: true);

      expect(find.text('Show over other apps'), findsNothing);
      expect(find.text('Allow'), findsNothing);
      expect(find.text('Allowed'), findsNothing);
    });

    testWidgets('does not exist on Windows', (tester) async {
      await pumpAs(tester, PlatformKind.windows, allowed: false);

      expect(find.text('Show over other apps'), findsNothing);
    });
  });
}
