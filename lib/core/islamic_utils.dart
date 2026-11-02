import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;
import 'package:intl/intl.dart';

/// حسابات إسلامية لواجهة العتبة: مواقيت الصلاة، اتجاه القبلة، التاريخ الهجري،
/// والزيارة اليومية — كلها محلياً بدون إنترنت.
@immutable
class IslamicUtils {
  const IslamicUtils._();

  /// إحداثيات كربلاء المقدسة (الموقع الافتراضي للتطبيق).
  static const double karbalaLat = 32.6160;
  static const double karbalaLng = 44.0249;

  /// إحداثيات الكعبة المشرّفة.
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  /// توقيت العراق: UTC+3 طوال السنة.
  static const int baghdadOffsetHours = 3;

  static const List<String> prayerNames = [
    'الفجر',
    'الشروق',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];

  /// مواقيت اليوم في الموقع المحدّد بتوقيت بغداد (ستّة أوقات بالترتيب أعلاه).
  /// الافتراضي: كربلاء المقدسة.
  static List<DateTime> todayPrayerTimes([
    DateTime? now,
    double lat = karbalaLat,
    double lng = karbalaLng,
  ]) {
    final local = (now ?? DateTime.now())
        .toUtc()
        .add(const Duration(hours: baghdadOffsetHours));
    return _prayTimes(local.year, local.month, local.day, lat, lng);
  }

  /// الصلاة القادمة: (الاسم، الوقت، المتبقي) حسب الموقع المحدّد.
  static ({String name, DateTime time, Duration remaining}) nextPrayer([
    DateTime? now,
    double lat = karbalaLat,
    double lng = karbalaLng,
  ]) {
    final local = (now ?? DateTime.now())
        .toUtc()
        .add(const Duration(hours: baghdadOffsetHours));
    final times = todayPrayerTimes(now, lat, lng);

    // نتجاهل الشروق في عدّاد الأذان.
    final candidates = <(int, DateTime)>[
      (0, times[0]),
      (2, times[2]),
      (3, times[3]),
      (4, times[4]),
      (5, times[5]),
    ];
    for (final (index, time) in candidates) {
      if (time.isAfter(local)) {
        return (
          name: prayerNames[index],
          time: time,
          remaining: time.difference(local),
        );
      }
    }
    // بعد العشاء: الأذان القادم هو فجر الغد.
    final tomorrow = _prayTimes(
      local.year,
      local.month,
      local.day + 1,
      lat,
      lng,
    )[0];
    return (
      name: prayerNames[0],
      time: tomorrow,
      remaining: tomorrow.difference(local),
    );
  }

  /// اتجاه القبلة بالدرجات من الشمال في الموقع المحدّد.
  static double qiblaBearing({
    double lat = karbalaLat,
    double lng = karbalaLng,
  }) {
    final phi = lat * math.pi / 180;
    final delta = kaabaLat * math.pi / 180;
    final dLng = (kaabaLng - lng) * math.pi / 180;
    final y = math.sin(dLng);
    final x = math.cos(phi) * math.tan(delta) - math.sin(phi) * math.cos(dLng);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  /// المسافة التقريبية إلى الكعبة المشرّفة بالكيلومتر (دائرة كبيرة).
  static double distanceToKaaba({
    double lat = karbalaLat,
    double lng = karbalaLng,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _rad(kaabaLat - lat);
    final dLng = _rad(kaabaLng - lng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(kaabaLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(a));
  }

  /// التاريخ الهجري (أم القرى) بخط عربي.
  static String hijriDate([DateTime? now]) {
    final local = (now ?? DateTime.now())
        .toUtc()
        .add(const Duration(hours: baghdadOffsetHours));
    try {
      return DateFormat('d MMMM yyyy', 'ar_SA-u-ca-islamic-umalqura')
          .format(local);
    } catch (_) {
      return '';
    }
  }

  /// اسم اليوم بالعربية (الجمعة، السبت...).
  static String weekdayName([DateTime? now]) {
    final local = (now ?? DateTime.now())
        .toUtc()
        .add(const Duration(hours: baghdadOffsetHours));
    try {
      return DateFormat('EEEE', 'ar').format(local);
    } catch (_) {
      const names = [
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ];
      return names[local.weekday % 7];
    }
  }

  /// هل هو ليلة الجمعة؟ (الخميس بعد المغرب والجمعة).
  static bool isFridayEve([DateTime? now]) {
    final local = (now ?? DateTime.now())
        .toUtc()
        .add(const Duration(hours: baghdadOffsetHours));
    return local.weekday == DateTime.friday ||
        (local.weekday == DateTime.thursday && local.hour >= 17);
  }

  /// الزيارة اليومية — تدور حسب يوم السنة.
  static const List<String> dailyZiyarat = [
    'زيارة عاشوراء',
    'زيارة عرفة',
    'زيارة الأربعين',
    'زيارة كربلاء المقدسة',
    'زيارة النجف الأشرف',
    'زيارة الكاظمين الشريفين',
    'زيارة السماوة',
    'زيارة الحسين والعباس',
  ];

  static String dailyZiyaratFor([DateTime? now]) {
    final local = (now ?? DateTime.now())
        .toUtc()
        .add(const Duration(hours: baghdadOffsetHours));
    final day = int.parse(
      DateFormat('D', 'en_US').format(local),
    );
    return dailyZiyarat[day % dailyZiyarat.length];
  }

  // -------------------------------------------------------------------------
  // الخوارزمية: مبنية على معادلات PrayTimes.org المبسّطة.
  // -------------------------------------------------------------------------
  static List<DateTime> _prayTimes(
    int year,
    int month,
    int day,
    double lat,
    double lng,
  ) {
    // تقويم يولياني مُجزّأ.
    final jDate = _julian(year, month, day) - lng / (15 * 24);

    final decl = _sunPosition(jDate).$1;
    final eqt = _sunPosition(jDate).$2;

    // الظهر: 12:00 شمسياً مصحّحاً.
    final dhuhr = 12.0 + baghdadOffsetHours - lng / 15 - eqt / 60;

    final fajr = dhuhr - _hourAngle(18.0, decl, lat);
    final sunrise = dhuhr - _hourAngle(0.833, decl, lat);
    final asr = dhuhr + _asrHourAngle(decl, lat);
    final maghrib = dhuhr + _hourAngle(0.833, decl, lat);
    final isha = dhuhr + _hourAngle(17.0, decl, lat);

    DateTime at(double hours) {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      var dt = DateTime(year, month, day, h, m);
      // تصحيح تجاوز الدقائق إلى الساعة التالية.
      if (m == 60) dt = dt.add(const Duration(hours: 1));
      return dt;
    }

    return [
      at(fajr),
      at(sunrise),
      at(dhuhr),
      at(asr),
      at(maghrib),
      at(isha),
    ];
  }

  static double _julian(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  /// (الانحراف الميلي للشمس، معادلة الزمن بالدقائق).
  static (double, double) _sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * math.sin(_rad(g)) +
        0.020 * math.sin(_rad(2 * g)));
    final e = 23.439 - 0.00000036 * d;
    final decl = _deg(math.asin(math.sin(_rad(e)) * math.sin(_rad(l))));
    var eqt = (q / 15) - _fixHour(_deg(math.atan2(
            math.cos(_rad(e)) * math.sin(_rad(l)), math.cos(_rad(l)))) /
        15);
    eqt = _fixHour(eqt);
    if (eqt > 12) eqt -= 24;
    return (decl, eqt * 60);
  }

  /// عدد الساعات من الظهر لزاوية شمسية معيّنة (أو العكس إذا ccw).
  static double _hourAngle(double angle, double decl, double lat) {
    final cosH = (-_sinDeg(angle) - _sinDeg(decl) * _sinDeg(lat)) /
        (_cosDeg(decl) * _cosDeg(lat));
    if (cosH.abs() > 1) return 0;
    return _deg(math.acos(cosH)) / 15;
  }

  /// زاوية العصر (عامل ظل الشافعي = 1).
  static double _asrHourAngle(double decl, double lat) {
    final delta = (lat - decl).abs();
    // زاوية الشمس عند العصر: arccot(t + tan|الفرق|) موجبة.
    final angle = _deg(math.atan(1 / (1 + math.tan(_rad(delta)))));
    final cosH = (_sinDeg(angle) - _sinDeg(decl) * _sinDeg(lat)) /
        (_cosDeg(decl) * _cosDeg(lat));
    if (cosH.abs() > 1) return 0;
    return _deg(math.acos(cosH)) / 15;
  }

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
  static double _sinDeg(double d) => math.sin(_rad(d));
  static double _cosDeg(double d) => math.cos(_rad(d));
  static double _fixAngle(double a) => a - 360 * (a / 360).floor();
  static double _fixHour(double h) => h - 24 * (h / 24).floor();
}
