import 'package:dhikr_reminder/core/support/bug_report.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The settings page's "Report a bug" row. Tapping it asks what went wrong,
/// then opens a report with that text and the app and device details already
/// filled in (see `bug_report.dart`), for the person to read over and send.
class BugReportCard extends ConsumerWidget {
  const BugReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.bug_report_outlined),
        title: Text(l10n.bugReportTitle),
        subtitle: Text(l10n.bugReportSubtitle),
        trailing: const Icon(Icons.open_in_new, size: 20),
        onTap: () => _report(context, ref),
      ),
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final description = await showDialog<String>(
      context: context,
      builder: (context) => const _BugReportDialog(),
    );
    if (description == null || !context.mounted) return;

    final details = await ref.read(bugReportDetailsProvider)();
    final uri = bugReportUri(description, details);
    final opened = await ref.read(bugReportOpenerProvider)(uri);
    if (opened || !context.mounted) return;

    // No browser to open it in: put the report on the clipboard so it is not
    // lost.
    await Clipboard.setData(
      ClipboardData(text: buildBugReportBody(description, details)),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).bugReportOpenFailed)),
      );
  }
}

class _BugReportDialog extends StatefulWidget {
  const _BugReportDialog();

  @override
  State<_BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends State<_BugReportDialog> {
  final _controller = TextEditingController();
  bool _empty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _empty = true);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      icon: const Icon(Icons.bug_report_outlined),
      title: Text(l10n.bugReportDialogTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          TextField(
            key: const ValueKey('bug-report-field'),
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              labelText: l10n.bugReportDescriptionLabel,
              hintText: l10n.bugReportDescriptionHint,
              errorText: _empty ? l10n.bugReportEmpty : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_empty) setState(() => _empty = false);
            },
          ),
          Text(
            l10n.bugReportDetailsNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.bugReportOpen),
        ),
      ],
    );
  }
}
