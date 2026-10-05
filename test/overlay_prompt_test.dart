import 'package:dhikr_reminder/features/mobile_reminders/overlay_prompt.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_overlay.dart';

Future<FakeOverlay> _pump(
  WidgetTester tester,
  PlatformKind kind, {
  required bool allowed,
}) async {
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
        home: OverlayPermissionPrompt(child: Scaffold(body: Text('home'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return overlay;
}

void main() {
  testWidgets('a pop-up asks for the permission when it is missing',
      (tester) async {
    final overlay = await _pump(tester, PlatformKind.android, allowed: false);

    expect(find.text('Show reminders over other apps?'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(overlay.permissionRequests, 1);
    expect(find.text('Show reminders over other apps?'), findsNothing);
  });

  testWidgets('"Not now" just closes it', (tester) async {
    final overlay = await _pump(tester, PlatformKind.android, allowed: false);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(overlay.permissionRequests, 0);
    expect(find.text('Show reminders over other apps?'), findsNothing);
  });

  testWidgets('nothing is asked once it is allowed', (tester) async {
    await _pump(tester, PlatformKind.android, allowed: true);

    expect(find.text('Show reminders over other apps?'), findsNothing);
  });

  testWidgets('nothing is asked on Windows', (tester) async {
    await _pump(tester, PlatformKind.windows, allowed: false);

    expect(find.text('Show reminders over other apps?'), findsNothing);
  });
}
