import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dhikr_reminder/core/update/update_installer.dart';
import 'package:dhikr_reminder/core/update/update_release.dart';
import 'package:dhikr_reminder/core/window/app_shell.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Where releases are published (`release.yml` attaches the installer to a
/// GitHub Release for every `vX.Y.Z` tag).
final _latestReleaseUri = Uri.https(
  'api.github.com',
  '/repos/i-Light/dhikr_reminder/releases/latest',
);

/// How long after launch the first check waits. Start-up is already busy with
/// the splash and the pre-warm, and a network round trip is not needed for
/// either.
const _firstCheckDelay = Duration(minutes: 2);

/// Between two checks that got an answer. GitHub allows an unauthenticated IP
/// 60 API calls an hour; this is nowhere near that.
const _checkInterval = Duration(hours: 6);

/// Between two checks when the last one failed — most often because the
/// machine had no network yet at log-in — so an update is not put off by a
/// whole [_checkInterval] for one dropped connection.
const _retryInterval = Duration(minutes: 15);

/// How often a downloaded update looks again for the app to be idle.
const _idlePoll = Duration(seconds: 30);

/// What the updater is doing right now.
enum UpdatePhase {
  /// Waiting for the next check.
  idle,
  checking,
  downloading,

  /// The installer is on disk and verified; it is only held back because the
  /// person is looking at the settings or a reminder is on screen.
  waitingForIdle,
  installing,
}

/// Keeps the installed app up to date with no one having to do anything.
///
/// Every [_checkInterval] it asks GitHub for the latest release; if that is
/// newer than the running version it downloads the installer in the background,
/// waits for a moment nobody is looking at the app, then runs it silently and
/// exits. The installer replaces the files and the app starts again on its own
/// (see [UpdateInstaller.applyScript]).
///
/// It only does anything for a copy installed by the Setup wizard
/// ([UpdateInstaller.installDirOf]) — never for `flutter run`, the portable
/// `.zip`, or an all-users install it has no rights to change — and every
/// failure is logged and waited out, never surfaced: an update that cannot
/// happen should cost the person nothing.
class UpdateNotifier extends Notifier<UpdatePhase> {
  Timer? _timer;
  bool _cycleRunning = false;

  @override
  UpdatePhase build() {
    ref.onDispose(() => _timer?.cancel());
    return UpdatePhase.idle;
  }

  /// Starts the schedule. Called once from `main`.
  void start() {
    if (kIsWeb || !Platform.isWindows || _timer != null) return;
    _schedule(_firstCheckDelay);
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(_cycle()));
  }

  Future<void> _cycle() async {
    if (_cycleRunning || !ref.mounted) return;
    _cycleRunning = true;
    var gotAnswer = false;
    try {
      final exe = Platform.resolvedExecutable;
      if (UpdateInstaller.installDirOf(exe) == null) {
        gotAnswer = true; // Nothing to update; nothing to retry either.
        return;
      }

      state = UpdatePhase.checking;
      final release = await _fetchLatest();
      gotAnswer = true;
      if (release == null) return;

      final current = AppVersion.tryParse(
        (await PackageInfo.fromPlatform()).version,
      );
      if (current == null || !release.version.isNewerThan(current)) return;

      final installer = UpdateInstaller();
      state = UpdatePhase.downloading;
      final setup = await installer.download(release);

      state = UpdatePhase.waitingForIdle;
      if (!await _untilIdle()) return;

      state = UpdatePhase.installing;
      _log('Updating ${current.toString()} -> ${release.version}.');
      await installer.launch(setup, appExe: exe);
      await ref.read(appShellProvider.notifier).quit();
    } catch (error, stackTrace) {
      gotAnswer = false;
      _log('Update check failed.', error, stackTrace);
    } finally {
      _cycleRunning = false;
      if (ref.mounted) {
        state = UpdatePhase.idle;
        _schedule(gotAnswer ? _checkInterval : _retryInterval);
      }
    }
  }

  /// The latest published release, or null if there is none this app can use.
  Future<UpdateRelease?> _fetchLatest() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(_latestReleaseUri);
      request.headers
        ..set(HttpHeaders.userAgentHeader, 'dhikr_reminder-updater')
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close().timeout(
            const Duration(seconds: 30),
          );
      // 404 is what a repo with no published release answers: an answer, not
      // a failure.
      if (response.statusCode == HttpStatus.notFound) {
        await response.drain<void>();
        return null;
      }
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException(
          'GitHub answered ${response.statusCode}',
          uri: _latestReleaseUri,
        );
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 30));
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return null;
      return UpdateRelease.fromGithubJson(json);
    } finally {
      client.close(force: true);
    }
  }

  /// Waits until the window is hidden and no reminder is on screen — the one
  /// state in which restarting the app costs the person nothing. Returns false
  /// if the notifier was disposed while it waited.
  Future<bool> _untilIdle() async {
    while (ref.mounted) {
      final quiet = ref.read(appShellProvider).mode == ShellMode.hidden &&
          ref.read(activeDhikrReminderProvider) == null;
      if (quiet) return true;
      await Future<void>.delayed(_idlePoll);
    }
    return false;
  }

  void _log(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'dhikr_reminder.update',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

final updateProvider = NotifierProvider<UpdateNotifier, UpdatePhase>(
  UpdateNotifier.new,
);
