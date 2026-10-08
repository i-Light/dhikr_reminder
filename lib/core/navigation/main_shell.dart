import 'dart:async';

import 'package:dhikr_reminder/core/navigation/shell_tab.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/presentation/dhikr_library_screen.dart';
import 'package:dhikr_reminder/features/mobile_reminders/setup_prompt.dart';
import 'package:dhikr_reminder/features/notifications/presentation/notifications_screen.dart';
import 'package:dhikr_reminder/features/requests/application/request_controller.dart';
import 'package:dhikr_reminder/features/settings/presentation/home_screen.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's own chrome: its pages, and the bottom bar that switches between
/// them.
///
/// An [IndexedStack] rather than a [Navigator] or a plain conditional child,
/// because every page should stay mounted while another is in front:
/// switching to the library and back must not throw away the settings card's
/// unsaved draft, nor the library's scroll position and search text. It also
/// keeps this widget's subtree, and with it the `DhikrReminderHost` and
/// `ToastOverlay` mounted above it (see `app.dart`), unchanged across a
/// switch.
///
/// `sizing: StackFit.expand`, so every page is laid out at the full body size
/// whether or not it is the one on show: a page sized to its own content would
/// rearrange itself the moment it came to the front.
///
/// Which page is in front lives in [shellTabProvider], so a page can send the
/// person to another one.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tab = ref.watch(shellTabProvider);

    // The "pick a dhikr to add" hint, and the add buttons it switched on,
    // belong to the visit that asked for them; leaving the library by any
    // route (the bar, or the banner's own way back) ends that visit.
    ref.listen<ShellTab>(shellTabProvider, (previous, next) {
      if (previous == ShellTab.library && next != ShellTab.library) {
        ref.read(dhikrLibraryProvider.notifier).endVisit();
      }
    });

    final page = Scaffold(
      body: IndexedStack(
        index: tab.index,
        sizing: StackFit.expand,
        children: const [
          HomeScreen(),
          NotificationsScreen(),
          DhikrLibraryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (index) {
          ref.read(shellTabProvider.notifier).show(ShellTab.values[index]);
          // News about a request is waiting in the library, so look when the
          // person goes there. Does nothing when the build has no service.
          if (ShellTab.values[index] == ShellTab.library) {
            unawaited(ref.read(dhikrRequestsProvider.notifier).refresh());
          }
        },
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

    return SetupPrompt(child: page);
  }
}
