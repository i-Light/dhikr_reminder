import 'package:dhikr_reminder/core/update/update_controller.dart';
import 'package:dhikr_reminder/core/update/update_source.dart';
import 'package:dhikr_reminder/core/widgets/collapsible_card.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The settings screen's "Updates" card: what version is running, what the
/// updater is doing about a newer one, and the two controls a person could
/// want — check now, and turn the automatic part off.
///
/// The updater needs none of this to work; the card only makes it visible.
class UpdateCard extends ConsumerWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final update = ref.watch(updateProvider);
    final notifier = ref.read(updateProvider.notifier);
    final status =
        _StatusText.of(update, l10n, Localizations.localeOf(context));
    final subtle = theme.colorScheme.onSurfaceVariant;

    // The one button that acts on the update itself, if there is one to act
    // on.
    final (String label, VoidCallback onPressed)? primary = switch (update) {
      UpdateState(phase: UpdatePhase.waitingForIdle) => (
          l10n.updateRestartButton,
          notifier.installNow,
        ),
      UpdateState(phase: UpdatePhase.idle, updateAvailable: true) =>
        update.canSelfUpdate
            ? (l10n.updateInstallButton, notifier.installNow)
            : (
                l10n.updateDownloadPageButton,
                () => openInBrowser(releasesPageUri),
              ),
      _ => null,
    };

    return CollapsibleCard(
      title: l10n.updateTitle,
      subtitle: l10n.updateSubtitle,
      initiallyExpanded: false,
      gradientBackground: true,
      // Folded, the card still has to say whether there is something to do.
      collapsedSummary: Row(
        spacing: 12,
        children: [
          _StatusIcon(status: status, size: 20),
          Expanded(
            child: Text(
              status.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      child: Column(
        spacing: 24,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (update.currentVersion != null)
            Row(
              spacing: 16,
              children: [
                const SizedBox(width: 24),
                Icon(Icons.info_outline, color: subtle),
                Text(
                  l10n.updateVersion(update.currentVersion.toString()),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          Row(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 24),
              _StatusIcon(status: status, size: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.title, style: theme.textTheme.bodyMedium),
                    if (status.hint != null)
                      Text(
                        status.hint!,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: subtle),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 64),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (primary != null)
                  FilledButton(
                    onPressed: primary.$2,
                    child: Text(primary.$1),
                  ),
                OutlinedButton.icon(
                  onPressed: update.busy ? null : notifier.checkNow,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.updateCheckButton),
                ),
              ],
            ),
          ),
          // Nothing to switch off on a copy that cannot update itself.
          if (update.canSelfUpdate) ...[
            const Divider(),
            Row(
              spacing: 16,
              children: [
                const SizedBox(width: 24),
                Icon(Icons.autorenew_rounded, color: subtle),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.updateAutoLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        l10n.updateAutoSubtitle,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: subtle),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: update.autoUpdate,
                  onChanged: notifier.setAutoUpdate,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _Tone { neutral, working, good, attention, problem }

/// What to say about an [UpdateState], and how loudly.
class _StatusText {
  const _StatusText(this.tone, this.title, [this.hint]);

  final _Tone tone;
  final String title;
  final String? hint;

  static _StatusText of(
      UpdateState update, AppLocalizations l10n, Locale locale) {
    final latest = update.latestVersion.toString();
    switch (update.phase) {
      case UpdatePhase.checking:
        return _StatusText(_Tone.working, l10n.updateChecking);
      case UpdatePhase.downloading:
        return _StatusText(_Tone.working, l10n.updateDownloading(latest));
      case UpdatePhase.waitingForIdle:
        return _StatusText(
          _Tone.attention,
          l10n.updateReady(latest),
          l10n.updateReadyHint,
        );
      case UpdatePhase.installing:
        return _StatusText(_Tone.working, l10n.updateInstalling(latest));
      case UpdatePhase.idle:
        break;
    }

    if (update.failed) {
      return _StatusText(
        _Tone.problem,
        l10n.updateFailed,
        l10n.updateFailedHint,
      );
    }
    if (update.updateAvailable) {
      return _StatusText(
        _Tone.attention,
        l10n.updateAvailable(latest),
        !update.canSelfUpdate
            ? l10n.updateAvailableManual
            : (update.autoUpdate ? null : l10n.updateAvailableAutoOff),
      );
    }
    final checked = update.lastChecked;
    if (checked != null) {
      return _StatusText(
        _Tone.good,
        l10n.updateUpToDate,
        l10n.updateLastChecked(
          DateFormat.jm(locale.toString()).format(checked),
        ),
      );
    }
    return _StatusText(_Tone.neutral, l10n.updateNeverChecked);
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.size});

  final _StatusText status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: switch (status.tone) {
        _Tone.working => Padding(
            padding: EdgeInsets.all(size / 6),
            child: const CircularProgressIndicator(strokeWidth: 2.5),
          ),
        _Tone.good => Icon(
            Icons.check_circle_outline,
            size: size,
            color: scheme.primary,
          ),
        _Tone.attention => Icon(
            Icons.system_update_alt_rounded,
            size: size,
            color: scheme.primary,
          ),
        _Tone.problem => Icon(
            Icons.error_outline,
            size: size,
            color: scheme.error,
          ),
        _Tone.neutral => Icon(
            Icons.help_outline,
            size: size,
            color: scheme.onSurfaceVariant,
          ),
      },
    );
  }
}
