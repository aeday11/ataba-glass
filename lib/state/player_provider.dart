import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/models.dart';
import 'store_provider.dart';

/// حالة التشغيل: قائمة، مؤشر، تحكم كامل مع استكمال من حيث توقف المستخدم.
class PlayerProvider extends ChangeNotifier with WidgetsBindingObserver {
  PlayerProvider(this._store) {
    _speed = _store.speed;
    _volume = _store.volume;
    _player = AudioPlayer(maxSkipsOnError: 4);
    unawaited(_player.setVolume(_volume));
    _bindPlayer();
    WidgetsBinding.instance.addObserver(this);
    restoreSession();
  }

  final StoreProvider _store;
  late final AudioPlayer _player;

  List<Track> _queue = [];
  int? _index;
  bool _playing = false;
  ProcessingState _processingState = ProcessingState.idle;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  double _volume = 1.0;
  LoopMode _loopMode = LoopMode.off;
  String? _error;
  bool _needsLoad = false;
  int? _resumeAppliedIndex;
  Timer? _positionTimer;

  // -------------------------------------------------------------------------
  // الحالة
  // -------------------------------------------------------------------------
  AudioPlayer get player => _player;
  List<Track> get queue => List.unmodifiable(_queue);
  int? get currentIndex => _index;
  bool get hasQueue => _queue.isNotEmpty;
  bool get playing => _playing;
  ProcessingState get processingState => _processingState;
  Duration get duration => _duration;
  double get speed => _speed;
  double get volume => _volume;
  LoopMode get loopMode => _loopMode;
  String? get error => _error;
  bool get needsLoad => _needsLoad;
  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;
  bool get isLoading =>
      _processingState == ProcessingState.loading ||
      _processingState == ProcessingState.buffering;

  Track? get currentTrack {
    final i = _index;
    if (i == null || i < 0 || i >= _queue.length) return null;
    return _queue[i];
  }

  Stream<Duration> get positionStream => _player.positionStream;

  // -------------------------------------------------------------------------
  // ربط المشغّل
  // -------------------------------------------------------------------------
  void _bindPlayer() {
    _player.playerStateStream.listen((state) {
      _playing = state.playing;
      _processingState = state.processingState;
      notifyListeners();
    });

    _player.currentIndexStream.listen((index) {
      if (index == null) return;
      _index = index;
      notifyListeners();
      _applyResume(index);
      _persistSession();
    });

    _player.durationStream.listen((value) {
      _duration = value ?? Duration.zero;
      notifyListeners();
    });

    _player.speedStream.listen((value) {
      if ((value - _speed).abs() > 0.001) {
        _speed = value;
        notifyListeners();
      }
    });

    _player.loopModeStream.listen((mode) {
      if (mode != _loopMode) {
        _loopMode = mode;
        notifyListeners();
      }
    });

    _player.errorStream.listen((_) {
      _error = 'تعذّر تشغيل المقطع — تحقّق من الاتصال بالإنترنت';
      notifyListeners();
    });

    _positionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _saveCurrentPosition();
    });
  }

  /// استرجاع موضع التشغيل عند تبديل المقاطع.
  Future<void> _applyResume(int index) async {
    if (_resumeAppliedIndex == index) return;
    _resumeAppliedIndex = index;
    if (index >= _queue.length) return;
    final track = _queue[index];
    final saved = _store.positionFor(track.id);
    if (saved == null || saved.inSeconds < 5) return;
    try {
      final duration = await _player.durationStream
          .firstWhere((d) => d != null)
          .timeout(const Duration(seconds: 8));
      final limit = duration! - const Duration(seconds: 15);
      if (saved < limit) await _player.seek(saved);
    } catch (_) {
      // نتجاهل أي فشل في الاسترجاع.
    }
  }

  void _saveCurrentPosition() {
    if (!_playing) return;
    final track = currentTrack;
    if (track == null) return;
    _store.savePosition(track.id, _player.position);
  }

  void _persistSession() {
    if (_queue.isEmpty) return;
    _store.saveSession(_queue, _index ?? 0);
  }

  /// استعادة آخر جلسة استماع عند فتح التطبيق.
  void restoreSession() {
    final saved = _store.lastQueue;
    if (saved.isEmpty) return;
    _queue = saved;
    _index = _store.lastIndex.clamp(0, saved.length - 1);
    _needsLoad = true;
    notifyListeners();
  }

  /// استكمال آخر جلسة (يُستدعى عند الضغط على "استكمال الاستماع").
  Future<void> resumeLastSession() async {
    if (_queue.isEmpty) return;
    await playQueue(_queue, startIndex: _index ?? 0);
  }

  // -------------------------------------------------------------------------
  // التحكم
  // -------------------------------------------------------------------------
  AudioSource _sourceFor(Track track) {
    final local = _store.localPathFor(track);
    final tag = MediaItem(
      id: track.id,
      title: track.titleAr,
      album: track.reciterName ?? 'دمعه عشق',
      artist: track.reciterName,
      artUri: track.artUrl != null ? Uri.tryParse(track.artUrl!) : null,
    );
    if (local != null) return AudioSource.file(local, tag: tag);
    return AudioSource.uri(Uri.parse(track.audioUrl), tag: tag);
  }

  /// الحد الأقصى لحجم القائمة المُحمّلة دفعة واحدة.
  ///
  /// القوائم الضخمة (مثل "تشغيل الكل" لباسم الكربلائي: 3,898 مقطع) تُؤخذ
  /// منها نافذة تبدأ من المقطع المختار وتلتف حول القائمة — تكفي لساعات
  /// استماع متواصلة مع بقاء الاستجابة سريعة وحفظ الجلسة صغيراً.
  static const int maxQueueSize = 300;

  /// تشغيل قائمة مقاطع ابتداءً من مقطع معيّن.
  Future<void> playQueue(
    List<Track> tracks, {
    int startIndex = 0,
    bool shuffle = false,
  }) async {
    if (tracks.isEmpty) return;
    var queue = tracks;
    var index = startIndex.clamp(0, tracks.length - 1);
    if (tracks.length > maxQueueSize) {
      queue = <Track>[
        ...tracks.sublist(index),
        ...tracks.sublist(0, index),
      ].take(maxQueueSize).toList(growable: false);
      index = 0;
    }
    _queue = List.of(queue);
    _index = index;
    _needsLoad = false;
    _error = null;
    _resumeAppliedIndex = null;
    notifyListeners();

    try {
      await _player.setAudioSources(
        _queue.map(_sourceFor).toList(),
        initialIndex: index,
        initialPosition: Duration.zero,
      );
      if (shuffle) {
        await _player.setShuffleModeEnabled(true);
        await _player.setLoopMode(LoopMode.all);
      }
      await _player.play();
      _persistSession();
    } catch (_) {
      // فشل التحميل (مثل انقطاع الشبكة): تبقى القائمة جاهزة
      // ويعاود النظام المحاولة عند إعادة الضغط.
      _error = 'تعذّر تشغيل هذا المقطع — تحقّق من الاتصال';
      notifyListeners();
    }
  }

  Future<void> _loadIfNeeded() async {
    if (!_needsLoad || _queue.isEmpty) return;
    _needsLoad = false;
    _error = null;
    _resumeAppliedIndex = null;
    await _player.setAudioSources(
      _queue.map(_sourceFor).toList(),
      initialIndex: _index ?? 0,
      initialPosition: Duration.zero,
    );
  }

  /// تشغيل / إيقاف مؤقت.
  Future<void> togglePlay() async {
    if (_queue.isEmpty) return;
    if (_needsLoad) {
      await _loadIfNeeded();
      await _player.play();
      return;
    }
    if (_playing) {
      _saveCurrentPosition();
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> next() async {
    if (!hasNext) return;
    await _player.seekToNext();
  }

  Future<void> previous() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (!hasPrevious) return;
    await _player.seekToPrevious();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> skipForward() async {
    final target = _player.position + const Duration(seconds: 10);
    await _player.seek(target > _duration ? _duration : target);
  }

  Future<void> skipBackward() async {
    final target = _player.position - const Duration(seconds: 10);
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  /// الانتقال إلى مقطع بعينه داخل القائمة الحالية.
  Future<void> playAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    if (_needsLoad) {
      _index = index;
      notifyListeners();
      await _loadIfNeeded();
      await _player.play();
      return;
    }
    await _player.seek(Duration.zero, index: index);
    if (!_playing) await _player.play();
  }

  /// إدراج مقطع بعد المقطع الحالي.
  Future<void> insertNext(Track track) async {
    if (_queue.isEmpty) {
      await playQueue([track]);
      return;
    }
    final at = (_index ?? 0) + 1;
    _queue.insert(at, track);
    if (_needsLoad) {
      notifyListeners();
      _persistSession();
      return;
    }
    await _player.insertAudioSource(at, _sourceFor(track));
    notifyListeners();
    _persistSession();
  }

  /// إضافة مقطع إلى نهاية القائمة.
  Future<void> addLast(Track track) async {
    if (_queue.isEmpty) {
      await playQueue([track]);
      return;
    }
    _queue.add(track);
    if (_needsLoad) {
      notifyListeners();
      _persistSession();
      return;
    }
    await _player.addAudioSource(_sourceFor(track));
    notifyListeners();
    _persistSession();
  }

  /// إزالة مقطع من القائمة الحالية.
  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (_needsLoad) {
      if (_queue.isEmpty) _index = null;
      notifyListeners();
      _persistSession();
      return;
    }
    await _player.removeAudioSourceAt(index);
    notifyListeners();
    _persistSession();
  }

  /// تبديل سرعة التشغيل (تُحفظ بين الجلسات).
  Future<void> setSpeed(double value) async {
    _speed = value;
    await _player.setSpeed(value);
    await _store.setSpeed(value);
    notifyListeners();
  }

  /// مستوى الصوت العام (0.0 – 1.0) ويُحفظ بين الجلسات.
  Future<void> setVolume(double value) async {
    await previewVolume(value);
    await persistVolume();
  }

  /// معاينة فورية أثناء سحب شريط الصوت (بدون كتابة على القرص).
  Future<void> previewVolume(double value) async {
    _volume = value.clamp(0.0, 1.0).toDouble();
    await _player.setVolume(_volume);
    notifyListeners();
  }

  /// تثبيت مستوى الصوت الحالي في التخزين المحلي.
  Future<void> persistVolume() => _store.setVolume(_volume);

  /// دورة وضع التكرار: إيقاف ← تكرار الكل ← تكرار المقطع.
  Future<void> cycleLoopMode() async {
    final nextMode = switch (_loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _player.setLoopMode(nextMode);
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // نظام النوم الحسيني: مؤقّت يهدأ الصوت تدريجياً حتى النوم.
  // -------------------------------------------------------------------------
  Duration? _sleepRemaining;
  Timer? _sleepTicker;

  bool get sleepActive => _sleepRemaining != null;
  Duration get sleepRemaining => _sleepRemaining ?? Duration.zero;

  /// بدء مؤقّت النوم: في آخر دقيقتين ينزل الصوت شوي شوي حتى ينقطع.
  void startSleepTimer(Duration total) {
    cancelSleepTimer();
    _sleepRemaining = total;
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = _sleepRemaining;
      if (left == null) {
        t.cancel();
        return;
      }
      _sleepRemaining = left - const Duration(seconds: 1);
      final now = _sleepRemaining!;
      if (now <= Duration.zero) {
        t.cancel();
        _finishSleep();
      } else if (now <= const Duration(minutes: 2) && _playing) {
        _player.setVolume(
          _volume * (now.inSeconds / 120).clamp(0.02, 1.0),
        );
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// إلغاء مؤقّت النوم واستعادة الصوت.
  void cancelSleepTimer() {
    _sleepTicker?.cancel();
    _sleepTicker = null;
    if (_sleepRemaining != null) _player.setVolume(_volume);
    _sleepRemaining = null;
    notifyListeners();
  }

  Future<void> _finishSleep() async {
    await _player.setVolume(_volume);
    await _player.pause();
    _saveCurrentPosition();
    _sleepRemaining = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // دورة الحياة
  // -------------------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveCurrentPosition();
    }
  }

  @override
  void dispose() {
    _saveCurrentPosition();
    _positionTimer?.cancel();
    _sleepTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }
}
