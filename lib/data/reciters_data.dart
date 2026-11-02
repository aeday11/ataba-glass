import 'models.dart';
import 'rafed_reciters.dart';

/// قاعدة البيانات الأساسية للرواديد الحسينيين.
///
/// تم دمج القائمتين (قائمة `radidAI` وقائمة `allRawadid`) في قائمة موحّدة:
/// - المعرّف الأساسي (`id`) مأخوذ من `allRawadid`.
/// - المعرّفات البديلة (`altIds`) من `ai_id` ليبقى التوافق مع البيانات القديمة.
/// - مفاتيح البحث (`searchKeys`) تجمع النسخ العربية والإنجليزية كلها.
/// - قناة يوتيوب محفوظة عند توفرها.
const List<Reciter> bundledReciters = [
  Reciter(
    id: 'basim_karbalaei',
    imageUrl: 'assets/reciters/basim_karbalaei.jpg',
    nameAr: 'باسم الكربلائي',
    searchKeys: [
      'باسم الكربلائي',
      'Basim Karbalai',
      'Basim Karbalaei',
      'ملا باسم',
    ],
    altIds: ['basim_karbalaei'],
    youtubeChannel: 'UCb7...basim',
  ),
  Reciter(
    id: 'jaleel_karbalaei',
    imageUrl: 'assets/reciters/jaleel_karbalaei.jpg',
    nameAr: 'جليل الكربلائي',
    searchKeys: ['جليل الكربلائي', 'Jalil Karbalai', 'Jaleel Karbalaei'],
    altIds: ['jaleel_karbalaei'],
  ),
  Reciter(
    id: 'nizar_qatari',
    imageUrl: 'assets/reciters/nizar_qatari.jpg',
    nameAr: 'نزار القطري',
    searchKeys: ['نزار القطري', 'Nizar Al Qatari', 'Nizar Qatari'],
    altIds: ['nizar_qatari'],
  ),
  Reciter(
    id: 'hussain_khalil',
    imageUrl: 'assets/reciters/hussain_khalil.jpg',
    nameAr: 'حسين خليل',
    searchKeys: ['حسين خليل', 'Hussain Khaleel', 'Hussain Khalil'],
    altIds: ['hussain_khaleel'],
  ),
  Reciter(
    id: 'muslim_waeli',
    imageUrl: 'assets/reciters/muslim_waeli.jpg',
    nameAr: 'مسلم الوائلي',
    searchKeys: ['مسلم الوائلي', 'Muslim Al Waeli'],
    altIds: ['muslim_waeli'],
  ),
  Reciter(
    id: 'khodor_abbas',
    imageUrl: 'assets/reciters/khodor_abbas.jpg',
    nameAr: 'خضر عباس',
    searchKeys: [
      'خضر عباس',
      'Khuder Abbas',
      'Khodor Abbas',
      'الرادود خضر عباس',
    ],
    altIds: ['khuder_abbas'],
  ),
  Reciter(
    id: 'qahtan_badiri',
    imageUrl: 'assets/reciters/qahtan_badiri.jpg',
    nameAr: 'قحطان البديري',
    searchKeys: ['قحطان البديري', 'Qahtan Al Badiri'],
    altIds: ['qahtan_al_badiri'],
  ),
  Reciter(
    id: 'murtada_harb',
    imageUrl: 'assets/reciters/murtada_harb.jpg',
    nameAr: 'مرتضى حرب',
    searchKeys: ['مرتضى حرب', 'Murtadha Harb', 'Murtada Harb'],
    altIds: ['murtada_harb'],
  ),
  Reciter(
    id: 'sayed_faqed',
    imageUrl: 'assets/reciters/sayed_faqed.jpg',
    nameAr: 'سيد فاقد الموسوي',
    searchKeys: [
      'سيد فاقد الموسوي',
      'سيد فاقد',
      'Sayed Faqid',
      'Sayed Faqad Al Musawi',
    ],
    altIds: ['sayed_faqid_al_musawi'],
  ),
  Reciter(
    id: 'ahmad_fatlawi',
    imageUrl: 'assets/reciters/ahmad_fatlawi.jpg',
    nameAr: 'احمد الفتلاوي',
    searchKeys: ['احمد الفتلاوي', 'أحمد الفتلاوي', 'Ahmed Fatlawi'],
    altIds: ['ahmed_al_fatlawi'],
  ),
  Reciter(
    id: 'ghassan_karbalaei',
    imageUrl: 'assets/reciters/ghassan_karbalaei.jpg',
    nameAr: 'غسان الكربلائي',
    searchKeys: ['غسان الكربلائي', 'Ghassan Karbalai', 'Ghassan Karbalaei'],
    altIds: ['ghassan_karbalaei'],
  ),
  Reciter(
    id: 'haider_bayati',
    imageUrl: 'assets/reciters/haider_bayati.jpg',
    nameAr: 'حيدر البياتي',
    searchKeys: ['حيدر البياتي', 'Haider Al Bayati'],
    altIds: ['haider_al_bayati'],
  ),
  Reciter(
    id: 'jafar_dirazi',
    imageUrl: 'assets/reciters/jafar_dirazi.jpg',
    nameAr: 'جعفر الدرازي',
    searchKeys: ['جعفر الدرازي', 'Jaafar Dirazi', 'Jafar Dirazi'],
  ),
  Reciter(
    id: 'mahdi_aboodi',
    imageUrl: 'assets/reciters/mahdi_aboodi.jpg',
    nameAr: 'مهدي العبودي',
    searchKeys: ['مهدي العبودي', 'Mahdi Al Aboudi'],
    altIds: ['mahdi_al_aboudi'],
  ),
  Reciter(
    id: 'mohammad_bojbara',
    imageUrl: 'assets/reciters/mohammad_bojbara.jpg',
    nameAr: 'محمد بوجبارة',
    searchKeys: ['محمد بوجبارة', 'Mohammed Bojubarah', 'Mohammad Bojbara'],
    altIds: ['mohammed_bojubarah'],
  ),
  Reciter(
    id: 'karrar_karbalaei',
    imageUrl: 'assets/reciters/karrar_karbalaei.jpg',
    nameAr: 'كرار الكربلائي',
    searchKeys: ['كرار الكربلائي', 'Karrar Karbalai'],
  ),
  Reciter(
    id: 'hussain_akraf',
    imageUrl: 'assets/reciters/hussain_akraf.jpg',
    nameAr: 'حسين الأكرف',
    searchKeys: ['حسين الأكرف', 'حسين الاكرف', 'Hussain Al Akraf'],
    altIds: ['hussain_al_akraf'],
  ),
  Reciter(
    id: 'hashim_battat',
    imageUrl: 'assets/reciters/hashim_battat.jpg',
    nameAr: 'سيد هشام البطاط',
    searchKeys: ['سيد هشام البطاط', 'هشام البطاط', 'Hashim Battat'],
  ),
  Reciter(
    id: 'ali_dalfi',
    imageUrl: 'assets/reciters/ali_dalfi.jpg',
    nameAr: 'علي الدلفي',
    searchKeys: ['علي الدلفي', 'Ali Dalfi'],
  ),
  Reciter(
    id: 'mustafa_aboodi',
    imageUrl: 'assets/reciters/mustafa_aboodi.jpg',
    nameAr: 'مصطفى العبودي',
    searchKeys: ['مصطفى العبودي', 'Mustafa Aboudi'],
  ),
  Reciter(
    id: 'mohammad_hujeirat',
    imageUrl: 'assets/reciters/mohammad_hujeirat.jpg',
    nameAr: 'محمد الحجيرات',
    searchKeys: ['محمد الحجيرات', 'Mohammad Hujeirat'],
  ),
  Reciter(
    id: 'haider_attar',
    imageUrl: 'assets/reciters/haider_attar.jpg',
    nameAr: 'حيدر العطار',
    searchKeys: ['حيدر العطار', 'Haider Attar'],
  ),
  Reciter(
    id: 'aqeel_kaabi',
    imageUrl: 'assets/reciters/aqeel_kaabi.jpg',
    nameAr: 'عقيل الكعبي',
    searchKeys: ['عقيل الكعبي', 'Aqeel Kaabi'],
  ),
  Reciter(
    id: 'jafar_qashami',
    imageUrl: 'assets/reciters/jafar_qashami.jpg',
    nameAr: 'جعفر القشعمي',
    searchKeys: ['جعفر القشعمي', 'Jafar Qashami'],
  ),
  Reciter(
    id: 'ihab_malki',
    imageUrl: 'assets/reciters/ihab_malki.jpg',
    nameAr: 'ايهاب المالكي',
    searchKeys: ['ايهاب المالكي', 'إيهاب المالكي', 'Ihab Malki'],
  ),

  // ضيوف المواليد واللطميات الجدد.
  Reciter(
    id: 'sayed_salam_alhusayni',
    imageUrl: 'assets/reciters/sayed_salam_alhusayni.jpg',
    nameAr: 'السيد سلام الحسيني',
    searchKeys: [
      'السيد سلام الحسيني',
      'سيد سلام الحسيني',
      'سلام الحسيني',
      'Sayed Salam Al Husayni',
    ],
  ),
  Reciter(
    id: 'jbar_alhrishawi',
    imageUrl: 'assets/reciters/jbar_alhrishawi.jpg',
    nameAr: 'جبار الحريشاوي',
    searchKeys: ['جبار الحريشاوي', 'جبار الحراشاوي', 'Jbar Alhrishawi'],
  ),
  Reciter(
    id: 'haider_alfreiji',
    imageUrl: 'assets/reciters/haider_alfreiji.jpg',
    nameAr: 'حيدر الفريجي',
    searchKeys: ['حيدر الفريجي', 'Haider Alfreiji'],
  ),

  // رواديد جدد من موقع «يا حسين» (yahosein.com — قسم اللطميات).
  Reciter(
    id: 'hassan_karbalaei',
    imageUrl: 'assets/reciters/hassan_karbalaei.jpg',
    nameAr: 'حسن الكربلائي',
    searchKeys: ['حسن الكربلائي', 'حسين الكربلائي', 'Hassan Karbalai'],
  ),
  Reciter(
    id: 'nusrat_qshqsh',
    imageUrl: 'assets/reciters/nusrat_qshqsh.jpg',
    nameAr: 'السيد نصرات قشاقش',
    searchKeys: ['نصرات قشاقش', 'السيد نصرات قشاقش', 'نصرت قشاقش', 'السيد نصرت قشاقش', 'Nusrat Qshqsh'],
  ),
  Reciter(
    id: 'saleh_dirazi',
    imageUrl: 'assets/reciters/saleh_dirazi.jpg',
    nameAr: 'صالح الدرازي',
    searchKeys: ['صالح الدرازي', 'Saleh Al Dirazi'],
  ),
  Reciter(
    id: 'rawadid_mix',
    nameAr: 'مجموعة من الرواديد',
    searchKeys: ['مجموعة من الرواديد', 'مجموعة الرواديد'],
  ),
  Reciter(
    id: 'abdulamir_biladi',
    imageUrl: 'assets/reciters/abdulamir_biladi.jpg',
    nameAr: 'عبد الأمير البلادي',
    searchKeys: ['عبد الأمير البلادي', 'عبد الامير البلادي', 'عبد الأمير البلداوي', 'Abdulamir Biladi'],
  ),
  Reciter(
    id: 'abudhar_halwaji',
    imageUrl: 'assets/reciters/abudhar_halwaji.jpg',
    nameAr: 'أبو ذر الحلواجي',
    searchKeys: ['أبو ذر الحلواجي', 'اباذر الحلواجي', 'Abudhar Halwaji'],
  ),
  Reciter(
    id: 'ali_alasideed',
    imageUrl: 'assets/reciters/ali_alasideed.jpg',
    nameAr: 'علي العضيد',
    searchKeys: ['علي العضيد', 'علي العضد', 'Ali Al Asideed'],
  ),
  Reciter(
    id: 'ali_shubber',
    imageUrl: 'assets/reciters/ali_shubber.jpg',
    nameAr: 'السيد علي شبر',
    searchKeys: ['علي شبر', 'السيد علي شبر', 'Ali Shubber'],
  ),
  Reciter(
    id: 'hassan_eissa',
    imageUrl: 'assets/reciters/hassan_eissa.jpg',
    nameAr: 'حسن عيسى',
    searchKeys: ['حسن عيسى', 'Hassan Eissa'],
  ),
  Reciter(
    id: 'hussain_kazim',
    imageUrl: 'assets/reciters/hussain_kazim.jpg',
    nameAr: 'حسين كاظم',
    searchKeys: ['حسين كاظم', 'Hussain Kazim'],
  ),
  Reciter(
    id: 'jafar_sahwan',
    imageUrl: 'assets/reciters/jafar_sahwan.jpg',
    nameAr: 'جعفر سهوان',
    searchKeys: ['جعفر سهوان', 'Jafar Sahwan'],
  ),
  Reciter(
    id: 'mohammad_alhusayni',
    imageUrl: 'assets/reciters/mohammad_alhusayni.jpg',
    nameAr: 'السيد محمد الحسيني',
    searchKeys: ['محمد الحسيني', 'السيد محمد الحسيني', 'Mohammad Al Husayni'],
  ),
  Reciter(
    id: 'saleh_almomen',
    imageUrl: 'assets/reciters/saleh_almomen.jpg',
    nameAr: 'صالح المؤمن',
    searchKeys: ['صالح المؤمن', 'Saleh Al Momen'],
  ),
  Reciter(
    id: 'yousef_alromi',
    imageUrl: 'assets/reciters/yousef_alromi.jpg',
    nameAr: 'يوسف الرومي',
    searchKeys: ['يوسف الرومي', 'Yousef Al Romi'],
  ),
  Reciter(
    id: 'hamza_alzagheer',
    imageUrl: 'assets/reciters/hamza_alzagheer.jpg',
    nameAr: 'حمزة الصغير',
    searchKeys: ['حمزة الصغير', 'حمزة الزغير', 'Hamza Alzagheer'],
  ),
  Reciter(
    id: 'abu_bashir_alnajafi',
    imageUrl: 'assets/reciters/abu_bashir_alnajafi.jpg',
    nameAr: 'أبو بشير النجفي',
    searchKeys: ['أبو بشير النجفي', 'ابو بشير النجفي', 'Abu Bashir Alnajafi'],
  ),
  Reciter(
    id: 'abdulriza_alnajafi',
    imageUrl: 'assets/reciters/abdulriza_alnajafi.jpg',
    nameAr: 'عبد الرضا النجفي',
    searchKeys: ['عبد الرضا النجفي', 'عبد الرضا', 'Abdulriza Alnajafi'],
  ),
  Reciter(
    id: 'mohammad_alhujurat',
    imageUrl: 'assets/reciters/mohammad_alhujurat.jpg',
    nameAr: 'محمد الحجيرات',
    searchKeys: ['محمد الحجيرات', 'الحاج محمد الحجيرات', 'Mohammad Alhujurat'],
  ),

  // رواديد مضافون من شبكة رافد (rafed.net) — يُولَّدون آلياً.
  ...rafedReciters,
];
