# Dhikr Reminder roadmap: ordered by value and ease

The app is a remembrance (dhikr) app only, for Windows and Android, in Arabic and English. The aim is the best focused dhikr app there is: no ads, no accounts, no drift into prayer times or a Quran reader. It is two weeks old (v0.1.3) and has grown fast: overlay reminders, Android native alarms, a Windows self-updater, a 281-entry library, and a Cloudflare Worker for dhikr requests.

This roadmap was re-sorted on 2026-10-09. The first version ordered work by calendar-style phases and gates. This one orders it by how much each thing matters to the people using the app and how quickly Claude can build it, and it puts the work only a person can do in its own lane so those clocks start early. Nothing was removed; every idea is still in `docs/research/ideas-pool.md`, which is the master list with the importance, effort and human columns for all 101 ideas.

## How the order was decided

**Importance**
- P0: users lose reminders or data today, or something is unsafe.
- P1: trust, truth, security, release safety. Invisible when fine, bad when it fails.
- P2: core dhikr value, or the main reason people keep or drop the app.
- P3: comfort. People notice if it is missing but do not leave.
- P4: reach, polish, future-proofing.
- P5: only if a trigger happens.

**My effort** (Claude doing the work in this repo; relative estimates, not promises). XS is a few edits inside a session, S is about one session, M is two or three sessions, L is four or more sessions or needs tooling setup. There are no calendar estimates on purpose: planning time is not the cost, so the roadmap does not spend it.

**Ordering rule.** Fix what is broken first (P0), then what makes people drop the app (annoying reminders), then what the owner asked for, then trust and release safety, then depth and reach. Within a wave, cheap and important goes first. Work that needs a person (a reviewer, an account, a borrowed phone) is started early in the human lane, so its waiting time overlaps with the build instead of coming after it.

**Real-time waits are not effort.** A 14-day soak, a Store verification, a scholar's review and a user's reply take wall-clock time that nobody can shorten. They run in the background while the next wave is built.

## Human lane: work only a person can do

Claude cannot do these, or cannot do them well enough to trust. Claude prepares the material so each one costs the person as little time as possible. Importance is for the whole project, "start" says when the clock should begin.

| Code | What | Why Claude cannot | Human time | Wait | Importance | Start | Claude prepares |
|---|---|---|---|---|---|---|---|
| H1 | Scholar review of virtue claims, weak or disputed items, grades, the 99 Names "compiled list" label, Quranic duas | Religious accuracy needs a qualified person, not a model | Several hours of an expert | Days to weeks | P1 | Now (W0) | The review list (about 42 entries plus disputed ones), made from the current library; later the provenance file |
| H2 | Review of meanings and translations if they ship | Same, and the reviewer must read Arabic and English | 10 to 20 hours for all entries; far less if only the top 60 entries ship first | Weeks | P3 | W9 | Drafts, in small batches, with the source line for each |
| H3 | Ask real users what they want and what annoys them; watch one parent try the app | Only people can answer; this corrects the importance column | About an hour to send and collect | 1 to 2 weeks | P1 (it fixes the ranking itself) | Now (W0) | Five short questions in Arabic and English, a message to send, and the in-app "Report a bug" and "Report a mistake" paths that keep collecting feedback |
| H4 | Licence answers: open an issue on rn0x/Adhkar-json asking for an explicit licence; read `sunnah.com/about` ("Reproduction, Copying, Scraping") in a browser | The fetch tool got a 403; a maintainer has to answer | 10 minutes | Maybe never answered | P1 | Now (W0) | The text of the issue; the place in `content-sources.md` to paste the answer |
| H5 | Recording or collecting adhkar audio with a usable licence or permission | No licensed adhkar audio exists (checked); recording and permissions are human work | Days to weeks | Weeks | P5 | Only if wanted | The licence checklist; sound effects need none because tones are made by code |
| H6 | Physical checks: unlock the Samsung phone for lock-screen tests, feel haptics, borrow an Oppo and a Xiaomi phone for battery settings deep links, listen to TalkBack and Narrator | Needs hands, ears and other people's phones | Minutes each; about two hours across everything | Days if borrowing | P2 | When the wave needs it | Exact steps and a one-line check per device |
| H7 | Accounts and identity: Microsoft Store registration (ID and selfie), Play Console declarations and service-account permission, Galaxy Store and F-Droid submissions | Identity, payment and agreements are the owner's | Under an hour each | Days of verification | P3 | W12, but the Store registration can start any time | The exact text for each form |
| H8 | Keys and secrets: generate the Ed25519 signing key offline, store it with backups, record where every token lives, rotate yearly | A secret I generate in a session is not offline | About an hour | None | P1 | Before W7 | The script and the runbook page |
| H9 | Egyptian Arabic phrasing review of each wave's new strings; pick the sound you like | Taste and dialect | 15 minutes per wave | None | P2 | End of every wave | A list of all new strings with their English |
| H10 | Store assets and listing text approval: screenshots in both languages, feature graphic, descriptions | Design judgment and ownership of the listing | 1 to 2 hours | None | P3 | W12 | Drafts and screenshots from the emulator |
| H11 | Decisions D1 to D6 (below) | They are the owner's | Minutes each | None | P1 | When reached | A one-paragraph recommendation each |
| H12 | Soaks: leave a Windows PC and the phone running for 14 days | Real elapsed time on real devices | Almost none | 14 days | P1 | After W5 and after W8 | The event log and daily totals to read afterwards |
| H13 | Play closed-test testers (12 people for 14 days) if Play still requires it for the account | Recruiting people | Hours of asking | 14 days | P1 | Check status now | A message to send |
| H14 | A second maintainer or sealed hand-over instructions | A relationship | One conversation | None | P4 | W13 | The hand-over page in `docs/maintenance.md` |
| H15 | Yearly duties (target API bump approval, token rotation) | Calendar and accounts | Hours per year | None | P1 | Forever | The calendar list under "Maintenance mode" |
| H16 | Fluent reviewers for extra meaning languages | None exist yet | Per language | Weeks | P5 | Only on a trigger | Data-file template |

What Claude can do that looks like human work: draft transliteration and meanings (H2 then verifies), write the survey and the forms, make tones for the sound feature, generate screenshots, install the Android emulator and Android 15 and 16 images (the PC has the SDK command-line tools, hardware virtualisation and about 62 GB free on C; I will ask before a multi-gigabyte download), and run every test.

## Execution order at a glance

| Wave | Ships as | Theme | Importance | My effort | Human lane needs |
|---|---|---|---|---|---|
| W0 | now | Start the human clocks | P1 | XS | H1, H3, H4 (and H13 status check) |
| W1 | 0.1.4 | Fix what is broken today, add CI | P0 | M | H6 tiny (unlock phone) |
| W2 | 0.2 | Data safety, feedback loop, credits | P0 | M | H11 (licence, D4) |
| W3 | 0.3 | Android works on new phones (Android 15 and 16), health check | P0 | L | H6 (other brands), H7 (Play text) |
| W4 | 0.4 | Polite reminders: quiet hours, snooze, do-not-disturb, call, idle | P2 | M | H9 |
| W5 | 1.0 | What the owner asked for: counter, history, sound, sessions, wird, backup | P2 | L | H6, H9, H12 |
| W6 | 1.1 | Android surfaces: widget, tiles, notification buttons, shortcuts | P2 | M | H6 tiny |
| W7 | 1.2 | Update and release trust: signed updater, staged rollout, Worker upkeep | P1 | M | H8, H7 |
| W8 | 1.3 | Content trust: verified library, Quran verbatim, grades | P1 | L | H1, H4, H12 |
| W9 | 2.0 | Comfort and access: simple mode, language, numerals, accessibility audit | P3 | M | H3, H6 |
| W10 | 2.1 | Depth: transliteration, meanings, 99 Names, memorise, finder | P3 | L | H1, H2 |
| W11 | 2.2 | Fit a life: profiles, long goals, timed dhikr | P3 | M | none |
| W12 | 3.0 | Reach: Store, landing page, other stores | P3 to P4 | L | H7, H10, H11 |
| W13 | next major | Sustain: outlive the author | P1 to P4 | M | H8, H14, H15 |

After any wave the project is in a state where it is safe to stop, and W13 then follows (decision D6).

## Findings that shaped the plan (verified in the code)

- Android's no-overlay fallback cannot fire. `flutter_local_notifications` 22.3.1 does not declare its alarm receivers and our manifest does not either (merged manifest has zero `ScheduledNotification` entries). The syncer cancels the native alarms first (`mobile_reminder_host.dart:66-69`), so a user who declines the overlay permission gets no reminders at all.
- On Android 15+ (we target 36) the floating card and the lock-screen card likely cannot start from an alarm unless battery optimisation is off. The test phone runs Android 12, so this was never seen. Google's Android 15 notes say a background foreground-service start by an overlay-permission holder now needs a visible overlay window first. Android 15 and 16 together are about a third of Egyptian phones (StatCounter 2026), which is why this is P0.
- Pause does nothing on Android (`pausedUntil` is never passed to `planReminders`), and `cancel` leaves the stored plan so a reboot revives it.
- One corrupt or truncated prefs file silently loses every setting on Windows, forever (non-atomic write, swallowed errors).
- Library ids are hashes of the text, so fixing a typo orphans every saved reminder. Only 26% of entries have a source, almost none have diacritics, and the scrape has typos and no licence note.
- The updater trusts one channel (digest comes from the same GitHub response as the binary), fails open if the digest is missing, and Ctrl+Shift+B publishes to everyone with no confirmation.
- The request feature can dead-end: stuck "queued" requests count as open and cannot be removed.
- Nothing monitors the Worker, the release, or the privacy URL, and CI does not build Windows or Android.

## Decisions already made (from you)

- Extra features: history and streaks, sound options. Not in scope: prayer times, user-typed dhikr.
- Content: rebuild the library from open verified datasets with a source and grade on every entry. Research changed the first step (see W8): no dataset with a clear data licence and per-entry grades exists, so a licence audit comes first and the realistic path is hand verification.
- Windows signing: no paid certificate. Free hardening (offline Ed25519 signature checked by the updater, canary step) in W7.
- Android phones that kill apps: guide and detect, plus an opt-in "always on" mode with a persistent notification.

## Decision gates still open (asked when we reach them, not now)

- **D1, start of W12: Microsoft Store channel.** Individual registration is now free and the Store signs MSIX packages at no cost, which removes the SmartScreen warning the unsigned Inno installer gets. Needs ID and selfie verification by you. Recommended: yes, as an additional channel next to the GitHub installer. The registration can start earlier because verification takes days.
- **D2, any time: typed custom dhikr.** Stays out. Revisit only if "Request a dhikr" shows repeated demand for private personal phrases.
- **D3, W10 or W12: extra languages for dhikr meanings** (Urdu, Indonesian, Turkish, French). Only if a fluent reviewer exists for each language.
- **D4, W2: code licence** (MIT or similar). The content licence is decided by the dataset licences.
- **D5, start of W12: other Android channels** (F-Droid, IzzyOnDroid, Galaxy Store). Each store signs differently from Play, so a person who installs from two stores cannot update across them. Recommended: IzzyOnDroid first (it serves our own signed GitHub APK), F-Droid only if you accept a second signing identity.
- **D6, end of each wave: stop or continue.** You choose the last feature wave; W13 then follows.

## Ground rules for every release

- Remembrance only. No accounts, analytics, ads, cloud sync, sharing of progress, leaderboards. The only network use stays the Windows updater and "Request a dhikr". Never change the Worker URL. If the request format changes, change `server/src/core.mjs`, the Dart gateway and `test/requests/request_service_e2e_test.dart` together.
- No showing-off features. Nothing that compares people, shares a streak, awards badges or shames a missed day. Streaks are private, can be switched off, and never use guilt wording. Sharing the text of a dhikr with a friend is fine; sharing your counts is not.
- Windows and Android only. Delete `ios/` (untouched scaffold that would crash on FLN init) and say so in the README.
- No em dashes, en dashes, curly quotes, arrows or other AI-looking symbols in strings, docs, commits or new comments. Every new Arabic string is written as natural Egyptian Arabic, not translated word for word. Add each string to both ARB files and run `flutter gen-l10n`.
- Every release ships with: `flutter analyze --fatal-infos`, `flutter test`, server tests, and the manual device checks listed under "Verification".
- Do not launch a built Windows exe while the installed copy runs (the runner kills the other instance). Do not uninstall the Samsung test phone's app as a testing shortcut. Never touch `CompanyName`/`ProductName` in `windows/runner/Runner.rc`: the prefs path is derived from them and changing them orphans every user's data.
- **Idea intake test.** A new idea enters the plan only if all five are yes: (1) it is remembrance, not another subject; (2) it works offline with no account; (3) it can run unattended for a year; (4) it adds no new permission or Play policy risk, or the risk is written down; (5) it can be checked by a test or by a line in the release checklist. Anything else is written into the idea pool as parked or rejected, with the reason.
- **Research is kept.** Every web finding that shapes a decision is written to `docs/research/` with its date, source and confidence, so later sessions build on it instead of repeating it.

## Finish line (definition of "done")

The project enters maintenance mode when all of these are true:

1. The W13 audit passes and the idea pool is empty ("Stop rule" in `docs/research/ideas-pool.md`).
2. CI builds Windows and Android on every push and weekly, and a scheduled health workflow checks the Worker, the latest release and the privacy URL, opening a GitHub issue on failure.
3. Dependency updates arrive as Dependabot PRs that only merge when CI is green.
4. `docs/maintenance.md` (runbook and yearly calendar) exists and every secret and key has a recorded backup location.
5. The only recurring human work is the yearly list in "Maintenance mode".

---

# W0: start the human clocks (now, before any code)

Importance P1, my effort XS. These cost a few minutes of the owner's time and unblock waves that are far away.

1. **Scholar review list (H1).** Generate, from the current library, the file of the roughly 42 entries that carry a virtue claim plus anything weak or disputed (such as the morning/evening salawat item), with each entry's text, count, current source line and the claim to check. Hand it to a qualified person now; the answer is needed at W8 and takes the longest.
2. **Licence questions (H4).** I draft the issue for rn0x/Adhkar-json asking for an explicit licence. You post it and read `sunnah.com/about` in a browser, pasting the exact wording into `docs/research/content-sources.md`.
3. **Ask real users (H3).** I write five short questions in Arabic and English (what annoys you, what would you use most, did reminders ever stop, what is missing, would a widget help). You send them to 10 to 20 people who use or would use the app. The answers re-sort this roadmap.
4. **Play closed-test status (H13).** Check whether Play still requires the 12-testers-for-14-days step for the account; if yes, start recruiting.
5. **Microsoft Store registration (H7, optional).** If D1 is likely yes, start the identity verification now.

---

# W1 (0.1.4): fix what is broken today

Importance P0, my effort M, human lane tiny (H6: unlock the phone for the lock-screen checks). Correctness fixes plus the CI that protects every later wave. No new features.

1. **Android reminders without the overlay permission.** Remove `flutter_local_notifications`, `timezone`, `packages/flutter_local_notifications_windows`, the `dependency_overrides` entry and the proguard `-keep class com.dexterous.**` rule. Delete `lib/features/mobile_reminders/notification_service.dart` (the only FLN import). Make `MobileReminderSyncer.sync` always call `_overlay.schedule`; native `ReminderDelivery` (`ReminderReceiver.kt:37-40`) already posts a notification when drawing is not allowed. Add the POST_NOTIFICATIONS request and the notification-tap-opens-the-dhikr intent extra natively in `MainActivity.kt` (replaces FLN's payload and `pendingOpenDhikrProvider`). Update `mobile_reminders_test.dart` and the fakes in `test/helpers/`.
2. **`cancel` consistency.** `MainActivity.kt:89-92` must also clear the stored plan and interval (or write `enabled=false`) in `ReminderStore`, so `BootReceiver`/`topUp` cannot revive cancelled reminders. Add a Kotlin unit test beside `PendingRules`.
3. **Pause on Android.** Pass `pausedUntil` through `MobileReminderSyncer.sync` into `planReminders` (already supported at `reminder_planner.dart:50-57`) and have `ReminderStore` remember it so `extend` respects it. Replace the fake in-process countdown on Android with the real next-alarm time from the store.
4. **Hijri crash guard.** `formatHijriDate` (`lib/core/date/hijri_date.dart:11-28`) must catch the package's out-of-range throw and return an empty string. It runs from `build` every minute.
5. **Tolerant loading.** `DhikrEntry.fromJson` (`dhikr_controller.dart:126-138`) must skip a malformed entry instead of losing the list, and a failed load must never write the defaults back over the saved list. Recompute `_nextId` as max(id)+1 after load.
6. **Request dead-end.** Let the person remove `queued` requests, stop counting stuck ones as open (`dhikr_request.dart:22-25`, `request_controller.dart:280-282, 371-377, 485-490`, `my_requests_screen.dart:276`), and keep the local copy when the server answers "daily cap reached" instead of deleting it (`request_controller.dart:362-370`).
7. **Autostart on first run.** Register the Run key from startup, not when Settings is first built (`autostart.dart`, `home_screen.dart:88`, `app.dart:121-130`).
8. **Release safety.** Remove the default Publish mode from the Ctrl+Shift+B task (`.vscode/tasks.json:38`), add a typed confirmation to `-Mode Publish` in `scripts/build_windows.ps1`, and make the Android release build fail when `key.properties` is missing instead of falling back to the debug key (`android/app/build.gradle.kts:74-78`). The failure is skipped only when `-PallowUnsigned=true` is passed, which our scripts never pass; W12 (F-Droid, IzzyOnDroid) will need it.
9. **CI and Dependabot (moved up from the old 0.5 because they protect everything after).** `ci.yml`: add `node --test` for `server/`, a `windows-latest` job running `flutter build windows --release`, an Android job running `flutter build apk --debug` and `./gradlew :app:testDebugUnitTest`, a manifest assertion (receivers and service present), and a weekly schedule trigger. Pin Flutter in `.fvmrc`; replace the fragile `ubuntu-26.04` label. Add `dependabot.yml`: monthly for pub, github-actions, gradle and `server/` npm; ignore `tray_manager` 0.6 and up and `flutter_lints` 6 until handled deliberately. Fix `pubspec.yaml` SDK floors to match the lock file (Dart and Flutter minimums are understated).
10. **Doc drift.** Fix `docs/publishing-guide.md` (duplicate paragraph at 540-544, APK-on-GitHub sections), the README sections that mention `_debugDemoDelay` and the Naskh font, the stale `release.yml` comment in `ci.yml`, and the `installer.iss` prefs-path comment.
11. **Commit `docs/research/` and `docs/roadmap.md`.** From now on update `ideas-pool.md` in every release.

---

# W2 (0.2): data safety, feedback loop, credits

Importance P0 to P1, my effort M, human lane: H11 (pick the code licence, D4).

### Data layer

- **Versioned storage.** New `lib/core/storage/` with one global schema version key, tested migrations (v1 to v2 to v3, none exists for 1 to 2 today), and a rule that a stored schema newer than the build is read-only (today it is rewritten and fields are dropped, `dhikr_controller.dart:305-306`).
- **Atomic writes and rolling backup (Windows).** Mirror the critical keys (entries, interval, history) to `%LOCALAPPDATA%\DhikrReminder\backup.json` via temp file then rename, keep the last 3, and on a failed or empty load restore from the newest good one and show a one-line notice. Debounce the two `setString` calls per tap in `dhikr_stats.dart:132-139`. Flush on `WM_ENDSESSION`.
- **Stable library ids.** Change `tool/library_builder.dart:159-162` so ids no longer hash the text; ship an alias map old-id to new-id, and make `linkEntriesToLibrary` (`dhikr_controller.dart:182-185`) use it and fall back to a normalised-text match. Fix the doc comment at `dhikr_item.dart:90-94`. Add a test that an id survives a text edit. Clean the orphan keys (`stats.today`, `stats.dailyGoal`).

### Feedback loop and credits (cheap, and they collect the human feedback the roadmap needs)

- **"Report a mistake" on every entry.** A small button on the library card that opens the existing GitHub bug-report flow (`bug_report.dart`) pre-filled with the entry id, its text and the app version, labelled `content`. This is how typos found by readers reach you without any server.
- **Credits screen** in Settings: sources and licences, grade legend, font licences, `showLicensePage`. Add a `LICENSE` file for the code (decision D4) and a font licence note.
- **PRIVACY.md matches the code.** It says the hashed IP lasts one day while the pruning is probabilistic and 2 days (`core.mjs:236-240`), and it does not state retention for requests. Fix the document now; the Worker cron that enforces it is in W7.
- Hijri: offer a plus/minus one day adjustment (Egypt's Dar al-Ifta can differ from Umm al-Qura).

### Cleanup

- Delete `lib/impeller_probe.dart` and `impeller_investigation.md` after moving the section 6-7 conclusion into a code comment in `outer_glow.dart`. Delete the unused toast subsystem (`app_toast`, `notification_center`, `notification_entry`, `toast_*`, and the `ToastOverlay` mount in `app.dart:56-59`), the unused parts of `gradient_widgets.dart`, `archivedSeries`/`brandNavy` and the Gratovo naming in the theme. Verify with grep and drop the declared-but-unreferenced `Naksh` font in `pubspec.yaml`. Delete `ios/`.

---

# W3 (0.3): Android works on new phones

Importance P0, my effort L, human lane: H6 (Oppo and Xiaomi phones for the brand deep links), H7 (Play foreground-service text). About a third of Egyptian phones run Android 15 or 16, where the card may never appear.

- **Get an Android 15 and 16 test bench.** Install the emulator and Android 15 and 16 system images with `sdkmanager` (the SDK command-line tools exist, hardware virtualisation is on, about 62 GB free on C). I will ask before the multi-gigabyte download. Add Android 11 and 13 images later for the version matrix.
- **Android 15+ delivery path.** First confirm on the emulator with `adb shell am compat enable FGS_SAW_RESTRICTIONS com.gratovo.dhikr_reminder`. Google's background-start page (read in full) lists these exemptions that could apply to us: the user turned battery optimisation off for the app; the app holds the overlay permission AND (target 15+) has a visible overlay window right now; the user interacted with a notification, widget or bubble; an exact alarm for an action the user requested (the page does not say which alarm APIs count, and ours are inexact `setAndAllowWhileIdle`, so assume no); boot, package-replaced, time, timezone and locale receivers. Try these candidate fixes in order and keep the first that works on the emulator without a battery exemption: (a) add a small `TYPE_APPLICATION_OVERLAY` window straight from the alarm receiver (allowed with the overlay permission, no service needed) and start the foreground service and the lock-screen activity once it is visible (`OverlayService.kt:145-163`; the lock-screen activity is started with a plain `startActivity` at `OverlayService.kt:149`), (b) schedule with an exact alarm the user has granted (adds another special permission; check Play's policy on `SCHEDULE_EXACT_ALARM` first, and `USE_EXACT_ALARM` is for alarm and calendar apps only), (c) a plain high-priority heads-up notification. A full-screen-intent notification is ruled out: Play only turns that permission on by default for calling and alarm apps and needs a declaration, and we are neither (the app uses no full-screen intent today). Whatever wins, make battery exemption the first setup card (`setup_requirement_cards.dart:27-45`), because it is itself an official exemption, and keep the notification fallback working and honest. The lock-screen card needs the same check.
- **Native event log.** A ring buffer in `ReminderStore`: scheduled time, fired time, path taken (card, lock screen, notification, dropped-busy) and any exception such as `ForegroundServiceStartNotAllowedException`.
- **Reminder health card** in Settings (reuse the red-card pattern in `setup_requirement_cards.dart`): notifications enabled and channel importance, overlay, battery exemption, standby bucket, background-restricted, unused-app (hibernation) status with a button to the system setting, armed alarm count, next three fire times, last fire. Show red "reminders stopped" when the gap since the last fire is over twice the interval while a plan is armed. Add the same snapshot and the manufacturer to `bug_report.dart`, and one line to `PRIVACY.md`.
- **Real-path test.** Add "test through the real alarm in 30 seconds" next to "Show a reminder now" (`test_reminder.dart:15-28`), because the current test starts the service from the foreground and hides the Android 15 problem.
- **Self-healing.** A persisted `JobScheduler` job (about every 12 h, survives reboot, no new dependency) that runs `topUp` and probes whether the last armed `PendingIntent` still exists. New receivers for `TIME_SET`, `TIMEZONE_CHANGED`, `LOCALE_CHANGED` (refresh labels and channel names), `MY_PACKAGE_REPLACED` and `QUICKBOOT_POWERON`. Native channel names become localised resources.
- **Opt-in "always on" mode.** A switch that runs a low-importance persistent foreground service for phones that wipe alarms. The health card explains when to turn it on. It needs an updated Play foreground-service declaration (text in `docs/publishing-guide.md`); if Play rejects it, remove the switch and nothing else changes.
- **Per-brand guidance.** Deep links and plain-language steps chosen by `Build.MANUFACTURER`, with a fallback to the generic battery screen. Priority follows Egypt's market (StatCounter, mobile, Aug to Sep 2026): Samsung about 23 to 25% (sleeping apps, "appear on top"), Oppo about 16 to 17% and Realme about 8 to 11% (ColorOS auto-launch and battery rules, the most aggressive killers), Xiaomi about 10 to 12% (HyperOS autostart, lock-screen popups), then Vivo and Huawei. The intents cannot be verified without those phones, so borrow one of each for 30 minutes (H6) and use the generic fallback until then.
- **Backup rules.** Set `dataExtractionRules`/`fullBackupContent` so Auto Backup restores the dhikr list but excludes the `dhikr_overlay` prefs (stale armed ids), and re-plan on first launch after a restore. Set `supportsRtl`.
- Test predictive back and edge-to-edge on the Android 16 emulator; 16 KB page alignment already passes.

---

# W4 (0.4): polite reminders

Importance P2 (annoying reminders are the main reason people uninstall a reminder app), my effort M, human lane: H9 (Arabic phrasing). Shared rule: each setting lives in `DhikrSettings` and is enforced natively on Android (`ReminderStore`/`ReminderDelivery`), because Dart is not running when alarms fire.

- **Quiet hours** (start/end) on both platforms. The Android lock-screen path currently lights the screen at any hour (`LockScreenReminderActivity.kt:37-48`).
- **Pause options**: 1 hour, until tomorrow, custom. The tray row respects pause (`tray_menu_panel.dart:222-231`).
- **Auto-hide and snooze.** An ignored card hides after N minutes without counting as done, with a "later" action. The scheduler skips ticks while a card is up, so an ignored card currently blocks the next one forever.
- **Windows do-not-disturb.** Defer reminders during fullscreen, presentation or Focus Assist using `SHQueryUserNotificationState` from the runner channel.
- **Respect Do Not Disturb and Bedtime mode** on Android (`NotificationManager.currentInterruptionFilter` checked at fire time), default on, with a visible setting.
- **Not during a phone call** on Android: skip the card while `AudioManager.getMode()` is in call or ringing (no permission needed), and show it after.
- **Wait until I am back** on Windows: if there has been no keyboard or mouse input for N minutes (`GetLastInputInfo` from the runner), hold the reminder and show one when the person returns, instead of piling up cards on an empty desk.
- **Interval jitter** (up to plus or minus 25%, off by default) so the app does not become a thing people stop noticing.
- **Per-dhikr active hours**: clock windows the person sets (sleep dhikr only in the evening). Not prayer times; the person picks the hours. Enforced natively on Android.
- **No-immediate-repeat** in the weighted pick, tested in `reminder_planner.dart` and mirrored in the native plan.
- **Windows runner and shell.** Show the reminder without stealing focus: `SW_SHOWNOACTIVATE` and `WS_EX_NOACTIVATE` in the runner's `dhikr_reminder/window` channel (the Dart `show(inactive: true)` at `app_shell.dart:524` is ignored by window_manager 0.5.2). Add an input guard so a click that was already in flight does not count the first 400 ms. Mixed-DPI monitor choice (`app_shell.dart:654-662`), taskbar overlap at 125-150% scaling, remember the settings window position, set a minimum window size, localise the hard-coded Arabic tray tooltip (`app_shell.dart:87, 385`). Tests for `AppShellNotifier` (684 lines, untested) around the queue, prewarm and reminder transitions. Cache the 9-size tray icon render and shorten the 1.8 s splash on autostart launches.

---

# W5 (1.0): what the owner asked for

Importance P2, my effort L, human lane: H6 (feel the haptics, one TalkBack listen), H9, H12 (soak). Ships as 1.0 when the checkpoint below passes.

Research behind the counter: competing tasbih apps win on a fast tap target, haptics, one-tap undo, goals and not showing ads; users complain most about ads, alerts that fail silently, and accidental taps. Android-specific evidence is thin, so treat the list as directional.

### Sessions and the sequence runner

- **Morning and evening sessions.** Opt-in, at clock times the person sets, running the morning or evening library entries in order with a "3 of 31" progress line, using the existing tags. Android sessions are native alarms with a session plan in `ReminderStore`. The session runner is built as a general "ordered sequence of (library id, count)" so the counter, the wird, memorisation reviews and timed dhikr reuse it.

### Counter

- **A counter screen**, opened from a dhikr in the Notifications list or the library ("Count now"), from the Windows tray, and later from the widget and tile. Tap anywhere to count. Also a plain "free counter" with no dhikr text (a number, not a typed dhikr).
- **Counting comfort.** Haptic strength setting (off, light, strong), a clear cue at the target (haptic, optional sound) that tells the person when the phone is on silent so the cue never seems "broken", one-tap undo placed away from the tap area, reset by long press instead of a confirmation, a hold-to-lock switch against accidental taps, keep-screen-on while counting, and resume where the person stopped.
- **Cycles.** A target can be a number of rounds, for example 10 rounds of 100, with a round counter beside the count.
- **Sequences.** Ordered (library id, count) lists such as 33, 33, 34 with auto-advance, and the morning and evening sets. Built-in sequences are data built from existing tags.
- **Android volume keys, in-app only.** Opt-in; `MainActivity.onKeyDown` while the counter is on screen. Counting with the screen off is rejected: it needs a media-session or accessibility trick that Play reviews badly.
- **Windows keyboard.** Space and Enter count in the counter window. Optional global hotkey (default off, person picks the key, clear message if the key is taken) that counts the current dhikr while another app has focus. Implement natively with `RegisterHotKey` on the existing `dhikr_reminder/window` channel (about 60 lines of C++, no dependency). `hotkey_manager` 0.2.3 exists but its repo looked slow-moving; a dependency we would have to babysit goes against the goal.
- **One store.** Every count (card tap, counter, hotkey, later widget, tile, notification) writes to `dhikr_stats` through the existing tap queue (`drainTaps`, `recordTaps`), so History and goals stay correct. Undo adjusts the same store.

### History, sound, personal plan

- **History and streaks.** Store per-day totals for the last 400 days (compact JSON, included in the backup). A small History view: last 7 and 30 days as simple bars, total, and a streak line that can be switched off in settings. Entirely on device; the Play Data safety form does not change.
- **Sound.** Optional, off by default. The tones are generated by code (short soft chimes written as audio data at build time), so no recording and no licence is involved; you pick the one you like (H9). Native on both platforms with no new Dart dependency (Windows through the runner, Android through the overlay service and channel), respecting silent and vibrate modes. This revives the dead mute scaffolding (`dhikr.muted`, `traySoundOn`, `notifSound*`) or deletes what is left.
- **Favourites**: a star on library cards, a filter, and favourites first in "Add dhikr".
- **My wird**: a named ordered list built only from library entries with targets, run by the sequence runner, optionally started by a morning or evening session. The wird's name is a label the person types; the dhikr inside are always library entries. Daily goals already exist per dhikr; extend them so a completed goal lowers that dhikr's chance in the weighted pick (goal-aware chance), so the app stops nagging about what is done.
- **Gentle feedback**: a calm completion cue, a private streak, a weekly summary in History. No badges, no sharing, no "you missed". Streak line stays switchable.
- **Backup and restore.** Windows: the rolling backup from W2 plus manual export/import of a JSON file using one official file-selector package. Android: Auto Backup from W3 plus the same manual export/import. A wird travels inside the backup file only; there is no sharing feature. The export format is versioned and documented from day one (it becomes the migration path to a Store install in W12).

### Comfort basics

- **Accessibility baseline.** `Semantics` on the reminder card, Space/Enter to count and Esc to close when the Windows card has focus, native content descriptions on the Android card, tooltips and 48 px targets for the close icon (`dhikr_reminder_overlay.dart:840-851`), contrast fix for the hint text (`border_frame.dart:216-227`, about 2.5:1), honour `disableAnimations`, and text scaling in the tray menu (`app_shell.dart:67`). Fix the RTL alignment of Arabic subtitles in English mode (`dhikr_library_card.dart:85-125`).
- **First run.** Language choice that starts from the phone/PC locale (today it starts Arabic and may flash), and a one-time "the app lives in the tray, pin it" hint on Windows 11.
- **Theme** choice: light, dark, system (`app.dart:33` is system only).
- Decision D2 stays: no typed dhikr.
- Tests: counter state machine (undo, reset, auto-advance, lock, cycles), a stats merge test for counts made while the app was closed, widget tests for RTL layout.

### Checkpoint 1.0: reminders you can trust

Acceptance checklist (all must pass):

- All CI jobs green on Linux, Windows and Android; server tests green.
- 14-day unattended soak on a Windows PC and the Android phone (H12): the event log and daily totals show reminders arrived at every expected time, across a reboot, an app update and a sleep/resume. The soak runs in the background while W6 is built.
- Device matrix: the Samsung phone (Android 12) plus emulators for the versions Egyptians actually run (StatCounter 2026: Android 15 about 16%, 16 about 14 to 18% and rising, 13 about 15%, 11 about 14%, 14 about 13%, 12 about 11%), so at least Android 11, 13, 15 and 16, covering card, lock-screen card, notification fallback, always-on mode, boot, update.
- Arabic and English pass: no clipped text, RTL correct, no em dashes, Egyptian phrasing reviewed (H9).
- Docs: README rewritten, `docs/maintenance.md` started, `docs/publishing-guide.md` matches reality, `docs/research/` current, every key and token has a backup location recorded (not in the repo).

The updater signature check and the content checks move to the "trust complete" checkpoint after W8.

---

# W6 (1.1): Android surfaces

Importance P2, my effort M, human lane: H6 tiny (look at the widget and tile on the phone).

- **Android home-screen widget** written natively (`AppWidgetProvider` with `RemoteViews`, reading the same store as the card). Shows today's total and the current dhikr, tap to count one. No `home_widget` dependency: it is a Flutter bridge that still needs the widget written natively, and the app already owns the native side. Updates are pushed on count, not on a timer, to spare battery (`updatePeriodMillis` cannot go below 30 minutes anyway). A tap on the widget, tile or a notification action counts as user interaction, which is an official background-start exemption, so these surfaces are safe on Android 15+.
- **Quick Settings tiles** (`TileService`, minSdk 26 is fine): "Count one" and "Pause reminders for an hour". The tile counts in `onClick()` without opening the app: keep the count in prefs (the service can be unbound between events), update the tile in `onStartListening`, and never use `startActivityAndCollapse` with an Intent (deprecated from API 34). When a count arrives from elsewhere while the shade is open, ask for a refresh with `requestListeningState`. The tile can also refresh the widget through `AppWidgetManager` (same app, same UID). Custom native work, small.
- **Notification actions** on the fallback notification: "Done" counts the dhikr, "Later" snoozes. Use broadcast `PendingIntent`s (Android 12+ forbids trampoline activities).
- **App shortcuts** (long-press the launcher icon): "Count one", "Pause an hour", "Library". A static `shortcuts.xml`, no code beyond intents.
- **Windows tray**: "Count one" row and a tooltip with today's total. Jump list and the Windows 11 Widgets board are parked (packaging cost).
- **Copy and share the text.** A "Copy" button (built-in clipboard) and an Android "Share" action that sends only the dhikr text and its source line. No counts, no streaks, ever.
- Taps from the widget, tile, shortcut and notification go through the same tap queue as the counter. Kotlin unit tests for the intent handling beside `PendingRules`.
- Android 16 Live Updates are rejected for counting (promoted ongoing notifications fit a timer or delivery, not a tally).

---

# W7 (1.2): update and release trust

Importance P1, my effort M, human lane: H8 (generate and store the signing key offline), H7 small (Play service-account permission).

### Updater (`lib/core/update/`)

- **Signed releases.** The release script signs the installer's SHA-256 with an Ed25519 private key kept offline and publishes `<setup>.sig` plus a small `latest.json` (version, sha256, signature). The app embeds the public key and fails closed if the signature is missing or wrong (today a missing digest silently drops to size plus `MZ` header, pinned by a test at `update_test.dart:97-108`). Use one small, maintained, pure-Dart Ed25519 package, pinned.
- **Second host and kill switch.** Serve the same `latest.json` from GitHub Pages as a fallback to the GitHub API (also avoids its 60-per-hour-per-IP limit), with a `halt` flag that stops updates if a release is bad.
- **Failure visibility.** A 404 from the release API is shown on the Updates card after repeated failures (today it looks like "no release", `update_source.dart:41-44`).
- **Canary.** `-Mode Publish` creates a prerelease (the updater already ignores prereleases), the owner soaks it on a spare PC, and `-Promote` flips it live. Keep the signing key offline; releases stay a local one-key task.
- Archive `symbols-<ver>.zip` as a release asset so Dart stack traces from old versions can be decoded; also upload the R8 mapping for every Play build (already done).

### Android release safety

- **Staged rollout with a halt.** `scripts/play_upload.mjs` releases to 20% first (`userFraction` 0.2 on the production track, status `inProgress`), a separate task raises it to 100% (`completed`), and a "halt" task sets `halted`. This is the Android equivalent of the updater kill switch. Verified limits from Google's docs and field reports: halting stops new installs only, a new upload can resume a halted rollout, and 100% cannot be halted, so promote to 100% only after the soak.

### Monitoring and Worker upkeep

- `health.yml` (weekly cron): Worker `/health` and the new deep health, latest release has a setup exe and a valid signature, `PRIVACY.md` URL returns 200, opens a GitHub issue on failure (free email to you).
- Worker: deep `/health` that runs a trivial D1 query; `[observability]` in `wrangler.toml`; pin wrangler with a `package-lock.json`. Daily Cron Trigger: prune `rate_events` and `used_challenges`, expire done and declined requests and their owner rows after a stated period (matching the PRIVACY.md text fixed in W2). Admin page: pagination (only the first 100 rows show, `admin_page.mjs:100`), search by text, bulk delete of old pending items; optional weekly digest by GitHub issue. Document the abuse lever: raising `POW_BITS` on the Worker takes effect with no app update (the client obeys up to 28).
- Crash path: write a crash marker from `AppLogger` and, on next launch, offer "Report this crash" through the existing GitHub issue flow with `labels=bug` (`bug_report.dart:144-148`). Android also gets free crash data from Play vitals. No new network endpoint.

### Toolchain and compliance

- Pin `targetSdk` explicitly (`build.gradle.kts:42`) instead of following Flutter's default. After the next Flutter update flip `android.newDsl` and `android.builtInKotlin` to true (`android/gradle.properties:4,6`) before AGP 10 removes the opt-outs.
- Re-check the Play Data safety form, foreground-service text and `PRIVACY.md` against the final behaviour (health snapshot, always-on mode, history). Store assets (feature graphic, screenshots in both languages) are made by the owner (H10) and listed in the runbook.

---

# W8 (1.3): content trust

Importance P1, my effort L (the pipeline is M; checking 281 entries against primary sources is the long part), human lane: H1 (scholar), H4 (licence answers), H12 (soak). Start the human part in W0 so it is ready here.

Research result (opened and read, 2026-10-09): there is no open, verified Hisn al-Muslim dataset to adopt.

- `rn0x/Adhkar-json` (132 categories, full diacritics, count and audio paths, no references, no grades) says in its README that the files have no usage licence ("do what you like for free"). That is not a licence, and the book it copies is the compiler's work. `rn0x/hisnmuslim_app` (MIT, archived) licenses its code only and takes its text from that same repo.
- `fawazahmed0/hadith-api` is under the Unlicense and advertises grades, but its credits list web sources (al-maktaba.org, sunnah.com, others) with no permission stated for them. Not safe to ingest as is.
- Sunnah.com asks reusers to keep grades, collection names and numbers, but its reproduction and scraping terms could not be read (403 from our fetch tool). Not used as a data source.
- English editions of the book are commercial (Darussalam) or hosted on IslamHouse with no stated terms.

So the first step is a gate, not a build, and the realistic path is to verify our own entries by hand.

- **Step 1, licence audit (half a day, no code).** For every candidate source write one row in `docs/research/content-sources.md`: what it is, who owns it, the exact licence text and URL, what we may do with it. A source with no clear licence is not ingested. The H4 answers from W0 go here.
- **Step 2, build from what passes.** Quran verses come from the Tanzil Uthmani text (CC BY 3.0, confirmed on tanzil.net: verbatim only, no changes, copyright notice must be reproduced, link to tanzil.net required). Hadith and dhikr wording comes from the existing entries, re-verified one by one by reading primary sources (Bukhari, Muslim, the Sunan, Ahmad; sunnah.com or al-maktaba.org are fine to read, not to copy from in bulk) and recorded in a checked-in provenance file naming book, hadith number, and grade. I do the first pass of matching entries to sources; the scholar (H1) signs off. Diacritics are taken from verified sources, never invented by a model. Hadith wording itself is not owned by anyone; what a modern book owns is its selection, translation and commentary, so we keep our own selection and our own wording of references and never copy a translation or a book's grading text. If unsure about one source, leave it out and ask a knowledgeable person. `Adhkar-json` and `hadith-api` may be used only as a cross-check to spot typos, never as shipped data.
- **Hard rules in the generator** (it fails the build otherwise): every entry has a `reference` naming its book and number, a `grade` (Quran, sahih, hasan, or unspecified), full diacritics, no duplicate normalised text, and none of the known scrape defects (alef maqsura for yeh, glued words, placeholder descriptions, "قال تعالى" duplicates). Entries over 500 characters stay reading-only or move out; count-0 entries are fixed or dropped. Replace the scrape pipeline (`tool/generate_library.dart`, `tool/library_builder.dart`, `tool/data/zekrel_scraped.json`) with checked-in sources plus a provenance file; output stays `lib/features/library/data/dhikr_library_data.dart`.
- **Quran entries are shown exactly as supplied.** The tashkeel toggle does not apply to them (the Tanzil licence forbids changing the text), and the Credits screen (W2) reproduces the Tanzil notice and link.
- **Review list for a person.** The file made in W0, kept current: the roughly 42 entries that carry a virtue claim, plus anything weak or disputed such as the morning/evening salawat item. Nothing ships with a claim that has no source.
- **Seeds and display.** Vocalise the 5 seed dhikr (`dhikr_controller.dart:195-201`); the tashkeel toggle becomes visible once the data has diacritics (`dhikr_library.dart:38-45`). Mark near-duplicate counts (for example 33 vs 100) as variants of one entry.
- **Tests:** `test/dhikr_library_test.dart` gains checks for references, grades, duplicates, Quran entries unchanged against the Tanzil text, and the alias map from W2. A migration test confirms an install with old ids keeps its reminders.

### Checkpoint: trust complete

- Updater: a signed canary installs on a spare PC; a bad signature and a missing signature are both refused.
- Content: generator passes with zero unsourced entries; scholar spot-check done (H1).
- The 14-day soak repeated on both platforms (H12).

---

# W9 (2.0): comfort and access

Importance P3, my effort M, human lane: H3 (watch a parent try simple mode), H6 (TalkBack and Narrator listening sessions).

- **Simple mode** for parents and elders: one switch (and a setup wizard someone can run for another person) that hides the library and most settings, shows large text and three big buttons, and keeps only interval, a few dhikr and pause.
- **Per-app language on Android 13+**: add `generateLocaleConfig = true` and `resources.properties` (AGP 8.1 or newer, we have 9.1) so the system's per-app language screen lists Arabic and English; keep Flutter's `supportedLocales` in step and test on an Android 13 emulator.
- **Accessibility audit with real tools**: TalkBack and Narrator sessions, Accessibility Insights for Windows, 200% text, keyboard-only on Windows, a high-contrast theme, reduce motion, contrast check. Arabic-Indic numerals option everywhere numbers show (counter, widget, History).
- **Gentle style**: a small chip or notification instead of the full card, a corner position on Windows, card size and position choices, and a few calm palettes. Independent card text size. An optional rosary-bead or ring look for the counter.
- **Large screens**: adaptive layouts for tablets and foldables (Play's quality guidance), landscape card, and a pre-check against the next Android preview.
- **Localisation hardening**: pseudo-locale test, RTL golden tests for the card, library and counter.

---

# W10 (2.1): depth

Importance P3, my effort L, human lane: H1 (99 Names label, duas), H2 (meanings review). This is the most human-bound wave; ship meanings for the top 60 entries first if reviewer time is short.

- **Per entry**, all optional to show: a Latin transliteration (one simple documented scheme, written by us; I draft it, no reviewer needed beyond a spot check), a short plain-Arabic meaning, an English meaning, and the existing "when to say it" tags and virtue note with grade. Meanings are drafted by me in small batches and checked by a reviewer (H2), or taken only from sources whose licence was checked in W8's audit. No scraping of commercial translations.
- **Where it shows**: expandable on the library card, and as one optional line under the Arabic on the reminder card (off by default).
  - Started early (2026-10-09, drafts only, still needs a reader who knows the recitation): a Latin transliteration for 250 library entries in `lib/features/library/data/dhikr_transliteration_data.dart`, shown under the Arabic on the library cards, the desktop card, the phone's floating card and the in-app phone screen. One switch in the library settings turns it on (on by default in English, off in Arabic); a second "Show Arabic" switch, in the library settings and again on the Notifications page for the reminder card, hides only the Arabic. Entries that are explanation rather than words to say, and the two very long funeral supplications, have none yet.
- **Search by meaning and by transliteration.**
- **The 99 Names (الأسماء الحسنى)** as a library section, one entry each, with meaning and a short note on calling on Allah by His Names. The numbered list is a compilation (the enumerating narration is disputed), so it is labelled "compiled list" and goes on the scholar review list.
- **Memorise mode** for any library entry: stage 1 read it; stage 2 every third word fades; stage 3 only the first words show; stage 4 blank with a "peek" button. The person rates themselves (easy, ok, again). Works on the card, the counter and the library page. Quran entries stay verbatim in every stage (Tanzil licence): the fading is a display layer over unchanged text.
- **Light spaced review**: a plain schedule (1, 3, 7, 14, 30 days) kept on the device. Due entries appear as part of a normal reminder or a morning session, never as an extra nagging channel. Entirely local, no scoring, no leaderboard.
- **Situation finder**: a short list of situations (waking, leaving home, travelling, rain, worry, illness, eating, sleeping) built from existing tags, each leading to the matching entries. A fast "I need a dua now" path.
- **Coverage audit against the book**: map every chapter of Hisn al-Muslim to library entries, list the gaps, and fill them through the W8 process (sourced, graded, reviewed). Not a copy of the book; the chapter list is only a checklist.
- **Quranic duas section** (for example the "Rabbana" supplications): library entries with counts, text verbatim from Tanzil with the notice. Entries only, no surah browsing and no reader.
- **Extra languages for meanings only** (decision D3): each language is one data file reviewed by a fluent reader. The UI stays Arabic and English.
- **Recorded audio**: research gate, not a build, and today nothing qualifies. Checked 2026-10-09: no adhkar recitation under a Creative Commons licence was found; Makkah Live's adhkar MP3s are personal-use only; the Adhkar-json audio (Hamad Al-Duraihim) has no licence. Quran recitation is different: the King Fahd Glorious Qur'an Printing Complex offers its recitations for free general use in apps, and Islamic Network licenses Quran recordings for free redistribution (but the reciters can ask for removal), while everyayah.com asks for a link back and one set lists its licence as unknown. So only the Quranic parts of some adhkar (Ayat al-Kursi, the last three surahs) could ever have audio, and only after the exact terms are copied into `content-sources.md`. Text-to-speech of religious text is rejected (mispronunciation risk). Audio stays parked (H5) until a written licence or permission is on file.
- Tests: every entry with a meaning has the reviewed flag; transliteration scheme round-trip on a fixed sample; the stage masking is deterministic and reversible; schedule maths for each rating; every situation resolves to at least one entry; the coverage report is part of CI output.

---

# W11 (2.2): fit a life

Importance P3, my effort M, human lane: none.

- **Profiles**: named sets of interval, entries, quiet hours and sound (for example Work, Home, Travel, Ramadan). Switched by hand from the tray, the Quick Settings tile or the app, or on a fixed weekday and time schedule the person sets. No Hijri-calendar auto switching: that would turn the app into a calendar app.
- **Long goals**: a personal target counted over weeks or months (for example one million salawat), with a plain progress bar. Private, no sharing.
- **Per-dhikr lifetime totals** and a month view in History (extends the 400-day store with a small totals table).
- **Gentle suggestions**: if cards at the same hour were ignored many times, the app offers (never forces) to add that hour to quiet hours. Plain rules on local history, no AI.
- **Timed dhikr**: a session of N minutes of free dhikr with a soft cue at the end, for example ten minutes of istighfar, counting optional.
- Soak test repeated because profiles change scheduling.

---

# W12 (3.0): reach

Importance P3 to P4, my effort L, human lane: H7 (accounts), H10 (store assets), H11 (D1, D5).

- **Microsoft Store channel (decision D1).** Research: individual registration is free (announced September 2025); the Store re-signs MSIX packages at no cost; an unpackaged EXE would need our own certificate, so MSIX is the route. Work: MSIX build (the `msix` pub package or the Flutter MSIX flow), `StartupTask` in the manifest instead of the Run key, the self-updater switched off when running packaged (the Store updates it), prefs live in a different place for a packaged app so users migrate through the W5 export/import file, runner single-instance logic re-checked, the `runFullTrust` capability and its justification in the submission (expected, verify), Windows App Certification Kit run, Store listing in both languages. The GitHub installer stays for people who prefer it; both are built by the same script. If the Store reviews badly, nothing else changes.
- **winget** (optional, only if the Store is declined): `wingetcreate submit` in the release script. Read in the winget-pkgs manifest docs: every tool must support a silent install (our Inno `/VERYSILENT` does), and MSIX packages must be signed; no signing rule was found for other installer types. SmartScreen reputation is per file hash, so winget does not remove the warning. Still unverified: the repo's current validation pipeline (installer scan), so test with `winget validate` and the Sandbox script before any submission.
- **Landing page on GitHub Pages** (Arabic and English): what the app is, privacy policy, download links for each channel, screenshots, and the `latest.json` host from W7. It becomes the single stable URL that Play, the Store and other stores point to.
- **Other Android channels (decision D5).** F-Droid requires free code and free dependencies, allows the Flutter SDK as an exception, and either signs with its own key or accepts our APK if the build reproduces; it does not accept Google services (we have none). IzzyOnDroid republishes our own signed APK from tagged GitHub releases, needs an OSI or FSF licence (decision D4), Fastlane-style metadata in the repo, and no debuggable flag. Both need `-PallowUnsigned=true` handled (W1 item 8). Galaxy Store (Samsung is about a quarter of Egyptian phones) is a free listing worth a trial. AppGallery stays parked.
- Each added channel gets a line in `docs/maintenance.md`: how a release reaches it and what to do if it lags. Re-run the Play Data safety and Store forms; nothing in the app changes.
- **Content correction by pull request**: the `content` issue label from W2 gets a template, and a correction is a pull request to the sourced data file that the generator validates in CI.
- **Meaning languages by community** (decision D3): a documented way to add one language as a data file, accepted only with a fluent reviewer's sign-off recorded in the file.
- **What's new** note after an update: shown once, from a bundled text per version, only if more than a few user-visible changes ship per year.
- No server, no accounts, no moderation queue: everything goes through GitHub.

---

# W13 (next major): sustain

Importance P1 to P4, my effort M, human lane: H8, H14, H15. Ships under whichever major number follows your last chosen wave.

- **Docs for a stranger**: `CONTRIBUTING.md`, `SECURITY.md`, issue templates (bug, content correction), a one-page architecture note, and the content-correction path.
- **Graceful decay, tested**: Worker gone (the request feature shows "unavailable" and hides after repeated failures), GitHub gone (updater idle without errors), Play policy change (notification-only mode already works), signing key lost (documented recovery). A scripted "sunset build" turns the network features off so a last version can live indefinitely.
- **Data longevity**: the export format is frozen and documented; a golden-file test imports every historical export version.
- **Budgets**: idle memory and CPU for the tray app, install size, cold start time, and on Android no wake locks and a battery-stats check, all measured in the soak and written into the runbook.
- **Security pass**: one-page threat model, dependency audit, admin token and signing key rotation rehearsed once.
- **Dependency diet**: list every package, keep only what earns its place, and replace small ones with native code where that is cheap, so there is less to babysit.
- **Toolchain rhythm**: upgrade Flutter on a branch at most twice a year and run the full checklist; the pinned versions and the upgrade steps are in the runbook.
- **Bus factor**: a trusted second person (or sealed instructions) can cut a release or retire the project from `docs/maintenance.md`.
- **Final audit**: walk the whole idea pool (`docs/research/ideas-pool.md`), mark each idea shipped, parked with a trigger, or rejected, run the two brainstorm passes from the Stop rule, then declare the idea pool empty.

## Maintenance mode (after the final audit)

Automation does: Dependabot PRs merge on green CI; weekly health check opens an issue if anything external breaks; Play vitals email on crashes.

You do (put these in a calendar):

- **July to August each year:** Google raises the minimum target API (Android 17 is expected next). Bump `targetSdk`, build, run the device matrix on emulators, upload through the existing task with a staged rollout. Ignoring it blocks Play updates.
- **Every quarter:** open Play Console once so the account never looks abandoned; read the policy emails.
- **Every year:** rotate the GitHub token and the Play service-account key; confirm the upload keystore backup still opens; re-check the `Re-check by` dates in `docs/research/`.
- **When a Dependabot PR is red or Flutter forces a major upgrade:** fix, or stay one version behind until forced.
- **When a bug report arrives:** triage within a month. Releases happen only for crashes, a Play policy notice, a broken updater, or a dependency security advisory.

Things that will end the project if ignored: the Play developer account closing, the Worker or GitHub owner disappearing (the Worker URL and `i-Light` are hard-coded in shipped apps), and losing the upload key. The runbook lists the recovery step for each.

---

## Idea pool

The master list of all 101 ideas, with origin, importance, my effort, human work and wave, lives in `docs/research/ideas-pool.md` so there is one copy to keep current. Parked and rejected ideas, and the stop rule that declares the pool empty, are there too. (The roadmap used to carry a duplicate of the table; it moved, nothing was dropped.)

## Research folder (created 2026-10-09)

`E:\programming\Flutter\dhikr_reminder\docs\research\` holds what the web and the code told us, so a later session starts from it. Keep it current in every release.

```
docs/research/
  README.md            index, the note template, how to add a finding
  competitors.md       tasbih and dhikr apps: features, complaints, gaps
  content-sources.md   every dataset and book checked: owner, exact licence, verdict
  android-platform.md  Android 15 background-start rule, widgets, tiles, DND, Play policy, Live Updates fit
  windows-platform.md  hotkeys, Store and MSIX, winget, toasts, SmartScreen
  distribution.md      Play, Store, F-Droid, IzzyOnDroid, Galaxy Store, staged rollout, market data
  ideas-pool.md        the master sorted list, kept current
```

Each note starts with: `Checked: <date>`, `Confidence: confirmed | likely | unverified`, `Sources:` (links), `Re-check by: <date>`. A finding that a decision depends on is never left only in chat.

## Research digest

Checked 2026-10-09. The full notes with links are in the files above; this is the short version.

- **Tanzil licence (confirmed):** Creative Commons Attribution 3.0. Verbatim copies only, "changing it is not allowed", the copyright notice must appear, and use in an app needs a clear source and a link to tanzil.net.
- **Hisn al-Muslim data (confirmed by opening the repos):** `rn0x/Adhkar-json` has no usage licence ("do what you like for free"), no references, no grades. `rn0x/hisnmuslim_app` is MIT for code only. The `adhkar` pub package is MIT code. None is an open licensed text source. English editions are commercial (Darussalam) or hosted without stated terms.
- **Hadith data (confirmed on the repo page):** `fawazahmed0/hadith-api` is under the Unlicense, but the sources it credits state no permission. Sunnah.com's reproduction terms could not be read (403); owner task H4.
- **Android background-start exemptions (confirmed, read in full):** visible UI state; user interaction with a notification, widget, bubble or activity; an exact alarm for a user-requested action (no API named); boot, package-replaced, time, timezone and locale receivers; the user turning battery optimisation off; the overlay permission plus (target 15+) a currently visible overlay window. `specialUse` is not mentioned. Test flag: `adb shell am compat enable FGS_SAW_RESTRICTIONS <package>`.
- **Full-screen intents (confirmed):** for apps targeting Android 14+, Play turns the permission on by default only for calling and alarm apps and needs a declaration. Our app uses none and should not start.
- **Play permission policy (confirmed):** the overlay permission is granted on a system settings page; do not pressure the user; the app must still work if declined. No declaration form for it is listed; check the Play Console form list once.
- **Quick Settings tile and widget (likely):** keep tile state in prefs, update in `onStartListening`, avoid `startActivityAndCollapse(Intent)`, use `requestListeningState`; `updatePeriodMillis` minimum is 30 minutes.
- **Adhkar audio (confirmed absence):** no Creative Commons adhkar recitation found. For the Quran: King Fahd Complex offers free general use in apps; Islamic Network has a removal-on-request caveat; everyayah wants a backlink.
- **Competitors (directional):** volume-button counting, haptics, one-tap undo, auto-advance presets, goals, streaks, widgets, offline, no account. Main complaint is ads; others are silent alerts and accidental taps.
- **Windows hotkeys (likely):** `hotkey_manager` 0.2.3 works system-wide but looked slow-moving; a native `RegisterHotKey` is the plan.
- **Microsoft Store (likely, confirm at storedeveloper.microsoft.com):** individual registration free since September 2025, identity check by ID and selfie. MSIX is signed by the Store at no cost and updated by it. An unpackaged EXE must be signed by us.
- **winget (likely):** silent install required; MSIX must be signed; no signing rule found for other types; SmartScreen reputation is per file hash.
- **Egypt market (likely, StatCounter 2026):** Samsung about 23 to 25%, Oppo about 15 to 17%, Xiaomi about 10 to 12%, Realme about 8 to 11%. Android 15 about 16%, 16 about 14 to 18% and rising, 13 about 15%, 11 about 14%, 14 about 13%, 12 about 11%.
- **F-Droid and IzzyOnDroid (likely):** F-Droid needs free code, dependencies and tools, rejects Google services, and signs with its own key unless the build reproduces; signing must be optional. IzzyOnDroid republishes the developer-signed APK from tagged GitHub releases and needs an OSI or FSF licence.
- **Per-app language (confirmed, Android docs):** needs a `localeConfig`; AGP 8.1+ can generate it.
- **Play staged rollout (confirmed):** `userFraction` with `inProgress`, `halted` stops new installs only, a new upload may resume a halted rollout, 100% cannot be halted in the Console.
- **This PC (checked 2026-10-09):** Android SDK command-line tools present, no emulator or system images installed, hardware virtualisation on, about 62 GB free on C and 122 GB on E. Platforms installed: 33, 34, 36.
- **Still unverified:** sunnah.com reproduction terms; Store `runFullTrust` and any extra review for an always-on tray app; whether `setAndAllowWhileIdle` counts as the exact-alarm exemption (assume no); the Play Console form list for the overlay permission; winget-pkgs' current installer scan; the Hisn al-Muslim compiler's or publisher's own reuse policy; how Flutter reports a per-app locale change on Android 13+.

---

## Critical files by theme

- Android native: `android/app/src/main/kotlin/` (`MainActivity.kt`, `ReminderReceiver.kt`, `ReminderAlarms.kt`, `ReminderStore`, `ReminderPlan.kt`, `OverlayService.kt`, `LockScreenReminderActivity.kt`, `PendingRules.kt`), `AndroidManifest.xml`, `build.gradle.kts`, `gradle.properties`. New in W6: an `AppWidgetProvider`, two `TileService` classes, notification action receivers, `shortcuts.xml`.
- Android Dart: `lib/features/mobile_reminders/` (`mobile_reminder_host.dart`, `reminder_planner.dart`, `setup_requirement_cards.dart`, `overlay_service.dart`).
- Scheduling and state: `lib/features/settings/application/dhikr_controller.dart`, `dhikr_reminder_controller.dart`, `lib/features/stats/dhikr_stats.dart`.
- Windows shell: `lib/core/window/app_shell.dart`, `windows/runner/flutter_window.cpp`, `main.cpp`, `Runner.rc`, `lib/platform/autostart.dart`.
- Library and content: `tool/library_builder.dart`, `tool/generate_library.dart`, `lib/features/library/`.
- Updater and release: `lib/core/update/`, `scripts/build_windows.ps1`, `scripts/build_android.ps1`, `scripts/publish_android.ps1`, `scripts/play_upload.mjs`, `.vscode/tasks.json`, `.github/workflows/ci.yml`.
- Backend: `server/src/core.mjs`, `admin_page.mjs`, `wrangler.toml`, `lib/features/requests/`.

Reuse rather than rebuild: the red setup-card widgets (`setup_requirement_cards.dart`) for the health card; `planReminders` and its `pausedUntil`; `PendingRules` unit-test pattern for new native rules; the overlay tap queue (`drainTaps`, `recordTaps`) for every new counting surface; the W5 session runner for sequences, wird, memorisation reviews and timed dhikr; `AppLogger` and `bug_report.dart` for the crash path and the "Report a mistake" button; the existing `/health` route and the Worker's `core.mjs` test harness; `scripts/play_upload.mjs` and the VS Code Play tasks for Android releases.

## Verification

Per release:

- `flutter analyze --fatal-infos`, `flutter test` (about 34 s), `node --test` in `server/` (59 tests today), `./gradlew :app:testDebugUnitTest` once added to CI (W1).
- Android on the Samsung A21s (Android 12): build with `--build-number=2003` so `adb install -r` upgrades in place; change one permission at a time and restore it (see the test-phone notes); check card, lock-screen card (phone is PIN-locked, so use `adb exec-out screencap -p` and `dumpsys window`), notification fallback with overlay denied, reboot, and `dumpsys alarm` for armed alarms. Relaunch the app at the end because `am force-stop` cancels alarms.
- Android 11, 13, 15 and 16: emulators installed in W3, with `FGS_SAW_RESTRICTIONS` enabled for the first Android 15 fix, because the real phone cannot show that failure.
- Windows: run the debug build, or install the release build only when the installed copy is closed; check tray, countdown, pause, reminder with another app fullscreen, sleep/resume, and corrupt-prefs recovery by truncating `%APPDATA%\com.gratovo\dhikr_reminder\shared_preferences.json` on a test profile.
- Updater: signed canary on a spare PC; tamper with the `.sig` and confirm refusal.
- Worker: `node server/dev.mjs --memory` for local runs; after deploying changes, hit `/health` and the deep health route.
- W5 to W11 extras: counter, sequence, memorise and schedule tests; widget, tile, shortcut and notification actions on the phone and on a stock emulator (count while the app is killed, then open the app and check History); global hotkey with another app focused; Store build run through the Windows App Certification Kit before submission; TalkBack and Narrator sessions recorded in the release notes; staged rollout halted and resumed once on the internal track before first real use.
- Soak: the 14-day soak runs in the background after W5 and after W8, and the final one in W13.
