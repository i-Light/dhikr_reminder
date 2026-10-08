import 'package:dhikr_reminder/core/update/update_controller.dart';
import 'package:dhikr_reminder/core/update/update_release.dart';
import 'package:dhikr_reminder/features/settings/presentation/widgets/update_card.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedUpdate extends UpdateNotifier {
  _FixedUpdate(this.fixed);
  final UpdateState fixed;
  int checks = 0;
  int installs = 0;

  @override
  UpdateState build() => fixed;

  @override
  Future<void> checkNow() async => checks++;

  @override
  Future<void> installNow() async => installs++;
}

const _v1 = AppVersion(0, 1, 0);
const _v2 = AppVersion(0, 2, 0);

Future<_FixedUpdate> _pump(
  WidgetTester tester,
  UpdateState state, {
  Locale locale = const Locale('en'),
}) async {
  final notifier = _FixedUpdate(state);
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [updateProvider.overrideWith(() => notifier)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SingleChildScrollView(child: UpdateCard())),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

void main() {
  testWidgets('says the app is up to date and offers a check', (tester) async {
    final notifier = await _pump(
      tester,
      UpdateState(
        currentVersion: _v1,
        latestVersion: _v1,
        lastChecked: DateTime(2026, 9, 29, 9, 30),
        canSelfUpdate: true,
      ),
    );

    expect(find.text("You're up to date"), findsOneWidget);
    expect(find.textContaining('Version 0.1.0'), findsOneWidget);
    expect(find.text('Update now'), findsNothing);

    await tester.tap(find.byTooltip('Check for updates'));
    expect(notifier.checks, 1);
  });

  testWidgets('offers Update now when a newer version is out', (tester) async {
    final notifier = await _pump(
      tester,
      const UpdateState(
        currentVersion: _v1,
        latestVersion: _v2,
        canSelfUpdate: true,
        autoUpdate: false,
      ),
    );

    expect(find.text('Version 0.2.0 is available'), findsOneWidget);
    expect(find.textContaining('Automatic updates are off'), findsOneWidget);

    await tester.tap(find.text('Update now'));
    expect(notifier.installs, 1);
  });

  testWidgets('a copy that cannot update itself gets the download page instead',
      (tester) async {
    await _pump(
      tester,
      const UpdateState(currentVersion: _v1, latestVersion: _v2),
    );

    expect(find.text('Open download page'), findsOneWidget);
    expect(find.text('Update now'), findsNothing);
    // No automatic-update switch for something that never updates itself.
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('a downloaded update waiting for an idle moment can be started',
      (tester) async {
    final notifier = await _pump(
      tester,
      const UpdateState(
        phase: UpdatePhase.waitingForIdle,
        currentVersion: _v1,
        latestVersion: _v2,
        canSelfUpdate: true,
      ),
    );

    expect(find.text('Version 0.2.0 is ready to install'), findsOneWidget);
    // Busy: checking again would be pointless.
    expect(
      tester
          .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.refresh_rounded))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Restart and update'));
    expect(notifier.installs, 1);
  });

  testWidgets('shows a failed check without a button to act on it',
      (tester) async {
    await _pump(
      tester,
      const UpdateState(currentVersion: _v1, failed: true, canSelfUpdate: true),
    );

    expect(find.text("Couldn't check for updates"), findsOneWidget);
    expect(find.byTooltip('Check for updates'), findsOneWidget);
  });

  testWidgets('renders in Arabic (right to left) without overflowing',
      (tester) async {
    await _pump(
      tester,
      const UpdateState(
          currentVersion: _v1, latestVersion: _v2, canSelfUpdate: true),
      locale: const Locale('ar'),
    );

    expect(find.text('حدّث دلوقتي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('on Android, where Google Play does the updating', () {
    Future<void> pumpAndroid(WidgetTester tester, {Locale? locale}) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPlatformProvider
                .overrideWithValue(const AppPlatform(PlatformKind.android)),
            updateProvider.overrideWith(
              () => _FixedUpdate(const UpdateState(currentVersion: _v1)),
            ),
          ],
          child: MaterialApp(
            locale: locale ?? const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: UpdateCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('says so, and offers the store page instead of a check',
        (tester) async {
      await pumpAndroid(tester);

      expect(find.text('Updates come from Google Play'), findsOneWidget);
      expect(find.textContaining('Version 0.1.0'), findsOneWidget);
      expect(find.text('Open Google Play'), findsOneWidget);
      // None of the Windows updater's controls.
      expect(find.byTooltip('Check for updates'), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Update now'), findsNothing);
    });

    testWidgets('renders in Arabic without overflowing', (tester) async {
      await pumpAndroid(tester, locale: const Locale('ar'));

      expect(find.text('التحديثات بتيجي من Google Play'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
