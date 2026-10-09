import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _entry = DhikrEntry(id: 1, name: 'سبحان الله', amount: 3);

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onTap,
  required VoidCallback onDismiss,
  int count = 0,
}) async {
  tester.view.physicalSize = const Size(1120, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DhikrReminderSurface(
          reminder: ActiveDhikrReminder(entry: _entry, count: count),
          onTap: onTap,
          onDismiss: onDismiss,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('Space and Enter count, Escape closes', (tester) async {
    var taps = 0;
    var dismissals = 0;
    await _pump(tester, onTap: () => taps++, onDismiss: () => dismissals++);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
    expect(taps, 3);
    expect(dismissals, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(dismissals, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('other keys do nothing, and a finished dhikr is not counted again',
      (tester) async {
    var taps = 0;
    await _pump(tester, onTap: () => taps++, onDismiss: () {}, count: 3);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 0);
  });

  testWidgets('a screen reader hears the dhikr, how far it is, and what to do',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, onTap: () {}, onDismiss: () {}, count: 1);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(DhikrReminderSurface)));

    // Everything the card says, as the screen reader's one stream of text.
    final spoken = tester.getSemantics(
      find.bySemanticsLabel(RegExp('سبحان الله')).first,
    );
    final text = '${spoken.label} ${spoken.value} ${spoken.hint}';
    expect(text, contains('سبحان الله'));
    expect(text, contains('1 / 3'));
    expect(text, contains(l10n.dhikrReminderTouchEverywhereTip));
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
