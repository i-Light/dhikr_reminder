import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/notifications/presentation/notifications_screen.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_overlay.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  PlatformKind kind,
  FakeOverlay overlay,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [
    appPlatformProvider.overrideWithValue(AppPlatform(kind)),
    reminderOverlayProvider.overrideWithValue(overlay),
  ]);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NotificationsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // The button is among the reminder settings, folded away until wanted.
  await tester.tap(find.byKey(const ValueKey('collapsible-header')));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _finish(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
}

void main() {
  testWidgets('on a phone the test button shows the floating card',
      (tester) async {
    final overlay = FakeOverlay(allowed: true);
    final container = await _pump(tester, PlatformKind.android, overlay);

    await tester.tap(find.byKey(const ValueKey('test-reminder-button')));
    await tester.pumpAndSettle();

    expect(overlay.shownNow, isNotNull);
    expect(container.read(activeDhikrReminderProvider), isNull);
    await _finish(tester, container);
  });

  testWidgets('without the permission it falls back to the in-app card',
      (tester) async {
    final overlay = FakeOverlay(allowed: false);
    final container = await _pump(tester, PlatformKind.android, overlay);

    await tester.tap(find.byKey(const ValueKey('test-reminder-button')));
    await tester.pumpAndSettle();

    expect(overlay.shownNow, isNull);
    expect(container.read(activeDhikrReminderProvider), isNotNull);
    await _finish(tester, container);
  });

  testWidgets('on Windows it shows the in-app card', (tester) async {
    final overlay = FakeOverlay(allowed: true);
    final container = await _pump(tester, PlatformKind.windows, overlay);

    await tester.tap(find.byKey(const ValueKey('test-reminder-button')));
    await tester.pumpAndSettle();

    expect(overlay.shownNow, isNull);
    expect(container.read(activeDhikrReminderProvider), isNotNull);
    await _finish(tester, container);
  });
}
