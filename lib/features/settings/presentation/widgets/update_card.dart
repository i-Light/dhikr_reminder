import 'package:dhikr_reminder/core/update/update_controller.dart';
import 'package:dhikr_reminder/core/update/update_source.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The home page's update card: one compact row saying what the updater is
/// doing (and the running version), with the one button that acts on it and a
/// check-now button — plus, where the app can update itself, a one-line switch
/// for the automatic part.
///
/// Always open; there is nothing to fold away. The updater needs none of this
/// to work; the card only makes it visible.
class UpdateCard extends ConsumerWidget {
  const UpdateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appPlatformProvider).updatesThroughStore) {
      return const _StoreUpdateCard();
    }
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

    // "Version 0.1.0" over "Last checked 9:41 PM": the running version always,
    // and the status' own detail after it.
    final detail = [
      if (update.currentVersion != null)
        l10n.updateVersion(update.currentVersion.toString()),
      if (status.hint != null) status.hint!,
    ].join('\n');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 10),
        child: Column(
          children: [
            Row(
              spacing: 12,
              children: [
                _StatusIcon(status: status, size: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: subtle),
                        ),
                    ],
                  ),
                ),
                if (primary != null)
                  FilledButton(
                    onPressed: primary.$2,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(primary.$1),
                  ),
                IconButton(
                  tooltip: l10n.updateCheckButton,
                  onPressed: update.busy ? null : notifier.checkNow,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            // Nothing to switch off on a copy that cannot update itself.
            if (update.canSelfUpdate)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Row(
                  spacing: 12,
                  children: [
                    SizedBox.square(
                      dimension: 22,
                      child: Icon(Icons.autorenew_rounded,
                          size: 20, color: subtle),
                    ),
                    Expanded(
                      child: Text(
                        l10n.updateAutoLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: update.autoUpdate,
                        onChanged: notifier.setAutoUpdate,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The card on a phone, where Google Play delivers updates: the running
/// version, a note that Play does the updating, and a shortcut to the app's
/// page there.
class _StoreUpdateCard extends ConsumerWidget {
  const _StoreUpdateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final version = ref.watch(updateProvider.select((s) => s.currentVersion));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Icon(
                  Icons.system_update_alt_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        l10n.updatePlayTitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        [
                          if (version != null) l10n.updateVersion('$version'),
                          l10n.updatePlayHint,
                        ].join('\n'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Under the text rather than beside it: the sentence needs the
            // width, and "Google Play" in the middle of Arabic wraps badly in
            // a narrow column.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _openPlayPage,
                child: Text(l10n.updateOpenPlayButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The Play Store app if there is one, the web page if not.
  Future<void> _openPlayPage() async {
    if (await openInBrowser(playStoreAppUri)) return;
    await openInBrowser(playStorePageUri);
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
