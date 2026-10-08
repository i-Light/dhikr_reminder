import 'dart:async';

import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/requests/application/request_controller.dart';
import 'package:dhikr_reminder/features/requests/domain/request_rules.dart';
import 'package:dhikr_reminder/features/requests/presentation/library_lookup.dart';
import 'package:dhikr_reminder/features/requests/presentation/my_requests_screen.dart';
import 'package:dhikr_reminder/features/requests/presentation/request_messages.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the sheet for asking to have a dhikr added to the library.
/// [initialText] fills the box, for a request that starts from a search.
Future<void> showDhikrRequestSheet(
  BuildContext context, {
  String initialText = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (_) => DhikrRequestSheet(initialText: initialText),
  );
}

enum _Stage { form, exists, own, sent, queued }

/// The request form, and what comes after it: the dhikr turned out to be in the
/// library already, the person had already asked for it, or it was sent (or
/// saved to be sent).
class DhikrRequestSheet extends ConsumerStatefulWidget {
  const DhikrRequestSheet({super.key, this.initialText = ''});

  final String initialText;

  @override
  ConsumerState<DhikrRequestSheet> createState() => _DhikrRequestSheetState();
}

class _DhikrRequestSheetState extends ConsumerState<DhikrRequestSheet> {
  late final _text = TextEditingController(text: widget.initialText);
  final _source = TextEditingController();

  _Stage _stage = _Stage.form;
  String? _error;
  bool _busy = false;
  DhikrItem? _match;
  bool _duplicate = false;

  @override
  void dispose() {
    _text.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _send({bool ignoreLibrary = false}) async {
    final l10n = AppLocalizations.of(context);
    final cleaned = cleanRequestText(_text.text);

    // Offered first, so nobody asks for what is already there.
    if (!ignoreLibrary && checkRequestText(cleaned) == null) {
      final match = findInLibrary(cleaned);
      if (match != null) {
        setState(() {
          _match = match;
          _stage = _Stage.exists;
        });
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = await ref
        .read(dhikrRequestsProvider.notifier)
        .submit(text: _text.text, source: _source.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (outcome) {
        case Refused(:final problem, :final seconds):
          _error = requestProblemMessage(l10n, problem, seconds: seconds);
        case AlreadyRequested():
          _stage = _Stage.own;
        case Submitted(:final duplicate):
          _duplicate = duplicate;
          _stage = _Stage.sent;
        case Queued():
          _stage = _Stage.queued;
      }
    });
  }

  void _openMine() {
    final navigator = Navigator.of(context);
    navigator.pop();
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const MyRequestsScreen()),
      ),
    );
  }

  void _showMatch() {
    final match = _match;
    if (match == null) return;
    showInLibrary(ref, match);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + inset),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_stage) {
          _Stage.form => _form(l10n),
          _Stage.exists => _exists(l10n),
          _Stage.own => _message(
              key: 'own',
              icon: Icons.history,
              title: l10n.requestOwnTitle,
              body: l10n.requestOwnBody,
              primary: FilledButton(
                onPressed: _openMine,
                child: Text(l10n.requestOwnShow),
              ),
            ),
          _Stage.sent => _message(
              key: 'sent',
              icon: Icons.check_circle_outline,
              title: l10n.requestSentTitle,
              body: _duplicate
                  ? l10n.requestDuplicateBody
                  : l10n.requestSentBody,
              primary: FilledButton(
                onPressed: _openMine,
                child: Text(l10n.requestsTitle),
              ),
              secondary: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.requestSentOk),
              ),
            ),
          _Stage.queued => _message(
              key: 'queued',
              icon: Icons.schedule_send_outlined,
              title: l10n.requestQueuedTitle,
              body: l10n.requestQueuedBody,
              primary: FilledButton(
                onPressed: _openMine,
                child: Text(l10n.requestsTitle),
              ),
              secondary: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.requestSentOk),
              ),
            ),
        },
      ),
    );
  }

  Widget _form(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.requestSheetTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          l10n.requestSheetIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('request-text-field'),
          controller: _text,
          autofocus: widget.initialText.isEmpty,
          minLines: 3,
          maxLines: 6,
          maxLength: requestTextMax,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 20,
            height: 1.7,
          ),
          decoration: InputDecoration(
            labelText: l10n.requestTextLabel,
            hintText: l10n.requestTextHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('request-source-field'),
          controller: _source,
          maxLength: requestSourceMax,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            labelText: l10n.requestSourceLabel,
            hintText: l10n.requestSourceHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            key: const ValueKey('request-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('request-send'),
          onPressed: _busy ? null : _send,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Text(_busy ? l10n.requestSending : l10n.requestSend),
        ),
      ],
    );
  }

  Widget _exists(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final match = _match!;
    return Column(
      key: const ValueKey('exists'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.library_books_outlined, size: 40, color: theme.colorScheme.primary),
        const SizedBox(height: 10),
        Text(
          l10n.requestExistsTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.requestExistsBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            match.text,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'NotoSansArabic',
              fontSize: 20,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('request-show-match'),
          onPressed: _showMatch,
          child: Text(l10n.requestExistsShow),
        ),
        TextButton(
          key: const ValueKey('request-send-anyway'),
          onPressed: () {
            setState(() => _stage = _Stage.form);
            unawaited(_send(ignoreLibrary: true));
          },
          child: Text(l10n.requestExistsSendAnyway),
        ),
      ],
    );
  }

  Widget _message({
    required String key,
    required IconData icon,
    required String title,
    required String body,
    required Widget primary,
    Widget? secondary,
  }) {
    final theme = Theme.of(context);
    return Column(
      key: ValueKey(key),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 44, color: theme.colorScheme.primary),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        primary,
        if (secondary != null) secondary,
      ],
    );
  }
}
