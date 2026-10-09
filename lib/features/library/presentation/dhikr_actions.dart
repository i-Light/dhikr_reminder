import 'dart:async';

import 'package:dhikr_reminder/core/features.dart';
import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/features/library/presentation/report_mistake.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hands a piece of text to the phone's share sheet. Overridden in tests.
abstract class TextSharer {
  /// False when the phone could not open a share sheet.
  Future<bool> share(String text);
}

/// [TextSharer] over the Android side's method channel (see MainActivity).
class ChannelTextSharer implements TextSharer {
  ChannelTextSharer([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('dhikr_reminder/share');

  final MethodChannel _channel;

  @override
  Future<bool> share(String text) async {
    try {
      return await _channel.invokeMethod<bool>('shareText', {'text': text}) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

final textSharerProvider = Provider<TextSharer>((ref) => ChannelTextSharer());

/// What is copied or shared for [item]: its text and its source line, nothing
/// else. Never a count, a streak or anything about the person.
String dhikrShareText(DhikrItem item) {
  final reference = item.reference?.trim() ?? '';
  final text = item.text.trim();
  return reference.isEmpty ? text : '$text\n\n$reference';
}

/// Press and hold a dhikr in the library: a small sheet with what can be done
/// with it. On a phone that is sharing its text (the share sheet has Copy in
/// it); on Windows, copying it. Reporting a mistake in it is the last row.
///
/// A press and hold and not a button on every card on purpose: 281 buttons
/// would make the library look busy for the sake of something done now and then.
Future<void> showDhikrActions(
  BuildContext context,
  WidgetRef ref,
  DhikrItem item,
) async {
  final l10n = AppLocalizations.of(context);
  final onPhone = ref.read(appPlatformProvider).usesNotifications;
  unawaited(HapticFeedback.mediumImpact());
  final choice = await showModalBottomSheet<_DhikrAction>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onPhone)
            ListTile(
              key: const ValueKey('dhikr-share'),
              leading: const Icon(Icons.share_outlined),
              title: Text(l10n.libraryShare),
              onTap: () => Navigator.of(context).pop(_DhikrAction.share),
            )
          else
            ListTile(
              key: const ValueKey('dhikr-copy'),
              leading: const Icon(Icons.copy_rounded),
              title: Text(l10n.libraryCopy),
              onTap: () => Navigator.of(context).pop(_DhikrAction.copy),
            ),
          if (Features.reportMistake)
            ListTile(
              key: const ValueKey('dhikr-report'),
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.libraryReport),
              onTap: () => Navigator.of(context).pop(_DhikrAction.report),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  switch (choice) {
    case _DhikrAction.copy:
      await Clipboard.setData(ClipboardData(text: dhikrShareText(item)));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.libraryCopied),
            duration: const Duration(seconds: 2),
          ),
        );
    case _DhikrAction.share:
      await ref.read(textSharerProvider).share(dhikrShareText(item));
    case _DhikrAction.report:
      await reportMistake(context, ref, item);
  }
}

enum _DhikrAction { copy, share, report }
