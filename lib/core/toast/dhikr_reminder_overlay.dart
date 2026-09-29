import 'dart:async';
import 'dart:math';

import 'package:dhikr_reminder/core/constants/app_colors.dart';
import 'package:dhikr_reminder/core/toast/border_frame.dart';
import 'package:dhikr_reminder/core/toast/dhikr_fit_text.dart';
import 'package:dhikr_reminder/core/toast/dust_particles_overlay.dart';
import 'package:dhikr_reminder/core/toast/outer_glow.dart';
import 'package:dhikr_reminder/core/widgets/mouse_glow_overlay.dart';
import 'package:dhikr_reminder/features/settings/application/dhikr_reminder_controller.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uniform scale for the whole dhikr reminder card — bump this one value to
/// make the entire card (border, text, ring, button, confetti, everything)
/// bigger or smaller together. `1.0` is the original size; the card's width
/// is compensated to stay the same regardless of this value (see
/// `_DhikrReminderCardState.build`'s `width:`), so raising it mainly buys
/// height and bigger content, not a wider card.
const double kDhikrReminderCardScale = 1.2;

class DhikrTimers {
  // Entrance scale/fade and background opacity
  static const Duration cardEntrance = Duration(milliseconds: 200);

  // The quick shrink/expand effect when tapping the card/button
  static const Duration bumpPress = Duration(milliseconds: 500);

  // The speed of the outer glow pulsing effect
  static const Duration glowPulse = Duration(milliseconds: 500);

  // The time it takes for the progress border to catch up
  static const Duration progressFill = Duration(milliseconds: 300);

  // How long the card stays fully mounted after the target's hit before its
  // exit transition begins. This is the longer of [autoDismiss] and
  // [confettiBurst] rather than [autoDismiss] alone — [autoDismiss] alone is
  // a plain reading dwell, and confetti fired alongside it (see
  // `_DhikrReminderCardState.didUpdateWidget`) needs the full
  // [confettiBurst] to play out. Starting the card's exit fade
  // ([cardEntrance], via `AnimatedSwitcher`) any earlier means the burst is
  // still mid-flight when the card starts shrinking away and gets clipped.
  // By the time this delay elapses the confetti has already faded to
  // nothing on its own (particle opacity hits 0 as its progress reaches 1),
  // so the subsequent exit transition needs no further coordination — it
  // finishes destroying the card on its own schedule.
  static Duration get dismissDelay =>
      confettiBurst > autoDismiss ? confettiBurst : autoDismiss;

  // Background holy dust movement/animation speed
  static const Duration dustParticles = Duration(seconds: 5);

  // Auto-dismiss delay after the target is reached
  static const Duration autoDismiss = Duration(milliseconds: 2000);

  // The duration of the confetti burst animation
  static const Duration confettiBurst = Duration(milliseconds: 2000);

  // The transition duration for resizing the card and glowing layers
  static const Duration layoutTransition = Duration(milliseconds: 1500);

  // The slide and fade duration for the count text
  static const Duration countSlide = Duration(milliseconds: 320);
}

/// Every color the reminder card paints with, derived once per build from
/// the theme and whether the target's been hit. Kept in one place so a
/// future color tweak means editing a field here, not hunting through the
/// widget tree for the right `.withValues(alpha: ...)`.
@immutable
class DhikrPalette {
  const DhikrPalette({
    required this.accent,
    required this.cardFill,
    required this.progressTrack,
  });

  /// The one color everything else (border, shadow, progress stroke, done
  /// text) keys off — the brand gradient's first stop, or flat green once
  /// complete.
  final Color accent;

  /// The card's own background: the brand gradient blended faintly into the
  /// surface color, so it's a single opaque fill rather than a translucent
  /// layer stacked over one.
  final Gradient cardFill;

  /// The progress ring's unfilled track.
  final Color progressTrack;

  /// Flat green — the one moment this card should read as "done", not
  /// "brand".
  static const _doneGradient = LinearGradient(
    colors: [
      Color.fromARGB(80, 52, 211, 153),
      Color.fromARGB(190, 22, 163, 74)
    ],
  );
  static const _normalGradient = LinearGradient(
    colors: [
      Color.fromARGB(181, 144, 104, 47),
      Color.fromARGB(195, 190, 140, 60),
      Color.fromARGB(190, 150, 100, 40),
      Color.fromARGB(195, 105, 70, 30),
      Color.fromARGB(215, 55, 38, 18),
    ],
    stops: [0.0, 0.45, 0.65, 0.85, 1.0],
  );
  //LIGHT MODE
  // colors: [
  //   Color.fromARGB(160, 255, 231, 170), // pale gold highlight
  //   Color.fromARGB(180, 255, 200, 110), // warm gold
  //   Color.fromARGB(200, 255, 185, 80), // bright sheen streak
  //   Color.fromARGB(190, 235, 155, 50), // rich amber gold
  //   Color.fromARGB(175, 180, 100, 30), // warm bronze
  //   Color.fromARGB(200, 110, 65, 20), // deep gold-brown shadow
  // ],
  // stops: [0.0, 0.2, 0.45, 0.65, 0.85, 1.0],

  // Not `of(context)`: nothing here reads the theme. The palette is a fixed
  // gold scheme that only changes shape between "in progress" and "done", so
  // passing a BuildContext through it would be a lie about what varies.
  factory DhikrPalette.forState({required bool isComplete}) {
    final brand = isComplete ? _doneGradient : _normalGradient;
    final accent = isComplete
        ? brand.colors.first.withValues(alpha: 1)
        : const Color.fromARGB(255, 231, 170, 72);

    return DhikrPalette(
      progressTrack: accent.withValues(alpha: 0.3),
      accent: accent,
      cardFill: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: brand.colors,
        stops: brand.stops,
        // [
        //   Color.alphaBlend(
        //       brand.colors[0].withValues(alpha: gradientAlpha * 2), surface),
        //   for (final color in brand.colors.skip(1))
        //     Color.alphaBlend(
        //         color.a != 1.0 ? color : color.withValues(alpha: gradientAlpha),
        //         surface),
        // ],
      ),
    );
  }
}

/// Hosts the floating dhikr-reminder card above [child] — mounted once at
/// the app root next to `ToastOverlay` (see `app.dart`), so a reminder fired
/// from anywhere lands at the same top-center spot regardless of which page
/// is underneath. Unlike `ToastOverlay` there's only ever one of these on
/// screen at a time, so it's a single card rather than an animated stack.
///
/// Also the one place `dhikrReminderSchedulerProvider` gets watched — that
/// notifier's state (the next due time) is for the tray menu, not for this
/// widget to render; what matters here is the side-effecting `Timer` in its
/// `build()`, but a `NotifierProvider` still needs a live listener to stay
/// built at all, so watching it here (selecting nothing, so a new due time
/// does not rebuild the overlay) is what keeps the reminder timer running for
/// the app's lifetime.
class DhikrReminderOverlay extends ConsumerStatefulWidget {
  const DhikrReminderOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DhikrReminderOverlay> createState() =>
      _DhikrReminderOverlayState();
}

class _DhikrReminderOverlayState extends ConsumerState<DhikrReminderOverlay> {
  Timer? _autoDismissTimer;

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dhikrReminderSchedulerProvider.select((_) => null));
    final reminder = ref.watch(activeDhikrReminderProvider);

    // Reaching the target count is a state change, not a user action, so
    // there's no tap to hang the dismiss off — give it a beat to register
    // the checkmark and confetti, then clear itself the same way a toast's
    // own timer would. That beat is `DhikrTimers.dismissDelay`, not
    // `autoDismiss` alone, so the card doesn't start fading out — and
    // clipping the confetti — before the burst has actually finished.
    ref.listen(activeDhikrReminderProvider, (previous, next) {
      _autoDismissTimer?.cancel();
      if (next != null && next.isComplete) {
        // Start destroying (calling dismiss(), which flips the provider to
        // null and lets `AnimatedSwitcher` begin the card's exit transition)
        // only once both the confetti burst and the plain reading dwell have
        // had their say — see `DhikrTimers.dismissDelay`.
        _autoDismissTimer = Timer(DhikrTimers.dismissDelay, () {
          ref.read(activeDhikrReminderProvider.notifier).dismiss();
        });
      }
    });

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: reminder == null,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(children: [
                  AnimatedOpacity(
                    // 1. Match the duration of your dialog animation
                    duration: DhikrTimers.cardEntrance,
                    // 2. Fade to 0 when reminder is null, 1 when active
                    opacity: reminder == null ? 0.0 : 1.0,
                    // 3. Prevent the invisible layer from blocking taps when hidden
                    child: IgnorePointer(
                      ignoring: reminder == null,
                      child: Container(
                        color: AppColors.primaryDark.withAlpha(180),
                        // Gated on `reminder` rather than left mounted and
                        // faded: `AnimatedOpacity` above only changes this
                        // layer's alpha, and `HolyDustBackground` drives a
                        // `.repeat()`ing AnimationController. Left alone it
                        // would repaint every particle, every frame, for the
                        // whole session — an always-running animation for a
                        // background that is only ever visible while a
                        // reminder is on screen.
                        child: reminder == null
                            ? const SizedBox.shrink()
                            : const HolyDustBackground(
                                particleCount: 15,
                              ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: DhikrTimers.cardEntrance,
                      // The scale+fade the switcher always ran, routed
                      // through [_SnapshotExitTransition] so the *exit*
                      // plays against a frozen texture of the card instead
                      // of re-rasterizing the whole card (glow blurs, text
                      // shadows, SVG frame and all) on every frame of the
                      // fade — see the class docs below.
                      transitionBuilder: (child, animation) =>
                          _SnapshotExitTransition(
                        animation: animation,
                        child: child,
                      ),
                      child: reminder == null
                          ? const SizedBox.shrink(key: ValueKey('empty'))
                          : _DhikrReminderCard(
                              key: ValueKey(reminder.entry.id),
                              reminder: reminder,
                              maxWidth: constraints.maxWidth,
                              maxHeight: constraints.maxHeight,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(activeDhikrReminderProvider.notifier)
                                    .increment();
                              },
                              onDismiss: () => ref
                                  .read(activeDhikrReminderProvider.notifier)
                                  .dismiss(),
                            ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Wraps [child] in the reminder card's exit transition — the same
/// scale+fade `AnimatedSwitcher` always ran — but freezes the card to a
/// texture the instant its exit begins.
///
/// The switcher gives every child its own animation: it runs forward while
/// the child enters and in reverse while it exits. On the first
/// `AnimationStatus.reverse`, this widget flips its [SnapshotWidget]
/// controller on, and the snapshot render object captures the card into a
/// `ui.Image` during that frame's paint. From then on the scale and fade
/// composite a single texture instead of re-running the card's glow blurs,
/// text shadows, SVG frame and everything else on every frame of the exit —
/// GPU cost drops to a texture draw, and the visual is identical because the
/// card isn't supposed to change while leaving. Any animation still ticking
/// inside the card is simply frozen with it (that's `SnapshotWidget`'s
/// documented behaviour for short transitions).
///
/// The capture sits *below* the scale and fade, so what it records is the
/// untransformed card — the transition math is untouched.
class _SnapshotExitTransition extends StatefulWidget {
  const _SnapshotExitTransition({
    required this.animation,
    required this.child,
  });

  /// This child's switcher animation: forward on entry, reverse on exit.
  final Animation<double> animation;

  final Widget child;

  @override
  State<_SnapshotExitTransition> createState() =>
      _SnapshotExitTransitionState();
}

class _SnapshotExitTransitionState extends State<_SnapshotExitTransition> {
  final SnapshotController _snapshot = SnapshotController();

  /// The scale curve, created once in [initState] and disposed in [dispose]
  /// because [CurvedAnimation] registers a status listener on its parent for
  /// its lifetime (see its own docs). Never changes for a given switcher
  /// entry — the switcher reuses one animation per child for its whole
  /// life, entry included.
  late final CurvedAnimation _scale;

  @override
  void initState() {
    super.initState();
    _scale = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    widget.animation.addStatusListener(_handleStatus);
  }

  void _handleStatus(AnimationStatus status) {
    // Reverse is the exit (forward is the entrance). Flipping the controller
    // here — still in the frame's build phase — makes the snapshot render
    // object capture the freshly painted card in this same frame's paint, so
    // there is never a half-captured frame.
    if (status == AnimationStatus.reverse &&
        !_snapshot.allowSnapshotting &&
        mounted) {
      _snapshot.allowSnapshotting = true;
    }
  }

  @override
  void dispose() {
    // Both removals are safe even if the switcher already disposed its
    // animation first — listeners may be removed from a disposed animation,
    // and [SnapshotController]'s render object does the same with ours.
    widget.animation.removeStatusListener(_handleStatus);
    _scale.dispose();
    _snapshot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.88, end: 1).animate(_scale),
      child: FadeTransition(
        opacity: widget.animation,
        child: SnapshotWidget(
          // Off until an exit starts; the switcher's reverse status turns it
          // on above. Re-captures instead of stretching if the card is mid
          // layout transition when the exit begins.
          autoresize: true,
          controller: _snapshot,
          child: widget.child,
        ),
      ),
    );
  }
}

/// The card itself: the dhikr's text on a big circular clicker, a progress
/// ring toward `DhikrEntry.amount` when it has one, and a running count
/// below. Visually a bigger, single-purpose cousin of `ToastCard` — same
/// surface color, border and shadow language, scaled up for something
/// meant to be tapped dozens of times rather than just read.
///
/// Every tap gets a quick squash-and-settle bounce and the progress ring
/// eases toward its new value rather than jumping, so the count climbing
/// toward the target reads as motion rather than a series of snapshots.
/// Crossing the target flips the accent to a celebratory green and fires a
/// one-shot confetti burst from the center of the ring.
class _DhikrReminderCard extends StatefulWidget {
  const _DhikrReminderCard({
    super.key,
    required this.reminder,
    required this.maxWidth,
    required this.maxHeight,
    required this.onTap,
    required this.onDismiss,
  });

  final ActiveDhikrReminder reminder;
  final double maxWidth;
  final double maxHeight;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  State<_DhikrReminderCard> createState() => _DhikrReminderCardState();
}

class _DhikrReminderCardState extends State<_DhikrReminderCard>
    with TickerProviderStateMixin {
  late final AnimationController _bumpController = AnimationController(
    vsync: this,
    duration: DhikrTimers.bumpPress,
  );
  late final Animation<double> _bump = TweenSequence<double>([
    TweenSequenceItem(
      tween:
          Tween(begin: 1.0, end: 0.7).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.7, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_bumpController);

  // Own controller for the duplicated "biggest" glow's pulse, timed off
  // `DhikrTimers.glowPulse` rather than piggybacking on `_bumpController`'s
  // `bumpPress` duration — triggered on the same tap as `_bump`, but free to
  // run at its own speed.
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: DhikrTimers.glowPulse,
  );

  // Drives the duplicated glow as an opacity ramp rather than a scale: it
  // jumps from invisible up to its full strength on tap, then eases back
  // down to invisible, so a tap reads as the glow flashing outward rather
  // than growing. The other glow layers are isolated from this animation
  // and stay at their static, state-driven alpha.
  late final Animation<double> _glowOpacity = TweenSequence<double>([
    TweenSequenceItem(
      tween:
          Tween(begin: 0.4, end: 0.9).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween:
          Tween(begin: 0.9, end: 0.4).chain(CurveTween(curve: Curves.easeIn)),
      weight: 65,
    ),
  ]).animate(_glowController);

  // Own controller for the main dhikr text's extra glow flash — same
  // tap trigger as `_glowController`, but scoped to the text's own shadow
  // stack instead of the card's outer glow, and free to run at its own
  // speed independent of it.
  late final AnimationController _textGlowController = AnimationController(
    vsync: this,
    duration: DhikrTimers.glowPulse,
  );

  // Same jump-up-then-ease-back-down shape as `_glowOpacity`: invisible on
  // rest, flashes up to full strength on tap, then eases back down. This
  // drives the alpha of one extra `Shadow` layered on top of the text's
  // static shadows below, rather than a `FadeTransition`.
  late final Animation<double> _textGlowOpacity = TweenSequence<double>([
    TweenSequenceItem(
      tween:
          Tween(begin: 0.0, end: 0.4).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween:
          Tween(begin: 0.4, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
      weight: 65,
    ),
  ]).animate(_textGlowController);

  late final AnimationController _confettiController = AnimationController(
    vsync: this,
    duration: DhikrTimers.confettiBurst,
  );
  late final List<_ConfettiParticle> _particles =
      _ConfettiParticle.generate(16);

  /// Falloff sprites shared by the card's two outer-glow layers (glow
  /// layer 1 and 1b), so the 60-blur shape is baked once and drawn twice.
  /// Owned here so the images are disposed with the card.
  final GlowSpriteStore _glowSprites = GlowSpriteStore();

  @override
  void didUpdateWidget(covariant _DhikrReminderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reminder.count != oldWidget.reminder.count) {
      _bumpController.forward(from: 0);
      _glowController.forward(from: 0);
      _textGlowController.forward(from: 0);
    }
    if (widget.reminder.isComplete && !oldWidget.reminder.isComplete) {
      _confettiController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bumpController.dispose();
    _glowController.dispose();
    _textGlowController.dispose();
    _confettiController.dispose();
    _glowSprites.dispose();
    super.dispose();
  }

  double _s(double value) => value * kDhikrReminderCardScale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reminder = widget.reminder;
    final entry = reminder.entry;
    final progress = reminder.hasTarget ? reminder.count / entry.amount : null;

    final palette = DhikrPalette.forState(isComplete: reminder.isComplete);
    final accent = palette.accent;

    // Everything about the dhikr text that affects its layout, minus the size:
    // [DhikrFitText] measures with this and solves for the size itself.
    final dhikrTextStyle = (theme.textTheme.displayLarge ?? const TextStyle())
        .copyWith(fontFamily: 'Naksh', wordSpacing: 12, height: 1.6);

    final widgetWidth = widget.maxWidth * 0.75;
    final widgetHeight = widget.maxHeight * 0.75;

    // The glow layers bake their sprites at the current display density;
    // re-set on every build so a density change re-bakes them (see
    // [GlowSpriteStore.devicePixelRatio]).
    _glowSprites.devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: reminder.isComplete ? null : widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Isolated Background Glow Layer — static, no longer tied to
            // the tap animation. Its own alpha still reacts to `isComplete`
            // via the eased transition below, but nothing here scales or
            // fades on tap anymore.
            //
            // The three outer-blur shadows it used to paint through an
            // `AnimatedContainer` decoration are drawn by
            // [AmbientGlowPainter] instead: at rest every shadow is a
            // pre-rendered sprite from [_glowSprites], so the frames the
            // dust ticker keeps producing re-draw textures rather than
            // re-running screen-sized gaussian blur passes — only the 1.5s
            // `isComplete` ease itself still paints the lerped decoration
            // live, which is exactly what AnimatedContainer recorded before.
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                // Carries the `isComplete` ease that AnimatedContainer used
                // to give this layer: 0 while the reminder is in progress,
                // eased to 1 once complete. `begin` mirrors `end` so nothing
                // animates on the first frame, and TweenAnimationBuilder
                // retargets from wherever it currently is, exactly like the
                // implicit AnimatedContainer did.
                tween: Tween<double>(
                  begin: reminder.isComplete ? 1.0 : 0.0,
                  end: reminder.isComplete ? 1.0 : 0.0,
                ),
                duration: DhikrTimers.layoutTransition,
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) {
                  return CustomPaint(
                    painter: AmbientGlowPainter(
                      store: _glowSprites,
                      accent: accent,
                      progress: progress,
                    ),
                  );
                },
              ),
            ),
            // 1b. Duplicated biggest glow (the blurRadius: 60 shadow above),
            // whose strength pulses from 0.4 up to its max and back on every
            // tap. The pulse rides the shadow's own alpha rather than a
            // `FadeTransition` around this container: a composited opacity
            // layer over a decoration that paints *only* an outer-blur shadow
            // makes Impeller break on
            // "Contents::SetInheritedOpacity should never be called when
            // Contents::CanAcceptOpacity returns false" once per frame — see
            // impeller_investigation.md. Folding the same value into the
            // shadow's colour is visually equivalent and costs no layer.
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                // Carries the `isComplete` ease that `AnimatedContainer` used to
                // give this shadow: 1 while the reminder is open, eased down to
                // 0 once it is completed. `begin` mirrors `end` so nothing
                // animates on the first frame, and TweenAnimationBuilder
                // retargets from wherever it currently is, so a tap pulse
                // mid-flight never restarts this ease.
                tween: Tween(
                  begin: reminder.isComplete ? 0.0 : 1.0,
                  end: reminder.isComplete ? 0.0 : 1.0,
                ),
                duration: DhikrTimers.layoutTransition,
                curve: Curves.easeOutCubic,
                builder: (context, completion, _) {
                  return AnimatedBuilder(
                    animation: _glowController,
                    // The pulse reads the controller's value directly on each
                    // frame — exactly what `FadeTransition` used to apply to the
                    // whole layer — so the flash keeps its 180ms attack instead
                    // of being re-eased.
                    builder: (context, _) {
                      return CustomPaint(
                        // No blur pass: the 60-blur halo is the baked
                        // sprite, re-tinted every frame the pulse or the
                        // completion ease moves (see [PulseGlowPainter]).
                        painter: PulseGlowPainter(
                          store: _glowSprites,
                          accent: accent,
                          alpha: completion * _glowOpacity.value,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // 2. Foreground Card Layer
            AnimatedContainer(
              clipBehavior: Clip.antiAlias,
              duration: DhikrTimers.layoutTransition,
              curve: Curves.easeOutCubic,
              width: widgetWidth,
              height: widgetHeight,
              decoration: BoxDecoration(
                gradient: palette.cardFill,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: accent, width: 2),
              ),
              child: MouseGlow(
                  child: Padding(
                padding: EdgeInsets.fromLTRB(_s(30), _s(20), _s(30), _s(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      spacing: 16,
                      children: [
                        Icon(
                          Icons.dark_mode,
                          color: accent,
                        ),
                        Text(
                          l10n.dhikrReminderTitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: accent,
                            fontSize: _s(16),
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        ScaleTransition(
                          scale: _bump,
                          child: TweenAnimationBuilder<double>(
                            duration: DhikrTimers.progressFill,
                            curve: Curves.easeOutCubic,
                            tween: Tween(
                              begin: 0,
                              end: progress == null
                                  ? 1.0
                                  : progress.clamp(0.0, 1.0),
                            ),
                            builder: (context, value, child) {
                              return CustomPaint(
                                painter: _RRectProgressPainter(
                                  progress: value,
                                  color: Color.lerp(accent,
                                          theme.colorScheme.onSurface, 0.2) ??
                                      accent,
                                  trackColor: palette.progressTrack,
                                  strokeWidth: 4,
                                ),
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withAlpha(150),
                                    Colors.transparent,
                                  ],
                                  stops: const [0, 1],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              child: _AnimatedCount(
                                count: reminder.count,
                                amount:
                                    reminder.hasTarget ? entry.amount : null,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: reminder.isComplete ? accent : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: widget.onDismiss,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: _s(22),
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _s(30)),
                    Expanded(
                      child: DynamicOrnateCard(
                        goldColor: accent.withAlpha(70),
                        nominalCornerSize: const Size.square(120),
                        cornerPath: 'assets/images/frame_corner.svg',
                        centerBumpAnimation: _bump,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Align(
                            //   alignment: Alignment.topCenter,
                            //   child: Text(entry.name.length.toString()),
                            // ),
                            // The three `Shadow`s below are the text's static,
                            // state-driven glow. `AnimatedBuilder` here layers
                            // one extra `Shadow` on top of them, whose alpha
                            // and blur ride `_textGlowOpacity` — invisible at
                            // rest, flashing outward on every tap the same
                            // way the card's own `_glowOpacity` flashes the
                            // outer card glow, but with its own controller so
                            // it's free to be tuned independently later.
                            DhikrFitText(
                              text: entry.name,
                              style: dhikrTextStyle,
                              // Keeps the text clear of the corner ornaments
                              // and the "touch anywhere" hint pinned to the
                              // frame's bottom edge.
                              reserve: const EdgeInsets.symmetric(vertical: 24),
                              builder: (context, fontSize) => AnimatedBuilder(
                                animation: _textGlowController,
                                builder: (context, _) {
                                  final glowColor = !reminder.isComplete
                                      ? const Color.fromARGB(255, 255, 215, 128)
                                      : accent;
                                  return Text(
                                    entry.name,
                                    textAlign: TextAlign.center,
                                    textScaler: TextScaler.noScaling,
                                    style: dhikrTextStyle.copyWith(
                                      fontSize: fontSize,
                                      shadows: [
                                        Shadow(
                                          color: (!reminder.isComplete
                                                  ? const Color(0xFFE8B058)
                                                  : accent)
                                              .withValues(alpha: 0.85),
                                          blurRadius: 10,
                                        ),
                                        Shadow(
                                          color: (!reminder.isComplete
                                                  ? const Color(0xFFD48B28)
                                                  : accent)
                                              .withValues(alpha: 0.60),
                                          blurRadius: 24,
                                        ),
                                        Shadow(
                                          color: (!reminder.isComplete
                                                  ? const Color(0xFFB36715)
                                                  : accent)
                                              .withValues(alpha: 0.35),
                                          blurRadius: 30,
                                        ),
                                        Shadow(
                                          offset: const Offset(-3, -12),
                                          color: glowColor.withValues(
                                            alpha: 0.6 + _textGlowOpacity.value,
                                          ),
                                          blurRadius: 60,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _confettiController,
                                builder: (context, _) => CustomPaint(
                                  size: Size(widgetWidth, widgetHeight),
                                  painter: _ConfettiPainter(
                                    progress: _confettiController.value,
                                    particles: _particles,
                                    scale: kDhikrReminderCardScale + 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rolls the digits of [count] (and `/ [amount]` when there's a target) with
/// a quick slide-up-and-fade rather than snapping to the new text, so each
/// tap's progress registers as a small piece of motion instead of a static
/// label update.
class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({required this.count, required this.amount, this.style});

  final int count;
  final int? amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final text = amount == null ? '$count' : '$count / $amount';
    return AnimatedSwitcher(
      duration: DhikrTimers.countSlide,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Text(text, key: ValueKey(text), style: style),
    );
  }
}

/// A single confetti flake's fixed launch parameters, rolled once per burst
/// so the same shape/color/direction is reused across every animation frame
/// instead of re-randomized each build.
class _ConfettiParticle {
  _ConfettiParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.spin,
    required this.delay,
  });

  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double spin;
  final double delay;

  static const _colors = [
    Color(0xFF2ECC71),
    Color(0xFFF1C40F),
    Color(0xFFE74C3C),
    Color(0xFF3498DB),
    Color(0xFFE67E22),
    Color(0xFF9B59B6),
  ];

  static List<_ConfettiParticle> generate(int count) {
    final random = Random();
    return List.generate(count, (i) {
      return _ConfettiParticle(
        angle: random.nextDouble() * 2 * pi,
        distance: 60 + random.nextDouble() * 50,
        size: 4 + random.nextDouble() * 4,
        color: _colors[random.nextInt(_colors.length)],
        spin: (random.nextDouble() - 0.5) * 10,
        delay: random.nextDouble() * 0.25,
      );
    });
  }
}

/// Paints [particles] flying outward and falling from the ring's center as
/// [progress] runs 0 → 1, fading out toward the end of the burst.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.particles,
    this.scale = 1,
  });

  final double progress;
  final List<_ConfettiParticle> particles;

  /// Scales each particle's travel distance and size to match
  /// [kDhikrReminderCardScale] — otherwise the burst stays pinned to its
  /// original 168px-circle radius while the ring around it grows.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    for (final particle in particles) {
      final localT =
          ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final eased = Curves.easeOut.transform(localT);
      final dx = cos(particle.angle) * particle.distance * scale * eased;
      final dy = sin(particle.angle) * particle.distance * scale * eased * 0.6 +
          130 * scale * eased * eased;
      final opacity = (1 - localT).clamp(0.0, 1.0);
      final paint = Paint()..color = particle.color.withValues(alpha: opacity);
      final position = center + Offset(dx, dy);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.spin * progress * pi);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 1.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RRectProgressPainter extends CustomPainter {
  const _RRectProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 2.0,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Inset by half the stroke width so the stroke stays fully within bounds
    final halfStroke = -strokeWidth * 0.5;
    final rect = Rect.fromLTWH(
      halfStroke,
      halfStroke,
      size.width + strokeWidth * 0.5,
      size.height + strokeWidth * 0.5,
    );
    const radii = Radius.circular(20);

    final path = Path();
    // Start at top-center for clean clockwise progress filling
    path.moveTo(rect.center.dx, rect.top);
    path.lineTo(rect.right - radii.x, rect.top);
    path.arcToPoint(Offset(rect.right, rect.top + radii.y), radius: radii);
    path.lineTo(rect.right, rect.bottom - radii.y);
    path.arcToPoint(Offset(rect.right - radii.x, rect.bottom), radius: radii);
    path.lineTo(rect.left + radii.x, rect.bottom);
    path.arcToPoint(Offset(rect.left, rect.bottom - radii.y), radius: radii);
    path.lineTo(rect.left, rect.top + radii.y);
    path.arcToPoint(Offset(rect.left + radii.x, rect.top), radius: radii);
    path.close();

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      final metrics = path.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final extractPath = metric.extractPath(0, metric.length * progress);
        canvas.drawPath(extractPath, progressPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RRectProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
