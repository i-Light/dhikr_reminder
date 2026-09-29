import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/features/settings/presentation/widgets/dhikr_settings_card.dart';
import 'package:dhikr_reminder/features/settings/presentation/widgets/update_card.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The settings screen: the azkar settings card, the updates card, plus a way
/// to see a reminder without waiting out the interval.
///
/// Only ever shown from the tray icon (see `AppShellNotifier`) — opening the
/// app does not bring it up.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const UpdateCard(),
                  const SizedBox(height: 24),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: ref.read(activeDhikrReminderProvider.notifier).showTest,
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
