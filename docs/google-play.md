# Publishing Dhikr Reminder on Google Play

This is the whole path from this repository to a live Play Store listing, and
how updates reach people afterwards. Things marked **You** need your hands (an
account, a password, screenshots). Everything else is already done in the repo.

## What is already done

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
| The only thing the Android app sends is a dhikr request the person chooses to make (internet permission, Data safety answers in step 6) | `AndroidManifest.xml`, `server/` |
| Updates on Android come from Play, and the app does not try to update itself (Play forbids that) | `Settings` page, update card |

## Step by step

### 1. You: create the developer account

1. Go to <https://play.google.com/console/signup> with the Google account you
   want to own the app. The one-time fee is US$25.
2. Choose **Personal** or **Organization**. This matters:
   - A **personal** account created after 13 November 2023 must run a closed
     test with at least **12 testers opted in for 14 days in a row** before it
     can publish to production (step 9). Plan for that.
   - An organization account is exempt, but needs a registered business and a
     D-U-N-S number.
3. Verify your identity, phone number and email. Your developer name and
   contact details may be shown on the store listing.

### 2. You: make the upload key (once)

```powershell
.\scripts\create_upload_key.ps1
```

It asks for a password and writes `android/upload-keystore.jks` and
`android/key.properties`. Neither is in git, on purpose. **Back both up with the
password.** Play App Signing (on by default) means Google holds the key users'
phones check, so a lost upload key can be replaced through Play support, but it
costs days.

### 3. Build the bundle

```powershell
.\scripts\build_android.ps1
```

This runs the checks, then writes
`build\app\outputs\bundle\release\app-release.aab`. That one file is what you
upload. The version comes from `pubspec.yaml` (`0.1.2+3` means version name
0.1.2, version code 3). **Every upload needs a higher version code than the last
one**, which the Windows release script (`-Mode Publish`) already raises by one
each time.

"Request a dhikr" needs the request service deployed first (`server/README.md`).
Its address is committed in `lib/features/requests/data/requests_config.dart`
(it is public, not a secret), so a normal build already points at it. Setting
`$env:DHIKR_REQUESTS_URL` before `.\scripts\build_android.ps1` overrides it for
that build, for example to try another server. To build an app without the
feature, run `flutter build` yourself with `--dart-define=DHIKR_REQUESTS_URL=`
(empty).

Optional but useful: upload `build\symbols` as the deobfuscation file for each
release, so crash reports in Play Console are readable.

### 4. You: create the app in Play Console

**Create app**, then:

- App name: `Dhikr Reminder` (the Arabic name is added as a translation).
- Default language: English (United States) or Arabic, as you prefer.
- App or game: **App**. Free or paid: **Free** (you cannot change a free app to
  paid later).
- Accept the declarations.

### 5. Privacy policy address

Play wants a public web address. After you push this repository, the policy is
at:

```
https://github.com/i-Light/dhikr_reminder/blob/main/PRIVACY.md
```

If you would rather have a cleaner address, turn on GitHub Pages for the repo
and use the page it gives you. Paste the address under **Policy and programs >
App content > Privacy policy**.

### 6. App content declarations

Under **Policy and programs > App content**, the honest answers are:

| Form | Answer |
| --- | --- |
| Privacy policy | the address from step 5 |
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

### 7. Permissions and foreground service

The app uses three things Play looks at closely. Have a short screen recording
ready (30 to 60 seconds, uploaded to YouTube as unlisted): turn on the reminder
permission, wait for a reminder card to appear over another app, tap it to count
until it finishes. Reviewers ask for exactly this.

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

### 8. You: store listing

Under **Grow users > Store presence > Main store listing** use the text in
`docs/google-play/listing.md`. Graphics:

| Asset | Requirement | Status |
| --- | --- | --- |
| App icon | 512 x 512 PNG, up to 1 MB | `docs/google-play/icon-512.png` is ready |
| Feature graphic | 1024 x 500 PNG or JPEG | **You**: not made yet |
| Phone screenshots | 2 to 8, PNG or JPEG, each side between 320 and 3840 px, 16:9 or 9:16 | **You**: take them on a phone |

Good screenshots: the Settings page with the next-reminder countdown; a reminder
card over another app; the Notifications page with the list of dhikr; the
library. Take one set in Arabic, one in English.

### 9. Test, then go to production

1. **Internal testing** (up to 100 testers, available within minutes): upload the
   bundle here first. Install it from the link on a real phone and check that the
   reminder card, notifications and both permissions work. This also proves the
   signing and the manifest.
2. **Closed testing** (needed for personal accounts): create a track, upload the
   same or a newer bundle, add testers by email or Google Group, and send them
   the opt-in link. You need **12 people who stay opted in for 14 days**. They
   must install the app from Play, not a file. Ask for 15 to 20 so a few
   dropping out does not restart the clock.
3. After 14 days, the **Apply for production** button appears on the dashboard.
   Answer the short questions, then create the production release and send it
   for review. A first review usually takes from a day to about a week.

### 10. Releasing updates after that

For each new version:

1. Run the Windows release as usual (`.\scripts\build_windows.ps1 -Mode Publish`);
   it bumps `pubspec.yaml`, builds the Windows installer, builds the APKs and
   publishes the GitHub Release. Windows users get it by themselves.
2. Run `.\scripts\build_android.ps1` and upload the new `app-release.aab` to
   **Production > Create new release**. Add release notes, then send for review.

## How updates reach people

| Where | How |
| --- | --- |
| **Windows** | The app checks GitHub 45 seconds after it starts and then every hour. A newer release's installer is downloaded, checked (size, SHA-256, `MZ` header), and installed silently when no reminder is on screen and the window is closed. The app starts again by itself. What it does is written to `%LOCALAPPDATA%\DhikrReminder\dhikr_reminder.log` and goes into bug reports. |
| **Android** | Google Play does it. Most phones update apps on Wi-Fi by themselves; people who turned that off see an Update button on the Play page. The Settings page shows "Updates come from Google Play" with a shortcut to that page. |

The app deliberately does not download and install APKs on Android: Google Play
policy forbids an app distributed there from updating itself any other way.

## Later, once the app is on Play

- **In-app update prompts.** Google's In-App Updates API can ask people inside the
  app to update (useful for people with auto-update off). It only works for an
  app installed from Play with a newer version available, so it cannot be tested
  before the first release. Add it as a follow-up.
- **Staged rollouts.** On a new release choose a percentage (for example 20%) to
  limit the damage of a bad one, then raise it.
- **Pre-launch report.** Play runs the bundle on real devices and reports crashes
  before you publish.

## Sources

- Closed testing requirement for new personal accounts: <https://support.google.com/googleplay/android-developer/answer/14151465>
- Target API level policy: <https://support.google.com/googleplay/android-developer/answer/11917020>
- Battery optimisation exemptions and Play policy: <https://developer.android.com/training/monitoring-device-state/doze-standby>
- Foreground service declarations: <https://support.google.com/googleplay/android-developer/answer/13392821>
