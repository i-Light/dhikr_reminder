# Publishing guide: from this repo to Google Play

Follow this top to bottom, tick the boxes as you go. It assumes you have never
published an app before. It is written to be used without Claude: every command
and every click is here.

Related files:

- [google-play/listing.md](google-play/listing.md): the store listing text in
  English and Arabic, ready to paste (kept separate because you copy from it).
- [../PRIVACY.md](../PRIVACY.md): the privacy policy Play asks for.

Google changes the names of buttons and menus in Play Console from time to
time. If a name below does not match, look for the closest one; the idea is the
same. When in doubt, the Play Console Dashboard has a "Set up your app" list that
says exactly what is still missing.

---

## 0. Words you will meet

| Word | Meaning |
| --- | --- |
| **AAB** (App Bundle, `.aab`) | The file you upload to Play. Google builds the small per-phone APKs from it. You cannot install an `.aab` yourself. |
| **APK** (`.apk`) | An installable file. Used for GitHub downloads and quick tests, never uploaded to Play for a new app. |
| **Package name / application id** | `com.gratovo.dhikr_reminder`. It is the app's permanent identity. It can never be changed after the first upload. |
| **Version name / version code** | `pubspec.yaml` has `version: 0.1.3+4`. `0.1.3` is the version name people see. `4` is the version code (build number). **Every upload to Play needs a higher version code than any upload before it, on any track.** Same number twice is rejected. |
| **Upload key** | The key you made with `create_upload_key.ps1`. It proves to Play that an upload comes from you. |
| **App signing key** | The key Google keeps (Play App Signing, on by default). It signs what people actually install. It is not the upload key. |
| **Track** | A release channel. **Internal testing** (up to 100 testers, no wait), **Closed testing** (the invited testers; internally called `alpha`), **Open testing** (anyone can join), **Production** (everyone). |
| **Service account** | A robot login that lets `scripts/publish_android.ps1` upload for you without a browser. |

---

## 1. The whole path in one picture

| Phase | What | Time | Who |
| --- | --- | --- | --- |
| 1 | Developer account | 1 hour, plus up to a few days for verification | You |
| 2 | Prepare: key, graphics, video, first bundle | 2 to 3 hours | You |
| 3 | Create the app and fill in the forms | 1 to 2 hours | You |
| 4 | First upload by hand (Internal testing) | 30 minutes | You |
| 5 | Turn on one-click uploads | 20 minutes, once | You |
| 6 | Closed test with 12+ testers | 14 days minimum | Testers, you fix bugs |
| 7 | Apply for production, review, live | 1 to 7 days | Google |
| 8 | Every update afterwards | 5 minutes of your time | One task |

Phase 6 can start as soon as Phase 4 is done. The 14 days are the bottleneck, so
get testers lined up early (Phase 1).

### What is already done in the repo

You do not need to do any of this; it is listed so you know what exists.

| Done in the repo | Where |
| --- | --- |
| Application id `com.gratovo.dhikr_reminder` (permanent once published) | `android/app/build.gradle.kts` |
| Targets Android 16 (API 36), which Play requires for new apps and updates since 31 August 2026 | Flutter 3.47 default |
| Minimum Android 8.0 (the reminder card needs it) | `android/app/build.gradle.kts` |
| Release signing wired to `android/key.properties`; a bundle signed with the debug key is refused by the build script | `scripts/build_android.ps1` |
| Script that makes the upload key for you | `scripts/create_upload_key.ps1` |
| App Bundle build with R8 shrinking and obfuscation | `scripts/build_android.ps1` |
| Store text in English and Arabic | `docs/google-play/listing.md` |
| 512 px store icon | `docs/google-play/icon-512.png` |
| Privacy policy (English and Arabic) | `PRIVACY.md` |
| The only thing the Android app sends is a dhikr request the person chooses to make (internet permission, Data safety answers in 3.3) | `AndroidManifest.xml`, `server/` |
| Updates on Android come from Play, and the app does not try to update itself (Play forbids that) | `Settings` page, update card |


---

## Phase 1. Developer account

- [ ] Go to <https://play.google.com/console/signup> with the Google account that
  should own the app forever. Use an account you will not lose (turn on 2-step
  verification on it).
- [ ] Pay the one-time **US$25** fee.
- [ ] Choose the account type:
  - **Personal** (most likely you). Rule for personal accounts created after
    13 November 2023: before you can publish to production you must run a
    **closed test with at least 12 testers who stay opted in for 14 days in a
    row**. This applies to your first app. Details in Phase 6.
  - **Organization**. Said to skip that rule, but needs a registered business and
    a D-U-N-S number. Not worth it for a hobby app.
- [ ] Verify your identity (a government ID photo), your phone number and your
  email. This can take from minutes to a few days.
- [ ] Know what becomes public: the **developer name** and a **contact email**
  appear on the store page. Use an email you are happy to show.

**Line up testers now.** Aim for **15 to 20 people** (a few always drop out, and
if the count falls below 12 during the 14 days the clock may restart). They need:

- an Android phone with Play Store (not a Huawei without Google services),
- a Google account whose email you know,
- to install from the Play link (not a file), and to keep the app installed for
  14 days.

Friends, family, a WhatsApp group, a masjid group. Write down their Gmail
addresses in a note or a spreadsheet.

---

## Phase 2. Prepare

### 2.1 Make the upload key (once)

- [ ] In VS Code: **Terminal > Run Task > Play: create upload key (once)**.
  (Same as `.\scripts\create_upload_key.ps1`.)
- [ ] Choose a password (at least 6 characters, none of `\ # ! = :`). It writes
  two files in `android/`: `upload-keystore.jks` and `key.properties`. Both are
  git-ignored on purpose.
- [ ] **Back up both files and the password** somewhere that is not this PC: a
  password manager, an encrypted USB stick, a private cloud folder. If you lose
  the key you can ask Play support to reset the upload key, but it costs days. If
  you lose the Play account instead, nothing helps, so protect that too.

The script refuses to overwrite an existing key, so you cannot destroy it by
running the task twice.

### 2.2 Store graphics

| Asset | Requirement | Status |
| --- | --- | --- |
| App icon | 512x512 PNG | Ready: `docs/google-play/icon-512.png` |
| Feature graphic | 1024x500 PNG or JPEG, no transparency | **You make it** (Canva, Figma). The logo plus the app name on a calm background is enough. |
| Phone screenshots | 2 to 8, PNG or JPEG, 9:16 or 16:9, each side 320 to 3840 px | **You take them** |

Good screenshots, in this order: the Settings page with the countdown; a reminder
card floating over another app; the Notifications page with the dhikr list; the
library. Take one set with the phone in Arabic and one in English.

How to take them from your phone (adb screenshots do not need a PIN, but the
phone must be unlocked while you set the scene):

```powershell
$adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
& $adb exec-out screencap -p > shot1.png
```

Or just use the phone's own screenshot buttons and copy the files over.

### 2.3 The permission video

Play reviewers will look at the app's special permissions (draw over other apps,
foreground service, battery exemption). A 30 to 60 second screen recording
answers most questions before they are asked.

- [ ] Record the phone screen (the phone's built-in screen recorder).
- [ ] Show, in order: opening the app; the "display over other apps" permission
  being granted; the card appearing over another app; tapping it until it
  finishes; locking the phone and the card lighting the screen.
- [ ] Upload it to YouTube as **Unlisted** and keep the link. It is pasted into
  the permission forms in Phase 3.

### 2.4 Check the request service is up

"Request a dhikr" talks to the Cloudflare Worker at the address in
`lib/features/requests/data/requests_config.dart`. Open the Worker URL's health
endpoint (see `server/README.md`) and make sure it answers. The Data safety
answers in Phase 3 are only true while it is deployed. **Never change that
address once the app is out.**

It is public, not a secret, so a normal build already points at it. Setting
`$env:DHIKR_REQUESTS_URL` before a build overrides it for that build (to try
another server). To build an app without the feature, run `flutter build`
yourself with `--dart-define=DHIKR_REQUESTS_URL=` (empty); it still declares the
internet permission, so keep the Data safety answers either way.

### 2.5 Build the first bundle

- [ ] Run **Terminal > Run Task > Play: build bundle only**.
- [ ] It runs analyze and tests, then writes
  `build/app/outputs/bundle/release/app-release.aab`. That file is what you upload
  in Phase 4.
- [ ] If it says `key.properties not found`, do step 2.1 first.

---

## Phase 3. Create the app and fill in the forms

Open <https://play.google.com/console>.

### 3.1 Create the app

- [ ] **Create app**.
- [ ] App name: `Dhikr Reminder`. (The Arabic name is added later as a
  translation.)
- [ ] Default language: your choice (English (United States) is fine).
- [ ] **App** (not Game). **Free** (a free app can never become paid).
- [ ] Tick the declarations (developer program policies, US export laws).

### 3.2 Privacy policy address

Play needs a public web page. This repository's policy is at:

```
https://github.com/i-Light/dhikr_reminder/blob/main/PRIVACY.md
```

- [ ] Push the repo to GitHub first (`git push`) so that address works.
- [ ] Paste it under **Policy and programs > App content > Privacy policy**.
  The repository must stay public for as long as the app is on Play.
- [ ] Optional: for a cleaner address turn on GitHub Pages for the repo and use
  the page it gives you instead.

### 3.3 App content (all the declaration forms)

Under **Policy and programs > App content**. Tick each one off as you finish it.
The honest answers, form by form:

| Form | Answer |
| --- | --- |
| Privacy policy | the address from 3.2 |
| Ads | No ads |
| App access | All functionality is available without logging in or any special access |
| Content rating | Fill the questionnaire: no violence, no user-generated content, no purchases. Expect "Everyone" |
| Target audience | 13 and older. Do not pick children: that brings in the Families policy |
| Data safety | See the table below this one |
| Advertising ID | No (the app does not use it) |
| Government app, financial features, health | No / none |
| News app | No |

**Data safety form.** The app collects data only when someone uses "Request a
dhikr". The honest answers are below; check them against the form's wording on
the day, it changes.

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | Collects, yes. Shares with third parties: no |
| Other user-generated content | Collected: the dhikr text (and the source, if given) in a request. Purpose: app functionality. Optional: yes, only when the person uses the feature |
| Device or other IDs | Collected: a random code the app makes for itself so a person can see their own requests. Purpose: app functionality, and fraud prevention and security |
| Is all of the data encrypted in transit? | Yes, HTTPS only |
| Can people ask for their data to be deleted? | Yes: open an issue on the repository, as `PRIVACY.md` says |
| Everything else (location, contacts, photos, files, financial, health, messages, web history, calendar and so on) | Not collected |

This is only true while the request service is deployed (see `server/README.md`)
at the address in `requests_config.dart`. A build made with an empty
`DHIKR_REQUESTS_URL` never connects to anything, but it still declares the
internet permission, so keep the answers above either way.

#### Permissions and foreground service

The app uses four things Play looks at closely. Have the screen recording from
2.3 ready for them; reviewers ask for exactly this.

**Foreground service, type "Special use"** (App content > Foreground service
permissions). Subtype is already declared in the manifest. Paste:

> The app shows a floating reminder card over other apps when a scheduled dhikr
> reminder is due. The user turns this on themselves by allowing "Display over
> other apps". A foreground service is used only while the card is on screen
> (from a few seconds up to three minutes) and stops itself as soon as the user
> finishes counting or dismisses the card. If a reminder came due while the phone
> was locked and nobody counted it, the service also stays until the next unlock
> (a reminder nobody got to within 12 hours is dropped, and the service stops
> with it) so the card can be shown again then; it never runs for any other
> reason. Without a foreground service Android
> stops the process before the card can be shown, and a reminder would not
> appear at the time the user chose.

**Display over other apps (`SYSTEM_ALERT_WINDOW`)**: this is the app's main
feature: each reminder is drawn in front of the app the person is using, so it
is not missed. The person is shown what the permission looks like and can decline;
without it reminders arrive as ordinary notifications.

**Showing over the lock screen (`WAKE_LOCK`, `showWhenLocked`, `turnScreenOn`)**:
when a reminder comes due while the phone is locked, the app lights the screen
and shows the same card for 30 seconds, then lets the phone go back to sleep. It
uses an ordinary activity declared with `showWhenLocked` and `turnScreenOn`, not
a full-screen-intent notification, and it does not unlock anything: the person
still unlocks the phone themselves. `WAKE_LOCK` only keeps the screen on for those
30 seconds. A reminder that was missed waits and is shown as the usual floating
card the next time the phone is unlocked (it is dropped after 12 hours). Mention
the lock screen card in the screen recording: lock the phone, wait for the
reminder, watch the screen light up and go dark again.

**Ignore battery optimisation (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`)**: this
is the one most likely to be questioned. Google Play allows it only when the
app's core function breaks without it. The justification to use:

> Dhikr Reminder is a reminder app: its only job is to deliver reminders at the
> times the user set. Reminders are scheduled with alarms. On Android 12 and
> later, an app that has not been opened for a few days is moved to the "rare"
> App Standby bucket, which limits its alarms to one per hour, and many makers'
> battery managers stop idle apps altogether. Either way, reminders set every 5
> to 30 minutes silently stop arriving. The app explains this to the user and
> asks once per launch, and only for as long as it is not allowed. It uses the
> system's one-tap request, never changes any setting itself, and still works
> (with less reliable timing) if the user declines.

(Measured on a Samsung Galaxy A21s running Android 12: the app was in bucket 40,
"rare", with `standby_quota_rare=1`; after the exemption it moved to bucket 5,
"exempted", which has no quota.)

**If Play rejects that permission**, nothing else needs rewriting: delete its
line from `android/app/src/main/AndroidManifest.xml`. The app notices the
permission is missing and sends people to the system's battery list instead (one
more step for them, but allowed without a declaration). See
`MainActivity.openBatterySettings`.

Rules of thumb for all of these forms:

- Answer what is true. A wrong Data safety answer is a policy violation and can
  get the app removed later; a true one that looks scary does not.
- If the form wording differs from the tables above, answer the question being
  asked using the same facts. The facts do not change: no accounts, no ads, no
  tracking, the only thing sent is a dhikr request the person chooses to make,
  over HTTPS, with a random code the app makes up.

### 3.4 Main store listing

Under **Grow users > Store presence > Main store listing** (name may vary).

- [ ] Short description, full description: paste from
  [google-play/listing.md](google-play/listing.md).
- [ ] App icon: `docs/google-play/icon-512.png`.
- [ ] Feature graphic and screenshots from 2.2.
- [ ] Category: Lifestyle (or Books & Reference). Contact email (public).
- [ ] **Manage translations**: add Arabic and paste the Arabic block from
  listing.md.

The Dashboard shows a checklist of unfinished tasks. Get them all to green over
time; Play will not let you go to production while any is open.

---

## Phase 4. First upload (by hand, once)

The Play API can only touch an app that already has one upload made in the
website, so this one cannot be automated.

- [ ] **Testing > Internal testing > Create new release**.
- [ ] If it asks about **Play App Signing**, accept (let Google manage the app
  signing key).
- [ ] Upload `app-release.aab`.
- [ ] Release name: leave the suggestion. Release notes: `First test build.`
- [ ] **Testers** tab: create a list, add your own Gmail address (and any
  others), save.
- [ ] **Save**, then **Review release**, then **Start rollout to Internal
  testing**.
- [ ] Copy the **opt-in link** from the Testers tab.

### 4.1 Move your Samsung test phone to the Play version (wipes its data)

You agreed to the wipe. Android refuses to install over a build signed with a
different key, so the dev copy has to go first.

- [ ] Uninstall the dev copy. Either long-press the app and uninstall, or:

  ```powershell
  & "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" uninstall com.gratovo.dhikr_reminder
  ```

  The dhikr list and counters are lost; you can re-add dhikr from the library.
- [ ] On the phone, open the **opt-in link** with the same Google account you
  added as a tester, tap **Become a tester**, then **Download it on Google
  Play**, and install.
- [ ] Re-grant what the app asks for (display over other apps, battery).
- [ ] Check: reminder card over another app, the lock-screen card, notifications,
  Arabic and English, and leave it overnight to see that reminders keep coming.

From now on, the F5 debug builds from VS Code need the Play version removed
first (same key clash, in reverse). Either use a second phone or an emulator for
`flutter run`, or accept uninstalling whenever you switch. A tidy setup is:
**phone = Play builds only; emulator or second phone = development**.

---

## Phase 5. Turn on one-click uploads (once)

This lets the VS Code tasks upload a new build for you.

1. [ ] Play Console: **Setup > API access** (name may vary). Link an existing
   Google Cloud project or create a new one.
2. [ ] Open <https://console.cloud.google.com> with the same Google account, make
   sure that project is selected, go to **IAM & Admin > Service accounts**, and
   **Create service account** (any name, for example `play-publisher`). No
   project roles are needed.
3. [ ] Open the service account, **Keys > Add key > Create new key > JSON**. A
   file downloads. This file is a password: never commit it or send it.
4. [ ] Move it to `android/play-service-account.json` (the name matters; it is
   git-ignored).
5. [ ] Back in Play Console: **Users and permissions > Invite new users**. Paste the
   service account's email (looks like `play-publisher@your-project.iam.gserviceaccount.com`).
   Give it permission for this app to **release to testing tracks** and **release
   to production** (and to manage the store listing is not needed).
6. [ ] Wait a few minutes, then run **Terminal > Run Task > Play: check
   connection**. Success prints `Play connection works`.

If it says 403: permissions have not applied yet (wait 10 minutes) or you gave
the account access to the wrong app. If it says 404: the package name is wrong
or no first upload has been made yet (Phase 4).

---

## Phase 6. Closed test (the 14 days)

### 6.1 Set it up

- [ ] **Testing > Closed testing > Create track** (the default one is fine).
- [ ] **Testers**: the easiest way to manage 15 to 20 people is a **Google Group**
  (<https://groups.google.com>). Create a group, add every tester's Gmail, and add
  the group's email address as the tester list. Adding or removing people later is
  then a group edit, not a Play Console edit.
- [ ] Copy the **opt-in link** and send it to the testers with these instructions:
  1. Open the link on your phone, signed in with the Gmail I have for you.
  2. Tap **Become a tester**, then **Download it on Google Play**.
  3. Install, open the app once, and **keep it installed for at least 14 days**.
  4. Tell me about anything odd.
- [ ] Upload a build: run **Terminal > Run Task > Play: upload to closed
  testing**. Type release notes when asked. (Closed testing releases can take
  from hours to a couple of days to be reviewed before testers can install.)

### 6.2 During the 14 days

- Check **Testing > Closed testing > Testers** each day: the number of testers who
  have **joined and stayed** must stay at 12 or more.
- Ask your testers to open the app now and then. It is not required, but real use
  finds real bugs.
- Fix bugs and upload new builds as often as you like. Per Google's
  rule it is the testers staying opted in that counts, not the build, but check
  the Testers tab after each upload to be sure the count did not drop.
- Read Play Console **Quality > Android vitals** and **Crashes and ANRs**: a
  crash shows up there with a readable trace (the upload script sends the R8
  mapping file for that).
- Play also runs a **pre-launch report** on a few real devices for each build:
  look at it before promoting a build.

### 6.3 The daily loop (what you will actually do)

1. Change code, test on the emulator or second phone (F5).
2. **Terminal > Run Task > Test** (or let the upload task do it).
3. **Play: upload to internal testing** to check the real Play build on your
   phone within minutes.
4. When happy, **Play: upload to closed testing** so the testers get it.

Each upload task: asks for release notes, raises the build number in
`pubspec.yaml`, runs analyze and tests, builds the signed bundle, uploads it,
and makes a git commit for the number bump (it does not push; push when you
like). If anything fails, `pubspec.yaml` is put back.

If an upload fails *after* Play accepted the bundle (rare), run
`.\scripts\publish_android.ps1 -NoBump` so the same number is not skipped, or
just run the task again; a skipped build number is harmless.

---

## Phase 7. Production

- [ ] After 14 days with 12+ testers, the Dashboard shows **Apply for production**.
  Click it and answer the questions honestly: how you recruited testers, what
  feedback you got, what you changed, why the app is ready. Real examples from the
  14 days help.
- [ ] Google reviews the application (usually within a few days).
- [ ] Run **Play: upload to production (draft)**. This makes a *draft* release on
  the Production track.
- [ ] In Play Console: **Production**, open the draft, read it, set the countries
  (all, or a chosen list), then **Send for review**.
- [ ] Review of a first release takes a day to about a week. Updates are usually
  faster.
- [ ] When approved the app goes live automatically (or when you press publish,
  if you chose managed publishing).

If the first API upload says "Only releases with status draft may be created on
draft app", nothing is wrong: the script retries as a draft automatically and you
press **Roll out** in Play Console. That message appears while the app has never
been through review.

### If Play rejects something

Google emails the account owner and shows the reason in **Policy status**. The
usual suspects for this app:

- **Battery optimisation exemption** (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`):
  allowed only when the core function breaks without it. Use the justification in
  3.3. If rejected, delete that one `uses-permission` line from
  `android/app/src/main/AndroidManifest.xml`; the app falls back to sending
  people to the system battery list. Rebuild, upload.
- **Display over other apps**: it is the main feature. Explain it as in
  3.3 and point to the video.
- **Foreground service type**: make sure the declaration form text matches the
  manifest.
- **Data safety mismatch**: fix the form to match reality; do not change the app
  to match a form unless you want to.

You can appeal from the notice email, and you can resubmit as many times as
needed. A rejection is a fix-and-resubmit, not a ban.

---

## Phase 8. Every update after launch

1. [ ] Code is committed and passing (`Test` task).
2. [ ] Windows release: **Ctrl+Shift+B** (the Release task). Bumps the version,
   builds the installer, and publishes the GitHub Release; installed Windows
   copies update themselves.
3. [ ] **Terminal > Run Task > Play: upload to production (draft)**. Enter release
   notes.
4. [ ] Play Console > Production > open the draft > **Send for review**.

Prefer a safer rollout? From a terminal:

```powershell
.\scripts\publish_android.ps1 -Track production -Status inProgress -Rollout 0.2 -Notes "What changed"
```

That releases to 20% of people. In Play Console you can raise the percentage or
**Halt rollout** if crashes appear. There is no "undo": to roll back, upload the
previous code as a *new, higher* version code.

Both the Windows release and the Play upload raise the same build number in
`pubspec.yaml`, so they never collide.

### Command reference

| Task / command | What it does |
| --- | --- |
| `Play: create upload key (once)` | Makes the key, once |
| `Play: build bundle only` | Builds the `.aab`, uploads nothing |
| `Play: check connection` | Tests the service account without uploading |
| `Play: upload to internal testing` | Bump, test, build, upload to Internal |
| `Play: upload to closed testing` | Same, to Closed testing |
| `Play: upload to production (draft)` | Same, as a draft on Production |
| `.\scripts\publish_android.ps1 -Track <internal\|alpha\|beta\|production>` | The command behind the tasks |
| `-Notes "text"` / `-NotesAr "نص"` | Release notes in English / Arabic |
| `-Status completed\|draft\|inProgress`, `-Rollout 0.2` | How the release goes out |
| `-SkipChecks` | Skip analyze and tests (faster, riskier) |
| `-NoBump` | Do not raise the build number |
| `-Check` | Only test the connection |

---

## How updates reach people

| Where | How |
| --- | --- |
| **Windows** | The app checks GitHub 45 seconds after it starts and then every hour. A newer release's installer is downloaded, checked (size, SHA-256, `MZ` header), and installed silently when no reminder is on screen and the window is closed. The app starts again by itself. What it does is written to `%LOCALAPPDATA%\DhikrReminder\dhikr_reminder.log` and goes into bug reports. |
| **Android** | Google Play does it. Most phones update apps on Wi-Fi by themselves; people who turned that off see an Update button on the Play page. The Settings page shows "Updates come from Google Play" with a shortcut to that page. |

The app deliberately does not download and install APKs on Android: Google Play
policy forbids an app distributed there from updating itself any other way.

The app deliberately does not download and install APKs on Android: Google Play
policy forbids an app distributed there from updating itself any other way.

---

## Telling the people who installed the APK from GitHub

The Android APKs you published on GitHub so far are signed with the debug key.
The Play version is signed with Google's key. Android will not install one over
the other, so those people must **uninstall, then install from Play**, and they
lose their dhikr list. There is no way to push this to their phones: the old
versions on their phones (up to 0.1.3) check nothing on GitHub (they show
"Updates come from Google Play" and never look), so the message has to reach them
from outside the app.

Do these when the app is live on Play (replace the link if it differs):

```
https://play.google.com/store/apps/details?id=com.gratovo.dhikr_reminder
```

- [ ] Put a note at the top of the repo `README.md` and in the notes of the next
  GitHub Release. Suggested text:

  ```
  The Android app is now on Google Play: <link>
  The Play version replaces the APK downloads. They are signed differently, so
  the old APK cannot be updated: write down your dhikr list, uninstall the APK,
  then install from Play. Windows is unchanged and keeps updating itself.
  ```

  Arabic version for the same places (and for any group where you shared the APK):

  ```
  تطبيق الأندرويد بقى على Google Play: <link>
  نسخة Play بتحل مكان نسخة الـ APK. التوقيع مختلف فمش هينفع تتحدّث فوق القديمة:
  اكتب قايمة أذكارك، امسح نسخة الـ APK، وبعدين نزّل من Play.
  الويندوز زي ما هو وبيتحدّث لوحده.
  ```

- [ ] Send the same message wherever you originally shared the APK link (chats,
  groups, social posts). That is the only reliable channel for the existing
  installs.
- [ ] After the migration period, stop attaching Android APKs to GitHub Releases:
  add `-SkipAndroid` to the Release task's arguments in `.vscode/tasks.json`
  (`build_windows.ps1` supports it). From then on GitHub Releases are
  Windows-only. This avoids confusing people with APKs that Play users cannot
  update.
- [ ] Optional, later: add an in-app card shown only when the app was *not*
  installed from Play ("Get the Play version"). It cannot reach copies that are
  already installed, only new sideloads, so it is a nice-to-have, not part of
  launch.

---

## After launch: things that need you

- **Reviews**: reply from Play Console. Replying politely raises ratings.
- **Crashes**: check **Quality > Android vitals** weekly in the first month.
- **Yearly API level bump**: each year Google raises the minimum target API for
  new apps and updates (for example, Android 16 / API 36 since 31 August 2026).
  Updating Flutter usually updates the target. If you ignore it, your updates are
  blocked until you catch up.
- **Request service**: keep the Cloudflare Worker deployed and its address
  unchanged. If you ever remove it, the Data safety form and PRIVACY.md must be
  updated.
- **Privacy policy URL**: must keep working. Keep the repo public, or move the
  policy to GitHub Pages and update the address in Play Console.
- **Account health**: keep the developer email working; Play sends policy notices
  there. Accounts left unused for a long time can be closed.
- **In-app update prompts** (optional, later): Google's In-App Updates API can
  ask people inside the app to update, useful for people with auto-update off.
  It only works for an app installed from Play with a newer version available,
  so it cannot be tested before the first release.
- **Backups**: keep a current backup of `upload-keystore.jks`,
  `key.properties`, the password and `play-service-account.json`.

---

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `key.properties not found` when building the bundle | Run the create upload key task (Phase 2.1). |
| Play: `Version code N has already been used` | Build number was not raised. Do not use `-NoBump` after a bundle was accepted; run the task normally. |
| Play: `You uploaded an APK or Android App Bundle that was signed in debug mode` | Signed with the debug key because `key.properties` is missing or wrong. Fix it and rebuild. |
| Play: `...signed with the wrong key` on the second upload | You used a different upload key than the first. Restore the original `upload-keystore.jks` from your backup. If it is lost, ask Play support to reset the upload key (Setup > App signing). |
| Script: `403` | The service account is not invited with release permission for this app, or permissions have not applied yet. Wait 10 minutes, recheck Phase 5 step 5. |
| Script: `404` | Wrong package name, or no first upload by hand yet (Phase 4). |
| Script: `Only releases with status draft may be created on draft app` | Handled automatically: it retries as a draft; press Roll out in Play Console. |
| Script: `Could not sign in with the service account` | The JSON file is wrong, deleted, or the key was revoked. Create a new key in Google Cloud (Phase 5 step 3). |
| Tester says "App not available" or "item not found" | They are signed in with a different Google account than the one you added, or have not tapped Become a tester, or the release is still under review. |
| Install on the phone fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | A copy signed with another key is installed. Uninstall it first (Phase 4.1). |
| Reminders thin out on a phone after some days | The phone's battery manager. In the app, allow the battery exemption; on Samsung also remove the app from "Sleeping apps". |
| `flutter` build fails after changing localization files | Run the **Regenerate localizations** task. |

---

## Appendix: facts this guide is based on

- Closed test rule for personal accounts (12 testers, 14 days):
  <https://support.google.com/googleplay/android-developer/answer/14151465>
- The Play API only works on an app that already has an upload, and cannot
  complete legal declarations:
  <https://developers.google.com/android-publisher/edits>
- Target API policy:
  <https://support.google.com/googleplay/android-developer/answer/11917020>
- Foreground service declarations:
  <https://support.google.com/googleplay/android-developer/answer/13392821>
- Battery optimisation exemptions and Play policy:
  <https://developer.android.com/training/monitoring-device-state/doze-standby>

Re-check anything above against these pages before relying on it, because
Google changes rules and menus.
