# Waqf Charter & Succession Guide (ميثاق الوقف والصدقة الجارية)

> *"When a person dies, their deeds come to an end except for three: an ongoing charity (Sadaqah Jariyah), beneficial knowledge, or a righteous child who prays for them."* — Sahih Muslim 1631

**Dhikr Reminder (`ذِكر`)** is dedicated as an open digital *Waqf* (endowment) for the sake of Allah alone. This document records the unchanging covenant of the project and gives any future maintainer — whether a trusted friend, a family member, or a stranger decades from now — everything needed to keep this app alive, pure, and working even when its original author is no longer here.

---

## 1. The Five Unchanging Pillars (Non-Negotiables Forever)

Any official build, continuation, or blessed fork carrying the spirit of this Waqf commits to five permanent rules:

1. **Free Forever, Zero Monetisation**: Never add advertisements, paid tiers, subscriptions, "pro" unlocks, affiliate links, crypto tokens, or intrusive donation popups. Every Muslim — rich or poor, young or elderly — gets the complete experience for free.
2. **100% Local Privacy, Zero Accounts, Zero Tracking**: Never require sign-up, login, phone numbers, or cloud accounts. Never integrate third-party analytics, crash-tracking SDKs that fingerprint users, or ad networks. A person's remembrance of Allah is strictly between them and their Lord.
3. **Sincerity (*Ikhlas*) Over Gamified Ego (*Riyaa'*)**: Never add public leaderboards, competitive streaks that punish missed days with guilt, or "share my dhikr score" badges. Encourage steady, gentle remembrance (*"the most beloved deeds to Allah are the most consistent, even if small"*).
4. **Scholarly Authenticity Only**: Every dhikr, Quranic verse, virtue (*fadl*), and reflection must be grounded in verified Sunni primary sources (*Quran*, *Sahihayn*, *Hisn al-Muslim*) and reviewed by a human. Never ship unreviewed AI-generated religious text or text-to-speech mispronunciations of Arabic adhkar.
5. **Single Calm Purpose**: This app does one job — making daily remembrance of Allah effortless, calm, and beloved. Do not bloat it into an all-in-one portal of unrelated features.

---

## 2. Zero-Maintainer Survival Architecture (How It Outlives Its Creator)

Open-source repositories still die when they depend on one person's servers, store accounts, or fast-rotting frameworks. To survive unattended for decades, the project follows four architectural guarantees:

1. **Offline-First & Silent Server Decay**:
   - All counting, scheduling, adaptive comfort tuning, history, backups, and bundled audio recitations work **100% offline** from day one to year thirty.
   - Any optional network endpoint (such as the Cloudflare `dhikr-requests` Worker or GitHub Release update check) MUST fail **silently and gracefully** with short timeouts, never blocking startup or showing error banners if the domain or server ever expires.
2. **Framework-Agnostic Core Specification**:
   - Keep the adaptive scheduling engine (see `workbench/js/engine.js` and `docs/superpowers/specs/`) and the verified adhkar dataset (`data.js` / JSON) decoupled from platform UI code and covered by deterministic golden tests.
   - When mobile or desktop UI toolkits change 10 or 20 years from now, any developer can port the entire brain of the app to the new platform in a single weekend without guessing how a single rule worked.
3. **Store-Independent Distribution**:
   - **F-Droid & IzzyOnDroid (Android)**: Reproducible builds compiled directly from signed Git tags so Android users can install updates even if a personal Google Play account is closed due to inactivity.
   - **GitHub / Codeberg Releases (Windows & Android)**: Standalone installers and APKs built automatically by CI workflows.
   - **Installable Offline Web App (PWA)**: A zero-build static web app capable of running offline on any phone, tablet, or computer browser with zero app-store gatekeeper.
4. **Frozen, Human-Readable Backup Format**:
   - User exports use plain, versioned UTF-8 JSON (`lib/core/storage/backup_file.dart`) with forward-and-backward compatibility guards so no user ever loses their personal list or lifetime remembrance count across upgrades or forks.

---

## 3. Succession & Handover Protocol (If the Maintainer Is Gone)

If the primary repository goes **12 months** without maintainer response to critical OS-breaking issues or pull requests:

1. **Co-Maintainers Step Forward**: Designated co-owners in the GitHub Organization have full permission and moral trust to merge dependency/OS compatibility updates and cut new releases under `docs/maintenance.md` and `docs/publishing-guide.md`.
2. **Community Continuation Right**: Under the **MIT License** (`LICENSE`) and **CC-BY-4.0 / CC0** (`LICENSE-DATA.md`), any group of trustworthy Muslim developers is explicitly encouraged to fork the repository, maintain compatibility with new Android/Windows/Web versions, submit the fork to F-Droid / app stores, and carry the Waqf forward — keeping the Five Unchanging Pillars intact.
3. **Du'a**: If this codebase, design, or app benefits you or your family, remember its creator, contributors, reviewers, and users in your sincere prayers (*du'a*) for forgiveness, mercy, and acceptance.

---

## ميثاق الوقف والصدقة الجارية (بالعربية)

هذا التطبيق (**ذِكر**) وقفٌ حرٌّ ومفتوح المصدر لوجه الله تعالى، بُني ليكون صدقةً جاريةً وعلمًا يُنتفع به في حياة صاحبه وبعد وفاته.

### الأصول الخمسة الثابتة التي لا تتغير:
1. **مجاني بالكامل للأبد**: بلا إعلانات، ولا اشتراكات، ولا مزايا مدفوعة، ولا استغلال مادي تحت أي مسمى.
2. **خصوصية تامة بغير حسابات ولا تتبّع**: كل بيانات المستخدم وأذكاره وعدد تسبيحاته محفوظة على جهازه وحده؛ لا تسجيل دخول ولا جمع بيانات.
3. **الإخلاص والرفق لا التباهي ولا التأنيب**: لا لوحات شرف علنية، ولا عقاب عند فتور الهمة، بل تدرّج رفيق يعين على المداومة عملاً بقول النبي صلى الله عليه وسلم: «أحب الأعمال إلى الله أدومها وإن قل».
4. **التوثيق الشرعي الموثوق**: الاقتصار على الأذكار الثابتة الصحيحة ومصادرها المعتمدة، وعدم نشر نصوص أو فضائل مولّدة آلياً بغير مراجعة بشرية متقنة.
5. **البقاء والاستغناء عن الخوادم**: يعمل التطبيق بكامل وظائفه دون إنترنت، ويُتاح كوده ومحتواه برخصة مفتوحة (`MIT` و`CC-BY-4.0`) لكل مسلم أمين يكمل مسيرته ويحفظه حياً نافعاً على مرّ السنين.

نسأل الله القبول والإخلاص، ولا تنسوا صاحب العمل وكل من أعان عليه من صالح دعائكم بالمغفرة والرحمة وحسن الختام.
