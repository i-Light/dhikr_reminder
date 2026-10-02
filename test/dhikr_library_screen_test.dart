import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/library/presentation/dhikr_library_screen.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/dhikr_library_card.dart';
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
  return (
    container: container,
    l10n: AppLocalizations.of(tester.element(find.byType(DhikrLibraryScreen))),
  );
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
    expect(find.text(l10n.libraryResultsCount(filtered.length)), findsOneWidget);

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

  testWidgets('the quick settings popup steps the size and toggles tashkeel',
      (tester) async {
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
    expect(container.read(dhikrLibraryProvider).fontSize,
        dhikrLibraryFontDefault);

    await tester.tap(find.byType(Switch));
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

  testWidgets('the filter gallery narrows the list to a group',
      (tester) async {
    final (:container, :l10n) = await _pumpLibrary(tester);

    await tester.tap(find.byTooltip(l10n.libraryFilterTitle));
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

  testWidgets('turning tashkeel off strips the vowel marks off the cards',
      (tester) async {
    final l10n = (await _pumpLibrary(tester)).l10n;
    final first = dhikrLibrary.first;

    expect(find.text(first.text), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.libraryQuickSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.libraryClose));
    await tester.pumpAndSettle();

    expect(find.text(first.text), findsNothing);
    expect(find.text(stripTashkeel(first.text)), findsOneWidget);
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
    final l10n =
        (await _pumpLibrary(tester, locale: const Locale('en'))).l10n;

    expect(find.text(l10n.libraryTitle), findsOneWidget);
    expect(find.text(l10n.libraryResultsCount(dhikrLibrary.length)),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
