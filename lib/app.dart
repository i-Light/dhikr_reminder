import 'package:dhikr_reminder/core/theme/app_theme.dart';
import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/core/toast/toast_overlay.dart';
import 'package:dhikr_reminder/features/settings/presentation/home_screen.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Root widget of the standalone dhikr reminder.
///
/// This is gratovo_toolbox's `app.dart` reduced to what this app actually
/// needs: the same theme, the same localization setup, and — most
/// importantly — the same `builder` that keeps both overlays mounted above
/// every screen.
class DhikrReminderApp extends StatelessWidget {
  const DhikrReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dhikr Reminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale:
          null, // Follows the OS locale; falls back to en for anything else.
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const HomeScreen(),
      // Both overlays sit in `builder`, above `home`, and that placement is
      // the whole reason they work:
      //
      //  - `DhikrReminderOverlay` is the only place
      //    `dhikrReminderSchedulerProvider` is watched, and a
      //    `NotifierProvider` with nothing listening to it is torn down.
      //    Mounting it here — rather than inside a screen — means the timer
      //    outlives every rebuild of the widget below it.
      //  - `ToastOverlay` likewise needs one permanent home, since
      //    `AppToast.*` calls come from widgets (the settings card's Save)
      //    that can be built and thrown away at any time.
      //
      // Reminder above toast, so a reminder that fires while a toast is up
      // still reads as the more urgent of the two.
      builder: (context, child) => DhikrReminderOverlay(
        child: ToastOverlay(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
