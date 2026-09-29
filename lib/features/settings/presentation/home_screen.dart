import 'dart:async';

import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/settings/presentation/widgets/dhikr_settings_card.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long a debug session waits before popping its free reminder. Long
/// enough that the window has painted and the saved settings have come back
/// from disk, short enough that pressing F5 and looking away is all it takes.
const _debugDemoDelay = Duration(seconds: 3);

/// The app's only screen: the azkar settings card, plus a way to see a
/// reminder without waiting out the interval.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _debugDemoTimer;

  @override
  void initState() {
    super.initState();
    if (kReleaseMode) return;
    // Debug/Profile only: the interval defaults to 30 minutes, which makes
    // "does the reminder even render?" a half-hour question every time you
    // start a debugging session. Fire one on its own after a short beat so
    // F5 answers it immediately.
    _debugDemoTimer = Timer(_debugDemoDelay, _showTestReminder);
  }

  @override
  void dispose() {
    _debugDemoTimer?.cancel();
    super.dispose();
  }

  /// Pops a reminder right now, reusing the scheduler's own entry point.
  ///
  /// Deliberately not `DhikrReminderScheduler.pickWeighted`: that is
  /// `@visibleForTesting`, and this is app code. The test button and the
  /// debug demo both just take the first un-muted entry — the point is to see
  /// the card, not to sample the weighting.
  void _showTestReminder() {
    final settings = ref.read(dhikrSettingsProvider);
    // With the chance option off nothing is excluded, whatever chance an
    // entry has stored.
    final entries = settings.entries
        .where((entry) => !settings.useChance || entry.chance > 0)
        .toList();
    if (entries.isEmpty) return;
    ref.read(activeDhikrReminderProvider.notifier).show(entries.first);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.appTitle, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    l10n.homeSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const DhikrCard(),
                  const SizedBox(height: 24),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: _showTestReminder,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.commonTestReminder),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
