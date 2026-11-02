/// إعدادات الاتصال بسيرفر الصوتيات.
///
/// التطبيق يعمل افتراضياً بالمكتبة المضمّنة الحقيقية (كل مقاطع الرواديد
/// داخل `assets/library/`). إن كان لديك سيرفر خاص يطابق العقد أدناه، ضع
/// رابطه في [ApiConfig.baseUrl] (أو مرّره وقت البناء):
/// ```sh
/// flutter build apk --dart-define=API_BASE_URL=https://api.example.com
/// ```
class ApiConfig {
  ApiConfig._();

  /// رابط السيرفر بدون شرطة مائلة في النهاية.
  /// مثال: `https://api.example.com`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// هل تم ضبط السيرفر؟
  static bool get isConfigured => baseUrl.trim().isNotEmpty;

  /// نقاط النهاية المطلوبة من السيرفر:
  ///
  /// - `GET {baseUrl}/api/reciters`
  ///     → `{"reciters": [{"id": "basim_karbalaei", "name_ar": "باسم الكربلائي",
  ///        "image_url": "...", "search_keys": ["..."]}]}`
  /// - `GET {baseUrl}/api/reciters/{id}/tracks`
  ///     → `{"tracks": [{"id": "t1", "title_ar": "...", "audio_url": "...",
  ///        "duration_sec": 312, "art_url": "..."}]}`
  /// - `GET {baseUrl}/api/search?q=النص`
  ///     → `{"reciters": [...], "tracks": [...]}`
  static const String recitersEndpoint = '/api/reciters';
  static const String searchEndpoint = '/api/search';

  /// مسار قوائم مقاطع رادد معيّن: `{recitersEndpoint}/{id}/tracks`
  static String tracksEndpoint(String reciterId) =>
      '$recitersEndpoint/$reciterId/tracks';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// معرّف تطبيق الرحال (يُستخدم لاسم قناة الإشعار في أندرويد).
  static const String appId = 'com.rihal.rihal';
}
