# Content sources: text, hadith data and audio

The rule for the library: a source is used only if its licence (or a written permission) is on file here. A source with no clear licence is a cross-check at most, never shipped data.

Hadith wording itself is not owned by anyone. What a modern book owns is its selection, translation, commentary and grading text. So we keep our own selection, our own wording of references, and never copy a translation or a book's grading text. This is a working rule, not legal advice; ask a knowledgeable person when unsure.

## Quran text

### Tanzil (Quran text, Uthmani)

Checked: 2026-10-09
Confidence: confirmed (read on tanzil.net)
Sources: https://tanzil.net/docs/text_license
Re-check by: 2027-10-09 (also look at https://tanzil.net/updates/ for text changes)

- Licence: Creative Commons Attribution 3.0.
- Modification: not allowed. The page says "changing it is not allowed"; the text must be distributed unchanged.
- Verbatim copies may be copied and distributed.
- Use in a website or app is permitted if the source (Tanzil Project) is clearly indicated and a link to tanzil.net is given.
- The copyright notice (Tanzil Quran Text, Copyright (C) 2007-2021 Tanzil Project, License: Creative Commons Attribution 3.0) must appear in verbatim copies, and be reproduced appropriately in derived files that contain a substantial portion of the text.
- Consequences for the app: Quran entries are shown exactly as supplied. The tashkeel toggle does not apply to them. Memorise mode (release 3.0) may only mask words at display time over unchanged text. The Credits screen reproduces the notice and the link.

## Dhikr and hadith text

### rn0x/Adhkar-json

Checked: 2026-10-09
Confidence: confirmed (README read)
Sources: https://github.com/rn0x/Adhkar-json
Re-check by: 2027-10-09

- 132 categories. Category fields: `id`, `category`, `audio`, `filename`, `array`. Entry fields: `id`, `text`, `count`, `audio`, `filename`. No `reference`, no `description`, no grades, no translation, no transliteration.
- Full diacritics in the sample entry.
- Licence: the README says the files come without a usage licence and that you may do what you want with them for free. That is not a legal licence, and the text copies the book by Sa'id bin Ali bin Wahf Al-Qahtani.
- Verdict: cross-check for typos only. Not shipped data.

### rn0x/hisnmuslim_app

Checked: 2026-10-09
Confidence: confirmed (repo page read)
Sources: https://github.com/rn0x/hisnmuslim_app
Re-check by: 2027-10-09

- MIT licence for the code; no separate licence for the data is stated. Archived since July 2023.
- Text comes from the Adhkar-json repo above; audio comes from hisnmuslim.com, recited by Hamad Al-Duraihim.
- Verdict: code licence does not cover the text. Not used.

### adhkar (pub.dev package)

Checked: 2026-10-09
Confidence: likely (search summary)
Sources: https://pub.dev/packages/adhkar
Re-check by: 2027-10-09

- MIT licence for the package code, extracted from Hisn al-Muslim. Same issue: a code licence does not settle the text.
- Verdict: not used.

### fawazahmed0/hadith-api

Checked: 2026-10-09
Confidence: confirmed (repo page and References.md read)
Sources: https://github.com/fawazahmed0/hadith-api, https://github.com/fawazahmed0/hadith-api/blob/1/References.md
Re-check by: 2027-10-09

- Labelled Unlicense. Advertises "multiple grades" and an `/info` endpoint with grades and book references. Editions listed in `editions.json`.
- References.md credits web sources (al-maktaba.org, sunnah.com, iium.edu.my DEED Hadith, hadithbd.com, urdupoint.com, hamariweb.com, al-hadees.com, muhammad.pk, gadingnst/hadith-api, forhuman.free.fr, rahmathpublications.com, normalift.com, zubairalizai.com) and states no terms or permission for any of them. It names editions via al-maktaba.org: Abu Dawud (Albani, Arnaut, Abdul Hamid), An-Nasa'i (Albani, Abu Ghuddah), Tirmidhi (Albani, Shakir, Maarouf), Ibn Majah (Albani, Abd al-Baqi, Arnaut), Malik (Salim Al Hilali).
- The Unlicense does not give rights the original sources never granted.
- Verdict: cross-check only. Not shipped data.

### Sunnah.com

Checked: 2026-10-09
Confidence: unverified (https://sunnah.com/about returned HTTP 403 to our fetch tool)
Sources: search summaries of https://sunnah.com/about and https://sunnah.com/llms.txt
Re-check by: as soon as the owner reads it in a browser

- The site calls itself an open platform and publishes an API and open-source repositories. Its guidance file says it is meant for research, personal study, citation and discovery, that a single hadith is not a standalone legal ruling, and asks reusers to keep grades, collection names and reference numbers where they exist.
- The About page has a section called "Reproduction, Copying, Scraping". We could not read it.
- Mirrors of the About page said grading decisions came from Shaykh al-Albani and Darussalam (Hafiz Zubair Ali Za'i), and that the Arabic text came from al-eman.com and other sources; mirrors disagree and may be old.
- OWNER TASK: read the section in a browser and paste the exact wording here. Until then: read it as a person to verify our entries, do not copy from it in bulk.

### English and other translations of Hisn al-Muslim

Checked: 2026-10-09
Confidence: likely
Sources: https://en.wikipedia.org/wiki/Fortress_of_the_Muslim, https://darussalam.uk/products/fortress-of-the-muslim, https://old.islamhouse.com/39062/en/en/books/[_Hisn_Almuslim_]_Fortress_of_the_Muslim,_Invocations_from_the_Quran_and_Sunnah
Re-check by: 2027-10-09

- The Arabic book was published in Saudi Arabia in 1988 by Sa'id bin Ali bin Wahf Al-Qahtani.
- English editions are sold commercially (Darussalam, 2006 edition, 192 pages). IslamHouse hosts editions for free download, but hosting is not a licence and no reuse terms were found.
- A third-party dataset project states that translations and gradings belong to their authors and publishers (such as Darussalam) and are limited to reference use. That is that project's view, not the publisher's.
- Verdict: no translation is copied. English meanings are written by the owner (release 2.0) or taken from a source whose licence is recorded here first.

### Other leads (never opened)

- Sakina DevGroup (https://github.com/SakinaDevGroup): says every dataset it prepares is released publicly as clean JSON; the tables seen cover Quran and hadith, no Hisn al-Muslim entry. Unverified.
- A "Morning and Evening Adhkar Database" (JSON, CSV, SQL, SQLite): covers only morning and evening adhkar. Unverified.
- A JSON of adhkar and supplications with audio, from Hisn al-Muslim, last updated July 2023, on the GitHub adhkar topic page. Name and licence unknown. Unverified.
- Launchpad "hisn-al-muslim": plans Arabic text, translations, transliteration and audio; no licence or dataset found. Unverified.

## Audio

Checked: 2026-10-09
Confidence: confirmed absence of a usable adhkar licence; likely for the Quran terms
Sources: https://makkahlive.net/en/audio/morning-evening-adhkar, https://qurancomplex.gov.sa/en/?p=3979, https://alquran.cloud/terms-and-conditions, https://www.safinasociety.org/wird
Re-check by: 2027-04-09

- No morning or evening adhkar recitation under a Creative Commons licence was found.
- Makkah Live lists 11 adhkar MP3s (Mishary Al-Afasy, Fares Abbad, Muhammad Jibril, Nasser Al-Qatami); terms limit downloads to personal use. Not usable in an app.
- Adhkar-json audio (Hamad Al-Duraihim): no licence. Not usable.
- Safina Society WIRD page: audio, video and PDF resources for the morning and evening litanies; licence terms were not shown. Unverified.
- King Fahd Glorious Qur'an Printing Complex: offers digital copies of its recitations for free general use in computer apps, broadcasting and websites. Quran only, not the supplications.
- Islamic Network: recitations licensed to them by reciters or their estates for free, non-commercial redistribution; bundling into a commercial product is allowed but copyright stays with the reciters, who may ask for removal. Quran only.
- everyayah.com: asks for a link back to their site for the timing files; one recitation set lists its licence as unknown. Be careful.
- Text-to-speech of dhikr is rejected: mispronunciation risk on religious text.
- Verdict: audio stays parked. Only the Quranic parts of some adhkar (Ayat al-Kursi, the last three surahs) could ever have audio, and only after the exact terms are copied into this file.

## Decision recorded

There is no open, verified Hisn al-Muslim dataset to adopt. Release 0.3 therefore verifies the existing 281 entries by hand against primary sources (Bukhari, Muslim, the Sunan, Ahmad), records book, hadith number and grade for each in a checked-in provenance file, and takes Quran verses from Tanzil verbatim.
