import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../core/config.dart';
import 'models.dart';
import 'reciters_data.dart';

/// نتائج البحث (رواديد + مقاطع).
class SearchResults {
  const SearchResults({this.reciters = const [], this.tracks = const []});

  final List<Reciter> reciters;
  final List<Track> tracks;

  bool get isEmpty => reciters.isEmpty && tracks.isEmpty;
}

/// واجهة مصدر المحتوى الصوتي.
abstract class AudioApi {
  /// true عند الاتصال بسيرفر خارجي، false عند استخدام المكتبة المضمّنة.
  bool get isRemote;

  Future<List<Reciter>> fetchReciters();

  Future<List<Track>> fetchTracks(Reciter reciter);

  Future<SearchResults> search(String query);

  /// عدد المقاطع لكل رادد (للعرض في القائمة) إن كان المصدر يعرفها مسبقاً.
  Future<Map<String, int>> trackCounts() async => const {};
}

/// تنفيذ الاتصال بالسيرفر عبر dio.
class HttpAudioApi extends AudioApi {
  HttpAudioApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                headers: const {'Accept': 'application/json'},
              ),
            );

  final Dio _dio;

  @override
  bool get isRemote => true;

  @override
  Future<List<Reciter>> fetchReciters() async {
    final response = await _dio.get<dynamic>(ApiConfig.recitersEndpoint);
    final data = _asMap(response.data);
    final list = data['reciters'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Reciter.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<Track>> fetchTracks(Reciter reciter) async {
    final response =
        await _dio.get<dynamic>(ApiConfig.tracksEndpoint(reciter.id));
    final data = _asMap(response.data);
    final list = data['tracks'];
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) {
      final json = Map<String, dynamic>.from(e);
      json['reciter_id'] ??= reciter.id;
      json['reciter_name'] ??= reciter.nameAr;
      return Track.fromJson(json);
    }).toList();
  }

  @override
  Future<SearchResults> search(String query) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConfig.searchEndpoint,
        queryParameters: {'q': query},
      );
      final data = _asMap(response.data);
      final reciters = data['reciters'];
      final tracks = data['tracks'];
      return SearchResults(
        reciters: reciters is List
            ? reciters
                .whereType<Map>()
                .map((e) => Reciter.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        tracks: tracks is List
            ? tracks
                .whereType<Map>()
                .map((e) => Track.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
      );
    } on DioException {
      return const SearchResults();
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

/// المكتبة الحقيقية المضمّنة داخل التطبيق.
///
/// جميع مقاطع الرواديد محفوظة في ملفات JSON داخل `assets/library/`:
/// - `assets/library/{reciter_id}.json` → مقاطع الرادد مع روابط البث المباشر.
/// - `assets/library/index.json` → عدد مقاطع كل رادد.
///
/// تُولَّد هذه الملفات عبر أدوات `tool/` ويمكن تحديثها في أي وقت:
/// - `dart run tool/fetch_latmiyat.dart` → مصدر shiavoice.com.
/// - `dart run tool/fetch_yahosein.dart` → مصدر yahosein.com (يا حسين).
class BundledLibraryApi implements AudioApi {
  BundledLibraryApi({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, List<Track>> _cache = {};
  final Set<String> _missing = {};
  Map<String, int>? _counts;

  @override
  bool get isRemote => false;

  @override
  Future<List<Reciter>> fetchReciters() async => bundledReciters;

  @override
  Future<List<Track>> fetchTracks(Reciter reciter) async {
    final cached = _cache[reciter.id];
    if (cached != null) return cached;
    if (_missing.contains(reciter.id)) return const [];
    try {
      final raw =
          await _bundle.loadString('assets/library/${reciter.id}.json');
      final data = jsonDecode(raw);
      final tracks = <Track>[];
      if (data is Map && data['tracks'] is List) {
        for (final e in data['tracks'] as List) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final id = m['id'] as String?;
          final url = (m['url'] ?? m['audio_url']) as String?;
          if (id == null || url == null) continue;
          final dur = m['duration'];
          tracks.add(
            Track(
              id: id,
              reciterId: reciter.id,
              titleAr:
                  (m['title'] ?? m['title_ar'] ?? 'بدون عنوان').toString(),
              audioUrl: url,
              duration:
                  dur is num ? Duration(seconds: dur.toInt()) : null,
              artUrl: (m['cover'] ?? m['art_url']) as String?,
              reciterName: reciter.nameAr,
            ),
          );
        }
      }
      _cache[reciter.id] = tracks;
      return tracks;
    } catch (_) {
      // الملف غير موجود لهذا الرادد.
      _missing.add(reciter.id);
      return const [];
    }
  }

  @override
  Future<Map<String, int>> trackCounts() async {
    final known = _counts;
    if (known != null) return known;
    try {
      final raw = await _bundle.loadString('assets/library/index.json');
      final data = jsonDecode(raw);
      final map = <String, int>{};
      if (data is Map && data['reciters'] is List) {
        for (final e in data['reciters'] as List) {
          if (e is! Map) continue;
          final id = e['id'];
          final count = e['count'];
          if (id is String && count is num) map[id] = count.toInt();
        }
      }
      _counts = map;
      return map;
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<SearchResults> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const SearchResults();
    final reciters = bundledReciters
        .where((r) => r.matches(q))
        .toList(growable: false);

    // بحث في كامل المكتبة (الملفات تُحمّل وتُخزَّن مرة واحدة فقط).
    const limit = 100;
    final tracks = <Track>[];
    for (final r in bundledReciters) {
      final list = await fetchTracks(r);
      for (final t in list) {
        if (t.titleAr.contains(q)) {
          tracks.add(t);
          if (tracks.length >= limit) break;
        }
      }
      if (tracks.length >= limit) break;
    }
    return SearchResults(reciters: reciters, tracks: tracks);
  }
}

/// إنشاء مصدر المحتوى حسب إعدادات التطبيق:
/// سيرفر خارجي عند ضبط الرابط، وإلا المكتبة المضمّنة الحقيقية.
AudioApi createApi() =>
    ApiConfig.isConfigured ? HttpAudioApi() : BundledLibraryApi();
