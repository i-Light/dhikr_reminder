# Android platform notes

Our app targets API 36, minSdk 26. The test phone is a Samsung Galaxy A21s on Android 12, so Android 15+ behaviour has never been seen on a real device.

## Background-start exemptions (foreground services)

Checked: 2026-10-09
Confidence: confirmed (page read in full)
Sources: https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start, https://developer.android.com/about/versions/15/behavior-changes-15, https://developer.android.com/about/versions/12/foreground-services
Re-check by: 2027-07-01 (before the yearly target-API bump)

An app targeting Android 12+ cannot start a foreground service from the background unless one of these applies:

1. The app transitions from a user-visible state such as an activity.
2. The app can start an activity from the background (except when it has an activity in the back stack of an existing task).
3. A high-priority Firebase Cloud Messaging message arrives (not used by us).
4. The user performs an action on a UI element related to the app: a bubble, notification, widget or activity. Notification actions fall here.
5. The app invokes an exact alarm to complete an action the user requested. The page names no API and does not distinguish exact from inexact alarms. Our alarms are inexact (`setAndAllowWhileIdle`), so assume this does not cover us.
6. The app is the current input method.
7. A geofencing or activity-recognition transition event.
8. After reboot, on `ACTION_BOOT_COMPLETED`, `ACTION_LOCKED_BOOT_COMPLETED` or `ACTION_MY_PACKAGE_REPLACED`. For target 14+, some foreground service types are restricted from `BOOT_COMPLETED`.
9. On `ACTION_TIMEZONE_CHANGED`, `ACTION_TIME_CHANGED` or `ACTION_LOCALE_CHANGED`.
10. NFC `ACTION_TRANSACTION_DETECTED`.
11. Device owners, profile owners and similar roles.
12. Companion Device Manager apps with the right flags.
13. The user turns battery optimisation off for the app.
14. The app holds `SYSTEM_ALERT_WINDOW`. If the app targets Android 15 or higher, it must hold the permission AND currently have a visible overlay window (a `TYPE_APPLICATION_OVERLAY` window visible before the start is attempted; `View.getWindowVisibility()` can check).

Not mentioned on the page: `specialUse` foreground services.

How to test the Android 15 rule on an older device: `adb shell am compat enable FGS_SAW_RESTRICTIONS com.gratovo.dhikr_reminder`.

What this means for the app (release 0.2):
- Candidate fix (a): add a small overlay window straight from the alarm receiver (allowed with the overlay permission, no service needed), then start the foreground service and the lock-screen activity once it is visible.
- Candidate fix (b): an exact alarm the user granted (adds another special permission; `USE_EXACT_ALARM` is restricted by Play to alarm and calendar apps).
- Candidate fix (c): a plain high-priority heads-up notification.
- Battery exemption is itself an official exemption, so it must be the first setup card.
- Widget, tile, shortcut and notification-action taps count as user interaction (exemption 4), so those surfaces are safe on Android 15+.
- The lock-screen activity is started with a plain `startActivity` from `OverlayService.kt` (line 149 at the time of writing); the app uses no full-screen intent.

## Full-screen intents

Checked: 2026-10-09
Confidence: confirmed for the policy summary (search result quoting Google's help article); the declaration form itself was not opened
Sources: https://support.google.com/googleplay/android-developer/answer/13392821, https://source.android.com/docs/core/permissions/fsi-limits
Re-check by: 2027-04-09

- For apps targeting Android 14+, Google Play keeps `USE_FULL_SCREEN_INTENT` on by default only for apps whose core functionality is calling or alarms (rule applied from 22 January 2025). Others must ask the user and degrade gracefully.
- A Play Console declaration has been required since 31 May 2024 (App content page).
- Play revokes the permission at install for apps without calling or alarm functionality; `NotificationManager#canUseFullScreenIntent()` shows the state.
- Verdict: a full-screen-intent notification is ruled out for this app. We are neither a calling nor an alarm-clock app.

## Play permission policy for the overlay permission

Checked: 2026-10-09
Confidence: confirmed (help article read)
Sources: https://support.google.com/googleplay/android-developer/answer/9888170
Re-check by: 2027-04-09

- `SYSTEM_ALERT_WINDOW` is a special permission: direct users to the system settings page to approve it.
- Respect a declined request; do not pressure or trick the user; the app must remain functional (offer a workable alternative). Our notification fallback is that alternative once release 0.1.4 fixes it.
- The article lists declaration forms for other permissions (QUERY_ALL_PACKAGES, full-screen intent, background location) but none for `SYSTEM_ALERT_WINDOW`. Still check the Play Console form list once.
- Ads policy history: restrictions on ad behaviour that interferes with other apps extend to overlays (not relevant: we show no ads).

## Quick Settings tile and home-screen widget

Checked: 2026-10-09
Confidence: likely (Android reference excerpts and a search summary)
Sources: https://developer.android.com/reference/android/service/quicksettings/TileService, https://developer.android.com/develop/ui/views/appwidgets/advanced
Re-check by: 2027-04-09

- A counting tile does not need `startActivityAndCollapse`; the Intent overload is deprecated from API 34. Handle `onClick()`, store the count in prefs (the service can be unbound between events), and update the tile in place.
- Register listeners in `onStartListening` and unregister in `onStopListening`. For outside updates use `requestListeningState`.
- The tile subtitle needs API 29+ (we have minSdk 26, so guard it).
- `AppWidgetManager` can be called from anywhere in the app with the same UID as the provider, so a tile can refresh the widget.
- `updatePeriodMillis` cannot be below 30 minutes: push widget updates on count instead.
- Broadcast receivers have about 10 seconds; `goAsync` allows about 30 seconds.
- `home_widget` (pub) is a Flutter bridge; the widget UI itself is still written natively. We write it natively and skip the dependency.

## Per-app language (Android 13+)

Checked: 2026-10-09
Confidence: confirmed for the Android side; the Flutter side is an inference
Sources: https://developer.android.com/guide/topics/resources/app-languages
Re-check by: 2027-04-09

- Without a `localeConfig`, the app does not appear in the system per-app language screen.
- Automatic generation: AGP 8.1+ with `generateLocaleConfig = true` in the `androidResources` block and a `res/resources.properties` declaring the base language (for example `unqualifiedResLocale=en-US`). Extra languages come from `values-*` folders.
- Manual alternative: `res/xml/locales_config.xml` referenced by `android:localeConfig` on `<application>`.
- Flutter's own `supportedLocales` must be kept in step. Unverified: how Flutter reports a per-app locale change. Test on an Android 13 emulator.

## Android 16 Live Updates

Checked: 2026-10-09
Confidence: likely
Sources: search summaries of Android 16 behaviour
Re-check by: 2027-07-01

- Promoted ongoing notifications suit a timer or a delivery, not a tally. Rejected for the counter.

## Yearly platform duty

- Google raises the minimum target API each year (deadline around 31 August). Android 17 is expected next. Bump `targetSdk`, build, run the device matrix on emulators, upload with a staged rollout. Ignoring it blocks Play updates.
- Flip `android.newDsl` and `android.builtInKotlin` to true in `android/gradle.properties` before AGP 10 removes the opt-outs.
