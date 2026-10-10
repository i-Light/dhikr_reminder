import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/features/library/application/favourites_controller.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/presentation/dhikr_library_screen.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/dhikr_library_card.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DhikrLibraryScreen()),
      ),
    );

void main() {
  final first = dhikrLibrary[0];
  final second = dhikrLibrary[1];

  group('the favourites list', () {
    test('keeps the order the stars were pressed in, and remembers it',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final stars = container.read(favouritesProvider.notifier);

      await stars.toggle(second.id);
      await stars.toggle(first.id);
      expect(container.read(favouritesProvider), [second.id, first.id]);
      expect(container.read(favouriteItemsProvider), [second, first]);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(favouritesPrefsKey), [second.id, first.id]);

      await stars.toggle(second.id);
      expect(container.read(favouritesProvider), [first.id]);
      expect(prefs.getStringList(favouritesPrefsKey), [first.id]);
    }, skip: !Features.wird);

    test('reads the saved stars, dropping what the library no longer has',
        () async {
      SharedPreferences.setMockInitialValues({
        favouritesPrefsKey: [first.id, 'no-such-entry', first.id, second.id],
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(favouritesProvider);
      await _settle();
      expect(container.read(favouritesProvider), [first.id, second.id]);
    }, skip: !Features.wird);

    test('a star pressed while the saved list is still loading is not lost',
        () async {
      SharedPreferences.setMockInitialValues({
        favouritesPrefsKey: [first.id],
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Pressed straight away, before the first read has finished.
      await container.read(favouritesProvider.notifier).toggle(second.id);
      expect(container.read(favouritesProvider), [first.id, second.id]);
    }, skip: !Features.wird);
  });

  group('the library', () {
    testWidgets('a starred card shows a small star, the others do not',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        favouritesPrefsKey: [first.id],
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(_app(container));
      await tester.runAsync(_settle);
      await tester.pump();

      expect(
        find.byKey(ValueKey('favourite-mark-${first.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('favourite-mark-${second.id}')),
        findsNothing,
      );
    }, skip: !Features.wird);

    testWidgets('press and hold, then "Add to favourites", stars the entry',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(_app(container));
      await tester.pump();

      await tester.longPress(find.byType(DhikrLibraryCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dhikr-favourite')));
      await tester.runAsync(_settle);
      await tester.pumpAndSettle();

      expect(container.read(favouritesProvider), [first.id]);
      expect(
        find.byKey(ValueKey('favourite-mark-${first.id}')),
        findsOneWidget,
      );

      // The same row now offers to take it off.
      await tester.longPress(find.byType(DhikrLibraryCard).first);
      await tester.pumpAndSettle();
      expect(find.text('Remove from favourites'), findsOneWidget);
    }, skip: !Features.wird);

    testWidgets('the Favourites filter leaves only the starred entries',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        favouritesPrefsKey: [second.id],
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(_app(container));
      await tester.runAsync(_settle);
      await tester.pump();

      container.read(dhikrLibraryProvider.notifier).toggleFavouritesOnly();
      await tester.pump();

      expect(container.read(filteredDhikrProvider), [second]);
      expect(container.read(dhikrLibraryProvider).activeFilterCount, 1);

      // "All" puts everything back.
      container.read(dhikrLibraryProvider.notifier).clearTags();
      await tester.pump();
      expect(container.read(dhikrLibraryProvider).favouritesOnly, isFalse);
      expect(
        container.read(filteredDhikrProvider).length,
        dhikrLibrary.length,
      );
    }, skip: !Features.wird);

    test('choosing what to add lists the starred entries first', () async {
      SharedPreferences.setMockInitialValues({
        favouritesPrefsKey: [second.id],
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(favouritesProvider);
      await _settle();

      // Plain browsing keeps the library's own order.
      expect(container.read(filteredDhikrProvider).first, first);

      container.read(dhikrLibraryProvider.notifier).setAddHint(true);
      final shown = container.read(filteredDhikrProvider);
      expect(shown.first, second);
      expect(shown.length, dhikrLibrary.length);
      // The rest keep their order.
      expect(shown[1], first);
    }, skip: !Features.wird);
  });
}
