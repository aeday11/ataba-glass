import 'package:flutter/material.dart';

/// أدوات مساعدة عامة.
class AppUtils {
  AppUtils._();

  /// تشكيل النص العربي (حركات) للإزالة عند البحث.
  static final RegExp _tashkeel =
      RegExp('[ً-ْٰـٓ-ٟۖ-ۭ]');

  /// تحويل الأرقام إلى صيغة الوقت `م:ث` أو `س:م:ث`.
  static String formatDuration(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    if (hours > 0) return '$hours:${two(minutes)}:${two(seconds)}';
    return '$minutes:${two(seconds)}';
  }

  /// تهيئة النص للمقارنة: إزالة التشكيل وتوحيد الألف والياء.
  static String normalize(String input) {
    var s = input.toLowerCase().trim();
    s = s.replaceAll(_tashkeel, '');
    s = s
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  /// الحرف الأول من الاسم لعرضه داخل الأيقونة الدائرية.
  static String initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '؟' : String.fromCharCode(trimmed.runes.first);
  }

  /// لون مميّز ثابت لكل رادد بناءً على معرّفه.
  static Color avatarColor(String seed) {
    final hues = [38, 18, 200, 260, 340, 160, 90, 120];
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    final hue = hues[hash % hues.length];
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.45, 0.42).toColor();
  }

  /// حجم الملف بصيغة مقروءة.
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 ك.ب';
    const units = ['ب', 'ك.ب', 'م.ب', 'ج.ب'];
    var size = bytes.toDouble();
    var i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    final value = size >= 10 || size == size.roundToDouble()
        ? size.round().toString()
        : size.toStringAsFixed(1);
    return '$value ${units[i]}';
  }

  /// عرض مساعدة للرسائل التوضيحية.
  static void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// تحويل الأرقام اللاتينية إلى أرقام عربية-هندية (٠١٢...).
  static String arabicDigits(String input) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i == null ? c : digits[i];
    }).join();
  }

  /// مدة بكلمات عربية: "ساعة و٢٠ دقيقة" أو "٢٥ دقيقة".
  static String durationWords(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${arabicDigits('$hours')} ساعة و${arabicDigits('$minutes')} دقيقة';
    }
    if (hours > 0) return '${arabicDigits('$hours')} ساعة';
    return '${arabicDigits('$minutes')} دقيقة';
  }
}
