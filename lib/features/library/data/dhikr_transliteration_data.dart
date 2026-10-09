// Latin-letter pronunciation of the azkar library, keyed by DhikrItem.id.
//
// Written by hand (a draft that still wants a reader who knows the recitation
// to check it), not generated. One simple scheme, no accents or special
// letters, so it types and renders the same everywhere:
//
//   '  hamza and ayn (a hamza at the start of a word is left out)
//   th dh kh gh sh  the Arabic letters of the same sound
//   s d t z h  for the heavy and the light forms alike (no dots below)
//   -  joins the article and the little words to the word they sound with
//      (wal-hamdu, fil-ard); a letter after the article is doubled when the
//      recitation assimilates it (ash-shaytan, ar-Rahman)
//   a word ending is written as it is said when the sentence stops there
//
// Entries that are explanation rather than words to say (the virtue texts, the
// narrator chains, the guidance on how to recite) have no transliteration, and
// neither do the two very long funeral supplications: the library shows the
// Arabic alone for them.

const Map<String, String> dhikrTransliterations = <String, String>{
  'd17424625ae':
      'Allahu la ilaha illa huwa, al-Hayyul-Qayyum, la ta\'khudhuhu sinatun wa la nawm, lahu ma fis-samawati wa ma fil-ard, man dhal-ladhi yashfa\'u \'indahu illa bi-idhnih, ya\'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bi-shay\'in min \'ilmihi illa bima sha\', wasi\'a kursiyyuhus-samawati wal-ard, wa la ya\'uduhu hifzuhuma, wa huwal-\'Aliyyul-\'Azim.',
  'd11ccb91029':
      'Qul huwa Allahu ahad, Allahus-samad, lam yalid wa lam yulad, wa lam yakun lahu kufuwan ahad.',
  'dd3516e6e04':
      'Qul a\'udhu bi-rabbil-falaq, min sharri ma khalaq, wa min sharri ghasiqin idha waqab, wa min sharrin-naffathati fil-\'uqad, wa min sharri hasidin idha hasad.',
  'd0f59d20a47':
      'Qul a\'udhu bi-rabbin-nas, malikin-nas, ilahin-nas, min sharril-waswasil-khannas, alladhi yuwaswisu fi suduri-nnas, minal-jinnati wan-nas.',
  'da271c50a00':
      'Asbahna wa asbahal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa \'ala kulli shay\'in qadir. Rabbi as\'aluka khayra ma fi hadhal-yawm wa khayra ma ba\'dah, wa a\'udhu bika min sharri ma fi hadhal-yawm wa sharri ma ba\'dah. Rabbi a\'udhu bika minal-kasali wa su\'il-kibar, rabbi a\'udhu bika min \'adhabin fin-nar wa \'adhabin fil-qabr.',
  'df407984787':
      'Allahumma anta rabbi la ilaha illa ant, khalaqtani wa ana \'abduk, wa ana \'ala \'ahdika wa wa\'dika mastata\'t, a\'udhu bika min sharri ma sana\'t, abu\'u laka bi-ni\'matika \'alayya, wa abu\'u bi-dhanbi fa-ghfir li, fa-innahu la yaghfirudh-dhunuba illa ant.',
  'db5fd486b57':
      'Raditu billahi rabba, wa bil-islami dina, wa bi-Muhammadin salla Allahu \'alayhi wa sallama nabiyya.',
  'd2cb471cf5f':
      'Allahumma inni asbahtu ushhiduk, wa ushhidu hamalata \'arshik, wa mala\'ikatik, wa jami\'a khalqik, annaka antallahu la ilaha illa anta wahdaka la sharika lak, wa anna Muhammadan \'abduka wa rasuluk.',
  'dbf02f3aea6':
      'Allahumma ma asbaha bi min ni\'matin aw bi-ahadin min khalqik, fa-minka wahdaka la sharika lak, fa-lakal-hamdu wa lakash-shukr.',
  'daca3cdf8fa':
      'Hasbiyallahu la ilaha illa huwa, \'alayhi tawakkaltu wa huwa rabbul-\'arshil-\'azim.',
  'd249fa22f07':
      'Bismillahil-ladhi la yadurru ma\'asmihi shay\'un fil-ardi wa la fis-sama\', wa huwas-Sami\'ul-\'Alim.',
  'd136b306ec4':
      'Allahumma bika asbahna wa bika amsayna, wa bika nahya wa bika namut, wa ilaykan-nushur.',
  'daef92cfc92':
      'Asbahna \'ala fitratil-islam, wa \'ala kalimatil-ikhlas, wa \'ala dini nabiyyina Muhammadin salla Allahu \'alayhi wa sallam, wa \'ala millati abina Ibrahima hanifan musliman wa ma kana minal-mushrikin.',
  'db583de41f9':
      'Subhanallahi wa bihamdih, \'adada khalqih, wa rida nafsih, wa zinata \'arshih, wa midada kalimatih.',
  'db637c7d029':
      'Allahumma \'afini fi badani, Allahumma \'afini fi sam\'i, Allahumma \'afini fi basari, la ilaha illa ant.',
  'd80e119656c':
      'Allahumma inni a\'udhu bika minal-kufr, wal-faqr, wa a\'udhu bika min \'adhabil-qabr, la ilaha illa ant.',
  'dd9ec528045':
      'Allahumma inni as\'alukal-\'afwa wal-\'afiyata fid-dunya wal-akhirah, Allahumma inni as\'alukal-\'afwa wal-\'afiyata fi dini wa dunyaya wa ahli wa mali, Allahummastur \'awrati wa amin raw\'ati, Allahummahfazni min bayni yadayya wa min khalfi, wa \'an yamini wa \'an shimali, wa min fawqi, wa a\'udhu bi-\'azamatika an ughtala min tahti.',
  'd339286ade8':
      'Ya Hayyu ya Qayyum, bi-rahmatika astaghith, aslih li sha\'ni kullah, wa la takilni ila nafsi tarfata \'ayn.',
  'd347d5d0427':
      'Asbahna wa asbahal-mulku lillahi rabbil-\'alamin, Allahumma inni as\'aluka khayra hadhal-yawm, fathahu, wa nasrahu, wa nurahu wa barakatah, wa hudah, wa a\'udhu bika min sharri ma fihi wa sharri ma ba\'dah.',
  'de5f8e8b916':
      'Allahumma \'Alimal-ghaybi wash-shahadah, fatiras-samawati wal-ard, rabba kulli shay\'in wa malikah, ashhadu an la ilaha illa ant, a\'udhu bika min sharri nafsi wa min sharrish-shaytani wa shirkih, wa an aqtarifa \'ala nafsi su\'an aw ajurrahu ila muslim.',
  'df95d9ec924': 'A\'udhu bi-kalimatillahit-tammati min sharri ma khalaq.',
  'd904e76671e': 'Allahumma salli wa sallim wa barik \'ala nabiyyina Muhammad.',
  'd4a8d4cf96f':
      'Allahumma inna na\'udhu bika min an nushrika bika shay\'an na\'lamuh, wa nastaghfiruka lima la na\'lamuh.',
  'd90a6f1e9a2':
      'Allahumma inni a\'udhu bika minal-hammi wal-huzn, wa a\'udhu bika minal-\'ajzi wal-kasal, wa a\'udhu bika minal-jubni wal-bukhl, wa a\'udhu bika min ghalabatid-dayn, wa qahrir-rijal.',
  'dc8ae811466':
      'Astaghfirullahal-\'Azimal-ladhi la ilaha illa huwa, al-Hayyul-Qayyum, wa atubu ilayh.',
  'de6d9b05582':
      'Ya rabbi, lakal-hamdu kama yanbaghi li-jalali wajhik, wa li-\'azimi sultanik.',
  'd78cd98f3f9':
      'Allahumma inni as\'aluka \'ilman nafi\'a, wa rizqan tayyiba, wa \'amalan mutaqabbala.',
  'd2a795a5fbd':
      'Allahumma anta rabbi la ilaha illa ant, \'alayka tawakkalt, wa anta rabbul-\'arshil-\'azim, ma sha\'a Allahu kan, wa ma lam yasha\' lam yakun, wa la hawla wa la quwwata illa billahil-\'Aliyyil-\'Azim, a\'lamu annallaha \'ala kulli shay\'in qadir, wa annallaha qad ahata bi-kulli shay\'in \'ilma, Allahumma inni a\'udhu bika min sharri nafsi, wa min sharri kulli dabbatin anta akhidhun bi-nasiyatiha, inna rabbi \'ala siratin mustaqim.',
  'def92708bf6':
      'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa \'ala kulli shay\'in qadir.',
  'df563766dac': 'Subhanallahi wa bihamdih.',
  'd2a30d74945': 'Astaghfirullaha wa atubu ilayh',
  'dc8aef6c2b3':
      'Amanar-rasulu bima unzila ilayhi min rabbihi wal-mu\'minun, kullun amana billahi wa mala\'ikatihi wa kutubihi wa rusulih, la nufarriqu bayna ahadin min rusulih, wa qalu sami\'na wa ata\'na, ghufranaka rabbana wa ilaykal-masir. La yukallifullahu nafsan illa wus\'aha, laha ma kasabat wa \'alayha maktasabat, rabbana la tu\'akhidhna in nasina aw akhta\'na, rabbana wa la tahmil \'alayna isran kama hamaltahu \'alal-ladhina min qablina, rabbana wa la tuhammilna ma la taqata lana bih, wa\'fu \'anna, waghfir lana, warhamna, anta mawlana fansurna \'alal-qawmil-kafirin.',
  'd9e0b3a595c':
      'Amsayna wa amsal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa \'ala kulli shay\'in qadir. Rabbi as\'aluka khayra ma fi hadhihil-laylah wa khayra ma ba\'daha, wa a\'udhu bika min sharri ma fi hadhihil-laylah wa sharri ma ba\'daha. Rabbi a\'udhu bika minal-kasali wa su\'il-kibar, rabbi a\'udhu bika min \'adhabin fin-nar wa \'adhabin fil-qabr.',
  'deb8574e997':
      'Allahumma inni amsaytu ushhiduk, wa ushhidu hamalata \'arshik, wa mala\'ikatik, wa jami\'a khalqik, annaka antallahu la ilaha illa anta wahdaka la sharika lak, wa anna Muhammadan \'abduka wa rasuluk.',
  'd97b25374ff':
      'Allahumma ma amsa bi min ni\'matin aw bi-ahadin min khalqik, fa-minka wahdaka la sharika lak, fa-lakal-hamdu wa lakash-shukr.',
  'd15c7901400':
      'Allahumma bika amsayna wa bika asbahna, wa bika nahya wa bika namut, wa ilaykal-masir.',
  'df302293fb1':
      'Amsayna \'ala fitratil-islam, wa \'ala kalimatil-ikhlas, wa \'ala dini nabiyyina Muhammadin salla Allahu \'alayhi wa sallam, wa \'ala millati abina Ibrahima hanifan musliman wa ma kana minal-mushrikin.',
  'd6b9fc504a4':
      'Amsayna wa amsal-mulku lillahi rabbil-\'alamin, Allahumma inni as\'aluka khayra hadhihil-laylah fathaha wa nasraha, wa nuraha wa barakataha, wa hudaha, wa a\'udhu bika min sharri ma fiha wa sharri ma ba\'daha.',
  'd22de4e6344':
      'Astaghfirullah, astaghfirullah, astaghfirullah. Allahumma antas-salam, wa minkas-salam, tabarakta ya dhal-jalali wal-ikram.',
  'd7d14ca1e1b':
      'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa \'ala kulli shay\'in qadir, Allahumma la mani\'a lima a\'tayt, wa la mu\'tiya lima mana\'t, wa la yanfa\'u dhal-jaddi minkal-jadd.',
  'ded9c2c6ffb':
      'La ilaha illallah, wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa \'ala kulli shay\'in qadir, la hawla wa la quwwata illa billah, la ilaha illallah, wa la na\'budu illa iyyah, lahun-ni\'matu wa lahul-fadl wa lahuth-thana\'ul-hasan, la ilaha illallahu mukhlisina lahud-dina wa law karihal-kafirun.',
  'd87b68ccd23': 'Subhanallah, wal-hamdu lillah, wallahu akbar.',
  'd3ce38bc45b':
      'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa \'ala kulli shay\'in qadir.',
  'd0693978714':
      'Qul huwa Allahu ahad, Allahus-samad, lam yalid wa lam yulad, wa lam yakun lahu kufuwan ahad. Bismillahir-Rahmanir-Rahim. Qul a\'udhu bi-rabbil-falaq, min sharri ma khalaq, wa min sharri ghasiqin idha waqab, wa min sharrin-naffathati fil-\'uqad, wa min sharri hasidin idha hasad. Bismillahir-Rahmanir-Rahim. Qul a\'udhu bi-rabbin-nas, malikin-nas, ilahin-nas, min sharril-waswasil-khannas, alladhi yuwaswisu fi suduri-nnas, minal-jinnati wan-nas.',
  'da8eb2b234d':
      'Allahu la ilaha illa huwa, al-Hayyul-Qayyum, la ta\'khudhuhu sinatun wa la nawm, lahu ma fis-samawati wa ma fil-ard, man dhal-ladhi yashfa\'u \'indahu illa bi-idhnih, ya\'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bi-shay\'in min \'ilmihi illa bima sha\', wasi\'a kursiyyuhus-samawati wal-ard, wa la ya\'uduhu hifzuhuma, wa huwal-\'Aliyyul-\'Azim.',
  'dfb9d1ae639':
      'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, yuhyi wa yumit wa huwa \'ala kulli shay\'in qadir.',
  'dcee0129f51': 'Allahumma ajirni minan-nar.',
  'dc5786d0f82':
      'Allahumma a\'inni \'ala dhikrika wa shukrika wa husni \'ibadatik.',
  'd27cde320dd': 'Subhanallah',
  'd11f8222df4': 'Subhanallah wal-hamdu lillah',
  'de4bf2c3c9a': 'Subhanallahil-\'Azim wa bihamdih',
  'dc9b254316b': 'Subhanallahi wa bihamdih, subhanallahil-\'Azim',
  'd2652166f09': 'La hawla wa la quwwata illa billah',
  'd74bf8e76b3': 'Alhamdu lillahi rabbil-\'alamin',
  'd53076996a2': 'Allahumma salli wa sallim wa barik \'ala sayyidina Muhammad',
  'd516bd15e8a': 'Astaghfirullah',
  'dc19bd8a849':
      'Subhanallah, wal-hamdu lillah, wa la ilaha illallah, wallahu akbar',
  'ded5167039c': 'La ilaha illallah',
  'd62f88bcdce': 'Allahu akbar',
  'd2b467f551f':
      'Subhanallah, wal-hamdu lillah, wa la ilaha illallah, wallahu akbar, Allahummaghfir li, Allahummarhamni, Allahummarzuqni.',
  'd71f1700dd4': 'Alhamdu lillahi hamdan kathiran tayyiban mubarakan fih.',
  'db53338fa27':
      'Allahu akbaru kabira, wal-hamdu lillahi kathira, wa subhanallahi bukratan wa asila.',
  'd80f70ecdf7':
      'Allahumma salli \'ala Muhammadin wa \'ala ali Muhammad kama sallayta \'ala Ibrahima, wa \'ala ali Ibrahima innaka Hamidun Majid, Allahumma barik \'ala Muhammadin wa \'ala ali Muhammad kama barakta \'ala Ibrahima wa \'ala ali Ibrahima innaka Hamidun Majid.',
  'dbc7011dbf4':
      'Bismika rabbi wada\'tu janbi, wa bika arfa\'uh, fa-in amsakta nafsi farhamha, wa in arsaltaha fahfazha bima tahfazu bihi \'ibadakas-salihin.',
  'd6a5129e015':
      'Allahumma innaka khalaqta nafsi wa anta tawaffaha, laka mamatuha wa mahyaha, in ahyaytaha fahfazha, wa in amattaha faghfir laha. Allahumma inni as\'alukal-\'afiyah.',
  'd6cb08a6d7d': 'Allahumma qini \'adhabaka yawma tab\'athu \'ibadak.',
  'd5962298b6d': 'Bismikallahumma amutu wa ahya.',
  'd0104da00ca':
      'Alhamdu lillahil-ladhi at\'amana wa saqana, wa kafana, wa awana, fakam mimman la kafiya lahu wa la mu\'wiy.',
  'd90a8413555':
      'Allahumma aslamtu nafsi ilayk, wa fawwadtu amri ilayk, wa wajjahtu wajhi ilayk, wa alja\'tu zahri ilayk, raghbatan wa rahbatan ilayk, la malja\'a wa la manja minka illa ilayk, amantu bi-kitabikal-ladhi anzalt, wa bi-nabiyyikal-ladhi arsalt.',
  'd758bdb5bd6': 'Subhanallah',
  'd60e2f10bbd': 'Alhamdu lillah',
  'd073ef32955': 'Allahu akbar',
  'd0f13b405ef':
      'Yajma\'u kaffayhi thumma yanfuthu fihima wa yaqra\'u fihima: {Qul huwa Allahu ahad} wa {Qul a\'udhu bi-rabbil-falaq} wa {Qul a\'udhu bi-rabbin-nas}, thumma yamsahu bihima ma istata\'a minal-jasad, yabda\'u bihima \'ala ra\'sihi wa wajhihi wa ma aqbala min jasadih.',
  'd5069a75860':
      'Amanar-rasulu bima unzila ilayhi min rabbihi wal-mu\'minun, kullun amana billahi wa mala\'ikatihi wa kutubihi wa rusulih, la nufarriqu bayna ahadin min rusulih, wa qalu sami\'na wa ata\'na, ghufranaka rabbana wa ilaykal-masir. La yukallifullahu nafsan illa wus\'aha, laha ma kasabat wa \'alayha maktasabat, rabbana la tu\'akhidhna in nasina aw akhta\'na, rabbana wa la tahmil \'alayna isran kama hamaltahu \'alal-ladhina min qablina, rabbana wa la tuhammilna ma la taqata lana bih, wa\'fu \'anna, waghfir lana, warhamna, anta mawlana fansurna \'alal-qawmil-kafirin.',
  'd53a989d5b8':
      'Allahu la ilaha illa huwa, al-Hayyul-Qayyum, la ta\'khudhuhu sinatun wa la nawm, lahu ma fis-samawati wa ma fil-ard, man dhal-ladhi yashfa\'u \'indahu illa bi-idhnih, ya\'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bi-shay\'in min \'ilmihi illa bima sha\', wasi\'a kursiyyuhus-samawati wal-ard, wa la ya\'uduhu hifzuhuma, wa huwal-\'Aliyyul-\'Azim.',
  'd2e72559401':
      'Alhamdu lillahil-ladhi ahyana ba\'da ma amatana wa ilayhin-nushur.',
  'd2b475178db':
      'Alhamdu lillahil-ladhi \'afani fi jasadi wa radda \'alayya ruhi wa adhina li bidhikrih.',
  'd1321d33fed':
      'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa huwa \'ala kulli shay\'in qadir, subhanallah, wal-hamdu lillah, wa la ilaha illallahu wallahu akbar, wa la hawla wa la quwwata illa billahil-\'Aliyyil-\'Azim. Rabbighfir li.',
  'd99e89a389b':
      'Allahumma ba\'id bayni wa bayna khatayaya kama ba\'adta baynal-mashriqi wal-maghrib, Allahumma naqqini min khatayaya kama yunaqqath-thawbul-abyadu minad-danas, Allahummaghsilni min khatayaya bith-thalji wal-ma\'i wal-barad. Subhanaka Allahumma wa bihamdik, wa tabarakasmuk, wa ta\'ala jadduk, wa la ilaha ghayruk. Alhamdu lillahi hamdan kathiran tayyiban mubarakan fih. Allahu akbaru kabira, wal-hamdu lillahi kathira, wa subhanallahi bukratan wa asila. A\'udhu billahi minash-shaytan: min nafkhihi, wa nafthihi, wa hamzih. Allahumma rabba Jibrila, wa Mika\'ila, wa Israfil, fatiras-samawati wal-ard, \'Alimal-ghaybi wash-shahadah, anta tahkumu bayna \'ibadika fima kanu fihi yakhtalifun, ihdini lima ikhtulifa fihi minal-haqqi bi-idhnik, innaka tahdi man tasha\'u ila siratin mustaqim. Wajjahtu wajhiya lilladhi fataras-samawati wal-arda hanifan wa ma ana minal-mushrikin, inna salati, wa nusuki, wa mahyaya, wa mamati lillahi rabbil-\'alamin, la sharika lah, wa bidhalika umirtu wa ana minal-muslimin. Allahumma antal-maliku la ilaha illa ant, anta rabbi wa ana \'abduk, zalamtu nafsi wa\'taraftu bidhanbi faghfir li dhunubi jami\'an, innahu la yaghfirudh-dhunuba illa ant. Wahdini li-ahsanil-akhlaq, la yahdi li-ahsaniha illa ant, wasrif \'anni sayyi\'aha, la yasrifu \'anni sayyi\'aha illa ant. Labbayka wa sa\'dayk, wal-khayru kulluhu bi-yadayk, wash-sharru laysa ilayk, ana bika wa ilayk, tabarakta wa ta\'alayt, astaghfiruka wa atubu ilayk.',
  'd3626bab699':
      'Subhana rabbiyal-\'Azim. Thalatha marrat aw akthar. Subhana rabbiyal-\'Azimi wa bihamdih. Thalatha marrat. Subhanakallahumma rabbana wa bihamdik, Allahummaghfir li. Subbuhun, quddus, rabbul-mala\'ikati war-ruh. Subhana dhil-jabaruti wal-malakuti wal-kibriya\'i wal-\'azamah. Allahumma laka raka\'tu, wa bika amantu, wa laka aslamtu, khasha\'a laka sam\'i wa basari, wa mukhkhi wa \'azmi wa \'asabi.',
  'd4289323fa6':
      'Sami\'allahu liman hamidah. Rabbana wa lakal-hamd, hamdan kathiran tayyiban mubarakan fih. Allahumma laka raka\'tu, wa bika amantu, wa laka aslamtu, khasha\'a laka sam\'i, wa basari, wa mukhkhi, wa \'azmi, wa \'asabi, wa mastaqallat bihi qadami lillahi rabbil-\'alamin. Allahumma rabbana lakal-hamdu mil\'as-samawati wa mil\'al-ard, wa ma baynahuma, wa mil\'a ma shi\'ta min shay\'in ba\'d, ahlath-thana\'i wal-majd, ahaqqu ma qalal-\'abd, wa kulluna laka \'abd, Allahumma la mani\'a lima a\'tayt, wa la mu\'tiya lima mana\'t, wa la yanfa\'u dhal-jaddi minkal-jadd. Allahumma lakal-hamdu mil\'as-sama\', wa mil\'al-ard, wa mil\'a ma shi\'ta min shay\'in ba\'d, Allahumma tahhirni bith-thalji wal-barad, wal-ma\'il-barid, Allahumma tahhirni minadh-dhunubi wal-khataya, kama yunaqqath-thawbul-abyadu minal-wasakh.',
  'da571489569':
      'Subhana rabbiyal-A\'la. Thalatha marrat aw akthar. Subhana rabbiyal-A\'la wa bihamdih. Thalatha marrat. Subbuhun quddus rabbul-mala\'ikati war-ruh. Subhanakallahumma rabbana wa bihamdik, Allahummaghfir li. Subhana dhil-jabaruti wal-malakuti wal-kibriya\'i wal-\'azamah. Allahummaghfir li dhanbi kullah, diqqahu wa jillah, wa awwalahu wa akhirah, wa \'alaniyatahu wa sirrah. Allahumma laka sajadtu wa bika amantu, wa laka aslamt, sajada wajhi lilladhi khalaqah, wa sawwarah, wa shaqqa sam\'ahu wa basarah, tabarakallahu ahsanul-khaliqin. Allahumma inni a\'udhu bi-ridaka min sakhatik, wa bi-mu\'afatika min \'uqubatik, wa a\'udhu bika minka, la uhsi thana\'an \'alayk, anta kama athnayta \'ala nafsik. Rabbi a\'ti nafsi taqwaha zakkiha anta khayru man zakkaha anta waliyyuha wa mawlaha. Allahummaj\'al fi qalbi nura, waj\'al fi sam\'i nura, waj\'al fi basari nura, waj\'al min tahti nura, waj\'al min fawqi nura, wa \'an yamini nura, wa \'an yasari nura, waj\'al amami nura, waj\'al khalfi nura, wa a\'zim li nura.',
  'df38c25f3dc':
      'Rabbi rabbighfir li, rabbighfir li. Allahummaghfir li, warhamni, wahdini, wajburni, wa \'afini, warzuqni, warfa\'ni.',
  'de08bf58b3d':
      'Sajada wajhi lilladhi khalaqah, wa shaqqa sam\'ahu wa basarah, bihawlihi wa quwwatih, fatabarakallahu ahsanul-khaliqin. Allahummaktub li biha \'indaka ajra, wa da\' \'anni biha wizra, waj\'alha li \'indaka dhukhra, wa taqabbalha minni kama taqabbaltaha min \'abdika Dawud.',
  'dda57a9329a':
      'At-tahiyyatu lillahi was-salawatu wat-tayyibat, as-salamu \'alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh, as-salamu \'alayna wa \'ala \'ibadillahis-salihin, ashhadu an la ilaha illallah, wa ashhadu anna Muhammadan \'abduhu wa rasuluh.',
  'd4af7fd2ace':
      'At-tahiyyatu lillahi was-salawatu wat-tayyibat, as-salamu \'alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh, as-salamu \'alayna wa \'ala \'ibadillahis-salihin, ashhadu an la ilaha illallah, wa ashhadu anna Muhammadan \'abduhu wa rasuluh. Allahumma salli \'ala Muhammadin wa \'ala ali Muhammad kama sallayta \'ala Ibrahima wa \'ala ali Ibrahima innaka Hamidun Majid, Allahumma barik \'ala Muhammadin wa \'ala ali Muhammad kama barakta \'ala Ibrahima wa \'ala ali Ibrahima innaka Hamidun Majid.',
  'db5a8f5c46a':
      'Allahumma inni a\'udhu bika min \'adhabil-qabr, wa min \'adhabi jahannam, wa min fitnatil-mahya wal-mamat, wa min sharri fitnatil-Masihid-Dajjal. Allahumma inni a\'udhu bika min \'adhabil-qabr. Wa a\'udhu bika min fitnatil-Masihid-Dajjal. Wa a\'udhu bika min fitnatil-mahya wal-mamat. Allahumma inni a\'udhu bika minal-ma\'thami wal-maghram. Allahumma inni zalamtu nafsi zulman kathira, wa la yaghfirudh-dhunuba illa ant. Faghfir li maghfiratan min \'indika warhamni, innaka antal-Ghafurur-Rahim. Allahummaghfir li ma qaddamtu wa ma akhkhart. Wa ma asrartu wa ma a\'lant. Wa ma asraft. Wa ma anta a\'lamu bihi minni. Antal-Muqaddimu wa antal-Mu\'akhkhir. La ilaha illa ant. Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar. Allahumma inni as\'alukal-jannata wa a\'udhu bika minan-nar. Allahumma inni as\'aluka ya Allahu bi-annakal-Wahidul-Ahadus-Samadul-ladhi lam yalid wa lam yulad, wa lam yakun lahu kufuwan ahad, an taghfira li dhunubi innaka antal-Ghafurur-Rahim. Allahumma hasibni hisaban yasira. Allahumma inni as\'aluka bi-anna lakal-hamd, la ilaha illa anta wahdaka la sharika lak, al-Mannan, ya Badi\'as-samawati wal-ard, ya Dhal-jalali wal-ikram, ya Hayyu ya Qayyum inni as\'alukal-jannata wa a\'udhu bika minan-nar. Allahumma inni as\'aluka bi-anni ashhadu annaka antallahu la ilaha illa antal-Ahadus-Samadul-ladhi lam yalid wa lam yulad wa lam yakun lahu kufuwan ahad. Allahumma bi-\'ilmikal-ghayba wa qudratika \'alal-khalqi ahyini ma \'alimtal-hayata khayran li, wa tawaffani idha \'alimtal-wafata khayran li, Allahumma inni as\'aluka khashyataka fil-ghaybi wash-shahadah, wa as\'aluka kalimatal-haqqi fir-rida wal-ghadab, wa as\'alukal-qasda fil-ghina wal-faqr, wa as\'aluka na\'iman la yanfad, wa as\'aluka qurrata \'aynin la tanqati\', wa as\'alukar-rida ba\'dal-qada\', wa as\'aluka bardal-\'aysh ba\'dal-mawt, wa as\'aluka ladhdhatan-nazari ila wajhik, wash-shawqa ila liqa\'ika fi ghayri darra\'a mudirra, wa la fitnatin mudilla, Allahumma zayyinna bi-zinatil-iman, waj\'alna hudatan muhtadin.',
  'd025a7a59b2':
      'Allahummahdini fiman hadayt, wa \'afini fiman \'afayt, wa tawallani fiman tawallayt, wa barik li fima a\'tayt, wa qini sharra ma qadayt, fa-innaka taqdi wa la yuqda \'alayk, innahu la yadhillu man walayt, tabarakta rabbana wa ta\'alayt. Allahumma inni a\'udhu bi-ridaka min sakhatik wa a\'udhu bi-mu\'afatika min \'uqubatik, wa a\'udhu bika minka la uhsi thana\'an \'alayk, anta kama athnayta \'ala nafsik. Allahumma iyyaka na\'bud, wa laka nusalli wa nasjud, wa ilayka nas\'a wa nahfid, narju rahmataka, wa nakhsha \'adhabak, inna \'adhabaka bil-kafirina mulhaq, Allahumma inna nasta\'inuk, wa nastaghfiruk, wa nuthni \'alaykal-khayr, wa la nakfuruk, wa nu\'minu bik, wa nakhda\'u lak, wa nakhla\'u man yakfuruk. Allahumma taqabbal minna innaka antas-Sami\'ul-\'Alim wa tub \'alayna innaka antat-Tawwabur-Rahim. Wa salla Allahu \'ala sayyidina Muhammadin wa \'ala alihi wa sahbihi wa sallam.',
  'd8c553bc48d':
      'Rabbana la tuzigh qulubana ba\'da idh hadaytana wa hab lana min ladunka rahmah, innaka antal-Wahhab, wa aslih Allahumma ahwalana fil-umuri kulliha, wa ballighna bima yurdika amalana, wakhtim Allahumma bis-salihati a\'malana wa bis-sa\'adati ajalana, wa tawaffana ya rabbi wa anta radin \'anna. Allahummaj\'al jam\'ana hadha jam\'an mubarakan marhuma, wa tafarruqana min kulli sharrin ma\'suma. Rabbana la tada\' lana dhanban illa ghafartah, wa la hamman illa farrajtah, wa la maridan illa shafaytah, wa la mayyitan illa rahimtah, wa la taliban amran min umuril-khayri illa sahhaltahu lahu wa yassartah. Allahumma wahhid kalimatal-muslimin, wajma\' shamlahum, waj\'alhum yadan wahidatan \'ala man siwahum, wansur Allahummal-muslimin, wakhdhulil-kafaratal-mushrikin a\'daka a\'dad-din. Allahumma inna nas\'aluka li-wulati umurinas-salaha was-sadad. Allahumma kun lahum \'awna, wa khudh bi-aydihim ilal-haqqi was-sawabi was-sadadi war-rashad, wa waffiqhum lil-\'amali lima fihi ridak, wa ma fihi salihul-\'ibadi wal-bilad. Allahumma inna nas\'aluka li-baladina hadha, Allahummaj\'alhu baladan aminan, warzuqhu min kullil-khayrat, wa jannibhul-fitana ma zahara minha wa ma batan, wa allif Allahumma ma bayna qulubina wa bayna qulubi abna\'i hadhal-watan, waj\'alhum Allahumma ya rabbana bismika mutahabbin wa \'ala nusrati dinika muta\'awinin. Allahumma inna nasta\'idhu bika min sharri ma khalaqt, wa min kulli \'ayni hasid, wa nas\'aluka Allahumma at-tawfiqa was-sadada wal-hidayata war-rashada wa husnal-\'uqba wa husnal-mi\'ad. Allahumma asbigh \'alayna ni\'mataka wa \'ala jami\'il-muslimin, wamla\' Allahumma qulubana bil-imani wal-qana\'ah, walzam jawarihana al-\'ibadata wat-ta\'ah, waghfir Allahumma lana wa li-walidayna wa li-ikhwanina wa ashyakhina wa li-jami\'i man sabaqana bil-iman, wa atina min ladunka rahmah, wa hayyi\' lana min amrina rashada, wa atina rabbana fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar. Subhana rabbika rabbil-\'izzati \'amma yasifun, wa salamun \'alal-mursalin, wal-hamdu lillahi rabbil-\'alamin.',
  'd10d55aa03d':
      'Allahumma ya bari\'al-bariyyat, wa ghafiral-khati\'at, wa \'alimal-khafiyyat, al-muttali\'a \'alad-damairi wan-niyyat, ya man ahata bi-kulli shay\'in \'ilma, wa wasi\'a kulla shay\'in rahmah, wa qahara kulla makhluqin \'izzatan wa hukma, ighfir li dhunubi, wastur \'uyubi, wa tajawaz \'an sayyi\'ati innaka antal-Ghafurur-Rahim. Allahumma ya sami\'ad-da\'awat, ya muqilal-\'atharat, ya qadiyal-hajat, ya kashifal-kurubat, ya rafi\'ad-darajat, wa ya ghafiraz-zallat, ighfir lil-muslimina wal-muslimat, wal-mu\'minina wal-mu\'minat, al-ahya\'i minhum wal-amwat, innaka sami\'un qaribun mujibud-da\'awat. Allahumma inni as\'aluka bismikal-a\'zam, alladhi idha du\'ita bihi ajabt, wa idha su\'ilta bihi a\'tayt, as\'aluka bi-anni ashhadu annaka antallahu la ilaha illa ant, al-Ahadus-Samad, alladhi lam yalid, wa lam yulad, wa lam yakun lahu kufuwan ahad; an taghfira li dhunubi, innaka antal-Ghafurur-Rahim. Allahumma innaka \'afuwwun karimun tuhibbul-\'afwa fa\'fu \'anni. Allahumma rabbi ighfir li wa li-walidayya wa liman dakhala bayti mu\'minan wa lil-mu\'minina wal-mu\'minat.',
  'da4f1326529':
      'Allahummaghfir li khati\'ati wa jahli, wa israfi fi amri, wa ma anta a\'lamu bihi minni, Allahummaghfir li hazli wa jiddi, wa khata\'i wa \'amdi, wa kullu dhalika \'indi. Allahumma rabbi inni zalamtu nafsi faghfir li. Allahumma anta rabbi la ilaha illa ant khalaqtani wa ana \'abduk, wa ana \'ala \'ahdika wa wa\'dika mastata\'t, a\'udhu bika min sharri ma sana\'t abu\'u laka bi-ni\'matika \'alayya wa abu\'u laka bi-dhanbi faghfir li fa-innahu la yaghfirudh-dhunuba illa ant. Allahummaghfir li, warhamni wahdini, wa \'afini warzuqni, wajburni, warfa\'ni. Allahumma ya man la tadurruhudh-dhunub, wa la tanqusuhul-maghfirah, ighfir lana ma la yadurruk, wa hab lana ma la yanqusuk.',
  'd8c1c002b1f':
      'Allahummaghfir li dhanbi kullah, diqqahu wa jillah, wa awwalahu wa akhirah, wa \'alaniyatahu wa sirrah. Allahumma inna dhunubi \'izamun wa hiya sighar fi janbi \'afwika ya karim, faghfirha li. Allahummaghfir li dhanbi, wa wassi\' li fi dari, wa barik li fi rizqi. Allahumma rabbana la tu\'akhidhna in nasina aw akhta\'na, rabbana wa la tahmil \'alayna isran kama hamaltahu \'alal-ladhina min qablina, rabbana wa la tuhammilna ma la taqata lana bih, wa\'fu \'anna waghfir lana warhamna anta mawlana fansurna \'alal-qawmil-kafirin. Allahumma inna qad ata\'naka fi ahabbil-ashya\'i ilayka an tuta\'a fih, al-imani bik, wal-iqrari bik, wa lam na\'sika fi abghadil-ashya\'i an tu\'sa fih; al-kufri wal-juhudi bik, Allahumma faghfir lana ma baynahuma.',
  'd430c09f81d':
      'Allahummaghfir li ma qaddamtu wa ma akhkhart, wa ma a\'lantu wa ma asrart, wa ma anta a\'lamu bihi minni, antal-Muqaddimu wa antal-Mu\'akhkhiru la ilaha illa ant. Allahumma rabbanaghfir lana dhunubana wa kaffir \'anna sayyi\'atina wa tawaffana ma\'al-abrar. Allahumma rabbanaghfir lana wa li-ikhwaninal-ladhina sabaquna bil-iman, rabbana wasi\'ta kulla shay\'in rahmatan wa \'ilma faghfir lilladhina tabu wattaba\'u sabilaka wa qihim \'adhabal-jahim. Allahumma aqil \'atharatina, waghfir zallatina, wa kaffir \'anna sayyi\'atina, wa tawaffana ma\'al-abrar. Allahumma ba\'id bayni wa bayna khatayaya kama ba\'adta baynal-mashriqi wal-maghrib, Allahummaghsilni min khatayaya bil-ma\'i wath-thalji wal-barad, Allahumma naqqini minal-khataya kama yunaqqath-thawbul-abyadu minad-danas.',
  'd9227484b53':
      'Allahumma inni zalamtu nafsi zulman kathira, wa la yaghfirudh-dhunuba illa ant. Faghfir li maghfiratan min \'indik, warhamni innaka antal-Ghafurur-Rahim. Allahumma inni as\'aluka ya Allahu bi-annakal-Wahidul-Ahad, as-Samad, alladhi lam yalid wa lam yulad wa lam yakun lahu kufuwan ahad, an taghfira li dhunubi, innaka antal-Ghafurur-Rahim. Allahumma ilahi: hujjati hajati, wa \'uddati faqati, farhamni. Allahumma ilahi: kayfa amtani\'u bidh-dhanbi minad-du\'a\', wa la araka tamna\'u ma\'adh-dhanbi minal-\'ata\', fa-in ghafarta fa-khayru rahimin ant, wa in \'adhdhabta fa-ghayru zalimin ant. Allahumma ilahi: as\'aluka tadhallulan fa-a\'tini tafaddula.',
  'ddf6a8a5dab':
      'Allahumma ya man \'alal-\'arshis-tawa, ya man khalaqa fasawwa wa qaddara fahada, wa a\'ta kulla shay\'in khalqahu thumma hada, ya man adhaka wa abka, wa amata wa ahya, wa as\'ada wa ashqa, wa awjada wa abla, wa rafa\'a wa khafad, wa a\'azza wa adhall, wa a\'ta wa mana\', wa rafa\'a wa wada\'. Allahumma ya man shaqqal-bihar, wa ajral-anhar, wa kawwaran-nahara \'alal-layli wal-layla \'alan-nahar, ya man hada min dalalah, wa anqadha min jahalah, wa anaral-absar, wa ahyad-damairi wal-afkar. Allahummahdina fiman hadayt, wa \'afina fiman \'afayt, wa tawallana fiman tawallayt. Allahummahdinas-siratal-mustaqim, siratal-ladhina an\'amta \'alayhim minan-nabiyyina was-siddiqina wash-shuhada\'i was-salihin. Allahumma waffiqna li-hudak, waj\'al \'amalana fi ridak.',
  'd9718776648':
      'Allahumma arinal-haqqa haqqan warzuqnattiba\'ah, wa arinal-batila batilan warzuqnajtinabah. Allahumma ati nafsi taqwaha, wa zakkiha anta khayru man zakkaha, anta waliyyuha wa mawlaha. Allahumma rabbana atmim lana nurana waghfir lana innaka \'ala kulli shay\'in qadir. Allahumma habbib ilaynal-imana wa zayyinhu fi qulubina, wa karrih ilaynal-kufra wal-fusuqa wal-\'isyan, waj\'alna minar-rashidin. Allahumma musarrifal-qulub, sarrif qulubana \'ala ta\'atik.',
  'd4fa1b42d15':
      'Allahumma khudh bi-nawasina lil-birri wat-taqwa, wa lima tuhibbu minal-\'amali wa tarda. Allahumma rabba Jibra\'ila wa Mika\'ila, wa Israfil, fatiras-samawati wal-ard, \'Alimal-ghaybi wash-shahadah, anta tahkumu bayna \'ibadika fima kanu fihi yakhtalifun, ihdina lima ikhtulifa fihi minal-haqqi bi-idhnik, innaka tahdi man tasha\'u ila siratin mustaqim. Allahumma inni \'abduka ibnu \'abdika ibnu amatik, nasiyati biyadik, madin fi hukmik, \'adlun fi qada\'ik, as\'aluka bi-kulli ismin huwa lak, sammayta bihi nafsak, aw anzaltahu fi kitabik, aw \'allamtahu ahadan min khalqik, aw ista\'tharta bihi fi \'ilmil-ghaybi \'indak, an taj\'alal-qur\'ana rabi\'a qalbi, wa nura sadri, wa jala\'a huzni, wa dhahaba hammi. Allahummaj\'al fi qalbi nura, wa fi sam\'i nura, wa fi basari nura, wa \'an yamini nura, wa \'an shimali nura, wa min bayni yadayya nura, wa min khalfi nura, wa min fawqi nura, wa min tahti nura, waj\'al li nura, wa a\'zim li nura. Allahumma aghnini bil-\'ilm, wa zayyini bil-hilm, wa akrimni bit-taqwa, wa jammilni bil-\'afiyah.',
  'deff399fad5':
      'Allahumma inni as\'aluka \'ilmal-khaifina mink, wa khawfal-\'alimina bik, wa yaqinal-mutawakkilina \'alayk, wa tawakkulal-muqinina bik, wa inabatal-mukhbitina ilayk, wa ikhbatal-munibina ilayk, wa shukras-sabirina lak, wa sabrash-shakirina lak, wa lihaqan bil-ahya\'il-marzuqina \'indak. Allahummahdini wa saddidni, Allahumma inni as\'alukal-huda was-sadad. Allahumma alhimni rushdi, wa a\'idhni min sharri nafsi. Allahummanfa\'ni bima \'allamtani, wa \'allimni ma yanfa\'uni, wa zidni \'ilma. Allahumma inni as\'aluka \'ilman nafi\'a, wa a\'udhu bika min \'ilmin la yanfa\'.',
  'ddd874fd6d5':
      'Allahumma thabbitni waj\'alni hadiyan mahdiyya. Allahumma laka aslamt, wa bika amant, wa \'alayka tawakkalt, wa ilayka anabt, wa bika khasamt, a\'udhu bi-\'izzatika, la ilaha illa ant, an tudillani, antal-Hayyul-ladhi la yamut, wal-jinnu wal-insu yamutun. Allahummahdini li-ahsanil-akhlaq la yahdi li-ahsaniha illa ant, wasrif \'anni sayyi\'aha la yasrifu \'anni sayyi\'aha illa ant. Allahumma kama ahsanta khalqi fa-ahsin khuluqi. Allahumma faliqal-habbi wan-nawa, wa mukhrijal-hayyi minal-mayyiti wa mukhrijal-mayyiti minal-hayy, faliqal-isbah, wa ja\'ilal-layli sakana, wash-shamsa wal-qamara husbana, ya man ja\'ala lanan-nujuma linahtadiya biha fi zulumatil-barri wal-bahr.',
  'd33eabc3e86':
      'Allahumma jallat qudratuk, wa ta\'alat hikmatuk, wa tabarakasmuk, wa ta\'ala jadduk, wa la ilaha ghayruk. Allahumma inni as\'aluka bi-anna lakal-hamd, la ilaha illa ant, al-Mannan, Badi\'us-samawati wal-ard, Dhul-jalali wal-ikram, ya Hayyu ya Qayyum. Allahummarzuqna rizqan yazidunna laka shukra, wa ilayka faqatan wa faqra, wa bika \'amman siwaka ghina. Allahummaj\'al awsa\'a rizqika \'alayya \'inda kibari sinni, wanqita\'i \'umri. Allahumma inni as\'aluka min fadlika wa rahmatik, fa-innahu la yamlikuha illa ant.',
  'db3a430b51a':
      'Allahumma rabbi la tadharni fardan wa anta khayrul-warithin. Allahumma rabbi hab li minas-salihin. Allahumma qanni\'ni bima razaqtani, wa barik li fih, wakhlif \'alayya kulla gha\'ibatin li minka bi-khayr. Allahumma rabbana hab lana min azwajina wa dhurriyyatina qurrata a\'yunin waj\'alna lil-muttaqina imama. Allahumma ya man tusabbihu lahus-samawatu bi-nujumiha wa abrajiha, wal-ardu bi-suhuliha wa fijajiha, wal-bihar bi-ahya\'iha wa amwajiha, wal-jibalu bi-qimamiha wa awtadiha, wal-ashjaru bi-furu\'iha wa thimariha, was-siba\'u fi falawatiha, wat-tayru fi wukunatiha, ya man tusabbihu lahudh-dharratu \'ala sighariha, wal-majarratu \'ala kibariha, ya man tusabbihu lahus-samawatus-sab\'u wal-ardu wa man fihinn, wa in min shay\'in illa yusabbihu bihamdih.',
  'd09c3c7bdcf':
      'Allahumma ya man khalaqal-arda was-samawatil-\'ula, ya rahmanan \'alal-\'arshis-tawa, ya man lahu ma fis-samawati wa ma fil-ardi wa ma baynahuma wa ma tahtath-thara, ya man ya\'lamus-sirra wa akhfa, ya man lahul-asma\'ul-husna, ya man ma\'a \'ibadihi yasma\'u wa yara, ya man a\'ta kulla shay\'in khalqahu thumma hada. Allahumma antal-badi\'u bil-ihsani min qabli tawajjuhil-\'abidin, wa antal-badi\'u bil-\'ataya qabla talabit-talibin wa antal-Wahhab. Allahumma inni as\'alukal-jannata wa ma qarraba ilayha min qawlin wa \'amal, wa a\'udhu bika minan-nari wa ma qarraba ilayha min qawlin wa \'amal. Allahumma rabbi ibni li \'indaka baytan fil-jannah. Allahumma inni as\'aluka ridaka wal-jannah, wa a\'udhu bika min sakhatika wan-nar.',
  'd7dfdc8a16e':
      'Allahumma ahsin \'aqibatana fil-umuri kulliha, wa ajirna min khizyid-dunya wa \'adhabil-akhirah. Allahumma rabbanasrif \'anna \'adhaba jahannam inna \'adhabaha kana gharama. Allahumma rabbana innana amanna faghfir lana dhunubana wa qina \'adhaban-nar. Allahumma inni as\'alukal-jannah, wa astajiru bika minan-nar. Allahumma rabbana wa atina ma wa\'adtana \'ala rusulika wa la tukhzina yawmal-qiyamah innaka la tukhliful-mi\'ad.',
  'd5bbb6ec8b5':
      'Allahumma hasibni hisaban yasira. Allahumma inna na\'udhu bika an nushrika bika shay\'an na\'lamuh, wa nastaghfiruka lima la na\'lamuh. Allahumma inni a\'udhu bika min jahdil-bala\', wa darakish-shaqa\', wa su\'il-qada\', wa shamatatil-a\'da\', ya sami\'ad-du\'a\'. Allahumma inni a\'udhu bika min \'adhabi jahannam, wa min \'adhabil-qabr, wa min fitnatil-mahya wal-mamat, wa min fitnatil-Masihid-Dajjal, wa a\'udhu bika minal-ma\'thami wal-maghram. Allahumma inni a\'udhu bika min fitnatin-nari wa \'adhabin-nar, wa fitnatil-qabr, wa \'adhabil-qabr, wa sharri fitnatil-ghina, wa sharri fitnatil-faqr, Allahumma inni a\'udhu bika min sharri fitnatil-Masihid-Dajjal.',
  'd4d5177ac54':
      'Allahummaghsil qalbi bima\'ith-thalji wal-barad, wa naqqi qalbi minal-khataya kama naqqaytath-thawbal-abyada minad-danas, wa ba\'id bayni wa bayna khatayaya kama ba\'adta baynal-mashriqi wal-maghrib. Allahumma inni a\'udhu bika minal-kasali wal-ma\'thami wal-maghram. Allahumma rabba Jibra\'ila, wa Mika\'ila, wa rabba Israfil, a\'udhu bika min harrin-nar wa min \'adhabil-qabr. Allahumma inni a\'udhu bika min jaris-su\'i fi darril-muqamah, fa-inna jaral-badiyati yatahawwal. Allahumma inni a\'udhu bika minal-\'ajzi wal-kasal, wal-jubni wal-bukhl, wal-harami wal-qaswah, wal-ghaflati wal-\'aylati wadh-dhillati, wal-maskanah, wa a\'udhu bika minal-faqri wal-kufr, wal-fusuqi wash-shiqaqi wan-nifaq, was-sum\'ati war-riya\', wa a\'udhu bika minas-samami wal-bukmi, wal-junun, wal-judham, wal-baras, wa sayyi\'il-asqam.',
  'deffee150a5':
      'Allahumma inni a\'udhu bika minal-\'ajzi wal-kasal, wal-jubn, wal-bukhl, wal-haram, wa \'adhabil-qabr, Allahumma ati nafsi taqwaha, wa zakkiha anta khayru man zakkaha, anta waliyyuha wa mawlaha. Allahumma inni a\'udhu bika min \'ilmin la yanfa\', wa min qalbin la yakhsha\', wa min nafsin la tashba\', wa min da\'watin la yustajabu laha. Allahumma inni a\'udhu bika min munkaratil-akhlaqi wal-a\'mali wal-ahwa\'i wal-adwa\'. Allahumma inni a\'udhu bika an tuhsina fi lawa\'ihil-\'uyuni \'alaniyati, wa tuqabbiha fi khafiyyatil-\'uyuni sarirati, Allahumma kama asa\'tu wa ahsanta ilayya, fa-idha \'udtu fa\'ud \'alayya. Allahumma inni a\'udhu bika min sharri sam\'i, wa min sharri basari, wa min sharri lisani, wa min sharri qalbi, wa min sharri maniyyi.',
  'd07f3d72bab':
      'Allahumma inni a\'udhu bika an aqula zuran, aw aghsha fujuran, aw akuna bika maghrura. Allahumma inni a\'udhu bika minash-shiqaqi wan-nifaq, wa su\'il-akhlaq. Allahumma inni a\'udhu bi-ridaka min sakhatik, wa bi-mu\'afatika min \'uqubatik, wa bika minka, la uhsi thana\'an \'alayk, anta kama athnayta \'ala nafsik. Allahumma rabbas-samawatis-sab\'i wa rabbal-ard, wa rabbal-\'arshil-\'azim, rabbana wa rabba kulli shay\'in, faliqal-habbi wan-nawa, wa munzilat-tawrati wal-injili wal-furqan, a\'udhu bika min sharri kulli shay\'in anta akhidhun bi-nasiyatih, Allahumma antal-awwalu falaysa qablaka shay\'un, wa antal-akhiru falaysa ba\'daka shay\'un, wa antaz-zahiru falaysa fawqaka shay\'un, iqdi \'annad-dayna wa aghnina minal-faqr. Allahumma inni a\'udhu bika min ghalabatid-dayn, wa ghalabatil-\'aduww, wa shamatatil-a\'da\'.',
  'd65e51d65b1':
      'Allahumma inni a\'udhu bika minal-faqri wal-qillati wadh-dhillah, wa a\'udhu bika min an azlima aw uzlam. Allahumma inni a\'udhu bika min sharri fitnatil-ghina, wa min sharri fitnatil-faqr. Allahumma inni a\'udhu bika min zawali ni\'matik, wa tahawwuli \'afiyatik, wa fuja\'ati niqmatik, wa jami\'i sakhatik. Allahumma inni a\'udhu bika min yawmis-su\'i, wa min laylatis-su\'i, wa min sa\'atis-su\'i, wa min sahibis-su\'i, wa min jaris-su\'i, fi darril-muqamah. Allahumma inni a\'udhu bika min qalbin la yakhsha\', wa min du\'a\'in la yusma\', wa min nafsin la tashba\', wa min \'ilmin la yanfa\', a\'udhu bika min ha\'ula\'il-arba\'.',
  'd6e92c0a552':
      'Allahumma inni a\'udhu bika minat-taraddi, wal-hadm, wal-gharaq, wal-haraq, wa a\'udhu bika an yatakhabbatanish-shaytanu \'indal-mawt, wa a\'udhu bika min an amuta fi sabilika mudbira, wa a\'udhu bika an amuta ladigha. Allahumma rabbi a\'udhu bika min hamazatish-shayatin, wa a\'udhu bika rabbi an yahduryun. Allahumma inni a\'udhu bika min sharril-ashrar, wa min kaydil-fujjar, wa min tawariqil-layli wan-nahar illa tariqan yatruqu bi-khayrin ya Rahman. Allahumma rabbi a\'udhu bika min a\'yunil-\'a\'inin, wa min sihris-sahirin, wa min sharri kulli dhi sharr. Allahumma inni a\'udhu bika minal-ju\', fa-innahu bi\'sad-daji\', wa a\'udhu bika minal-khiyanah, fa-innaha bi\'satil-bitanah.',
  'd2e9fee6a81':
      'Allahumma inni a\'udhu bika min \'uquqil-abna\', wa min qati\'atil-aqriba\', wa min jafwatil-ahya\', wa min taghayyuril-asdiqa\', wa min shamatatil-a\'da\'. Allahumma inni a\'udhu bika min an azilla aw uzall, aw adilla aw udall, aw azlima aw uzlam, aw ajhala aw yujhala \'alayya. Allahumma inna nasta\'inuka wa nastahdik, wa nastaghfiruka wa natubu ilayk, wa nu\'minu bik, wa natawakkalu \'alayk, wa nuthni \'alaykal-khayra kullah, nashkuruka wa la nakfuruk, wa nakhla\'u wa natruku man yafjuruk, Allahumma iyyaka na\'bud, wa laka nusalli wa nasjud, wa ilayka nas\'a wa nahfid, narju rahmataka, wa nakhsha \'adhabak, inna \'adhabakal-jadda bil-kuffari mulhaq. Allahumma rabbana a\'izzana bil-islam, wa a\'izza bina al-islam, Allahumma a\'li bina kalimatal-islam, warfa\' bina rayatal-qur\'an. Allahumma munzilal-kitab, wa mujriyas-sahab, wa hazimal-ahzab, \'alimal-ghaybi wash-shahadah, as\'aluka bismikal-a\'zamil-ladhi idha du\'ita bihi ajabt, wa idha su\'ilta bihi a\'tayt.',
  'd885c4f25ed':
      'Allahumma ya Hayyu ya Qayyum, ya Hayyu ya Qayyum, ya Hayyu ya Qayyum, Allahumma azillani fi zilli \'arshika yawma la zilla illa zillak. Allahumma azhir dinaka \'alad-dini kullihi wa law karihal-mushrikun. Allahumma ya man yujibul-mudtarra idha da\'ah, wa yakshifus-su\', ikshifis-su\'a \'an ikhwaninal-usara wal-masjunina wal-mu\'taqalin, Allahummafkik bi-quwwatika asrahum, wajbur bi-rahmatika kasrahum, wa tawalla bi-\'inayatika amrahum, wa raddahum ila ahlihim salimina ghanimin. Allahumma kun lil-muslimina wal-mustad\'afina fi kulli makan; farrij hammahum, wa nafnis kurbahum, wa aqil \'atharatahum wa tawalla binafsika amrahum. Allahumma irfa\' rayatahum, wakbit \'aduwwahum.',
  'd0affe5f368':
      'Allahumma wahhid saffahum, wajma\' kalimatahum, wa raddahum ilayka radhan jamila. Allahumma la abarra bihim minka, wa la arhama bihim minka, wa la ar\'afa bihim minka.. Allahumma hum minka wa ilayk.. Allahummaj\'alid-da\'irata lahum la \'alayhim wan-nasru halifahum.. ya rabb. Allahumma ya khayra man su\'il, wa ajwada man a\'ta, wa akrama man \'afa, wa a\'zama man ghafar, wa a\'dala man hakam, wa asdaqa man haddath, wa awfa man wa\'ad, wa absara man raqab, wa asra\'a man hasab, wa arhama man \'aqab, wa ahsana man khalaq, wa ahkama man shara\', wa ahaqqa man \'ubid, wa awla man du\'iy, wa abarra man ajab. Allahumma inni as\'aluka khayral-mas\'alah, wa khayrad-du\'a\', wa khayran-najah, wa khayral-\'amal, wa khayrath-thawab, wa khayral-hayah, wa khayral-mamat, wa thabbitni, wa thaqqil mawazini, wa haqqiq imani, warfa\' darajati, wa taqabbal salati, waghfir khati\'ati, wa as\'alukad-darajatil-\'ula minal-jannah. Allahumma inni as\'aluka fawatihal-khayr, wa khawatimah, wa jawami\'ah, wa awwalah, wa zahirah, wa batinah, wad-darajatil-\'ula minal-jannati amin.',
  'df820af544a':
      'Allahumma inni as\'aluka khayra ma ati, wa khayra ma af\'al, wa khayra ma a\'mal, wa khayra ma batan, wa khayra ma zahar, wad-darajatil-\'ula minal-jannati amin. Allahumma inni as\'aluka an tarfa\'a dhikri, wa tada\'a wizri, wa tuslih amri, wa tutahhira qalbi, wa tuhassina farji, wa tunawwira qalbi, wa taghfira li dhanbi, wa as\'alukad-darajatil-\'ula minal-jannati amin. Allahumma inni as\'aluka an tubarika fi nafsi, wa fi sam\'i, wa fi basari, wa fi ruhi, wa fi khalqi, wa fi khuluqi, wa fi ahli, wa fi mahyaya, wa fi mamati, wa fi \'amali, fa-taqabbal hasanati, wa as\'alukad-darajatil-\'ula minal-jannati amin. Allahumma lakal-hamdu kulluh, Allahumma la qabida lima basat, wa la basita lima qabadt, wa la hadiya liman adlalt, wa la mudilla liman hadayt, wa la mu\'tiya lima mana\'t, wa la mani\'a lima a\'tayt, wa la muqarriba lima ba\'adt, wa la muba\'ida lima qarrabt, Allahummabsut \'alayna min barakatika wa rahmatika wa fadlika wa rizqik, Allahumma inni as\'alukan-na\'imal-muqimal-ladhi la yahulu wa la yazul, Allahumma inni as\'alukan-na\'ima yawmal-\'aylati wal-amna yawmal-khawf, Allahumma inni \'a\'idhun bika min sharri ma a\'taytana wa sharri ma mana\'tana. Allahumma habbib ilaynal-imana wa zayyinhu fi qulubina wa karrih ilaynal-kufra wal-fusuqa wal-\'isyan, waj\'alna minar-rashidin, Allahumma tawaffana muslimin, wa ahyina muslimin, wa alhiqna bis-salihina ghayra khazaya wa la maftunin, Allahumma qatilil-kafaratal-ladhina yukadhdhibuna rusulak, wa yasuddun \'an sabilik, waj\'al \'alayhim rijzaka wa \'adhabak, Allahumma qatilil-kafaratal-ladhina utul-kitab, ilahal-haqq.. amin.',
  'dbbc0d601ba':
      'Allahumma bi-\'ilmikal-ghayb, wa qudratika \'alal-khalq; ahyini ma \'alimtal-hayata khayran li, wa tawaffani idha \'alimtal-wafata khayran li, Allahumma inni as\'aluka khashyataka fil-ghaybi wash-shahadah, wa as\'aluka kalimatal-haqqi fir-rida wal-ghadab, wa as\'alukal-qasda fil-ghina wal-faqr, wa as\'aluka na\'iman la yanfad, wa as\'aluka qurrata \'aynin la tanqati\', wa as\'alukar-rida ba\'dal-qada\', wa as\'aluka bardal-\'aysh ba\'dal-mawt, wa as\'aluka ladhdhatan-nazari ila wajhik, wash-shawqa ila liqa\'ik, fi ghayri darra\'a mudirrah wa la fitnatin mudillah, Allahumma zayyinna bi-zinatil-iman, waj\'alna hudatan muhtadin. Allahumma inni as\'aluka fi\'lal-khayrat, wa tarkal-munkarat, wa hubbal-masakin, wa an taghfira li wa tarhamni, wa idha aradta fitnata qawmin fa-tawaffani ghayra maftun, wa as\'aluka hubbak, wa hubba man yuhibbuk, wa hubba kulli \'amalin yuqarribuni ila hubbik. Allahumma inni as\'aluka minal-khayri kullih; \'ajilihi wa ajilih, ma \'alimtu minhu wa ma lam a\'lam, wa a\'udhu bika minash-sharri kullih \'ajilihi wa ajilih, ma \'alimtu minhu wa ma lam a\'lam. Allahumma inni as\'aluka min khayri ma sa\'alaka \'abduka wa nabiyyuka Muhammad, wa a\'udhu bika min sharri ma ista\'adha bika minhu \'abduka wa nabiyyuka Muhammad. Allahumma inni as\'alukal-jannata wa ma qarraba ilayha min qawlin aw \'amal, wa a\'udhu bika minan-nari wa ma qarraba ilayha min qawlin aw \'amal, wa as\'aluka an taj\'ala kulla qada\'in qadaytahu li khayra.',
  'd8a4a49da09':
      'Allahummaqsim lana min khashyatika ma tahulu bihi baynana wa bayna ma\'asik, wa min ta\'atika ma tuballighuna bihi jannatak, wa minal-yaqini ma tuhawwinu bihi \'alayna masa\'ibad-dunya, Allahumma matti\'na bi-asma\'ina, wa absarina, wa quwwatina ma ahyaytana, waj\'alhul-warithu minna, waj\'al tha\'rana \'ala man zalamana, wansurna \'ala man \'adana, wa la taj\'al musibatana fi dinina wa la taj\'alid-dunya akbara hammina, wa la mablagha \'ilmina, wa la tusallit \'alayna man la yarhamuna. Allahumma inna nas\'aluka mujibati rahmatik, wa \'aza\'ima maghfiratik, was-salamata min kulli ithm, wal-ghanimata min kulli birr, wal-fawza bil-jannah, wan-najata minan-nar. Allahumma la tada\' lana dhanban illa ghafartah, wa la hamman illa farrajtah, wa la dayna illa qadaytah, wa la maridan illa shafaytah, wa la mubtalan illa \'afaytah, wa la dallan illa hadaytah, wa la gha\'iban illa radadtah, wa la mazluman illa nasartah, wa la asiran illa fakaktah, wa la mayyitan illa rahimtah, wa la hajata lana fiha salahun wa laka fiha rida illa qadaytaha wa yassartaha bi-fadlika ya akramal-akramin. Allahumma rabbi a\'inni wa la tu\'in \'alayya, wansurni wa la tansur \'alayya, wamkur li wa la tamkur \'alayya, wahdini wa yassiril-huda ilayya, wansurni \'ala man bagha \'alayya. Allahumma rabbij\'alni laka shakkara, laka dhakkara, laka rahhaba, laka mitwa\'a, ilayka mukhbitan awwahan munibah, rabbi taqabbal tawbati, waghsil hawbati, wa ajib da\'wati, wa thabbit hujjati, wahdi qalbi, wa saddid lisani, wasallil sakhimata qalbi.',
  'd22701f516f':
      'Allahumma inna nas\'aluka yusran laysa ba\'dahu \'usr, wa ghinan laysa ba\'dahu faqr, wa amnan laysa ba\'dahu khawf, wa sa\'adatan laysa ba\'daha shaqa\'. Allahumma allif bayna qulubina, wa aslih dhata baynina, wahdina subulas-salam, wa najjina minaz-zulumati ilan-nur, wa jannibnal-fawahisha ma zahara minha wa ma batan, wa barik lana fi asma\'ina, wa absarina, wa qulubina, wa azwajina, wa dhurriyyatina, wa tub \'alayna innaka antat-Tawwabur-Rahim, waj\'alna shakirina li-ni\'amika muthnina biha \'alayka qabilina laha wa atimmaha \'alayna. Allahumma ya muqallibal-qulubi wal-absar, thabbit qulubana \'ala ta\'atik, wa la tuzigh qulubana ba\'da idh hadaytana, wa la taftinna fi dinina, waj\'al yawmana khayran min amsina, waj\'al ghadana khayran min yawmina, waj\'al khayra a\'marina awakhiraha, wa khayra a\'malina khawatimaha, wa khayra ayyamina yawma nalqaka wa anta radin \'anna. Allahumma antal-ladhi khalaqtani fa-anta tahdin, wa antal-ladhi tut\'imuni wa tasqin, wa idha maridtu fa-anta tashfin, wa antal-ladhi tumituni thumma tuhyin, wa antal-ladhi atma\'u an yaghfira li khati\'ati yawmad-din, rabbi hab li hukman wa alhiqni bis-salihin, waj\'al li lisana sidqin fil-akhirin, waj\'alni min warathati jannatin-na\'im, waghfir li-aba\'ina wa ummahatina minal-muslimin wa la tukhzini yawma yub\'athun, yawma la yanfa\'u malun wa la banun, illa man atallaha bi-qalbin salim. Allahummahfazni bil-islami qa\'iman, wahfazni bil-islami qa\'idan, wahfazni bil-islami raqidan, wa la tushmit bi \'aduwwan wa la hasidan.',
  'de26aa34a25':
      'Allahumma inni as\'aluka min kulli khayrin khaza\'inuhu biyadik, wa a\'udhu bika min kulli sharrin khaza\'inuhu biyadik. Allahumma ya dhal-hablish-shadid, wal-amrir-rashid, as\'alukal-amna yawmal-wa\'id, wal-jannata daral-khulud, ma\'al-muqarrabinash-shuhud, ar-ruka\'is-sujud, al-mufina bil-\'uhud, innaka rahimun wadud, wa innaka taf\'alu ma turid. Allahummaj\'alna hadina muhtadin, ghayra dallina wa la mudillin, silman li-awliya\'ik, wa harban \'ala a\'da\'ik, nuhibbu bi-hubbika man ahabbak, wa nu\'adi bi-\'adawatika man khalafak. Allahumma hadhad-du\'a\'u wa minkal-ijabah, Allahumma hadhal-juhdu wa \'alaykat-tuklan. Allahumma inni as\'aluka imanan la yartadd, wa na\'iman la yanfad, wa murafaqata nabiyyika Muhammadin fi a\'la jannatil-khuld. Allahumma atinil-hikmatal-lati man utiyaha fa-qad utiya khayran kathira.',
  'df288dfed69':
      'Allahumma a\'inni \'ala dhikrika wa shukrika wa husni \'ibadatik. Allahummarhamni, fa-anta khayrur-rahimin, warzuqni, fa-anta khayrur-raziqin, waghfir li fa-anta khayrul-ghafirin, wansurni, fa-anta khayran-nasirin. Allahumma rahmataka arju fa-la takilni ila nafsi tarfata \'ayn, wa aslih li sha\'ni kullah, la ilaha illa ant. Allahumma zidna wa la tanqusna, wa akrimna wa la tuhinna, wa a\'tina wa la tahrimna, wa athirna wa la tu\'thir \'alayna, wa ardina wardha \'anna. Allahumma inni as\'aluka \'ayshatan naqiyyah, wa mitatan sawiyyah, wa maradda ghayra mukhzin wa la fadih.',
  'd6f8ef99504':
      'Allahumma rabbi awzi\'ni an ashkura ni\'mataka allati an\'amta \'alayya wa \'ala walidayya, wa an a\'mala salihan tardah, wa adkhilni bi-rahmatika fi \'ibadikas-salihin. Allahumma inni as\'alukal-\'afwa wal-\'afiyata wal-mu\'afata fid-dunya wal-akhirah. Allahumma inni as\'alukal-huda, wat-tuqa, wal-\'afafa wal-ghina. Allahumma inni as\'aluka \'ilman nafi\'a, wa rizqan tayyiba, wa \'amalan mutaqabbala. Allahummaghfir li, wahdini warzuqni, wa \'afini, a\'udhu billahi min diqil-maqami yawmal-qiyamah.',
  'df4c85e5742':
      'Allahumma qini sharra nafsi, wa\'zim li \'ala arshadi amri, Allahummaghfir li ma asrartu, wa ma a\'lantu wa ma akhta\'t, wa ma ta\'ammadt, wa ma \'alimt, wa ma jahilt. Allahumma akthir mali, wa waladi, wa barik li fima a\'taytani, wa atil hayati \'ala ta\'atik, wa ahsin \'amali waghfir li. Allahummastur \'awrati, wa amin raw\'ati, wahfazni min bayni yadayya wa min khalfi, wa \'an yamini wa \'an shimali, wa min fawqi, wa a\'udhu bika an ughtala min tahti. Allahumma akrimni wa la tuhinni, wa a\'tini wa la tahrimni, wa zidni wa la tanqusni, wa athirni wa la tu\'thir \'alayya, wardha \'anni wa ardini. Allahummaftah lana fathan mubina, wahdina siratan mustaqima, wansurna nasran \'aziza, wa atimma \'alayna ni\'mataka, wa anzil fi qulubina sakinatak, wanshur \'alayna fadlaka wa rahmatak.',
  'd67ebde94fc':
      'Allahumma a\'inna \'ala shahawati anfusina, wa qaswati qulubina, wa da\'fi iradatina, wa la takilna ila anfusina wa la ila ahadin ghayrik. Allahumma la takilna ila anfusina tarfata \'aynin wa la aqalla min dhalik. Allahumma rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar. Allahummashghal qulubana bi-hubbik, wa alsinatana bi-dhikrik, wa abdanana bi-ta\'atik, wa \'uqulana bit-tafakkuri fi khalqika wat-tafaqquhi fi dinik. Allahummashfi mardana, warham mawtana, wa \'afi mubtalana, wa fukka asrana, wajbur kasrana.',
  'd13cb990eb5':
      'Allahumma at\'imna min ju\', wa aminna min khawf, wa qawwina min da\'f, wa \'allimna min jahalah, wa anqidhna min dalalah. Allahummakhtim bis-salihati a\'malana, wa bis-sa\'adati ajalana, wa ballighna mimma yurdika amalana. Allahumma aslih li dini alladhi huwa \'ismatu amri, wa aslih li dunyaya allati fiha ma\'ashi, wa aslih li akhirati allati fiha ma\'adi, waj\'alil-hayata ziyadatan li fi kulli khayr, waj\'alil-mawta rahatan li min kulli sharr. Allahummaj\'al khayra \'umri awakhirah, wa khayra \'amali khawatimah, wa khayra ayyami yawma liqaka. Allahummahfazni bil-islami qa\'iman, wahfazni bil-islami qa\'idan, wahfazni bil-islami raqidan, wa la tushmit bi \'aduwwan wa la hasidan.',
  'd2a98be09f3':
      'Allahumma ahyina muslimin, wa tawaffana muslimin, wa alhiqna bis-salihin. Allahumma abrim li-hadhihil-ummati amra rushd, yu\'azzu fihi ahlu ta\'atik, wa yudhallu fihi ahlu ma\'siyatik, wa yu\'maru fihi bil-ma\'ruf, wa yunha fihi \'anil-munkar. Allahumma Allahumma salli wa sallim wa barik \'ala \'abdika wa rasulika Muhammad wa \'ala alihi wa sahbihi ajma\'in.',
  'd42d88dff56':
      'Allahumma anta rabbi la ilaha illa ant, khalaqtani wa ana \'abduk, wa ana \'ala \'ahdika wa wa\'dika mastata\'t, a\'udhu bika min sharri ma sana\'t, abu\'u laka bi-ni\'matika \'alayya, wa abu\'u bi-dhanbi fa-ghfir li fa-innahu la yaghfirudh-dhunuba illa ant.',
  'd7cd83bdbdf':
      'Allahumma inni zalamtu nafsi zulman kathira, wa la yaghfirudh-dhunuba illa ant, faghfir li maghfiratan min \'indika warhamni innaka antal-Ghafurur-Rahim.',
  'd4264ac3360':
      'Rabbighfir li khati\'ati wa jahli wa israfi fi amri kullih wa ma anta a\'lamu bihi minni, Allahummaghfir li khataya-ya wa \'amdi wa jahli wa hazli, wa kullu dhalika \'indi, Allahummaghfir li ma qaddamtu wa ma akhkhart wa ma asrartu wa ma a\'lant, antal-Muqaddimu wa antal-Mu\'akhkhiru wa anta \'ala kulli shay\'in qadir.',
  'd575771fb64':
      'Allahummaghfir li dhanbi kullah, diqqahu, wa jillah, wa awwalahu, wa akhirah, wa \'alaniyatahu, wa sirrah.',
  'db1556e6377':
      'Allahumma inni a\'udhu bika minal-hammi wal-huzni wal-\'ajzi wal-kasali wal-jubni wal-bukhli wa dala\'id-dayni wa ghalabatir-rijal.',
  'd87f5b07a81':
      'Allahumma inni a\'udhu bika minal-bukhl, wa a\'udhu bika minal-jubn, wa a\'udhu bika an uradda ila ardhalil-\'umur, wa a\'udhu bika min fitnatid-dunya, wa a\'udhu bika min \'adhabil-qabr.',
  'd581e3e84f5':
      'Allahumma inni a\'udhu bika minal-kasali wal-harami wal-ma\'thami wal-maghram, wa min fitnatil-qabri wa \'adhabil-qabr, wa min fitnatin-nari wa \'adhabin-nar, wa min sharri fitnatil-ghina, wa a\'udhu bika min fitnatil-faqr, wa a\'udhu bika min fitnatil-Masihid-Dajjal, Allahummaghsil \'anni khatayaya bima\'ith-thalji wal-barad, wa naqqi qalbi minal-khataya kama naqqaytath-thawbal-abyada minad-danas, wa ba\'id bayni wa bayna khatayaya kama ba\'adta baynal-mashriqi wal-maghrib.',
  'd27654d3cad':
      'Allahumma rabbas-samawati wa rabbal-ard wa rabbal-\'arshil-\'azim, rabbana wa rabba kulli shay\'in, faliqal-habbi wan-nawa wa munzilat-tawrati wal-injili wal-furqan, a\'udhu bika min sharri kulli shay\'in anta akhidhun bi-nasiyatih, Allahumma antal-awwalu falaysa qablaka shay\'un, wa antal-akhiru falaysa ba\'daka shay\'un, wa antaz-zahiru falaysa fawqaka shay\'un, wa antal-batinu falaysa dunaka shay\'un, iqdi \'annad-dayna wa aghnina minal-faqr.',
  'd19bd89c5ac':
      'Allahumma inni a\'udhu bika min sharri ma \'amiltu wa min sharri ma lam a\'mal.',
  'd60e0c361be':
      'Allahumma aslih li dini alladhi huwa \'ismatu amri, wa aslih li dunyaya allati fiha ma\'ashi, wa aslih li akhirati allati fiha ma\'adi, waj\'alil-hayata ziyadatan li fi kulli khayr, waj\'alil-mawta rahatan li min kulli sharr.',
  'df22dc44e67':
      'Allahumma inni as\'alukal-huda wat-tuqa wal-\'afafa wal-ghina.',
  'dae643593db':
      'Allahumma inni a\'udhu bika minal-\'ajzi wal-kasal, wal-jubni wal-bukhl, wal-harami wa \'adhabil-qabr, Allahumma ati nafsi taqwaha wa zakkiha anta khayru man zakkaha, anta waliyyuha wa mawlaha, Allahumma inni a\'udhu bika min \'ilmin la yanfa\', wa min qalbin la yakhsha\', wa min nafsin la tashba\', wa min da\'watin la yustajabu laha.',
  'd037d67dba9':
      'Allahumma laka aslamtu wa bika amantu, wa \'alayka tawakkaltu wa ilayka anabtu wa bika khasamt, Allahumma inni a\'udhu bi-\'izzatika la ilaha illa anta an tudillani, antal-Hayyul-ladhi la yamutu wal-jinnu wal-insu yamutun.',
  'd7de5d9de9f':
      'Allahumma inni a\'udhu bika min zawali ni\'matika wa tahawwuli \'afiyatika wa fuja\'ati niqmatika wa jami\'i sakhatik.',
  'defdc86b8ef': 'Allahumma musarrifal-qulubi sarrif qulubana \'ala ta\'atik.',
  'd5660145059':
      'Allahumma rabba Jibra\'ila wa Mika\'ila wa Israfil, fatiras-samawati wal-ard, \'Alimal-ghaybi wash-shahadah, anta tahkumu bayna \'ibadika fima kanu fihi yakhtalifun, ihdini lima ikhtulifa fihi minal-haqqi bi-idhnik, innaka tahdi man tasha\'u ila siratin mustaqim.',
  'dee655891d1':
      'Allahumma inni a\'udhu bi-ridaka min sakhatik, wa bi-mu\'afatika min \'uqubatik, wa a\'udhu bika minka, la uhsi thana\'an \'alayk, anta kama athnayta \'ala nafsik.',
  'd9485afa658':
      'Allahumma inni a\'udhu bika min jahdil-bala\'i wa darakish-shaqa\'i wa su\'il-qada\'i wa shamatatil-a\'da\'.',
  'd2aebf8bf53':
      'Allahummaj\'al li fi qalbi nura, wa fi lisani nura, wa fi sam\'i nura, wa fi basari nura, wa min fawqi nura, wa min tahti nura, wa \'an yamini nura, wa \'an shimali nura, wa min bayni yadayya nura, wa min khalfi nura, waj\'al fi nafsi nura, wa a\'zim li nura.',
  'd34c0f05796':
      'Allahumma inni as\'aluka minal-khayri kullihi \'ajilihi wa ajilih ma \'alimtu minhu wa ma lam a\'lam, wa a\'udhu bika minash-sharri kullihi \'ajilihi wa ajilih ma \'alimtu minhu wa ma lam a\'lam, Allahumma inni as\'aluka min khayri ma sa\'alaka \'abduka wa nabiyyuk, wa a\'udhu bika min sharri ma \'adha bihi \'abduka wa nabiyyuk, Allahumma inni as\'alukal-jannata wa ma qarraba ilayha min qawlin aw \'amal, wa a\'udhu bika minan-nari wa ma qarraba ilayha min qawlin aw \'amal wa as\'aluka an taj\'ala kulla qada\'in qadaytahu li khayra.',
  'df2aaf0af28':
      'Allahumma bi-\'ilmikal-ghaybi wa qudratika \'alal-khalqi ahyini ma \'alimtal-hayata khayran li, wa tawaffani idha \'alimtal-wafata khayran li, Allahumma wa as\'aluka khashyataka fil-ghaybi wash-shahadah, wa as\'aluka kalimatal-haqqi fir-rida wal-ghadab, wa as\'alukal-qasda fil-faqri wal-ghina, wa as\'aluka na\'iman la yanfad, wa as\'aluka qurrata \'aynin la tanqati\', wa as\'alukar-rida ba\'dal-qada\', wa as\'aluka bardal-\'aysh ba\'dal-mawt, wa as\'aluka ladhdhatan-nazari ila wajhika wash-shawqa ila liqa\'ika fi ghayri darra\'a mudirrah wa la fitnatin mudillah, Allahumma zayyinna bi-zinatil-iman, waj\'alna hudatan muhtadin.',
  'd9d1e0d0df8':
      'Allahumma inni as\'alukal-\'afwa wal-\'afiyata fid-dunya wal-akhirah, Allahumma inni as\'alukal-\'afwa wal-\'afiyata fi dini wa dunyaya wa ahli wa mali, Allahummastur \'awrati wa amin raw\'ati, wahfazni min bayni yadayya wa min khalfi wa \'an yamini wa \'an shimali wa min fawqi, wa a\'udhu bi-\'azamatika an ughtala min tahti.',
  'd3a6720aaf7':
      'Allahumma \'Alimal-ghaybi wash-shahadah, fatiras-samawati wal-ard, rabba kulli shay\'in wa malikah, ashhadu an la ilaha illa ant, a\'udhu bika min sharri nafsi wa sharrish-shaytani wa shirkih.',
  'dd3f0f3e3ed':
      'Allahumma inni as\'alukath-thabata fil-amr, wal-\'azimata \'alar-rushd, wa as\'aluka mujibati rahmatik, wa \'aza\'ima maghfiratik, wa as\'aluka shukra ni\'matik, wa husna \'ibadatik, wa as\'aluka qalban salima, wa lisanan sadiqa, wa as\'aluka min khayri ma ta\'lam, wa a\'udhu bika min sharri ma ta\'lam, wa astaghfiruka lima ta\'lam, innaka anta \'allamul-ghuyub.',
  'd0f98141fb9':
      'Allahummakfini bi-halalika \'an haramik wa aghnini bi-fadlika \'amman siwak.',
  'd86040fca97':
      'Allahumma \'afini fi badani, Allahumma \'afini fi sam\'i, Allahumma \'afini fi basari, la ilaha illa ant, Allahumma inni a\'udhu bika minal-kufri wal-faqr, Allahumma inni a\'udhu bika min \'adhabil-qabr, la ilaha illa ant.',
  'd690fd30aea':
      'Rabbi a\'inni wa la tu\'in \'alayya, wansurni wa la tansur \'alayya, wamkur li wa la tamkur \'alayya, wahdini wa yassiril-huda li, wansurni \'ala man bagha \'alayya, rabbij\'alni laka shakkara, laka dhakkara, laka rahhaba, laka mitwa\'a, laka mukhbitan ilayka awwahan munibah, rabbi taqabbal tawbati waghsil hawbati wa ajib da\'wati wa thabbit hujjati wa saddid lisani wahdi qalbi wasallil sakhimata sadri.',
  'd027b254da5':
      'Allahumma lakal-hamdu kulluh, Allahumma la qabida lima basat, wa la basita lima qabadt, wa la hadiya lima adlalt, wa la mudilla liman hadayt, wa la mu\'tiya lima mana\'t, wa la mani\'a lima a\'tayt, wa la muqarriba lima ba\'adt, wa la muba\'ida lima qarrabt, Allahummabsut \'alayna min barakatika wa rahmatika wa fadlika wa rizqik, Allahumma inni as\'alukan-na\'imal-muqimal-ladhi la yahulu wa la yazul, Allahumma inni as\'alukan-na\'ima yawmal-\'aylah, wal-amna yawmal-khawf, Allahumma inni \'a\'idhun bika min sharri ma a\'taytana wa sharri ma mana\'t, Allahumma habbib ilaynal-imana wa zayyinhu fi qulubina, wa karrih ilaynal-kufra wal-fusuqa wal-\'isyan, waj\'alna minar-rashidin, Allahumma tawaffana muslimin, wa ahyina muslimin, wa alhiqna bis-salihina ghayra khazaya wa la maftunin, Allahumma qatilil-kafaratal-ladhina yukadhdhibuna rusulak, wa yasuddun \'an sabilik, waj\'al \'alayhim rijzaka wa \'adhabak, Allahumma qatilil-kafaratal-ladhina utul-kitab ilahal-haqq.',
  'dc8c7379228':
      'Allahumma salli \'ala Muhammadin wa \'ala ali Muhammad kama sallayta \'ala Ibrahima wa \'ala ali Ibrahim, innaka Hamidun Majid, Allahumma barik \'ala Muhammadin wa \'ala ali Muhammad kama barakta \'ala Ibrahima wa \'ala ali Ibrahima innaka Hamidun Majid.',
  'de17005f7f3':
      'Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar',
  'de6cc7d08ef':
      'Rabbana afrigh \'alayna sabran wa thabbit aqdamana wansurna \'alal-qawmil-kafirin',
  'd18712ecd95':
      'Rabbana la tu\'akhidhna in nasina aw akhta\'na, rabbana wa la tahmil \'alayna isran kama hamaltahu \'alal-ladhina min qablina, rabbana wa la tuhammilna ma la taqata lana bih, wa\'fu \'anna waghfir lana warhamna anta mawlana fansurna \'alal-qawmil-kafirin',
  'd8f81430801':
      'Rabbana la tuzigh qulubana ba\'da idh hadaytana wa hab lana min ladunka rahmah innaka antal-Wahhab',
  'db696a437b4':
      'Rabbana innana amanna faghfir lana dhunubana wa qina \'adhaban-nar',
  'dc6bf6dce98':
      'Rabbi hab li min ladunka dhurriyyatan tayyibah innaka sami\'ud-du\'a\'',
  'dd7f9b47e32':
      'Rabbana amanna bima anzalta wattaba\'nar-rasula faktubna ma\'ash-shahidin',
  'd1e3593083b':
      'Rabbanaghfir lana dhunubana wa israfana fi amrina wa thabbit aqdamana wansurna \'alal-qawmil-kafirin',
  'dc62cd498ee':
      'Rabbana ma khalaqta hadha batilan subhanaka faqina \'adhaban-nar, rabbana innaka man tudkhilin-nara faqad akhzaytah, wa lizzalimina min ansar, rabbana innana sami\'na munadiyan yunadi lil-imani an aminu bi-rabbikum fa-amanna, rabbana faghfir lana dhunubana wa kaffir \'anna sayyi\'atina wa tawaffana ma\'al-abrar, rabbana wa atina ma wa\'adtana \'ala rusulika wa la tukhzina yawmal-qiyamah innaka la tukhliful-mi\'ad',
  'd09f55a218d':
      'Rabbana zalamna anfusana wa in lam taghfir lana wa tarhamna lanakunanna minal-khasirin',
  'd81d9856add': 'Rabbana la taj\'alna ma\'al-qawmiz-zalimin',
  'd32d428da63': 'Rabbana afrigh \'alayna sabran wa tawaffana muslimin',
  'd9a48af4417':
      'Hasbiyallahu la ilaha illa huwa \'alayhi tawakkaltu wa huwa rabbul-\'arshil-\'azim',
  'd03dcb23937':
      'Rabbana la taj\'alna fitnatan lil-qawmiz-zalimin, wa najjina bi-rahmatika minal-qawmil-kafirin',
  'd2b9ec7b550':
      'Rabbi inni a\'udhu bika an as\'alaka ma laysa li bihi \'ilm, wa illa taghfir li wa tarhamni akun minal-khasirin',
  'd539ff3d552':
      'Rabbij\'alni muqimas-salati wa min dhurriyyati, rabbana wa taqabbal du\'a\'',
  'dc656ba268b':
      'Rabbanaghfir li wa li-walidayya wa lil-mu\'minina yawma yaqumul-hisab',
  'd36eb46d9f7':
      'Rabbi adkhilni mudkhala sidqin wa akhrijni mukhraja sidqin waj\'al li min ladunka sultanan nasira',
  'd5d9c6ca17f':
      'Rabbana atina min ladunka rahmatan wa hayyi\' lana min amrina rashada',
  'ddbd46cd8f0':
      'Rabbishrah li sadri, wa yassir li amri, wahlul \'uqdatan min lisani, yafqahu qawli',
  'dd1c86974a0': 'Rabbi zidni \'ilma',
  'ddff77ab3f8': 'La ilaha illa anta subhanaka inni kuntu minaz-zalimin',
  'd0c5c450bd3': 'Rabbi la tadharni fardan wa anta khayrul-warithin',
  'dd441214312':
      'Rabbi a\'udhu bika min hamazatish-shayatin, wa a\'udhu bika rabbi an yahdurun',
  'd9fb6b06aea': 'Rabbana amanna faghfir lana warhamna wa anta khayrur-rahimin',
  'd46b2d7c904': 'Rabbighfir warham wa anta khayrur-rahimin',
  'd9955f6cfa3':
      'Rabbighfir li wa li-walidayya wa liman dakhala bayti mu\'minan wa lil-mu\'minina wal-mu\'minati wa la tazidiz-zalimina illa tabara\nRabbi inni a\'udhu bika an as\'alaka ma laysa li bihi \'ilm, wa illa taghfir li wa tarhamni akun minal-khasirin\nRabbi anzilni munzalan mubarakan wa anta khayrul-munzilin',
  'd3220bf033c':
      'Rabbana taqabbal minna innaka antas-Sami\'ul-\'Alim (127) rabbana waj\'alna muslimayni laka wa min dhurriyyatina ummatan muslimatan laka wa arina manasikana wa tub \'alayna innaka antat-Tawwabur-Rahim (128)\nRabbij\'alni muqimas-salati wa min dhurriyyati, rabbana wa taqabbal du\'a\' (40) rabbanaghfir li wa li-walidayya wa lil-mu\'minina yawma yaqumul-hisab (41)\nRabbi hab li hukman wa alhiqni bis-salihin (83) waj\'al li lisana sidqin fil-akhirin (84) waj\'alni min warathati jannatin-na\'im (85)\nRabbana \'alayka tawakkalna wa ilayka anabna wa ilaykal-masir (4) rabbana la taj\'alna fitnatan lilladhina kafaru waghfir lana rabbana, innaka antal-\'Azizul-Hakim (5)\nRabbi hab li minas-salihin',
  'dcacd7e753c':
      'Inni tawakkaltu \'alallahi rabbi wa rabbikum, ma min dabbatin illa huwa akhidhun bi-nasiyatiha, inna rabbi \'ala siratin mustaqim',
  'd4f007ce70d':
      'Rabbinsurni \'alal-qawmil-mufsidin\nRabbi najjini wa ahli mimma ya\'malun',
  'd89fc847b6e':
      'Fatiras-samawati wal-ardi anta waliyyi fid-dunya wal-akhirah, tawaffani musliman wa alhiqni bis-salihin',
  'db46e7a8197':
      'Wasi\'a rabbuna kulla shay\'in \'ilma, \'alallahi tawakkalna, rabbanaftah baynana wa bayna qawmina bil-haqq wa anta khayrul-fatihin',
  'd851f5fd4d7':
      'Rabbi inni zalamtu nafsi faghfir li\nRabbi bima an\'amta \'alayya falan akuna zahiran lil-mujrimin\nRabbi inni lima anzalta ilayya min khayrin faqir\nRabbishrah li sadri (25) wa yassir li amri (26) wahlul \'uqdatan min lisani (27) yafqahu qawli (28)',
  'df7cfe09e37': 'Anni massaniyad-durru wa anta arhamur-rahimin',
  'd64a0fff60f':
      'Rabbi awzi\'ni an ashkura ni\'mataka allati an\'amta \'alayya wa \'ala walidayya wa an a\'mala salihan tardah, wa adkhilni bi-rahmatika fi \'ibadikas-salihin',
  'd21873ab38c':
      'Rabbi hab li min ladunka dhurriyyatan tayyibah innaka sami\'ud-du\'a\'\nRabbi la tadharni fardan wa anta khayrul-warithin',
  'decfcb5345b': 'Innama ashku baththi wa huzni ilallah',
  'dec2ec5614e':
      'Alhamdu lillahil-ladhi kasani hadha (ath-thawb) wa razaqanihi min ghayri hawlin minni wa la quwwah.',
  'd3d1e023d22': 'Allahumma lakal-hamdu anta kasawtanih, as\'aluka min khayrih',
  'de2121bedec':
      'La ilaha illallahul-\'Azimul-Halim, la ilaha illallahu rabbul-\'arshil-\'azim, la ilaha illallahu rabbus-samawati wa rabbul-ardi wa rabbul-\'arshil-karim. Allahumma rahmataka arju fa-la takilni ila nafsi tarfata \'ayn wa aslih li sha\'ni kullah, la ilaha illa ant. La ilaha illa anta subhanaka inni kuntu minaz-zalimin. Allah, Allah, rabbi la ushriku bihi shay\'a',
  'df122ba2d0c':
      'Allahumma inni \'abduka ibnu \'abdika ibnu amatik nasiyati biyadik madin fi hukmik, \'adlun fi qada\'ik, as\'aluka bi-kulli ismin huwa lak sammayta bihi nafsak aw anzaltahu fi kitabik, aw \'allamtahu ahadan min khalqik aw ista\'tharta bihi fi \'ilmil-ghaybi \'indak an taj\'alal-qur\'ana rabi\'a qalbi, wa nura sadri wa jala\'a huzni wa dhahaba hammi. Allahumma inni a\'udhu bika minal-hammi wal-huzni wal-\'ajzi wal-kasali wal-bukhli wal-jubni, wa dala\'id-dayni wa ghalabatir-rijal.',
  'd9ed7a1d5e3':
      'Allahumma inni as\'aluka khayraha, wa khayra ma fiha, wa khayra ma ursilat bih, wa a\'udhu bika min sharriha, wa sharri ma fiha wa sharri ma ursilat bih.',
  'd4dc0a14527':
      'Subhanal-ladhi yusabbihur-ra\'du bihamdihi wal-mala\'ikatu min khifatih',
  'dc13c44c02c':
      'As-salamu \'alaykum ahlad-diyari minal-mu\'minina wal-muslimin, wa inna in sha\'a Allahu bikum lahiqun, wa yarhamu Allahul-mustaqdimina minna wal-musta\'khirin, as\'alu Allaha lana wa lakumul-\'afiyah.',
  'd232231a06b': 'Allahumma sayyiban nafi\'a',
  'd1a9c223641':
      'Bismillah, alhamdu lillah, subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinin wa inna ila rabbina lamunqalibun, alhamdu lillah, alhamdu lillah, alhamdu lillah, Allahu akbar, Allahu akbar, Allahu akbar, subhanaka Allahumma inni zalamtu nafsi faghfir li, fa-innahu la yaghfirudh-dhunuba illa ant.',
  'd108917a0bb':
      'Allahumma inna nas\'aluka fi safarina hadhal-birra wat-taqwa, wa minal-\'amali ma tarda, Allahumma hawwin \'alayna safarana hadha watwi \'anna bu\'dah, Allahumma antas-sahibu fis-safar, wal-khalifatu fil-ahl, Allahumma inni a\'udhu bika min wa\'tha\'is-safar, wa ka\'abatil-manzar, wa su\'il-munqalabi fil-mali wal-ahl. Wa idha raja\'a qalahunna wa zada fihinn: ayibuna, ta\'ibuna, \'abiduna, li-rabbina hamidun',
  'd1fb7e630b2': 'Astawdi\'ukumullahal-ladhi la tadi\'u wada\'i\'uh',
  'd0a296ee55d':
      'Astawdi\'ullaha dinaka wa amanataka, wa khawatima \'amalik, zawwadakallahut-taqwa, wa ghafara dhanbak, wa yassara lakal-khayra haythuma kunt',
  'dab19b38552': 'A\'udhu bi-kalimatillahit-tammati min sharri ma khalaq',
  'da877ac2d6f':
      'Rabbighfir li rabbighfir li Allahummaghfir li, warhamni wahdini wajburni wa \'afini warzuqni warfa\'ni',
  'dc6e0f208ef':
      'Allahumma la sahla illa ma ja\'altahu sahla wa anta taj\'alul-hazna idha shi\'ta sahla',
  'de55f47a6b3':
      'Allahumma inni a\'udhu bika an ushrika bika wa ana a\'lam, wa astaghfiruka lima la a\'lam',
  'd3023d367b7':
      'Rabbighfir li wa tub \'alayya innaka antat-Tawwabul-Ghafur (mi\'ata marra qabla an yaqum)',
  'ddabb8f87b2':
      'Subhanakallahumma wa bihamdik, ashhadu an la ilaha illa ant, astaghfiruka wa atubu ilayk',
  'da6ce1d72bd':
      'Alhamdu lillahil-ladhi \'afani mimma ibtala bihi wa faddalani \'ala kathirin mimman khalaqa tafdila',
  'd2b85e05ed2': 'A\'udhu billahi minash-shaytanir-rajim',
  'd75f4843055':
      'Barakallahu lak, wa baraka \'alayk, wa jama\'a baynakuma fi khayr',
  'd31020bcd34':
      'Allahumma inni as\'aluka khayraha wa khayra ma jabaltaha \'alayh wa a\'udhu bika min sharriha wa sharri ma jabaltaha \'alayh, wa idha ishtara ba\'iran fal-ya\'khudh bi-dhirwati sanamihi wal-yaqul mithla dhalik',
  'dfb0e02baeb':
      'Bismillah, Allahumma jannibnash-shaytan, wa jannibish-shaytana ma razaqtana',
  'd4d5a042be6':
      'Idha \'atasa ahadukum fal-yaqul: alhamdu lillah, wal-yaqul lahu akhuhu, aw sahibuhu: yarhamukallah, fa-idha qala lahu: yarhamukallah, fal-yaqul: yahdikumullahu wa yuslihu balakum.',
  'df8a10d1633':
      'Dhahabaz-zama\'u, wabtallatil-\'uruq, wa thabatal-ajru in sha\'a Allah',
  'd9f4cb27e47':
      'Aftara \'indakumus-sa\'imun, wa akala ta\'amakumul-abrar, wa sallat \'alaykumul-mala\'ikah',
  'd20d05fd16c':
      'Allahu akbar, Allahumma ahillahu \'alayna bil-amni wal-imani was-salamati wal-islam, wat-tawfiqi lima tuhibbu wa tarda, rabbuna wa rabbukallah.',
  'da70aebfc3c':
      'Inna lillahi wa inna ilayhi raji\'un, Allahumma ajirni fi musibati wakhluf li khayran minha',
  'd4da406dac0':
      'La ba\'sa tahurun in sha\'a Allah. Ma min \'abdin muslimin ya\'udu maridan lam yahdur ajaluhu fayaqulu sab\'a marrat: as\'alullahal-\'Azima rabbal-\'arshil-\'azimi an yashfiyak, illa \'ufiy.',
  'd51a8a3a4c4': 'Allahummaghfir li warhamni wa alhiqni bir-rafiqil-a\'la',
  'dca86279047':
      'U\'idhukuma bi-kalimatillahit-tammati min kulli shaytanin wa hammah, wa min kulli \'aynin lammah',
  'd55ab930a7b':
      'Hasbunallahu wa ni\'mal-wakil. Allahumma inna naj\'aluka fi nuhurihim wa na\'udhu bika min shururihim. Allahumma anta \'adudi, wa anta nasiri, bika ajulu wa bika asulu wa bika uqatil',
  'd77ba6e7aea':
      'Qala Jabir ibn \'Abdillah radiyallahu \'anhuma: kana rasulullahi salla Allahu \'alayhi wa sallam yu\'allimunal-istikharata fil-umuri kulliha kama yu\'allimunas-surata minal-qur\'an, yaqul: (idha hamma ahadukum bil-amri falyarka\' rak\'atayni min ghayril-faridah thumma liyaqul: Allahumma inni astakhiruka bi-\'ilmik, wa astaqdiruka bi-qudratik, wa as\'aluka min fadlikal-\'azim, fa-innaka taqdiru wa la aqdir, wa ta\'lamu wa la a\'lam, wa anta \'allamul-ghuyub, Allahumma in kunta ta\'lamu anna hadhal-amra (wa yusammi hajatahu) khayrun li fi dini wa ma\'ashi wa \'aqibati amri aw qala \'ajilihi wa ajilihi faqdurhu li wa yassirhu li thumma barik li fih, wa in kunta ta\'lamu anna hadhal-amra sharrun li fi dini wa ma\'ashi wa \'aqibati amri aw qala \'ajilihi wa ajilihi fasrifhu \'anni wasrifni \'anhu waqdur liyal-khayra haythu kana thumma ardini bih).',
  'db51322baa6':
      'Sajada wajhi lilladhi khalaqahu wa shaqqa sam\'ahu wa basarahu bihawlihi wa quwwatih (fatabarakallahu ahsanul-khaliqin)',
  'd4ce6c3f5d4':
      'Allahumma ba\'id bayni wa bayna khatayaya kama ba\'adta baynal-mashriqi wal-maghrib, Allahumma naqqini min khatayaya kama yunaqqath-thawbul-abyadu minad-danas, Allahummaghsilni min khatayaya bith-thalji wal-ma\'i wal-barad. Subhanaka Allahumma wa bihamdik wa tabarakasmuk wa ta\'ala jadduk wa la ilaha ghayruk. Allahu akbaru kabira, Allahu akbaru kabira, Allahu akbaru kabira, wal-hamdu lillahi kathira, wal-hamdu lillahi kathira, wal-hamdu lillahi kathira, wa subhanallahi bukratan wa asila (thalatha) "a\'udhu billahi minash-shaytani min nafkhihi wa nafthihi wa hamzih".',
  'df26a6e2932':
      'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu yuhyi wa yumitu wa huwa hayyun la yamut, biyadihil-khayru wa huwa \'ala kulli shay\'in qadir (kataba Allahu lahu alfa alfi hasanah, wa maha \'anhu alfa alfi sayyi\'ah, wa rafa\'a lahu alfa alfi darajah, wa fi riwayah: wa bana lahu baytan fil-jannah). Bismillah, Allahumma inni as\'aluka khayra hadhihis-suq, wa khayra ma fiha, wa a\'udhu bika min sharriha wa sharri ma fiha, Allahumma inni a\'udhu bika an usiba biha yaminan fajirah, aw safqatan khasirah.',
  'dfee6653762':
      'Da\' yadaka \'alal-ladhi ta\'allama min jasadika wa qul: bismillah, thalatha, wa qul sab\'a marrat: a\'udhu billahi wa qudratihi min sharri ma ajidu wa uhadhir.',
  'd02c959c055':
      'Yaqulu mithla ma yaqulul-mu\'adhdhin illa fi "hayya \'alas-salah wa hayya \'alal-falah" fa-yaqul: "la hawla wa la quwwata illa billah".',
  'd24a1f6ee2e':
      '\'An Sa\'d ibn Abi Waqqas radiyallahu \'anhu \'anin-nabiyyi salla Allahu \'alayhi wa sallam annahu qal: "man qala hina yasma\'ul-mu\'adhdhin: ashhadu an la ilaha illallahu wahdahu la sharika lah, wa anna Muhammadan \'abduhu wa rasuluh, raditu billahi rabba, wa bi-Muhammadin rasula, wa bil-islami dina, ghufira lahu dhanbuh". Rawahu Muslim.',
  'd981e2c7cf5':
      '\'An Jabir ibn \'Abdillah radiyallahu \'anhuma anna rasulallahi salla Allahu \'alayhi wa sallam qal: "man qala hina yasma\'un-nida\': Allahumma rabba hadhihid-da\'watit-tammah, was-salatil-qa\'imah, ati Muhammadanil-wasilata wal-fadilah, wab\'athhu maqaman mahmudanil-ladhi wa\'adtah, hallat lahu shafa\'ati yawmal-qiyamah". Rawahul-Bukhari.',
  'd64c1a16b8f':
      'Allahumma salli wa sallim wa barik \'ala sayyidina Muhammad. Allahumma rabba hadhihid-da\'watit-tammah, was-salatil-qa\'imah, ati Muhammadanil-wasilata wal-fadilah, wab\'athhu maqaman mahmudanil-ladhi wa\'adtah, innaka la tukhliful-mi\'ad.',
  'db7846c6906':
      'Allahu akbar, Allahu akbar, Allahu akbar, Allahu akbar, ashhadu an la ilaha illallah, ashhadu an la ilaha illallah, ashhadu anna Muhammadan rasulullah, ashhadu anna Muhammadan rasulullah, hayya \'alas-salah, hayya \'alas-salah, hayya \'alal-falah, hayya \'alal-falah, Allahu akbar, Allahu akbar, la ilaha illallah',
  'da69c0ab0bc':
      'Allahu akbar, Allahu akbar, Allahu akbar, Allahu akbar, ashhadu an la ilaha illallah, ashhadu an la ilaha illallah, ashhadu anna Muhammadan rasulullah, ashhadu anna Muhammadan rasulullah, hayya \'alas-salah, hayya \'alas-salah, hayya \'alal-falah, hayya \'alal-falah, as-salatu khayrun minan-nawm, as-salatu khayrun minan-nawm, Allahu akbar, Allahu akbar, la ilaha illallah',
  'd87505e4efd':
      'Allahu akbar, Allahu akbar, ashhadu an la ilaha illallah, ashhadu anna Muhammadan rasulullah, hayya \'alas-salah, hayya \'alal-falah, qad qamatis-salah, qad qamatis-salah, Allahu akbar, Allahu akbar, la ilaha illallah',
  'dba2490a5b3':
      'Allahummaj\'al fi qalbi nura, wa fi lisani nura, waj\'al fi sam\'i nura, waj\'al fi basari nura, waj\'al min khalfi nura, wa min amami nura, waj\'al min fawqi nura, wa min tahti nura. Allahumma a\'tini nura.',
  'da38a6f9e07':
      'Yabda\'u bi-rijlihil-yumna, wa yaqul: a\'udhu billahil-\'Azim, wa bi-wajhihil-karim, wa sultanihil-qadim, minash-shaytanir-rajim, bismillah, was-salatu was-salamu \'ala rasulillah, Allahummaftah li abwaba rahmatik.',
  'dea51c3e0b0':
      'Yabda\'u bi-rijlihil-yusra, wa yaqul: bismillah, was-salatu was-salamu \'ala rasulillah, Allahumma inni as\'aluka min fadlik, Allahumma\'simni minash-shaytanir-rajim.',
  'd47689bfe98': 'Qablal-wudu\': "bismillah".',
  'dfe85fe3808':
      '"Ashhadu an la ilaha illallahu wahdahu la sharika lah, wa ashhadu anna Muhammadan \'abduhu wa rasuluh". "Allahummaj\'alni minat-tawwabina waj\'alni minal-mutatahhirin". "Subhanakallahumma wa bihamdik, ashhadu an la ilaha illa anta, astaghfiruka wa atubu ilayk".',
  'dd850765ff8':
      'Bismillahi walajna, wa bismillahi kharajna, wa \'ala rabbina tawakkalna.',
  'd4942e09ae3':
      'Bismillah, tawakkaltu \'alallah, wa la hawla wa la quwwata illa billah. Allahumma inni a\'udhu bika an adilla aw udall, aw azilla aw uzall, aw azlima aw uzlam, aw ajhala aw yujhala \'alayya.',
  'd64113a3567':
      '(Bismillah) Allahumma inni a\'udhu bika minal-khubthi wal-khaba\'ith.',
  'da7fa9e9bbb': 'Ghufranak.',
  'd0fa1318262':
      'Bismillah. Fa-in nasiya fi awwalihi, fal-yaqul: bismillahi awwalahu wa akhirah.',
  'd90af4b3234': 'Allahumma barik lana fihi, wa zidna minh.',
  'd4d80257dcf':
      'Alhamdu lillahil-ladhi at\'amani hadha, wa razaqanihi min ghayri hawlin minni wa la quwwah. Alhamdu lillahi kathiran tayyiban mubarakan fihi ghayra mukfiyyin wa la muwadda\'in wa la mustaghnan \'anhu rabbana.',
  'd6b54d89195':
      'Allahummarhamni bil-qur\'an, waj\'alhu li imaman wa nuran wa hudan wa rahmah\nAllahumma dhakkirni minhu ma nasit, wa \'allimni minhu ma jahilt, warzuqni tilawatahu ana\'al-layli wa atrafan-nahar, waj\'alhu li hujjatan ya rabbal-\'alamin\nAllahumma aslih li dini alladhi huwa \'ismatu amri, wa aslih li dunyaya allati fiha ma\'ashi, wa aslih li akhirati allati fiha ma\'adi, waj\'alil-hayata ziyadatan li fi kulli khayr, waj\'alil-mawta rahatan li min kulli sharr\nAllahummaj\'al khayra \'umri akhirah, wa khayra \'amali khawatimah, wa khayra ayyami yawma alqaka fih\nAllahumma inni as\'aluka \'ayshatan haniyyah, wa mitatan sawiyyah, wa maradda ghayra mukhzin wa la fadih\nAllahumma inni as\'aluka khayral-mas\'alah, wa khayrad-du\'a\', wa khayran-najah, wa khayral-\'ilm, wa khayral-\'amal, wa khayrath-thawab, wa khayral-hayah, wa khayral-mamat, wa thabbitni, wa thaqqil mawazini, wa haqqiq imani, warfa\' darajati, wa taqabbal salati, waghfir khati\'ati, wa as\'alukal-\'ula minal-jannah\nAllahumma inni as\'aluka mujibati rahmatik, wa \'aza\'ima maghfiratik, was-salamata min kulli ithm, wal-ghanimata min kulli birr, wal-fawza bil-jannah, wan-najata minan-nar\nAllahumma ahsin \'aqibatana fil-umuri kulliha, wa ajirna min khizyid-dunya wa \'adhabil-akhirah\nAllahummaqsim lana min khashyatika ma tahulu bihi baynana wa bayna ma\'siyatik, wa min ta\'atika ma tuballighuna biha jannatak, wa minal-yaqini ma tuhawwinu bihi \'alayna masa\'ibad-dunya, wa matti\'na bi-asma\'ina wa absarina wa quwwatina ma ahyaytana, waj\'alhul-warithu minna, waj\'al tha\'rana \'ala man zalamana, wansurna \'ala man \'adana, wa la taj\'al musibatana fi dinina, wa la taj\'alid-dunya akbara hammina, wa la mablagha \'ilmina, wa la tusallit \'alayna man la yarhamuna\nAllahumma la tada\' lana dhanban illa ghafartah, wa la hamman illa farrajtah, wa la dayna illa qadaytah, wa la hajatan min hawa\'ijid-dunya wal-akhirati illa qadaytaha ya arhamar-rahimin\nRabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina \'adhaban-nar, wa salla Allahu \'ala sayyidina wa nabiyyina Muhammadin wa \'ala alihi wa ashabihil-akhyari wa sallama tasliman kathira.',
  'd8e93665453':
      'Allahummaj\'alhu farathan wa dhukhran li-walidayh, wa shafi\'an mujaba, Allahumma thaqqil bihi mawazinahuma, wa a\'zim bihi ujurahuma, wa alhiqhu bi-salihil-mu\'minin, waj\'alhu fi kafalati Ibrahim, wa qihi bi-rahmatika \'adhabal-jahim, wa abdilhu daran khayran min darih, wa ahlan khayran min ahlih, Allahummaghfir li-aslafina, wa afratina, wa man sabaqana bil-iman.',
  'dee1481a501':
      'Allahummaghfir lahu warhamhu wa \'afihi wa\'fu \'anh, wa akrim nuzulah, wa wassi\' mudkhalah, waghsilhu bil-ma\'i wath-thalji wal-barad, wa naqqihi minal-khataya kama naqqaytath-thawbal-abyada minad-danas, wa abdilhu daran khayran min darih, wa ahlan khayran min ahlih, wa zawjan khayran min zawjih, wa adkhilhul-jannah, wa qihi fitnatal-qabri wa \'adhaban-nar.',
  'dd8489e0460':
      'Bismillahir-Rahmanir-Rahim (1) alhamdu lillahi rabbil-\'alamin (2) ar-Rahmanir-Rahim (3) maliki yawmid-din (4) iyyaka na\'budu wa iyyaka nasta\'in (5) ihdinas-siratal-mustaqim (6) siratal-ladhina an\'amta \'alayhim ghayril-maghdubi \'alayhim wa lad-dallin (7).\nAlif lam mim (1) dhalikal-kitabu la rayba fih, hudan lil-muttaqin (2) alladhina yu\'minuna bil-ghaybi wa yuqimunas-salata wa mimma razaqnahum yunfiqun (3) wal-ladhina yu\'minuna bima unzila ilayka wa ma unzila min qablika wa bil-akhirati hum yuqinun (4) ula\'ika \'ala hudan min rabbihim wa ula\'ika humul-muflihun (5).\nAllahu la ilaha illa huwa, al-Hayyul-Qayyum, la ta\'khudhuhu sinatun wa la nawm, lahu ma fis-samawati wa ma fil-ard, man dhal-ladhi yashfa\'u \'indahu illa bi-idhnih, ya\'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bi-shay\'in min \'ilmihi illa bima sha\', wasi\'a kursiyyuhus-samawati wal-ard, wa la ya\'uduhu hifzuhuma, wa huwal-\'Aliyyul-\'Azim.\nLillahi ma fis-samawati wa ma fil-ard, wa in tubdu ma fi anfusikum aw tukhfuhu yuhasibkum bihillah, fa-yaghfiru liman yasha\'u wa yu\'adhdhibu man yasha\', wallahu \'ala kulli shay\'in qadir (284) amanar-rasulu bima unzila ilayhi min rabbihi wal-mu\'minun, kullun amana billahi wa mala\'ikatihi wa kutubihi wa rusulih, la nufarriqu bayna ahadin min rusulih, wa qalu sami\'na wa ata\'na, ghufranaka rabbana wa ilaykal-masir (285) la yukallifullahu nafsan illa wus\'aha, laha ma kasabat wa \'alayha maktasabat, rabbana la tu\'akhidhna in nasina aw akhta\'na, rabbana wa la tahmil \'alayna isran kama hamaltahu \'alal-ladhina min qablina, rabbana wa la tuhammilna ma la taqata lana bih, wa\'fu \'anna, waghfir lana, warhamna, anta mawlana fansurna \'alal-qawmil-kafirin (286).\nQul ya ayyuhal-kafirun (1) la a\'budu ma ta\'budun (2) wa la antum \'abiduna ma a\'bud (3) wa la ana \'abidun ma \'abadtum (4) wa la antum \'abiduna ma a\'bud (5) lakum dinukum wa liya din (6).\nQul huwa Allahu ahad (1) Allahus-samad (2) lam yalid wa lam yulad (3) wa lam yakun lahu kufuwan ahad (4).\nQul a\'udhu bi-rabbil-falaq (1) min sharri ma khalaq (2) wa min sharri ghasiqin idha waqab (3) wa min sharrin-naffathati fil-\'uqad (4) wa min sharri hasidin idha hasad (5).\nQul a\'udhu bi-rabbin-nas (1) malikin-nas (2) ilahin-nas (3) min sharril-waswasil-khannas (4) alladhi yuwaswisu fi suduri-nnas (5) minal-jinnati wan-nas (6).',
  'd3e7354d5e8':
      'A\'udhu billahil-\'Azim, wa bi-wajhihil-karim, wa sultanihil-qadim, minash-shaytanir-rajim.\nA\'udhu billahi minash-shaytanir-rajim, min hamzihi wa nafkhihi wa nafthih.\nA\'udhu bi-kalimatillahit-tammah, min kulli shaytanin wa hammah, wa min kulli \'aynin lammah.\nA\'udhu bi-kalimatillahit-tammati min sharri ma khalaq.\nBismillahi arqik, min kulli shay\'in yu\'dhik, min sharri kulli nafsin aw \'ayni hasid, Allahu yashfik, bismillahi arqik.\nBismillah (thalatha), a\'udhu billahi wa qudratihi min sharri ma ajidu wa uhadhir (sab\'a marrat).\nAs\'alullahal-\'Azima rabbal-\'arshil-\'azim, an yu\'afiyaka wa yashfiyak.\nAllahumma rabban-nas, adhhibil-ba\'s, washfi, antash-Shafi la shifa\'a illa shifa\'uk, shifa\'an la yughadiru saqama.\nAllahummashfi \'abdak, wa saddaqa rasulak.\nAllahumma barik \'alayh, wa adhhib \'anhu harral-\'ayni wa bardaha wa wasabaha.\nAllahumma inna nas\'aluka min khayri ma sa\'alaka minhu nabiyyuka Muhammadun salla Allahu \'alayhi wa sallam wa na\'udhu bika min sharri ma ista\'adha minhu nabiyyuka Muhammadun salla Allahu \'alayhi wa sallam wa antal-Musta\'an, wa \'alaykal-balagh, wa la hawla wa la quwwata illa billah.\nLa ilaha illallahul-\'Azimul-Halim, la ilaha illallahu rabbul-\'arshil-karim, la ilaha illallahu rabbus-samawati wa rabbul-\'arshil-\'azim.\nRabbunallahul-ladhi fis-sama\', taqaddasa ismuk, amruka fis-sama\'i wal-ard, kama rahmatuka fis-sama\'i faj\'al rahmataka fil-ard, ighfir lana hubana wa khatayana, anta rabbut-tayyibin, anzil rahmatan min rahmatik, wa shifa\'an min shifa\'ik \'ala hadhal-waja\', fa-yabra\'. (thalatha marrat).\nA\'udhu bi-wajhillahil-karim, wa bi-kalimatillahit-tammat, allati la yujawizuhunna barrun wa la fajir, min sharri ma yanzilu minas-sama\'i wa sharri ma ya\'ruju fiha, wa sharri ma dhara\'a fil-ardi wa sharri ma yakhruju minha, wa min fitanil-layli wan-nahar, wa min tawariqil-layli wan-nahar, illa tariqan yatruqu bi-khayrin ya Rahman.\nBismillahil-ladhi la yadurru ma\'asmihi shay\'un fil-ardi wa la fis-sama\'i wa huwas-Sami\'ul-\'Alim. (thalatha marrat).\nA\'udhu bi-kalimatillahit-tammati min ghadabihi wa \'iqabih, wa sharri \'ibadih, wa min hamazatish-shayatin, wa an yahdurun.\nBismillahil-\'Azim, a\'udhu billahil-Kabir min sharri kulli \'irqin na\'ar, wa min sharri harrin-nar.\nBismillahi turbatu ardina, bi-riqati ba\'dina, yushfa saqimuna, bi-idhni rabbina.\nAllahumma inni as\'aluka bi-anna lakal-hamd, la ilaha illa ant, al-Mannan, ya Badi\'as-samawati wal-ard, ya Dhal-jalali wal-ikram, ya Hayyu ya Qayyum.\nAllahumma inni as\'aluka bi-anni ashhadu annaka antallahu la ilaha illa ant, al-Ahad, as-Samad, alladhi lam yalid, wa lam yulad, wa lam yakun lahu kufuwan ahad.\nAs\'alullahal-\'Azima rabbal-\'arshil-\'azim, an yu\'afiyaka wa yashfiyak. (sab\'a marrat).\nAllahumma barrid qalbi bith-thalji wal-barad wal-ma\'il-barid, Allahumma naqqi qalbi minal-khataya kama naqqaytath-thawbal-abyada minad-danas.\nAllahumma inni a\'udhu bi-wajhikal-karim wa kalimatikat-tammati min sharri ma anta akhidhun bi-nasiyatih, Allahumma anta takshiful-maghrama wal-ma\'tham, Allahumma la yuhzamu junduk, wa la yukhlafu wa\'duk, wa la yanfa\'u dhal-jaddi minkal-jadd, subhanaka wa bihamdik.\nBismillahi yubri\'ik, wa min kulli da\'in yashfik, wa min sharri hasidin idha hasad, wa sharri kulli dhi \'ayn.\nAllahummashfi \'abdaka yanka\'u laka \'aduwwan, aw yamshi laka ila salah.\nAllahumma salli \'ala Muhammadin wa \'ala ali Muhammad kama sallayta \'ala Ibrahima wa \'ala ali Ibrahima innaka Hamidun Majid, Allahumma barik \'ala Muhammadin wa \'ala ali Muhammad kama barakta \'ala Ibrahima wa \'ala ali Ibrahima fil-\'alamina innaka Hamidun Majid.',
};
