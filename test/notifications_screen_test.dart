import 'package:dhikr_reminder/core/navigation/shell_tab.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/notifications/presentation/dhikr_edit_dialog.dart';
import 'package:dhikr_reminder/features/notifications/presentation/notifications_screen.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String lang = 'en',
  Size size = const Size(900, 1600),
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = size;
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

/// Opens the folded reminder settings.
Future<void> _expandSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('collapsible-header')));
  await tester.pumpAndSettle();
}

/// Gives the saved dhikr these entries, and waits for the page to show them.
Future<void> _setEntries(
  WidgetTester tester,
  ProviderContainer container,
  List<DhikrEntry> entries,
) async {
  await container.read(dhikrSettingsProvider.notifier).updateEntries(entries);
  await tester.pumpAndSettle();
}

void main() {
  for (final lang in ['en', 'ar']) {
    testWidgets('renders in $lang without overflowing', (tester) async {
      await _pump(tester, lang: lang);
      expect(tester.takeException(), isNull);
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });
  }

  testWidgets('has no sound switch for now', (tester) async {
    await _pump(tester);
    await _expandSettings(tester);

    // Hidden until reminders have a sound (see _ReminderSettingsCard).
    expect(find.text('Sound'), findsNothing);
    expect(find.byIcon(Icons.volume_up), findsNothing);
    // The priority switch next to it is still there.
    expect(find.text('Dhikr priority'), findsOneWidget);
  });

  group('the reminder settings card', () {
    testWidgets('starts folded, and says what is set in two short lines',
        (tester) async {
      await _pump(tester);

      // Folded: none of the controls, only the summary.
      expect(find.byType(Slider), findsNothing);
      expect(find.byKey(const ValueKey('priority-switch')), findsNothing);
      expect(find.text('Remind me every 30 min'), findsOneWidget);
      expect(find.text('Every dhikr is equally likely'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings-summary-interval')),
        findsOneWidget,
      );
      // Two lines, one each, however long the words are.
      for (final key in [
        'settings-summary-interval',
        'settings-summary-priority'
      ]) {
        final text = tester.widget<Text>(find.byKey(ValueKey(key)));
        expect(text.maxLines, 1, reason: key);
      }
    });

    testWidgets('the summary follows the settings', (tester) async {
      final container = await _pump(tester);

      await container.read(dhikrSettingsProvider.notifier).updateInterval(5);
      await container
          .read(dhikrSettingsProvider.notifier)
          .updateUseChance(true);
      await tester.pumpAndSettle();

      expect(find.text('Remind me every 5 min'), findsOneWidget);
      expect(find.text('Dhikr come up by their priority'), findsOneWidget);
    });

    testWidgets('opens to the slider, the switch and the test button',
        (tester) async {
      await _pump(tester);
      await _expandSettings(tester);

      expect(find.byType(Slider), findsOneWidget);
      expect(find.byKey(const ValueKey('priority-switch')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('test-reminder-button')),
        findsOneWidget,
      );
      // The summary gives way to the controls.
      expect(find.byKey(const ValueKey('settings-summary-interval')),
          findsNothing);

      await _expandSettings(tester);
      expect(find.byType(Slider), findsNothing);
      expect(find.byKey(const ValueKey('settings-summary-interval')),
          findsOneWidget);
    });

    testWidgets('the priority switch has no icon and turns the weighting on',
        (tester) async {
      final container = await _pump(tester);
      await _expandSettings(tester);

      // No icon beside it, and the whole row is the touch target.
      expect(find.byIcon(Icons.balance), findsNothing);
      expect(container.read(dhikrSettingsProvider).useChance, isFalse);
      await tester.tap(find.text('Dhikr priority'));
      await tester.pumpAndSettle();
      expect(container.read(dhikrSettingsProvider).useChance, isTrue);

      await tester.tap(find.byKey(const ValueKey('priority-switch')));
      await tester.pumpAndSettle();
      expect(container.read(dhikrSettingsProvider).useChance, isFalse);
    });

    testWidgets('the priority row is tight: the switch sits close to its text',
        (tester) async {
      await _pump(tester);
      await _expandSettings(tester);

      final row = tester.getRect(find.byKey(const ValueKey('priority-row')));
      final text = tester.getRect(find.descendant(
        of: find.byKey(const ValueKey('priority-row')),
        matching: find.byType(Column),
      ));
      final toggle =
          tester.getRect(find.byKey(const ValueKey('priority-switch')));
      // A plain list tile leaves 16 between its text and the switch, and 16
      // more beyond it. Here both gaps are a few pixels.
      expect(toggle.left - text.right, lessThan(14));
      expect(row.right - toggle.right, lessThan(14));
    });

    testWidgets('renders in Arabic without overflowing, folded and open',
        (tester) async {
      await _pump(tester, lang: 'ar', size: const Size(360, 740));
      expect(tester.takeException(), isNull);
      await _expandSettings(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('أولوية الأذكار'), findsOneWidget);
    });
  });

  group('a dhikr with a daily goal', () {
    const withGoal = DhikrEntry(
        id: 71, name: 'اللهم صل على محمد', amount: 3, dailyGoal: 100);
    const other =
        DhikrEntry(id: 72, name: 'سبحان الله', amount: 3, dailyGoal: 50);
    const plain = DhikrEntry(id: 73, name: 'الحمد لله', amount: 3);

    testWidgets('shows a bar and how far today has got', (tester) async {
      final container = await _pump(tester);
      await _setEntries(tester, container, [withGoal]);
      container.read(dhikrStatsProvider.notifier).recordTaps(71, 42);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('goal-progress')), findsOneWidget);
      expect(find.text('Today 42 of 100'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('goal-progress')),
      );
      expect(bar.value, closeTo(0.42, 0.001));
      // Not there yet: the card is as it always was.
      expect(find.byKey(const ValueKey('tile-71')), findsOneWidget);
      expect(find.byKey(const ValueKey('tile-achieved-71')), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('a dhikr with no goal shows no bar', (tester) async {
      final container = await _pump(tester);
      await _setEntries(tester, container, [plain]);

      expect(find.byKey(const ValueKey('goal-progress')), findsNothing);
      expect(find.byKey(const ValueKey('tile-73')), findsOneWidget);
    });

    testWidgets('starts at nothing, and the bar is empty', (tester) async {
      final container = await _pump(tester);
      await _setEntries(tester, container, [withGoal]);

      expect(find.text('Today 0 of 100'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('goal-progress')),
      );
      expect(bar.value, 0);
    });

    testWidgets('reaching the goal recolours the whole card', (tester) async {
      final container = await _pump(tester);
      await _setEntries(tester, container, [withGoal]);
      Color? cardColor() => tester
          .widget<Card>(find.descendant(
            of: find.byType(Dismissible),
            matching: find.byType(Card),
          ))
          .color;
      expect(cardColor(), isNull);

      container.read(dhikrStatsProvider.notifier).recordTaps(71, 100);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tile-achieved-71')), findsOneWidget);
      expect(cardColor(), isNotNull);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Today 100 of 100'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('goal-progress')),
      );
      expect(bar.value, 1);
    });

    testWidgets('going over changes only the counter', (tester) async {
      final container = await _pump(tester);
      await _setEntries(tester, container, [withGoal]);
      container.read(dhikrStatsProvider.notifier).recordTaps(71, 100);
      await tester.pumpAndSettle();
      final atGoal = tester
          .widget<Card>(find.descendant(
            of: find.byType(Dismissible),
            matching: find.byType(Card),
          ))
          .color;

      container.read(dhikrStatsProvider.notifier).recordTaps(71, 50);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tile-achieved-71')), findsOneWidget);
      expect(
        tester
            .widget<Card>(find.descendant(
              of: find.byType(Dismissible),
              matching: find.byType(Card),
            ))
            .color,
        atGoal,
      );
      expect(find.text('Today 150 of 100'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('goal-progress')),
      );
      expect(bar.value, 1);
    });

    testWidgets('each dhikr is counted on its own', (tester) async {
      final container = await _pump(tester);
      await _setEntries(tester, container, [withGoal, other]);

      container.read(dhikrStatsProvider.notifier).recordTaps(72, 50);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tile-achieved-72')), findsOneWidget);
      expect(find.byKey(const ValueKey('tile-71')), findsOneWidget);
      expect(find.text('Today 50 of 50'), findsOneWidget);
      expect(find.text('Today 0 of 100'), findsOneWidget);
    });

    testWidgets("yesterday's count is not today's", (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = ProviderContainer(overrides: [
        dhikrStatsClockProvider
            .overrideWithValue(() => DateTime(2026, 10, 9, 12)),
      ]);
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await container
          .read(dhikrSettingsProvider.notifier)
          .updateEntries([withGoal]);
      // Counted yesterday, with the app open through midnight and no tap since.
      container.read(dhikrStatsProvider.notifier).recordTaps(71, 100);
      expect(container.read(dhikrStatsProvider).day, '2026-10-09');
      var now = DateTime(2026, 10, 9, 12);
      final later = ProviderContainer(overrides: [
        dhikrStatsClockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(later.dispose);
      await later
          .read(dhikrSettingsProvider.notifier)
          .updateEntries([withGoal]);
      later.read(dhikrStatsProvider.notifier).recordTaps(71, 100);
      now = DateTime(2026, 10, 10, 0, 5);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: later,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: NotificationsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today 0 of 100'), findsOneWidget);
      expect(find.byKey(const ValueKey('tile-achieved-71')), findsNothing);
    });
  });

  group('the dhikr editor', () {
    testWidgets('takes 90% of a phone screen', (tester) async {
      final container = await _pump(tester, size: const Size(400, 800));
      final first = container.read(dhikrSettingsProvider).entries.first;

      await tester.tap(find.text(first.name).first);
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(const ValueKey('dhikr-edit-box')));
      expect(size.width, closeTo(360, 0.5));
      expect(size.height, closeTo(720, 0.5));
    });

    testWidgets('does not grow into a wall on a big window', (tester) async {
      final container = await _pump(tester, size: const Size(2000, 1200));
      final first = container.read(dhikrSettingsProvider).entries.first;

      await tester.tap(find.text(first.name).first);
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(const ValueKey('dhikr-edit-box')));
      expect(size.width, 720);
      expect(size.height, closeTo(1080, 0.5));
    });

    testWidgets('scrolls, with the buttons held in place', (tester) async {
      final container = await _pump(tester, size: const Size(360, 600));
      await container
          .read(dhikrSettingsProvider.notifier)
          .updateUseChance(true);
      final first = container.read(dhikrSettingsProvider).entries.first;
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(first.name).first);
      await tester.tap(find.text(first.name).first);
      await tester.pumpAndSettle();
      await tester
          .ensureVisible(find.byKey(const ValueKey('dhikr-goal-switch')));
      await tester.tap(find.byKey(const ValueKey('dhikr-goal-switch')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The last thing in the editor is below the fold until it is scrolled to.
      final hint = find.text(
          'A weight, not a percentage: 6 comes up twice as often as 3. 0 means never.');
      final scroll = find.byKey(const ValueKey('dhikr-edit-scroll'));
      await tester.dragUntilVisible(hint, scroll, const Offset(0, -80));
      expect(hint, findsOneWidget);
      // Save and Cancel never scroll away.
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers 1 and 10 among the daily goal shortcuts',
        (tester) async {
      expect(dailyGoalShortcuts, containsAll([1, 10, 33, 100, 300, 500, 1000]));
      final container = await _pump(tester);
      final first = container.read(dhikrSettingsProvider).entries.first;
      await tester.tap(find.text(first.name).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dhikr-goal-switch')));
      await tester.pumpAndSettle();

      Finder shortcut(int n) => find.descendant(
            of: find.byKey(const ValueKey('goal-shortcuts')),
            matching: find.text('$n'),
          );
      for (final n in [1, 10]) {
        await tester.ensureVisible(shortcut(n));
        expect(shortcut(n), findsOneWidget);
      }

      await tester.tap(shortcut(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(dhikrSettingsProvider)
            .entries
            .firstWhere((e) => e.id == first.id)
            .dailyGoal,
        1,
      );
    });

    testWidgets('explains the daily goal in one short line', (tester) async {
      final container = await _pump(tester, lang: 'ar');
      final first = container.read(dhikrSettingsProvider).entries.first;
      await tester.tap(find.text(first.name).first);
      await tester.pumpAndSettle();

      expect(find.text('حدد عدد الهدف اليومي'), findsOneWidget);
    });
  });

  testWidgets('adding a dhikr opens the library with a hint, no typing',
      (tester) async {
    final container = await _pump(tester);
    final before = container.read(dhikrSettingsProvider).entries.length;

    await tester.tap(find.text('Add dhikr'));
    await tester.pumpAndSettle();

    // No dialog asking for text: the person is sent to the library.
    expect(find.byType(TextField), findsNothing);
    expect(container.read(shellTabProvider), ShellTab.library);
    expect(container.read(dhikrLibraryProvider).showAddHint, isTrue);
    expect(container.read(dhikrSettingsProvider).entries.length, before);
  });

  testWidgets('the seeded dhikr are linked to the library', (tester) async {
    final container = await _pump(tester);

    final entries = container.read(dhikrSettingsProvider).entries;
    expect(entries, isNotEmpty);
    for (final entry in entries) {
      expect(entry.libraryId, isNotNull, reason: entry.name);
    }
  });

  testWidgets('the editor shows the dhikr but does not let its text change',
      (tester) async {
    final container = await _pump(tester);
    final first = container.read(dhikrSettingsProvider).entries.first;

    await tester.tap(find.text(first.name).first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dhikr-name-preview')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
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
    await _expandSettings(tester);

    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();

    expect(container.read(dhikrSettingsProvider).intervalMinutes, 15);
  });

  testWidgets('a daily goal is set inside the dhikr editor', (tester) async {
    final container = await _pump(tester);
    final first = container.read(dhikrSettingsProvider).entries.first;

    await tester.tap(find.text(first.name).first);
    await tester.pumpAndSettle();
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
        .firstWhere((e) => e.id == first.id);
    expect(saved.dailyGoal, 300);
    expect(saved.name, first.name);
    expect(saved.libraryId, first.libraryId);
  });

  testWidgets('a dhikr has no daily goal unless one is switched on',
      (tester) async {
    final container = await _pump(tester);
    final first = container.read(dhikrSettingsProvider).entries.first;

    await tester.tap(find.text(first.name).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = container
        .read(dhikrSettingsProvider)
        .entries
        .firstWhere((e) => e.id == first.id);
    expect(saved.dailyGoal, 0);
  });

  testWidgets('the number of repetitions is changed in the editor',
      (tester) async {
    final container = await _pump(tester);
    final first = container.read(dhikrSettingsProvider).entries.first;

    await tester.tap(find.text(first.name).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('33'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = container
        .read(dhikrSettingsProvider)
        .entries
        .firstWhere((e) => e.id == first.id);
    expect(saved.amount, 33);
  });
}
