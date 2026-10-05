import 'package:dhikr_reminder/features/library/presentation/dhikr_library_screen.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_prompt.dart';
import 'package:dhikr_reminder/features/notifications/presentation/notifications_screen.dart';
import 'package:dhikr_reminder/features/settings/presentation/home_screen.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The app's own chrome: its two pages, and the bottom bar that switches
/// between them.
///
/// An [IndexedStack] rather than a [Navigator] or a plain conditional child,
/// because both pages should stay mounted while the other is in front:
/// switching to the library and back must not throw away the settings card's
/// unsaved draft, nor the library's scroll position and search text. It also
/// keeps this widget's subtree — and with it the `DhikrReminderHost` and
/// `ToastOverlay` mounted above it (see `app.dart`) — unchanged across a
/// switch.
///
/// `sizing: StackFit.expand`, so both pages are laid out at the full body
/// size whether or not they are the one on show: a page sized to its own
/// content would rearrange itself the moment it came to the front.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// The settings page is what the window opens on: the reminder is the app's
  /// one job, and its settings are what the tray icon led here for. The
  /// library is the second tab, one tap away.
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final page = Scaffold(
      body: IndexedStack(
        index: _index,
        sizing: StackFit.expand,
        children: const [
          HomeScreen(),
          NotificationsScreen(),
          DhikrLibraryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune),
            label: l10n.navSettings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_none),
            selectedIcon: const Icon(Icons.notifications),
            label: l10n.navNotifications,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.navLibrary,
          ),
        ],
      ),
    );

    return OverlayPermissionPrompt(child: page);
  }
}
