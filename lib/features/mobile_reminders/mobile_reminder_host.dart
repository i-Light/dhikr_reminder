import 'dart:async';
import 'dart:math';

import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/core/locale/locale_controller.dart';
import 'package:dhikr_reminder/core/navigation/shell_tab.dart';
import 'package:dhikr_reminder/core/quiet_hours.dart';
import 'package:dhikr_reminder/features/library/application/transliteration_controller.dart';
import 'package:dhikr_reminder/features/mobile_reminders/background_access.dart';
import 'package:dhikr_reminder/features/mobile_reminders/next_reminder.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_health.dart';
import 'package:dhikr_reminder/features/mobile_reminders/reminder_planner.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/sound/chime_player.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps what the phone has scheduled in step with the settings: whenever the
/// interval, the entries, the chance option, a pause or the language change,
/// and whenever the app comes back to the foreground (which tops the plan up),
/// the old schedule is thrown away and a fresh one handed to the native alarms.
///
/// The plan always goes to the same place. With "display over other apps"
/// allowed the native side shows the floating card when a reminder is due;
/// without it, the same alarm posts the dhikr as an ordinary notification. So
/// there is one schedule, and a reminder is never shown twice.
class MobileReminderSyncer {
  MobileReminderSyncer(this._overlay, {Random? random})
      : _random = random ?? Random();

  final ReminderOverlay _overlay;
  final Random _random;

  Future<void> sync({
    required DhikrSettings settings,
    required Locale locale,
    bool showTransliteration = false,
    DateTime? pausedUntil,
    DateTime? now,
  }) async {
    if (!settings.isLoaded) return;
    final at = now ?? DateTime.now();
    // A pause that has already ended is no pause.
    final pause =
        pausedUntil != null && pausedUntil.isAfter(at) ? pausedUntil : null;
    final plan = planReminders(
      now: at,
      interval: Duration(minutes: settings.intervalMinutes),
      entries: settings.entries,
      useChance: settings.useChance,
      random: _random,
      pausedUntil: pause,
      quiet: Features.politeReminders ? settings.quiet : const QuietHours(),
      showTransliteration: showTransliteration,
    );
    final l10n = lookupAppLocalizations(locale);
    await _overlay.setArabicHidden(!settings.overlayShowArabic);
    await _overlay.schedule(
      plan,
      interval: Duration(minutes: settings.intervalMinutes),
      title: l10n.dhikrReminderTitle,
      closeLabel: l10n.commonClose,
      tip: l10n.dhikrReminderTouchEverywhereTip,
      dayLabel: l10n.statToday,
      pausedUntil: pause,
      quiet: Features.politeReminders ? settings.quiet : const QuietHours(),
    );
    if (Features.surfaces) {
      await _overlay.setSurfaceLabels({
        'countOne': l10n.surfaceCountOne,
        'pause': l10n.trayPause,
        'resume': l10n.trayResume,
        'library': l10n.navLibrary,
        'done': l10n.surfaceDone,
        'later': l10n.surfaceLater,
        'openApp': l10n.trayOpenApp,
        'today': l10n.statToday,
        // The phone fills in the time, so the template is sent.
        'pausedUntil': l10n.trayPausedUntil('{time}'),
      });
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
    await ref.read(reminderOverlayProvider).requestNotificationPermission();
    await _collectOpenRequest();
    await _collectSurfaceChanges();
    await _collectOverlayTaps();
    _scheduleSync();
  }

  /// A notification the person tapped (also the one that started the app)
  /// names the dhikr to open; it waits in the provider for the saved entries.
  Future<void> _collectOpenRequest() async {
    final id = await ref.read(reminderOverlayProvider).takeOpenDhikr();
    if (id == null || !mounted) return;
    ref.read(pendingOpenDhikrProvider.notifier).set(id);
  }

  /// Takes up what was done from outside the app: a pause started or lifted
  /// from a quick-settings tile or a launcher shortcut, and a shortcut that
  /// asks for the library. The pause comes first, so the sync that follows
  /// sends the right one back instead of undoing it.
  Future<void> _collectSurfaceChanges() async {
    if (!Features.surfaces) return;
    final overlay = ref.read(reminderOverlayProvider);
    final pause = await overlay.takePauseChange();
    if (!mounted) return;
    if (pause != null) {
      final notifier = ref.read(reminderPauseProvider.notifier);
      final left =
          DateTime.fromMillisecondsSinceEpoch(pause).difference(DateTime.now());
      if (pause > 0 && !left.isNegative && left > Duration.zero) {
        notifier.pauseFor(left);
      } else {
        notifier.resume();
      }
    }
    final tab = await overlay.takeOpenTab();
    if (!mounted) return;
    if (tab == 'library') {
      ref.read(shellTabProvider.notifier).show(ShellTab.library);
    }
  }

  /// Takes up a change the person made with the Arabic button on the floating
  /// card while the app was closed. Waits for the saved settings, which the
  /// change would otherwise be overwritten by.
  Future<void> _collectArabicChange() async {
    if (!ref.read(dhikrSettingsProvider).isLoaded) return;
    final hidden = await ref.read(reminderOverlayProvider).takeArabicHidden();
    if (hidden == null || !mounted) return;
    unawaited(
      ref.read(dhikrSettingsProvider.notifier).updateOverlayShowArabic(!hidden),
    );
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
      unawaited(_collectOpenRequest());
      unawaited(_collectSurfaceChanges());
      unawaited(_collectOverlayTaps());
      // Both permissions are granted on a system screen outside the app.
      unawaited(ref.read(overlayAllowedProvider.notifier).refresh());
      unawaited(ref.read(backgroundAllowedProvider.notifier).refresh());
      unawaited(ref.read(reminderHealthProvider.notifier).refresh());
      _scheduleSync();
    }
  }

  /// Hands the taps made on the overlay while the app was closed to the stats.
  Future<void> _collectOverlayTaps() async {
    unawaited(_collectArabicChange());
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
    unawaited(
      ref.read(reminderOverlayProvider).setToday(
            today,
            stats.day == today ? stats.byDhikr : const <int, int>{},
          ),
    );
  }

  void _scheduleSync() {
    _debounce?.cancel();
    // Settings change per keystroke; wait for the typing to stop.
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      unawaited(_syncAndRefresh());
    });
  }

  Future<void> _syncAndRefresh() async {
    // A pause made on a tile while the app was open has to be taken up before
    // the plan is sent, or the plan would lift it.
    await _collectSurfaceChanges();
    if (!mounted) return;
    await _syncer.sync(
      settings: ref.read(dhikrSettingsProvider),
      locale: ref.read(localeProvider),
      showTransliteration: ref.read(showTransliterationProvider),
      pausedUntil: ref.read(reminderPauseProvider),
    );
    if (mounted) unawaited(ref.read(nextReminderProvider.notifier).refresh());
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
          previous.quiet != next.quiet ||
          !listEquals(previous.entries, next.entries);
      if (changed) _scheduleSync();
      if (previous?.isLoaded != true && next.isLoaded) {
        unawaited(_collectArabicChange());
      }
      // The phone plays the chime itself when a card is finished with the app
      // closed, so it is told whether to, and given the sound, when that changes.
      if (Features.sound &&
          next.isLoaded &&
          (previous == null || previous.soundOn != next.soundOn)) {
        unawaited(
          ref.read(chimePlayerProvider).prepare(enabled: next.soundOn),
        );
      }
      // The card reads this when it appears, so it goes over at once instead
      // of waiting for the plan to be rebuilt.
      if (previous != null &&
          previous.overlayShowArabic != next.overlayShowArabic) {
        unawaited(
          ref
              .read(reminderOverlayProvider)
              .setArabicHidden(!next.overlayShowArabic),
        );
      }
      _openPending();
    });
    ref.listen(dhikrStatsProvider, (_, __) => _pushToday());
    ref.listen(localeProvider, (_, __) => _scheduleSync());
    ref.listen(reminderPauseProvider, (_, __) => _scheduleSync());
    ref.listen(showTransliterationProvider, (_, __) => _scheduleSync());
    ref.listen(pendingOpenDhikrProvider, (_, __) => _openPending());
    return widget.child;
  }
}
