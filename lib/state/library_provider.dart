import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api.dart';
import '../data/models.dart';
import '../data/reciters_data.dart';

/// يدير تحميل الرواديد والمقاطع والبحث.
class LibraryProvider extends ChangeNotifier {
  LibraryProvider(this._api) {
    _reciters = List.of(bundledReciters);
    load();
  }

  final AudioApi _api;

  List<Reciter> _reciters = List.of(bundledReciters);
  final Map<String, List<Track>> _tracksCache = {};
  final Set<String> _loadingTracks = {};
  Map<String, int> _counts = const {};
  bool _loading = false;
  String? _error;

  /// هل السيرفر مربوط فعلاً؟
  bool get isRemote => _api.isRemote;

  List<Reciter> get reciters => List.unmodifiable(_reciters);
  bool get loading => _loading;
  String? get error => _error;

  /// تحميل قائمة الرواديد (من السيرفر مع الرجوع للقائمة المضمّنة عند الفشل).
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final remote = await _api.fetchReciters();
      if (remote.isNotEmpty) {
        // ندمج بيانات السيرفر مع مفاتيح البحث المحلية عند تطابق المعرّف.
        _reciters = remote.map((r) {
          final local = bundledReciters.where((b) => b.id == r.id).firstOrNull;
          if (local == null) return r;
          return Reciter(
            id: r.id,
            nameAr: r.nameAr.isNotEmpty ? r.nameAr : local.nameAr,
            searchKeys:
                {...local.searchKeys, ...r.searchKeys}.toList(growable: false),
            altIds: {...local.altIds, ...r.altIds}.toList(growable: false),
            youtubeChannel: r.youtubeChannel ?? local.youtubeChannel,
            imageUrl: r.imageUrl ?? local.imageUrl,
          );
        }).toList();
      } else {
        _reciters = List.of(bundledReciters);
      }
      _counts = await _api.trackCounts();
    } catch (e) {
      _reciters = List.of(bundledReciters);
      _error = 'تعذّر جلب قائمة الرواديد، تم عرض القائمة المضمّنة';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// مقاطع رادد معيّن (مع التخزين المؤقت).
  Future<List<Track>> tracksFor(Reciter reciter) async {
    final cached = _tracksCache[reciter.id];
    if (cached != null) return cached;
    if (_loadingTracks.contains(reciter.id)) {
      // انتظر حتى ينتهي التحميل الجاري.
      while (_loadingTracks.contains(reciter.id)) {
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      return _tracksCache[reciter.id] ?? const [];
    }

    _loadingTracks.add(reciter.id);
    // تأجيل الإخطار: هذه الدالة قد تُستدعى من initState أثناء دورة البناء،
    // وإخطار المستمعين هنا يُسقط الشجرة (markNeedsBuild أثناء build).
    scheduleMicrotask(notifyListeners);
    try {
      final tracks = await _api.fetchTracks(reciter);
      _tracksCache[reciter.id] = tracks;
      return tracks;
    } catch (e) {
      return _tracksCache[reciter.id] ?? const [];
    } finally {
      _loadingTracks.remove(reciter.id);
      notifyListeners();
    }
  }

  bool isLoadingTracks(String reciterId) => _loadingTracks.contains(reciterId);

  bool hasTracks(String reciterId) =>
      _tracksCache[reciterId]?.isNotEmpty ?? false;

  /// بحث عن راددين ومقاطع.
  Future<SearchResults> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const SearchResults();

    final localReciters =
        _reciters.where((r) => r.matches(q)).toList(growable: false);

    // نتائج المصدر: المكتبة المضمّنة أو السيرفر.
    final apiResults = await _api.search(q);

    // ما هو مخزّن محلياً بالفعل من مقاطع الرواديد المطابقين.
    final cachedTracks = <Track>[];
    for (final reciter in localReciters) {
      final cached = _tracksCache[reciter.id];
      if (cached == null) continue;
      cachedTracks.addAll(cached.where((t) => t.titleAr.contains(q)));
    }

    const limit = 100;
    final seen = <String>{};
    final merged = <Track>[
      ...apiResults.tracks,
      ...cachedTracks,
    ].where((t) => seen.add(t.id)).take(limit).toList(growable: false);

    return SearchResults(reciters: localReciters, tracks: merged);
  }

  /// عدد المقاطع المحملة لرادد (للعرض في القائمة).
  int trackCountOf(String reciterId) =>
      _tracksCache[reciterId]?.length ?? _counts[reciterId] ?? 0;
}
