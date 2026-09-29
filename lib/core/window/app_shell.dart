import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
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

/// Size of the tray popup, in logical pixels — see `TrayMenuPanel`.
const kTrayMenuSize = Size(272, 264);

/// Size of the splash window; the splash card fills it.
const kSplashSize = Size(420, 240);

/// Size of the reminder popup window: the card plus room for its glow (see
/// [kDhikrReminderGlowMargin]). Shrunk to fit a display smaller than this.
const kReminderWindowSize = Size(1120, 700);

/// Size the settings window opens at the first time.
const kSettingsWindowSize = Size(960, 720);

/// How long the splash stays up. `SplashSurface` runs its fade in and out
/// inside this.
const kSplashDuration = Duration(milliseconds: 1800);

const _trayIconAsset = 'assets/images/tray_icon.ico';
const _trayTooltip = 'Dhikr Reminder';

/// Gap between a popup and the tray icon it opened from, and between a popup
/// and the screen's edge.
const _screenGap = 10.0;

/// How long a leaving reminder is given to play its exit before the window
/// goes away under it (`DhikrTimers.cardEntrance`, plus a little).
const _reminderExitGrace = Duration(milliseconds: 300);

/// Windows-only window tweaks `window_manager` cannot do — see
/// `windows/runner/flutter_window.cpp`.
const _windowChannel = MethodChannel('dhikr_reminder/window');

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

  /// Where the settings window was last, so it reopens in the same place.
  Rect? _settingsBounds;

  Future<void> _queue = Future<void>.value();

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
    ref.onDispose(() {
      if (!_initialised) return;
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    });
    return const ShellState(ShellMode.hidden, revealed: true);
  }

  /// Sets up the tray icon and takes over the window's close button. Called
  /// once from `main` before `runApp`; a failure leaves the app behaving like
  /// an ordinary window (closing it quits) rather than hidden with no way
  /// back.
  Future<void> init() async {
    if (_initialised || kIsWeb || !Platform.isWindows) return;
    try {
      await windowManager.ensureInitialized();
      await trayManager.setIcon(_trayIconAsset);
      await trayManager.setToolTip(_trayTooltip);
      trayManager.addListener(this);
      windowManager.addListener(this);
      // Last, so nothing above failing leaves a window that can't be closed.
      await windowManager.setPreventClose(true);
      _initialised = true;
    } catch (error, stackTrace) {
      _log('Tray setup failed; closing the window will quit the app.',
          error, stackTrace);
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
      if (!kIsWeb && Platform.isWindows) {
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
      if (state.mode == ShellMode.reminder || state.mode == ShellMode.trayMenu) {
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
  Future<void> quit() async {
    try {
      await trayManager.destroy();
    } catch (_) {
      // The icon going with the process anyway is fine; quitting must not
      // depend on it.
    }
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
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
    final next = _queue.then((_) => task()).catchError((Object error, StackTrace stackTrace) {
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
  Future<void> _enter(ShellMode target) async {
    if (!_initialised) return;
    final from = state.mode;
    if (from == target && state.revealed) return;
    _busy = true;
    try {
      if (from == ShellMode.settings && !_isHidden) {
        _settingsBounds = await windowManager.getBounds();
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
      await _setHiddenFromTaskbar(spec.hiddenFromTaskbar);
      await windowManager.setPosition(_offscreen);
      await windowManager.show(inactive: true);
      _isHidden = false;

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
      await windowManager.setPosition(spec.rect.topLeft);
      if (spec.takeFocus) await windowManager.focus();
      state = ShellState(target, revealed: true);
    } finally {
      _busy = false;
    }
  }

  Future<void> _setHiddenFromTaskbar(bool hidden) async {
    try {
      await _windowChannel.invokeMethod<void>('setToolWindow', hidden);
    } on MissingPluginException {
      // An older runner without the channel: the popup just shows in the
      // taskbar while it is up.
    }
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
          rect: _centred(area, kSplashSize),
          frameless: true,
          transparent: true,
          alwaysOnTop: true,
          hiddenFromTaskbar: true,
          takeFocus: false,
        );
      case ShellMode.reminder:
      case ShellMode.prewarm:
        return _WindowSpec(
          rect: _centred(area, kReminderWindowSize),
          frameless: true,
          transparent: true,
          alwaysOnTop: true,
          hiddenFromTaskbar: true,
          takeFocus: false,
        );
      case ShellMode.trayMenu:
        return _WindowSpec(
          rect: _menuRect(cursor, area),
          frameless: true,
          transparent: false,
          alwaysOnTop: true,
          hiddenFromTaskbar: true,
          takeFocus: true,
        );
      case ShellMode.settings:
        return _WindowSpec(
          rect: _settingsBounds ?? _centred(area, kSettingsWindowSize),
          frameless: false,
          transparent: false,
          alwaysOnTop: false,
          hiddenFromTaskbar: false,
          takeFocus: true,
        );
      case ShellMode.hidden:
        throw StateError('hidden has no window to describe');
    }
  }

  Future<Display> _displayAt(Offset point) async {
    final displays = await screenRetriever.getAllDisplays();
    for (final display in displays) {
      if (_usableArea(display).inflate(_screenGap * 2).contains(point)) {
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

  /// A [size] window in the middle of [area], shrunk to fit it if need be.
  Rect _centred(Rect area, Size size) {
    final fitted = Size(
      math.min(size.width, area.width - _screenGap * 2),
      math.min(size.height, area.height - _screenGap * 2),
    );
    return Rect.fromCenter(
      center: area.center,
      width: fitted.width,
      height: fitted.height,
    );
  }

  /// Where the menu goes: centred on the cursor (which is on the tray icon),
  /// above it when the icon is in the lower half of the screen and below it
  /// otherwise, and always fully inside the usable area.
  Rect _menuRect(Offset cursor, Rect area) {
    const size = kTrayMenuSize;
    final above = cursor.dy > area.center.dy;
    final left = (cursor.dx - size.width / 2).clamp(
      area.left + _screenGap,
      area.right - size.width - _screenGap,
    );
    final top = (above
            ? cursor.dy - size.height - _screenGap
            : cursor.dy + _screenGap)
        .clamp(
      area.top + _screenGap,
      area.bottom - size.height - _screenGap,
    );
    return Rect.fromLTWH(left, top, size.width, size.height);
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
