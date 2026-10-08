import 'package:dhikr_reminder/core/navigation/shell_tab.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/library/presentation/dhikr_library_screen.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/dhikr_library_card.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/library_popups.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/reminder_panel.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the library page inside its own container and MaterialApp, tall
/// enough that a handful of cards and the whole filter gallery are on screen.
///
/// Returns the container (to assert the view state a tap produced) and the
/// localizations (to look the strings up rather than hard-coding Arabic).
Future<({ProviderContainer container, AppLocalizations l10n})> _pumpLibrary(
  WidgetTester tester, {
  Locale locale = const Locale('ar'),
  bool addUi = false,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DhikrLibraryScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final l10n =
      AppLocalizations.of(tester.element(find.byType(DhikrLibraryScreen)));
  if (addUi) {
    // The cards start compact; the bell is what brings the add buttons.
    await tester.tap(find.byKey(const ValueKey('add-ui-button')));
    await tester.pumpAndSettle();
  }
  return (container: container, l10n: l10n);
}

void main() {
  testWidgets('opens on the whole library and says how many entries it has',
      (tester) async {
    final (:container, :l10n) = await _pumpLibrary(tester);

    expect(find.text(l10n.libraryTitle), findsOneWidget);
    expect(
      find.text(l10n.libraryResultsCount(dhikrLibrary.length)),
      findsOneWidget,
    );
    expect(find.byType(DhikrLibraryCard), findsWidgets);
    // Nothing is filtered or searched for on arrival.
    expect(container.read(dhikrLibraryProvider).query, isEmpty);
    expect(container.read(dhikrLibraryProvider).hasTagFilter, isFalse);
  });

  testWidgets('search narrows the list, and the clear button restores it',
      (tester) async {
    final (:container, :l10n) = await _pumpLibrary(tester);

    await tester.enterText(find.byType(TextField), 'زبد البحر');
    await tester.pumpAndSettle();

    final filtered = container.read(filteredDhikrProvider);
    expect(filtered, isNotEmpty);
    expect(filtered.length, lessThan(dhikrLibrary.length));
    expect(
        find.text(l10n.libraryResultsCount(filtered.length)), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.librarySearchClear));
    await tester.pumpAndSettle();

    expect(container.read(dhikrLibraryProvider).query, isEmpty);
    expect(
      find.text(l10n.libraryResultsCount(dhikrLibrary.length)),
      findsOneWidget,
    );
  });

  testWidgets('a search that matches nothing offers a way back',
      (tester) async {
    final (:container, :l10n) = await _pumpLibrary(tester);

    await tester.enterText(find.byType(TextField), 'قققققق');
    await tester.pumpAndSettle();

    expect(find.byType(DhikrLibraryCard), findsNothing);
    expect(find.text(l10n.libraryEmptyTitle), findsOneWidget);

    await tester.tap(find.text(l10n.libraryEmptyAction));
    await tester.pumpAndSettle();

    expect(find.text(l10n.libraryEmptyTitle), findsNothing);
    expect(container.read(dhikrLibraryProvider).query, isEmpty);
    expect(find.byType(DhikrLibraryCard), findsWidgets);
  });

  testWidgets('the quick settings popup steps the size', (tester) async {
    final (:container, :l10n) = await _pumpLibrary(tester);

    await tester.tap(find.byTooltip(l10n.libraryQuickSettings));
    await tester.pumpAndSettle();

    // The popup shows the current size as a plain number.
    expect(find.text(l10n.libraryFontSizeLabel), findsOneWidget);
    expect(find.text('${dhikrLibraryFontDefault.round()}'), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.libraryFontIncrease));
    await tester.pumpAndSettle();
    const bigger = dhikrLibraryFontDefault + dhikrLibraryFontStep;
    expect(container.read(dhikrLibraryProvider).fontSize, bigger);
    expect(find.text('${bigger.round()}'), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.libraryFontDecrease));
    await tester.pumpAndSettle();
    expect(
        container.read(dhikrLibraryProvider).fontSize, dhikrLibraryFontDefault);

    // The library has no vowelled text, so there is nothing for a tashkeel
    // switch to switch.
    expect(libraryHasTashkeel, isFalse);
    expect(find.text(l10n.libraryTashkeelLabel), findsNothing);
  });

  testWidgets('the tashkeel switch toggles when the library has vowels',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DhikrQuickSettingsPopup(showTashkeelOption: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(container.read(dhikrLibraryProvider).showTashkeel, isFalse);
  });

  testWidgets('the size stepper stops at both ends', (tester) async {
    final (:container, :l10n) = await _pumpLibrary(tester);
    final notifier = container.read(dhikrLibraryProvider.notifier);
    for (var i = 0; i < 100; i++) {
      await notifier.stepFontSize(-1);
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(l10n.libraryQuickSettings));
    await tester.pumpAndSettle();

    expect(find.text('${dhikrLibraryFontMin.round()}'), findsOneWidget);
    // At the floor, "smaller" is offered but inert rather than absent.
    final decrease = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.remove),
        matching: find.byType(IconButton),
      ),
    );
    expect(decrease.onPressed, isNull);
  });

  testWidgets('the filter gallery narrows the list to a group', (tester) async {
    final (:container, :l10n) = await _pumpLibrary(tester);

    // One button for the settings and the filters: there is no second one.
    expect(find.byTooltip(l10n.libraryFilterTitle), findsNothing);
    await tester.tap(find.byTooltip(l10n.libraryQuickSettings));
    await tester.pumpAndSettle();

    // Every group is offered, whether or not it currently matches anything.
    expect(find.text(l10n.tagRuqyah), findsOneWidget);
    expect(find.text(l10n.libraryFilterAll), findsWidgets);

    await tester.tap(find.text(l10n.tagRuqyah));
    await tester.pumpAndSettle();

    final filtered = container.read(filteredDhikrProvider);
    expect(filtered, isNotEmpty);
    expect(filtered.every((i) => i.tags.contains(DhikrTag.ruqyah)), isTrue);
    expect(find.text(l10n.libraryFilterCount(1)), findsOneWidget);

    // A second group widens the list rather than replacing the first.
    await tester.tap(find.text(l10n.tagHajjUmrah));
    await tester.pumpAndSettle();
    expect(container.read(dhikrLibraryProvider).selectedTags.length, 2);
    expect(
      container.read(filteredDhikrProvider).length,
      greaterThan(filtered.length),
    );

    // "All" drops the whole selection.
    await tester.tap(find.text(l10n.libraryFilterAll).first);
    await tester.pumpAndSettle();
    expect(container.read(dhikrLibraryProvider).hasTagFilter, isFalse);
    expect(container.read(filteredDhikrProvider).length, dhikrLibrary.length);
  });

  testWidgets('turning tashkeel off strips the vowel marks off a card',
      (tester) async {
    const item = DhikrItem(id: 'x', text: 'اللَّهُ أَكْبَرُ');

    Future<void> pump(bool showTashkeel) => tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DhikrLibraryCard(
                item: item,
                view: DhikrLibraryView(showTashkeel: showTashkeel),
              ),
            ),
          ),
        );

    await pump(true);
    expect(find.text(item.text), findsOneWidget);
    await pump(false);
    expect(find.text(item.text), findsNothing);
    expect(find.text(stripTashkeel(item.text)), findsOneWidget);
  });

  group('adding to reminders from the library', () {
    DhikrItem firstRemindable(ProviderContainer container) =>
        container.read(filteredDhikrProvider).firstWhere((i) => i.isRemindable);

    Finder reminderButton(DhikrItem item) =>
        find.byKey(ValueKey('reminder-button-${item.id}'));

    testWidgets('the panel is hidden until the reminder button is pressed',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'), addUi: true);
      final item = firstRemindable(container);

      expect(find.byType(ReminderPanel), findsNothing);
      expect(
        find.descendant(
          of: reminderButton(item),
          matching: find.text(l10n.libraryAddButton),
        ),
        findsOneWidget,
      );

      await tester.tap(reminderButton(item));
      await tester.pumpAndSettle();
      expect(find.byType(ReminderPanel), findsOneWidget);

      await tester.tap(reminderButton(item));
      await tester.pumpAndSettle();
      expect(find.byType(ReminderPanel), findsNothing);
    });

    testWidgets('adding saves a linked reminder with the count picked',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'), addUi: true);
      final item = firstRemindable(container);
      final before = container.read(dhikrSettingsProvider).entries.length;

      await tester.tap(reminderButton(item));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.libraryAddConfirm));
      await tester.pumpAndSettle();

      final entries = container.read(dhikrSettingsProvider).entries;
      expect(entries.length, before + 1);
      expect(entries.last.libraryId, item.id);
      expect(entries.last.name, item.text);
      expect(entries.last.amount, 7);
      // The button now says it is in the reminders, and so does the panel.
      expect(
        find.descendant(
          of: reminderButton(item),
          matching: find.text(l10n.libraryAddedButton),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.libraryAddedNote), findsOneWidget);
      expect(find.text(l10n.libraryAddedSnack), findsOneWidget);
    });

    testWidgets('the panel starts at the count the sources give',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'), addUi: true);
      final item = container
          .read(filteredDhikrProvider)
          .firstWhere((i) => i.isRemindable && i.count == 3);

      await tester.ensureVisible(reminderButton(item));
      await tester.tap(reminderButton(item));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.libraryAddConfirm));
      await tester.pumpAndSettle();

      expect(container.read(dhikrSettingsProvider).entries.last.amount, 3);
    });

    testWidgets('a dhikr that is already added says so and can be removed',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'), addUi: true);
      final seeded = container.read(dhikrSettingsProvider).entries.first;
      final item = libraryItemById(seeded.libraryId!)!;

      container.read(dhikrLibraryProvider.notifier).toggleTag(DhikrTag.tasabih);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: reminderButton(item),
          matching: find.text(l10n.libraryAddedButton),
        ),
        findsOneWidget,
      );

      await tester.tap(reminderButton(item));
      await tester.pumpAndSettle();
      expect(find.text(l10n.libraryAddedNote), findsOneWidget);

      await tester.tap(find.text(l10n.libraryRemoveButton));
      await tester.pumpAndSettle();

      expect(
        container
            .read(dhikrSettingsProvider)
            .entries
            .any((e) => e.libraryId == item.id),
        isFalse,
      );
      expect(
        find.descendant(
          of: reminderButton(item),
          matching: find.text(l10n.libraryAddButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the count of an added dhikr is changed in the panel',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'), addUi: true);
      final seeded = container.read(dhikrSettingsProvider).entries.first;
      final item = libraryItemById(seeded.libraryId!)!;
      container.read(dhikrLibraryProvider.notifier).toggleTag(DhikrTag.tasabih);
      await tester.pumpAndSettle();

      await tester.tap(reminderButton(item));
      await tester.pumpAndSettle();
      await tester.tap(find.text('33'));
      await tester.pumpAndSettle();

      expect(
        container
            .read(dhikrSettingsProvider)
            .entries
            .firstWhere((e) => e.libraryId == item.id)
            .amount,
        33,
      );
    });

    testWidgets('reading material has no reminder button', (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'), addUi: true);
      container
          .read(dhikrLibraryProvider.notifier)
          .toggleTag(DhikrTag.virtueOfSuras);
      await tester.pumpAndSettle();

      expect(find.byType(DhikrLibraryCard), findsWidgets);
      expect(find.text(l10n.libraryAddButton), findsNothing);
      expect(find.text(l10n.libraryReadOnlyNote), findsWidgets);
    });

    testWidgets('only one panel is open at a time', (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'), addUi: true);
      final remindable = container
          .read(filteredDhikrProvider)
          .where((i) => i.isRemindable)
          .take(2)
          .toList();

      await tester.tap(reminderButton(remindable[0]));
      await tester.pumpAndSettle();
      await tester.ensureVisible(reminderButton(remindable[1]));
      await tester.tap(reminderButton(remindable[1]));
      await tester.pumpAndSettle();

      expect(find.byType(ReminderPanel), findsOneWidget);
      expect(container.read(dhikrLibraryProvider).expandedId, remindable[1].id);
    });
  });

  group('the bell and the add buttons', () {
    testWidgets('the cards start compact, with no add button', (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'));

      expect(container.read(dhikrLibraryProvider).showAddUi, isFalse);
      expect(find.byType(DhikrLibraryCard), findsWidgets);
      expect(find.text(l10n.libraryAddButton), findsNothing);
      expect(find.text(l10n.libraryAddedButton), findsNothing);
      expect(find.byType(ReminderPanel), findsNothing);
    });

    testWidgets('the bell brings the buttons, and puts them away again',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'));
      final bell = find.byKey(const ValueKey('add-ui-button'));
      expect(find.byTooltip(l10n.libraryAddUiShow), findsOneWidget);

      await tester.tap(bell);
      await tester.pumpAndSettle();
      expect(find.text(l10n.libraryAddButton), findsWidgets);
      expect(find.byTooltip(l10n.libraryAddUiHide), findsOneWidget);

      // Open a panel, then hide the buttons: the panel goes with them.
      final item = container
          .read(filteredDhikrProvider)
          .firstWhere((i) => i.isRemindable);
      await tester.tap(find.byKey(ValueKey('reminder-button-${item.id}')));
      await tester.pumpAndSettle();
      expect(find.byType(ReminderPanel), findsOneWidget);

      await tester.tap(bell);
      await tester.pumpAndSettle();
      expect(find.text(l10n.libraryAddButton), findsNothing);
      expect(find.byType(ReminderPanel), findsNothing);
      expect(container.read(dhikrLibraryProvider).expandedId, isNull);
    });

    testWidgets('being sent here to add a dhikr brings them, for that visit',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'));
      final notifier = container.read(dhikrLibraryProvider.notifier);

      notifier.setAddHint(true);
      await tester.pumpAndSettle();
      expect(container.read(dhikrLibraryProvider).showAddUi, isTrue);
      expect(find.text(l10n.libraryAddButton), findsWidgets);

      // Closing the banner does not take the buttons away.
      await tester.tap(find.byTooltip(l10n.libraryClose));
      await tester.pumpAndSettle();
      expect(container.read(dhikrLibraryProvider).showAddUi, isTrue);

      // Leaving the library does.
      notifier.endVisit();
      await tester.pumpAndSettle();
      expect(container.read(dhikrLibraryProvider).showAddUi, isFalse);
      expect(find.text(l10n.libraryAddButton), findsNothing);
    });

    testWidgets('buttons the person switched on themselves stay on',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'), addUi: true);

      container.read(dhikrLibraryProvider.notifier).endVisit();
      await tester.pumpAndSettle();

      expect(container.read(dhikrLibraryProvider).showAddUi, isTrue);
      expect(find.text(l10n.libraryAddButton), findsWidgets);
    });

    testWidgets('a visit that finds the bell already on does not turn it off',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'), addUi: true);
      final notifier = container.read(dhikrLibraryProvider.notifier);

      notifier.setAddHint(true);
      notifier.endVisit();
      await tester.pumpAndSettle();

      expect(container.read(dhikrLibraryProvider).showAddUi, isTrue);
    });
  });

  group('hiding what is already added', () {
    testWidgets('leaves the dhikr in the reminders out of the list',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'));
      final seeded = container
          .read(dhikrSettingsProvider)
          .entries
          .map((e) => e.libraryId)
          .whereType<String>()
          .toSet();
      expect(seeded, isNotEmpty);
      final all = container.read(filteredDhikrProvider);
      expect(all.any((i) => seeded.contains(i.id)), isTrue);

      await tester.tap(find.byTooltip(l10n.libraryQuickSettings));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hide-added-switch')));
      await tester.pumpAndSettle();

      final shown = container.read(filteredDhikrProvider);
      expect(shown.any((i) => seeded.contains(i.id)), isFalse);
      expect(shown.length, all.length - seeded.length);
      expect(container.read(dhikrLibraryProvider).hideAdded, isTrue);
    });

    testWidgets('an added dhikr drops out at once, a removed one returns',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'));
      await container.read(dhikrLibraryProvider.notifier).toggleHideAdded();
      final item = container
          .read(filteredDhikrProvider)
          .firstWhere((i) => i.isRemindable);

      final settings = container.read(dhikrSettingsProvider.notifier);
      await settings.addFromLibrary(item);
      expect(
        container.read(filteredDhikrProvider).any((i) => i.id == item.id),
        isFalse,
      );

      await settings.removeLibraryItem(item.id);
      expect(
        container.read(filteredDhikrProvider).any((i) => i.id == item.id),
        isTrue,
      );
    });

    testWidgets('is remembered, and says it is on', (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'));
      expect(find.text(l10n.libraryHidingAdded), findsNothing);

      await container.read(dhikrLibraryProvider.notifier).toggleHideAdded();
      await tester.pumpAndSettle();

      expect(find.text(l10n.libraryHidingAdded), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dhikr_reminder.library.hideAdded'), isTrue);
    });

    testWidgets('counts as a filter on the settings button', (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'));
      final notifier = container.read(dhikrLibraryProvider.notifier);
      expect(container.read(dhikrLibraryProvider).activeFilterCount, 0);
      expect(find.byType(Badge), findsNothing);

      notifier.toggleTag(DhikrTag.ruqyah);
      await notifier.toggleHideAdded();
      await tester.pumpAndSettle();

      expect(container.read(dhikrLibraryProvider).activeFilterCount, 2);
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.label, isA<Text>());
      expect((badge.label! as Text).data, '2');
    });
  });

  group('the add hint', () {
    testWidgets('is shown when the notifications page sent the person here',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'));
      expect(find.text(l10n.libraryAddHintTitle), findsNothing);

      container.read(dhikrLibraryProvider.notifier).setAddHint(true);
      await tester.pumpAndSettle();
      expect(find.text(l10n.libraryAddHintTitle), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.libraryClose));
      await tester.pumpAndSettle();
      expect(find.text(l10n.libraryAddHintTitle), findsNothing);
    });

    testWidgets('offers the way back to the notifications page',
        (tester) async {
      final (:container, :l10n) =
          await _pumpLibrary(tester, locale: const Locale('en'));
      container.read(shellTabProvider.notifier).show(ShellTab.library);
      container.read(dhikrLibraryProvider.notifier).setAddHint(true);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.libraryAddHintBack));
      await tester.pumpAndSettle();

      expect(container.read(shellTabProvider), ShellTab.notifications);
      expect(container.read(dhikrLibraryProvider).showAddHint, isFalse);
    });
  });

  testWidgets('renders in Arabic, right to left, without overflowing',
      (tester) async {
    final l10n = (await _pumpLibrary(tester)).l10n;

    expect(Directionality.of(tester.element(find.byType(TextField))),
        TextDirection.rtl);
    expect(find.text(l10n.libraryTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in English without overflowing', (tester) async {
    final l10n = (await _pumpLibrary(tester, locale: const Locale('en'))).l10n;

    expect(find.text(l10n.libraryTitle), findsOneWidget);
    expect(find.text(l10n.libraryResultsCount(dhikrLibrary.length)),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
