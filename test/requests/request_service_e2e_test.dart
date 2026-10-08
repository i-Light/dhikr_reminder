@TestOn('windows || mac-os || linux')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dhikr_reminder/features/requests/application/request_controller.dart';
import 'package:dhikr_reminder/features/requests/data/request_gateway.dart';
import 'package:dhikr_reminder/features/requests/domain/dhikr_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Dart client against the real request service (server/dev.mjs, the same
/// code as the Cloudflare Worker) running on this computer. This is what proves
/// the proof-of-work, the JSON and the status flow agree on both sides.
///
/// Skipped when Node is not installed.

const _adminToken = 'e2e-admin-token-0123456789abcdef';

bool _hasNode() {
  try {
    return Process.runSync('node', ['--version']).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

class _Service {
  _Service(this.process, this.base);

  final Process process;
  final Uri base;

  static Future<_Service> start() async {
    final port = await _freePort();
    final process = await Process.start(
      'node',
      ['dev.mjs', '--memory'],
      workingDirectory: 'server',
      environment: {
        'PORT': '$port',
        'POW_BITS': '10',
        'ADMIN_TOKEN': _adminToken,
      },
    );
    final ready = Completer<void>();
    process.stdout.transform(utf8.decoder).listen((text) {
      if (text.contains('Dhikr request service') && !ready.isCompleted) {
        ready.complete();
      }
    });
    process.stderr.transform(utf8.decoder).listen((_) {});
    await ready.future.timeout(const Duration(seconds: 20));
    return _Service(process, Uri.parse('http://127.0.0.1:$port'));
  }

  Future<void> stop() async {
    process.kill();
    await process.exitCode;
  }

  /// The admin call that moves a request along, like the admin page does.
  Future<void> setStatus(String id, Map<String, Object?> body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(base.replace(path: '/admin/api/requests/$id'));
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $_adminToken')
        ..contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close();
      await response.drain<void>();
      expect(response.statusCode, 200);
    } finally {
      client.close(force: true);
    }
  }
}

const _install = 'A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6Q7r8S9t0U1v';
const _text = 'اللهم إني أسألك علما نافعا ورزقا طيبا وعملا متقبلا';

void main() {
  final hasNode = _hasNode();

  group('the app against the real service', () {
    late _Service service;
    late HttpRequestGateway gateway;

    setUp(() async {
      service = await _Service.start();
      gateway = HttpRequestGateway(service.base);
    });

    tearDown(() async => service.stop());

    test('sends a request and reads its status back', () async {
      final result = await gateway.submit(
        installToken: _install,
        text: _text,
        source: 'رواه مسلم',
        locale: 'ar',
        platform: 'android',
        appVersion: '0.1.3',
      );
      expect(result.duplicate, isFalse);
      expect(result.request.status, RequestStatus.pending);
      expect(result.request.id, hasLength(16));

      final mine = await gateway.fetch(_install);
      expect(mine.single.id, result.request.id);
      expect(mine.single.status, RequestStatus.pending);
    });

    test('learns when the dev team has worked on it', () async {
      final sent = await gateway.submit(
        installToken: _install,
        text: _text,
        locale: 'ar',
        platform: 'android',
        appVersion: '0.1.3',
      );

      await service.setStatus(sent.request.id, {'status': 'in_progress'});
      expect((await gateway.fetch(_install)).single.status, RequestStatus.inProgress);

      await service.setStatus(sent.request.id, {
        'status': 'done',
        'libraryId': 'dabc123',
        'shippedIn': '0.1.4',
      });
      final done = (await gateway.fetch(_install)).single;
      expect(done.status, RequestStatus.done);
      expect(done.libraryId, 'dabc123');
      expect(done.shippedIn, '0.1.4');

      await service.setStatus(sent.request.id, {'status': 'declined', 'reason': 'unclear'});
      final declined = (await gateway.fetch(_install)).single;
      expect(declined.status, RequestStatus.declined);
      expect(declined.reason, DeclineReason.unclear);
    });

    test('a second person asking for the same dhikr joins the first', () async {
      final first = await gateway.submit(
        installToken: _install,
        text: _text,
        locale: 'ar',
        platform: 'android',
        appVersion: '0.1.3',
      );
      final second = await gateway.submit(
        installToken: 'Z' * 43,
        text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
        locale: 'ar',
        platform: 'windows',
        appVersion: '0.1.3',
      );

      expect(second.duplicate, isTrue);
      expect(second.request.id, first.request.id);
      expect(second.request.votes, 2);
    });

    test('the service refusing the text comes back as a rejection', () async {
      await expectLater(
        gateway.submit(
          installToken: _install,
          text: 'please add this dhikr to the library',
          locale: 'ar',
          platform: 'android',
          appVersion: '0.1.3',
        ),
        throwsA(
          isA<RequestRejected>()
              .having((e) => e.reason, 'reason', 'not_arabic'),
        ),
      );
    });

    test('a person only ever sees their own requests', () async {
      await gateway.submit(
        installToken: _install,
        text: _text,
        locale: 'ar',
        platform: 'android',
        appVersion: '0.1.3',
      );
      expect(await gateway.fetch('Y' * 43), isEmpty);
    });

    test('the whole flow through the notifier', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: [
        requestGatewayProvider.overrideWithValue(gateway),
        requestAppInfoProvider.overrideWithValue(
          () async => const RequestAppInfo(platform: 'android', appVersion: '0.1.3'),
        ),
      ]);
      addTearDown(container.dispose);
      container.listen(dhikrRequestsProvider, (_, __) {});
      final notifier = container.read(dhikrRequestsProvider.notifier);
      await notifier.loaded;

      final outcome = await notifier.submit(text: _text);
      expect(outcome, isA<Submitted>());
      final serverId = container.read(dhikrRequestsProvider).requests.single.serverId!;

      await service.setStatus(serverId, {'status': 'done', 'shippedIn': '0.1.4'});
      await notifier.refresh(force: true);

      final state = container.read(dhikrRequestsProvider);
      expect(state.requests.single.status, RequestStatus.done);
      expect(state.unseenCount, 1);
    });
  }, skip: hasNode ? false : 'Node is not installed');

  group('the gateway on its own', () {
    test('refuses to talk plain HTTP to anywhere but this computer', () {
      expect(
        () => HttpRequestGateway(Uri.parse('http://example.com')),
        throwsArgumentError,
      );
      expect(() => HttpRequestGateway(Uri.parse('https://example.com')), returnsNormally);
      expect(() => HttpRequestGateway(Uri.parse('http://127.0.0.1:8787')), returnsNormally);
    });

    test('a service that is not there is unavailable, not a crash', () async {
      final port = await _freePort();
      final gateway = HttpRequestGateway(Uri.parse('http://127.0.0.1:$port'));
      await expectLater(gateway.fetch(_install), throwsA(isA<RequestUnavailable>()));
    });

    test('an answer that is not the service is unavailable too', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) {
        request.response
          ..statusCode = 200
          ..write('<html>not json</html>');
        unawaited(request.response.close());
      });
      final gateway = HttpRequestGateway(Uri.parse('http://127.0.0.1:${server.port}'));
      await expectLater(gateway.fetch(_install), throwsA(isA<RequestUnavailable>()));
    });

    test('an answer that is far too big is not read to the end', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response.statusCode = 200;
        try {
          for (var i = 0; i < 100; i++) {
            request.response.write('x' * 8192);
            await request.response.flush();
          }
        } catch (_) {
          // The client hung up, as it should.
        }
        await request.response.close().catchError((_) {});
      });
      final gateway = HttpRequestGateway(Uri.parse('http://127.0.0.1:${server.port}'));
      await expectLater(gateway.fetch(_install), throwsA(isA<RequestUnavailable>()));
    });

    test('does not follow a redirect', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) {
        request.response
          ..statusCode = 302
          ..headers.set(HttpHeaders.locationHeader, 'http://127.0.0.1:1/elsewhere');
        unawaited(request.response.close());
      });
      final gateway = HttpRequestGateway(Uri.parse('http://127.0.0.1:${server.port}'));
      await expectLater(gateway.fetch(_install), throwsA(isA<RequestUnavailable>()));
    });
  });
}
