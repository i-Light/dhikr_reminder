import 'package:dhikr_reminder/platform/windows/window_placement.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Windows window tweaks `window_manager` cannot do, implemented by the
/// runner (`windows/runner/flutter_window.cpp`) behind the
/// `dhikr_reminder/window` channel.
///
/// Everything here works in physical pixels on the monitor the cursor is on —
/// the one thing Dart-side logical-pixel arithmetic gets wrong once two
/// monitors differ in scale. Every method tolerates an older runner without the
/// channel: it does nothing, or returns null, and the caller falls back.
abstract class NativeWindow {
  /// Called when a newer copy of the app was started and wants this one gone.
  void onQuitRequested(VoidCallback callback);

  /// Takes the window out of the taskbar and Alt+Tab (or puts it back). Takes
  /// effect the next time the window is shown.
  Future<void> setToolWindow(bool hidden);

  /// Leaves the maximized state: a window hidden and re-shown while maximized
  /// comes back maximized, whatever size it is then given.
  Future<void> restore();

  /// Makes the Flutter view exactly fill the window's client area.
  Future<void> syncContent();

  /// Centres a window of [size] (logical pixels) on the monitor the cursor is
  /// on. Null if the runner cannot; otherwise whether the move changed the
  /// window's DPI (and so its surface needs a moment to lay out again).
  Future<bool?> centreOnCursorMonitor(Size size, {double gap = kWindowGap});

  /// Puts a popup of [size] beside the cursor (see [popupRectNearCursor]).
  /// Same return value as [centreOnCursorMonitor].
  Future<bool?> placeNearCursor(Size size, {double gap = kWindowGap});

  /// What Windows says about whether a reminder is welcome right now, or null
  /// when the runner cannot tell (an older runner, a failure).
  Future<UserState?> userState();
}

/// Whether the person is in the middle of something a reminder should not
/// interrupt, as Windows reports it.
@immutable
class UserState {
  const UserState({required this.notificationState, required this.idleSeconds});

  /// `QUERY_USER_NOTIFICATION_STATE`: 1 not present (locked, screen saver),
  /// 2 a full-screen app, 3 a full-screen Direct3D game, 4 presentation mode,
  /// 5 free, 6 Focus Assist quiet time, 7 a Store app.
  final int notificationState;

  /// Seconds since the last keyboard or mouse input.
  final int idleSeconds;

  /// Away this long and a card would only sit on an empty desk.
  static const awayAfter = Duration(minutes: 15);

  bool get shouldHoldReminder =>
      const {1, 2, 3, 4, 6}.contains(notificationState) ||
      idleSeconds >= awayAfter.inSeconds;
}

/// [NativeWindow] over the runner's method channel.
class ChannelNativeWindow implements NativeWindow {
  ChannelNativeWindow([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('dhikr_reminder/window');

  final MethodChannel _channel;

  @override
  void onQuitRequested(VoidCallback callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'quit') callback();
    });
  }

  Future<void> _call(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // An older runner without the channel: nothing to do without its help.
    }
  }

  Future<bool?> _place(String method, Size size, double gap) async {
    try {
      final dpiChanged = await _channel.invokeMethod<bool>(
        method,
        {'width': size.width, 'height': size.height, 'gap': gap},
      );
      return dpiChanged ?? false;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> setToolWindow(bool hidden) => _call('setToolWindow', hidden);

  @override
  Future<void> restore() => _call('restoreWindow');

  @override
  Future<void> syncContent() => _call('syncContent');

  @override
  Future<bool?> centreOnCursorMonitor(Size size, {double gap = kWindowGap}) =>
      _place('centerOnCursorMonitor', size, gap);

  @override
  Future<bool?> placeNearCursor(Size size, {double gap = kWindowGap}) =>
      _place('placeNearCursor', size, gap);

  @override
  Future<UserState?> userState() async {
    try {
      final map = await _channel.invokeMapMethod<String, int>('userState');
      if (map == null) return null;
      return UserState(
        notificationState: map['notificationState'] ?? 5,
        idleSeconds: map['idleSeconds'] ?? 0,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

/// The native window in use. Overridden in tests with a fake.
final nativeWindowProvider = Provider<NativeWindow>(
  (ref) => ChannelNativeWindow(),
);
