import 'package:dhikr_reminder/app.dart';
import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_screen.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_overlay.dart';

ProviderContainer _container(PlatformKind kind, [FakeOverlay? overlay]) {
  final container = ProviderContainer(
    overrides: [
      appPlatformProvider.overrideWithValue(AppPlatform(kind)),
      reminderOverlayProvider.overrideWithValue(overlay ?? FakeOverlay()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  testWidgets(
    'on Android the app asks for the notification permission and shows the '
    'counter over the app while a reminder is active',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final overlay = FakeOverlay();
      final container = _container(PlatformKind.android, overlay);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DhikrReminderApp(),
        ),
      );
      await tester.pump();

      expect(overlay.notificationPermissionRequests, 1);
      expect(find.byType(MobileReminderScreen), findsNothing);

      container
          .read(activeDhikrReminderProvider.notifier)
          .show(const DhikrEntry(id: 1, name: 'dhikr text', amount: 3));
      await tester.pump();

      expect(find.byType(MobileReminderScreen), findsOneWidget);
      expect(find.text('dhikr text'), findsOneWidget);

      // Let the debounced schedule sync run out, then unmount: no timer may be
      // left pending when the test ends.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );

  testWidgets('on Windows no phone plumbing is started', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final overlay = FakeOverlay();
    final container = _container(PlatformKind.windows, overlay);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DhikrReminderApp(),
      ),
    );
    await tester.pump();

    expect(overlay.notificationPermissionRequests, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets(
      'taps made on the overlay while the app was closed are counted '
      'when it starts', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final overlay = FakeOverlay(allowed: true, taps: {4: 12});
    final container = _container(PlatformKind.android, overlay);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DhikrReminderApp(),
      ),
    );
    await tester.pump();

    expect(container.read(dhikrStatsProvider).todayFor(4), 12);
    expect(overlay.drains, greaterThanOrEqualTo(1));

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets(
    'the Arabic button pressed on the card while the app was closed is '
    'taken up once the settings have loaded',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final overlay = FakeOverlay(allowed: true)..arabicHiddenOnCard = true;
      final container = _container(PlatformKind.android, overlay);
      expect(container.read(dhikrSettingsProvider).overlayShowArabic, isTrue);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DhikrReminderApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(container.read(dhikrSettingsProvider).overlayShowArabic, isFalse);
      // And the card is told what the app now says, not left to its own copy.
      expect(overlay.arabicHidden, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );

  testWidgets(
    'the Arabic setting changed in the app is handed to the card at once',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final overlay = FakeOverlay(allowed: true);
      final container = _container(PlatformKind.android, overlay);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DhikrReminderApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.runAsync(
        () => container
            .read(dhikrSettingsProvider.notifier)
            .updateOverlayShowArabic(false),
      );
      await tester.pump();
      expect(overlay.arabicHidden, isTrue);

      await tester.runAsync(
        () => container
            .read(dhikrSettingsProvider.notifier)
            .updateOverlayShowArabic(true),
      );
      await tester.pump();
      expect(overlay.arabicHidden, isFalse);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );

  testWidgets('a tapped reminder notification opens that dhikr\'s counter', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dhikr_reminder.dhikr.entries':
          '[{"id":5,"name":"tapped dhikr","amount":3,"chance":10,"dailyGoal":0}]',
    });
    final overlay = FakeOverlay(allowed: true)..openDhikrId = 5;
    final container = _container(PlatformKind.android, overlay);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DhikrReminderApp(),
      ),
    );
    // Let the saved entries load (real I/O), then the host picks the id up.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(container.read(activeDhikrReminderProvider)?.entry.id, 5);
    expect(overlay.openDhikrId, isNull);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
