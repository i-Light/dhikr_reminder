import 'dart:async';

import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/core/navigation/shell_tab.dart';
import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/application/transliteration_controller.dart';
import 'package:dhikr_reminder/features/library/presentation/report_mistake.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/dhikr_library_card.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/dhikr_tag_label.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/library_popups.dart';
import 'package:dhikr_reminder/features/requests/application/request_controller.dart';
import 'package:dhikr_reminder/features/requests/presentation/my_requests_screen.dart';
import 'package:dhikr_reminder/features/requests/presentation/request_sheet.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How wide the library's content column grows before it stops and centres —
/// wide enough that a long ayah reads as a paragraph rather than as a column
/// of three words, narrow enough that the eye does not have to travel the
/// whole window on a maximised desktop.
const double _contentMaxWidth = 900;

/// موسوعة الأذكار — the searchable library.
///
/// Laid out as a fixed top block (title, the bell and settings buttons, the
/// search box and the result count) over a scrolling list of the entries the
/// current search and filters leave in (see [filteredDhikrProvider]).
class DhikrLibraryScreen extends ConsumerStatefulWidget {
  const DhikrLibraryScreen({super.key});

  @override
  ConsumerState<DhikrLibraryScreen> createState() => _DhikrLibraryScreenState();
}

class _DhikrLibraryScreenState extends ConsumerState<DhikrLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Quietly sends any request that was waiting for a connection and learns
    // how the earlier ones are going, so the news badge is right on arrival.
    Future.microtask(() {
      if (!mounted) return;
      unawaited(ref.read(dhikrRequestsProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(dhikrLibraryProvider);
    final items = ref.watch(filteredDhikrProvider);
    final addedIds = ref.watch(addedLibraryIdsProvider);
    final showTransliteration = ref.watch(showTransliterationProvider);
    final libraryNotifier = ref.read(dhikrLibraryProvider.notifier);
    final canRequest = ref.watch(requestsEnabledProvider);

    // The one direction the text field cannot manage on its own: when the
    // query is changed somewhere else (the empty state's "clear" button), the
    // field has to follow. Listening rather than assigning during build keeps
    // this out of the build phase, where touching the controller would try to
    // rebuild the field mid-build.
    ref.listen(dhikrLibraryProvider.select((v) => v.query), (_, query) {
      if (_searchController.text != query) _searchController.text = query;
    });

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LibraryHeader(view: view),
                if (view.showAddHint) ...[
                  const SizedBox(height: 12),
                  const _AddHintBanner(),
                ],
                const SizedBox(height: 16),
                _LibrarySearchField(
                  controller: _searchController,
                  hasQuery: view.query.isNotEmpty,
                ),
                const SizedBox(height: 8),
                _ResultSummary(view: view, count: items.length),
                Expanded(
                  child: items.isEmpty
                      ? _EmptyState(canRequest: canRequest, query: view.query)
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 4, bottom: 24),
                          // One more row at the end, when requests are
                          // possible: the way to ask for what is not here.
                          itemCount: items.length + (canRequest ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == items.length) {
                              return const _RequestTile();
                            }
                            return DhikrLibraryCard(
                              // Keyed on the entry's own id, so a filter change
                              // that reorders the list reuses the right rows
                              // instead of re-binding every card's state.
                              key: ValueKey(items[index].id),
                              item: items[index],
                              view: view,
                              showTransliteration: showTransliteration,
                              isAdded: addedIds.contains(items[index].id),
                              onToggleReminder: () => libraryNotifier
                                  .toggleExpanded(items[index].id),
                              onLongPress: Features.reportMistake
                                  ? () => reportMistake(
                                        context,
                                        ref,
                                        items[index],
                                      )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The banner the notifications page's "Add dhikr" leads to: say what to do
/// here, and offer the way back.
class _AddHintBanner extends ConsumerWidget {
  const _AddHintBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_alert_outlined,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.libraryAddHintTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(dhikrLibraryProvider.notifier).setAddHint(false),
                  tooltip: l10n.libraryClose,
                  icon: Icon(Icons.close, color: colors.onPrimaryContainer),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: Text(
                l10n.libraryAddHintBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                ref.read(dhikrLibraryProvider.notifier).setAddHint(false);
                ref
                    .read(shellTabProvider.notifier)
                    .show(ShellTab.notifications);
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.libraryAddHintBack),
              style: TextButton.styleFrom(
                foregroundColor: colors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title, subtitle and the buttons: the person's requests, the bell that shows
/// or hides the add buttons on the cards, and the settings and filters.
///
/// The buttons live here rather than in the top block's own row so they stay
/// pinned beside the title at every width — on a phone the subtitle wraps
/// under them rather than pushing them off the edge.
class _LibraryHeader extends ConsumerWidget {
  const _LibraryHeader({required this.view});

  final DhikrLibraryView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canRequest = ref.watch(requestsEnabledProvider);
    final news = ref.watch(dhikrRequestsProvider.select((s) => s.unseenCount));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.libraryTitle, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                l10n.librarySubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // The person's own requests, with a count of the ones that have news.
        if (canRequest)
          IconButton(
            key: const ValueKey('my-requests-button'),
            onPressed: () => unawaited(
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyRequestsScreen(),
                ),
              ),
            ),
            tooltip: l10n.requestsTitle,
            icon: news > 0
                ? Badge.count(
                    count: news,
                    child: const Icon(Icons.inbox_outlined),
                  )
                : const Icon(Icons.inbox_outlined),
          ),
        // The bell: whether the cards offer to add a dhikr to the reminders.
        // Off, they stay compact.
        IconButton(
          key: const ValueKey('add-ui-button'),
          onPressed: ref.read(dhikrLibraryProvider.notifier).toggleAddUi,
          tooltip:
              view.showAddUi ? l10n.libraryAddUiHide : l10n.libraryAddUiShow,
          isSelected: view.showAddUi,
          icon: const Icon(Icons.notifications_none),
          selectedIcon: const Icon(Icons.notifications_active),
        ),
        // A count on the button, so a list that is quietly showing a subset
        // says so without the popup having to be opened to find out.
        IconButton(
          key: const ValueKey('library-settings-button'),
          onPressed: () => unawaited(showDhikrQuickSettings(context)),
          tooltip: l10n.libraryQuickSettings,
          icon: view.activeFilterCount > 0
              ? Badge.count(
                  count: view.activeFilterCount,
                  child: const Icon(Icons.tune),
                )
              : const Icon(Icons.tune),
        ),
      ],
    );
  }
}

/// The search box.
class _LibrarySearchField extends ConsumerWidget {
  const _LibrarySearchField({required this.controller, required this.hasQuery});

  final TextEditingController controller;
  final bool hasQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return TextField(
      controller: controller,
      onChanged: ref.read(dhikrLibraryProvider.notifier).updateQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.librarySearchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: hasQuery
            ? IconButton(
                onPressed: ref.read(dhikrLibraryProvider.notifier).clearQuery,
                tooltip: l10n.librarySearchClear,
                icon: const Icon(Icons.close),
              )
            : null,
      ),
    );
  }
}

/// How many selected filters are named next to the result count before the
/// rest are folded into a "+N" pill.
const int _maxShownTags = 3;

/// A small rounded label for one active filter (or the "+N" for the rest).
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// How many entries the search and filter left, and a way to drop the filter
/// without opening the popup again.
class _ResultSummary extends ConsumerWidget {
  const _ResultSummary({required this.view, required this.count});

  final DhikrLibraryView view;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.libraryResultsCount(count),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // The filters in effect: the first few by name, the rest as one
              // "+N" pill in the same style.
              for (final tag in view.selectedTags.take(_maxShownTags))
                _FilterPill(label: '${tag.emoji} ${dhikrTagLabel(l10n, tag)}'),
              if (view.selectedTags.length > _maxShownTags)
                _FilterPill(
                  label: '+${view.selectedTags.length - _maxShownTags}',
                ),
              if (view.hideAdded) _FilterPill(label: l10n.libraryHidingAdded),
            ],
          ),
        ),
        if (view.hasTagFilter)
          TextButton.icon(
            onPressed: ref.read(dhikrLibraryProvider.notifier).clearTags,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: Text(l10n.libraryFilterClear),
          ),
      ],
    );
  }
}

/// What the list shows when the search and filter match nothing — and the way
/// back out, rather than leaving a blank page and no explanation.
class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.canRequest, required this.query});

  final bool canRequest;

  /// What was searched for, which a request starts from.
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.libraryEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.libraryEmptyHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              final notifier = ref.read(dhikrLibraryProvider.notifier);
              notifier.clearQuery();
              notifier.clearTags();
            },
            child: Text(l10n.libraryEmptyAction),
          ),
          if (canRequest) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const ValueKey('request-from-empty'),
              onPressed: () => unawaited(
                showDhikrRequestSheet(context, initialText: query.trim()),
              ),
              icon: const Icon(Icons.add_comment_outlined),
              label: Text(l10n.requestEmptyAction),
            ),
          ],
        ],
      ),
    );
  }
}

/// The last row of the list: for the dhikr that is not here, a way to ask for
/// it.
class _RequestTile extends StatelessWidget {
  const _RequestTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.add_comment_outlined, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.requestTileTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.requestTileBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              key: const ValueKey('request-from-tile'),
              onPressed: () => unawaited(showDhikrRequestSheet(context)),
              child: Text(l10n.requestTileButton),
            ),
          ],
        ),
      ),
    );
  }
}
