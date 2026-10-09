import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/reminder_panel.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('"Count now" opens the reminder card for a dhikr already added',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final item = dhikrLibrary.firstWhere((i) => i.isRemindable);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(dhikrSettingsProvider);
    await tester.runAsync(() async {
      while (!container.read(dhikrSettingsProvider).isLoaded) {
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      await container
          .read(dhikrSettingsProvider.notifier)
          .addFromLibrary(item, amount: 3);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: ReminderPanel(item: item))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(activeDhikrReminderProvider), isNull);
    await tester.tap(find.byKey(const ValueKey('count-now-button')));
    await tester.pump();

    final active = container.read(activeDhikrReminderProvider);
    expect(active, isNotNull);
    expect(active!.entry.libraryId, item.id);
    expect(active.entry.amount, 3);
    container.read(activeDhikrReminderProvider.notifier).dismiss();
  });

  testWidgets('a dhikr that is not added yet has no such button',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final item = dhikrLibrary.firstWhere((i) => i.isRemindable);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: ReminderPanel(item: item))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('count-now-button')), findsNothing);
  });
}
