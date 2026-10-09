import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:dhikr_reminder/core/locale/locale_controller.dart';
import 'package:dhikr_reminder/features/requests/data/request_gateway.dart';
import 'package:dhikr_reminder/features/requests/data/requests_config.dart';
import 'package:dhikr_reminder/features/requests/domain/dhikr_request.dart';
import 'package:dhikr_reminder/features/requests/domain/request_rules.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _listPrefsKey = 'dhikr_reminder.requests.list';
const _installPrefsKey = 'dhikr_reminder.requests.install';

/// The service address in use. Empty here, so a test never reaches the real
/// service by accident; `main` sets it to [requestsApiUrl].
final requestsUrlProvider = Provider<String>((ref) => '');

/// The conversation with the request service, or null when this build has no
/// service to talk to (see [requestsApiUrl]). Overridden in tests.
final requestGatewayProvider = Provider<RequestGateway?>((ref) {
  final url = ref.watch(requestsUrlProvider);
  final uri = Uri.tryParse(url);
  if (url.isEmpty || uri == null || !uri.hasAuthority) return null;
  try {
    return HttpRequestGateway(uri);
  } on ArgumentError {
    return null;
  }
});

/// Whether requesting a dhikr is possible in this build.
final requestsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(requestGatewayProvider) != null,
);

/// What is sent along with a request to say which app it came from.
@immutable
class RequestAppInfo {
  const RequestAppInfo({required this.platform, required this.appVersion});

  final String platform;
  final String appVersion;
}

/// The seam tests replace for the app version and platform.
final requestAppInfoProvider = Provider<Future<RequestAppInfo> Function()>(
  (ref) => () async {
    var version = 'unknown';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isWindows
            ? 'windows'
            : Platform.operatingSystem;
    return RequestAppInfo(platform: platform, appVersion: version);
  },
);

/// The seam tests replace for the time.
final requestClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// A reason a request was not made, in terms the screen can explain.
enum RequestProblem {
  tooShort,
  tooLong,
  notArabic,
  hasLink,
  repeated,

  /// Three requests are already open.
  tooManyOpen,

  /// Five requests in the last day.
  dailyLimit,

  /// The last one was a moment ago.
  tooSoon,

  /// The service asked for a pause.
  busy,

  /// The service looked at the text and refused it.
  rejected,
}

/// What came of asking to make a request.
sealed class SubmitOutcome {
  const SubmitOutcome();
}

/// Sent, and the service has it. [duplicate] means somebody had already asked
/// for the same dhikr and this person was added to them.
class Submitted extends SubmitOutcome {
  const Submitted(this.request, {this.duplicate = false});

  final DhikrRequest request;
  final bool duplicate;
}

/// Kept on the device to be sent when the connection is back.
class Queued extends SubmitOutcome {
  const Queued(this.request);

  final DhikrRequest request;
}

/// The person already asked for this one.
class AlreadyRequested extends SubmitOutcome {
  const AlreadyRequested(this.request);

  final DhikrRequest request;
}

/// Not made. [seconds] is how long to wait, when that is the problem.
class Refused extends SubmitOutcome {
  const Refused(this.problem, {this.seconds});

  final RequestProblem problem;
  final int? seconds;
}

@immutable
class RequestsState {
  const RequestsState({
    this.requests = const [],
    this.isLoaded = false,
    this.isSyncing = false,
  });

  /// Newest first.
  final List<DhikrRequest> requests;

  /// Whether the saved list has been read yet.
  final bool isLoaded;
  final bool isSyncing;

  /// Requests whose status changed since the person last looked.
  int get unseenCount => requests.where((r) => r.unseen).length;

  /// Requests still going through at [now]. One that never got sent and is
  /// days old is stuck and does not count, so it cannot block new requests.
  int openCountAt(DateTime now) =>
      requests.where((r) => r.countsAsOpenAt(now)).length;

  RequestsState copyWith({
    List<DhikrRequest>? requests,
    bool? isLoaded,
    bool? isSyncing,
  }) {
    return RequestsState(
      requests: requests ?? this.requests,
      isLoaded: isLoaded ?? this.isLoaded,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

/// The person's requests: keeps them on the device, sends new ones (or holds
/// them until there is a connection), and asks the service how the earlier
/// ones are going.
class DhikrRequestsNotifier extends Notifier<RequestsState> {
  DateTime? _lastSync;
  Future<void>? _loading;

  @override
  RequestsState build() {
    _loading = _load();
    return const RequestsState();
  }

  RequestGateway? get _gateway => ref.read(requestGatewayProvider);
  DateTime get _now => ref.read(requestClockProvider)();

  /// Completes once the saved list has been read.
  Future<void> get loaded => _loading ?? Future.value();

  Future<void> _load() async {
    var requests = <DhikrRequest>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_listPrefsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          requests = [
            for (final item in decoded)
              if (DhikrRequest.tryFromJson(item) case final request?) request,
          ];
        }
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load the saved requests; starting empty.',
        name: 'dhikr_reminder.requests',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
    state = state.copyWith(requests: requests, isLoaded: true);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _listPrefsKey,
        jsonEncode([for (final r in state.requests) r.toJson()]),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to save the requests.',
        name: 'dhikr_reminder.requests',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The random secret that stands for this install at the service. Made on
  /// first use and kept: it is what lets the person see their own requests and
  /// nobody else's. 32 random bytes, 43 URL-safe characters.
  Future<String> _installToken() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_installPrefsKey);
    if (saved != null && RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(saved)) {
      return saved;
    }
    final random = Random.secure();
    final token = base64Url.encode(
        [for (var i = 0; i < 32; i++) random.nextInt(256)]).replaceAll('=', '');
    await prefs.setString(_installPrefsKey, token);
    return token;
  }

  /// Asks for [text] to be added to the library.
  ///
  /// Checks everything it can on the device first, so a mistake is explained
  /// at once; sends it; and if there is no connection keeps it to be sent
  /// later, which still counts as made.
  Future<SubmitOutcome> submit({required String text, String? source}) async {
    await loaded;
    final gateway = _gateway;
    if (gateway == null) return const Refused(RequestProblem.rejected);

    final cleaned = cleanRequestText(text);
    switch (checkRequestText(cleaned)) {
      case RequestTextProblem.tooShort:
        return const Refused(RequestProblem.tooShort);
      case RequestTextProblem.tooLong:
        return const Refused(RequestProblem.tooLong);
      case RequestTextProblem.notArabic:
        return const Refused(RequestProblem.notArabic);
      case RequestTextProblem.hasLink:
        return const Refused(RequestProblem.hasLink);
      case RequestTextProblem.repeated:
        return const Refused(RequestProblem.repeated);
      case null:
        break;
    }
    final cleanedSource = source == null ? null : cleanRequestSource(source);
    if (requestSourceHasLink(cleanedSource)) {
      return const Refused(RequestProblem.hasLink);
    }

    final existing = findOwnRequest(cleaned, state.requests);
    if (existing != null) return AlreadyRequested(existing);

    final now = _now;
    if (state.openCountAt(now) >= requestMaxOpen) {
      return const Refused(RequestProblem.tooManyOpen);
    }
    final lastDay = state.requests
        .where((r) => now.difference(r.createdAt) < const Duration(days: 1))
        .toList();
    if (lastDay.length >= requestMaxPerDay) {
      final oldest = lastDay
          .map((r) => r.createdAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final wait = const Duration(days: 1) - now.difference(oldest);
      return Refused(RequestProblem.dailyLimit, seconds: wait.inSeconds);
    }
    if (lastDay.isNotEmpty) {
      final newest = lastDay
          .map((r) => r.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final since = now.difference(newest);
      if (since < requestMinGap) {
        return Refused(
          RequestProblem.tooSoon,
          seconds: (requestMinGap - since).inSeconds + 1,
        );
      }
    }

    final request = DhikrRequest(
      localId: 'r${now.microsecondsSinceEpoch}',
      text: cleaned,
      source: cleanedSource,
      createdAt: now,
      status: RequestStatus.queued,
    );
    state = state.copyWith(requests: [request, ...state.requests]);
    await _save();

    final sent = await _send(request);
    return switch (sent) {
      final _Sent s => Submitted(s.request, duplicate: s.duplicate),
      final _Dropped d => Refused(d.problem, seconds: d.seconds),
      _ => Queued(request),
    };
  }

  /// Tries to send one queued request. Updates the list to match.
  Future<_SendResult> _send(DhikrRequest request) async {
    final gateway = _gateway;
    if (gateway == null) return const _Kept();
    try {
      final info = await ref.read(requestAppInfoProvider)();
      final result = await gateway.submit(
        installToken: await _installToken(),
        text: request.text,
        source: request.source,
        locale: ref.read(localeProvider).languageCode,
        platform: info.platform,
        appVersion: info.appVersion,
      );
      final remote = result.request;
      final updated = request.copyWith(
        serverId: remote.id,
        status: remote.status,
        reason: remote.reason,
        libraryId: remote.libraryId,
        shippedIn: remote.shippedIn,
        votes: remote.votes,
        unseen: false,
      );
      _replace(updated);
      await _save();
      return _Sent(updated, result.duplicate);
    } on RequestRejected catch (error) {
      _remove(request.localId);
      await _save();
      return _Dropped(switch (error.reason) {
        'too_short' => RequestProblem.tooShort,
        'too_long' => RequestProblem.tooLong,
        'not_arabic' => RequestProblem.notArabic,
        'has_link' => RequestProblem.hasLink,
        'repeated' => RequestProblem.repeated,
        _ => RequestProblem.rejected,
      });
    } on RequestRateLimited catch (error) {
      if (error.code != 'too_many_open') {
        // The daily cap or a busy service: nothing is wrong with the request
        // itself, so it stays on the list and is sent on a later refresh
        // instead of being thrown away.
        developer.log(
          'The service is not taking requests right now: ${error.code}',
          name: 'dhikr_reminder.requests',
        );
        return const _Kept();
      }
      _remove(request.localId);
      await _save();
      return _Dropped(
        RequestProblem.tooManyOpen,
        seconds: error.retryAfterSeconds,
      );
    } on RequestUnavailable catch (error) {
      developer.log(
        'Could not send a request yet: $error',
        name: 'dhikr_reminder.requests',
      );
      return const _Kept();
    }
  }

  void _replace(DhikrRequest updated) {
    state = state.copyWith(
      requests: [
        for (final r in state.requests)
          r.localId == updated.localId ? updated : r,
      ],
    );
  }

  void _remove(String localId) {
    state = state.copyWith(
      requests: [
        for (final r in state.requests)
          if (r.localId != localId) r,
      ],
    );
  }

  /// Sends what is waiting to be sent and asks the service how every request
  /// is going. Quiet about failure: no connection just means try again later.
  /// Does nothing more than once every 20 seconds unless [force] is set.
  Future<void> refresh({bool force = false}) async {
    await loaded;
    if (_gateway == null || state.isSyncing) return;
    final started = _now;
    if (!force &&
        _lastSync != null &&
        started.difference(_lastSync!) < const Duration(seconds: 20)) {
      return;
    }
    _lastSync = started;
    state = state.copyWith(isSyncing: true);
    try {
      final waiting = state.requests
          .where((r) => r.status == RequestStatus.queued)
          .toList()
          .reversed;
      for (final request in waiting) {
        final result = await _send(request);
        if (result is _Kept) break;
      }

      if (state.requests.any((r) => r.serverId != null)) {
        final remote = await _gateway!.fetch(await _installToken());
        _merge(remote);
        await _save();
      }
    } on RequestFailure catch (error) {
      developer.log(
        'Could not refresh the requests: $error',
        name: 'dhikr_reminder.requests',
      );
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  void _merge(List<RemoteRequest> remote) {
    final byId = {for (final r in remote) r.id: r};
    final merged = <DhikrRequest>[];
    for (final local in state.requests) {
      final id = local.serverId;
      if (id == null) {
        merged.add(local);
        continue;
      }
      final now = byId[id];
      // Gone from the service: the dev team removed it. Nothing to show.
      if (now == null) continue;
      final changedStatus = now.status != local.status ||
          now.reason != local.reason ||
          now.libraryId != local.libraryId;
      merged.add(
        DhikrRequest(
          localId: local.localId,
          serverId: local.serverId,
          text: local.text,
          source: local.source,
          createdAt: local.createdAt,
          status: now.status,
          reason: now.reason,
          libraryId: now.libraryId,
          shippedIn: now.shippedIn,
          votes: now.votes,
          // News is the dev team having done something, not just more votes.
          unseen: local.unseen ||
              (changedStatus && now.status != RequestStatus.pending),
        ),
      );
    }
    state = state.copyWith(requests: _pruned(merged));
  }

  List<DhikrRequest> _pruned(List<DhikrRequest> requests) {
    if (requests.length <= requestMaxKept) return requests;
    final keep = [...requests];
    for (var i = keep.length - 1; i >= 0 && keep.length > requestMaxKept; i--) {
      if (keep[i].status.isFinished) keep.removeAt(i);
    }
    return keep;
  }

  /// The person has looked at the list: nothing in it is news any more.
  Future<void> markAllSeen() async {
    if (state.unseenCount == 0) return;
    state = state.copyWith(
      requests: [
        for (final r in state.requests)
          r.unseen ? r.copyWith(unseen: false) : r,
      ],
    );
    await _save();
  }

  /// Takes a finished request off the person's list.
  Future<void> forget(String localId) async {
    final request =
        state.requests.where((r) => r.localId == localId).firstOrNull;
    if (request == null || !request.canRemove) return;
    _remove(localId);
    await _save();
  }
}

final dhikrRequestsProvider =
    NotifierProvider<DhikrRequestsNotifier, RequestsState>(
  DhikrRequestsNotifier.new,
);

sealed class _SendResult {
  const _SendResult();
}

class _Sent extends _SendResult {
  const _Sent(this.request, this.duplicate);

  final DhikrRequest request;
  final bool duplicate;
}

class _Dropped extends _SendResult {
  const _Dropped(this.problem, {this.seconds});

  final RequestProblem problem;
  final int? seconds;
}

class _Kept extends _SendResult {
  const _Kept();
}
