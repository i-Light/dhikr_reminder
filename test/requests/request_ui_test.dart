import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/library/presentation/dhikr_library_screen.dart';
import 'package:dhikr_reminder/features/requests/application/request_controller.dart';
import 'package:dhikr_reminder/features/requests/data/request_gateway.dart';
import 'package:dhikr_reminder/features/requests/domain/dhikr_request.dart';
import 'package:dhikr_reminder/features/requests/presentation/my_requests_screen.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Gateway implements RequestGateway {
  final submitted = <String>[];
  List<RemoteRequest> remote = [];
  RequestFailure? submitFailure;
  var _n = 0;

  @override
  Future<SubmitResult> submit({
    required String installToken,
    required String text,
    String? source,
    required String locale,
    required String platform,
    required String appVersion,
  }) async {
    if (submitFailure != null) throw submitFailure!;
    submitted.add(text);
    final request = RemoteRequest(id: 'srv${_n++}', status: RequestStatus.pending);
    remote = [...remote, request];
    return SubmitResult(request: request, duplicate: false);
  }

  @override
  Future<List<RemoteRequest>> fetch(String installToken) async => remote;
}

const _newDhikr = 'اللهم ارزقني الإخلاص في القول والعمل والنية';

Future<({ProviderContainer container, AppLocalizations l10n, _Gateway gateway})>
    _pump(
  WidgetTester tester, {
  bool enabled = true,
  Map<String, Object> prefs = const {},
  List<RemoteRequest> remote = const [],
  bool offline = false,
  Widget? home,
  Locale locale = const Locale('en'),
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final gateway = _Gateway()..remote = remote;
  if (offline) gateway.submitFailure = const RequestUnavailable('offline');
  final container = ProviderContainer(overrides: [
    requestGatewayProvider.overrideWithValue(enabled ? gateway : null),
    requestAppInfoProvider.overrideWithValue(
      () async => const RequestAppInfo(platform: 'android', appVersion: '0.1.3'),
    ),
  ]);
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
        home: home ?? const Scaffold(body: DhikrLibraryScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    container: container,
    l10n: AppLocalizations.of(tester.element(find.byType(Scaffold).first)),
    gateway: gateway,
  );
}

Finder get _listScrollable => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

/// Narrows the library to one dhikr, so the request tile at the end of the
/// list is on screen instead of 280 cards away.
Future<void> _showOnlyKhatm(WidgetTester tester, ProviderContainer container) async {
  container.read(dhikrLibraryProvider.notifier).toggleTag(DhikrTag.khatmQuran);
  await tester.pumpAndSettle();
}

Future<void> _openSheet(
  WidgetTester tester,
  AppLocalizations l10n,
  ProviderContainer container,
) async {
  await _showOnlyKhatm(tester, container);
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('request-from-tile')),
    400,
    scrollable: _listScrollable,
  );
  await tester.tap(find.byKey(const ValueKey('request-from-tile')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('request-text-field')), findsOneWidget);
}

void main() {
  group('on the library page', () {
    testWidgets('a build with no service offers no way to request',
        (tester) async {
      await _pump(tester, enabled: false);
      expect(find.byKey(const ValueKey('my-requests-button')), findsNothing);
      expect(find.byKey(const ValueKey('request-from-tile')), findsNothing);
    });

    testWidgets('the end of the list offers a way to ask for a dhikr',
        (tester) async {
      final (:container, :l10n, :gateway) = await _pump(tester);
      expect(find.byKey(const ValueKey('my-requests-button')), findsOneWidget);
      await _showOnlyKhatm(tester, container);
      await tester.scrollUntilVisible(
        find.text(l10n.requestTileTitle),
        400,
        scrollable: _listScrollable,
      );
      expect(find.text(l10n.requestTileTitle), findsOneWidget);
    });

    testWidgets('an empty search offers to request what was searched for',
        (tester) async {
      await _pump(tester);
      await tester.enterText(find.byType(TextField).first, _newDhikr);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('request-from-empty')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('request-text-field')), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('request-text-field')),
      );
      expect(field.controller!.text, _newDhikr);
    });

    testWidgets('a request with news shows a badge on the button',
        (tester) async {
      final request = DhikrRequest(
        localId: 'r1',
        serverId: 'srv0',
        text: _newDhikr,
        createdAt: DateTime(2026, 10, 8),
        status: RequestStatus.done,
        unseen: true,
      );
      await _pump(
        tester,
        prefs: {'dhikr_reminder.requests.list': '[${_json(request)}]'},
        remote: const [RemoteRequest(id: 'srv0', status: RequestStatus.done)],
      );
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsWidgets);
    });
  });

  group('the request sheet', () {
    testWidgets('sends a request and thanks the person', (tester) async {
      final (:container, :l10n, :gateway) = await _pump(tester);
      await _openSheet(tester, l10n, container);

      await tester.enterText(
        find.byKey(const ValueKey('request-text-field')),
        _newDhikr,
      );
      await tester.tap(find.byKey(const ValueKey('request-send')));
      await tester.pumpAndSettle();

      expect(gateway.submitted, [_newDhikr]);
      expect(find.text(l10n.requestSentTitle), findsOneWidget);
      expect(find.text(l10n.requestSentBody), findsOneWidget);
      expect(container.read(dhikrRequestsProvider).requests, hasLength(1));
    });

    testWidgets('explains a mistake and keeps what was typed', (tester) async {
      final (:container, :l10n, :gateway) = await _pump(tester);
      await _openSheet(tester, l10n, container);

      await tester.enterText(
        find.byKey(const ValueKey('request-text-field')),
        'please add this',
      );
      await tester.tap(find.byKey(const ValueKey('request-send')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.requestProblemNotArabic), findsOneWidget);
      expect(gateway.submitted, isEmpty);

      // Typing again takes the message away.
      await tester.enterText(
        find.byKey(const ValueKey('request-text-field')),
        _newDhikr,
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('request-error')), findsNothing);
    });

    testWidgets('says so when there is no connection and keeps the request',
        (tester) async {
      final (:container, :l10n, :gateway) = await _pump(tester);
      gateway.submitFailure = const RequestUnavailable('offline');
      await _openSheet(tester, l10n, container);

      await tester.enterText(
        find.byKey(const ValueKey('request-text-field')),
        _newDhikr,
      );
      await tester.tap(find.byKey(const ValueKey('request-send')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.requestQueuedTitle), findsOneWidget);
      expect(
        container.read(dhikrRequestsProvider).requests.single.status,
        RequestStatus.queued,
      );
    });

    testWidgets('points to the library when it already has the dhikr',
        (tester) async {
      final (:container, :l10n, :gateway) = await _pump(tester);
      await _openSheet(tester, l10n, container);
      final existing = dhikrLibrary.firstWhere((i) => i.text.length > 40);

      await tester.enterText(
        find.byKey(const ValueKey('request-text-field')),
        existing.text,
      );
      await tester.tap(find.byKey(const ValueKey('request-send')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.requestExistsTitle), findsOneWidget);
      expect(gateway.submitted, isEmpty);

      await tester.tap(find.byKey(const ValueKey('request-show-match')));
      await tester.pumpAndSettle();

      // The sheet is gone and the library is searching for that dhikr.
      expect(find.text(l10n.requestExistsTitle), findsNothing);
      expect(container.read(dhikrLibraryProvider).query, isNotEmpty);
      expect(container.read(filteredDhikrProvider), contains(existing));
    });

    testWidgets('sends the request anyway when it is not the same dhikr',
        (tester) async {
      final (:container, :l10n, :gateway) = await _pump(tester);
      await _openSheet(tester, l10n, container);
      final existing = dhikrLibrary.firstWhere((i) => i.text.length > 40);

      await tester.enterText(
        find.byKey(const ValueKey('request-text-field')),
        existing.text,
      );
      await tester.tap(find.byKey(const ValueKey('request-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('request-send-anyway')));
      await tester.pumpAndSettle();

      expect(gateway.submitted, hasLength(1));
      expect(find.text(l10n.requestSentTitle), findsOneWidget);
    });

    testWidgets('does not ask twice for the same dhikr', (tester) async {
      final (:container, :l10n, :gateway) = await _pump(tester);
      await container
          .read(dhikrRequestsProvider.notifier)
          .submit(text: _newDhikr);
      await tester.pumpAndSettle();
      await _openSheet(tester, l10n, container);

      await tester.enterText(
        find.byKey(const ValueKey('request-text-field')),
        _newDhikr,
      );
      await tester.tap(find.byKey(const ValueKey('request-send')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.requestOwnTitle), findsOneWidget);
      expect(gateway.submitted, hasLength(1));
    });

    testWidgets('renders in Arabic without overflowing', (tester) async {
      final (:container, :l10n, :gateway) =
          await _pump(tester, locale: const Locale('ar'));
      await _openSheet(tester, l10n, container);
      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byKey(const ValueKey('request-send')))),
        TextDirection.rtl,
      );
    });
  });

  group('my requests', () {
    DhikrRequest request(
      String id,
      RequestStatus status, {
      String? libraryId,
      String? shippedIn,
      DeclineReason? reason,
      bool unseen = false,
      int votes = 1,
    }) =>
        DhikrRequest(
          localId: id,
          serverId: 'srv-$id',
          text: 'اللهم ارزقني الإخلاص رقم $id',
          createdAt: DateTime(2026, 10, 8),
          status: status,
          libraryId: libraryId,
          shippedIn: shippedIn,
          reason: reason,
          unseen: unseen,
          votes: votes,
        );

    Future<AppLocalizations> pumpMine(
      WidgetTester tester,
      List<DhikrRequest> requests, {
      bool offline = false,
    }) async {
      final (:container, :l10n, :gateway) = await _pump(
        tester,
        home: const MyRequestsScreen(),
        offline: offline,
        prefs: {
          'dhikr_reminder.requests.list':
              '[${requests.map(_json).join(',')}]',
        },
        remote: [
          for (final r in requests)
            RemoteRequest(
              id: r.serverId!,
              status: r.status,
              reason: r.reason,
              libraryId: r.libraryId,
              shippedIn: r.shippedIn,
              votes: r.votes,
            ),
        ],
      );
      await tester.pumpAndSettle();
      return l10n;
    }

    testWidgets('says when there is nothing yet', (tester) async {
      final l10n = await pumpMine(tester, const []);
      expect(find.text(l10n.requestsEmptyTitle), findsOneWidget);
    });

    testWidgets('gives each status its own words and thanks', (tester) async {
      final l10n = await pumpMine(tester, [
        request('a', RequestStatus.queued),
        request('b', RequestStatus.pending, votes: 4),
        request('c', RequestStatus.inProgress),
        request('d', RequestStatus.done, shippedIn: '0.1.4'),
        request('e', RequestStatus.done),
        request('f', RequestStatus.declined, reason: DeclineReason.duplicate),
        request('g', RequestStatus.declined, reason: DeclineReason.unclear),
        request('h', RequestStatus.declined, reason: DeclineReason.notSuitable),
      ], offline: true);

      for (final text in [
        l10n.requestStatusQueued,
        l10n.requestStatusPending,
        l10n.requestStatusInProgress,
        l10n.requestNoteQueued,
        l10n.requestNotePending,
        l10n.requestNoteInProgress,
        l10n.requestNoteDoneVersion('0.1.4'),
        l10n.requestNoteDoneLater,
        l10n.requestNoteDuplicate,
        l10n.requestNoteUnclear,
        l10n.requestNoteNotSuitable,
        l10n.requestVotes(4),
      ]) {
        await tester.scrollUntilVisible(
          find.text(text),
          300,
          scrollable: _listScrollable,
        );
        expect(find.text(text), findsWidgets, reason: text);
      }
    });

    testWidgets('an added dhikr that this app has can be opened in the library',
        (tester) async {
      final item = dhikrLibrary.firstWhere((i) => i.isRemindable);
      final l10n = await pumpMine(tester, [
        request('a', RequestStatus.done, libraryId: item.id),
      ]);

      expect(find.text(l10n.requestNoteDone), findsOneWidget);
      expect(find.text(l10n.requestShowInLibrary), findsOneWidget);
    });

    testWidgets('an added dhikr that this app does not have yet says when',
        (tester) async {
      final l10n = await pumpMine(tester, [
        request('a', RequestStatus.done, libraryId: 'from-the-future', shippedIn: '9.9.9'),
      ]);

      expect(find.text(l10n.requestNoteDoneVersion('9.9.9')), findsOneWidget);
      expect(find.text(l10n.requestShowInLibrary), findsNothing);
    });

    testWidgets('looking at the list clears the news', (tester) async {
      final (:container, :l10n, :gateway) = await _pump(
        tester,
        home: const MyRequestsScreen(),
        prefs: {
          'dhikr_reminder.requests.list':
              '[${_json(request('a', RequestStatus.done, unseen: true))}]',
        },
        remote: const [RemoteRequest(id: 'srv-a', status: RequestStatus.done)],
      );
      await tester.pumpAndSettle();

      expect(container.read(dhikrRequestsProvider).unseenCount, 0);
    });

    testWidgets('a finished request can be removed from the list',
        (tester) async {
      final l10n = await pumpMine(tester, [
        request('a', RequestStatus.declined, reason: DeclineReason.other),
      ]);

      await tester.tap(find.text(l10n.requestRemove));
      await tester.pumpAndSettle();

      expect(find.text(l10n.requestsEmptyTitle), findsOneWidget);
    });

    testWidgets('an open request cannot be removed', (tester) async {
      final l10n = await pumpMine(tester, [request('a', RequestStatus.pending)]);
      expect(find.text(l10n.requestRemove), findsNothing);
    });

    for (final lang in ['en', 'ar']) {
      testWidgets('renders in $lang without overflowing', (tester) async {
        await pumpMine(tester, [
          request('a', RequestStatus.done, shippedIn: '0.1.4'),
          request('b', RequestStatus.declined, reason: DeclineReason.unclear),
        ]);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

String _json(DhikrRequest r) {
  final map = r.toJson();
  return _encode(map);
}

String _encode(Object? value) {
  if (value is Map) {
    return '{${value.entries.map((e) => '${_encode(e.key)}:${_encode(e.value)}').join(',')}}';
  }
  if (value is String) {
    final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }
  return '$value';
}
