# Dhikr Reminder

A small Windows desktop app that pops a dhikr on screen every few minutes. Click
anywhere on the card to count it off; it fades once you reach its target, and the
next one arrives on the interval. Nothing else — no accounts, no database. The only
network use is the updater below.

It is a slice of [gratovo_toolbox](https://github.com/i-Light/gratovo_code)
lifted out into its own project: the reminder overlay, the toast system it rides
on, the azkar settings card and the providers behind them. The reminder code is
the same code, comment for comment, so a fix made here should be pushed back
there (and vice versa) rather than allowed to drift.

## Running it

```
flutter pub get
flutter run -d windows
```

In VS Code: open this folder, pick **Dhikr Reminder (Windows)** and press F5.
Hot reload works as usual, and because the reminder scheduler lives in
`MaterialApp.builder`, a hot restart that rebuilds the whole widget tree does not
lose the running timer.

**Closing the window hides it to the system tray** instead of quitting. Left-click
the tray icon to bring the app back; right-click it for a small themed menu —
open the app, the countdown to the next dhikr, a sound on/off toggle (the icon
changes with the state) and close-for-real. A reminder that comes due while the
window is hidden raises it, and hides it again once the reminder is done. The
tray code is in `lib/core/window/`; it only runs on Windows.

Two conveniences worth knowing about:

- **A reminder pops by itself 3 seconds after launch in debug builds.** The
  interval defaults to 30 minutes, and waiting that long to answer "does the card
  render?" gets old fast. See `_debugDemoDelay` in `home_screen.dart`; release
  builds never schedule it.
- **"Show a reminder now"** on the home screen fires one on demand, from whatever
  is currently saved in the azkar settings.

`CTRL + SHIFT + B` runs the Release build (`scripts/build_windows.ps1`); the
*Test* task (`Tasks: Run Test Task`) runs `flutter test`.

## What is in here

```
lib/
  main.dart                    runApp inside a ProviderScope — nothing to await first
  app.dart                     MaterialApp, theme, locales, and the two overlays
  core/
    constants/app_colors.dart
    theme/                     palette, GradientText / GradientBox
    toast/                     the reminder overlay, toasts, dust, glow, border frame
    update/                    the silent self-updater (GitHub Releases -> Setup)
    widgets/                   CollapsibleCard (what the settings card is built from)
  features/settings/
    application/               dhikr persistence + the reminder scheduler
    presentation/              home_screen.dart + the azkar settings card
  l10n/                        app_en.arb, app_ar.arb (generated: l10n/gen/)
scripts/                       build_windows.ps1, installer.iss
test/                          the scheduler's weighted pick + the tap counter
```

### The one rule that matters

`DhikrReminderOverlay` must stay mounted for the timer to exist.
`dhikrReminderSchedulerProvider` is a `NotifierProvider` with a `Timer`, and a
provider with no listener is disposed. That is why `app.dart` mounts it in
`MaterialApp.builder` rather than inside a screen — the same reason
`ToastOverlay` sits there. Moving either one under `home:` will silently cost you
either the reminder or every toast in the app.

Related: `HolyDustBackground` behind the card runs a repeating animation, so the
overlay only builds it while a reminder is actually on screen. `AnimatedOpacity`
would fade it but keep repainting 15 particles every frame for the rest of the
session.

## Settings

Everything lives in `shared_preferences` under `dhikr_reminder.dhikr.*` — the
encoded dhikr list, the interval in minutes, and the next row id. The keys are
deliberately **not** the ones gratovo_toolbox uses, so installing this beside it
cannot read or overwrite the toolbox's azkar list.

The reminder is weighted, not random-uniform: each row's *Chance* is a weight
(`0` mutes a row), and the row picked on each tick is drawn in
`DhikrReminderScheduler.pickWeighted`.

## Localizations

`lib/l10n/app_en.arb` and `app_ar.arb` are the source of truth; `lib/l10n/gen/`
is generated from them by `flutter gen-l10n` (configured in `l10n.yaml`) and
committed, so CI can assert it is up to date. Add a string to both ARB files, run
`flutter gen-l10n`, and never edit `lib/l10n/gen/` by hand.

## Building

```
.\scripts\build_windows.ps1              # dist\dhikr_reminder-<ver>-windows-x64{.zip,}
.\scripts\build_windows.ps1 -Installer   # + dist\dhikr_reminder-<ver>-setup.exe
```

The `.zip` is portable and always produced; the installer needs
[Inno Setup 6](https://jrsoftware.org/isdl.php) and gives a Start-menu entry plus
an uninstaller. Pushing a `vX.Y.Z` tag (matching `pubspec.yaml`'s version) makes
`.github/workflows/release.yml` build it and attach both files to a GitHub
Release. `ci.yml` runs format, `flutter analyze --fatal-infos` and `flutter test`
on every push and pull request.

## Automatic updates

An app installed with the Setup wizard keeps itself up to date with nothing for
the person to do. Two minutes after launch, and every six hours after that, it
asks GitHub for the latest release (`lib/core/update/`). If that is newer than
the running version it downloads the release's `*-setup.exe` in the background,
checks its size, SHA-256 and `MZ` header, waits until no reminder is showing and
the settings window is closed, then runs it with `/VERYSILENT` and quits. A
PowerShell one-liner outlives the app, waits for Setup to finish and starts the
app again — even if the install failed, so a broken update never leaves the
reminders switched off. The dhikr list and interval live in `%APPDATA%` and are
untouched.

What it deliberately does **not** touch: `flutter run` builds and the portable
`.zip` (no `unins000.exe` beside the exe), and an all-users install in
`Program Files` (the folder is not writable without the UAC prompt this exists
to avoid). Failures — no network, GitHub rate limit, a bad download — are logged
(`dhikr_reminder.update`) and retried in 15 minutes; nothing is shown.

To ship an update: bump `version:` in `pubspec.yaml`, commit, and push the
matching `vX.Y.Z` tag. The installer is not code-signed yet, so Windows
SmartScreen may warn on a first manual download, and antivirus may look harder
at a silently launched installer than it would at a signed one.

## Assets and fonts

`assets/fonts/PanoramaNaskhMobile-Regular.otf` is the face the reminder card
renders its Arabic in (`fontFamily: 'Naskh'`), and the two `.svg` files in
`assets/images/` are the card's corner ornament and mandala backdrop. Both are
declared in `pubspec.yaml`; drop either and the overlay throws at runtime rather
than at build time.

