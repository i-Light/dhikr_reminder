import 'package:dhikr_reminder/core/support/bug_report.dart';
import 'package:dhikr_reminder/features/settings/presentation/widgets/bug_report_card.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _details = BugReportDetails(
  appVersion: '0.1.2 (3)',
  device: 'Samsung SM-A546B, Android 14 (API 34)',
);

void main() {
  group('the report', () {
    test('carries what the person wrote, the version and the device', () {
      final body = buildBugReportBody('  The card never shows  ', _details);

      expect(body, startsWith('The card never shows'));
      expect(body, contains('App version: 0.1.2 (3)'));
      expect(body, contains('Device: Samsung SM-A546B, Android 14 (API 34)'));
      expect(body, isNot(contains('log')));
    });

    test('adds the end of the app log when there is one', () {
      final body = buildBugReportBody(
        'Crash',
        const BugReportDetails(
          appVersion: '1',
          device: 'x',
          logTail: 'Uncaught: boom',
        ),
      );

      expect(body, contains('Uncaught: boom'));
    });

    test('is cut short so the address stays within what a browser takes', () {
      final uri = bugReportUri('ا' * 20000, _details);

      expect(uri.toString().length, lessThan(8000));
    });

    test('titles the report with the first line', () {
      expect(bugReportTitle('Cannot count\nsecond line'),
          'Bug report: Cannot count');
      expect(bugReportTitle('   '), 'Bug report');
      expect(bugReportTitle('x' * 200).length, lessThan(100));
    });

    test('is a pre-filled new issue on the app repository', () {
      final uri = bugReportUri('الذكر مش بيظهر', _details);

      expect(uri.host, 'github.com');
      expect(uri.path, '/i-Light/dhikr_reminder/issues/new');
      expect(uri.queryParameters['title'], 'Bug report: الذكر مش بيظهر');
      expect(uri.queryParameters['body'], contains('الذكر مش بيظهر'));
      expect(uri.queryParameters['body'], contains('0.1.2 (3)'));
    });
  });

  group('the settings row', () {
    Future<List<Uri>> pump(
      WidgetTester tester, {
      bool opens = true,
      Locale locale = const Locale('en'),
    }) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final opened = <Uri>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bugReportDetailsProvider.overrideWithValue(() async => _details),
            bugReportOpenerProvider.overrideWithValue((uri) async {
              opened.add(uri);
              return opens;
            }),
          ],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: BugReportCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('asks what went wrong, then opens the report', (tester) async {
      final opened = await pump(tester);

      await tester.tap(find.text('Report a bug'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('bug-report-field')),
        'Reminders stop after an hour',
      );
      await tester.tap(find.text('Open report'));
      await tester.pumpAndSettle();

      expect(opened, hasLength(1));
      expect(opened.single.queryParameters['body'],
          contains('Reminders stop after an hour'));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('will not send an empty report', (tester) async {
      final opened = await pump(tester);

      await tester.tap(find.text('Report a bug'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open report'));
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
      expect(find.text('Write what went wrong first'), findsOneWidget);
    });

    testWidgets('cancel opens nothing', (tester) async {
      final opened = await pump(tester);

      await tester.tap(find.text('Report a bug'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
    });

    testWidgets('copies the report when no browser can be opened',
        (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await pump(tester, opens: false);
      await tester.tap(find.text('Report a bug'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('bug-report-field')),
        'It crashed',
      );
      await tester.tap(find.text('Open report'));
      await tester.pumpAndSettle();

      expect(copied, contains('It crashed'));
      expect(find.textContaining('Could not open the browser'), findsOneWidget);
    });

    testWidgets('renders in Arabic without overflowing', (tester) async {
      await pump(tester, locale: const Locale('ar'));

      expect(find.text('بلّغ عن مشكلة'), findsOneWidget);
      await tester.tap(find.text('بلّغ عن مشكلة'));
      await tester.pumpAndSettle();
      expect(find.text('إيه اللي حصل؟'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
