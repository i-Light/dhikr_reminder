import 'package:dhikr_reminder/features/library/domain/dhikr_item.dart';

import 'sections/asma_allah.dart';
import 'sections/daily_life.dart';
import 'sections/deceased_khatm.dart';
import 'sections/duas.dart';
import 'sections/hajj_ruqyah.dart';
import 'sections/morning_evening.dart';
import 'sections/prayer.dart';
import 'sections/prophets.dart';
import 'sections/quranic_duas.dart';
import 'sections/sleep_waking.dart';
import 'sections/tasabih_misc.dart';
import 'sections/virtue.dart';

/// The azkar library's content: every section under `sections/`, in one
/// `const` list.
///
/// Plain data rather than a database or a JSON asset, for one reason — the
/// library screen's search and tag filter then walk an in-memory list, with
/// nothing to parse, nothing to load asynchronously and nothing to keep in
/// step. The split into files is only so no single file runs to thousands of
/// lines; the screen never depends on which file an entry lives in, only on
/// its [DhikrItem.tags].
///
/// The concatenation order is the order the unfiltered list shows: the daily
/// adhkar first (morning through night), then the duas and the prophets, then
/// the reference half — the virtues, the names of Allah, and the duas for the
/// occasions that have no time of day.
const List<DhikrItem> dhikrLibrary = <DhikrItem>[
  ...morningEveningAdhkar,
  ...prayerAdhkar,
  ...sleepWakingAdhkar,
  ...dailyLifeAdhkar,
  ...tasabihMiscAdhkar,
  ...duasAdhkar,
  ...prophetsAdhkar,
  ...quranicDuas,
  ...hajjRuqyahAdhkar,
  ...virtueAdhkar,
  ...asmaAllahAdhkar,
  ...deceasedKhatmAdhkar,
];
