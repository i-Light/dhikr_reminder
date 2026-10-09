import 'dart:async';

import 'package:dhikr_reminder/core/support/bug_report.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Press and hold a dhikr in the library: asks once whether to report a mistake
/// in it, then opens a ready GitHub issue (labelled `content`) with the entry's
/// id, text and source and the app version. Nothing leaves the device until the
/// person presses Submit on GitHub, and it needs no server of ours.
///
/// A long press and not a button on every card on purpose: 281 buttons would
/// make the library look busy to everyone for the sake of the rare typo.
Future<void> reportMistake(
  BuildContext context,
  WidgetRef ref,
  DhikrItem item,
) async {
  final l10n = AppLocalizations.of(context);
  unawaited(HapticFeedback.mediumImpact());
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.reportMistakeTitle),
      content: Text(l10n.reportMistakeBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.reportMistakeSend),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return;

  final details = await ref.read(bugReportDetailsProvider)();
  final uri = contentReportUri(
    id: item.id,
    text: item.text,
    reference: item.reference,
    details: details,
  );
  final opened = await ref.read(bugReportOpenerProvider)(uri);
  if (opened || !context.mounted) return;

  await Clipboard.setData(ClipboardData(text: uri.toString()));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(l10n.reportMistakeOpenFailed)));
}
