# Research notes

What the web and the code told us while planning this app, kept so a later session starts from it instead of searching again.

The app is a remembrance (dhikr) app only. Anything here that does not serve that goal is recorded as rejected in `ideas-pool.md`, with the reason.

## Files

| File | What it holds |
|---|---|
| `competitors.md` | Tasbih and dhikr apps: features, complaints, gaps |
| `content-sources.md` | Every dataset, book and audio source checked: owner, exact licence, verdict |
| `android-platform.md` | Background-start rules, full-screen intents, Play permission policy, tiles, widgets, per-app language |
| `windows-platform.md` | Global hotkeys, toasts, Microsoft Store and MSIX, winget, SmartScreen |
| `distribution.md` | Play staged rollout, F-Droid, IzzyOnDroid, Galaxy Store, Egypt market data |
| `ideas-pool.md` | Every idea with its origin and verdict (planned, parked, rejected), kept current |

## Note template

Every finding starts with these four lines, so it is clear how far to trust it:

```
Checked: 2026-10-09
Confidence: confirmed | likely | unverified
Sources: <links>
Re-check by: <date>
```

- **confirmed**: the page was opened and read in full by us.
- **likely**: seen in a search summary, a mirror or a partial page; the claim is plausible but not read at the source.
- **unverified**: a lead only. Do not build on it until it is upgraded.

## Rules

1. A finding that a decision depends on is written here, never left only in a chat or a plan.
2. Copy exact licence wording and the URL it came from. A summary of a licence is not a licence.
3. When a finding changes, edit it in place and update `Checked`. Do not keep two versions of the same fact.
4. Update `ideas-pool.md` in every release: move ideas to shipped, parked (with a trigger) or rejected (with a reason).
5. Once a year, in July, re-check every note whose `Re-check by` date has passed (see `docs/maintenance.md` once it exists).
6. Intake test for any new idea (all five must be yes): it is remembrance; it works offline with no account; it can run unattended for a year; it adds no new permission or Play policy risk (or the risk is written down); it can be checked by a test or a release checklist line. Otherwise it goes into the pool as parked or rejected.

## Open items (unverified, do before relying on them)

- Sunnah.com reproduction and scraping terms: the fetch tool got HTTP 403. The owner reads `sunnah.com/about` ("Reproduction, Copying, Scraping") in a browser and records the answer in `content-sources.md`.
- Microsoft Store: whether `runFullTrust` and an always-on tray app need extra review.
- Whether `setAndAllowWhileIdle` counts as the "exact alarm" background-start exemption (assume no).
- The Play Console form list: is there a declaration for the overlay permission.
- winget-pkgs' current installer validation pipeline.
- The Hisn al-Muslim compiler's or publisher's own reuse policy.
- How Flutter reports a per-app locale change on Android 13+.
