# Dhikr workbench and the reimagined experience: design

Date: 2026-11-16. Status: approved by the owner on 2026-11-16. Plan: `docs/superpowers/plans/2026-11-16-dhikr-workbench.md`.

Marks used below: **(owner)** was decided by the owner in conversation. **(call)** is Claude's choice, open to correction, most of it through comments pinned in the workbench.

## 1. Intent

Rethink the whole app from nothing, around one aim: the easiest and most satisfying dhikr experience there is. Clear to an elderly person and to someone who is not used to dhikr. The person looks at a screen and knows what to do next without anyone explaining.

The deliverable is a clickable web prototype of the full app inside a workbench, with a comment tool, so the owner can scan every screen and pin what should change. Once the owner says the prototype is right, it is the target the real app is rebuilt from, in a later session. The rebuild is not part of this work. **(owner)**

The existing app's screens, layout, wording and earlier decisions are a throwaway sandbox. Nothing is reused because it exists. **(owner)**

## 2. Who it is for

- An elderly parent who cannot be expected to learn an interface.
- A busy or young person with little patience, who leaves if the one thing they came for is not in front of them.
- Someone new to dhikr, who needs to be led into it gently and not handed a library.
- A family member who sets the app up for someone else in under a minute.

## 3. What goes wrong today (owner's observations plus Claude's walk-through)

1. Settings are in different places (Home, a folded card on Notifications, inside the Library, an edit sheet). Put together on one screen they overwhelm.
2. People wait for the owner to explain instead of seeing the next action.
3. Reaching a dhikr, adding one, and changing its amount, frequency or day's goal are all hard. With help they will edit, but they will not add.
4. Morning, evening, before-sleep and on-waking adhkar are hard to do. They are filter tags and a buried Start button; nothing arrives at the right time.
5. Each dhikr carries three numbers, one of them a weight ("6 of 10, not a percentage").
6. Adding means a 281-entry library with 23 filter groups.
7. No screen has a main action.

## 4. Goals, non-goals, anti-goals

Goals

- Every screen answers "what do I do now?" with one sentence and one main button.
- A dhikr shows the person one number: today's amount.
- Reminders adapt by themselves to what the person does, per dhikr and per hour of the day.
- No tap is ever lost.
- One icon family drawn for this app, and motion that has a job. **(owner)**
- The owner can comment on any element of any screen and Claude can read the comments from the repo.

Non-goals

- The Flutter rebuild, real notifications, real permissions, real storage.
- Verified religious content. The prototype uses example adhkar and example sunnah numbers taken from the app's current library file. Real numbers need verified sources before the rebuild.
- Audio.

Anti-goals (a failure even if it works)

- A screen that needs explaining.
- Emojis or a stock icon pack. **(owner)**
- Blame, guilt, badges, comparing people, or anything that shames a missed day.
- More popups than the person chose.
- Hidden gestures (press and hold, swipe-only actions).
- Anything leaving the device. All behaviour tracking is local.

## 5. Constraints

- Lives in `workbench/` at the repo root, tracked in git. **(owner)**
- Opens by double-clicking `index.html` in Chrome or Edge. No install, no build, no network. So: plain script files (ES modules do not load from `file://`), libraries and fonts in the folder.
- Egyptian Arabic first, written naturally and not translated word for word. English second. Right-to-left is the primary layout.
- No em dashes, en dashes, curly quotes, arrows or other AI-looking symbols in any text, comment or doc.
- Phone first. Windows second.

## 6. Approaches considered

- **A. Same recipe as the gratovo_toolbox workbench (chosen by the owner).** Plain files, React and htm in `vendor/`, comment tool ported from the toolbox's `design/workbench-prototype/js/comments.js`. Fast to change, already familiar to the owner. Added: an optional small Node server that writes comments to a file in the repo.
- **B. A Vite, React and TypeScript project.** Better structure, but brings an install and a build into a Flutter repo for something meant to be changed quickly.
- **C. Flutter in the browser.** Closest to the real app, but Flutter draws on a canvas, so there are no elements to pin a comment to, and every change needs a compile. Ruled out.

## 7. The experience: decided with the owner

### 7.1 Three numbers, one of them visible

- **Sunnah number**: the count from the hadith for that dhikr (100, 33, 3). It is the destination. Some adhkar have none.
- **Day target**: what the person is asked for today. Always fixed for the day, and for the week unless the person changes it. If the person set none, the app sets a default and re-tunes it weekly from the last week's behaviour. This is the one number the person sees and edits.
- **Piece**: how many are asked in one appearance. Never shown as a setting. The engine owns it.

The person's chosen frequency is a ceiling: the app never appears more often than they chose. A bigger target is reached by bigger pieces in the hours where they respond, never by more popups. The app pushes gently toward the sunnah number when the person is responsive and used to the amount.

### 7.2 Onboarding

Six steps, each with "Choose for me" (takes the middle option), so it can be finished in five taps.

1. Language: اللغة العربية or English, pre-picked from the device.
2. "How is dhikr with you today?": I'm just starting / I do some / It's part of my day. Sets the starting rung and how many adhkar they begin with (3, 5 or 8 well-known ones). They do not pick adhkar here.
3. "How often may we remind you?": A few times a day (about every 3 hours) / Every hour / Often (about every 20 minutes). This is the ceiling.
4. "When do you wake and sleep?": two times. Gives the quiet hours and the four timed moments.
5. Try one: a real reminder appears, they tap it 3 times, then choose Small card or Full screen by seeing both.
6. Phone only: the permissions, one at a time, one sentence each (pretend in the prototype).

Then Home, with the first dhikr ready. Every answer is later one row in Settings, in the same words.

### 7.3 The reminder card

Two sizes: a small card that counts in place without opening anything, and full screen. A tap on the card counts one. Two buttons: Later and close. It shows the piece ("7 of 10") and, smaller, the day ("37 of 50 today").

| What the person does                 | What the app takes from it                                                                                                                 |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Finishes the piece                   | This hour and size work. A few in a row and the piece grows a little in that hour.                                                         |
| Taps some, then leaves               | Progress is kept and the next appearance of that dhikr continues the same piece. The piece for that hour shrinks toward what they managed. |
| Closes without a tap                 | "Not now." Once means nothing. Repeated in the same hour, that hour gets smaller pieces.                                                   |
| Never touches it and it hides itself | "Not there." Says nothing about the dhikr, only about the hour.                                                                            |
| Presses Later                        | Neutral. It returns in 10 minutes.                                                                                                         |

A piece is never below 1 and never above what is left of the day's target. A long dhikr opens to its full text even in small mode.

### 7.4 Progress is never lost

Every tap is saved at once into the day's count, wherever it happens (card, session, counter, widget-like surfaces). A piece or a session left partway continues from where it stopped.

### 7.5 A finished dhikr steps aside

A dhikr whose day target is reached does not appear again until every other dhikr's target is reached. When the last one is reached, Home shows a clear finish ("Today's adhkar are complete", a short celebration). After that the popups continue as extra at a slower pace, counted on top of the target and shown as extra.

### 7.6 Four timed moments

On waking, Morning, Evening, Before sleep. They come by themselves as their own moment, at clock times derived from the wake and sleep answers. No prayer times, no location. At the time, one card: the name, about how many minutes, Start and Later. Start runs the set in order, one dhikr at a time, with "3 of 12". If missed, it waits as the main button on Home until its time passes, then goes without a word.

### 7.7 The weekly card

Once a week, one gentle card. Example: "You kept up all week. This week: 50 a day. The sunnah is 100." with one button to refuse: "Keep it at 30".

- After a bad week an automatic target steps down one rung, quietly, with no words about failing.
- A target the person typed is never changed. The card may only suggest.
- A dhikr that keeps being skipped while the others are finished is named on the card: "This one was heavy this week", with three buttons: Keep it, Make it lighter, Rest it for now. Nothing is ever removed silently.

## 8. The experience: Claude's calls (to be corrected through comments)

### 8.1 Three places, always labelled

A bottom bar with three items, each an icon with its word: **Today**, **My adhkar**, **More**.

**Today**

- The Now card: one sentence, one big button. What it says, first match wins:
  1. Reminders cannot appear yet (a permission is missing): "Fix it".
  2. The weekly card is waiting: "See this week".
  3. A timed moment is in its window and not done: "Start" or "Continue".
  4. A piece or session was left partway: "Continue".
  5. Adhkar are left today: "Say one now". Under it, when the next one comes by itself.
  6. All complete: the finish state, with a soft "Say more".
- Today's list: each dhikr as a large row with a progress ring and how many are left. Finished ones sink to the bottom with a check. Tapping a row opens it to count now.
- The four moments as a small strip showing done, waiting or later today.
- "Pause for an hour" as a plain text button at the bottom.

**My adhkar**

- A big "Add a dhikr" button first.
- The list: name, "50 a day", and "sunnah: 100" when there is one. Tapping opens the dhikr's page: the full text, one stepper for today's amount with the sunnah number marked on it, "Count now", "Rest it" and "Remove".
- Add page: "Suggested for you" (about six, each with a one-tap Add), then groups as large tiles (Morning, Evening, Before sleep, After prayer, Tasabih, Duas), with search at the top. Adding never asks for a number; the amount comes from the rung.
- "Daily moments": the four sets, each with its time, what is in it, and an on or off switch.

**More**

- Rows written as the onboarding questions: How often may we remind you? When do you wake and sleep? How should a reminder look? Sound and vibration. Language. Text size.
- "My days": history, kept simple and private.
- A folded "Other" for backup, request a dhikr, report a problem, updates, about.

### 8.2 One card in three sizes

The reminder (small and full) and the count-now and session screens are the same component, so counting looks and feels identical everywhere.

### 8.3 Clarity rules

- Body text at least 18 px on the phone, dhikr text at least 28 px, touch targets at least 56 px, strong contrast.
- Every icon has a word next to it. One main button per screen.
- Undo instead of "are you sure?".
- Guidance comes from the Now card and from empty states that say what to do. In the first three days one hint line may sit under the Now card. No tours.
- Western digits by default.

### 8.4 Look, icons and motion

- Two looks built on the same tokens (colour, type, corner, ornament) and switchable from the Workbench menu, so the owner chooses by seeing. Decided at build time with the design skills; neither copies the current app.
- One icon family drawn as SVG for this app: same line weight, same corners. No emojis, no stock pack.
- Motion with a job: the count landing, a piece completing, a ring filling, the day completing, one screen handing over to the next, the card arriving and leaving. Honours "reduce motion".
- An "Icons and motion" page shows every icon and every animation alone, each pinnable.
- Fonts are open-licence files kept in `workbench/fonts/`.

### 8.5 Situations the prototype must show

First open. Onboarding finished with "Choose for me" only. A permission refused. The first reminder. Partial count then leaving. Closing without a tap. Ignoring. Later. A long dhikr. A dhikr said once. All complete, then extras. A missed moment. A missed whole day. Back after a week away (welcome back, no blame, lower targets). The weekly card going up, going down, and with a heavy dhikr. Adding a dhikr. Adding one already added. Resting and bringing back. Removing with undo. Changing an amount above the sunnah number. Pause. Quiet hours. Large text. English. Dark.

## 9. The engine rules (calls, exact enough to test)

One file, no screen code in it, usable from the browser and from Node.

- **Day boundary**: the middle of the sleep period, so a before-sleep set after midnight belongs to the day that is ending.
- **Slot**: one chance to appear, every interval inside waking hours. Interval: 180, 60 or 20 minutes. No ordinary slot during a running session, a pause, or the first 20 minutes of a moment's window. After the day is complete the interval doubles (extras).
- **Which dhikr**: among those with something left, the one furthest behind where it should be by this time of day; never the same twice running when there is a choice. Rested adhkar never appear. In extras mode all active adhkar take turns.
- **Ladder**: rungs at 10, 30, 50, 70 and 100 percent of the sunnah number, rounded to the nearest 5 (a result of 0 becomes 5, repeats are dropped); the top rung is the sunnah number exactly (33 gives 5, 10, 15, 25, 33; 15 gives 5, 10, 15). A sunnah number of 10 or less has one rung: itself. A dhikr with no sunnah number uses 10, 20, 33, 50, 70, 100.
- **Start**: "just starting" begins at the 30 percent rung with 3 adhkar, "I do some" at 50 percent with 5, "part of my day" at 100 percent with 8. Fit rule: if the day's total cannot fit in the day's slots at the starting comfort, start one rung lower, down to the lowest.
- **Comfort**: a number per hour of the day, the piece size that hour can take. Starts at 5, 10 or 33 by the onboarding answer.
  - Three finished pieces in a row in an hour: comfort for that hour times 1.25, rounded up, at most 100.
  - Partial (k of the piece): comfort becomes the average of itself and k, at least 1.
  - Closed without a tap twice running in an hour: times 0.75.
  - Untouched three times running in an hour: halved.
  - Later: no change.
- **Per-dhikr factor**: between 0.25 and 1. Two closes running for the same dhikr: times 0.75. Three finishes running: back up by the same step.
- **Long dhikr**: comfort is divided by the number of words over 6, rounded up, so a long dhikr is asked fewer times.
- **Piece**: what is needed to stay on pace for the day, limited by the hour's comfort times the dhikr's factor. In an hour where the person finishes at least 70 percent of pieces the limit may stretch to 1.5 times when the day is behind. Always between 1 and what is left. A piece left partway is continued before a new one is made.
- **Weekly review**, every 7 days, for automatic targets: finished on 5 or more days, up one rung (never past the sunnah number); on 2 or fewer, down one rung; otherwise unchanged. Hand-set targets: at most one suggestion.
- **Heavy dhikr**: at least 5 appearances in the week, closed or ignored in 60 percent or more of them, while the others stay at 30 percent or less.
- **Moments**: On waking at the wake time (window 1 hour); Morning 15 minutes after waking (until noon); Evening at 17:00 (until Before sleep begins); Before sleep 20 minutes before the sleep time (until 1 hour after). Each time is editable. Counts inside a set also count toward that dhikr's day target if it is in My adhkar. "The day is complete" means every target in My adhkar is reached; the moments are not part of that.
- **Resting**: a rested dhikr sits in a "Resting" group at the bottom of My adhkar with a "Bring it back" button, keeps its rung, and is left out of the day's completion.

The numbers above are starting values. They are in one table at the top of the file so the owner's comments can move them.

## 10. The workbench

### 10.1 Files

```
workbench/
  README.md         how to open it, how to comment, what each control does
  index.html
  serve.mjs         optional: serves the folder and writes comments.json
  comments.json     the owner's comments, tracked
  vendor/           react, react-dom, htm (copied from the toolbox workbench)
  fonts/
  css/              tokens (two looks), app, workbench chrome
  js/
    core.js         shared namespace, state, undo, languages
    strings.js      Arabic and English
    data.js         example adhkar, sets, people, example days
    engine.js       section 9, nothing else
    sim.js          the clock and the pretend person
    icons.js        the icon family
    ui.js           shared parts (button, ring, sheet, bar)
    card.js         the dhikr card in three sizes
    onboarding.js  today.js  adhkar.js  add.js  moments.js  weekly.js  more.js
    frames.js       phone frame and Windows frame
    gallery.js      "Icons and motion"
    wb.js           the Workbench menu
    comments.js     the comment tool
  test/
    engine.test.mjs run with node --test
```

### 10.2 Frames

- **Phone**: a fixed-size frame drawn with plain page elements (not an iframe, so the comment tool can reach inside). The app, the popup over a pretend home screen, and the lock screen.
- **Windows**: a pretend desktop with the small corner card, the full card, the tray menu, and the app in a window at desktop width.

### 10.3 The Workbench menu

- **Example day**: first open; a normal day at noon; everything complete; a missed week; the weekly card (up, down, heavy).
- **Simulate a day**: a clock to drag or play, and a pretend person to choose (responsive, busy at noon, ignores one dhikr, away all day). Each appearance and what the engine learned from it is listed in a side log, so the owner can watch pieces grow and shrink.
- Language, light or dark, text size, look A or B, phone or Windows.
- Icons and motion.
- Comments. Reset example data.

State is kept in the browser only. Nothing is sent anywhere.

### 10.4 The comment tool

Ported from the toolbox workbench, same behaviour:

- Press C or the comment button, point at anything, click. A box asks what should change, with a kind: Fix, Idea or Question.
- A numbered pin stays on that element, on that screen, in that example day, language and frame, and comes back when the owner returns there.
- A list of all comments: go to one, mark it done, delete with undo, show or hide done ones, show or hide pins.
- "Copy for Claude" turns the open comments into text.
- Alt-click picks the larger area around an element.

Added here: when the page is opened through `node workbench/serve.mjs`, every change is also written to `workbench/comments.json`, and comments in that file are loaded at start. Opened by double-click it behaves exactly like the toolbox (browser storage and Copy for Claude).

## 11. How it is checked

- `node --test workbench/test/` passes: the ladder, the fit rule, comfort changes for each outcome, the piece limits, which dhikr is picked, the weekly review, the heavy-dhikr rule, the day boundary, extras pace.
- Opened from disk in Chrome: every situation in 8.5 can be reached, in Arabic and in English, with no console errors and no clipped text.
- A comment pinned inside the phone frame survives a reload and a change of example day and back.

## 12. Left to the builder

- The two looks, the icon drawings and the exact motion, using the design skills.
- The exact wording, in Egyptian Arabic and English.
- Which library entries become the starting adhkar and the four sets.
- How the code inside each file is arranged.

## 13. Open after approval

- The owner's comments on the first full pass drive the next rounds. The prototype is done when the owner says it is.
- Real sunnah numbers and their sources (scholar review, already listed in `docs/human-lane/`).
