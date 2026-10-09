import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/core/locale/locale_controller.dart';
import 'package:dhikr_reminder/core/window/svg_icon.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/stats/dhikr_stats.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:dhikr_reminder/platform/windows/native_window.dart';
import 'package:dhikr_reminder/platform/windows/window_placement.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// What the one native window is currently being used as.
enum ShellMode {
  /// Nothing on screen. The app's normal state: it lives in the tray.
  hidden,

  /// A quick floating splash, shown once when the app starts.
  splash,

  /// The reminder popup, parked far off-screen and run once through its whole
  /// life (entrance, taps, completion, exit) so the fonts, artwork and glow
  /// sprites it needs are already in memory by the time a real reminder shows.
  prewarm,

  /// The floating dhikr popup.
  reminder,

  /// The settings screen. Only ever reached from the tray icon.
  settings,

  /// A small frameless popup shown at the tray icon, rendering
  /// `TrayMenuPanel`.
  trayMenu,
}

/// The window's mode plus whether it has actually arrived.
///
/// A window is re-shaped out of sight (see [AppShellNotifier]) and only then
/// moved on screen. [revealed] is false for the first part of that and true
/// from the moment the window is where the person will see it, so a surface
/// can hold its entrance animation until there is someone to see it.
@immutable
class ShellState {
  const ShellState(this.mode, {this.revealed = false});

  final ShellMode mode;
  final bool revealed;

  @override
  bool operator ==(Object other) =>
      other is ShellState && other.mode == mode && other.revealed == revealed;

  @override
  int get hashCode => Object.hash(mode, revealed);
}

/// Size of the tray popup, in logical pixels, see `TrayMenuPanel`. Four rows of
/// 36, the divider, and the padding around them; one more row while the tray
/// has "Count one" ([Features.trayCount]). It was 212 while the menu also had
/// the sound toggle (hidden for now).
const kTrayMenuSize = Size(208, Features.trayCount ? 212 : 176);

/// Size of the splash window; the splash card fills it.
const kSplashSize = Size(420, 270);

/// Size of the reminder popup window: the card plus room for its glow (see
/// [kDhikrReminderGlowMargin]). Shrunk to fit a display smaller than this.
const kReminderWindowSize = Size(1120, 700);

/// Size the settings window opens at the first time.
const kSettingsWindowSize = Size(960, 720);

/// Anything smaller than this is not a real settings window size (it is what a
/// minimized or mid-change window reports), so it is never remembered.
const _minSettingsSize = Size(400, 300);

/// How long the splash stays up. `SplashSurface` runs its fade in and out
/// inside this.
const kSplashDuration = Duration(milliseconds: 1800);

const _trayTooltip = 'ذِكر';

/// How long a leaving reminder is given to play its exit before the window
/// goes away under it (`DhikrTimers.cardEntrance`, plus a little).
const _reminderExitGrace = Duration(milliseconds: 300);

/// Somewhere no monitor is, for changing the window's shape out of sight.
const _offscreen = Offset(-20000, -20000);

/// How the window should look for one [ShellMode].
class _WindowSpec {
  const _WindowSpec({
    required this.rect,
    required this.frameless,
    required this.transparent,
    required this.alwaysOnTop,
    required this.hiddenFromTaskbar,
    required this.takeFocus,
    this.centredOnScreen = false,
    this.nearCursor = false,
  });

  /// Where the window ends up on screen, in logical pixels.
  final Rect rect;

  /// No title bar or border: the surface draws everything itself.
  final bool frameless;

  /// The desktop shows through wherever the surface paints nothing.
  final bool transparent;

  final bool alwaysOnTop;

  /// Out of the taskbar and Alt+Tab.
  final bool hiddenFromTaskbar;

  /// Whether showing it should pull keyboard focus. The splash and the
  /// reminder must not: the person is probably typing into something else.
  final bool takeFocus;

  /// Placed at the exact centre of the monitor (see
  /// [AppShellNotifier._centreOnScreen]) instead of at [rect]'s corner.
  final bool centredOnScreen;

  /// Placed beside the cursor, which is on the tray icon (see
  /// [AppShellNotifier._placeNearCursor]).
  final bool nearCursor;
}

/// Owns the app's relationship with its own window and the system tray.
///
/// The app has no window of its own to speak of: it lives in the tray, and its
/// one native window is only ever *shown* as one of a few things (see
/// [ShellMode]):
///
///  * on start-up, a quick floating splash, then an off-screen pre-warm run of
///    the reminder popup;
///  * when a reminder comes due, the reminder popup — a frameless, transparent,
///    always-on-top window holding just the card, which is why it reads as a
///    floating popup and not as part of an app;
///  * from the tray icon's left click, the settings screen — the only way to
///    it;
///  * from the tray icon's right click, a themed menu (rendered by Flutter,
///    not a native one).
///
/// One window, several modes, rather than several native windows: the Flutter
/// engine, the providers and the reminder timer all live in this one, and a
/// second engine would have had to be kept in step with them. The price is that
/// a reminder that comes due while settings is open takes the window over for
/// its duration, and settings comes back afterwards exactly as it was.
///
/// Every change of mode goes through one queue ([_enqueue]) and re-checks the
/// state when its turn comes, so a burst of events (a click during the splash,
/// a reminder while the menu is opening) resolves in order instead of racing.
///
/// Everything native is skipped off Windows (and in tests, where [init] is
/// never called), so the notifier itself is safe to build anywhere.
class AppShellNotifier extends Notifier<ShellState>
    with TrayListener, WindowListener {
  bool _initialised = false;

  /// True while the native window is hidden.
  bool _isHidden = true;

  /// True while a mode change is under way, so the focus changes it causes
  /// itself are not mistaken for the person clicking away.
  bool _busy = false;

  /// The resting mode ([ShellMode.hidden] or [ShellMode.settings]) the window
  /// goes back to when a transient one (reminder, menu, splash) is over.
  ShellMode _resting = ShellMode.hidden;

  /// How big the settings window was last, so it reopens at the same size
  /// (though always centred — see [_WindowSpec.centredOnScreen]).
  Rect? _settingsBounds;

  Future<void> _queue = Future<void>.value();

  NativeWindow get _native => ref.read(nativeWindowProvider);

  @override
  ShellState build() {
    ref.listen(activeDhikrReminderProvider, (previous, next) {
      if (!_initialised) return;
      if (previous == null && next != null) {
        _enqueue(_onReminderShown);
      } else if (previous != null && next == null) {
        _enqueue(_onReminderDone);
      }
    });
    if (Features.trayCount) {
      ref.listen(dhikrStatsProvider, (_, __) => _scheduleTooltip());
      ref.onDispose(() => _tooltipTimer?.cancel());
    }
    ref.onDispose(() {
      if (!_initialised) return;
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    });
    return const ShellState(ShellMode.hidden, revealed: true);
  }

  Timer? _tooltipTimer;

  /// Puts today's total under the app name in the tray tooltip. Counts come in
  /// bursts, so it waits for them to stop; nothing happens before the tray exists.
  void _scheduleTooltip() {
    if (!_initialised || _quitting) return;
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_applyTooltip());
    });
  }

  Future<void> _applyTooltip() async {
    if (_quitting) return;
    final stats = ref.read(dhikrStatsProvider);
    final total = stats.day == dhikrDayKey(DateTime.now()) ? stats.today : 0;
    final l10n = lookupAppLocalizations(ref.read(localeProvider));
    try {
      await trayManager.setToolTip(
        total > 0
            ? '$_trayTooltip${String.fromCharCode(10)}'
                '${l10n.trayTodayTotal(total)}'
            : _trayTooltip,
      );
    } catch (_) {
      // A tooltip that did not update is not worth a message.
    }
  }

  /// Sets up the tray icon and takes over the window's close button. Called
  /// once from `main` before `runApp`; a failure leaves the app behaving like
  /// an ordinary window (closing it quits) rather than hidden with no way
  /// back.
  Future<void> init() async {
    if (_initialised || !ref.read(appPlatformProvider).hasWindowShell) {
      return;
    }
    try {
      await windowManager.ensureInitialized();
      // The native window outlives this Dart isolate: after a hot restart it
      // is still on screen, shaped for whatever the previous run had turned it
      // into (a reminder, say), while this run starts out believing it is
      // hidden. Putting it away and out of sight here makes that belief true,
      // so the first mode change reshapes it from a known state.
      await windowManager.hide();
      await windowManager.setPosition(_offscreen);
      // A newer copy of the app was started and is waiting for this one to go
      // (see `ReplaceRunningInstance` in windows/runner/main.cpp).
      _native.onQuitRequested(() => unawaited(quit()));
      final icons = await _buildTrayIcons();
      _quittingIconPath = icons.quitting;
      await trayManager.setIcon(icons.normal);
      await trayManager.setToolTip(_trayTooltip);
      trayManager.addListener(this);
      windowManager.addListener(this);
      // Last, so nothing above failing leaves a window that can't be closed.
      await windowManager.setPreventClose(true);
      _initialised = true;
    } catch (error, stackTrace) {
      _log('Tray setup failed; closing the window will quit the app.', error,
          stackTrace);
    }
  }

  /// Runs the start-up sequence: the splash, then the off-screen pre-warm.
  /// Called once from `main` after `runApp`.
  ///
  /// The window starts hidden (see `flutter_window.cpp`), so without this — or
  /// a tray click — nothing would ever be on screen.
  Future<void> start() async {
    if (!_initialised) {
      // No tray means no way to reach the app once it is hidden: show the
      // window as the plain settings window it would otherwise be.
      if (ref.read(appPlatformProvider).hasWindowShell) {
        try {
          await windowManager.show();
        } catch (_) {}
      }
      return;
    }
    await _enqueue(() => _enter(ShellMode.splash));
    if (state.mode != ShellMode.splash) return; // Something took over.
    await Future<void>.delayed(kSplashDuration);
    await _enqueue(() async {
      if (state.mode == ShellMode.splash) await _enter(ShellMode.prewarm);
    });
  }

  /// Called by the pre-warm surface once it has played out.
  void prewarmFinished() {
    _enqueue(() async {
      if (state.mode != ShellMode.prewarm) return;
      await _enter(_resting);
      // A debug session would otherwise wait out the whole interval (30
      // minutes by default) to find out whether the reminder even renders,
      // so it gets one for free as soon as start-up is done.
      if (!kReleaseMode && !_demoShown) {
        _demoShown = true;
        ref.read(activeDhikrReminderProvider.notifier).showTest();
      }
    });
  }

  bool _demoShown = false;

  // ---- window / tray events ------------------------------------------------

  @override
  void onWindowClose() {
    switch (state.mode) {
      case ShellMode.settings:
        _enqueue(() => _enter(ShellMode.hidden));
      case ShellMode.trayMenu:
        _enqueue(_closeMenu);
      case ShellMode.reminder:
        ref.read(activeDhikrReminderProvider.notifier).dismiss();
      case ShellMode.hidden || ShellMode.splash || ShellMode.prewarm:
        break;
    }
  }

  // A transient surface is a fixed-size popup. If something maximizes it
  // (a keyboard shortcut, snapping) it is put back the way it was placed.
  @override
  void onWindowMaximize() => _putBackIfTransient();

  @override
  void onWindowEnterFullScreen() => _putBackIfTransient();

  void _putBackIfTransient() {
    final mode = state.mode;
    if (_busy || !state.revealed) return;
    if (mode == ShellMode.splash ||
        mode == ShellMode.reminder ||
        mode == ShellMode.trayMenu) {
      _enqueue(() => _enter(mode, force: true));
    } else {
      _enqueue(_native.syncContent);
    }
  }

  @override
  void onWindowBlur() {
    if (state.mode == ShellMode.trayMenu && !_busy) {
      _enqueue(_closeMenu);
    }
  }

  // The `...MouseDown` callbacks, not `...MouseUp`: on Windows the plugin
  // reports a click once, on button release, and only ever under the
  // `MouseDown` names — the `MouseUp` ones are never delivered there.
  @override
  void onTrayIconMouseDown() => unawaited(openApp());

  @override
  void onTrayIconRightMouseDown() => unawaited(openTrayMenu());

  // ---- actions -------------------------------------------------------------

  /// Brings up the settings screen, from the tray icon or from the menu.
  Future<void> openApp() {
    return _enqueue(() async {
      // A reminder in progress owns the window; the person is mid-dhikr.
      if (state.mode == ShellMode.reminder) return;
      _resting = ShellMode.settings;
      if (state.mode == ShellMode.settings && state.revealed) {
        // Already open, perhaps behind something: just bring it forward.
        await windowManager.show();
        await windowManager.focus();
        return;
      }
      await _enter(ShellMode.settings);
    });
  }

  Future<void> openTrayMenu() {
    return _enqueue(() async {
      if (state.mode == ShellMode.reminder ||
          state.mode == ShellMode.trayMenu) {
        return;
      }
      await _enter(ShellMode.trayMenu);
    });
  }

  Future<void> toggleMuted() {
    final muted = ref.read(dhikrSettingsProvider).isMuted;
    return ref.read(dhikrSettingsProvider.notifier).updateMuted(!muted);
  }

  /// Really exits, past the hide-to-tray on close.
  ///
  /// The window is hidden first: tearing down the engine takes a moment, and
  /// until then the tray menu would sit on screen frozen. The process is also
  /// ended outright if a graceful shutdown has not finished shortly after, so
  /// a stuck teardown can never leave the app hanging around.
  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    _tooltipTimer?.cancel();
    // The app is going away regardless, so a stalled shutdown must not survive
    // any of the awaits below.
    Timer(const Duration(seconds: 2), () => exit(0));
    try {
      await windowManager.hide();
    } catch (_) {}
    try {
      // Until the process is really gone the icon is what the person sees.
      final dimmed = _quittingIconPath;
      if (dimmed != null) await trayManager.setIcon(dimmed);
      await trayManager.setToolTip('$_trayTooltip (بيتقفل...)');
    } catch (_) {}
    try {
      await trayManager.destroy();
    } catch (_) {
      // The icon going with the process anyway is fine; quitting must not
      // depend on it.
    }
    try {
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
    } catch (_) {
      exit(0);
    }
  }

  bool _quitting = false;

  /// A grayed, faded copy of the tray icon (see [_buildQuittingIcon]), shown
  /// while the app shuts down. Null if it could not be made.
  String? _quittingIconPath;

  /// Draws the tray icon, and the grayed-out one shown while quitting, from
  /// the app's one SVG ([kAppIconSvgAsset]) into the temp directory, where the
  /// tray can load them from (it takes a file path, not an asset). Both are
  /// made now so quitting never waits on drawing.
  Future<({String normal, String? quitting})> _buildTrayIcons() async {
    final svg = await rootBundle.loadString(kAppIconSvgAsset);
    final normal = await _writeIcon('tray', await renderSvgAsIco(svg));
    try {
      final dimmed = await renderSvgAsIco(svg, dimmed: true);
      return (
        normal: normal,
        quitting: await _writeIcon('tray_quitting', dimmed)
      );
    } catch (error, stackTrace) {
      // Only the closing animation is lost; the tray icon itself is fine.
      _log('Could not build the shutting-down tray icon.', error, stackTrace);
      return (normal: normal, quitting: null);
    }
  }

  Future<String> _writeIcon(String name, List<int> bytes) async {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'dhikr_reminder_$name.ico',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ---- reminder ------------------------------------------------------------

  Future<void> _onReminderShown() async {
    if (ref.read(activeDhikrReminderProvider) == null) return; // Already gone.
    if (state.mode == ShellMode.reminder) return;
    await _enter(ShellMode.reminder);
  }

  Future<void> _onReminderDone() async {
    if (state.mode != ShellMode.reminder) return;
    // The card plays a short exit; taking the window away now would cut it.
    await Future<void>.delayed(_reminderExitGrace);
    // Another reminder may have started in the meantime — it keeps the window.
    if (ref.read(activeDhikrReminderProvider) != null) return;
    if (state.mode != ShellMode.reminder) return;
    await _enter(_resting);
  }

  Future<void> _closeMenu() async {
    if (state.mode != ShellMode.trayMenu || _busy) return;
    await _enter(_resting);
  }

  // ---- internals -----------------------------------------------------------

  /// Runs [task] after every earlier one, and never lets one failure stop the
  /// ones behind it.
  Future<void> _enqueue(Future<void> Function() task) {
    final next = _queue
        .then((_) => task())
        .catchError((Object error, StackTrace stackTrace) {
      _log('A window change failed.', error, stackTrace);
      // A failure part-way leaves the window in an unknown shape; hiding it is
      // the one state that is always safe to be in.
      _isHidden = true;
      unawaited(windowManager.hide().catchError((_) {}));
      state = const ShellState(ShellMode.hidden, revealed: true);
    });
    _queue = next;
    return next;
  }

  /// Turns the window into [target], out of sight, and only then moves it
  /// where it belongs.
  ///
  /// The order matters, and is why the window is *shown* off-screen rather than
  /// hidden while it changes shape: a Flutter window resized while hidden comes
  /// back as a black rectangle, and one resized on screen shows the old
  /// surface squashed into the new frame.
  Future<void> _enter(ShellMode target, {bool force = false}) async {
    if (!_initialised) return;
    final from = state.mode;
    if (from == target && state.revealed && !force) return;
    _busy = true;
    try {
      if (from == ShellMode.settings &&
          !_isHidden &&
          !await windowManager.isMaximized() &&
          // A minimized window reports a tiny title-bar-only rectangle;
          // remembering that would reopen settings as a sliver.
          !await windowManager.isMinimized()) {
        final bounds = await windowManager.getBounds();
        if (bounds.width >= _minSettingsSize.width &&
            bounds.height >= _minSettingsSize.height) {
          _settingsBounds = bounds;
        }
      }
      if (target == ShellMode.settings || target == ShellMode.hidden) {
        _resting = target;
      }

      if (target == ShellMode.hidden) {
        if (!_isHidden) await windowManager.hide();
        _isHidden = true;
        state = const ShellState(ShellMode.hidden, revealed: true);
        return;
      }

      final spec = await _specFor(target);

      // Out of sight first. A window that is visible has to be hidden to
      // change its taskbar presence anyway.
      if (!_isHidden) {
        await windowManager.hide();
        _isHidden = true;
      }
      await _native.setToolWindow(spec.hiddenFromTaskbar);
      await windowManager.setPosition(_offscreen);
      await windowManager.show(inactive: true);
      _isHidden = false;

      // A window the person maximized (settings can be) stays maximized
      // through hide and show, and would then ignore the size it is given.
      await _native.restore();

      // Re-shape.
      if (spec.frameless) {
        await windowManager.setAsFrameless();
        await windowManager.setHasShadow(false);
      } else {
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      }
      await windowManager.setBackgroundColor(
        spec.transparent ? const Color(0x00000000) : const Color(0xFF000000),
      );
      await windowManager.setAlwaysOnTop(spec.alwaysOnTop);
      await windowManager.setBounds(
        spec.rect.translate(_offscreen.dx, _offscreen.dy),
      );

      // Only now that the window has its new size: the settings screen records
      // the size it is given (see `ShellHost`) and must not record another
      // mode's.
      state = ShellState(target);
      // Time to lay out and paint the new surface at its new size.
      await _settle();

      if (target == ShellMode.prewarm) {
        // Stays where it is: the whole point is that nobody sees it.
        state = ShellState(target, revealed: true);
        return;
      }
      final placed = spec.centredOnScreen
          ? await _centreOnScreen(spec.rect.size)
          : spec.nearCursor && await _placeNearCursor(spec.rect.size);
      if (!placed) await windowManager.setPosition(spec.rect.topLeft);
      if (spec.takeFocus) await windowManager.focus();
      // Belt and braces: make sure the Flutter view fills the window as it
      // ended up, whatever order the style and size changes landed in.
      await _native.syncContent();
      state = ShellState(target, revealed: true);
    } finally {
      _busy = false;
    }
  }

  /// Centres the window on the middle of the whole monitor the cursor is on,
  /// natively and in physical pixels, which stays exact at any resolution or
  /// DPI where logical-pixel arithmetic across monitors does not. Returns
  /// false when the runner cannot, so the caller can place it the Dart way.
  Future<bool> _centreOnScreen(Size size) async {
    final dpiChanged = await _native.centreOnCursorMonitor(size);
    if (dpiChanged == null) return false;
    // Landing on a monitor with another DPI re-scales the window; give the
    // surface a moment to lay out again at the new density.
    if (dpiChanged) await _settle();
    return true;
  }

  /// Puts the popup beside the cursor natively, on the monitor the cursor is
  /// on. Returns false when the runner cannot.
  Future<bool> _placeNearCursor(Size size) async {
    final dpiChanged = await _native.placeNearCursor(size);
    if (dpiChanged == null) return false;
    if (dpiChanged) await _settle();
    return true;
  }

  /// A moment for Flutter to lay out and paint after a change of size.
  Future<void> _settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    WidgetsBinding.instance.scheduleForcedFrame();
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }

  Future<_WindowSpec> _specFor(ShellMode mode) async {
    final cursor = await screenRetriever.getCursorScreenPoint();
    final area = _usableArea(await _displayAt(cursor));

    switch (mode) {
      case ShellMode.splash:
        return _WindowSpec(
          rect: centredRect(area, kSplashSize),
          frameless: true,
          transparent: true,
          alwaysOnTop: true,
          hiddenFromTaskbar: true,
          takeFocus: false,
          centredOnScreen: true,
        );
      case ShellMode.reminder:
      case ShellMode.prewarm:
        return _WindowSpec(
          rect: centredRect(area, kReminderWindowSize),
          frameless: true,
          transparent: true,
          alwaysOnTop: true,
          hiddenFromTaskbar: true,
          takeFocus: false,
          centredOnScreen: true,
        );
      case ShellMode.trayMenu:
        return _WindowSpec(
          rect: popupRectNearCursor(cursor, area, kTrayMenuSize),
          frameless: true,
          transparent: true,
          alwaysOnTop: true,
          hiddenFromTaskbar: true,
          takeFocus: true,
          nearCursor: true,
        );
      case ShellMode.settings:
        return _WindowSpec(
          // Reopens at the size it last had, but always in the middle of the
          // monitor the cursor is on rather than wherever it was left.
          rect: centredRect(area, _settingsBounds?.size ?? kSettingsWindowSize),
          frameless: false,
          transparent: false,
          alwaysOnTop: false,
          hiddenFromTaskbar: false,
          takeFocus: true,
          centredOnScreen: true,
        );
      case ShellMode.hidden:
        throw StateError('hidden has no window to describe');
    }
  }

  Future<Display> _displayAt(Offset point) async {
    final displays = await screenRetriever.getAllDisplays();
    for (final display in displays) {
      if (_usableArea(display).inflate(kWindowGap * 2).contains(point)) {
        return display;
      }
    }
    return screenRetriever.getPrimaryDisplay();
  }

  /// The part of [display] not covered by the taskbar.
  Rect _usableArea(Display display) {
    final origin = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;
    return Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height);
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'dhikr_reminder.shell',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

final appShellProvider = NotifierProvider<AppShellNotifier, ShellState>(
  AppShellNotifier.new,
);
