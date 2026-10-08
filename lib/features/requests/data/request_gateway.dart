import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dhikr_reminder/features/requests/data/proof_of_work.dart';
import 'package:dhikr_reminder/features/requests/domain/dhikr_request.dart';
import 'package:flutter/foundation.dart';

/// What the service says about one request.
@immutable
class RemoteRequest {
  const RemoteRequest({
    required this.id,
    required this.status,
    this.reason,
    this.libraryId,
    this.shippedIn,
    this.votes = 1,
  });

  final String id;

  /// Never [RequestStatus.queued]: that one only exists on the device.
  final RequestStatus status;
  final DeclineReason? reason;
  final String? libraryId;
  final String? shippedIn;
  final int votes;

  /// Reads one request of the service's answer; null when it is not one.
  static RemoteRequest? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    if (id is! String || id.isEmpty || id.length > 64) return null;
    final status = switch (raw['status']) {
      'in_progress' => RequestStatus.inProgress,
      'done' => RequestStatus.done,
      'declined' => RequestStatus.declined,
      _ => RequestStatus.pending,
    };
    final reason = switch (raw['reason']) {
      'duplicate' => DeclineReason.duplicate,
      'unclear' => DeclineReason.unclear,
      'not_suitable' => DeclineReason.notSuitable,
      'other' => DeclineReason.other,
      _ => null,
    };
    String? shortString(Object? value) =>
        value is String && value.isNotEmpty && value.length <= 40
            ? value
            : null;
    return RemoteRequest(
      id: id,
      status: status,
      reason: status == RequestStatus.declined
          ? (reason ?? DeclineReason.other)
          : null,
      libraryId: shortString(raw['libraryId']),
      shippedIn: shortString(raw['shippedIn']),
      votes: raw['votes'] is int && (raw['votes'] as int) > 0
          ? raw['votes'] as int
          : 1,
    );
  }
}

/// The service's answer to a sent request.
@immutable
class SubmitResult {
  const SubmitResult({required this.request, required this.duplicate});

  final RemoteRequest request;

  /// Somebody had already asked for the same dhikr; this person joined them.
  final bool duplicate;
}

/// Something stopped a request from going through.
sealed class RequestFailure implements Exception {
  const RequestFailure();
}

/// The service looked at the request and said no: retrying will not help.
/// [reason] is the service's word for it when it gave one (`too_short`,
/// `not_arabic`, `has_link`, ...).
class RequestRejected extends RequestFailure {
  const RequestRejected(this.code, [this.reason]);

  final String code;
  final String? reason;

  @override
  String toString() => 'RequestRejected($code, $reason)';
}

/// Too many requests, from this person or from everyone. Try again after
/// [retryAfterSeconds] when the service said how long.
class RequestRateLimited extends RequestFailure {
  const RequestRateLimited(this.code, [this.retryAfterSeconds]);

  final String code;
  final int? retryAfterSeconds;

  @override
  String toString() => 'RequestRateLimited($code, $retryAfterSeconds)';
}

/// The service could not be reached or did not answer properly. The request is
/// kept and tried again later.
class RequestUnavailable extends RequestFailure {
  const RequestUnavailable(this.message);

  final String message;

  @override
  String toString() => 'RequestUnavailable($message)';
}

/// The conversation with the request service.
abstract class RequestGateway {
  /// Sends a request. [installToken] is the app's random secret, see
  /// `DhikrRequestsNotifier`. Throws a [RequestFailure].
  Future<SubmitResult> submit({
    required String installToken,
    required String text,
    String? source,
    required String locale,
    required String platform,
    required String appVersion,
  });

  /// The status of every request this install has made. Throws a
  /// [RequestFailure].
  Future<List<RemoteRequest>> fetch(String installToken);
}

/// [RequestGateway] over HTTPS with `dart:io`.
///
/// Careful on purpose: only HTTPS (plain HTTP to the loopback address in a
/// debug build, for trying it out), no redirects followed, short timeouts, and
/// no more than 64 KB of answer read. Whatever comes back is parsed field by
/// field and never trusted to be well formed.
class HttpRequestGateway implements RequestGateway {
  HttpRequestGateway(this.base, {HttpClient Function()? clientFactory})
      : _clientFactory = clientFactory ?? HttpClient.new {
    final secure = base.scheme == 'https';
    final loopback = base.scheme == 'http' &&
        (base.host == '127.0.0.1' || base.host == 'localhost');
    if (!secure && !(loopback && kDebugMode)) {
      throw ArgumentError.value(base, 'base', 'must be an https address');
    }
  }

  final Uri base;
  final HttpClient Function() _clientFactory;

  static const _maxAnswerBytes = 64 * 1024;
  static const _timeout = Duration(seconds: 25);

  @override
  Future<SubmitResult> submit({
    required String installToken,
    required String text,
    String? source,
    required String locale,
    required String platform,
    required String appVersion,
  }) async {
    final challenge = await _send('GET', '/v1/challenge');
    final puzzle = challenge.body;
    final challengeText = puzzle['challenge'];
    final bits = puzzle['bits'];
    if (challengeText is! String || bits is! int || bits < 0 || bits > 28) {
      throw const RequestUnavailable('bad puzzle');
    }
    final counter = await solveProofOfWork(
      challenge: challengeText,
      install: installToken,
      bits: bits,
    );

    final answer = await _send(
      'POST',
      '/v1/requests',
      token: installToken,
      body: {
        'text': text,
        if (source != null) 'source': source,
        'challenge': challengeText,
        'counter': counter,
        'locale': locale,
        'platform': platform,
        'appVersion': appVersion,
      },
    );
    final remote = RemoteRequest.tryFromJson(answer.body);
    if (remote == null) throw const RequestUnavailable('bad answer');
    return SubmitResult(
      request: remote,
      duplicate: answer.body['duplicate'] == true,
    );
  }

  @override
  Future<List<RemoteRequest>> fetch(String installToken) async {
    final answer = await _send('GET', '/v1/requests', token: installToken);
    final list = answer.body['requests'];
    if (list is! List) throw const RequestUnavailable('bad answer');
    return [
      for (final item in list)
        if (RemoteRequest.tryFromJson(item) case final remote?) remote,
    ];
  }

  Future<({int status, Map<String, dynamic> body})> _send(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    final client = _clientFactory()..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = base.replace(path: path);
      final request = await client.openUrl(method, uri);
      request.followRedirects = false;
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set(HttpHeaders.userAgentHeader, 'dhikr_reminder-requests');
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        final bytes = utf8.encode(jsonEncode(body));
        request.headers
          ..contentType = ContentType('application', 'json', charset: 'utf-8')
          ..contentLength = bytes.length;
        request.add(bytes);
      }
      final response = await request.close().timeout(_timeout);
      final text = await _readLimited(response).timeout(_timeout);

      Map<String, dynamic> json = const {};
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) json = decoded;
      } on FormatException {
        // Not JSON; the status code still says enough.
      }

      final status = response.statusCode;
      if (status >= 200 && status < 300) return (status: status, body: json);

      final code = json['error'] is String ? json['error'] as String : 'error';
      if (status == 429) {
        final retry = json['retryAfter'];
        throw RequestRateLimited(code, retry is int ? retry : null);
      }
      if (status == 400 && code == 'invalid_text') {
        throw RequestRejected(
          code,
          json['reason'] is String ? json['reason'] as String : null,
        );
      }
      throw RequestUnavailable('HTTP $status $code');
    } on RequestFailure {
      rethrow;
    } on TimeoutException {
      throw const RequestUnavailable('timeout');
    } on SocketException catch (e) {
      throw RequestUnavailable('network: ${e.message}');
    } on HandshakeException catch (e) {
      throw RequestUnavailable('tls: ${e.message}');
    } on HttpException catch (e) {
      throw RequestUnavailable('http: ${e.message}');
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _readLimited(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > _maxAnswerBytes) {
        throw const RequestUnavailable('answer too large');
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}
