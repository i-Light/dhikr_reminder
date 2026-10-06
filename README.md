# Dhikr Reminder

A small Windows desktop app that pops a dhikr on screen every few minutes. Click
anywhere on the card to count it off; it fades once you reach its target, and the
next one arrives on the interval. Nothing else — no accounts, no database. The only
network use is the updater below.

Opening the app (left-click its tray icon) shows two pages behind one bottom bar:
the azkar **settings** the reminders are drawn from, and a searchable **dhikr
library** (موسوعة الأذكار). The library is content, not user data — its entries live
in `lib/features/library/data/` and nothing there can be edited or saved from the
app.

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
    navigation/main_shell.dart the two pages behind one bottom bar
    theme/                     palette, GradientText / GradientBox
    toast/                     the reminder overlay, toasts, dust, glow, border frame
    update/                    the silent self-updater (GitHub Releases -> Setup)
    widgets/                   CollapsibleCard (what the settings card is built from)
  features/library/
    domain/dhikr_item.dart     one entry, its tags, and the tashkeel stripper
    data/                      every entry — one `const` list per section
    application/               the view state: search, tag filter, tashkeel, size
    presentation/              the library page, the card, the two popups
  features/settings/
    application/               dhikr persistence + the reminder scheduler
    presentation/              home_screen.dart + the azkar settings card
  l10n/                        app_en.arb, app_ar.arb (generated: l10n/gen/)
scripts/                       build_windows.ps1 (build + release), installer.iss
test/                          the weighted pick, the tap counter, the library
```

### The dhikr library

`dhikrLibrary` (`features/library/data/dhikr_library.dart`) is one `const` list,
assembled from the per-section files under `data/sections/`. The split is only so
no single file runs to thousands of lines — the screen never cares which file an
entry lives in, only about its `tags`.

- **Search** is tashkeel-insensitive: `matchesQuery` strips the diacritics off both
  the needle and the haystack, so typing `الله` finds a vocalised `اللَّه`. It looks
  at the text, the subtitle, the reference and the description.
- **The tag filter** is additive: an empty selection means "no filter", and each
  further group *widens* the list rather than replacing the last one.
- **The tashkeel toggle** is a formatting change at render time — `stripTashkeel`
  removes the vowel marks and leaves the letters, so the data is stored vocalised
  once and never duplicated.
- **The text size and the tashkeel choice** are remembered in
  `SharedPreferences`; the search text and the tag filter deliberately are not.
- The dhikr itself renders in the bundled `Naksh` face (the reminder card's own),
  at a line height tall enough that the tashkeel of one line cannot collide with
  the next.

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

## Building and releasing

Only the installer is built — there is no portable `.zip`. It needs
[Inno Setup 7](https://jrsoftware.org/isdl.php) installed.

```
.\scripts\build_windows.ps1                      # dist\dhikr_reminder-<ver>-setup.exe, version untouched
.\scripts\build_windows.ps1 -InstallHere         # ...and install it on this PC over the current copy
.\scripts\build_windows.ps1 -Mode Publish        # bump, tag, push, publish a GitHub Release
```

`CTRL + SHIFT + B` runs the same script through the *Release* task in
`.vscode/tasks.json`; which of the two modes it uses, and whether it also
installs on this PC, is chosen by commenting lines in and out of that task's
`args`.

`-Mode Publish` runs `flutter analyze` and `flutter test`, raises the version in
`pubspec.yaml` (patch by default; `-Bump minor` / `-Bump major`; the build number
after the `+` always goes up by one), builds, commits `Release vX.Y.Z`, tags it,
pushes the branch and the tag, and creates a GitHub Release with the installer
attached. It refuses to start with uncommitted changes, so the release commit
holds only the version bump, and it needs a GitHub token: `GH_TOKEN` /
`GITHUB_TOKEN` if set, otherwise the sign-in Git Credential Manager keeps for
github.com (the first publish may open a browser to create it). `-DryRun` checks
all of that and prints the plan without changing anything.

`ci.yml` runs `flutter analyze --fatal-infos` and `flutter test` on every push
and pull request. Releases are made by the script, not by CI.

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

The settings screen has an **Updates** card (`update_card.dart`): the running
version, what the updater is doing (checking, downloading, ready, installing, up
to date, or failed), a *Check for updates* button, *Update now* / *Restart and
update* to skip the wait for an idle moment, and an *Update automatically*
switch. With that switch off it still checks, and says a new version exists, but
installs only when told to.

What it deliberately does **not** install for: `flutter run` builds and any copy
without the `unins000.exe` Setup writes beside the exe, and an all-users install
in `Program Files` (the folder is not writable without the UAC prompt this
exists to avoid). Those still learn that a newer version exists, and the card
offers the download page instead. Failures — no network, GitHub rate limit, a
bad download — are logged (`dhikr_reminder.update`), shown on the card, and
retried in 15 minutes.

To ship an update, run the *Release* task in Publish mode. The installer is not
code-signed yet, so Windows SmartScreen may warn on a first manual download, and
antivirus may look harder at a silently launched installer than it would at a
signed one.

## Assets and fonts

`assets/fonts/PanoramaNaskhMobile-Regular.otf` is the face the reminder card
renders its Arabic in (`fontFamily: 'Naskh'`), and the two `.svg` files in
`assets/images/` are the card's corner ornament and mandala backdrop. Both are
declared in `pubspec.yaml`; drop either and the overlay throws at runtime rather
than at build time.

