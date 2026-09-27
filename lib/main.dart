import 'package:dhikr_reminder/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // No Supabase/SQLite/window-tray boot sequence to await here — the only
  // startup work is the dhikr settings' own `SharedPreferences` read, which
  // `DhikrController` kicks off lazily when it is first watched. So `runApp`
  // is not gated on anything, and the window paints immediately.
  runApp(const ProviderScope(child: DhikrReminderApp()));
}
