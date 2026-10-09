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

  /// Replaces every scheduled reminder with [plan]. [interval] is the gap
  /// between two reminders: the native side uses it to keep the schedule going
  /// on its own once [plan] runs out. [title], [closeLabel], [tip] and
  /// [dayLabel] (the words under the day counter) are the card's (localized)
  /// texts.
  Future<void> schedule(
    List<PlannedReminder> plan, {
    required Duration interval,
    required String title,
    required String closeLabel,
    required String tip,
    required String dayLabel,
  });

  /// Shows one reminder card right now, outside the plan. Returns false when
  /// drawing over other apps is not allowed.
  Future<bool> showNow({
    required int dhikrId,
    required String text,
    required int amount,
    required int goal,
    required String title,
    required String closeLabel,
    required String tip,
    required String dayLabel,
    String translit = '',
  });

  /// Tells the card whether to leave the Arabic out (showing the transliteration
  /// alone). The card reads it when it appears, so it holds for the reminders
  /// that come with the app closed too. The card has a button for it as well.
  Future<void> setArabicHidden(bool hidden);

  /// The new value if the person pressed that button on the card since the last
  /// call, or null if they did not. The app is not running when they do, so it
  /// asks when it comes back.
  Future<bool?> takeArabicHidden();

  /// Cancels every scheduled reminder.
  Future<void> cancel();

  /// Taps counted on the card since the last call, by dhikr id.
  Future<Map<int, int>> drainTaps();

  /// Tells the card how far each dhikr has got today, so a dhikr with a daily
  /// goal can show it. [day] is the day key the counts belong to
  /// (`dhikrDayKey`); [counts] is by dhikr id. The card adds the taps it counts
  /// itself while the app is closed.
  Future<void> setToday(String day, Map<int, int> counts);
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
    } on PlatformException {
      // The phone has no screen for it. Asking must never be what breaks.
    }
  }

  @override
  Future<void> schedule(
    List<PlannedReminder> plan, {
    required Duration interval,
    required String title,
    required String closeLabel,
    required String tip,
    required String dayLabel,
  }) async {
    try {
      await _channel.invokeMethod<void>('schedule', {
        'intervalMillis': interval.inMilliseconds,
        'title': title,
        'closeLabel': closeLabel,
        'tip': tip,
        'dayLabel': dayLabel,
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
    required int goal,
    required String title,
    required String closeLabel,
    required String tip,
    required String dayLabel,
    String translit = '',
  }) async {
    try {
      return await _channel.invokeMethod<bool>('showNow', {
            'dhikrId': dhikrId,
            'text': text,
            'amount': amount,
            'goal': goal,
            'translit': translit,
            'title': title,
            'closeLabel': closeLabel,
            'tip': tip,
            'dayLabel': dayLabel,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> setArabicHidden(bool hidden) async {
    try {
      await _channel.invokeMethod<void>('setArabicHidden', {'hidden': hidden});
    } on MissingPluginException {
      // No overlay on this platform.
    }
  }

  @override
  Future<bool?> takeArabicHidden() async {
    try {
      return await _channel.invokeMethod<bool>('takeArabicHidden');
    } on MissingPluginException {
      return null;
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
  Future<void> setToday(String day, Map<int, int> counts) async {
    try {
      await _channel.invokeMethod<void>('setToday', {
        'day': day,
        'counts': {
          for (final entry in counts.entries) '${entry.key}': entry.value,
        },
      });
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
