import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';

/// The localized label for [tag] — what the filter gallery's button says
/// under its emoji.
///
/// Deliberately a free function here rather than a getter on [DhikrTag]: the
/// enum (and with it the whole library data set) stays free of any
/// localization dependency, so the data can be read, tested and reasoned
/// about without a `BuildContext` in hand. Every tag is covered by the
/// exhaustive switch, so adding one to the enum is a compile error here until
/// it is given a label.
String dhikrTagLabel(AppLocalizations l10n, DhikrTag tag) {
  return switch (tag) {
    DhikrTag.morning => l10n.tagMorning,
    DhikrTag.evening => l10n.tagEvening,
    DhikrTag.afterPrayer => l10n.tagAfterPrayer,
    DhikrTag.tasabih => l10n.tagTasabih,
    DhikrTag.sleep => l10n.tagSleep,
    DhikrTag.waking => l10n.tagWaking,
    DhikrTag.prayer => l10n.tagPrayer,
    DhikrTag.jawamiDuas => l10n.tagJawamiDuas,
    DhikrTag.propheticDuas => l10n.tagPropheticDuas,
    DhikrTag.quranicDuas => l10n.tagQuranicDuas,
    DhikrTag.prophetsDuas => l10n.tagProphetsDuas,
    DhikrTag.misc => l10n.tagMisc,
    DhikrTag.adhan => l10n.tagAdhan,
    DhikrTag.mosque => l10n.tagMosque,
    DhikrTag.wudu => l10n.tagWudu,
    DhikrTag.home => l10n.tagHome,
    DhikrTag.khalaa => l10n.tagKhalaa,
    DhikrTag.food => l10n.tagFood,
    DhikrTag.hajjUmrah => l10n.tagHajjUmrah,
    DhikrTag.khatmQuran => l10n.tagKhatmQuran,
    DhikrTag.virtueOfDua => l10n.tagVirtueOfDua,
    DhikrTag.virtueOfDhikr => l10n.tagVirtueOfDhikr,
    DhikrTag.virtueOfSuras => l10n.tagVirtueOfSuras,
    DhikrTag.virtueOfQuran => l10n.tagVirtueOfQuran,
    DhikrTag.asmaAllah => l10n.tagAsmaAllah,
    DhikrTag.duasForDeceased => l10n.tagDuasForDeceased,
    DhikrTag.ruqyah => l10n.tagRuqyah,
  };
}