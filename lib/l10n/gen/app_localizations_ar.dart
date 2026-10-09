// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ذِكر';

  @override
  String get splashDescription =>
      'تذكير هادي بالأذكار، قاعد جنب الساعة وبيفكّرك بذكر الله.';

  @override
  String get homeSubtitle =>
      'كل شوية هيظهرلك ذكر. اضغط عليه وعدّه وبعدين كمّل اللي كنت بتعمله.';

  @override
  String get commonTestReminder => 'وريني تذكير دلوقتي';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonSave => 'حفظ';

  @override
  String get dhikrReminderTitle => 'تذكير بذكر الله';

  @override
  String get dhikrReminderTouchEverywhereTip => 'اضغط في أي مكان عشان تعدّ';

  @override
  String get dhikrReminderHideArabic => 'اخفي العربي';

  @override
  String get dhikrReminderShowArabic => 'اظهر العربي';

  @override
  String get trayOpenApp => 'افتح التطبيق';

  @override
  String get trayNextDhikr => 'الذكر الجاي';

  @override
  String trayNextDhikrIn(String time) {
    return 'بعد $time';
  }

  @override
  String get trayNextDhikrPending => 'مستني الإعدادات';

  @override
  String get traySoundOn => 'الصوت شغال';

  @override
  String get traySoundOff => 'الصوت مقفول';

  @override
  String get trayPause => 'وقّف التذكيرات ساعة';

  @override
  String get trayResume => 'كمّل التذكيرات';

  @override
  String trayPausedUntil(String time) {
    return 'واقف لحد $time';
  }

  @override
  String get settingsAutostartTitle => 'افتح مع ويندوز';

  @override
  String get settingsAutostartSubtitle =>
      'يفتح بهدوء جنب الساعة أول ما تشغّل الجهاز.';

  @override
  String get trayQuit => 'اقفل التطبيق';

  @override
  String get updateTitle => 'التحديثات';

  @override
  String get updateSubtitle => 'خلّي ذِكر على آخر نسخة';

  @override
  String updateVersion(String version) {
    return 'النسخة $version';
  }

  @override
  String get updateNeverChecked => 'لسه ماشوفناش في تحديثات';

  @override
  String get updateChecking => 'بندوّر على تحديثات...';

  @override
  String get updateUpToDate => 'إنت على آخر نسخة';

  @override
  String updateLastChecked(String time) {
    return 'آخر فحص الساعة $time';
  }

  @override
  String updateAvailable(String version) {
    return 'النسخة $version نزلت';
  }

  @override
  String get updateAvailableManual =>
      'النسخة دي مش متسطّبة من برنامج التسطيب، فمش هتقدر تحدّث نفسها. نزّل برنامج التسطيب الجديد من صفحة الإصدارات.';

  @override
  String get updateAvailableAutoOff =>
      'التحديث التلقائي مقفول. اضغط حدّث دلوقتي عشان تسطّب النسخة الجديدة.';

  @override
  String updateDownloading(String version) {
    return 'بننزّل النسخة $version...';
  }

  @override
  String updateReady(String version) {
    return 'النسخة $version جاهزة للتسطيب';
  }

  @override
  String get updateReadyHint =>
      'هتتسطّب لوحدها أول ما تقفل الشاشة دي ومايبقاش في تذكير ظاهر.';

  @override
  String updateInstalling(String version) {
    return 'بنسطّب النسخة $version...';
  }

  @override
  String get updateFailed => 'معرفناش نشوف في تحديثات';

  @override
  String get updateFailedHint => 'اتأكد إن النت شغال. هنحاول تاني بعد شوية.';

  @override
  String get updateCheckButton => 'شوف في تحديثات';

  @override
  String get updateInstallButton => 'حدّث دلوقتي';

  @override
  String get updateRestartButton => 'اقفل وحدّث';

  @override
  String get updateDownloadPageButton => 'افتح صفحة التنزيل';

  @override
  String get updateAutoLabel => 'حدّث تلقائي';

  @override
  String get updateAutoSubtitle =>
      'نزّل النسخ الجديدة في الخلفية وسطّبها لما التطبيق يكون فاضي';

  @override
  String get updatePlayTitle => 'التحديثات بتيجي من Google Play';

  @override
  String get updatePlayHint =>
      'سيب التحديث التلقائي شغال في Google Play والنسخ الجديدة هتتسطّب لوحدها.';

  @override
  String get updateOpenPlayButton => 'افتح Google Play';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get statToday => 'ذكر النهارده';

  @override
  String get homeNextReminder => 'التذكير الجاي';

  @override
  String get homePauseShort => 'وقّف ساعة';

  @override
  String get homeResumeShort => 'كمّل';

  @override
  String get navNotifications => 'الإشعارات';

  @override
  String get notifTitle => 'الإشعارات';

  @override
  String get notifSubtitle => 'اختار كل قد إيه يوصلك ذكر، وأنهي أذكار.';

  @override
  String get notifIntervalTitle => 'فكّرني كل';

  @override
  String get notifSettingsTitle => 'إعدادات التذكير';

  @override
  String get notifSummaryEqual => 'كل الأذكار بنفس الفرصة';

  @override
  String get notifSummaryWeighted => 'الأذكار بحسب أولويتها';

  @override
  String notifIntervalMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      few: '$minutes دقايق',
      two: 'دقيقتين',
      one: 'دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get notifSoundTitle => 'الصوت';

  @override
  String get notifSoundSubtitle => 'شغّل صوت لما التذكير يوصل';

  @override
  String get notifPriorityTitle => 'أولوية الأذكار';

  @override
  String get notifPrioritySubtitle => 'حدّد نسبة ظهور كل ذكر';

  @override
  String get notifOverlayArabicTitle => 'العربي في التذكير';

  @override
  String get notifOverlayArabicSubtitle =>
      'اقفله عشان يظهر النطق بس في التذكير';

  @override
  String get notifMySection => 'أذكاري';

  @override
  String get notifAddDhikr => 'إضافة ذكر';

  @override
  String get notifEmptyTitle => 'لسه مفيش أذكار';

  @override
  String get notifEmptyHint =>
      'اختار من موسوعة الأذكار الأذكار اللي عايز نفكّرك بيها.';

  @override
  String get notifEditTitle => 'تعديل الذكر';

  @override
  String get notifAmountLabel => 'عدد مرات التكرار';

  @override
  String notifRepeatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرة',
      few: '$count مرات',
      two: 'مرتين',
      one: 'مرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get notifFrequencyLabel => 'نسبة ظهوره';

  @override
  String get notifFrequencyNever => 'مش هيظهر';

  @override
  String notifFrequencyValue(int value) {
    return '$value من 10';
  }

  @override
  String get notifFrequencyHint =>
      'ده وزن مش نسبة مئوية: اللي على 6 بيظهر ضعف اللي على 3. والصفر معناه إنه مش هيظهر خالص.';

  @override
  String get notifDeleted => 'الذكر اتمسح';

  @override
  String get notifUndo => 'تراجع';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonAllow => 'سماح';

  @override
  String get notifGoalTitle => 'هدف اليوم';

  @override
  String get notifGoalSubtitle => 'حدد عدد الهدف اليومي';

  @override
  String notifGoalCount(int count) {
    return '$count في اليوم';
  }

  @override
  String notifGoalProgress(int done, int goal) {
    return 'النهارده $done من $goal';
  }

  @override
  String get commonClose => 'إغلاق';

  @override
  String get overlayPromptTitle => 'عايز التذكيرات تظهر فوق التطبيقات التانية؟';

  @override
  String get overlayPromptBody =>
      'فعّل \"الظهور فوق التطبيقات الأخرى\" عشان كل تذكير يظهرلك قدامك على طول فوق أي تطبيق شغّال. من غيرها التذكيرات هتوصلك كإشعارات عادية.';

  @override
  String get overlayPromptLater => 'مش دلوقتي';

  @override
  String get overlayPreviewHint =>
      'ده اللي هيظهرلك بعد كده. دوّر على ذِكر في القايمة وشغّل الزرار بتاعه، وبعدين ارجع للتطبيق. لو القايمة طويلة، ممكن تلاقي ذِكر في الآخر، أو استخدم زرار البحث اللي فوق.';

  @override
  String get overlayPreviewScreenTitle => 'الظهور فوق التطبيقات الأخرى';

  @override
  String get overlayMissingTitle => 'التذكيرات مش هتظهر فوق التطبيقات التانية';

  @override
  String get overlayMissingBody =>
      'دلوقتي التذكير بيوصلك كإشعار صغير ممكن يفوتك. اسمح بده عشان يظهرلك قدامك على طول.';

  @override
  String get batteryPromptTitle => 'خلّي التذكيرات شغالة';

  @override
  String get batteryPromptBody =>
      'الموبايل ساعات بيقفل التطبيقات اللي في الخلفية عشان يوفّر البطارية، وساعتها التذكيرات بتقف. اسمح للتطبيق يفضل شغال، وبعدين اضغط سماح في الشباك اللي هيظهر.';

  @override
  String get batteryMissingTitle => 'التذكيرات ممكن تقف بعد شوية';

  @override
  String get batteryMissingBody =>
      'الموبايل بيقيّد التطبيق في الخلفية، فالتذكيرات ممكن تقف لحد ما تفتح التطبيق تاني. اسمح له يفضل شغال.';

  @override
  String get bugReportTitle => 'بلّغ عن مشكلة';

  @override
  String get bugReportSubtitle => 'في حاجة مش شغالة صح؟ قولنا إيه اللي حصل.';

  @override
  String get bugReportDialogTitle => 'بلّغ عن مشكلة';

  @override
  String get bugReportDescriptionLabel => 'إيه اللي حصل؟';

  @override
  String get bugReportDescriptionHint =>
      'اكتب كنت بتعمل إيه، وإيه اللي كنت مستنيه، وإيه اللي حصل بدله.';

  @override
  String get bugReportDetailsNote =>
      'رقم النسخة ونوع موبايلك أو جهازك بيتضافوا للبلاغ لوحدهم. البلاغ بيفتح في المتصفح وتراجعه قبل ما تبعته.';

  @override
  String get bugReportOpen => 'افتح البلاغ';

  @override
  String get bugReportEmpty => 'اكتب إيه اللي حصل الأول';

  @override
  String get bugReportOpenFailed =>
      'معرفناش نفتح المتصفح، فنسخنا البلاغ. الصقه في Issue جديد على GitHub.';

  @override
  String get navLibrary => 'موسوعة الأذكار';

  @override
  String get libraryTitle => 'موسوعة الأذكار';

  @override
  String get librarySubtitle =>
      'دوّر في كل الأذكار والأدعية وصفّيها بالمجموعة.';

  @override
  String get librarySearchHint => 'دوّر في الأذكار والأدعية...';

  @override
  String get librarySearchClear => 'امسح البحث';

  @override
  String libraryResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ذكر',
      few: '$count أذكار',
      two: 'ذكرين',
      one: 'ذكر واحد',
      zero: 'مفيش أذكار',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmptyTitle => 'مفيش حاجة بتطابق بحثك';

  @override
  String get libraryEmptyHint => 'جرّب كلمة تانية، أو امسح الفلاتر.';

  @override
  String get libraryEmptyAction => 'امسح الفلاتر';

  @override
  String get libraryQuickSettings => 'الإعدادات والفلاتر';

  @override
  String get libraryTashkeelLabel => 'إظهار التشكيل';

  @override
  String get libraryTashkeelSubtitle => 'إظهار الحركات على الحروف';

  @override
  String get libraryHideAddedLabel => 'إخفاء اللي في تذكيراتك';

  @override
  String get libraryHideAddedSubtitle =>
      'الأذكار اللي ضفتها لتذكيراتك مش هتظهر في القايمة';

  @override
  String get libraryArabicLabel => 'إظهار العربي';

  @override
  String get libraryArabicSubtitle => 'اقفله لو عايز تقرا النطق بس';

  @override
  String get libraryHidingAdded => 'من غير اللي عندك';

  @override
  String get libraryAddUiShow => 'إظهار أزرار الإضافة';

  @override
  String get libraryAddUiHide => 'إخفاء أزرار الإضافة';

  @override
  String get libraryFontSizeLabel => 'حجم الخط';

  @override
  String get libraryFontIncrease => 'كبّر الخط';

  @override
  String get libraryFontDecrease => 'صغّر الخط';

  @override
  String libraryFontValue(int size) {
    return '$size بكسل';
  }

  @override
  String get libraryClose => 'إغلاق';

  @override
  String get libraryFilterTitle => 'صفّي بالمجموعة';

  @override
  String get libraryFilterSubtitle =>
      'اختار مجموعة أو أكتر. ولو ماختارتش حاجة هتشوف كل الأذكار.';

  @override
  String get libraryFilterAll => 'الكل';

  @override
  String get libraryFilterClear => 'امسح الفلاتر';

  @override
  String libraryFilterCount(int count) {
    return 'اخترت $count';
  }

  @override
  String get libraryAddButton => 'ضيف للتذكيرات';

  @override
  String get libraryAddedButton => 'في تذكيراتك';

  @override
  String get libraryAddConfirm => 'ضيف';

  @override
  String get libraryAddedNote =>
      'الذكر ده في تذكيراتك وبيظهرلك زي باقي الأذكار.';

  @override
  String get libraryAddRepeatsLabel => 'هتقوله كام مرة؟';

  @override
  String libraryRecommendedCount(int count) {
    return 'الوارد في المصدر: $count';
  }

  @override
  String get libraryRemoveButton => 'شيله من التذكيرات';

  @override
  String get libraryAddedSnack => 'الذكر اتضاف لتذكيراتك';

  @override
  String get libraryRemovedSnack => 'الذكر اتشال من تذكيراتك';

  @override
  String get libraryReadOnlyNote => 'للقراءة بس، مش بيتضاف للتذكيرات';

  @override
  String get libraryAddHintTitle => 'اختار الذكر اللي عايز تضيفه';

  @override
  String get libraryAddHintBody =>
      'دوس على \"ضيف للتذكيرات\" تحت أي ذكر وهيتضاف لقايمتك.';

  @override
  String get libraryAddHintBack => 'رجوع للإشعارات';

  @override
  String get requestsTitle => 'طلباتي';

  @override
  String get requestsSubtitle => 'تابع حالة الأذكار اللي طلبت إضافتها.';

  @override
  String get requestTileTitle => 'مش لاقي الذكر اللي عايزه؟';

  @override
  String get requestTileBody => 'ابعتلنا الذكر وهنراجعه ونضيفه لو مناسب.';

  @override
  String get requestTileButton => 'اطلب إضافة ذكر';

  @override
  String get requestEmptyAction => 'اطلب إضافته';

  @override
  String get requestSheetTitle => 'اطلب إضافة ذكر';

  @override
  String get requestSheetIntro =>
      'اكتب الذكر زي ما هو وارد وهنراجعه قبل ما نضيفه. بنبعت النص ده بس، ومفيش أي بيانات عنك.';

  @override
  String get requestTextLabel => 'نص الذكر';

  @override
  String get requestTextHint => 'اكتب الذكر كامل بالعربي';

  @override
  String get requestSourceLabel => 'المصدر (لو تعرفه)';

  @override
  String get requestSourceHint => 'مثلا: رواه البخاري';

  @override
  String get requestSend => 'ابعت الطلب';

  @override
  String get requestSending => 'جاري الإرسال...';

  @override
  String get requestProblemTooShort => 'الذكر قصير أوي، اكتبه كامل.';

  @override
  String requestProblemTooLong(int max) {
    return 'الذكر طويل أوي. الحد الأقصى $max حرف.';
  }

  @override
  String get requestProblemNotArabic => 'اكتب الذكر بالعربي.';

  @override
  String get requestProblemHasLink => 'ممنوع الروابط والرموز الغريبة هنا.';

  @override
  String get requestProblemRepeated => 'فيه حروف مكررة كتير، راجع الكتابة.';

  @override
  String requestProblemTooManyOpen(int count) {
    return 'عندك $count طلبات لسه مستنية. استنى لحد ما واحد فيهم يخلص.';
  }

  @override
  String get requestProblemDailyLimit =>
      'وصلت للحد الأقصى النهارده. جرب تاني بكرة.';

  @override
  String requestProblemTooSoon(int seconds) {
    return 'استنى $seconds ثانية قبل الطلب الجاي.';
  }

  @override
  String get requestProblemBusy => 'الخدمة مشغولة دلوقتي. جرب كمان شوية.';

  @override
  String get requestProblemRejected =>
      'مقدرناش نقبل الطلب ده. راجع النص وجرب تاني.';

  @override
  String get requestExistsTitle => 'الذكر ده موجود عندنا';

  @override
  String get requestExistsBody => 'ممكن يكون هو اللي بتدور عليه:';

  @override
  String get requestExistsShow => 'شوفه في الموسوعة';

  @override
  String get requestExistsSendAnyway => 'مش هو، ابعت طلبي';

  @override
  String get requestOwnTitle => 'انت طلبت الذكر ده قبل كده';

  @override
  String get requestOwnBody => 'تقدر تتابع حالته من طلباتي.';

  @override
  String get requestOwnShow => 'افتح طلباتي';

  @override
  String get requestSentTitle => 'وصل طلبك';

  @override
  String get requestSentBody =>
      'شكرا لمساهمتك. هنراجع الذكر ولو مناسب هنضيفه، وتقدر تتابع حالته من طلباتي.';

  @override
  String get requestDuplicateBody =>
      'ناس تانية طلبت الذكر ده كمان فضفناك معاهم. شكرا لصبرك.';

  @override
  String get requestQueuedTitle => 'الطلب محفوظ';

  @override
  String get requestQueuedBody => 'مفيش نت دلوقتي. هنبعته أول ما النت يرجع.';

  @override
  String get requestSentOk => 'تمام';

  @override
  String get requestsEmptyTitle => 'لسه ماطلبتش أي ذكر';

  @override
  String get requestsEmptyBody =>
      'لو مش لاقي ذكر في الموسوعة اطلب إضافته وهتلاقي حالته هنا.';

  @override
  String get requestsRefresh => 'حدّث';

  @override
  String get requestsNewButton => 'طلب جديد';

  @override
  String get requestStatusQueued => 'مستني النت';

  @override
  String get requestStatusPending => 'وصل ومستني المراجعة';

  @override
  String get requestStatusInProgress => 'بنشتغل عليه';

  @override
  String get requestStatusDone => 'اتضاف';

  @override
  String get requestStatusDeclined => 'مش هيتضاف';

  @override
  String get requestNoteQueued => 'هيتبعت أول ما النت يرجع.';

  @override
  String get requestNotePending => 'شكرا لصبرك. هنراجعه وهتلاقي الرد هنا.';

  @override
  String get requestNoteInProgress =>
      'جزاك الله خيرا على صبرك. الذكر ده بيتراجع ويتجهز للإضافة دلوقتي.';

  @override
  String get requestNoteDone =>
      'جزاك الله خيرا على مساهمتك. الذكر ده بقى في الموسوعة.';

  @override
  String get requestNoteDoneLater =>
      'جزاك الله خيرا على مساهمتك. الذكر ده جاهز وهيوصلك في التحديث الجاي.';

  @override
  String requestNoteDoneVersion(String version) {
    return 'جزاك الله خيرا على مساهمتك. الذكر ده هيوصلك في الإصدار $version.';
  }

  @override
  String get requestNoteDuplicate =>
      'الذكر ده موجود فعلا في الموسوعة. جرب تدور عليه بكلمة تانية، وشكرا على اهتمامك.';

  @override
  String get requestNoteUnclear =>
      'مقدرناش نتأكد من نص الذكر. ممكن تبعته تاني مكتوب بوضوح مع مصدره، وشكرا ليك.';

  @override
  String get requestNoteNotSuitable =>
      'الطلب ده مش مناسب للإضافة دلوقتي. شكرا على اهتمامك وربنا يتقبل منك.';

  @override
  String get requestNoteOther =>
      'مقدرناش نضيف الطلب ده المرة دي. شكرا على اهتمامك.';

  @override
  String requestVotes(int count) {
    return '$count ناس طلبوا الذكر ده';
  }

  @override
  String get requestShowInLibrary => 'شوفه في الموسوعة';

  @override
  String get requestRemove => 'شيله من القايمة';

  @override
  String get tagMorning => 'أذكار الصباح';

  @override
  String get tagEvening => 'أذكار المساء';

  @override
  String get tagAfterPrayer => 'أذكار بعد الصلاة';

  @override
  String get tagTasabih => 'تسابيح';

  @override
  String get tagSleep => 'أذكار النوم';

  @override
  String get tagWaking => 'أذكار الاستيقاظ';

  @override
  String get tagPrayer => 'أذكار الصلاة';

  @override
  String get tagJawamiDuas => 'جوامع الدعاء';

  @override
  String get tagPropheticDuas => 'أدعية نبوية';

  @override
  String get tagQuranicDuas => 'الأدعية القرآنية';

  @override
  String get tagProphetsDuas => 'أدعية الأنبياء';

  @override
  String get tagMisc => 'أذكار متفرقة';

  @override
  String get tagAdhan => 'أذكار الأذان';

  @override
  String get tagMosque => 'أذكار المسجد';

  @override
  String get tagWudu => 'أذكار الوضوء';

  @override
  String get tagHome => 'أذكار المنزل';

  @override
  String get tagKhalaa => 'أذكار الخلاء';

  @override
  String get tagFood => 'أذكار الطعام';

  @override
  String get tagHajjUmrah => 'أذكار الحج والعمرة';

  @override
  String get tagKhatmQuran => 'دعاء ختم القرآن الكريم';

  @override
  String get tagVirtueOfDua => 'فضل الدعاء';

  @override
  String get tagVirtueOfDhikr => 'فضل الذكر';

  @override
  String get tagVirtueOfSuras => 'فضل السور';

  @override
  String get tagVirtueOfQuran => 'فضل القرآن';

  @override
  String get tagDuasForDeceased => 'أدعية للميّت';

  @override
  String get tagRuqyah => 'الرُّقية الشرعية';

  @override
  String get aboutLink => 'عن التطبيق';

  @override
  String get aboutTitle => 'عن ذِكر';

  @override
  String aboutVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get aboutSources =>
      'الأذكار متجمّعة من مصادر منشورة، ومراجعتها على أيدي أهل العلم لسه مكمّلتش. لو لقيت غلطة، اضغط ضغطة طويلة على الذكر في الموسوعة وابعتها لنا.';

  @override
  String get aboutPrivacy =>
      'من غير إعلانات ولا حسابات ولا تتبّع. بياناتك على جهازك بس، ما عدا طلب إضافة ذكر لو إنت اللي بعتّه.';

  @override
  String get aboutFonts =>
      'الخطوط: IBM Plex Sans Arabic و Noto Sans Arabic، بترخيص SIL Open Font License.';

  @override
  String get aboutLicenses => 'تراخيص المكتبات المفتوحة';

  @override
  String get reportMistakeTitle => 'في غلطة في الذكر ده؟';

  @override
  String get reportMistakeBody =>
      'هنفتحلك صفحة جاهزة على GitHub تبعت منها. مفيش حاجة بتتبعت غير لما تدوس إرسال هناك.';

  @override
  String get reportMistakeSend => 'افتح الصفحة';

  @override
  String get reportMistakeOpenFailed => 'مقدرناش نفتح المتصفح. البلاغ اتنسخ.';

  @override
  String get storageRestoredNotice =>
      'رجّعنا أذكارك من النسخة الاحتياطية لأن ملف الإعدادات كان بايظ.';

  @override
  String get commonOpenSettings => 'افتح الإعدادات';

  @override
  String get notifBlockedTitle => 'الإشعارات مقفولة';

  @override
  String get notifBlockedBody =>
      'التذكيرات مش هتوصلك لأن إشعارات التطبيق مقفولة. افتحها من الإعدادات.';

  @override
  String get remindersStoppedTitle => 'التذكيرات شكلها وقفت';

  @override
  String get remindersStoppedBody =>
      'مفيش تذكير وصلك من فترة. غالبًا الموبايل بيقفل التطبيق في الخلفية. افتح الإعدادات واسمح له يشتغل.';

  @override
  String get quietTitle => 'ساعات الهدوء';

  @override
  String get quietSubtitle => 'من غير تذكيرات وقت النوم';

  @override
  String quietRange(String start, String end) {
    return 'من $start إلى $end';
  }

  @override
  String get quietChange => 'غيّر';

  @override
  String get quietPickStart => 'الهدوء يبدأ الساعة كام؟';

  @override
  String get quietPickEnd => 'الهدوء لحد الساعة كام؟';

  @override
  String get historyRowTitle => 'ذكرك';

  @override
  String historyRowToday(int count) {
    return 'النهارده: $count';
  }

  @override
  String get historyToday => 'النهارده';

  @override
  String get historyLast7 => 'آخر 7 أيام';

  @override
  String get historyLast30 => 'آخر 30 يوم';

  @override
  String get historyTotal => 'الإجمالي';

  @override
  String historyStreak(int days) {
    return '$days يوم ورا بعض';
  }

  @override
  String get historyStreakSwitch => 'اعرض الأيام ورا بعض';

  @override
  String get historyEmpty => 'لسه مفيش عدّ. أول ما تعدّ ذكر هيظهر هنا.';

  @override
  String get soundTitle => 'صوت هادي';

  @override
  String get soundSubtitle => 'نغمة خفيفة لما تخلّص عدّ الذكر';

  @override
  String get libraryCountNow => 'عدّ دلوقتي';

  @override
  String get libraryCopy => 'انسخ النص';

  @override
  String get libraryShare => 'شارك النص';

  @override
  String get libraryCopied => 'اتنسخ';

  @override
  String get libraryReport => 'بلّغ عن غلطة';

  @override
  String get surfaceCountOne => 'عدّ مرة';

  @override
  String get surfaceDone => 'خلّصت';

  @override
  String get surfaceLater => 'بعدين';

  @override
  String trayTodayTotal(int count) {
    return 'النهارده: $count';
  }
}
