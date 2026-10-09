import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/core/navigation/shell_tab.dart';
import 'package:dhikr_reminder/core/window/tray_menu_panel.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/library/presentation/dhikr_actions.dart';
import 'package:dhikr_reminder/features/library/presentation/dhikr_library_screen.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/dhikr_library_card.dart';
import 'package:dhikr_reminder/features/mobile_reminders/mobile_reminder_host.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_overlay.dart';

class _FakeSharer implements TextSharer {
  final shared = <String>[];

  @override
  Future<bool> share(String text) async {
    shared.add(text);
    return true;
  }
}

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

const _android = AppPlatform(PlatformKind.android);
const _windows = AppPlatform(PlatformKind.windows);

Future<void> _longPressFirstCard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpAndSettle();
  await tester.longPress(find.byType(DhikrLibraryCard).first);
  await tester.pumpAndSettle();
}

void main() {
  const skipSurfaces = !Features.surfaces;

  group('dhikrShareText', () {
    test('is the text and its source line, nothing more', () {
      const item = DhikrItem(
        id: 'x',
        text: 'سبحان الله',
        reference: 'رواه مسلم',
        tags: [],
      );
      expect(dhikrShareText(item), 'سبحان الله\n\nرواه مسلم');
    });

    test('has no blank lines when the entry has no source', () {
      const item = DhikrItem(id: 'x', text: 'سبحان الله', tags: []);
      expect(dhikrShareText(item), 'سبحان الله');
    });
  });

  group('the sheet on a long press', skip: !Features.shareText, () {
    testWidgets('copies the text on Windows', (tester) async {
      SharedPreferences.setMockInitialValues({});
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(_windows)],
          child: _app(const Scaffold(body: DhikrLibraryScreen())),
        ),
      );
      await _longPressFirstCard(tester);

      expect(find.byKey(const ValueKey('dhikr-copy')), findsOneWidget);
      expect(find.byKey(const ValueKey('dhikr-share')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('dhikr-copy')));
      await tester.pumpAndSettle();

      expect(copied, isNotNull);
      expect(copied, isNotEmpty);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(DhikrLibraryScreen)),
      );
      expect(find.text(l10n.libraryCopied), findsOneWidget);
    });

    testWidgets('shares the text on a phone, with no copy row', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final sharer = _FakeSharer();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPlatformProvider.overrideWithValue(_android),
            textSharerProvider.overrideWithValue(sharer),
          ],
          child: _app(const Scaffold(body: DhikrLibraryScreen())),
        ),
      );
      await _longPressFirstCard(tester);

      expect(find.byKey(const ValueKey('dhikr-copy')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('dhikr-share')));
      await tester.pumpAndSettle();

      expect(sharer.shared, hasLength(1));
      expect(sharer.shared.single, isNotEmpty);
    });

    testWidgets('keeps the report row as the last one', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(_android)],
          child: _app(
            const Scaffold(body: DhikrLibraryScreen()),
            locale: const Locale('ar'),
          ),
        ),
      );
      await _longPressFirstCard(tester);

      expect(find.byKey(const ValueKey('dhikr-report')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the host and the extra ways to count', skip: skipSurfaces, () {
    testWidgets('hands the surfaces their words, in the app language', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final overlay = FakeOverlay(allowed: true);
      final container = ProviderContainer(
        overrides: [
          appPlatformProvider.overrideWithValue(_android),
          reminderOverlayProvider.overrideWithValue(overlay),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const MobileReminderHost(child: SizedBox())),
        ),
      );
      await tester.runAsync(() async {
        while (!container.read(dhikrSettingsProvider).isLoaded) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
      });
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 20),
          ));

      final labels = overlay.surfaceLabels;
      expect(labels, isNotNull);
      expect(labels!['countOne'], isNotEmpty);
      expect(labels['done'], isNotEmpty);
      expect(labels['later'], isNotEmpty);
      // The phone puts the time in; the template must still hold its slot.
      expect(labels['pausedUntil'], contains('{time}'));
    });

    testWidgets('takes up a pause made on a tile', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final overlay = FakeOverlay(allowed: true)
        ..pauseChange = DateTime.now()
            .add(const Duration(minutes: 40))
            .millisecondsSinceEpoch;
      final container = ProviderContainer(
        overrides: [
          appPlatformProvider.overrideWithValue(_android),
          reminderOverlayProvider.overrideWithValue(overlay),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const MobileReminderHost(child: SizedBox())),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 20),
          ));

      final until = container.read(reminderPauseProvider);
      expect(until, isNotNull);
      expect(
        until!.difference(DateTime.now()),
        greaterThan(const Duration(minutes: 30)),
      );
      container.read(reminderPauseProvider.notifier).resume();
    });

    testWidgets('takes up a pause that a tile lifted', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final overlay = FakeOverlay(allowed: true)..pauseChange = 0;
      final container = ProviderContainer(
        overrides: [
          appPlatformProvider.overrideWithValue(_android),
          reminderOverlayProvider.overrideWithValue(overlay),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(reminderPauseProvider.notifier)
          .pauseFor(const Duration(hours: 1));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const MobileReminderHost(child: SizedBox())),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 20),
          ));

      expect(container.read(reminderPauseProvider), isNull);
    });

    testWidgets('a shortcut can open the library', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final overlay = FakeOverlay(allowed: true)..openTab = 'library';
      final container = ProviderContainer(
        overrides: [
          appPlatformProvider.overrideWithValue(_android),
          reminderOverlayProvider.overrideWithValue(overlay),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const MobileReminderHost(child: SizedBox())),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 20),
          ));

      expect(container.read(shellTabProvider), ShellTab.library);
    });
  });

  group('"Count one" in the tray', skip: !Features.trayCount, () {
    test('counts the dhikr last shown, else the first one', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(dhikrSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final entries = container.read(dhikrSettingsProvider).entries;
      expect(entries.length, greaterThan(1));

      final active = container.read(activeDhikrReminderProvider.notifier);
      expect(active.countOne(), isTrue);
      final stats = container.read(dhikrStatsProvider);
      expect(stats.todayFor(entries.first.id), 1);

      active.show(entries[1]);
      active.dismiss();
      expect(active.countOne(), isTrue);
      expect(container.read(dhikrStatsProvider).todayFor(entries[1].id), 1);
      expect(container.read(dhikrStatsProvider).today, 2);
    });

    testWidgets('has a row that adds one and shows the total', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      container.read(dhikrSettingsProvider);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const Material(child: TrayMenuPanel())),
        ),
      );
      await tester.pump();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TrayMenuPanel)),
      );

      expect(find.text(l10n.surfaceCountOne), findsOneWidget);
      expect(find.text(l10n.trayTodayTotal(0)), findsOneWidget);
      await tester.tap(find.text(l10n.surfaceCountOne));
      await tester.pump();
      expect(find.text(l10n.trayTodayTotal(1)), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  });

  test('every library entry that can be shared has some text', () {
    for (final item in dhikrLibrary) {
      expect(dhikrShareText(item), isNotEmpty, reason: item.id);
    }
  });
}
