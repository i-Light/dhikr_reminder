import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the phone lets the app run in the background without limits.
///
/// Reminders are alarms the phone is trusted to deliver. To save battery, many
/// phones stop apps they think are idle, and the reminders go with them. The
/// person can exempt the app from that, in a system dialog this opens; the
/// app cannot do it for them.
abstract class BackgroundAccess {
  /// True when the app is exempt from battery optimisation. Also true where
  /// the question does not apply (Windows, tests), so nothing is asked there.
  Future<bool> isUnrestricted();

  /// Opens the system dialog (or, failing that, the settings screen) where the
  /// exemption is granted. Does nothing if the phone has neither.
  Future<void> request();
}

/// [BackgroundAccess] over the Android side's method channel (the one the
/// reminder overlay uses; see `MainActivity.kt`).
class ChannelBackgroundAccess implements BackgroundAccess {
  ChannelBackgroundAccess([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('dhikr_reminder/overlay');

  final MethodChannel _channel;

  @override
  Future<bool> isUnrestricted() async {
    try {
      return await _channel.invokeMethod<bool>('isBackgroundUnrestricted') ??
          true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return true;
    }
  }

  @override
  Future<void> request() async {
    try {
      await _channel.invokeMethod<void>('requestBackgroundUnrestricted');
    } on MissingPluginException {
      // Nothing to open.
    } on PlatformException {
      // The phone has no screen for it. Asking must never be what breaks.
    }
  }
}

/// The access in use. Overridden in tests with a fake.
final backgroundAccessProvider = Provider<BackgroundAccess>(
  (ref) => ChannelBackgroundAccess(),
);

/// Whether the app may run in the background right now. Refreshed whenever the
/// app comes back to the foreground, since it is granted outside the app.
class BackgroundAllowedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(backgroundAccessProvider).isUnrestricted();

  Future<void> refresh() async {
    state =
        AsyncData(await ref.read(backgroundAccessProvider).isUnrestricted());
  }

  Future<void> request() => ref.read(backgroundAccessProvider).request();
}

final backgroundAllowedProvider =
    AsyncNotifierProvider<BackgroundAllowedNotifier, bool>(
  BackgroundAllowedNotifier.new,
);
