import 'package:flutter/foundation.dart' show immutable;

/// محافظة عراقية بإحداثيات مركزها (تُستخدم لحساب المواقيت والقبلة).
@immutable
class Governorate {
  const Governorate({
    required this.id,
    required this.nameAr,
    required this.lat,
    required this.lng,
    this.seatAr = '',
  });

  final String id;
  final String nameAr;

  /// إحداثيات مدينة المركز.
  final double lat;
  final double lng;

  /// مركز المحافظة (يُعرض تحت الاسم).
  final String seatAr;
}

/// كل محافظات العراق (١٩ محافظة) — اختر محافظتك لضبط المواقيت والقبلة.
const List<Governorate> iraqGovernorates = [
  Governorate(
    id: 'karbala',
    nameAr: 'كربلاء',
    seatAr: 'كربلاء المقدسة',
    lat: 32.6160,
    lng: 44.0249,
  ),
  Governorate(
    id: 'baghdad',
    nameAr: 'بغداد',
    seatAr: 'العاصمة',
    lat: 33.3152,
    lng: 44.3661,
  ),
  Governorate(
    id: 'najaf',
    nameAr: 'النجف',
    seatAr: 'النجف الأشرف',
    lat: 32.0003,
    lng: 44.3167,
  ),
  Governorate(
    id: 'basra',
    nameAr: 'البصرة',
    seatAr: 'البصرة',
    lat: 30.5085,
    lng: 47.7804,
  ),
  Governorate(
    id: 'erbil',
    nameAr: 'أربيل',
    lat: 36.1901,
    lng: 44.0091,
  ),
  Governorate(
    id: 'mosul',
    nameAr: 'الموصل',
    seatAr: 'نينوى — الموصل',
    lat: 36.3489,
    lng: 43.1577,
  ),
  Governorate(
    id: 'sulaymaniyah',
    nameAr: 'السليمانية',
    lat: 35.5634,
    lng: 45.4353,
  ),
  Governorate(
    id: 'kirkuk',
    nameAr: 'كركوك',
    lat: 35.4681,
    lng: 44.3922,
  ),
  Governorate(
    id: 'anbar',
    nameAr: 'الأنبار',
    seatAr: 'الرمادي',
    lat: 33.3782,
    lng: 43.3022,
  ),
  Governorate(
    id: 'babel',
    nameAr: 'بابل',
    seatAr: 'الحلة',
    lat: 32.4680,
    lng: 44.4314,
  ),
  Governorate(
    id: 'wasit',
    nameAr: 'واسط',
    seatAr: 'الكوت',
    lat: 32.5117,
    lng: 45.8108,
  ),
  Governorate(
    id: 'diyala',
    nameAr: 'ديالى',
    seatAr: 'بعقوبة',
    lat: 33.8117,
    lng: 44.6526,
  ),
  Governorate(
    id: 'maysan',
    nameAr: 'ميسان',
    seatAr: 'العمارة',
    lat: 31.8356,
    lng: 47.1503,
  ),
  Governorate(
    id: 'dhikar',
    nameAr: 'ذي قار',
    seatAr: 'الناصرية',
    lat: 31.0375,
    lng: 46.2572,
  ),
  Governorate(
    id: 'qadisiyah',
    nameAr: 'القادسية',
    seatAr: 'الديوانية',
    lat: 32.0085,
    lng: 44.9436,
  ),
  Governorate(
    id: 'salahaddin',
    nameAr: 'صلاح الدين',
    seatAr: 'تكريت',
    lat: 34.6071,
    lng: 43.6772,
  ),
  Governorate(
    id: 'muthanna',
    nameAr: 'المثنى',
    seatAr: 'السماوة',
    lat: 31.3194,
    lng: 45.2769,
  ),
  Governorate(
    id: 'duhok',
    nameAr: 'دهوك',
    lat: 36.8670,
    lng: 42.9977,
  ),
  Governorate(
    id: 'halabja',
    nameAr: 'حلبجة',
    lat: 35.1771,
    lng: 45.9870,
  ),
];

/// البحث بمعرّف المحافظة.
Governorate? governorateById(String id) {
  for (final g in iraqGovernorates) {
    if (g.id == id) return g;
  }
  return null;
}
