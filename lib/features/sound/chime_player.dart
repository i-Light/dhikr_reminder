import 'package:dhikr_reminder/features/sound/chime.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plays the finishing chime. An interface so tests need no speaker.
abstract class ChimePlayer {
  /// Hands the phone the chime and whether to play it on its own when a card
  /// is finished with the app closed. Does nothing on Windows.
  Future<void> prepare({required bool enabled});

  /// Plays it once, now.
  Future<void> play();
}

/// Over the platform channels: the Windows runner (`dhikr_reminder/window`,
/// `playChime`) and the Android side (`dhikr_reminder/overlay`, `setChime` and
/// `playChime`). A phone or PC without the channel plays nothing, quietly.
class ChannelChimePlayer implements ChimePlayer {
  ChannelChimePlayer(this._platform);

  final AppPlatform _platform;

  Uint8List? _wav;
  Uint8List get _chime => _wav ??= buildChimeWav();

  static const _windows = MethodChannel('dhikr_reminder/window');
  static const _android = MethodChannel('dhikr_reminder/overlay');

  @override
  Future<void> prepare({required bool enabled}) async {
    if (!_platform.usesNotifications) return;
    try {
      await _android.invokeMethod<void>('setChime', {
        'enabled': enabled,
        // The sound is only built when it is going to be used.
        if (enabled) 'wav': _chime,
      });
    } on MissingPluginException {
      // No native side: nothing to prepare.
    } on PlatformException {
      // A chime that cannot be set up must never be what breaks.
    }
  }

  @override
  Future<void> play() async {
    try {
      if (_platform.hasWindowShell) {
        await _windows.invokeMethod<void>('playChime', _chime);
      } else if (_platform.usesNotifications) {
        await _android.invokeMethod<void>('playChime');
      }
    } on MissingPluginException {
      // Nothing to play with.
    } on PlatformException {
      // Silence is a fine failure.
    }
  }
}

/// The chime in use. Overridden in tests with a fake.
final chimePlayerProvider = Provider<ChimePlayer>(
  (ref) => ChannelChimePlayer(ref.watch(appPlatformProvider)),
);
