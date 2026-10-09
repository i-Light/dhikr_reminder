import 'package:dhikr_reminder/core/quiet_hours.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_health.dart';
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
  /// texts. [pausedUntil] is the end of a pause, if one is on: the native side
  /// holds back anything due before it, and starts the topped-up plan after it.
  /// [quiet] is the daily window with no reminders: the native side keeps to it
  /// too, since it tops the plan up with the app closed.
  ///
  /// This is the only way reminders reach the phone. Where drawing over other
  /// apps is not allowed, the native side posts the same dhikr as an ordinary
  /// notification, so the plan is handed over either way.
  Future<void> schedule(
    List<PlannedReminder> plan, {
    required Duration interval,
    required String title,
    required String closeLabel,
    required String tip,
    required String dayLabel,
    DateTime? pausedUntil,
    QuietHours quiet = const QuietHours(),
  });

  /// Asks for the permission to post notifications (Android 13 and later; the
  /// system asks once). True if notifications are allowed afterwards.
  Future<bool> requestNotificationPermission();

  /// The dhikr id of a notification the person tapped, if one is waiting (it is
  /// forgotten once taken), else null. The app may have been started by it.
  Future<int?> takeOpenDhikr();

  /// When the next reminder will arrive, as the native alarms really hold it,
  /// or null when none is armed.
  Future<DateTime?> nextReminderAt();

  /// Whether reminders are getting through, and what the phone allows. Null
  /// where there is nothing to ask.
  Future<ReminderHealth?> health();

  /// Opens the phone maker's "start in the background" screen (or this app's
  /// settings page where there is none). False when nothing could be opened.
  Future<bool> openAppLaunchSettings();

  /// Opens this app's notification settings.
  Future<bool> openNotificationSettings();

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

  /// Hands over the words the widget, the quick-settings tiles, the launcher
  /// shortcuts and the notification buttons show, in the app's language. The
  /// native side keeps them and only redraws when they change.
  Future<void> setSurfaceLabels(Map<String, String> labels) async {}

  /// A pause set from a tile or shortcut since the last call, as milliseconds
  /// since the epoch (0 means the pause was lifted), or null if there was none.
  Future<int?> takePauseChange() async => null;

  /// The page a launcher shortcut asked for ("library"), or null. Forgotten
  /// once taken.
  Future<String?> takeOpenTab() async => null;

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
    DateTime? pausedUntil,
    QuietHours quiet = const QuietHours(),
  }) async {
    try {
      await _channel.invokeMethod<void>('schedule', {
        'intervalMillis': interval.inMilliseconds,
        'pausedUntil': pausedUntil?.millisecondsSinceEpoch ?? 0,
        'quietStart': quiet.enabled ? quiet.startMinutes : -1,
        'quietEnd': quiet.enabled ? quiet.endMinutes : -1,
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
  Future<ReminderHealth?> health() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>('health');
      return map == null ? null : ReminderHealth.fromMap(map);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<bool> openAppLaunchSettings() => _open('openAppLaunchSettings');

  @override
  Future<bool> openNotificationSettings() => _open('openNotificationSettings');

  Future<bool> _open(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try {
      return await _channel.invokeMethod<bool>(
            'requestNotificationPermission',
          ) ??
          true;
    } on MissingPluginException {
      return true;
    }
  }

  @override
  Future<int?> takeOpenDhikr() async {
    try {
      return await _channel.invokeMethod<int>('takeOpenDhikr');
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<DateTime?> nextReminderAt() async {
    try {
      final millis = await _channel.invokeMethod<int>('nextReminderAt');
      if (millis == null || millis <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } on MissingPluginException {
      return null;
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
  Future<void> setSurfaceLabels(Map<String, String> labels) async {
    try {
      await _channel.invokeMethod<void>('setSurfaceLabels', labels);
    } on MissingPluginException {
      // No surfaces on this platform.
    }
  }

  @override
  Future<int?> takePauseChange() async {
    try {
      return await _channel.invokeMethod<int>('takePauseChange');
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<String?> takeOpenTab() async {
    try {
      return await _channel.invokeMethod<String>('takeOpenTab');
    } on MissingPluginException {
      return null;
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
