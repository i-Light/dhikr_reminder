import 'dart:async';

import 'package:dhikr_reminder/features/library/application/library_controller.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/dhikr_library_card.dart';
import 'package:dhikr_reminder/features/library/presentation/widgets/library_popups.dart';
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
/// Laid out as a fixed top block (title, the two popup buttons, the search
/// box and the result count) over a scrolling list of the entries the current
/// search and tag filter leave in (see [filteredDhikrProvider]).
class DhikrLibraryScreen extends ConsumerStatefulWidget {
  const DhikrLibraryScreen({super.key});

  @override
  ConsumerState<DhikrLibraryScreen> createState() => _DhikrLibraryScreenState();
}

class _DhikrLibraryScreenState extends ConsumerState<DhikrLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(dhikrLibraryProvider);
    final items = ref.watch(filteredDhikrProvider);

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
                const SizedBox(height: 16),
                _LibrarySearchField(
                  controller: _searchController,
                  hasQuery: view.query.isNotEmpty,
                ),
                const SizedBox(height: 8),
                _ResultSummary(view: view, count: items.length),
                Expanded(
                  child: items.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 4, bottom: 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => DhikrLibraryCard(
                            // Keyed on the entry's own id, so a filter change
                            // that reorders the list reuses the right rows
                            // instead of re-binding every card's state.
                            key: ValueKey(items[index].id),
                            item: items[index],
                            view: view,
                          ),
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

/// Title, subtitle and the two popup buttons.
///
/// The buttons live here rather than in the top block's own row so they stay
/// pinned beside the title at every width — on a phone the subtitle wraps
/// under them rather than pushing them off the edge.
class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.view});

  final DhikrLibraryView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
        IconButton(
          onPressed: () => unawaited(showDhikrQuickSettings(context)),
          tooltip: l10n.libraryQuickSettings,
          icon: const Icon(Icons.tune),
        ),
        // A count on the filter button, so a list that is quietly showing a
        // subset says so without the popup having to be opened to find out.
        IconButton(
          onPressed: () => unawaited(showDhikrTagFilter(context)),
          tooltip: l10n.libraryFilterTitle,
          icon: view.hasTagFilter
              ? Badge.count(
                  count: view.selectedTags.length,
                  child: const Icon(Icons.filter_list),
                )
              : const Icon(Icons.filter_list),
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
          child: Text(
            l10n.libraryResultsCount(count),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
  const _EmptyState();

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
        ],
      ),
    );
  }
}