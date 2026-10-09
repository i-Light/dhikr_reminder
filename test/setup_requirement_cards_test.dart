import 'package:dhikr_reminder/features/mobile_reminders/background_access.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_permission_dialog.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_health.dart';
import 'package:dhikr_reminder/features/mobile_reminders/setup_requirement_cards.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_background_access.dart';
import 'helpers/fake_overlay.dart';

class _Setup {
  _Setup(this.overlay, this.background);
  final FakeOverlay overlay;
  final FakeBackgroundAccess background;
}

Future<_Setup> _pump(
  WidgetTester tester,
  PlatformKind kind, {
  required bool overlayAllowed,
  required bool backgroundAllowed,
  Locale locale = const Locale('en'),
  ReminderHealth? health,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final overlay = FakeOverlay(allowed: overlayAllowed)..healthNow = health;
  final background = FakeBackgroundAccess(unrestricted: backgroundAllowed);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPlatformProvider.overrideWithValue(AppPlatform(kind)),
        reminderOverlayProvider.overrideWithValue(overlay),
        backgroundAccessProvider.overrideWithValue(background),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SingleChildScrollView(
          child: SetupRequirementCards(),
        )),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Setup(overlay, background);
}

const _overlayKey = ValueKey('requirement-overlay');
const _backgroundKey = ValueKey('requirement-background');

void main() {
  testWidgets('shows a red card for each permission that is missing',
      (tester) async {
    await _pump(
      tester,
      PlatformKind.android,
      overlayAllowed: false,
      backgroundAllowed: false,
    );

    expect(find.byKey(_overlayKey), findsOneWidget);
    expect(find.byKey(_backgroundKey), findsOneWidget);
    expect(find.text("Reminders can't show over other apps"), findsOneWidget);
    expect(find.text('Reminders may stop after a while'), findsOneWidget);

    final card = tester.widget<Card>(
      find.descendant(
        of: find.byKey(_overlayKey),
        matching: find.byType(Card),
      ),
    );
    final scheme = Theme.of(tester.element(find.byKey(_overlayKey))).colorScheme;
    expect(card.color, scheme.errorContainer);
  });

  testWidgets('shows only the one that is missing', (tester) async {
    await _pump(
      tester,
      PlatformKind.android,
      overlayAllowed: true,
      backgroundAllowed: false,
    );

    expect(find.byKey(_overlayKey), findsNothing);
    expect(find.byKey(_backgroundKey), findsOneWidget);
  });

  testWidgets('shows nothing once everything is allowed', (tester) async {
    await _pump(
      tester,
      PlatformKind.android,
      overlayAllowed: true,
      backgroundAllowed: true,
    );

    expect(find.byType(Card), findsNothing);
    expect(find.text('Allow'), findsNothing);
  });

  testWidgets('shows nothing on Windows', (tester) async {
    await _pump(
      tester,
      PlatformKind.windows,
      overlayAllowed: false,
      backgroundAllowed: false,
    );

    expect(find.byType(Card), findsNothing);
  });

  testWidgets('the overlay card shows the preview before it opens settings',
      (tester) async {
    final setup = await _pump(
      tester,
      PlatformKind.android,
      overlayAllowed: false,
      backgroundAllowed: true,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(_overlayKey),
        matching: find.text('Allow'),
      ),
    );
    await tester.pumpAndSettle();

    // Nothing has been opened yet: the person is looking at the preview.
    expect(setup.overlay.permissionRequests, 0);
    expect(find.byType(OverlaySettingsPreview), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Allow'),
      ),
    );
    await tester.pumpAndSettle();
    expect(setup.overlay.permissionRequests, 1);
  });

  testWidgets('the overlay card can be dismissed without opening settings',
      (tester) async {
    final setup = await _pump(
      tester,
      PlatformKind.android,
      overlayAllowed: false,
      backgroundAllowed: true,
    );

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(setup.overlay.permissionRequests, 0);
    // Still missing, so the card stays.
    expect(find.byKey(_overlayKey), findsOneWidget);
  });

  testWidgets('the background card asks the phone straight away',
      (tester) async {
    final setup = await _pump(
      tester,
      PlatformKind.android,
      overlayAllowed: true,
      backgroundAllowed: false,
    );

    await tester.tap(find.text('Allow'));
    await tester.pump();

    expect(setup.background.requests, 1);
  });

  testWidgets('renders in Arabic without overflowing', (tester) async {
    await _pump(
      tester,
      PlatformKind.android,
      overlayAllowed: false,
      backgroundAllowed: false,
      locale: const Locale('ar'),
    );

    expect(find.text('التذكيرات مش هتظهر فوق التطبيقات التانية'),
        findsOneWidget);
    expect(find.text('التذكيرات ممكن تقف بعد شوية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('the two cards that only appear when they are true', () {
    const stoppedKey = ValueKey('requirement-stopped');
    const notificationsKey = ValueKey('requirement-notifications');

    testWidgets('nothing shows while reminders arrive', (tester) async {
      await _pump(
        tester,
        PlatformKind.android,
        overlayAllowed: true,
        backgroundAllowed: true,
        health: const ReminderHealth(armed: 10),
      );
      expect(find.byKey(stoppedKey), findsNothing);
      expect(find.byKey(notificationsKey), findsNothing);
    });

    testWidgets('reminders that stopped coming say so and open the settings',
        (tester) async {
      final setup = await _pump(
        tester,
        PlatformKind.android,
        overlayAllowed: true,
        backgroundAllowed: true,
        health: const ReminderHealth(armed: 10, stopped: true),
      );
      expect(find.byKey(stoppedKey), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byKey(stoppedKey),
        matching: find.byType(FilledButton),
      ));
      expect(setup.overlay.appLaunchSettingsOpened, 1);
    });

    testWidgets('no stopped card while the battery card is the cause',
        (tester) async {
      await _pump(
        tester,
        PlatformKind.android,
        overlayAllowed: true,
        backgroundAllowed: false,
        health: const ReminderHealth(armed: 10, stopped: true),
      );
      expect(find.byKey(_backgroundKey), findsOneWidget);
      expect(find.byKey(stoppedKey), findsNothing);
    });

    testWidgets(
        'notifications off with no card allowed is the one case that cannot '
        'be seen at all', (tester) async {
      final setup = await _pump(
        tester,
        PlatformKind.android,
        overlayAllowed: false,
        backgroundAllowed: true,
        health: const ReminderHealth(notificationsEnabled: false),
      );
      expect(find.byKey(notificationsKey), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byKey(notificationsKey),
        matching: find.byType(FilledButton),
      ));
      expect(setup.overlay.notificationSettingsOpened, 1);
    });

    testWidgets('notifications off is fine while the card is allowed',
        (tester) async {
      await _pump(
        tester,
        PlatformKind.android,
        overlayAllowed: true,
        backgroundAllowed: true,
        health: const ReminderHealth(notificationsEnabled: false),
      );
      expect(find.byKey(notificationsKey), findsNothing);
    });

    test('the bug report snapshot holds no dhikr text, only times and paths', () {
      final health = ReminderHealth.fromMap(const {
        'stopped': true,
        'armed': 3,
        'events': ['1700000000000|notification|ForegroundServiceStartNotAllowedException'],
      });
      expect(health.stopped, isTrue);
      expect(health.describe(), contains('STOPPED'));
      expect(health.describe(), contains('ForegroundServiceStartNotAllowedException'));
    });
  });
}
