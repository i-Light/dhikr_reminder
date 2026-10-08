# Privacy Policy for Dhikr Reminder (ذِكر)

Last updated: 8 October 2026

Dhikr Reminder ("the app") shows a dhikr every few minutes so you can count it
and carry on. This page explains what the app does with your information. The
short version: it collects nothing about you. The one exception is the optional
"Request a dhikr" feature, described below, which sends only what you choose to
send.

## What the app collects

Nothing about you. There are no accounts, no ads, no analytics and no tracking.
The app does not send your dhikr list, your counts or anything else about you to
us or to anyone. The only thing that ever leaves your device is a dhikr request
you decide to make (see below).

## What stays on your device

The app saves these on your own phone or PC so it can work:

- your list of dhikr, how often reminders come, and the language you chose;
- how many times you said each dhikr today;
- the requests you made, and how each one is going.

This data never leaves your device, except the requests as described below.
Uninstalling the app deletes it.

## Requesting a dhikr (optional)

If a dhikr you want is not in the library, you can ask for it to be added. Only
when you press "Send request" does the app contact a small service run by the
developer, so the team can review your request, and afterwards the app asks the
same service how your request is going. If you never use the feature, nothing
is ever sent.

What is sent:

- the dhikr text you typed and, if you filled it in, where you found it;
- a random code the app makes for itself the first time, so you can see your own
  requests and nobody else's. It is not tied to you, your phone, your accounts
  or any other app;
- the app version, the platform (Android or Windows) and the app language.

The service runs on Cloudflare, so Cloudflare sees the IP address of your
connection, as any web host does. The service itself keeps only a scrambled
(salted and hashed) form of that address for one day, to stop abuse, and a
scrambled form of your random code. It cannot tell who you are.

Requests are kept so the team can add the dhikr and so you can see their status.
A dhikr you request may be added to the library for everyone; your code and
details are never shown with it. To have a request deleted, open an issue
(below) quoting the text you sent.

## Permissions on Android, and why

- **Notifications**: to show a reminder as a notification when it cannot appear
  over other apps.
- **Display over other apps**: so each reminder can appear in front of the app
  you are using. You can turn it off at any time in Android settings.
- **Run in the background / ignore battery optimisation**: so Android does not
  stop the app and silently end your reminders.
- **Start at boot**: to schedule your reminders again after the phone restarts.
- **Foreground service**: only while a reminder card is on screen.
- **Internet**: only for "Request a dhikr", described above. The app makes no
  other connection.

None of these permissions is used to read or send your data, apart from the
internet permission carrying a request you chose to make.

## Network use

- **Android**: the app connects to the internet only to send a dhikr request
  you made and to ask how your requests are going.
- **Windows**: the app asks GitHub (`api.github.com`) once an hour whether a new
  version exists, and downloads the installer from GitHub when there is one. As
  with any web request, GitHub can see your IP address. The app sends no other
  information to GitHub. "Request a dhikr" works as described above.
- **Report a bug**: this opens your browser on a GitHub page, filled in with
  what you wrote, the app version and your device model. Nothing is sent unless
  you read it and press the button on that page yourself.

## Children

The app does not knowingly collect any information from anyone, including
children.

## Changes

If this policy changes, the new version will be published here with a new date.

## Contact

Open an issue at <https://github.com/i-Light/dhikr_reminder/issues>.

---

# سياسة الخصوصية لتطبيق ذِكر

آخر تحديث: 8 أكتوبر 2026

التطبيق مش بيجمع أي بيانات عنك. مفيش حسابات ولا إعلانات ولا تتبّع. الاستثناء
الوحيد هو ميزة "اطلب إضافة ذكر" الاختيارية، وبتبعت بس اللي انت قررت تبعته.

- قايمة أذكارك وعدّادك واللغة اللي اخترتها بتتحفظ على موبايلك أو جهازك بس، ومش
  بتتبعت لأي حد. لما تمسح التطبيق كل ده بيتمسح.
- لو الذكر اللي عايزه مش في الموسوعة، تقدر تطلب إضافته. التطبيق مبيتصلش بأي
  حاجة غير لما تدوس "ابعت الطلب"، وبعدها بيسأل نفس الخدمة عن حالة طلبك. اللي
  بيتبعت هو: نص الذكر اللي كتبته ومصدره لو كتبته، وكود عشوائي التطبيق بيعمله
  لنفسه عشان تشوف طلباتك انت بس (مش مربوط بيك ولا بموبايلك)، ورقم النسخة
  والنظام (أندرويد أو ويندوز) ولغة التطبيق. الخدمة شغالة على Cloudflare فبتشوف
  عنوان الاتصال زي أي موقع، وإحنا بنحتفظ بنسخة مشفّرة منه ليوم واحد بس لمنع
  الإساءة. الذكر اللي بتطلبه ممكن يتضاف للموسوعة للكل، من غير اسمك ولا الكود.
  لو عايز طلبك يتمسح افتح Issue واكتب فيها نص الذكر اللي بعتّه.
- تطبيق أندرويد بيطلب صلاحية الإنترنت عشان الميزة دي بس، ومبيتصلش بالنت لأي
  حاجة تانية.
- نسخة ويندوز بتسأل GitHub كل ساعة لو في نسخة جديدة، وبتنزّلها منه. مبتبعتش أي
  معلومات تانية.
- زرار "بلّغ عن مشكلة" بيفتح المتصفح على صفحة GitHub متعبّية بالنص اللي كتبته
  ورقم النسخة ونوع جهازك. مفيش حاجة بتتبعت غير لما تقراها وتدوس على الزرار هناك
  بنفسك.
- صلاحيات أندرويد (الإشعارات، الظهور فوق التطبيقات، التشغيل في الخلفية، التشغيل
  بعد إعادة التشغيل) بتستخدم بس عشان التذكيرات تظهر في وقتها.

للتواصل افتح Issue هنا: <https://github.com/i-Light/dhikr_reminder/issues>
