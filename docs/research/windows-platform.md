# Windows platform notes

The Windows app is a tray app with its own reminder card window, a custom `dhikr_reminder/window` channel in the runner, a single-instance rule that asks any running copy to quit, an Inno Setup installer, and a self-updater that reads GitHub Releases. The installer is not code-signed.

## Global hotkeys

Checked: 2026-10-09
Confidence: likely (pub.dev summaries)
Sources: https://pub.dev/packages/hotkey_manager, https://pub.dev/documentation/hotkey_manager/latest/
Re-check by: 2027-04-09

- `hotkey_manager` 0.2.3 registers system-wide hotkeys on Windows, macOS and Linux (`register`, `unregister`, `unregisterAll`; scope defaults to system). Windows implementation is a separate package (0.2.0, created March 2024). Call `unregisterAll` at startup for hot reload.
- Maintenance signals: 150 of 160 pub points; a third-party snapshot showed 152 stars, 41 forks, last push about 11 months earlier and 21 open issues.
- Not found: how it handles hotkeys already taken by other apps, or behaviour in elevated processes.
- `flutter_hotkeys` is NOT global: its "global" shortcuts work only inside the app.
- Decision: implement `RegisterHotKey` natively in the runner on the existing channel (about 60 lines of C++), default off, person picks the key, clear message if taken. No dependency to maintain.

## Toast notification packages

Checked: 2026-10-09
Confidence: likely
Sources: https://github.com/leanflutter/local_notifier, https://pub.dev/packages/flutter_desktop_notifications
Re-check by: 2027-04-09

- `flutter_desktop_notifications` documents Windows action buttons and a click callback with the pressed action; unpackaged apps need a registered app user model ID or Windows drops the toast.
- `local_notifier` works with thinner docs; `windows_notification` is older and template-based; `flutter_local_notifications` lists Windows buttons and text input but Windows scheduling was not confirmed.
- No result covered OS-level scheduled toasts for reminders.
- Decision: not needed. The reminder is our own card window. Toasts stay out unless the card is ever replaced.

## Microsoft Store (MSIX)

Checked: 2026-10-09
Confidence: likely (news posts and a Learn page; the live registration page was not opened)
Sources: https://blogs.windows.com/windowsdeveloper/2025/09/10/free-developer-registration-for-individual-developers-on-microsoft-store/, https://learn.microsoft.com/en-us/windows/apps/distribute-through-store/how-to-distribute-your-win32-app-through-microsoft-store, https://github.com/YehudaKremer/msix
Re-check by: 2027-04-09 (confirm at https://storedeveloper.microsoft.com)

- Individual developer registration became free in nearly 200 markets (announced September 2025). It was a one-time 19 dollars before. Registration needs a personal Microsoft account and identity verification with an ID and a selfie. A May 2026 post announced free account creation for companies too (not opened in full).
- MSIX packages: the Store re-signs them at no cost, so there is no certificate to buy; the OS checks for updates every 24 hours. MSIX also supports S Mode and package flighting.
- Unpackaged Win32 (EXE or MSI) submitted to the Store: not signed by the Store. The publisher must sign with a certificate from a CA in the Microsoft Trusted Root Program and host the installer at a versioned HTTPS URL; updates are the app's responsibility. A cost reference of about 10 dollars a month (Azure Artifact Signing, formerly Trusted Signing) appears in Microsoft's guide in a different row.
- A self-signed MSIX is rejected on other machines because the certificate is not trusted there.
- Packaging in Flutter: the `msix` pub package (YehudaKremer/msix).
- Work implied: `StartupTask` in the manifest instead of the Run key; switch the self-updater off when packaged; packaged apps redirect AppData, so existing users migrate through the export/import file (release 0.4); re-check the runner's kill-the-other-instance logic; `runFullTrust` capability and its justification (expected for a desktop app, unverified); run the Windows App Certification Kit; Store listing in Arabic and English.
- Decision gate D1 at release 2.2. Recommended: yes, as an extra channel next to the GitHub installer.

## winget

Checked: 2026-10-09
Confidence: likely (manifest docs read; the installer page did not mention signing for non-MSIX)
Sources: https://github.com/microsoft/winget-pkgs/blob/master/doc/manifest/schema/1.10.0/README.md, https://github.com/microsoft/winget-pkgs/blob/master/doc/manifest/schema/1.10.0/installer.md
Re-check by: 2027-04-09

- Rule read: "All tools must support a silent install to be permitted in the Windows Package Manager Community Repository." Our Inno Setup installer supports `/VERYSILENT`.
- Rule read: "MSIX installers must be signed to be included in the Microsoft community package repository." No signing rule was found for other installer types.
- One package version per pull request; the package identifier must be unique.
- Submissions are validated automatically and may be reviewed manually; a bot returns failing PRs to the submitter for 7 days. A false-positive malware flag can be contested with the Defender team (from secondary sources).
- `wingetcreate submit` can run in CI with a classic token that has `public_repo`. `winget validate` and the Sandbox script test a manifest first.
- SmartScreen reputation is tied to each file's hash, so every release starts untrusted, and winget does not remove the warning.
- Unverified: the repo's current validation pipeline for installers.
- Decision: parked; only worth it if the Store route is declined.

## SmartScreen and unsigned installer

- The installer is unsigned by decision (no paid certificate). Free hardening is the offline Ed25519 signature check inside the updater (release 0.5). The Store channel (above) is the free way to a signed Windows install.
- Sources for reputation behaviour are secondary: a project write-up and a Microsoft Q&A answer. Confidence: likely.
