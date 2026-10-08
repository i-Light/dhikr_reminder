import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The pages the bottom bar switches between, in bar order.
enum ShellTab { settings, notifications, library }

/// Which page is in front. A provider so a page can send the person to another
/// one (the notifications page's "Add dhikr" opens the library) without
/// reaching into the shell.
class ShellTabNotifier extends Notifier<ShellTab> {
  @override
  ShellTab build() => ShellTab.settings;

  void show(ShellTab tab) => state = tab;
}

final shellTabProvider = NotifierProvider<ShellTabNotifier, ShellTab>(
  ShellTabNotifier.new,
);
