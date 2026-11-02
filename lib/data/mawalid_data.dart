import '../core/utils.dart';
import 'mawalid_extra_generated.dart';
import 'mawalid_generated.dart';
import 'models.dart';
import 'reciters_data.dart';

/// رادد (أو فرقة) في فهرس المواليد — مُرتَّب حسب بلده.
class MawalidReciter {
  const MawalidReciter(this.nameAr, {this.cityAr, this.searchKeys = const []});

  /// الاسم المعروض.
  final String nameAr;

  /// البلد/المدينة الفرعية (كربلاء، بغداد، الدراز...) وتُعرض تحت الاسم.
  final String? cityAr;

  /// مفاتيح بحث إضافية (ألقاب، أسماء بديلة، كتابة لاتينية).
  final List<String> searchKeys;
}

/// مجموعة بلد كامل من فهرس المواليد.
class MawalidGroup {
  const MawalidGroup({
    required this.title,
    required this.flag,
    required this.reciters,
    this.note,
  });

  final String title;
  final String flag;

  /// سطر توضيحي صغير تحت اسم البلد.
  final String? note;

  final List<MawalidReciter> reciters;
}

/// يربط اسم الرادد بملف أبتهالات مواليد المضمّنة (`assets/library/mw_*.json`).
///
/// ملاحظة جوهرية: مفتاح النتيجة يبدأ دائماً بـ `mw_` كي تُحمَّل أبتهالات
/// وأهازيج الفرح من المواليد — لا مجالس الرثاء الواردة في المكتبة العامة.
/// نأخذ صورة الرادد الشخصية من المكتبة المضمّنة إن وُجدت للعرض فقط.
Reciter resolveMawalidReciter(MawalidReciter m) {
  String norm(String s) => AppUtils.normalize(s);
  final target = norm(m.nameAr);

  // ابحث عن نسخة الرادد في المكتبة لأخذ صورته الشخصية.
  String? imageUrl;
  for (final r in bundledReciters) {
    if (norm(r.nameAr) == target) {
      imageUrl = r.imageUrl;
      break;
    }
    var hit = false;
    for (final k in r.searchKeys) {
      if (norm(k) == target) {
        hit = true;
        break;
      }
    }
    if (hit) {
      imageUrl = r.imageUrl;
      break;
    }
  }
  if (imageUrl == null) {
    for (final r in bundledReciters) {
      final rn = norm(r.nameAr);
      if (rn.contains(target) || target.contains(rn)) {
        imageUrl = r.imageUrl;
        break;
      }
    }
  }

  return Reciter(
    // مفتاح ASCII من الخريطة المولَّدة إن توفرت أبتهالات لهذا الرادد،
    // وإلا مفتاح غير قابل للتحميل (tُرجع فارغاً من المكتبة).
    id: mawalidFileKeyByName[target] ?? 'mw_un_$target',
    nameAr: m.nameAr,
    searchKeys: [
      ...m.searchKeys,
      if (m.cityAr != null) m.cityAr!,
    ],
    imageUrl: imageUrl,
  );
}

/// هل توفرت أبتهالات مواليد فعلية لهذا الرادد في المكتبة؟
bool isPlayableMawalid(Reciter reciter) => mawalidPlayableIds.contains(reciter.id);

/// عدد أبتهالات المواليد المتوفرة للرادد (0 إن لم تتوفر).
int mawalidCountOf(Reciter reciter) => mawalidCounts[reciter.id] ?? 0;

/// القائمة المنسَّقة يدوياً: أسماء بشرية دقيقة ومدن لكل رادد.
///
/// لا يُدرج هنا رادد بلا أبتهال موثّقة — كل من في هذا الفهرس مُحمَّل فعلاً
/// من shiavoice؛ وكل رادد تعذّر إيجاد أبتهاله حُذف بدل أن يعرض «قريباً».
const List<MawalidGroup> _curatedGroups = <MawalidGroup>[  // ------------------------------------------------------------------ العراق
  MawalidGroup(
    title: 'العراق',
    flag: '🇮🇶',
    note: 'قلب المواليد وأرض المنبر الحسيني',
    reciters: [
      MawalidReciter('باسم الكربلائي', cityAr: 'كربلاء', searchKeys: [
        'ملا باسم',
        'Basim Karbalai',
      ]),
      MawalidReciter('جليل الكربلائي', cityAr: 'كربلاء'),
      MawalidReciter('حمزة الزغير', cityAr: 'كربلاء', searchKeys: ['حمزة الصغير']),
      MawalidReciter('ياسين الرميثي', cityAr: 'الرميثة'),
      MawalidReciter('جاسم النويني', cityAr: 'النجف'),
      MawalidReciter('كاظم القابجي', cityAr: 'بغداد'),
      MawalidReciter('مهدي العبودي', cityAr: 'بغداد'),
      MawalidReciter('خضر عباس', cityAr: 'كربلاء'),
      MawalidReciter('قحطان البديري', cityAr: 'كربلاء', searchKeys: ['ملأ قحطان']),
      MawalidReciter('حيدر البياتي', cityAr: 'بغداد'),
      MawalidReciter('عمار الكناني', cityAr: 'الكوفة'),
      MawalidReciter('علي الوائلي', cityAr: 'كربلاء'),
      MawalidReciter('أحمد الفتلاوي', cityAr: 'كربلاء'),
      MawalidReciter('عباس السعيدي', cityAr: 'كربلاء'),
      MawalidReciter('لؤي البغدادي', cityAr: 'بغداد'),
      MawalidReciter('مصطفى السوداني', cityAr: 'بغداد'),
      MawalidReciter('سيد فاقد الموسوي', cityAr: 'كربلاء', searchKeys: ['سيد فاقد']),
      MawalidReciter('محمد الحلفي', cityAr: 'كربلاء'),
      MawalidReciter('ملا جليل الكربلائي', cityAr: 'كربلاء'),
      MawalidReciter('أبو بشير النجفي', cityAr: 'النجف'),
      MawalidReciter('أحمد الباوي', cityAr: 'بغداد'),
      MawalidReciter('علي باشا الكربلائي', cityAr: 'كربلاء'),
      MawalidReciter('مسلم الوائلي', cityAr: 'كربلاء'),
      MawalidReciter('مرتضى حرب', cityAr: 'كربلاء'),
      MawalidReciter('حسين خليل', cityAr: 'كربلاء'),
      MawalidReciter('غسان الكربلائي', cityAr: 'كربلاء'),
      MawalidReciter('كرار الكربلائي', cityAr: 'كربلاء'),
      MawalidReciter('عقيل الكعبي', cityAr: 'كربلاء'),
      MawalidReciter('محمد الحجيرات', cityAr: 'كربلاء'),
      MawalidReciter('علي الدلفي', cityAr: 'كربلاء'),
      MawalidReciter('مصطفى العبودي', cityAr: 'بغداد'),
      MawalidReciter('حيدر العطار', cityAr: 'كربلاء'),
    ],
  ),

  // ----------------------------------------------------------------- البحرين
  MawalidGroup(
    title: 'البحرين',
    flag: '🇧🇭',
    note: 'مدرسة تعدد الألحان والإيقاعات',
    reciters: [
      MawalidReciter('أباذر الحلواجي', cityAr: 'المنامة', searchKeys: [
        'اباذر الحلواجي',
        'ملك المواليد',
      ]),
      MawalidReciter('حسين الأكرف', cityAr: 'الدراز', searchKeys: ['الاكرف']),
      MawalidReciter('عبدالأمير البلادي', cityAr: 'المنامة',
          searchKeys: ['عبد الامير البلادي']),
      MawalidReciter('جعفر القشعمي', cityAr: 'المحرق'),
      MawalidReciter('صالح الدرازي', cityAr: 'الدراز'),
      MawalidReciter('جعفر الدرازي', cityAr: 'الدراز'),
      MawalidReciter('مهدي سهوان', cityAr: 'السنابس'),
      MawalidReciter('علي حمادي', cityAr: 'البحرين'),
      MawalidReciter('سيد هاني الوداعي', cityAr: 'البحرين'),
      MawalidReciter('مرتضى الحلواجي', cityAr: 'المنامة'),
      MawalidReciter('سيد شرف الستراوي', cityAr: 'سترة'),
      MawalidReciter('سيد ناصر شرف', cityAr: 'البحرين'),
      MawalidReciter('أحمد الأكرف', cityAr: 'الدراز'),
      MawalidReciter('عبدالله المسيح', cityAr: 'البحرين'),
    ],
  ),

  // ----------------------------------------------------------------- الكويت
  MawalidGroup(
    title: 'الكويت',
    flag: '🇰🇼',
    note: 'رواديد المآتم والحفلات الولائية',
    reciters: [
      MawalidReciter('علي مهدي', cityAr: 'الكويت'),
      MawalidReciter('حسين العريان', cityAr: 'الكويت'),
      MawalidReciter('حسن شناوة', cityAr: 'الكويت'),
      MawalidReciter('سيد وليد المزيدي', cityAr: 'الكويت'),
      MawalidReciter('طاهر الشمالي', cityAr: 'الكويت'),
      MawalidReciter('صلاح الرمضان', cityAr: 'الكويت'),
      MawalidReciter('علي دشتي', cityAr: 'الكويت'),
      MawalidReciter('سيد علي الموسوي', cityAr: 'الكويت'),
      MawalidReciter('فيصل المطوع', cityAr: 'الكويت'),
      MawalidReciter('أحمد الساعدي', cityAr: 'الكويت'),
    ],
  ),

  // ----------------------------------------------------------------- لبنان
  MawalidGroup(
    title: 'لبنان',
    flag: '🇱🇧',
    note: 'رواديد الجنوب وأصحاب الألحان الولائية',
    reciters: [
      MawalidReciter('محمد بوجبارة', cityAr: 'صور', searchKeys: ['الملامحمد بوجبارة']),
      MawalidReciter('علي مهنا', cityAr: 'لبنان'),
    ],
  ),

  // ----------------------------------------------------------------- إيران
  MawalidGroup(
    title: 'إيران',
    flag: '🇮🇷',
    note: 'رواديد المدائح بالعربية والفارسية',
    reciters: [
      MawalidReciter('محمود كريمي', cityAr: 'طهران'),
      MawalidReciter('حامد شاكر نجاد', cityAr: 'طهران'),
      MawalidReciter('سيد مجيد بني فاطمة', cityAr: 'مشهد'),
      MawalidReciter('مهدي ميرداماد', cityAr: 'طهران'),
    ],
  ),

  // -------------------------------------------------------------- السعودية
  MawalidGroup(
    title: 'السعودية',
    flag: '🇸🇦',
    note: 'منطقة الأحساء والقطيف',
    reciters: [
      MawalidReciter('وجدي المليفي', cityAr: 'القطيف'),
      MawalidReciter('يوسف الجميعي', cityAr: 'السعودية'),
      MawalidReciter('صالح المؤمن', cityAr: 'السعودية'),
      MawalidReciter('هاني محفوظ', cityAr: 'الأحساء'),
      MawalidReciter('حسين الرمضان', cityAr: 'السعودية'),
      MawalidReciter('أبو حسن الأحسائي', cityAr: 'الأحساء'),
      MawalidReciter('السيد محمد المكي', cityAr: 'السعودية'),
      MawalidReciter('فتحي الباذر', cityAr: 'الأحساء'),
      MawalidReciter('سيد قاسم الشخص', cityAr: 'السعودية'),
      MawalidReciter('مالك إبراهيم', cityAr: 'السعودية'),
    ],
  ),

  // ------------------------------------------------- الخليج وسوريا ومتفرقة
  MawalidGroup(
    title: 'قطر وسوريا',
    flag: '🌐',
    note: 'رواديد متفرقون',
    reciters: [
      MawalidReciter('نزار القطري', cityAr: 'قطر', searchKeys: ['ملا نزار']),
      MawalidReciter('عيسى العيسى', cityAr: 'سوريا'),
    ],
  ),

  // -------------------------------------------------------- الفرق الإنشادية
  MawalidGroup(
    title: 'فرق إنشادية',
    flag: '🎗️',
    note: 'فرق متخصصة بالمواليد والأفراح',
    reciters: [
      MawalidReciter('فرقة النغمات الولائية', cityAr: 'شاملة',
          searchKeys: ['النغمات الولائية']),
      MawalidReciter('فرقة الولاية', cityAr: 'الكويت'),
      MawalidReciter('فرقة الإمام المنتظر', cityAr: 'شاملة'),
    ],
  ),
];

/// عنوان ← علم وملاحظة لبلدان لا تملك مجموعة منسَّقة.
const Map<String, List<String>> _extraGroupMeta = <String, List<String>>{
  'متفرقة': <String>['🌐', 'رواديد من فهرس أفراح shiavoice بلا بيانات بلد'],
};

/// الرواديد الجدد (من `mawalidExtraRows`) مجمّعين حسب البلد.
final Map<String, List<MawalidReciter>> _extrasGrouped = _groupExtras();

Map<String, List<MawalidReciter>> _groupExtras() {
  final out = <String, List<MawalidReciter>>{};
  for (final row in mawalidExtraRows) {
    if (row.length < 2) continue;
    out.putIfAbsent(row[1], () => <MawalidReciter>[]).add(
          MawalidReciter(
            row[0],
            cityAr: row.length > 2 && row[2].isNotEmpty ? row[2] : null,
          ),
        );
  }
  return out;
}

final Set<String> _curatedTitles = {for (final g in _curatedGroups) g.title};

/// الفهرس الشامل لرواديد وفرق المواليد، مُرتَّباً حسب البلدان.
///
/// يجمع القائمة المنسَّقة أعلاه مع رواديد فهرس `afrah` الجدد
/// (`mawalidExtraRows`) الذين تسحب أبتهالاتهم فعلياً — فلا تُدرج بطاقة
/// بلا مقطع. كل بطاقة هنا قابلة للتشغيل: ما تعذّر إيجاده حُذف.
List<MawalidGroup> get mawalidGroups => <MawalidGroup>[
      for (final g in _curatedGroups)
        MawalidGroup(
          title: g.title,
          flag: g.flag,
          note: g.note,
          reciters: <MawalidReciter>[
            ...g.reciters,
            ...(_extrasGrouped[g.title] ?? const <MawalidReciter>[]),
          ],
        ),
      for (final e in _extrasGrouped.entries)
        if (!_curatedTitles.contains(e.key))
          MawalidGroup(
            title: e.key,
            flag: _extraGroupMeta[e.key]?[0] ?? '🌍',
            note: _extraGroupMeta[e.key]?[1] ?? 'رواديد من فهرس أفراح shiavoice',
            reciters: e.value,
          ),
    ];
