# Maintenance runbook

Written so someone who did not build the app can keep it alive. Started during the 1.0 work; the yearly calendar and the hand-over page are still to write (roadmap W13).

## What runs where

| Thing | Where | Who looks after it |
|---|---|---|
| Windows app and installer | built on the owner's PC by `scripts/build_windows.ps1`, published as a GitHub Release | the owner |
| Android app | built by `scripts/build_android.ps1`, uploaded by `scripts/publish_android.ps1` to Google Play | the owner |
| "Request a dhikr" service | Cloudflare Worker `dhikr-requests` with a D1 database, source in `server/` | the owner |
| CI | `.github/workflows/ci.yml`, on every push, pull request and weekly | automatic |
| Dependency updates | `.github/dependabot.yml`, monthly pull requests | review, merge when CI is green |

## Everyday commands

- Check everything: `flutter analyze --fatal-infos`, `flutter test`, `node --test` in `server/`, `.\gradlew.bat :app:testDebugUnitTest` in `android/`.
- Release for Windows: the VS Code task "Release: publish" (it shows the plan and asks for the tag to be typed). Ctrl+Shift+B only builds and installs locally.
- Release for Android: the Play tasks in `.vscode/tasks.json`; `docs/publishing-guide.md` has the steps.
- Regenerate texts after editing `lib/l10n/*.arb`: `flutter gen-l10n`.

## Turning a feature off

Every optional feature has one constant in `lib/core/features.dart` (and `android/app/src/main/kotlin/com/gratovo/dhikr_reminder/Features.kt` for the phone's native side). Set it to `false`: its entry point disappears and nothing else depends on it. Build, run the tests, release.

## Where the user's data is, and what is backed up

- Windows: settings in `%APPDATA%\com.gratovo\dhikr_reminder\shared_preferences.json` (never change `CompanyName` or `ProductName` in `windows/runner/Runner.rc`, the path comes from them). A rolling backup of three copies is kept in `%LOCALAPPDATA%\DhikrReminder\backup*.json`, written a few seconds after a change; if the settings file is lost, the newest good copy is restored on the next start. The log is `dhikr_reminder.log` in the same folder.
- Android: Auto Backup carries the dhikr list and settings to a new phone (rules in `res/xml/`); the scheduler's own file `dhikr_overlay.xml` is left behind and rebuilt.
- A settings file written by a NEWER app version is read but never rewritten by an older one (`lib/core/storage/storage_guard.dart`).

## Keys and tokens (write where each is kept, never in the repo)

| Secret | Used for | Kept at |
|---|---|---|
| Android upload keystore and `android/key.properties` | signing Play uploads | (fill in) |
| Play service-account JSON | `scripts/publish_android.ps1` | (fill in) |
| GitHub token or sign-in | publishing a Windows release | (fill in) |
| Cloudflare account and the admin token of the Worker | the request service | (fill in) |
| Updater signing key (not made yet, roadmap W7) | signing Windows installers | (offline, fill in) |

## When a user says reminders stopped (Android)

Ask for a bug report from the app. It lists whether notifications and drawing over other apps are allowed, how many alarms are armed, whether reminders look stopped, and the last twelve events with the path taken (`card`, `lockscreen`, `notification`, `skipped`, `rearmed`) and the system's reason if the card was refused. The usual causes are the phone's battery or "auto start" rules (the red card links to the maker's screen) and a revoked permission.
