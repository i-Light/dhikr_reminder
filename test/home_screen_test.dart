import 'package:dhikr_reminder/features/settings/presentation/home_screen.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, String lang) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              HijriDateCard(clock: () => DateTime(2025, 6, 26)),
              const Expanded(child: HomeScreen()),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the Hijri date in Arabic', (tester) async {
    await _pump(tester, 'ar');
    final text = tester
        .widget<Text>(find.byKey(const ValueKey('hijri-date')).first)
        .data!;
    expect(text, contains('١٤٤٧'));
    expect(text, endsWith('هـ'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the Hijri date in English', (tester) async {
    await _pump(tester, 'en');
    final text = tester
        .widget<Text>(find.byKey(const ValueKey('hijri-date')).first)
        .data!;
    expect(text, contains('1447'));
    expect(text, endsWith('AH'));
    expect(tester.takeException(), isNull);
  });
}
