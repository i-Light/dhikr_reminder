import 'package:dhikr_reminder/core/navigation/main_shell.dart';
import 'package:dhikr_reminder/core/navigation/shell_tab.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/presentation/dhikr_library_screen.dart';
import 'package:dhikr_reminder/features/notifications/presentation/notifications_screen.dart';
import 'package:dhikr_reminder/features/settings/presentation/home_screen.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppLocalizations> _pumpShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainShell(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(MainShell)));
}

/// An icon in the bottom bar, not the same icon elsewhere on a page (the
/// library's bell is also a bell).
Finder _navIcon(IconData icon) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(icon),
    );

void main() {
  testWidgets('opens on the home page behind a three-item bottom bar',
      (tester) async {
    final l10n = await _pumpShell(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(l10n.navSettings), findsOneWidget);
    expect(find.text(l10n.navNotifications), findsOneWidget);
    expect(find.text(l10n.navLibrary), findsOneWidget);

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack).first);
    expect(stack.index, 0);
  });

  testWidgets('the bottom bar switches to the library and back',
      (tester) async {
    await _pumpShell(tester);

    // Tapping the destination's icon, not its label: the library's label and
    // the page's own title are the same words.
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack).first).index,
      2,
    );

    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pumpAndSettle();
    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack).first).index,
      0,
    );
  });

  testWidgets('both pages stay mounted, so neither loses its state',
      (tester) async {
    await _pumpShell(tester);

    // Both pages are in the tree — an IndexedStack keeps the one that is not
    // on show mounted, which is what preserves the settings draft and the
    // library's scroll position across a switch.
    expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
    expect(
      find.byType(DhikrLibraryScreen, skipOffstage: false),
      findsOneWidget,
    );
    // ...but only the settings page is actually on show.
    expect(find.byType(DhikrLibraryScreen), findsNothing);
    expect(
      find.byType(NotificationsScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(NotificationsScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('adding a dhikr from the notifications page', () {
    testWidgets('shows the add buttons for the visit, and takes them away',
        (tester) async {
      final l10n = await _pumpShell(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MainShell)),
      );

      // On the library by hand, the cards are compact.
      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();
      expect(container.read(dhikrLibraryProvider).showAddUi, isFalse);
      expect(find.text(l10n.libraryAddButton), findsNothing);

      // Back to notifications, and "Add dhikr" sends the person to the library.
      await tester.tap(_navIcon(Icons.notifications_none));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.notifAddDhikr).first);
      await tester.pumpAndSettle();
      expect(container.read(shellTabProvider), ShellTab.library);
      expect(container.read(dhikrLibraryProvider).showAddUi, isTrue);
      expect(find.text(l10n.libraryAddButton), findsWidgets);

      // The bottom bar leaves the library: the visit is over.
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      expect(container.read(dhikrLibraryProvider).showAddUi, isFalse);
      expect(container.read(dhikrLibraryProvider).showAddHint, isFalse);
    });

    testWidgets("the banner's way back ends the visit too", (tester) async {
      final l10n = await _pumpShell(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MainShell)),
      );
      await tester.tap(_navIcon(Icons.notifications_none));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.notifAddDhikr).first);
      await tester.pumpAndSettle();
      expect(container.read(dhikrLibraryProvider).showAddUi, isTrue);

      await tester.tap(find.text(l10n.libraryAddHintBack));
      await tester.pumpAndSettle();

      expect(container.read(shellTabProvider), ShellTab.notifications);
      expect(container.read(dhikrLibraryProvider).showAddUi, isFalse);
    });
  });
}
