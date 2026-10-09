import 'package:dhikr_reminder/core/support/bug_report.dart';
import 'package:dhikr_reminder/features/about/about_screen.dart';
import 'package:dhikr_reminder/features/library/presentation/dhikr_library_screen.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/dhikr_library_card.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _details = BugReportDetails(appVersion: '0.2.0 (5)', device: 'test');

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  group('contentReportUri', () {
    test('is a GitHub issue labelled content, naming the entry and build', () {
      final uri = contentReportUri(
        id: 'dabc123',
        text: 'سبحان الله',
        reference: 'رواه مسلم',
        details: _details,
      );
      expect(uri.host, 'github.com');
      expect(uri.path, endsWith('/issues/new'));
      expect(uri.queryParameters['labels'], 'content');
      expect(uri.queryParameters['title'], contains('dabc123'));
      final body = uri.queryParameters['body']!;
      expect(body, contains('Entry: dabc123'));
      expect(body, contains('سبحان الله'));
      expect(body, contains('رواه مسلم'));
      expect(body, contains('0.2.0 (5)'));
    });

    test('leaves the source line out when there is none', () {
      final uri = contentReportUri(
        id: 'x',
        text: 't',
        reference: null,
        details: _details,
      );
      expect(uri.queryParameters['body'], isNot(contains('Source line')));
    });
  });

  group('the library report', () {
    testWidgets('press and hold asks first, then opens the page', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final opened = <Uri>[];
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bugReportDetailsProvider.overrideWithValue(() async => _details),
            bugReportOpenerProvider.overrideWithValue((uri) async {
              opened.add(uri);
              return true;
            }),
          ],
          child: _app(const Scaffold(body: DhikrLibraryScreen())),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(DhikrLibraryScreen)),
      );

      await tester.longPress(find.byType(DhikrLibraryCard).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n.reportMistakeTitle), findsOneWidget);
      expect(opened, isEmpty, reason: 'nothing opens before the person agrees');

      await tester.tap(find.text(l10n.reportMistakeSend));
      await tester.pumpAndSettle();
      expect(opened, hasLength(1));
      expect(opened.single.queryParameters['labels'], 'content');
    });

    testWidgets('cancelling opens nothing', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final opened = <Uri>[];
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bugReportDetailsProvider.overrideWithValue(() async => _details),
            bugReportOpenerProvider.overrideWithValue((uri) async {
              opened.add(uri);
              return true;
            }),
          ],
          child: _app(const Scaffold(body: DhikrLibraryScreen())),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(DhikrLibraryScreen)),
      );

      await tester.longPress(find.byType(DhikrLibraryCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
    });
  });

  group('AboutScreen', () {
    for (final lang in ['en', 'ar']) {
      testWidgets(
        'shows version, sources and licences in $lang without overflow',
        (tester) async {
          await tester.pumpWidget(
            _app(
              AboutScreen(version: Future.value('0.2.0 (5)')),
              locale: Locale(lang),
            ),
          );
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(find.byType(AboutScreen)),
          );

          expect(find.text(l10n.aboutVersion('0.2.0 (5)')), findsOneWidget);
          expect(find.text(l10n.aboutSources), findsOneWidget);
          expect(find.text(l10n.aboutLicenses), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
