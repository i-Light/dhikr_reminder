import 'dart:async';

import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the "allow display over other apps" pop-up has already been shown
/// since the app started, so coming back from the system settings screen (or
/// to the app from the background) does not ask again.
final overlayPromptShownProvider = NotifierProvider<_PromptShown, bool>(
  _PromptShown.new,
);

class _PromptShown extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() => state = true;
}

/// On a phone, asks once per launch — in a pop-up — for the permission to show
/// reminders over other apps, if it has not been granted. Wraps the app's
/// pages; anywhere else it is a pass-through.
class OverlayPermissionPrompt extends ConsumerStatefulWidget {
  const OverlayPermissionPrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OverlayPermissionPrompt> createState() =>
      _OverlayPermissionPromptState();
}

class _OverlayPermissionPromptState
    extends ConsumerState<OverlayPermissionPrompt> {
  @override
  void initState() {
    super.initState();
    if (ref.read(appPlatformProvider).usesNotifications) {
      unawaited(_askIfNeeded());
    }
  }

  Future<void> _askIfNeeded() async {
    final allowed = await ref.read(overlayAllowedProvider.future);
    if (!mounted || allowed || ref.read(overlayPromptShownProvider)) return;
    ref.read(overlayPromptShownProvider.notifier).markShown();

    final l10n = AppLocalizations.of(context);
    final wantsIt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.layers_outlined),
        title: Text(l10n.overlayPromptTitle),
        content: Text(l10n.overlayPromptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.overlayPromptLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.overlayAllow),
          ),
        ],
      ),
    );
    if (wantsIt ?? false) {
      await ref.read(overlayAllowedProvider.notifier).request();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
