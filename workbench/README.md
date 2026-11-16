# Dhikr workbench

A clickable web prototype of the dhikr reminder app, built as plain HTML, CSS and JavaScript so every screen, card and adaptive engine rule can be tried and commented on directly in Chrome or Edge. No install, no build, no network calls.

## Open it

Double-click `workbench/index.html` in Chrome or Edge. Everything works directly from `file://`.

## Comment on anything

- Press `C` (or click `Comment (C)` in the top bar), point at any button, row, card, icon or word, and click. Hold `Alt` to target the whole screen.
- Pick `Fix`, `Idea` or `Question`, write your note, and press `Ctrl+Enter` or `Save`.
- Open `Comments (n)` in the top bar to filter open or done notes, jump back to the exact screen, language, frame and example day where a note was pinned, or click `Copy open for Claude`.
- Optional shared file mode (requires Node 20 or newer):

      node workbench/serve.mjs

  Open `http://127.0.0.1:4173/` (set `PORT` to change the port). Comments then sync automatically with `workbench/comments.json`.

## The Workbench menu

All controls in the dark top bar sit outside the app frames and are ignored by the comment picker:

- **Example day**: loads a state produced by running the real engine through `sim.js`.
- **Simulate a day**: opens a side panel with a pretend person (`Responsive`, `Busy at noon`, `Ignores one dhikr`, `Away all day`), a waking-day clock slider, `Play` / `Pause`, `Next day`, `Next week`, and a live appearance log showing each piece, what the person did, and how hourly comfort changed. Dragging backward restores the start-of-day snapshot and replays deterministically.
- **Frame**: `Phone` (390x844 with home-screen and lock-screen overlays) or `Windows` (desktop window with a labelled side navigation rail, 720 px max content width, bottom-corner card, dimmed full-screen card, tray menu, and keyboard `Space` / `Enter` to count and `Escape` to close).
- **Language**: Egyptian Arabic (`ar`, RTL, primary) or English (`en`, LTR, adds transliteration under dhikr text).
- **Theme**: `Light` or `Dark`.
- **Text**: `A` (18 px body / 30 px dhikr), `A+` (21 px / 36 px), `A++` (24 px / 42 px).
- **Look**: `A Olive` (olive wood and lime plaster, IBM Plex Sans Arabic UI, centred Amiri Regular dhikr, eight-point star ornament) or `B Iznik` (porcelain tile and cobalt ink, Noto Sans Arabic UI, start-aligned Amiri Bold dhikr, pointed arch ornament).
- **Reminder now**: `Small`, `Full` or `Lock screen`.
- **Moment card**: previews the timed moment arrival card (`On waking`, `Morning`, `Evening`, `Before sleep`).
- **Icons and motion**: opens the token, icon, component and animation gallery (`?route=gallery`).
- **Reset example data**: restores the current example day while keeping your saved comments.

## Example days

- `first`: first open, starting at onboarding step 1.
- `noon`: a normal day at 12:10 with morning moments done and adhkar in progress.
- `complete`: 22:10 with every active target reached and extras available.
- `missed`: back after 8 days away, showing the gentle welcome-back state and stepped-down targets.
- `weekup`: 7 days of steady completion, waiting with a weekly card that steps targets up one rung.
- `weekdown`: 7 partial days, waiting with a quiet weekly adjustment.
- `weekheavy`: 7 days where one dhikr was repeatedly closed while others finished, offering `Keep it`, `Make it lighter`, or `Rest it for now`.

## URL contract

State can be opened directly by query string:

    ?day=first|noon|complete|missed|weekup|weekdown|weekheavy
    &lang=ar|en&frame=phone|windows&look=a|b&theme=light|dark&size=1|2|3
    &route=<route>&popup=small|full|moment|lock&panel=comments

Routes: `onboarding/1` to `onboarding/6`, `today`, `adhkar`, `adhkar/<id>`, `add`, `add/<group>`, `moments`, `moments/<key>`, `session/<key>`, `count/<id>`, `weekly`, `more`, `more/<row>`, `days`, `gallery`.

Test hooks (read by `js/app.js` for automated tests): `junk=1`, `seedComment=<data-id>`, `autoComment=<data-id>`, `autoTap=<n|all>`, `autoClick=a,b,c`, `restAll=1`, `long=1`, `sim=<person>`, `simTo=HH:MM`, `simBack=HH:MM`.

## Run the tests

    node --test "workbench/test/*.test.mjs"

Covers `engine.test.mjs` (ladder, comfort, piece sizing, carry, weekly review, immutability), `sim.test.mjs` (determinism, personas, example days), `text.test.mjs` (bilingual parity and forbidden-character checks), `serve.test.mjs` (comment sync and path safety), and `smoke.test.mjs` (headless Edge/Chrome DOM, flows, Windows frame, simulator, and full route sweep).

## Fonts and licences

All fonts are local files in `workbench/fonts/`, loaded via `@font-face` in `css/tokens.css`:

- **IBM Plex Sans Arabic** (`IBMPlexSansArabic-Regular.ttf`, `Medium.ttf`, `SemiBold.ttf`): SIL Open Font License 1.1, copied from the app's `assets/fonts/`. UI font for Look A (Olive).
- **Noto Sans Arabic** (`NotoSansArabic-Variable.ttf`): SIL Open Font License 1.1, copied from the app's `assets/fonts/`. UI font for Look B (Iznik).
- **Amiri** (`Amiri-Regular.ttf`, `Amiri-Bold.ttf`): SIL Open Font License 1.1 (`fonts/Amiri-OFL.txt`), from the official `google/fonts` repository (`ofl/amiri/`). Classical Naskh face used for dhikr text in both looks.

## What is pretend in this prototype

- **Phone permissions** (onboarding step 6 and the `Fix it` banner when a permission is skipped) simulate Android overlay, notification and background permissions in browser state.
- **Phone home/lock overlays and the Windows desktop/taskbar/tray** are HTML frames around the app so reminders and tray actions can be tried and commented on in one browser tab.
- **Sound and vibration** store your choice in UI state without playing audio or vibrating the device.
- **Backup, Request a dhikr, Report a problem and Updates** under `More > Other` confirm the action with a local toast; nothing leaves the browser.

## Words to check

Every visible Arabic string (`js/strings.js`), written in natural Egyptian Arabic for the owner to review and tune:

- `app.name`: ذِكر / Dhikr
- `tab.today`: النهارده / Today
- `tab.adhkar`: أذكاري / My adhkar
- `tab.more`: المزيد / More
- `moment.waking`: أول ما تصحى / On waking
- `moment.morning`: الصبح / Morning
- `moment.evening`: المسا / Evening
- `moment.sleep`: قبل النوم / Before sleep
- `group.morning`: أذكار الصبح / Morning adhkar
- `group.evening`: أذكار المسا / Evening adhkar
- `group.sleep`: النوم والصحيان / Sleep and waking
- `group.afterprayer`: بعد الصلاة / After prayer
- `group.tasabih`: تسابيح / Tasbih
- `group.duas`: أدعية / Duas
- `level.new`: لسه ببتدي / I'm just starting
- `level.some`: بقول شوية / I do some
- `level.daily`: جزء من يومي / It's part of my day
- `freq.few`: كام مرة في اليوم (كل 3 ساعات تقريبا) / A few times a day (about every 3 hours)
- `freq.hour`: كل ساعة / Every hour
- `freq.often`: كتير (كل 20 دقيقة تقريبا) / Often (about every 20 minutes)
- `btn.start`: ابدأ / Start
- `btn.continue`: كمّل / Continue
- `btn.later`: بعدين / Later
- `btn.close`: اقفل / Close
- `btn.add`: ضيف / Add
- `btn.back`: رجوع / Back
- `btn.undo`: تراجع / Undo
- `btn.chooseforme`: اختارلي إنت / Choose for me
- `step.less`: أقل / Less
- `step.more`: أكتر / More
- `step.mark`: السُّنّة: {n} / Sunnah: {n}
- `step.aday`: في اليوم / a day
- `count.left`: فاضل {n} / {n} left
- `toast.later`: تمام، هنفكّرك تاني بعد 10 دقايق / OK, we will remind you again in 10 minutes
- `card.of`: من {n} / of {n}
- `card.day`: النهارده: {done} من {target} / Today: {done} of {target}
- `card.extra`: زيادة النهارده: {n} / Extra today: {n}
- `card.hint.small`: دوس على الكارت مع كل مرة تقولها / Tap the card each time you say it
- `card.hint.full`: دوس في أي حتة مع كل مرة تقولها / Tap anywhere each time you say it
- `card.done`: تقبّل الله / May Allah accept it
- `card.prev`: اللي قبله / Previous
- `card.next`: اللي بعده / Next
- `ob.step`: {n} من {total} / {n} of {total}
- `ob.lang.q`: اللغة / Language / اللغة / Language
- `ob.lang.ar`: اللغة العربية / اللغة العربية
- `ob.lang.en`: English / English
- `ob.level.q`: الذكر معاك عامل إزاي دلوقتي؟ / How is dhikr with you today?
- `ob.level.sub`: هنبدأ معاك على قدّك، وكل أسبوع نظبّطها / We start at your pace and adjust it every week
- `ob.freq.q`: نفكّرك كل قد إيه؟ / How often may we remind you?
- `ob.freq.sub`: عمرنا ما هنفكّرك أكتر من اللي تختاره / We will never remind you more often than you choose
- `ob.sleep.q`: بتصحى وبتنام إمتى؟ / When do you wake and sleep?
- `ob.sleep.sub`: مش هنبعت حاجة وإنت نايم، وأذكار الصبح والمسا والنوم تيجي في وقتها / Nothing arrives while you sleep, and the morning, evening and bedtime adhkar come at their time
- `ob.wake`: بصحى الساعة / I wake at
- `ob.sleep`: بنام الساعة / I sleep at
- `time.am`: ص / AM
- `time.pm`: م / PM
- `time.earlier`: بدري / Earlier
- `time.later`: متأخر / Later
- `ob.try.q`: جرّب واحد دلوقتي / Try one now
- `ob.try.sub`: ده شكل التذكير. قول الذكر ودوس على الكارت 3 مرات / This is what a reminder looks like. Say the dhikr and tap the card 3 times
- `ob.try.pick`: تحب التذكير يبقى شكله إيه؟ / How should a reminder look?
- `ob.size.small`: كارت صغير / Small card
- `ob.size.small.sub`: يطلع فوق اللي بتعمله وتعدّ عليه / Appears over what you are doing and you count on it
- `ob.size.full`: الشاشة كلها / Full screen
- `ob.size.full.sub`: الذكر بخط كبير وتدوس في أي حتة / The dhikr in large type, tap anywhere
- `ob.perm.q`: خلّي التذكير يوصلك / Let reminders reach you
- `ob.perm.1.t`: يظهر فوق التطبيقات / Show over other apps
- `ob.perm.1.s`: عشان الكارت يطلع قدامك وإنت بتعمل أي حاجة / So the card can appear while you are doing anything
- `ob.perm.2.t`: الإشعارات / Notifications
- `ob.perm.2.s`: لو الكارت ماعرفش يطلع، يوصلك إشعار بداله / If the card cannot appear, a notification comes instead
- `ob.perm.3.t`: يشتغل في الخلفية / Run in the background
- `ob.perm.3.s`: عشان الموبايل مايوقفش التذكير بعد شوية / So the phone does not stop the reminders after a while
- `btn.allow`: اسمح / Allow
- `btn.notnow`: مش دلوقتي / Not now
- `today.welcome`: نورت من تاني / Good to see you again
- `today.fix.text`: التذكير واقف عشان ناقص إذن واحد على الموبايل / Reminders cannot appear yet because one permission is off
- `today.fix.btn`: صلّحها / Fix it
- `today.fix.done`: تمام، التذكير جاهز دلوقتي / Reminders are ready now
- `today.weekly.text`: وقفة الأسبوع جاهزة، شوف أذكارك مشيت إزاي / Your weekly card is ready
- `today.weekly.btn`: شوف الأسبوع ده / See this week
- `today.moment.wait`: ده وقت أذكار {name} / Time for {name} adhkar
- `today.moment.run`: كمّل أذكار {name} من مكان ما وقفت / Continue {name} adhkar from where you stopped
- `today.continue.text`: كنت بدأت ذكر، تكمله دلوقتي؟ / You left a dhikr partway through
- `today.empty.text`: مفيش أذكار شغالة النهارده. ضيف ذكر نبدأ بيه / No active adhkar today. Add one whenever you are ready
- `today.add`: ضيف ذكر / Add a dhikr
- `today.say.text`: قول ذكر دلوقتي لو فاضي دقيقة / Take a quiet moment for one dhikr now
- `today.say.btn`: قول واحد دلوقتي / Say one now
- `today.next`: التذكير الجاي لوحده الساعة {time} / Next reminder on its own at {time}
- `today.paused.until`: التذكير متوقف مؤقتا لحد {time} / Paused until {time}
- `today.complete.title`: أذكار النهارده كملت، تقبّل الله / Today's adhkar are complete
- `today.complete.sub`: لو حابب تزود، أي تسبيحة زيادة بتتحسبلك / Anything more today counts as extra
- `today.saymore`: قول زيادة / Say more
- `today.hint`: التذكير بييجي لوحده طول اليوم، وتقدر تدوس على أي ذكر تحت في أي وقت / Reminders come on their own through the day, or tap any dhikr below whenever you like
- `today.list`: أذكار النهارده / Today's adhkar
- `today.moments`: أوقات الذكر / Daily moments
- `today.row.left`: فاضل {left} من {target} / {left} left of {target}
- `today.row.done`: خلصت {target} / Done ({target})
- `today.row.extra`: خلصت {target} وزيادة {extra} / Done ({target}) +{extra} extra
- `today.mstate.done`: تم / Done
- `today.mstate.waiting`: دلوقتي / Ready
- `today.mstate.running`: بدأت / Started
- `today.mstate.later`: لسه / Later
- `today.mstate.missed`: عدّى / Passed
- `today.mstate.off`: مقفول / Off
- `today.pause`: وقّف التذكير ساعة / Pause for an hour
- `today.resume`: رجّع التذكير / Resume
- `adhkar.sub.sunnah`: {target} في اليوم، السُّنّة: {sunnah} / {target} a day, Sunnah: {sunnah}
- `adhkar.sub.plain`: {target} في اليوم / {target} a day
- `adhkar.moments.title`: أوقات الذكر اليومية / Daily moments
- `adhkar.moments.sub`: الصبح والمسا والنوم وأول ما تصحى / On waking, morning, evening and before sleep
- `adhkar.resting`: واخدة راحة / Resting
- `adhkar.bringback`: رجّعه / Bring it back
- `adhkar.countnow`: عدّ دلوقتي / Count now
- `adhkar.rest`: ريّحه دلوقتي / Rest it
- `adhkar.remove`: شيله / Remove
- `adhkar.removed`: اتشال من أذكارك / Removed from your adhkar
- `adhkar.above`: أكتر من عدد السُّنّة ({sunnah}) / More than the sunnah count ({sunnah})
- `adhkar.todayamount`: عدد النهارده / Today's amount
- `add.title`: ضيف ذكر / Add a dhikr
- `add.search`: دوّر على ذكر أو دعاء / Search adhkar
- `add.suggested`: مقترحة ليك / Suggested for you
- `add.groups`: مجموعات الأذكار / Browse by group
- `add.added`: مضاف / Added
- `add.empty`: مفيش ذكر بالكلمة دي / No matching dhikr found
- `add.group.count`: {n} ذكر / {n} adhkar
- `add.once`: تتقال مرة واحدة / Said once
- `moments.sub`: {time}، {n} أذكار / {time}, {n} adhkar
- `moments.on`: شغال / On
- `moments.off`: مقفول / Off
- `moments.time`: المعاد / Time
- `moments.reset`: رجّع المعاد الأصلي / Use default time
- `moments.contents`: أذكار الوقت ده / In this set
- `moments.item.count`: {n} مرات / {n} times
- `moments.min.one`: حوالي دقيقة واحدة / About 1 minute
- `moments.min.many`: حوالي {n} دقايق / About {n} minutes
- `session.progress`: {n} من {total} / {n} of {total}
- `session.again`: قولها من الأول / Start again
- `weekly.up.title`: مشيت كويس الأسبوع اللي فات / You kept up well this week
- `weekly.up.sub`: ظبطنا عدد النهارده على قد خطوتك للأسبوع الجديد / Here are your daily amounts for the new week
- `weekly.neutral.title`: أذكار الأسبوع الجديد / This week's amounts
- `weekly.neutral.sub`: خلّينا العدد على قد يومك بهدوء / Set gently for the week ahead
- `weekly.change.sunnah`: من {from} لحد {to} في اليوم، والسُّنّة {sunnah} / From {from} to {to} a day, the sunnah is {sunnah}
- `weekly.change.plain`: من {from} لحد {to} في اليوم / From {from} to {to} a day
- `weekly.refuse`: خلّيه {n} / Keep it at {n}
- `weekly.kept`: هيفضل {n} / Keeping at {n}
- `weekly.suggest`: تحب نخليه {to} في اليوم؟ / Try {to} a day this week?
- `weekly.suggest.accept`: ماشي، خلّيه {to} / Set to {to}
- `weekly.heavy.title`: الذكر ده كان تقيل الأسبوع ده / This one was heavy this week
- `weekly.heavy.keep`: خلّيه زي ما هو / Keep it
- `weekly.heavy.lighter`: خفّفه شوية / Make it lighter
- `weekly.heavy.rest`: ريّحه دلوقتي / Rest it for now
- `weekly.done`: ابدأ الأسبوع / Start this week
- `weekly.none`: وقفة الأسبوع بتيجي كل 7 أيام / Your weekly review comes every 7 days
- `more.sound.q`: الصوت والهزة / Sound and vibration
- `more.sound.soft`: صوت هادي مع هزة / Gentle sound and vibration
- `more.sound.vibrate`: هزة بس / Vibration only
- `more.sound.silent`: من غير صوت ولا هزة / Silent
- `more.size.q`: حجم الخط / Text size
- `more.size.1`: عادي / Standard
- `more.size.2`: كبير / Large
- `more.size.3`: كبير أوي / Extra large
- `more.theme.q`: ألوان الشاشة / Appearance
- `more.theme.light`: فاتح / Light
- `more.theme.dark`: غامق / Dark
- `more.days.title`: أيامي / My days
- `more.days.sub`: سجل هادي وخاص على جهازك بس / Simple and kept only on your device
- `days.week`: آخر 7 أيام / Last 7 days
- `days.month`: آخر 30 يوم / Last 30 days
- `days.total`: مجموع الذكر: {n} / {n} said in total
- `days.private`: الأرقام دي ليك لوحدك ومش بتخرج برا جهازك / Kept on your device only
- `more.other`: حاجات تانية / Other
- `more.backup.t`: نسخة احتياطية / Backup
- `more.backup.p`: احفظ أذكارك وإعداداتك في ملف على جهازك عشان ترجّعها لو غيرت الموبايل. / Save your adhkar and settings to a file on your device, or bring them back from one.
- `more.backup.save`: احفظ ملف النسخة / Save backup file
- `more.backup.restore`: رجّع من ملف / Restore from file
- `more.backup.done`: اتحفظت النسخة الاحتياطية / Backup file saved
- `more.request.t`: اطلب إضافة ذكر / Request a dhikr
- `more.request.p`: اكتب الذكر أو الدعاء ومصدره لو عارفه عشان نراجعه ونضيفه. / Write the dhikr or dua and its source if you know it so it can be reviewed.
- `more.problem.t`: بلّغ عن مشكلة / Report a problem
- `more.problem.p`: قولنا إيه اللي ماشتغلش معاك وهنصلّحه. / Tell us what went wrong and we will look into it.
- `more.send`: ابعت / Send
- `more.sent`: وصلت، شكرا ليك / Received, thank you
- `more.updates.t`: التحديثات / Updates
- `more.updates.p`: النسخة الحالية 1.0. شوف لو فيه تحديث جديد نازل. / Current version 1.0. Check whether a newer version is ready.
- `more.updates.btn`: دوّر على تحديث / Check for updates
- `more.updates.ok`: إنت على أحدث نسخة / You are on the latest version
- `more.about.t`: عن التطبيق / About
- `more.about.p`: تطبيق ذكر معمول عشان الذكر يبقى سهل وهادي في يومك. كل حاجة محفوظة على جهازك بس ومفيش أي بيانات بتتبعت لأي حتة. / Built to make daily dhikr calm and effortless. Everything stays on your device and nothing is sent anywhere.
- `tray.open`: افتح / Open
- `tray.count`: قول واحد / Count one
