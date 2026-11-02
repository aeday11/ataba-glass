import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';

/// مقطع مُنزَّل داخل الجهاز.
class DownloadEntry {
  const DownloadEntry({
    required this.track,
    required this.path,
    required this.sizeBytes,
  });

  final Track track;
  final String path;
  final int sizeBytes;

  bool get fileExistsSync => File(path).existsSync();

  Map<String, dynamic> toJson() => {
        'track': track.toJson(),
        'path': path,
        'size_bytes': sizeBytes,
      };

  factory DownloadEntry.fromJson(Map<String, dynamic> json) => DownloadEntry(
        track: Track.fromJson(Map<String, dynamic>.from(json['track'] as Map)),
        path: json['path'] as String,
        sizeBytes: json['size_bytes'] as int? ?? 0,
      );
}

/// مخزن الحالة الدائم: المفضلة، التنزيلات، مواضع التشغيل، السرعة، آخر جلسة.
class StoreProvider extends ChangeNotifier {
  StoreProvider._(this._prefs, this._dio);

  static Future<StoreProvider> init(Dio dio) async {
    final prefs = await SharedPreferences.getInstance();
    final store = StoreProvider._(prefs, dio);
    store._loadAll();
    return store;
  }

  final SharedPreferences _prefs;
  final Dio _dio;

  // ---------------------------------------------------------------------------
  // المفضلة
  // ---------------------------------------------------------------------------
  static const String _kFavorites = 'fav_tracks';
  final List<Track> _favorites = [];
  List<Track> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String trackId) => _favorites.any((t) => t.id == trackId);

  void toggleFavorite(Track track) {
    if (isFavorite(track.id)) {
      _favorites.removeWhere((t) => t.id == track.id);
    } else {
      _favorites.insert(0, track);
    }
    _prefs.setString(
      _kFavorites,
      jsonEncode(_favorites.map((t) => t.toJson()).toList()),
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // التنزيلات
  // ---------------------------------------------------------------------------
  static const String _kDownloads = 'downloads';
  final Map<String, DownloadEntry> _downloads = {};
  final Map<String, double> _downloadProgress = {};

  Map<String, DownloadEntry> get downloads => Map.unmodifiable(_downloads);

  DownloadEntry? downloadFor(String trackId) => _downloads[trackId];

  bool isDownloaded(String trackId) => _downloads.containsKey(trackId);

  /// المسار المحلي للمقطع إن كان مُنزَّلاً، وإلا null.
  String? localPathFor(Track track) => _downloads[track.id]?.path;

  double? progressFor(String trackId) => _downloadProgress[trackId];

  bool isDownloading(String trackId) => _downloadProgress.containsKey(trackId);

  /// تنزيل مقطع داخل ذاكرة الجهاز للاستماع بدون إنترنت.
  Future<void> download(Track track) async {
    if (isDownloaded(track.id) || isDownloading(track.id)) return;
    _downloadProgress[track.id] = 0;
    notifyListeners();
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir =
          Directory('${docs.path}${Platform.pathSeparator}downloads');
      if (!await dir.exists()) await dir.create(recursive: true);

      final path =
          '${dir.path}${Platform.pathSeparator}${_safeName(track)}.${_extension(track)}';
      await _dio.download(
        track.audioUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          final value = received / total;
          final previous = _downloadProgress[track.id] ?? 0;
          if ((value - previous).abs() >= 0.02 || value >= 1) {
            _downloadProgress[track.id] = value.clamp(0, 1);
            notifyListeners();
          }
        },
      );

      final file = File(path);
      final size = await file.length();
      _downloads[track.id] =
          DownloadEntry(track: track, path: path, sizeBytes: size);
      _downloadProgress.remove(track.id);
      _persistDownloads();
      notifyListeners();
    } catch (_) {
      _downloadProgress.remove(track.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDownload(String trackId) async {
    final entry = _downloads.remove(trackId);
    _persistDownloads();
    if (entry != null) {
      final file = File(entry.path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  void _persistDownloads() {
    _prefs.setString(
      _kDownloads,
      jsonEncode(_downloads.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  static String _safeName(Track track) {
    final sanitized = track.id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return sanitized.length >= 3 ? sanitized : 'track_${track.id.hashCode.abs()}';
  }

  static String _extension(Track track) {
    final path = Uri.tryParse(track.audioUrl)?.path ?? '';
    final segment = path.split('/').last;
    final dot = segment.lastIndexOf('.');
    if (dot > 0 && dot < segment.length - 1) {
      final ext = segment.substring(dot + 1).toLowerCase();
      if (RegExp(r'^[a-z0-9]{2,5}$').hasMatch(ext)) return ext;
    }
    return 'mp3';
  }

  // ---------------------------------------------------------------------------
  // مواضع الاستكمال
  // ---------------------------------------------------------------------------
  static const String _kPositions = 'positions';
  final Map<String, int> _positions = {};

  Duration? positionFor(String trackId) {
    final micros = _positions[trackId];
    return micros == null ? null : Duration(microseconds: micros);
  }

  void savePosition(String trackId, Duration position) {
    if (position.inSeconds < 1) return;
    _positions[trackId] = position.inMicroseconds;
    // حفظ بدون notifyListeners حتى لا يُعيد بناء الواجهة مع كل نبضة.
    _prefs.setString(
      _kPositions,
      jsonEncode(_positions),
    );
  }

  // ---------------------------------------------------------------------------
  // الموقع (المحافظة) لحساب المواقيت والقبلة
  // ---------------------------------------------------------------------------
  static const String _kGovernorateId = 'governorate_id';

  /// معرّف المحافظة المختارة (الافتراضي: كربلاء المقدسة).
  String get governorateId =>
      _prefs.getString(_kGovernorateId) ?? 'karbala';

  Future<void> saveGovernorateId(String id) =>
      _prefs.setString(_kGovernorateId, id);

  // ---------------------------------------------------------------------------
  // المظهر والصوت
  // ---------------------------------------------------------------------------
  static const String _kThemeId = 'theme_id';
  static const String _kVolume = 'volume';

  String _themeId = 'karbala';
  double _volume = 1.0;

  String get themeId => _themeId;
  double get volume => _volume;

  Future<void> setThemeId(String id) async {
    _themeId = id;
    await _prefs.setString(_kThemeId, id);
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0).toDouble();
    await _prefs.setDouble(_kVolume, _volume);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // السرعة وآخر جلسة
  // ---------------------------------------------------------------------------
  static const String _kSpeed = 'speed';
  static const String _kLastQueue = 'last_queue';
  static const String _kLastIndex = 'last_index';

  double _speed = 1.0;
  double get speed => _speed;

  Future<void> setSpeed(double value) async {
    _speed = value;
    await _prefs.setDouble(_kSpeed, value);
    notifyListeners();
  }

  List<Track> _lastQueue = [];
  int _lastIndex = 0;

  List<Track> get lastQueue => List.unmodifiable(_lastQueue);
  int get lastIndex => _lastIndex;

  void saveSession(List<Track> queue, int index) {
    _lastQueue = List.of(queue);
    _lastIndex = index;
    _prefs.setString(
      _kLastQueue,
      jsonEncode(queue.map((t) => t.toJson()).toList()),
    );
    _prefs.setInt(_kLastIndex, index);
  }

  // ---------------------------------------------------------------------------
  // التحميل الأولي
  // ---------------------------------------------------------------------------
  void _loadAll() {
    try {
      final favRaw = _prefs.getString(_kFavorites);
      if (favRaw != null) {
        final list = jsonDecode(favRaw) as List;
        _favorites
          ..clear()
          ..addAll(list
              .whereType<Map>()
              .map((e) => Track.fromJson(Map<String, dynamic>.from(e))));
      }

      final downloadsRaw = _prefs.getString(_kDownloads);
      if (downloadsRaw != null) {
        final map = jsonDecode(downloadsRaw) as Map;
        for (final entry in map.entries) {
          final json = Map<String, dynamic>.from(entry.value as Map);
          final download = DownloadEntry.fromJson(json);
          if (download.fileExistsSync) {
            _downloads[entry.key.toString()] = download;
          }
        }
        if (_downloads.length != map.length) _persistDownloads();
      }

      final positionsRaw = _prefs.getString(_kPositions);
      if (positionsRaw != null) {
        final map = jsonDecode(positionsRaw) as Map;
        for (final entry in map.entries) {
          _positions[entry.key.toString()] = entry.value as int;
        }
      }

      _speed = _prefs.getDouble(_kSpeed) ?? 1.0;
      _themeId = _prefs.getString(_kThemeId) ?? 'karbala';
      _volume = (_prefs.getDouble(_kVolume) ?? 1.0)
          .clamp(0.0, 1.0)
          .toDouble();

      final queueRaw = _prefs.getString(_kLastQueue);
      if (queueRaw != null) {
        final list = jsonDecode(queueRaw) as List;
        _lastQueue = list
            .whereType<Map>()
            .map((e) => Track.fromJson(Map<String, dynamic>.from(e)))
            .where((t) => t.audioUrl.isNotEmpty)
            .toList();
        _lastIndex = _prefs.getInt(_kLastIndex) ?? 0;
        if (_lastQueue.isNotEmpty) {
          _lastIndex = _lastIndex.clamp(0, _lastQueue.length - 1);
        } else {
          _lastIndex = 0;
        }
      }
    } catch (_) {
      // في حال تلف البيانات المحفوظة نتجاهلها ونبدأ من جديد.
    }

    notifyListeners();
  }
}
