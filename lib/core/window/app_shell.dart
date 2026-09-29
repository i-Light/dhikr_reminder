import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';

import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// What the one native window is currently being used as.
enum ShellMode {
  /// The normal app window: settings screen plus the reminder overlay.
  app,

  /// A small frameless popup shown at the tray icon, rendering
  /// `TrayMenuPanel` instead of the app.
  trayMenu,
}

/// Size of the tray popup, in logical pixels — see `TrayMenuPanel`.
const kTrayMenuSize = Size(272, 264);

const _trayIconAsset = 'assets/images/tray_icon.ico';
const _trayTooltip = 'Dhikr Reminder';

/// Gap between the popup and the tray icon it opened from, and between the
/// popup and the screen's edge.
const _trayMenuGap = 10.0;

/// Owns the app's relationship with its own window and the system tray:
///
///  * closing the window hides it to the tray instead of quitting;
///  * the tray icon's left click brings the app back, its right click opens a
///    themed menu (rendered by Flutter, not a native one) — done by turning
///    this same window into a small frameless popup for as long as the menu is
///    up, then restoring it exactly as it was;
///  * a reminder that comes due while the window is hidden brings the window
///    up to show it, and puts it away again when the reminder is done.
///
/// One window, two modes, rather than a second native window: the Flutter
/// engine, the providers and the reminder timer all live in this one, and a
/// second engine would have had to be kept in step with them.
///
/// Everything native is skipped off Windows (and in tests, where [init] is
/// never called), so the notifier itself is safe to build anywhere.
class AppShellNotifier extends Notifier<ShellMode>
    with TrayListener, WindowListener {
  bool _initialised = false;

  /// True while the window is hidden to the tray.
  bool _isHidden = false;

  /// True when the window was raised only to show a reminder, so it should go
  /// back to the tray once that reminder is done. Cleared as soon as the
  /// person opens the app themselves.
  bool _shownForReminder = false;

  /// True while switching between modes, so the focus changes the switch
  /// itself causes are not mistaken for the person clicking away.
  bool _transitioning = false;

  Rect? _savedBounds;
  bool _wasHiddenBeforeMenu = false;

  @override
  ShellMode build() {
    ref.listen(activeDhikrReminderProvider, (previous, next) {
      if (!_initialised) return;
      if (previous == null && next != null) {
        unawaited(_onReminderShown());
      } else if (previous != null && next == null) {
        unawaited(_onReminderDone());
      }
    });
    ref.onDispose(() {
      if (!_initialised) return;
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    });
    return ShellMode.app;
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
      developer.log(
        'Tray setup failed; closing the window will quit the app.',
        name: 'dhikr_reminder.shell',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ---- window / tray events ------------------------------------------------

  @override
  void onWindowClose() {
    if (state == ShellMode.trayMenu) {
      unawaited(closeTrayMenu(showApp: false));
      return;
    }
    unawaited(_hideToTray());
  }

  @override
  void onWindowBlur() {
    if (state == ShellMode.trayMenu && !_transitioning) {
      unawaited(closeTrayMenu(showApp: false));
    }
  }

  @override
  void onTrayIconMouseUp() => unawaited(openApp());

  @override
  void onTrayIconRightMouseUp() => unawaited(openTrayMenu());

  // ---- actions -------------------------------------------------------------

  /// Brings the app window to the front, from the tray or from the menu.
  Future<void> openApp() async {
    _shownForReminder = false;
    if (state == ShellMode.trayMenu) {
      await closeTrayMenu(showApp: true);
      return;
    }
    await _showWindow();
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

  Future<void> openTrayMenu() async {
    if (!_initialised || state == ShellMode.trayMenu || _transitioning) return;
    _transitioning = true;
    try {
      final cursor = await screenRetriever.getCursorScreenPoint();
      final display = await _displayAt(cursor);

      _wasHiddenBeforeMenu = _isHidden;
      _savedBounds = await windowManager.getBounds();
      // Hidden while it changes shape, so the settings screen is never seen
      // squashed into a menu-sized frame.
      await windowManager.hide();
      state = ShellMode.trayMenu;
      await windowManager.setAsFrameless();
      await windowManager.setSkipTaskbar(true);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setBounds(_menuRect(cursor, display));
      // Gives the panel a moment to replace the app before it is shown.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await windowManager.show();
      await windowManager.focus();
      _isHidden = false;
    } catch (error, stackTrace) {
      developer.log(
        'Opening the tray menu failed.',
        name: 'dhikr_reminder.shell',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
      _transitioning = false;
      await closeTrayMenu(showApp: false);
    } finally {
      _transitioning = false;
    }
  }

  /// Puts the window back the way it was before the menu took it over: same
  /// frame, same size and position, and hidden again unless [showApp] says the
  /// person asked for the app.
  Future<void> closeTrayMenu({required bool showApp}) async {
    if (state != ShellMode.trayMenu || _transitioning) return;
    _transitioning = true;
    try {
      await windowManager.hide();
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setSkipTaskbar(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      final bounds = _savedBounds;
      if (bounds != null) await windowManager.setBounds(bounds);
      // Only now, at full size again: the app records the size it is given
      // whenever it is not the menu (see `_ShellHost`), and must not record
      // the popup's.
      state = ShellMode.app;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      if (showApp || !_wasHiddenBeforeMenu) {
        await _showWindow();
      } else {
        _isHidden = true;
      }
    } finally {
      _transitioning = false;
    }
  }

  // ---- internals -----------------------------------------------------------

  Future<void> _showWindow() async {
    _isHidden = false;
    // `show` also un-minimizes.
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _hideToTray() async {
    _shownForReminder = false;
    // A reminder left up behind a hidden window would block every later one
    // (the scheduler never interrupts one in progress) with nothing on screen
    // to dismiss it.
    ref.read(activeDhikrReminderProvider.notifier).dismiss();
    _isHidden = true;
    await windowManager.hide();
  }

  Future<void> _onReminderShown() async {
    if (state == ShellMode.trayMenu) {
      // The reminder is the thing to look at, not the menu.
      _shownForReminder = _wasHiddenBeforeMenu;
      await closeTrayMenu(showApp: true);
      return;
    }
    if (_isHidden) {
      _shownForReminder = true;
      await _showWindow();
    }
  }

  Future<void> _onReminderDone() async {
    if (!_shownForReminder || state != ShellMode.app) return;
    _shownForReminder = false;
    _isHidden = true;
    await windowManager.hide();
  }

  Future<Display> _displayAt(Offset point) async {
    final displays = await screenRetriever.getAllDisplays();
    for (final display in displays) {
      if (_usableArea(display).inflate(_trayMenuGap * 2).contains(point)) {
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

  /// Where the popup goes: centred on the cursor (which is on the tray icon),
  /// above it when the icon is in the lower half of the screen and below it
  /// otherwise, and always fully inside the usable area.
  Rect _menuRect(Offset cursor, Display display) {
    final area = _usableArea(display);
    const size = kTrayMenuSize;
    final above = cursor.dy > area.center.dy;
    final left = (cursor.dx - size.width / 2).clamp(
      area.left + _trayMenuGap,
      area.right - size.width - _trayMenuGap,
    );
    final top = (above
            ? cursor.dy - size.height - _trayMenuGap
            : cursor.dy + _trayMenuGap)
        .clamp(
      area.top + _trayMenuGap,
      area.bottom - size.height - _trayMenuGap,
    );
    return Rect.fromLTWH(left, top, size.width, size.height);
  }
}

final appShellProvider = NotifierProvider<AppShellNotifier, ShellMode>(
  AppShellNotifier.new,
);
