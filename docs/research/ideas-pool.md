# Idea pool (master sorted list)

Every idea we have, where it came from, how important it is, how hard it is for Claude to build, what only a person can do, and which wave of `docs/roadmap.md` it ships in. Update this file in every release.

Last updated: 2026-10-09 (W0 to W5 built; the simplicity principle parked several W5 ideas, see "Decisions of 2026-10-09")

## How to read the columns

**Origin:** CR code review, RS web research, CP competitor apps, UR the owner's requests, BR brainstorm.

**Importance** (how much it matters to the people using the app):
- P0: users lose reminders or data today, or something is unsafe.
- P1: trust, truth, security, release safety. Invisible when fine, bad when it fails.
- P2: core dhikr value, or the main reason people keep or drop the app.
- P3: comfort. People notice if it is missing but do not leave.
- P4: reach, polish, future-proofing.
- P5: only if a trigger happens.

**My effort** (Claude doing the work in this repo; relative estimates, not promises, and no calendar time): XS is a few edits inside a session, S is about one session, M is two or three sessions, L is four or more sessions or needs tooling setup.

**Human** (work only a person can do; codes are explained in `docs/roadmap.md` under "Human lane"): none, or a code with its size, for example H1 big. tiny is under 15 minutes, small is under an hour, big is hours or other people.

**Wave:** W1 to W13 in `docs/roadmap.md`. Release tags: W1 0.1.4, W2 0.2, W3 0.3, W4 0.4, W5 1.0, W6 1.1, W7 1.2, W8 1.3, W9 2.0, W10 2.1, W11 2.2, W12 3.0, W13 the final sustain release.

Intake test for a new idea (all five must be yes): (1) it is remembrance, not another subject; (2) it works offline with no account; (3) it can run unattended for a year; (4) it adds no new permission or Play policy risk, or the risk is written down; (5) it can be checked by a test or a release checklist line. Anything else is added here as parked or rejected.

## Reliability and platform

| # | Idea | Origin | Imp | My effort | Human | Wave |
|---|---|---|---|---|---|---|
| 1 | Fix Android fallback by removing FLN and going native | CR | P0 | M | none | W1 |
| 2 | Pause works on Android; `cancel` clears the stored plan | CR | P0 | S | none | W1 |
| 3 | Tolerant loading, Hijri guard, request dead-end, autostart first run | CR | P0 | S | none | W1 |
| 4 | Release safety (no default Publish, key.properties required) | CR | P1 | S | none | W1 |
| 5 | Android 15+ delivery path (visible overlay first) | RS | P0 | M | H6 tiny (OK to download the emulator) | W3 |
| 6 | Native event log, health card, real-path test | CR, BR | P1 | M | none | W3 |
| 7 | JobScheduler self-heal, time, locale, boot, package-replaced receivers | CR, RS | P1 | M | none | W3 |
| 8 | Opt-in always-on mode | UR | P2 | M | H7 small (Play declaration text) | W3 |
| 9 | Per-brand guidance ordered by Egypt's market (Samsung, Oppo, Realme, Xiaomi) | RS | P2 | S | H6 big (borrow Oppo and Xiaomi phones) | W3 |
| 10 | Versioned storage, atomic writes, rolling backup | CR | P0 | M | none | W2 |
| 11 | Stable library ids with alias map | CR | P0 | M | none | W2 |
| 12 | Windows show-without-stealing-focus, DPI, tray fixes | CR | P2 | M | none | W4 |
| 13 | Delete dead code, toast subsystem, `ios/` | CR | P3 | S | none | W2 |
| 14 | Quiet hours, pause options, auto-hide and snooze | CR, CP | P2 | M | none | W4 |
| 15 | Windows Focus Assist and fullscreen awareness | CR | P2 | S | none | W4 |
| 16 | Morning and evening sessions (and the sequence runner) | UR, CP | P2 | M | none | W5 |
| 17 | Optional sound (tones made by code, no recordings) | UR | P2 | S | H9 tiny (pick the tone you like) | W5 |
| 18 | History and streaks (private, switchable) | UR, CP | P2 | M | none | W5 |
| 19 | Export and import, Auto Backup rules | CR | P1 | M | none | W5 |
| 20 | Accessibility baseline, first run, theme choice | CR | P3 | M | H6 small (listen once with TalkBack) | W5 |
| 21 | Signed updater, second host, kill switch, canary | CR | P1 | M | H8 small (generate and store the key offline) | W7 |
| 22 | CI for Windows and Android, Dependabot (W1); weekly health check (W7) | CR | P1 | S | none | W1, W7 |
| 23 | Worker cron, retention, deep health; admin pagination | CR | P1, P4 | S | none | W7 |
| 24 | Crash marker and "Report this crash" | CR | P3 | S | none | W7 |
| 25 | Staged Play rollout with halt as the Android kill switch | RS | P1 | S | H7 small (service-account permission) | W7 |
| 26 | Full-screen-intent notifications | RS | | | | rejected: Play default only for calling and alarm apps |
| 27 | Unlock-triggered reminders | BR | | | | rejected: needs an always-running service |
| 28 | Event or location reminders | BR | P5 | | | parked: needs a privacy review first |

## Content

| # | Idea | Origin | Imp | My effort | Human | Wave |
|---|---|---|---|---|---|---|
| 29 | Rebuild library from a licensed open dataset | UR | P1 | L | H1 big, H4 tiny | W8 (changed: none exists, verify by hand instead) |
| 30 | Quran text verbatim from Tanzil with notice | RS | P1 | S | none | W8 |
| 31 | Reference and grade on every entry; review list for a scholar | CR | P1 | L (the list itself is XS and can be made now) | H1 big | W8 (list handed over in W0) |
| 32 | "Report a mistake" on every entry | BR | P2 | XS | none | W2 |
| 33 | Credits screen, `LICENSE` | CR | P1 | S | H11 tiny (pick the licence, D4) | W2 |
| 34 | Transliteration (AI draft), plain meaning, English meaning | CP, BR | P3 | M | H2 big (reviewer hours) | W10 |
| 35 | Search by meaning | BR | P3 | S | none | W10 |
| 36 | Copy and share the dhikr text (never counts) | BR | P3 | XS | none | W7 |
| 37 | The 99 Names | CP | P3 | S | H1 small (compiled-list label), H2 | W10 |
| 38 | Memorise mode and light spaced review | BR | P3 | M | none | W10 |
| 39 | Situation finder | BR | P3 | S | none | W10 |
| 40 | Coverage audit against the chapters of Hisn al-Muslim | BR | P3 | M | H1 small | W10 |
| 41 | Quranic duas section (entries only) | BR | P3 | S | H1 small | W10 |
| 42 | Extra meaning languages | BR | P5 | | H16 | parked: needs a fluent reviewer per language (D3) |
| 43 | Recorded audio | CP | P5 | | H5 big | parked: no adhkar audio with a usable licence; Quran audio possible later |
| 44 | Text-to-speech | BR | | | | rejected: mispronunciation of religious text |
| 45 | Typed custom dhikr | UR | P5 | | | parked: D2, trigger is repeated request demand |
| 46 | Prayer times, qibla, Quran reader, hadith browser | UR | | | | rejected: another subject |
| 47 | Hijri event calendars (Ramadan, Fridays) as automatic features | BR | | | | rejected: calendar app; allowed only as a user-made profile |
| 48 | AI chat, AI-written meanings shipped unreviewed | BR | | | | rejected: religious text needs a named source and a human |

## Counting and personal practice

| # | Idea | Origin | Imp | My effort | Human | Wave |
|---|---|---|---|---|---|---|
| 49 | Counter screen: tap, haptics, undo, lock, resume | CP | P2 | M | H6 tiny (feel the haptics on the phone) | W5 |
| 50 | Rounds (for example 10 x 100) | CP, BR | P3 | XS | none | W5 |
| 51 | Phased sequences 33/33/34 | CP | P2 | S | none | W5 |
| 52 | Volume-key counting in the app | CP | P3 | S | none | W5 |
| 53 | Volume-key counting with the screen off | CP | | | | rejected: media-session or accessibility trick |
| 54 | Windows keyboard counting and native global hotkey | RS | P3 | S | none | W5 |
| 55 | Favourites | CP | P3 | S | none | W5 |
| 56 | My wird (ordered list from the library) | CP, BR | P2 | M | none | W5 |
| 57 | Goal-aware chance in the weighted pick | BR | P3 | S | none | W5 |
| 58 | Rosary-bead or ring look | CP | P4 | S | none | W9 |
| 59 | Long goals (for example a million salawat) | BR | P3 | S | none | W11 |
| 60 | Lifetime totals per dhikr, month view | CP | P3 | S | none | W11 |
| 61 | Timed dhikr session | BR | P3 | S | none | W11 |
| 62 | Badges, leaderboards, sharing progress | CP | | | | rejected: the show-off rule |
| 63 | Wear OS counter | CP | P5 | | H14 | parked: trigger is a volunteer maintainer |

## Reminders

| # | Idea | Origin | Imp | My effort | Human | Wave |
|---|---|---|---|---|---|---|
| 64 | Interval jitter | BR | P3 | XS | none | W4 |
| 65 | Per-dhikr active hours | BR | P3 | S | none | W4 |
| 66 | Respect Do Not Disturb and Bedtime mode | BR | P2 | S | none | W4 |
| 67 | Skip during a phone call (Android) | BR | P2 | XS | none | W4 |
| 68 | Wait until I am back (Windows idle) | BR | P2 | S | none | W4 |
| 69 | Gentle chip style, position, size, palettes | BR | P3 | M | none | W9 |
| 70 | Profiles (Work, Home, Travel, Ramadan) | BR | P3 | M | none | W11 |
| 71 | Suggest quiet hours from ignored cards | BR | P4 | S | none | W11 |
| 72 | Simple mode and setup for a parent | BR | P3 | M | H3 small (watch one parent try it) | W9 |

## Surfaces and platform integration

| # | Idea | Origin | Imp | My effort | Human | Wave |
|---|---|---|---|---|---|---|
| 73 | Android home-screen widget (native) | CP, RS | P2 | M | H6 tiny | W6 |
| 74 | Quick Settings tiles: count, pause | RS | P3 | M | H6 tiny | W6 |
| 75 | Notification actions: Done, Later | RS | P2 | S | none | W6 |
| 76 | Launcher shortcuts | BR | P3 | XS | none | W6 |
| 77 | Windows tray "Count one" and today's total | BR | P3 | XS | none | W6 |
| 78 | `home_widget` package | RS | | | | rejected: still needs the native widget, adds a dependency |
| 79 | Android 16 Live Updates | RS | | | | rejected: poor fit for a tally |
| 80 | Windows jump list, Windows 11 Widgets board | BR | P5 | | | parked: trigger is the Store channel being stable |
| 81 | Android Auto | BR | | | | rejected: driving distraction and policy risk |
| 82 | "Say a dhikr before opening an app" blockers | CP | | | | rejected: accessibility or usage-access permission, Play risk, different product |

## Access, reach and distribution

| # | Idea | Origin | Imp | My effort | Human | Wave |
|---|---|---|---|---|---|---|
| 83 | Microsoft Store (free signed MSIX) | RS | P3 | L | H7 big (ID and selfie), H10 small, H11 (D1) | W12 |
| 84 | winget listing | RS | P5 | S | | parked: trigger is the Store being declined |
| 85 | Accessibility audit with real tools, large text, high contrast, Arabic-Indic numerals | CR, BR | P3 | M | H6 small (listening sessions) | W9 |
| 86 | Per-app language on Android 13+ | RS | P3 | S | none | W9 |
| 87 | Large-screen layouts | RS | P4 | M | none | W9 |
| 88 | Landing page on GitHub Pages | BR | P3 | S | H10 small (approve the text and screenshots) | W12 |
| 89 | IzzyOnDroid, F-Droid, Galaxy Store | RS | P4 | S to M each | H7 big (accounts and submissions), H11 (D5) | W12 |
| 90 | AppGallery | BR | P5 | | | parked: trigger is demand from Huawei users |
| 91 | Content correction by pull request | BR | P4 | S | none | W12 |
| 92 | "What's new" note | BR | P5 | XS | none | W12, only if updates become frequent |
| 93 | QR transfer to a new phone | BR | P5 | | | parked: export file and Auto Backup already cover it |
| 94 | Accounts, cloud sync, ads, analytics, tracking | BR | | | | rejected: ground rules |
| 95 | iOS, macOS, Linux | BR | | | | rejected: no second maintainer for another platform |

## Sustainability

| # | Idea | Origin | Imp | My effort | Human | Wave |
|---|---|---|---|---|---|---|
| 96 | Docs for strangers, templates, architecture note | BR | P3 | S | none | W13 |
| 97 | Graceful decay and a sunset build | BR | P1 | M | none | W13 |
| 98 | Frozen export format with golden-file test | BR | P1 | S | none | W13 |
| 99 | Performance and battery budgets | BR | P3 | S | H12 (passive) | W13 |
| 100 | Dependency diet and Flutter upgrade rhythm | BR | P4 | M | none | W13 |
| 101 | Security pass, bus factor | BR | P1 | S | H8 small, H14 | W13 |

## Decisions of 2026-10-09 (the simplicity principle)

The owner asked that the app stay simple: few buttons, settings and facts on screen, nothing that slows the app or changes how it looks, and every feature removable with one switch (`lib/core/features.dart`). That reorders the pool.

**Built, with the least possible interface:** quiet hours (one folded row), soft sound (one folded row, off), history (one row on the home page), count now (one button inside an open library card), the two warning cards (only when true), do not disturb and calls and full-screen apps and idle (no interface at all), no repeat of the same dhikr (none), the idle close of a Windows card (none), keyboard keys and screen-reader text on the card (none), report a mistake (press and hold, none on screen), About (one quiet link).

**Built in W6 (1.1), outside the app's own screens:** home-screen widget, two quick-settings tiles, launcher shortcuts, "Done" and "Later" on the notification, tray "Count one" and tooltip total, copy and share the text from a long press.

**Parked until users ask (H3), because each adds controls:** favourites, my wird, morning and evening sessions, cycles and sequences, haptic strength, volume-key counting, a global hotkey, a free counter, manual export and import of a file, a theme choice, language from the phone's locale, pause options (until tomorrow, custom), interval jitter, per-dhikr active hours, the always-on mode, a Hijri day adjustment, the "test through the real alarm" button, and the pre-count input guard.

**Needs a decision or a device:** the Android 15 and 16 delivery path (emulator download), the code licence (D4), the always-on Play declaration.

## Stop rule: when the pool is empty

The pool is empty when every row above is one of: shipped, parked with a written trigger, or rejected with a reason, and two fresh brainstorm passes add nothing that passes the intake test:

1. A pass on competitors and user reviews (Google Play reviews filtered for undo, widget, vibration and battery), plus whatever the user survey (H3) returned.
2. A pass on platform changes since the last release (Android, Windows, Play policy, the Microsoft Store).

The final audit in the sustain release runs both passes and records the dates here. After that the project only receives maintenance-mode work, and a new idea is judged by the intake test, not by enthusiasm.

Brainstorm passes done so far:

- 2026-10-09: first full pass (competitors, platform, content sources, distribution). Produced rows 1 to 101.
- 2026-10-09: re-sorted by importance and ease; no rows added or removed.
