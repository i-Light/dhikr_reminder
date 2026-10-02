import 'package:dhikr_reminder/core/navigation/main_shell.dart';
import 'package:dhikr_reminder/features/library/presentation/dhikr_library_screen.dart';
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

void main() {
  testWidgets('opens on the settings page behind a two-item bottom bar',
      (tester) async {
    final l10n = await _pumpShell(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(l10n.navSettings), findsOneWidget);

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
      1,
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
    expect(tester.takeException(), isNull);
  });
}
