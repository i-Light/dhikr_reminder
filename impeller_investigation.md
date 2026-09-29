# Chasing Impeller's `SetInheritedOpacity` validation break — investigation log

> **Status: solved.** The trigger is identified, reproduced in isolation, and
> fixed in `lib/core/toast/dhikr_reminder_overlay.dart` (glow layer 1b). What is
> left here is the write-up; §9 is the cleanup checklist for the diagnostic
> leftovers (`lib/impeller_probe.dart` + the `_*.txt` scratch files at the repo
> root).

---

## 0. TL;DR

**Symptom.** Running the app on Windows (`flutter run -d windows`, debug) spams:

```
[ERROR:flutter/impeller/entity/contents/contents.cc(119)] Break on
'impeller::ImpellerValidationBreak' to inspect point of failure:
Contents::SetInheritedOpacity should never be called when
Contents::CanAcceptOpacity returns false.
```

**The finding**

| Question | Answer |
|---|---|
| Is it fatal? | No. It is a `FML_LOG(ERROR)` + `DLOG(FATAL)`-style *validation break* — in a non-debugger run it just prints. The app keeps running and rendering. |
| How often? | ~55–60 per second (= **exactly one per repaint**) while the trigger is active, then **complete silence**. |
| When is it active? | Only while the **dhikr reminder card is on screen** *and* something inside it repaints (the burst stops dead the moment the card leaves). |
| Which widget pattern? | A **composited opacity layer whose entire subtree is one blurred shadow**: reminder-card glow layer 1b — `FadeTransition(opacity: _glowOpacity)`, which *rests at 0.4*, wrapped around a `Positioned.fill` `Container` whose `BoxDecoration` has **no colour, no gradient, and a single `BoxShadow(blurStyle: BlurStyle.outer, blurRadius: 60)`**. A blurred-shadow `Contents` answers `CanAcceptOpacity() == false`, and because it is the *only* entity in the layer, Impeller takes its "fold the alpha straight in" path and asserts. |
| What is the fix? | Delete the opacity layer, not the effect: fold the same animated value into the shadow's own colour (`alpha: completion * _glowOpacity.value`). Identical look, no `OpacityLayer`. Reproduced and re-verified as probe phases 21 → 27 in `lib/impeller_probe.dart`; details in §6–§7. |

**Where that leaves us:** the trigger is one widget in one file, the rule behind it
is measured rather than guessed (§6), and the shipped code is the fix. Everything
below is the trail that got there — including the wrong turn in §5, kept because
the reasoning for it was the natural one.

---

## 1. The symptom in detail

Captured log (`_app_ts.txt`, 11 675 lines, 11 659 of them the validation error),
timestamped by piping `flutter run` through `ForEach-Object { "$(Get-Date…) $_" }`:

```
06:12:04.528 Launching lib\main.dart on Windows in debug mode...
06:12:12.652 √ Built build\windows\x64\runner\Debug\dhikr_reminder.exe
06:12:12.770 [IMPORTANT:flutter/shell/platform/embedder/embedder_surface_gl_impeller.cc(126)]
               Using the Impeller rendering backend (OpenGLESSDF).
06:12:14.978 Syncing files to device Windows...
06:12:18.685 [ERROR:flutter/impeller/entity/contents/contents.cc(119)] Break on '…' …  ← first
```

Errors per minute (`_buckets.txt`):

| Minute | Errors | Reading |
|---|---|---|
| 06:12 | 2 436 | card on screen, repainting |
| 06:13 | 3 575 | ≈ 60/s → 1 per frame |
| 06:14 | 3 573 | same |
| 06:15 | 2 020 | card dismissed partway through the minute |
| 06:16 – 06:36 | **0** | nothing on screen → nothing to complain about |
| 06:37 | 55 | one ~1 s burst (pointer hover over the card's glow again) |

Two things fall out of that table:

1. **One offending entity per frame**, not "one per drawn primitive". With 15 dust
   particles (≈7 of them blurred) we would see 7× that rate if each blurred dot
   were the offender. So exactly *one* `Contents` object per frame receives the
   illegal inherited opacity.
2. **It is conditional on a repaint of the card's own subtree** — not on the dust
   behind it, which animates every single frame and never produced one line. Any
   rebuild of the card (pointer hover through `MouseGlow`, a tap, one of the
   card's tweens) re-records the offender's opacity layer, and every re-record
   costs exactly one assertion. In hindsight that is a *per-layer* rule, not a
   per-paint one; read at the time it looked "pointer-driven", which is what put
   `MouseGlow` on the throne for a day (§5).

---

## 2. Environment

| | |
|---|---|
| SDK | Flutter **3.41.0** stable / Dart 3.11.0, channel stable, at `C:\flutter` |
| Engine build | `5f77625673248ee5846fbcaf5d3e1a3878386fd7` (`C:\flutter\bin\internal\engine.version`) |
| Renderer on Windows | Impeller, **`OpenGLESSDF`** variant (see log line above) — the ANGLE/GL backend of Impeller, not Vulkan/Metal |
| Mode | debug, `flutter run -d windows`; the engine ships as a prebuilt artifact, so no engine source/symbols are attached locally |

Because the engine is prebuilt, the failing assertion can only be understood by
reading the engine source (flutter monorepo, `engine/src/flutter/flow/layers/`).
Two facts taken from it:

* `OpacityLayer::Preroll` only takes the "fold the opacity straight into the
  child" fast path when the subtree resolves to a *single* simple entity.
  Otherwise it pushes a composited `LayerStateStack` opacity, and the child's
  contents receive `SetInheritedOpacity()` while the display list records —
  which asserts when `CanAcceptOpacity()` is false.
* On the framework side both `RenderOpacity` (`opacity.dart`) and
  `RenderAnimatedOpacityMixin` (`animated_opacity.dart`) report
  `alwaysNeedsCompositing = _alpha > 0` and `isRepaintBoundary =
  alwaysNeedsCompositing`. So an `Opacity` / `FadeTransition` /
  `AnimatedOpacity` **at rest with `opacity == 1.0` (alpha 255) still publishes
  a real `OpacityLayer`** — "opacity 1.0 is free" is not true at layer level.
  That is why the overlay's
  `AnimatedOpacity(opacity: reminder == null ? 0 : 1)` and the card's
  `_glowOpacity` / `_textGlowOpacity` `FadeTransition`s stay on the suspect list
  even though they look idle.

---

## 3. Method

No debugger attach and no engine symbols ⇒ black-box differential testing:

1. **Static scan** for the patterns Impeller struggles with (`ShaderMask`,
   `BackdropFilter`, `MaskFilter.blur`, `BoxShadow` + blur, any `BlendMode`
   ≠ `srcOver`, `ColorFilter`, `Opacity`/`FadeTransition`) → `_paint_hits.txt`,
   `_ui_hits.txt`, `_timers.txt`, `_glow.txt`.
2. **`lib/impeller_probe.dart`** — a throwaway second entry point
   (`flutter run -t lib/impeller_probe.dart -d windows`) that cycles through N
   isolated phases, 1.8 s each, printing `PROBE: <i> <name>` so any engine error
   in the log maps to the phase that caused it. The scaffolding mirrors the real
   overlay (`AnimatedOpacity` wrapper that fades to 1.0 and rests there,
   `Positioned.fill` layers, a 520×320 card box) so the comparison is fair.
3. **Correlate with the real app** by timestamping `flutter run` output and
   bucketing it per minute. The *cadence* of the error is what actually narrowed
   the culprit (§1) — the phase sweep alone only told me what it is *not*.
4. **Then:** re-test the one remaining axis (non-`srcOver` blend modes) inside the
   probe. That run is the one that *missed* the answer by one phase (§6): the
   culprit had already been mounted, four phases earlier, as the "app glow 1b"
   case — and its output was in the log the whole time.

Stated plainly: steps 1–3 **disproved the initial hypothesis** (dust field /
blur under opacity). That is why this took several rounds — every "obvious"
candidate reads the same in source, so each had to be eliminated by *running*
it, and the first probe run also needed a fix round (phases 7–8 needed an SVG
asset path, the phase list had to be rebuilt after the wrapper switch was
extended) before results were usable.

---

## 4. What the probe has already ruled out

21 phases, two full runs (`_probe_out.txt` = phases 0–13, `_probe2.txt` =
phases 0–20). **Both runs finished with zero validation errors:**

| # | Phase | Result |
|---|---|---|
| 0 | baseline text, no opacity | clean |
| 1 | `Opacity(0.5)` + `Text` | clean |
| 2 | `Opacity(0.5)` + `CustomPaint` solid circles | clean |
| 3 | `Opacity(0.5)` + `CustomPaint` `MaskFilter.blur(Normal)` circles | clean |
| 4 | `Opacity(0.5)` + `LinearGradient` `DecoratedBox` | clean |
| 5 | `Opacity(0.5)` + `Container` `BoxShadow(blurStyle: outer)` | clean |
| 6 | `Opacity(0.5)` + `ShaderMask(srcIn)` + text | clean |
| 7 | `Opacity(0.5)` + `SvgPicture.asset` | clean |
| 8 | `Opacity(0.5)` + SVG + `ColorFilter.mode` | clean |
| 9 | `Opacity(1.0)` + blurred circles (at-rest layer) | clean |
| 10 | `Opacity(0.45)` + `TextField` w/ outline border | clean |
| 11 | `Opacity(0.5)` + radial-gradient shader paint | clean |
| 12 | `FadeTransition(0.3..0.7)` + outer `BoxShadow` (animating) | clean |
| 13 | no opacity + outer `BoxShadow` (control) | clean |
| 14 | `Opacity(0.5)` + `RepaintBoundary`(blur circles) | clean |
| 15 | `Opacity(1.0)` + `RepaintBoundary`(blur circles) | clean |
| 16 | `AnimatedOpacity(1.0)` + blur circles | clean |
| 17 | `AnimatedOpacity(1.0)` + `RepaintBoundary`(blur circles) | clean |
| 18 | **`AnimatedOpacity(1.0)` + tint + real `HolyDustBackground(15)`** — the app's exact combo | **clean** |
| 19 | same, plain `Opacity(1.0)` | clean |
| 20 | no opacity wrapper (naïve fix candidate) | clean |

Phase 18 is the important row: the whole dust layer exactly as the app builds
it, under an `AnimatedOpacity` pinned at 1.0, does **not** reproduce the error.
Dust, `MaskFilter.blur`, `RepaintBoundary` nesting and at-rest opacity layers are
therefore cleared. The axis none of phases 0–20 exercised is **blend mode** —
every paint in the probe uses the default `BlendMode.srcOver`.

---

## 5. The false lead: `MouseGlow`'s `BlendMode.overlay`

*(Kept in because the reasoning looks airtight and it cost two probe rounds. Skip
to §6 for the answer.)*

`MouseGlow` (`lib/core/widgets/mouse_glow_overlay.dart`) paints one radial
gradient circle with a non-default blend mode:

```dart
_paint.blendMode = GlowConfig.blendMode;   // BlendMode.overlay   (line 87)
```

and it is mounted **inside** the reminder card
(`lib/core/toast/dhikr_reminder_overlay.dart:508`), i.e. underneath the
`AnimatedSwitcher`'s `FadeTransition` and the card's own `FadeTransition`s
(`_glowOpacity`, `_textGlowOpacity`) — all of which publish `OpacityLayer`s even
at rest (§2).

Why it fits every observation:

* An opacity layer can only be folded into a child's colour when that child is
  drawn with `srcOver`. `BlendMode.overlay` reads the backdrop, so scaling the
  source alpha changes the result; `CanAcceptOpacity()` must answer false, yet
  the enclosing opacity layer still pushes the inherited alpha down into it —
  exactly the asserted contract.
* **One** offender per frame (§1): there is exactly one overlay-blend entity on
  screen.
* The burst stops when the card goes away and later returns as a ~1 s burst: the
  glow only paints while `MouseRegion.onHover` delivers events — no ticker, so
  the error rate tracks pointer movement, not the frame clock of the dust.
* 21 clean probe phases are consistent, since none of them used a blend mode.

Confidence: **moderate-to-high, still unverified.** The remaining alternatives
found by the static scan are all off-screen while the reminder shows:
`BlendMode.clear` in `lib/core/widgets/loading_spinner.dart:224`, and the
`CompositedTransformTarget/Follower` pairs in `lib/core/widgets/hero_dialog.dart`
and `lib/core/widgets/settings_dropdown.dart`. `GradientText`'s `ShaderMask` is
excluded by phase 6.

---

## 6. The answer: what the probe actually proved

Probe run 3 added four phases that copied the card's glow layers 1:1 instead of
using stand-ins, run back to back in one process. Run 4 added three entity-count
controls. Side by side:

| Probe phase | What is on screen | Errors in the log |
|---|---|---|
| 14 `opacity-0.5 + RepaintBoundary(blur circles)` | ~16 blurred dots under `Opacity` | 0 |
| 18 `animated-opacity-1.0 + tint + HolyDustBackground` | the real dust + tint under the real `AnimatedOpacity` | 0 |
| 20 `no-opacity + tint + HolyDustBackground` | same, opacity removed | 0 |
| **21 `opacity-0.4 + Positioned.fill BoxShadow(outer blur 60)`** | **glow layer 1b, copied exactly** | **~107 in 2 s** |
| 22 `Stack[card + BlendMode.overlay glow]` at opacity 0.5 | the §5 hypothesis, done properly | 0 |
| 23 same at opacity **1.0** (the at-rest case) | §5 hypothesis, at-rest variant | 0 |
| 24 same with `BlendMode.plus` | §5 control | 0 |
| 25 dust **+** overlay-blend glow together | both suspects at once | 0 |
| 26 **two** shadows in the same 1b-style layer, one `Color` backing | 1b + one more entity | 0 |
| 27 **fixed 1b** (alpha folded into the shadow, no opacity layer) | the shipped card | 0 |

The rule those rows spell out:

> **An `OpacityLayer` asserts when its subtree resolves to exactly *one* entity
> and that entity's `Contents::CanAcceptOpacity()` is false.** A blurred shadow
> is exactly such a `Contents`. Give the layer a second entity (phase 26) and the
> fold is abandoned — identical pixels, no assertion.

It is a *counting* rule, which is why it took 27 painted phases to see through
it:

* dust under `AnimatedOpacity` → dozens of entities in the layer → innocent
  (phases 14–20), even at `opacity: 1.0`, which really does publish a layer (§2);
* `ShaderMask` + text, `MaskFilter` circles, SVG + `ColorFilter` → several
  entities per layer → innocent (phases 4–11);
* phase 5 (*one* shadow under `Opacity`) already had the right shape — but the
  probe never repaints a layer that nothing animates, so its single assertion was
  never reached. The card repaints constantly, so there the same bug is a 60/s
  firehose;
* phase 21 is what the card actually does — one outer-blurred shadow under a
  `FadeTransition` that *rests at 0.4* — and it reproduced the burst on demand;
* the blend-mode theory (§5) is dead on every variant, including both suspects on
  screen at once.

---

## 6b. Why the app, and only the app, made it a firehose

`FadeTransition(opacity: _glowOpacity)` at rest is an `OpacityLayer` with
alpha 102 wrapping a `Container` with:

```dart
decoration: BoxDecoration(
  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.5),
                        blurStyle: BlurStyle.outer, blurRadius: 60)],
)
```

no colour and no gradient — i.e. one blurred shadow entity, the exact condition
the table above says must not sit under a composited opacity. The burst's
"one line per repaint" is the layer being re-recorded; its burst-shaped onset is
`_glowController.forward()` starting the fade, and its silence when no reminder
is up is the `SizedBox.shrink()` that keeps the card — and the layer — unmounted.

---

## 7. The fix (applied)

Glow layer 1b in `lib/core/toast/dhikr_reminder_overlay.dart` no longer has an
opacity layer at all — the animated alpha is folded into the shadow colour, which
is what a shadow already multiplies internally:

```dart
// before — an OpacityLayer whose only entity is a blurred shadow
FadeTransition(
  opacity: _glowOpacity,
  child: Positioned.fill(
    child: IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.5),
                                blurStyle: BlurStyle.outer, blurRadius: 60)],
        ),
      ),
    ),
  ),
)

// after — same curve, alpha carried by the shadow itself
Positioned.fill(
  child: TweenAnimationBuilder<double>(
    // carries the isComplete ease AnimatedContainer used to give this shadow
    tween: Tween(
      begin: reminder.isComplete ? 0.0 : 1.0,
      end: reminder.isComplete ? 0.0 : 1.0,
    ),
    duration: DhikrTimers.layoutTransition,
    curve: Curves.easeOutCubic,
    builder: (context, completion, _) => AnimatedBuilder(
      animation: _glowController, // unchanged: 0.4 -> 0.9 -> 0.4 TweenSequence
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: completion * _glowOpacity.value),
              blurStyle: BlurStyle.outer,
              blurRadius: 60,
            ),
          ],
        ),
      ),
    ),
  ),
)
```

The `AnimationController` and its `TweenSequence` (`_glowOpacity`: 0.4 → 0.9 → 0.4)
are unchanged — only *where the value lands* changed. `AnimatedBuilder` hands the
same per-frame value to `withValues(alpha:)` that `FadeTransition` used to hand to
an `OpacityLayer`, so the flash curve (180 ms attack, slower decay) is pixel-for-pixel
what the card had. The completion fade that the old `AnimatedContainer` used to ease
(`alpha: reminder.isComplete ? 0 : 1`) is the `completion` value of the outer
`TweenAnimationBuilder`, on the same `DhikrTimers.layoutTransition` /
`easeOutCubic` curve — and because `TweenAnimationBuilder` retargets from its
current value, a tap mid-ease does not restart it. The only thing lost is the
layer.

Layer 1 (`AnimatedSwitcher`'s fade over the accent + ambient shadow layer) was
**left alone**: three entities in that layer, so the rule in §6 does not bite —
confirmed clean by probe phase 26.

### The ranking that produced it, for the record

1. **Take the glow out of any opacity layer.** ← what was done, mechanically.
2. **Fold the alpha into the widget's own colours** ← what was done, visually
   lossless. Works anywhere a paint already owns its alpha (`BoxShadow`, gradients,
   `Paint.color`); it is the only variant that keeps the look *and* the animation.
3. **Don't mount opacity layers at rest** (`_SmartFade` returning `child`
   unchanged at 1.0). Would *not* have fixed this — 1b rests at 0.4, not 1.0. Good
   hygiene, wrong diagnosis; left out.
4. **Use an alpha-linear blend mode.** Irrelevant: blend modes turned out to be
   innocent (§6).

Not done on purpose: `RepaintBoundary` around the glow (does not change entity
count, so it does not address the rule) and switching the shadow to a gradient
container (would change the look for no gain).

---

## 8. Artifacts (temporary scratch, all untracked, repo root)

| File | What it is |
|---|---|
| `lib/impeller_probe.dart` | the phase-sweep entry point (phases 0–27); the executable regression for this bug |
| `_app_ts.txt`, `_stat.txt` | real-app runs before the fix — 11 659 of 11 664 log lines were the assertion |
| `_buckets.txt` | error count per minute → the table in §1 |
| `_probe_out.txt`, `_probe2.txt` | probe runs 1–2 (phases 0–20) — the "everything is innocent" run |
| `_probe3.txt`, `_probe4.txt` | probe runs 3–4 (phases 21–27) — the culprit + the entity-count controls |
| `_probe_names.txt`, `_probe_struct.txt` | phase-name / structure dumps used to line the runs up |
| `_main2.txt` … `_main6.txt` | real-app runs after the fix — 0 assertions |
| `_paint_hits.txt`, `_ui_hits.txt`, `_timers.txt`, `_glow.txt`, `_opacity_hits.txt`, `_assets.txt`, `_json.txt`, `_dust.txt`, `_a3.txt`, `_demo.txt` | `Select-String` scans (risky paint patterns, `DhikrTimers`, opacity widgets, assets, the debug demo reminder) |
| `_flutter_log.txt`, `_probe_log.txt`, `_p1.txt` | raw earlier captures |
| `_ver.txt`, `_ver2.txt`, `_sdk1.txt`, `_sdk2.txt` | SDK/engine build identifiers behind §2 |
| `_diff.txt`, `_grep.txt`, `_check.txt`, `_test.txt` | the fix's diff, its grep, `flutter analyze` and `flutter test` output |
| `_runapp.cmd` | wrapper that lets Task Scheduler run the app outside this agent's process tree |

The two commands that matter:

```powershell
# timestamped capture of a real app run (so errors can be bucketed per minute)
flutter run -d windows 2>&1 |
  ForEach-Object { "$(Get-Date -Format 'HH:mm:ss.fff') $_" } |
  Tee-Object -FilePath _app_ts.txt

# the phase sweep — phases 21 (faults), 26 and 27 (clean) are the regression trio
flutter run -t lib/impeller_probe.dart -d windows 2>&1 |
  Tee-Object -FilePath _probe4.txt
```

Tooling notes learned the hard way:

* `flutter run` without a piped stdin stays attached to the console and blocks
  for many minutes; long captures have to run detached (`Start-Process
  -RedirectStandardError`) and be stopped explicitly
  (`Get-Process | Where-Object Path -like '*Debug\dhikr_reminder.exe' |
  Stop-Process -Force`), otherwise the live app holds the window open.
* …and even a detached `Start-Process` child dies as soon as the *next* agent
  command reuses the terminal, which is why the post-fix app logs are short. To
  keep a run alive across commands, register it as a one-shot scheduled task
  (`schtasks /create … /tr '"…\_runapp.cmd"'` + `/run`); Task Scheduler starts it
  outside this process tree.
* A debug build shows a demo reminder 3 s after launch
  (`lib/features/settings/presentation/home_screen.dart:36`), so any debug run
  exercises the card without interaction — handy, and the reason the burst used to
  start ~4 s into every logged run.
* Inline `"$($_.LineNumber)…"` expressions get mangled by this environment's
  command quoting — write grep output to a file and read the file instead.
* The workspace search index is stale here (it answers "no results" for symbols
  that demonstrably exist, e.g. `DhikrTimers`), so code archaeology went through
  `Select-String`.

---

## 9. Remaining cleanup

* [x] `flutter analyze` → *No issues found*; `flutter test` → 7/7 passed (with the
      fix and the probe file in place)
* [x] Real-app run after the fix: 0 assertions
* [ ] `lib/impeller_probe.dart` — keep it while the fix is being reviewed (it is
      the only thing that can re-prove phase 21 vs 27 in one run); delete before
      or right after committing: `Remove-Item lib\impeller_probe.dart`
* [ ] delete every `_*.txt` scratch file and `_runapp.cmd` listed in §8, and
      `schtasks /delete /tn dhikr_app_verify /f`
* [ ] Keep this file, and when requested to delete by the user only after commiting this file: keep it next to the code, or distil §6–§7 into
      `docs/dependencies.md` (Impeller-on-Windows section) in the bilingual EN+AR
      style of the other docs. The in-code comment at glow layer 1b points here, so
      deleting the file means moving that note into the docs first.

---

## 10. One-paragraph version for whoever picks this up

The message is a **non-fatal** Impeller validation break meaning "an `OpacityLayer`
tried to fold its alpha into contents that cannot accept it". It fires once per
repaint, only while the dhikr reminder card is on screen. The offender is glow
layer **1b** of `_DhikrReminderCard`
(`lib/core/toast/dhikr_reminder_overlay.dart`): a `FadeTransition` resting at 0.4
whose entire subtree was a single `Container` with a single
`BoxShadow(blurStyle: BlurStyle.outer, blurRadius: 60)` — one blurred entity,
which `CanAcceptOpacity()` refuses, so Impeller's single-entity fold path asserts.
`MouseGlow` and its `BlendMode.overlay` — the obvious suspect from the repaint
cadence — are innocent, as are the dust field, `ShaderMask`, `MaskFilter.blur`,
SVG + `ColorFilter` and `RepaintBoundary` (probe phases 0–20 clean, 22–25 clean).
The rule is about *how many* entities the opacity layer wraps, not *what* they
draw: add one more entity and the same paint is legal again (phase 26). The fix
removes the layer instead of the effect — the tap-pulse alpha is folded into
`BoxShadow.color` (`alpha: completion * _glowOpacity.value`) inside a
`TweenAnimationBuilder` + `AnimatedBuilder`, which keeps the curve and the look
and prints nothing (phase 27, and a clean real-app run). If someone ever wants to
re-add an opacity animation to that layer, give the layer a second entity first,
or keep folding alpha into colours.





