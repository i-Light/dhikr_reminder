import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The reminder card drawn over other apps (Android's "Display over other
/// apps"), implemented natively: see `OverlayService.kt`.
///
/// Dart plans the reminders ahead of time and hands them over; the native side
/// arms alarms and shows the card when each one is due, even with the app
/// closed. Taps made on the card are collected later with [drainTaps].
abstract class ReminderOverlay {
  /// Whether the person has allowed drawing over other apps.
  Future<bool> canDraw();

  /// Opens the system screen where that permission is granted.
  Future<void> requestPermission();

  /// Replaces every scheduled reminder with [plan]. [title], [closeLabel] and
  /// [tip] are the card's (localized) texts.
  Future<void> schedule(
    List<PlannedReminder> plan, {
    required String title,
    required String closeLabel,
    required String tip,
  });

  /// Shows one reminder card right now, outside the plan. Returns false when
  /// drawing over other apps is not allowed.
  Future<bool> showNow({
    required int dhikrId,
    required String text,
    required int amount,
    required String title,
    required String closeLabel,
    required String tip,
  });

  /// Cancels every scheduled reminder.
  Future<void> cancel();

  /// Taps counted on the card since the last call, by dhikr id.
  Future<Map<int, int>> drainTaps();
}

/// [ReminderOverlay] over the Android side's method channel. Anywhere the
/// channel does not exist (other platforms, tests) it reports the overlay as
/// unavailable and does nothing.
class ChannelReminderOverlay implements ReminderOverlay {
  ChannelReminderOverlay([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('dhikr_reminder/overlay');

  final MethodChannel _channel;

  @override
  Future<bool> canDraw() async {
    try {
      return await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } on MissingPluginException {
      // Nothing to open.
    }
  }

  @override
  Future<void> schedule(
    List<PlannedReminder> plan, {
    required String title,
    required String closeLabel,
    required String tip,
  }) async {
    try {
      await _channel.invokeMethod<void>('schedule', {
        'title': title,
        'closeLabel': closeLabel,
        'tip': tip,
        'plan': [for (final reminder in plan) reminder.toOverlayMap()],
      });
    } on MissingPluginException {
      // No overlay on this platform.
    }
  }

  @override
  Future<bool> showNow({
    required int dhikrId,
    required String text,
    required int amount,
    required String title,
    required String closeLabel,
    required String tip,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('showNow', {
            'dhikrId': dhikrId,
            'text': text,
            'amount': amount,
            'title': title,
            'closeLabel': closeLabel,
            'tip': tip,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancel');
    } on MissingPluginException {
      // No overlay on this platform.
    }
  }

  @override
  Future<Map<int, int>> drainTaps() async {
    try {
      final taps =
          await _channel.invokeMapMethod<String, int>('drainTaps') ?? {};
      return {
        for (final entry in taps.entries)
          if (int.tryParse(entry.key) != null)
            int.parse(entry.key): entry.value,
      };
    } on MissingPluginException {
      return const {};
    }
  }
}

/// The overlay in use. Overridden in tests with a fake.
final reminderOverlayProvider = Provider<ReminderOverlay>(
  (ref) => ChannelReminderOverlay(),
);

/// Whether drawing over other apps is allowed right now. Refreshed whenever
/// the app comes back to the foreground, since the permission is granted on a
/// system screen outside the app.
class OverlayAllowedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(reminderOverlayProvider).canDraw();

  Future<void> refresh() async {
    state = AsyncData(await ref.read(reminderOverlayProvider).canDraw());
  }

  Future<void> request() =>
      ref.read(reminderOverlayProvider).requestPermission();
}

final overlayAllowedProvider =
    AsyncNotifierProvider<OverlayAllowedNotifier, bool>(
  OverlayAllowedNotifier.new,
);
