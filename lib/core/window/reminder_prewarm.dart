import 'dart:async';

import 'package:dhikr_reminder/core/toast/dhikr_reminder_overlay.dart';
import 'package:dhikr_reminder/core/window/app_shell.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A made-up reminder to run through the card once at start-up. Two taps to
/// finish, so the run covers the in-progress card *and* the completed one
/// (the green palette and the confetti). The text is Arabic, in the card's own
/// font, so that font's glyphs are the ones that get loaded.
const _sample = DhikrEntry(id: -1, name: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', amount: 2);

/// One scripted step: [after] into the run, [apply] to the sample.
typedef _Step = ({Duration after, ActiveDhikrReminder? Function(ActiveDhikrReminder?) apply});

final _script = <_Step>[
  // Mounted empty, so the entrance runs too.
  (after: const Duration(milliseconds: 150), apply: (_) => const ActiveDhikrReminder(entry: _sample)),
  (after: const Duration(milliseconds: 650), apply: (r) => r?.copyWith(count: 1)),
  (after: const Duration(milliseconds: 1100), apply: (r) => r?.copyWith(count: 2)),
  // Long enough after completion for the confetti to have flown; then the
  // exit transition.
  (after: const Duration(milliseconds: 2100), apply: (_) => null),
];

/// How long after the last step the run ends: the exit transition's 200ms
/// with room to spare.
const _tail = Duration(milliseconds: 350);

/// Plays the reminder card through its whole life once, in a window nobody can
/// see (see [ShellMode.prewarm]), so that the first real reminder does not pay
/// for what a first run costs: loading the card's font and artwork, laying out
/// and rasterizing its text, baking the glow sprites (shared with every later
/// card — see `DhikrReminderSurface.glowSprites`) and compiling whatever the
/// renderer compiles lazily.
///
/// Touches no provider: the sample lives in this widget's own state, so it can
/// neither play the reminder sound nor be mistaken for a real reminder.
class ReminderPrewarmSurface extends ConsumerStatefulWidget {
  const ReminderPrewarmSurface({super.key});

  @override
  ConsumerState<ReminderPrewarmSurface> createState() =>
      _ReminderPrewarmSurfaceState();
}

class _ReminderPrewarmSurfaceState
    extends ConsumerState<ReminderPrewarmSurface> {
  ActiveDhikrReminder? _reminder;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    for (final step in _script) {
      _timers.add(Timer(step.after, () {
        if (mounted) setState(() => _reminder = step.apply(_reminder));
      }));
    }
    _timers.add(Timer(_script.last.after + _tail, () {
      if (mounted) ref.read(appShellProvider.notifier).prewarmFinished();
    }));
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DhikrReminderSurface(
      reminder: _reminder,
      onTap: () {},
      onDismiss: () {},
    );
  }
}
