import 'dart:convert';

import 'package:dhikr_reminder/features/requests/application/request_controller.dart';
import 'package:dhikr_reminder/features/requests/data/request_gateway.dart';
import 'package:dhikr_reminder/features/requests/domain/dhikr_request.dart';
import 'package:dhikr_reminder/features/requests/domain/request_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that does what the test tells it to.
class FakeGateway implements RequestGateway {
  final submitted = <({String token, String text, String? source})>[];
  int fetches = 0;

  /// Thrown by the next [submit] calls, one each, while not empty.
  final failures = <RequestFailure>[];

  /// What [fetch] answers.
  List<RemoteRequest> remote = [];
  RequestFailure? fetchFailure;

  int _next = 0;

  @override
  Future<SubmitResult> submit({
    required String installToken,
    required String text,
    String? source,
    required String locale,
    required String platform,
    required String appVersion,
  }) async {
    if (failures.isNotEmpty) throw failures.removeAt(0);
    submitted.add((token: installToken, text: text, source: source));
    final request = RemoteRequest(id: 'srv${_next++}', status: RequestStatus.pending);
    remote = [...remote, request];
    return SubmitResult(request: request, duplicate: false);
  }

  @override
  Future<List<RemoteRequest>> fetch(String installToken) async {
    fetches++;
    if (fetchFailure != null) throw fetchFailure!;
    return remote;
  }
}

const _dhikrs = [
  'اللهم إني أسألك علما نافعا ورزقا طيبا',
  'اللهم اغفر لي ذنبي كله دقه وجله وأوله وآخره',
  'ربنا لا تؤاخذنا إن نسينا أو أخطأنا',
  'اللهم إني أعوذ بك من الهم والحزن',
  'اللهم اكفني بحلالك عن حرامك واغنني بفضلك',
  'اللهم ثبتني على دينك حتى ألقاك',
];

class _Rig {
  _Rig(this.container, this.gateway, this.clock);

  final ProviderContainer container;
  final FakeGateway gateway;
  final _Clock clock;

  DhikrRequestsNotifier get notifier =>
      container.read(dhikrRequestsProvider.notifier);
  RequestsState get state => container.read(dhikrRequestsProvider);
}

class _Clock {
  DateTime now = DateTime(2026, 10, 8, 12);
  void advance(Duration d) => now = now.add(d);
}

Future<_Rig> _rig({Map<String, Object> prefs = const {}, FakeGateway? gateway}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final fake = gateway ?? FakeGateway();
  final clock = _Clock();
  final container = ProviderContainer(overrides: [
    requestGatewayProvider.overrideWithValue(fake),
    requestClockProvider.overrideWithValue(() => clock.now),
    requestAppInfoProvider.overrideWithValue(
      () async => const RequestAppInfo(platform: 'android', appVersion: '0.1.3'),
    ),
  ]);
  addTearDown(container.dispose);
  container.listen(dhikrRequestsProvider, (_, __) {});
  await container.read(dhikrRequestsProvider.notifier).loaded;
  return _Rig(container, fake, clock);
}

void main() {
  group('making a request', () {
    test('sends it and keeps it as pending', () async {
      final rig = await _rig();

      final outcome = await rig.notifier.submit(text: _dhikrs[0], source: 'رواه مسلم');

      expect(outcome, isA<Submitted>());
      expect(rig.gateway.submitted.single.text, _dhikrs[0]);
      expect(rig.gateway.submitted.single.source, 'رواه مسلم');
      expect(rig.state.requests.single.status, RequestStatus.pending);
      expect(rig.state.requests.single.serverId, 'srv0');
      expect(rig.state.openCount, 1);
    });

    test('cleans the text before sending it', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: '  ${_dhikrs[0]}  \n\n\n\n ');
      expect(rig.gateway.submitted.single.text, _dhikrs[0]);
    });

    test('uses one install token for every request, and it is well formed',
        () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      rig.clock.advance(const Duration(minutes: 1));
      await rig.notifier.submit(text: _dhikrs[1]);

      final tokens = rig.gateway.submitted.map((s) => s.token).toSet();
      expect(tokens, hasLength(1));
      expect(tokens.single, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('dhikr_reminder.requests.install'), tokens.single);
    });

    test('makes a different token on another install', () async {
      final a = await _rig();
      await a.notifier.submit(text: _dhikrs[0]);
      final b = await _rig();
      await b.notifier.submit(text: _dhikrs[0]);
      expect(a.gateway.submitted.single.token,
          isNot(b.gateway.submitted.single.token));
    });

    test('says why a text is not fit to send, without sending it', () async {
      final rig = await _rig();
      final cases = {
        'قصير': RequestProblem.tooShort,
        'please add a dhikr to the library': RequestProblem.notArabic,
        'اللهم اغفر لي https://x.example': RequestProblem.hasLink,
        'اللهم اااااااا اغفر لي': RequestProblem.repeated,
        'اللهم ' * 120: RequestProblem.tooLong,
      };
      for (final entry in cases.entries) {
        final outcome = await rig.notifier.submit(text: entry.key);
        expect(outcome, isA<Refused>(), reason: entry.key);
        expect((outcome as Refused).problem, entry.value, reason: entry.key);
      }
      expect(rig.gateway.submitted, isEmpty);
      expect(rig.state.requests, isEmpty);
    });

    test('refuses a link in the source', () async {
      final rig = await _rig();
      final outcome = await rig.notifier
          .submit(text: _dhikrs[0], source: 'https://spam.example');
      expect((outcome as Refused).problem, RequestProblem.hasLink);
    });

    test('does not ask twice for the same dhikr', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      rig.clock.advance(const Duration(minutes: 1));

      final again = await rig.notifier.submit(
        text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا',
      );

      expect(again, isA<AlreadyRequested>());
      expect(rig.gateway.submitted, hasLength(1));
    });

    test('may ask again for a dhikr that was declined', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      rig.gateway.remote = [
        const RemoteRequest(
          id: 'srv0',
          status: RequestStatus.declined,
          reason: DeclineReason.unclear,
        ),
      ];
      await rig.notifier.refresh(force: true);
      rig.clock.advance(const Duration(minutes: 1));

      expect(await rig.notifier.submit(text: _dhikrs[0]), isA<Submitted>());
    });
  });

  group('limits on the device', () {
    test('three open requests at a time', () async {
      final rig = await _rig();
      for (var i = 0; i < 3; i++) {
        expect(await rig.notifier.submit(text: _dhikrs[i]), isA<Submitted>());
        rig.clock.advance(const Duration(minutes: 1));
      }
      final fourth = await rig.notifier.submit(text: _dhikrs[3]);
      expect((fourth as Refused).problem, RequestProblem.tooManyOpen);
    });

    test('a pause between two requests', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      rig.clock.advance(const Duration(seconds: 5));
      final soon = await rig.notifier.submit(text: _dhikrs[1]);
      expect((soon as Refused).problem, RequestProblem.tooSoon);
      expect(soon.seconds, inInclusiveRange(1, 20));

      rig.clock.advance(const Duration(seconds: 20));
      expect(await rig.notifier.submit(text: _dhikrs[1]), isA<Submitted>());
    });

    test('five requests in a day, then it says to come back tomorrow',
        () async {
      final rig = await _rig();
      for (var i = 0; i < 5; i++) {
        expect(await rig.notifier.submit(text: _dhikrs[i]), isA<Submitted>());
        // Finish each one so the open limit is not what stops the next.
        rig.gateway.remote = [
          for (final r in rig.gateway.remote)
            RemoteRequest(id: r.id, status: RequestStatus.done),
        ];
        await rig.notifier.refresh(force: true);
        rig.clock.advance(const Duration(minutes: 30));
      }
      final sixth = await rig.notifier.submit(text: _dhikrs[5]);
      expect((sixth as Refused).problem, RequestProblem.dailyLimit);
      expect(sixth.seconds, greaterThan(0));

      rig.clock.advance(const Duration(days: 1));
      expect(await rig.notifier.submit(text: _dhikrs[5]), isA<Submitted>());
    });
  });

  group('when the service answers badly', () {
    test('no connection keeps the request to send later', () async {
      final rig = await _rig();
      rig.gateway.failures.add(const RequestUnavailable('offline'));

      final outcome = await rig.notifier.submit(text: _dhikrs[0]);

      expect(outcome, isA<Queued>());
      expect(rig.state.requests.single.status, RequestStatus.queued);
      expect(rig.state.openCount, 1);

      await rig.notifier.refresh(force: true);
      expect(rig.state.requests.single.status, RequestStatus.pending);
      expect(rig.gateway.submitted.single.text, _dhikrs[0]);
    });

    test('a queued request is sent in the order it was made', () async {
      final rig = await _rig();
      rig.gateway.failures
        ..add(const RequestUnavailable('offline'))
        ..add(const RequestUnavailable('offline'));
      await rig.notifier.submit(text: _dhikrs[0]);
      rig.clock.advance(const Duration(minutes: 1));
      await rig.notifier.submit(text: _dhikrs[1]);

      await rig.notifier.refresh(force: true);

      expect(rig.gateway.submitted.map((s) => s.text), [_dhikrs[0], _dhikrs[1]]);
    });

    test('stays queued while the service is still away', () async {
      final rig = await _rig();
      rig.gateway.failures
        ..add(const RequestUnavailable('offline'))
        ..add(const RequestUnavailable('still offline'));
      await rig.notifier.submit(text: _dhikrs[0]);

      await rig.notifier.refresh(force: true);

      expect(rig.state.requests.single.status, RequestStatus.queued);
    });

    test('the service refusing the text drops the request with a reason',
        () async {
      final rig = await _rig();
      rig.gateway.failures.add(const RequestRejected('invalid_text', 'not_arabic'));

      final outcome = await rig.notifier.submit(text: _dhikrs[0]);

      expect((outcome as Refused).problem, RequestProblem.notArabic);
      expect(rig.state.requests, isEmpty);
    });

    test('the service asking for a pause drops the request and says so',
        () async {
      final rig = await _rig();
      rig.gateway.failures.add(const RequestRateLimited('rate_limited', 120));

      final outcome = await rig.notifier.submit(text: _dhikrs[0]);

      expect((outcome as Refused).problem, RequestProblem.busy);
      expect(outcome.seconds, 120);
      expect(rig.state.requests, isEmpty);
    });

    test('the service saying too many are open maps to the same message',
        () async {
      final rig = await _rig();
      rig.gateway.failures.add(const RequestRateLimited('too_many_open'));

      final outcome = await rig.notifier.submit(text: _dhikrs[0]);

      expect((outcome as Refused).problem, RequestProblem.tooManyOpen);
    });

    test('without a service the feature just refuses', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [requestGatewayProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);
      expect(container.read(requestsEnabledProvider), isFalse);
      final outcome = await container
          .read(dhikrRequestsProvider.notifier)
          .submit(text: _dhikrs[0]);
      expect(outcome, isA<Refused>());
    });
  });

  group('following a request', () {
    test('picks up each change and marks it as news', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      expect(rig.state.unseenCount, 0);

      rig.gateway.remote = [
        const RemoteRequest(id: 'srv0', status: RequestStatus.inProgress, votes: 3),
      ];
      await rig.notifier.refresh(force: true);
      expect(rig.state.requests.single.status, RequestStatus.inProgress);
      expect(rig.state.requests.single.votes, 3);
      expect(rig.state.unseenCount, 1);

      await rig.notifier.markAllSeen();
      expect(rig.state.unseenCount, 0);

      rig.gateway.remote = [
        const RemoteRequest(
          id: 'srv0',
          status: RequestStatus.done,
          libraryId: 'dabc',
          shippedIn: '0.1.4',
        ),
      ];
      await rig.notifier.refresh(force: true);
      final done = rig.state.requests.single;
      expect(done.status, RequestStatus.done);
      expect(done.libraryId, 'dabc');
      expect(done.shippedIn, '0.1.4');
      expect(rig.state.unseenCount, 1);
    });

    test('more votes alone are not news', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      rig.gateway.remote = [
        const RemoteRequest(id: 'srv0', status: RequestStatus.pending, votes: 9),
      ];
      await rig.notifier.refresh(force: true);
      expect(rig.state.requests.single.votes, 9);
      expect(rig.state.unseenCount, 0);
    });

    test('a decline carries its reason, and a later answer clears it',
        () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      rig.gateway.remote = [
        const RemoteRequest(
          id: 'srv0',
          status: RequestStatus.declined,
          reason: DeclineReason.duplicate,
        ),
      ];
      await rig.notifier.refresh(force: true);
      expect(rig.state.requests.single.reason, DeclineReason.duplicate);

      rig.gateway.remote = [
        const RemoteRequest(id: 'srv0', status: RequestStatus.done),
      ];
      await rig.notifier.refresh(force: true);
      expect(rig.state.requests.single.reason, isNull);
    });

    test('a request the dev team deleted disappears', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      rig.gateway.remote = [];
      await rig.notifier.refresh(force: true);
      expect(rig.state.requests, isEmpty);
    });

    test('a failed check leaves the list as it was', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      rig.gateway.fetchFailure = const RequestUnavailable('offline');
      await rig.notifier.refresh(force: true);
      expect(rig.state.requests.single.status, RequestStatus.pending);
      expect(rig.state.isSyncing, isFalse);
    });

    test('checks at most every twenty seconds unless asked to', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      await rig.notifier.refresh(force: true);
      final after = rig.gateway.fetches;

      await rig.notifier.refresh();
      expect(rig.gateway.fetches, after);

      rig.clock.advance(const Duration(seconds: 25));
      await rig.notifier.refresh();
      expect(rig.gateway.fetches, after + 1);
    });

    test('does not call the service when there is nothing to follow', () async {
      final rig = await _rig();
      await rig.notifier.refresh(force: true);
      expect(rig.gateway.fetches, 0);
    });
  });

  group('the list', () {
    test('a finished request can be removed, an open one cannot', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0]);
      final id = rig.state.requests.single.localId;

      await rig.notifier.forget(id);
      expect(rig.state.requests, hasLength(1));

      rig.gateway.remote = [const RemoteRequest(id: 'srv0', status: RequestStatus.done)];
      await rig.notifier.refresh(force: true);
      await rig.notifier.forget(id);
      expect(rig.state.requests, isEmpty);
    });

    test('is kept across a restart', () async {
      final rig = await _rig();
      await rig.notifier.submit(text: _dhikrs[0], source: 'رواه مسلم');
      rig.gateway.remote = [
        const RemoteRequest(id: 'srv0', status: RequestStatus.inProgress),
      ];
      await rig.notifier.refresh(force: true);

      final prefs = await SharedPreferences.getInstance();
      final again = await _rig(prefs: {
        for (final key in prefs.getKeys()) key: prefs.get(key)!,
      });

      final request = again.state.requests.single;
      expect(request.text, _dhikrs[0]);
      expect(request.source, 'رواه مسلم');
      expect(request.status, RequestStatus.inProgress);
      expect(request.unseen, isTrue);
    });

    test('a damaged saved list does not stop the app', () async {
      final rig = await _rig(prefs: {
        'dhikr_reminder.requests.list': jsonEncode([
          {'localId': 'ok', 'text': 'نص', 'createdAt': 1, 'status': 'done'},
          'rubbish',
          {'nope': true},
        ]),
      });
      expect(rig.state.requests.map((r) => r.localId), ['ok']);

      final broken = await _rig(prefs: {'dhikr_reminder.requests.list': '{not json'});
      expect(broken.state.requests, isEmpty);
      expect(broken.state.isLoaded, isTrue);
    });

    test('keeps only so many, dropping the oldest finished first', () async {
      final saved = [
        for (var i = 0; i < requestMaxKept + 5; i++)
          DhikrRequest(
            localId: 'old$i',
            serverId: 'srv$i',
            text: 'اللهم ارزقني رقم $i',
            createdAt: DateTime(2026, 1, 1).add(Duration(days: i)),
            status: RequestStatus.done,
          ).toJson(),
      ].reversed.toList();
      final rig = await _rig(prefs: {
        'dhikr_reminder.requests.list': jsonEncode(saved),
      });
      rig.gateway.remote = [
        for (var i = 0; i < requestMaxKept + 5; i++)
          RemoteRequest(id: 'srv$i', status: RequestStatus.done),
      ];

      await rig.notifier.refresh(force: true);

      expect(rig.state.requests.length, requestMaxKept);
    });
  });
}
