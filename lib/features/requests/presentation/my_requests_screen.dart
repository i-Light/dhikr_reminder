import 'dart:async';

import 'package:dhikr_reminder/features/library/data/dhikr_library.dart';
import 'package:dhikr_reminder/features/requests/application/request_controller.dart';
import 'package:dhikr_reminder/features/requests/domain/dhikr_request.dart';
import 'package:dhikr_reminder/features/requests/presentation/library_lookup.dart';
import 'package:dhikr_reminder/features/requests/presentation/request_messages.dart';
import 'package:dhikr_reminder/features/requests/presentation/request_sheet.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The person's requests and how each one is going.
///
/// Opening it asks the service for the latest, and whatever changed since the
/// last visit is highlighted for this visit and then counts as seen.
class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  /// The requests that were news when the page opened, kept highlighted while
  /// it is open even though they are marked as seen right away.
  Set<String> _news = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    final notifier = ref.read(dhikrRequestsProvider.notifier);
    await notifier.loaded;
    if (!mounted) return;
    _news = {
      for (final r in ref.read(dhikrRequestsProvider).requests)
        if (r.unseen) r.localId,
    };
    await notifier.markAllSeen();
    if (!mounted) return;
    await notifier.refresh(force: true);
    if (!mounted) return;
    // What the refresh turned up is news too.
    setState(() {
      _news = {
        ..._news,
        for (final r in ref.read(dhikrRequestsProvider).requests)
          if (r.unseen) r.localId,
      };
    });
    await notifier.markAllSeen();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(dhikrRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.requestsTitle),
        actions: [
          if (state.isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: l10n.requestsRefresh,
              onPressed: () => unawaited(
                ref.read(dhikrRequestsProvider.notifier).refresh(force: true),
              ),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(showDhikrRequestSheet(context)),
        icon: const Icon(Icons.add),
        label: Text(l10n.requestsNewButton),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: state.requests.isEmpty
                ? _Empty(loaded: state.isLoaded)
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(dhikrRequestsProvider.notifier)
                        .refresh(force: true),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                      children: [
                        Text(
                          l10n.requestsSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final request in state.requests)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RequestCard(
                              key: ValueKey(request.localId),
                              request: request,
                              isNews: _news.contains(request.localId),
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

class _Empty extends StatelessWidget {
  const _Empty({required this.loaded});

  final bool loaded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (!loaded) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(l10n.requestsEmptyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.requestsEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// One request: its status, the words, and a sentence that thanks the person
/// or explains what happened.
class _RequestCard extends ConsumerWidget {
  const _RequestCard({super.key, required this.request, required this.isNews});

  final DhikrRequest request;
  final bool isNews;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final item =
        request.libraryId == null ? null : libraryItemById(request.libraryId!);
    final tone = switch (request.status) {
      RequestStatus.queued => colors.outline,
      RequestStatus.pending => colors.secondary,
      RequestStatus.inProgress => colors.tertiary,
      RequestStatus.done => colors.primary,
      RequestStatus.declined => colors.onSurfaceVariant,
    };
    final icon = switch (request.status) {
      RequestStatus.queued => Icons.schedule_send_outlined,
      RequestStatus.pending => Icons.hourglass_empty,
      RequestStatus.inProgress => Icons.edit_note,
      RequestStatus.done => Icons.check_circle,
      RequestStatus.declined => Icons.info_outline,
    };

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNews
            ? BorderSide(color: colors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: tone),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    requestStatusLabel(l10n, request.status),
                    style: theme.textTheme.titleSmall?.copyWith(color: tone),
                  ),
                ),
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatShortDate(request.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'NotoSansArabic',
                fontSize: 20,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              requestNote(l10n, request, inLibrary: item != null),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            if (request.votes > 1 && request.status.isOpen) ...[
              const SizedBox(height: 4),
              Text(
                l10n.requestVotes(request.votes),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                if (item != null)
                  TextButton.icon(
                    onPressed: () {
                      showInLibrary(ref, item);
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(l10n.requestShowInLibrary),
                  ),
                if (request.canRemove)
                  TextButton.icon(
                    onPressed: () => unawaited(
                      ref
                          .read(dhikrRequestsProvider.notifier)
                          .forget(request.localId),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.requestRemove),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
