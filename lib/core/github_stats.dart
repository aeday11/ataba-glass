import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// نتائج آخر إصدار من مستودع GitHub: عدد تنزيلات ملف الـ APK.
class ReleaseStats {
  const ReleaseStats({
    required this.downloads,
    required this.tagName,
    required this.publishedAt,
  });

  /// مجموع تنزيلات ملفات `.apk` في آخر إصدار.
  final int downloads;

  /// وسم الإصدار (مثال: `v1.0.0`).
  final String tagName;

  /// تاريخ نشر الإصدار.
  final DateTime? publishedAt;
}

/// عدّاد تنزيلات التطبيق من مستودع GitHub — مجاني وبلا خادم:
/// يقرأ عدّاد `download_count` العلني في واجهة GitHub API.
class GithubCounter {
  GithubCounter._();

  static const _prefsOwner = 'gh_owner';
  static const _prefsRepo = 'gh_repo';
  static const _prefsCount = 'gh_last_count';
  static const _prefsTag = 'gh_last_tag';
  static const _prefsTime = 'gh_last_time';

  /// المستودع المحفوظ (المالك/الاسم) أو قيم فارغة إن لم يُضبط بعد.
  static Future<(String owner, String repo)> savedRepo() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getString(_prefsOwner) ?? '',
      prefs.getString(_prefsRepo) ?? '',
    );
  }

  /// حفظ المستودع من لوحة المطوّر.
  static Future<void> saveRepo(String owner, String repo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsOwner, owner.trim());
    await prefs.setString(_prefsRepo, repo.trim());
  }

  /// آخر عدّاد محفوظ دون اتصال (يظهر فوراً ثم يُحدَّث).
  static Future<ReleaseStats?> cached() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_prefsCount)) return null;
    final millis = prefs.getInt(_prefsTime);
    return ReleaseStats(
      downloads: prefs.getInt(_prefsCount) ?? 0,
      tagName: prefs.getString(_prefsTag) ?? '',
      publishedAt: millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }

  /// الاستعلام عن عدد تنزيلات الـ APK من آخر إصدار في المستودع.
  static Future<ReleaseStats> fetch({
    required String owner,
    required String repo,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {
          'User-Agent': 'KhademAlHussein',
          'Accept': 'application/vnd.github+json',
        },
      ),
    );

    try {
      final response = await dio.get<dynamic>(
        'https://api.github.com/repos/$owner/$repo/releases/latest',
      );
      final data = response.data as Map<String, dynamic>? ?? const {};

      final assets = (data['assets'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      var apkCount = 0;
      var totalCount = 0;
      for (final asset in assets) {
        final count = (asset['download_count'] as num?)?.toInt() ?? 0;
        totalCount += count;
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) apkCount += count;
      }

      final stats = ReleaseStats(
        downloads: apkCount > 0 ? apkCount : totalCount,
        tagName: (data['tag_name'] as String?) ?? '',
        publishedAt: DateTime.tryParse(data['published_at'] as String? ?? ''),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsCount, stats.downloads);
      await prefs.setString(_prefsTag, stats.tagName);
      await prefs.setInt(
        _prefsTime,
        (stats.publishedAt ?? DateTime.now()).millisecondsSinceEpoch,
      );
      return stats;
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 404:
          throw Exception('لا يوجد إصدار في المستودع — ارفع ملف APK في Releases');
        case 403:
          throw Exception('تجاوز حد الطلبات — أعد المحاولة بعد قليل');
        default:
          throw Exception('تعذّر الاتصال بـ GitHub — تحقّق من الإنترنت');
      }
    } catch (_) {
      throw Exception('تعذّر جلب العدد — تحقّق من اسم المستودع');
    }
  }
}
