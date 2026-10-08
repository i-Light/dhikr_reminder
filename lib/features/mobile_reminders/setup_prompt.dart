import 'dart:async';

import 'package:dhikr_reminder/features/mobile_reminders/background_access.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_permission_dialog.dart';
import 'package:dhikr_reminder/features/mobile_reminders/overlay_service.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether each pop-up has already been shown since the app started, so coming
/// back from a system settings screen (or to the app from the background) does
/// not ask again. A new launch asks again, for as long as the permission is
/// missing.
final overlayPromptShownProvider = NotifierProvider<_PromptShown, bool>(
  _PromptShown.new,
);

final backgroundPromptShownProvider = NotifierProvider<_PromptShown, bool>(
  _PromptShown.new,
);

class _PromptShown extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() => state = true;
}

/// On a phone, asks once per launch, in a pop-up each, for the two things the
/// reminders need to work: to show over other apps, and to keep running in the
/// background. Wraps the app's pages; anywhere else it is a pass-through.
///
/// A person who says "Not now" is not left alone with it: the same two are
/// shown as red cards on the settings page for as long as they are missing
/// (see `SetupRequirementCards`).
class SetupPrompt extends ConsumerStatefulWidget {
  const SetupPrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SetupPrompt> createState() => _SetupPromptState();
}

class _SetupPromptState extends ConsumerState<SetupPrompt>
    with WidgetsBindingObserver {
  bool _leftTheApp = false;
  Completer<void>? _cameBack;

  @override
  void initState() {
    super.initState();
    if (ref.read(appPlatformProvider).usesNotifications) {
      WidgetsBinding.instance.addObserver(this);
      unawaited(_askIfNeeded());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final cameBack = _cameBack;
      if (cameBack != null && !cameBack.isCompleted) cameBack.complete();
    } else {
      _leftTheApp = true;
    }
  }

  Future<void> _askIfNeeded() async {
    await _askForOverlay();
    if (!mounted) return;
    await _askForBackground();
  }

  Future<void> _askForOverlay() async {
    final allowed = await ref.read(overlayAllowedProvider.future);
    if (!mounted || allowed || ref.read(overlayPromptShownProvider)) return;
    ref.read(overlayPromptShownProvider.notifier).markShown();

    final openedSettings = await askForOverlayPermission(context, ref);
    if (openedSettings) await _waitForReturnFromSettings();
  }

  Future<void> _askForBackground() async {
    final allowed = await ref.read(backgroundAllowedProvider.future);
    if (!mounted || allowed || ref.read(backgroundPromptShownProvider)) return;
    ref.read(backgroundPromptShownProvider.notifier).markShown();

    final l10n = AppLocalizations.of(context);
    final wantsIt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.battery_charging_full),
        title: Text(l10n.batteryPromptTitle),
        content: Text(l10n.batteryPromptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.overlayPromptLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonAllow),
          ),
        ],
      ),
    );
    if ((wantsIt ?? false) && mounted) {
      await ref.read(backgroundAllowedProvider.notifier).request();
    }
  }

  /// If asking sent the person to the system settings, waits for them to come
  /// back before the next question, so it is not asked behind their back.
  Future<void> _waitForReturnFromSettings() async {
    _leftTheApp = false;
    // The app takes a moment to be covered by the screen that was opened.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted || !_leftTheApp) return;
    final cameBack = _cameBack = Completer<void>();
    await cameBack.future;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
