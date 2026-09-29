import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dhikr_reminder/core/update/update_installer.dart';
import 'package:dhikr_reminder/core/update/update_release.dart';
import 'package:dhikr_reminder/core/update/update_source.dart';
import 'package:dhikr_reminder/core/window/app_shell.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _autoUpdatePrefsKey = 'dhikr_reminder.update.auto';

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

/// Everything the settings card shows about updates.
@immutable
class UpdateState {
  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.currentVersion,
    this.latestVersion,
    this.lastChecked,
    this.failed = false,
    this.canSelfUpdate = false,
    this.autoUpdate = true,
  });

  final UpdatePhase phase;

  /// The running version; null until it has been read.
  final AppVersion? currentVersion;

  /// The newest published version the last successful check saw — which may
  /// be the running one, or older.
  final AppVersion? latestVersion;

  /// When a check last got an answer from GitHub.
  final DateTime? lastChecked;

  /// True when the most recent attempt (a check or a download) failed.
  final bool failed;

  /// Whether this copy is one the updater can replace: installed by the Setup
  /// wizard, in a folder it can write to (see
  /// [UpdateInstaller.installDirOf]).
  final bool canSelfUpdate;

  /// Whether new versions are downloaded and installed without being asked.
  final bool autoUpdate;

  /// A newer version than the running one has been published.
  bool get updateAvailable {
    final current = currentVersion;
    final latest = latestVersion;
    return current != null && latest != null && latest.isNewerThan(current);
  }

  /// The updater is in the middle of something and should not be started on
  /// another.
  bool get busy => phase != UpdatePhase.idle;

  UpdateState copyWith({
    UpdatePhase? phase,
    AppVersion? currentVersion,
    AppVersion? latestVersion,
    DateTime? lastChecked,
    bool? failed,
    bool? canSelfUpdate,
    bool? autoUpdate,
  }) {
    return UpdateState(
      phase: phase ?? this.phase,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      lastChecked: lastChecked ?? this.lastChecked,
      failed: failed ?? this.failed,
      canSelfUpdate: canSelfUpdate ?? this.canSelfUpdate,
      autoUpdate: autoUpdate ?? this.autoUpdate,
    );
  }
}

// The seams a test replaces. Each defaults to the real thing.

/// Asks GitHub for the latest release.
final updateSourceProvider = Provider<Future<UpdateRelease?> Function()>(
  (ref) => fetchLatestRelease,
);

final updateInstallerProvider = Provider<UpdateInstaller>(
  (ref) => UpdateInstaller(),
);

/// The folder this copy was installed into, or null if it cannot update
/// itself.
final updateInstallDirProvider = Provider<Directory?>((ref) {
  if (kIsWeb || !Platform.isWindows) return null;
  return UpdateInstaller.installDirOf(Platform.resolvedExecutable);
});

/// The running version.
final updateCurrentVersionProvider = Provider<Future<AppVersion?> Function()>(
  (ref) => () async =>
      AppVersion.tryParse((await PackageInfo.fromPlatform()).version),
);

/// How the app ends once the installer has been started.
final updateQuitProvider = Provider<Future<void> Function()>(
  (ref) => () => ref.read(appShellProvider.notifier).quit(),
);

/// Keeps the installed app up to date with no one having to do anything.
///
/// Every [_checkInterval] it asks GitHub for the latest release; if that is
/// newer than the running version it downloads the installer in the
/// background, waits for a moment nobody is looking at the app, then runs it
/// silently and exits. The installer replaces the files and the app starts
/// again on its own (see [UpdateInstaller.applyScript]).
///
/// It only *installs* for a copy installed by the Setup wizard
/// ([UpdateState.canSelfUpdate]) — never for `flutter run`, or an all-users
/// install it has no rights to change; those still get told a new version
/// exists. Failures are logged and waited out, and the settings card shows
/// that the last attempt failed, but nothing else interrupts the person.
class UpdateNotifier extends Notifier<UpdateState> {
  Timer? _timer;
  bool _cycleRunning = false;

  /// The person asked for the update to be installed now: the idle wait is
  /// skipped, and so is the "automatic updates are off" stop.
  bool _installRequested = false;
  Completer<void>? _wake;

  UpdateRelease? _release;
  File? _downloaded;

  @override
  UpdateState build() {
    ref.onDispose(() => _timer?.cancel());
    unawaited(_loadPersisted());
    return UpdateState(
        canSelfUpdate: ref.read(updateInstallDirProvider) != null);
  }

  Future<void> _loadPersisted() async {
    try {
      final version = await ref.read(updateCurrentVersionProvider)();
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      state = state.copyWith(
        currentVersion: version,
        autoUpdate: prefs.getBool(_autoUpdatePrefsKey),
      );
    } catch (error, stackTrace) {
      _log('Could not read the update settings.', error, stackTrace);
    }
  }

  /// Starts the schedule. Called once from `main`.
  void start() {
    if (kIsWeb || !Platform.isWindows || _timer != null) return;
    _schedule(_firstCheckDelay);
  }

  /// Checks now, from the settings card's button. If a newer version turns up
  /// and automatic updates are on, it carries on and installs it like a
  /// scheduled check would.
  Future<void> checkNow() => _cycle();

  /// Installs the newer version now instead of when the app is next idle —
  /// the settings card's "update" button. Checks first if nothing is known
  /// yet, and downloads first if that has not happened.
  Future<void> installNow() {
    _installRequested = true;
    final wake = _wake;
    if (wake != null && !wake.isCompleted) wake.complete();
    return _cycle();
  }

  Future<void> setAutoUpdate(bool value) async {
    state = state.copyWith(autoUpdate: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoUpdatePrefsKey, value);
    } catch (error, stackTrace) {
      _log('Could not save the automatic-updates setting.', error, stackTrace);
    }
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
      state = state.copyWith(phase: UpdatePhase.checking, failed: false);
      final release = await ref.read(updateSourceProvider)();
      gotAnswer = true;
      state = state.copyWith(
        lastChecked: DateTime.now(),
        latestVersion: release?.version,
      );
      if (release == null) return;

      final current = state.currentVersion ??
          await ref.read(updateCurrentVersionProvider)();
      if (current == null) return;
      state = state.copyWith(currentVersion: current);
      if (!release.version.isNewerThan(current)) return;

      // Told about, but not touched: a copy that cannot replace itself, or a
      // person who turned automatic updates off.
      if (!state.canSelfUpdate) return;
      if (!state.autoUpdate && !_installRequested) return;

      await _install(release, current);
    } catch (error, stackTrace) {
      gotAnswer = false;
      if (ref.mounted) state = state.copyWith(failed: true);
      _log('Update check failed.', error, stackTrace);
    } finally {
      _cycleRunning = false;
      _installRequested = false;
      if (ref.mounted) {
        state = state.copyWith(phase: UpdatePhase.idle);
        _schedule(gotAnswer ? _checkInterval : _retryInterval);
      }
    }
  }

  Future<void> _install(UpdateRelease release, AppVersion current) async {
    final installer = ref.read(updateInstallerProvider);

    var setup = _downloaded;
    if (setup == null ||
        _release?.version != release.version ||
        !setup.existsSync()) {
      state = state.copyWith(phase: UpdatePhase.downloading);
      setup = await installer.download(release);
      _release = release;
      _downloaded = setup;
    }

    state = state.copyWith(phase: UpdatePhase.waitingForIdle);
    if (!await _untilIdle()) return;

    state = state.copyWith(phase: UpdatePhase.installing);
    _log('Updating $current -> ${release.version}.');
    await installer.launch(setup, appExe: Platform.resolvedExecutable);
    await ref.read(updateQuitProvider)();
  }

  /// Waits until the window is hidden and no reminder is on screen — the one
  /// state in which restarting the app costs the person nothing — or until
  /// they ask for the update. Returns false if the notifier was disposed while
  /// it waited.
  Future<bool> _untilIdle() async {
    while (ref.mounted) {
      final quiet = ref.read(appShellProvider).mode == ShellMode.hidden &&
          ref.read(activeDhikrReminderProvider) == null;
      if (quiet || _installRequested) return true;
      final wake = _wake = Completer<void>();
      await Future.any([Future<void>.delayed(_idlePoll), wake.future]);
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

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);
