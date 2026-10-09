# Distribution: Play, other stores, rollout, market

## Google Play staged rollout and halt

Checked: 2026-10-09
Confidence: confirmed for rollout and halt via the API (English "halt" section was cut off, so details come from the Japanese and German pages, the 2018 API blog and field reports); likely for the caveats
Sources: https://developers.google.com/android-publisher/tracks, https://developers.google.com/android-publisher/api-ref/rest/v3/edits.tracks, https://android-developers.googleblog.com/2018/06/automating-your-app-releases-with.html, https://github.com/fastlane/fastlane/discussions/21991
Re-check by: 2027-04-09

- Every change goes through an edit: open an edit, update the track with `edits.tracks.update`, commit. An edit can be discarded without committing.
- A staged rollout is a release with status `inProgress` and a `userFraction` strictly between 0 and 1 (0.2 means 20%). Widen it by raising `userFraction` on the same release and committing.
- Halt by setting status `halted`; resume by setting it back to `inProgress`; finish with `completed`.
- Caveats: a halted release stops serving to new installs and leaves existing installs alone; a new upload can resume a halted rollout (from a third-party client doc, unconfirmed in the official reference); setting the fraction to 0 does not stop users who already received the update; a rollout at 100% cannot be halted in the Console (teams use 99.9% as a workaround).
- Automation needs a service-account key whose email is added in Play Console.
- Plan: `scripts/play_upload.mjs` releases to 20%, a second task raises to 100%, a third halts (release 0.5). This is the Android kill switch, since Play does the updating.

## Egypt market data (for device matrix and per-brand guidance)

Checked: 2026-10-09
Confidence: likely (StatCounter estimates from web traffic; named brands are a share of a noisy base with a large "unknown" bucket; the charts need JavaScript so cached tables were read)
Sources: https://gs.statcounter.com/vendor-market-share/mobile/egypt, https://gs.statcounter.com/android-version-market-share/mobile/egypt
Re-check by: 2027-04-09

- Vendor share, mobile, August and September 2026: Samsung about 23 to 24%, Oppo about 16 to 17%, Xiaomi about 10 to 12%, Realme about 8 to 10%, Apple about 12 to 17% (not our platform), unknown about 16%. Mobile and tablet June 2026: Samsung about 25%, Oppo about 17%, Xiaomi about 11%, Realme about 11%.
- Android versions, mobile, June 2026: 15 about 16%, 13 about 15.3%, 11 about 14.1%, 16 about 13.8%, 14 about 12.9%, 12 about 11.8%. July 2026: 16 about 18%, 15 about 15.7%, 13 about 15.2%, 11 about 13.8%, 14 about 12.8%, 12 about 11.4%. Android 16 rose roughly four points between June and July and about three points since May.
- Consequences: per-brand guidance order is Samsung, Oppo and Realme (ColorOS), Xiaomi, then Vivo and Huawei. The device matrix covers at least Android 11, 13, 15 and 16, plus the real Android 12 phone. minSdk 26 is safe.

## F-Droid

Checked: 2026-10-09
Confidence: likely (policy pages were partly truncated in the summary)
Sources: https://f-droid.org/docs/Inclusion_Policy, https://f-droid.org/docs/Inclusion_How-To, https://f-droid.org/docs/Security_Model, https://forum.f-droid.org/t/flutter-app-and-signing/30941
Re-check by: 2027-04-09 (read the current policy before submitting)

- Source and dependencies must be free; advertising, tracking and non-free libraries are turned away; Google services (GMS, Firebase) top the reject list. We have none.
- Build tools must be free; the policy gives the Flutter SDK, Android SDK and Hermes an exception for official prebuilt binaries while Debian lacks a package.
- Reproducible builds are the ideal but not mandatory. F-Droid rebuilds and diffs against the published APK; if only signature files differ, the developer-signed copy ships. Otherwise F-Droid signs with its own key. Apps that cannot reproduce can run a self-hosted repo that F-Droid clients can add.
- Flutter gotcha: a release build that fails without a local keystore breaks on F-Droid. Our 0.1.4 build rule allows `-PallowUnsigned=true` for this reason.
- Two signing identities mean a person cannot update across Play and F-Droid. Decision D5.

## IzzyOnDroid

Checked: 2026-10-09
Confidence: likely
Sources: https://izzyondroid.org/docs/general/AppInclusionPolicy/, https://izzyondroid.org/faq/
Re-check by: 2027-04-09

- Licence must be OSI or FSF approved (decision D4 picks ours).
- Source on Codeberg, GitLab, GitHub or similar. Trackers and ads are a firm no. The package must carry the developer's release signature and must not be debuggable or testOnly.
- Store-style listing text and images live in the repo in Fastlane layout (short and full description, icon at least).
- Binaries are the developer's own builds, mostly taken from tagged GitHub releases; new versions usually appear within about 24 hours.
- Fits us best as the first extra channel: it serves our own signed APK.

## Galaxy Store and AppGallery

Checked: 2026-10-09
Confidence: unverified (not researched beyond market share)
Sources: none yet
Re-check by: when decision D5 is reached

- Samsung is about a quarter of Egyptian phones, so a Galaxy Store listing is worth a trial. Fees, review rules and signing need to be researched then.
- AppGallery: parked until Huawei users ask.

## Windows channels

See `windows-platform.md` for the Microsoft Store (free signed MSIX) and winget.
