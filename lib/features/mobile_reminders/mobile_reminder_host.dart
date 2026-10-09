import 'dart:async';
import 'dart:math';

import 'package:dhikr_reminder/core/locale/locale_controller.dart';
import 'package:dhikr_reminder/features/library/application/transliteration_controller.dart';
import 'package:dhikr_reminder/features/mobile_reminders/background_access.dart';
import 'package:dhikr_reminder/features/mobile_reminders/notification_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The notification system in use. Overridden in tests with a fake.
final reminderNotificationsProvider = Provider<ReminderNotifications>(
  (ref) => LocalReminderNotifications(),
);

/// Keeps what the phone has scheduled in step with the settings: whenever the
/// interval, the entries, the chance option or the language change — and
/// whenever the app comes back to the foreground, which tops the plan up — the
/// old schedule is thrown away and a fresh one handed to the OS.
///
/// With "display over other apps" allowed the reminders go to the overlay (the
/// floating card); without it they are ordinary notifications. Only one of the
/// two is ever scheduled, so a reminder is never shown twice.
class MobileReminderSyncer {
  MobileReminderSyncer(
    this._notifications,
    this._overlay, {
    Random? random,
  }) : _random = random ?? Random();

  final ReminderNotifications _notifications;
  final ReminderOverlay _overlay;
  final Random _random;

  Future<void> sync({
    required DhikrSettings settings,
    required Locale locale,
    bool showTransliteration = false,
    DateTime? now,
  }) async {
    if (!settings.isLoaded) return;
    final plan = planReminders(
      now: now ?? DateTime.now(),
      interval: Duration(minutes: settings.intervalMinutes),
      entries: settings.entries,
      useChance: settings.useChance,
      random: _random,
      showTransliteration: showTransliteration,
      showArabic: settings.overlayShowArabic,
    );
    final l10n = lookupAppLocalizations(locale);
    if (await _overlay.canDraw()) {
      await _notifications.replaceAll(const [], title: l10n.dhikrReminderTitle);
      await _overlay.schedule(
        plan,
        interval: Duration(minutes: settings.intervalMinutes),
        title: l10n.dhikrReminderTitle,
        closeLabel: l10n.commonClose,
        tip: l10n.dhikrReminderTouchEverywhereTip,
        dayLabel: l10n.statToday,
      );
    } else {
      await _overlay.cancel();
      await _notifications.replaceAll(plan, title: l10n.dhikrReminderTitle);
    }
  }
}

/// A dhikr id from a tapped notification, waiting for the saved entries to
/// load (a cold start from a notification gets the tap before the settings).
final pendingOpenDhikrProvider = NotifierProvider<_PendingOpen, int?>(
  _PendingOpen.new,
);

class _PendingOpen extends Notifier<int?> {
  @override
  int? build() => null;

  // Riverpod notifiers expose state through a setter-less getter; this is the
  // one write path.
  void set(int? id) => state = id;
}

/// On a phone, owns the notification plumbing; on any other platform it is a
/// transparent pass-through. Mounted once, in `MaterialApp.builder`.
class MobileReminderHost extends ConsumerStatefulWidget {
  const MobileReminderHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MobileReminderHost> createState() => _MobileReminderHostState();
}

class _MobileReminderHostState extends ConsumerState<MobileReminderHost>
    with WidgetsBindingObserver {
  Timer? _debounce;

  /// Read once, up front: the platform cannot change while the app runs, and
  /// `dispose` may not touch `ref`.
  late final bool _active = ref.read(appPlatformProvider).usesNotifications;
  late final MobileReminderSyncer _syncer = MobileReminderSyncer(
    ref.read(reminderNotificationsProvider),
    ref.read(reminderOverlayProvider),
  );

  @override
  void initState() {
    super.initState();
    if (!_active) return;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  Future<void> _start() async {
    final notifications = ref.read(reminderNotificationsProvider);
    await notifications.init(
      onOpen: (id) => ref.read(pendingOpenDhikrProvider.notifier).set(id),
    );
    await notifications.requestPermission();
    await _collectOverlayTaps();
    _scheduleSync();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_active) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_collectOverlayTaps());
      // Both permissions are granted on a system screen outside the app.
      unawaited(ref.read(overlayAllowedProvider.notifier).refresh());
      unawaited(ref.read(backgroundAllowedProvider.notifier).refresh());
      _scheduleSync();
    }
  }

  /// Hands the taps made on the overlay while the app was closed to the stats.
  Future<void> _collectOverlayTaps() async {
    final taps = await ref.read(reminderOverlayProvider).drainTaps();
    if (!mounted) return;
    final stats = ref.read(dhikrStatsProvider.notifier);
    taps.forEach(stats.recordTaps);
    _pushToday();
  }

  /// Tells the floating card how far each dhikr has got today, so one with a
  /// daily goal can show it even with the app closed. Counts left over from
  /// yesterday are not today's, so they are sent as nothing.
  void _pushToday() {
    final stats = ref.read(dhikrStatsProvider);
    final today = dhikrDayKey(ref.read(dhikrStatsClockProvider)());
    unawaited(ref.read(reminderOverlayProvider).setToday(
          today,
          stats.day == today ? stats.byDhikr : const <int, int>{},
        ));
  }

  void _scheduleSync() {
    _debounce?.cancel();
    // Settings change per keystroke; wait for the typing to stop.
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      unawaited(_syncer.sync(
        settings: ref.read(dhikrSettingsProvider),
        locale: ref.read(localeProvider),
        showTransliteration: ref.read(showTransliterationProvider),
      ));
    });
  }

  void _openPending() {
    final id = ref.read(pendingOpenDhikrProvider);
    final settings = ref.read(dhikrSettingsProvider);
    if (id == null || !settings.isLoaded) return;
    ref.read(pendingOpenDhikrProvider.notifier).set(null);
    final entry = settings.entries.where((e) => e.id == id).firstOrNull;
    if (entry != null) {
      ref.read(activeDhikrReminderProvider.notifier).show(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return widget.child;
    ref.listen(dhikrSettingsProvider, (previous, next) {
      final changed = previous == null ||
          previous.isLoaded != next.isLoaded ||
          previous.intervalMinutes != next.intervalMinutes ||
          previous.useChance != next.useChance ||
          previous.overlayShowArabic != next.overlayShowArabic ||
          !listEquals(previous.entries, next.entries);
      if (changed) _scheduleSync();
      _openPending();
    });
    ref.listen(dhikrStatsProvider, (_, __) => _pushToday());
    ref.listen(localeProvider, (_, __) => _scheduleSync());
    ref.listen(showTransliterationProvider, (_, __) => _scheduleSync());
    ref.listen(pendingOpenDhikrProvider, (_, __) => _openPending());
    return widget.child;
  }
}
