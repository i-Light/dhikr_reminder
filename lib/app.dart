import 'package:dhikr_reminder/core/locale/locale_controller.dart';
import 'package:dhikr_reminder/core/navigation/main_shell.dart';
import 'package:dhikr_reminder/core/theme/app_theme.dart';
import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/core/toast/toast_overlay.dart';
import 'package:dhikr_reminder/core/window/app_shell.dart';
import 'package:dhikr_reminder/core/window/reminder_prewarm.dart';
import 'package:dhikr_reminder/core/window/splash_surface.dart';
import 'package:dhikr_reminder/core/window/tray_menu_panel.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget of the standalone dhikr reminder.
///
/// This is gratovo_toolbox's `app.dart` reduced to what this app actually
/// needs: the same theme, the same localization setup, and a `builder` that
/// decides what the one native window is showing — see [_ShellHost].
class DhikrReminderApp extends ConsumerWidget {
  const DhikrReminderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Dhikr Reminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // Arabic (Egyptian) unless the person switched to English in settings —
      // never the OS locale. See `localeProvider`.
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // `MainShell` is the app's own two pages (settings, the azkar library)
      // behind one bottom bar — see `core/navigation/main_shell.dart`.
      home: const MainShell(),
      // `DhikrReminderHost` sits in `builder`, above everything the window can
      // show, and that placement is the whole reason the reminders work: it is
      // the only place `dhikrReminderSchedulerProvider` is watched, and a
      // `NotifierProvider` with nothing listening to it is torn down. Mounting
      // it here — rather than inside a screen — means the timer outlives every
      // change of what the window is showing.
      //
      // `ToastOverlay` likewise needs one permanent home, since `AppToast.*`
      // calls come from widgets (the settings card's Save) that can be built
      // and thrown away at any time.
      builder: (context, child) => DhikrReminderHost(
        child: _ShellHost(
          app: ToastOverlay(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Shows whichever surface matches what [AppShellNotifier] currently has the
/// window turned into: nothing, the splash, the reminder popup (or its
/// invisible pre-warm run), the tray menu, or the settings screen.
///
/// The settings screen is not built until it is first opened, and is never
/// unmounted after that: doing so would throw away the navigator and with it
/// the settings card's unsaved draft, which matters when a reminder or the
/// menu takes the window over while settings is open. Instead it is taken out
/// of view and pinned to the size it last had, so it is not laid out at the
/// other surface's size (which would squash the page) while it waits.
class _ShellHost extends ConsumerStatefulWidget {
  const _ShellHost({required this.app});

  final Widget app;

  @override
  ConsumerState<_ShellHost> createState() => _ShellHostState();
}

class _ShellHostState extends ConsumerState<_ShellHost> {
  Size _appSize = kSettingsWindowSize;
  bool _appEverShown = false;

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(appShellProvider);
    final showApp = shell.mode == ShellMode.settings;
    _appEverShown = _appEverShown || showApp;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Only once the window has arrived at its settings size: on the way
        // there the constraints are still whatever the last mode's were.
        if (showApp && shell.revealed) _appSize = constraints.biggest;
        return Stack(
          children: [
            if (_appEverShown)
              Offstage(
                key: const ValueKey('app'),
                offstage: !showApp,
                // Same widget in every mode (only its arguments change) so the
                // app keeps its state across the switch.
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: showApp ? null : _appSize.width,
                  maxWidth: showApp ? null : _appSize.width,
                  minHeight: showApp ? null : _appSize.height,
                  maxHeight: showApp ? null : _appSize.height,
                  child: widget.app,
                ),
              ),
            ...switch (shell.mode) {
              ShellMode.hidden || ShellMode.settings => const <Widget>[],
              ShellMode.splash => [
                  // Mounted only once the window is on screen, so the splash's
                  // fade-in is the first thing anyone sees of it.
                  if (shell.revealed)
                    const Positioned.fill(
                      key: ValueKey('splash'),
                      child: SplashSurface(),
                    ),
                ],
              ShellMode.prewarm => const [
                  Positioned.fill(
                    key: ValueKey('prewarm'),
                    child: ReminderPrewarmSurface(),
                  ),
                ],
              ShellMode.reminder => [
                  Positioned.fill(
                    key: const ValueKey('reminder'),
                    // Empty until the window is on screen, so the card plays
                    // its entrance where it can be seen.
                    child:
                        DhikrReminderProviderSurface(visible: shell.revealed),
                  ),
                ],
              ShellMode.trayMenu => const [
                  Positioned.fill(
                    key: ValueKey('menu'),
                    child: TrayMenuPanel(),
                  ),
                ],
            },
          ],
        );
      },
    );
  }
}
