import 'package:flutter/services.dart';

/// نتيجة فحص حماية التطبيق على الجهاز الحالي.
class SecurityStatus {
  const SecurityStatus({
    this.rooted,
    this.debugger,
    this.emulator,
    this.signatureSha256,
    this.installer,
  });

  /// هل الجهاز مُتجذّر (Root)؟ `null` = غير متاح على هذه المنصة.
  final bool? rooted;

  /// هل مفتاح المطوّر (Debugger) موصول؟
  final bool? debugger;

  /// هل يعمل على مُحاكي أندرويد؟
  final bool? emulator;

  /// بصمة SHA-256 لشهادة توقيع النسخة الحالية من التطبيق.
  final String? signatureSha256;

  /// الـ تطبيق مُثبَّت عبر أي متجر؟ (فارغ = تثبيت مباشر)
  final String? installer;

  /// بصمة التوقيع الأصلية للإصدار المرفوع من المطوّر.
  /// أي نسخة مُعاد تغليفها بتوقيع آخر تُعتبر غير موثّقة.
  static const String expectedSignature =
      'FE:7A:BB:50:F8:8B:72:BA:E3:D9:A5:3B:7D:97:FE:66:45'
      ':F5:ED:13:E8:E1:5F:57:09:30:F6:22:16:B7:A6:46';

  /// هل هذه النسخة أصلية مطابقة للتوقيع المعتمد؟
  /// `true` أصلية، `false` مُعاد توقيعها، `null` غير معروف هنا.
  bool? get isAuthentic {
    final sig = signatureSha256;
    if (sig == null || sig.isEmpty) return null;
    return sig.toUpperCase() == expectedSignature.toUpperCase();
  }

  static const SecurityStatus unknown = SecurityStatus();

  /// فحص الحماية عبر قناة Kotlin في MainActivity (أندرويد فقط).
  /// على المنصات الأخرى (الاختبارات/سطح المكتب) تُرجع [unknown].
  static Future<SecurityStatus> check() async {
    try {
      final map = await const MethodChannel('rihal/security')
          .invokeMapMethod<String, dynamic>('securityInfo');
      if (map == null) return unknown;
      final installer = map['installer'] as String?;
      return SecurityStatus(
        rooted: map['rooted'] as bool?,
        debugger: map['debugger'] as bool?,
        emulator: map['emulator'] as bool?,
        signatureSha256: map['signatureSha256'] as String?,
        installer: (installer == null || installer.isEmpty) ? null : installer,
      );
    } catch (_) {
      return unknown;
    }
  }

  /// رقم توثيق ثابت مشتق من بصمة التوقيع الأصلية بصيغة `RHL-XXXX-XXXX`.
  static String get verificationCode => _codeOf(expectedSignature);

  static String _codeOf(String source) {
    final hex = source.replaceAll(':', '');
    var h1 = 0x811c9dc5;
    var h2 = 0x1b873593;
    for (final unit in hex.codeUnits) {
      h1 = ((h1 ^ unit) * 0x01000193) & 0x7fffffff;
      h2 = ((h2 + unit * 7) * 0x85ebca6b) & 0x7fffffff;
    }
    String group(int v) => v
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0')
        .substring(0, 4);
    return 'RHL-${group(h1)}-${group(h2)}';
  }
}
