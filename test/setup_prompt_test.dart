import 'package:dhikr_reminder/features/mobile_reminders/background_access.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_permission_dialog.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/setup_prompt.dart';
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
  bool backgroundAllowed = true,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final overlay = FakeOverlay(allowed: overlayAllowed);
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
        home: const SetupPrompt(child: Scaffold(body: Text('home'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Setup(overlay, background);
}

/// The dialog's own button, not a same-named one on the page behind it.
Finder _inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

void main() {
  const overlayTitle = 'Show reminders over other apps?';
  const batteryTitle = 'Keep reminders running';

  testWidgets('a pop-up asks for the overlay permission when it is missing',
      (tester) async {
    final setup =
        await _pump(tester, PlatformKind.android, overlayAllowed: false);

    expect(find.text(overlayTitle), findsOneWidget);
    await tester.tap(_inDialog('Allow'));
    await tester.pumpAndSettle();

    expect(setup.overlay.permissionRequests, 1);
    expect(find.text(overlayTitle), findsNothing);
    // The system screen did not take the app away in this test, so the next
    // question follows after a moment.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the pop-up shows what the system screen looks like',
      (tester) async {
    await _pump(tester, PlatformKind.android, overlayAllowed: false);

    expect(find.byType(OverlaySettingsPreview), findsOneWidget);
    expect(find.text('Display over other apps'), findsOneWidget);
    expect(find.text('ذِكر'), findsOneWidget);
  });

  testWidgets('the pop-up is in Arabic when the app is', (tester) async {
    await _pump(
      tester,
      PlatformKind.android,
      overlayAllowed: false,
      locale: const Locale('ar'),
    );

    expect(find.text('الظهور فوق التطبيقات الأخرى'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Not now" just closes it', (tester) async {
    final setup =
        await _pump(tester, PlatformKind.android, overlayAllowed: false);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(setup.overlay.permissionRequests, 0);
    expect(find.text(overlayTitle), findsNothing);
  });

  testWidgets('nothing is asked once everything is allowed', (tester) async {
    await _pump(tester, PlatformKind.android, overlayAllowed: true);

    expect(find.text(overlayTitle), findsNothing);
    expect(find.text(batteryTitle), findsNothing);
  });

  testWidgets('nothing is asked on Windows', (tester) async {
    await _pump(
      tester,
      PlatformKind.windows,
      overlayAllowed: false,
      backgroundAllowed: false,
    );

    expect(find.text(overlayTitle), findsNothing);
    expect(find.text(batteryTitle), findsNothing);
  });

  testWidgets('asks to keep running in the background when that is missing',
      (tester) async {
    final setup = await _pump(
      tester,
      PlatformKind.android,
      overlayAllowed: true,
      backgroundAllowed: false,
    );

    expect(find.text(batteryTitle), findsOneWidget);
    await tester.tap(_inDialog('Allow'));
    await tester.pumpAndSettle();

    expect(setup.background.requests, 1);
    expect(setup.overlay.permissionRequests, 0);
  });

  testWidgets('with both missing, one question follows the other',
      (tester) async {
    final setup = await _pump(
      tester,
      PlatformKind.android,
      overlayAllowed: false,
      backgroundAllowed: false,
    );

    expect(find.text(overlayTitle), findsOneWidget);
    expect(find.text(batteryTitle), findsNothing);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text(batteryTitle), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(setup.overlay.permissionRequests, 0);
    expect(setup.background.requests, 0);
  });
}
