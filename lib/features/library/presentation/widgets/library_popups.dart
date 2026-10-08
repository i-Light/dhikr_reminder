import 'dart:async';

import 'package:dhikr_reminder/core/theme/gradient_text.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/dhikr_tag_label.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the settings and filters popup: the tashkeel toggle, the text size,
/// hiding what is already added, and the gallery of group buttons.
Future<void> showDhikrQuickSettings(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const DhikrQuickSettingsPopup(),
  );
}

/// The shell the popup is built from: a titled, closeable [Dialog] whose body
/// scrolls once it outgrows the screen.
///
/// Built on [Dialog] rather than a menu anchored to the button that opened it
/// so the same code is right on a phone (where a popup must be reachable by
/// thumb and may need to scroll) and on a desktop window (where the button is
/// at the top edge and a centred popup is simply the calm choice). The body
/// sits in a [Flexible] + [SingleChildScrollView] so the filter gallery —
/// twenty-eight buttons, which will not fit a phone in portrait — scrolls
/// instead of overflowing.
class LibraryPopupCard extends StatelessWidget {
  const LibraryPopupCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.maxWidth = 380,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Width the popup stops growing at. The quick settings are two controls
  /// and read oddly wide; the tag gallery needs the room for its buttons to
  /// sit in rows.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 8, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GradientText(title, style: theme.textTheme.titleMedium),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: l10n.libraryClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The library's settings and its filters in one popup: the tashkeel toggle,
/// the text-size stepper, the switch that leaves out what is already added, and
/// the gallery of group buttons.
///
/// Reads and writes [dhikrLibraryProvider] directly, so a change made here is
/// already on screen in the list behind the popup — there is nothing to
/// confirm and no button to press twice.
class DhikrQuickSettingsPopup extends ConsumerWidget {
  const DhikrQuickSettingsPopup({super.key, bool? showTashkeelOption})
      : _showTashkeelOption = showTashkeelOption;

  /// Whether to offer the tashkeel switch. Left out by default when the
  /// library has no vowelled text, since the switch would change nothing.
  final bool? _showTashkeelOption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final view = ref.watch(dhikrLibraryProvider);
    final notifier = ref.read(dhikrLibraryProvider.notifier);
    final size = view.fontSize.round();
    final atMin = view.fontSize <= dhikrLibraryFontMin;
    final atMax = view.fontSize >= dhikrLibraryFontMax;

    return LibraryPopupCard(
      title: l10n.libraryQuickSettings,
      maxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showTashkeelOption ?? libraryHasTashkeel) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: view.showTashkeel,
              onChanged: (_) => unawaited(notifier.toggleTashkeel()),
              secondary: const Icon(Icons.text_fields),
              title: Text(l10n.libraryTashkeelLabel),
              subtitle: Text(l10n.libraryTashkeelSubtitle),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
          ],
          Text(
            l10n.libraryFontSizeLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          // The number sits between the two buttons rather than beside them:
          // it is what they act on, and reading the current size without
          // looking away from the control is the whole point of showing it.
          Row(
            children: [
              IconButton.filledTonal(
                onPressed:
                    atMin ? null : () => unawaited(notifier.stepFontSize(-1)),
                tooltip: l10n.libraryFontDecrease,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Semantics(
                  label: l10n.libraryFontValue(size),
                  child: Text(
                    '$size',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed:
                    atMax ? null : () => unawaited(notifier.stepFontSize(1)),
                tooltip: l10n.libraryFontIncrease,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          SwitchListTile(
            key: const ValueKey('hide-added-switch'),
            contentPadding: EdgeInsets.zero,
            value: view.hideAdded,
            onChanged: (_) => unawaited(notifier.toggleHideAdded()),
            title: Text(l10n.libraryHideAddedLabel),
            subtitle: Text(l10n.libraryHideAddedSubtitle),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          const _TagFilterSection(),
        ],
      ),
    );
  }
}

/// The gallery of group buttons.
///
/// Every tag is offered, whether or not anything currently matches it, so the
/// gallery reads as a fixed index of what the library holds. Selection is
/// additive — picking a second group widens the list rather than replacing
/// the first — which is what a wall of toggle buttons invites you to expect.
/// The popup stays open after a tap so several groups can be picked in one go.
class _TagFilterSection extends ConsumerWidget {
  const _TagFilterSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final view = ref.watch(dhikrLibraryProvider);
    final notifier = ref.read(dhikrLibraryProvider.notifier);
    final selected = view.selectedTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.libraryFilterTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.libraryFilterSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              avatar: const Icon(Icons.select_all, size: 18),
              label: Text(l10n.libraryFilterAll),
              selected: selected.isEmpty,
              // The emoji/icon stays put when a chip is picked; the tinted
              // fill is what says "selected". Swapping in a checkmark would
              // hide the very thing that tells the buttons apart.
              showCheckmark: false,
              onSelected: (_) => notifier.clearTags(),
            ),
            for (final tag in DhikrTag.values)
              FilterChip(
                avatar: Text(tag.emoji),
                label: Text(dhikrTagLabel(l10n, tag)),
                selected: selected.contains(tag),
                showCheckmark: false,
                onSelected: (_) => notifier.toggleTag(tag),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                selected.isEmpty
                    ? l10n.libraryFilterAll
                    : l10n.libraryFilterCount(selected.length),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (selected.isNotEmpty)
              TextButton.icon(
                onPressed: notifier.clearTags,
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: Text(l10n.libraryFilterClear),
              ),
          ],
        ),
      ],
    );
  }
}
