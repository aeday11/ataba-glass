/// نماذج البيانات: الرواديد والمقاطع الصوتية.
library;

/// رادد حسيني.
class Reciter {
  const Reciter({
    required this.id,
    required this.nameAr,
    this.searchKeys = const [],
    this.altIds = const [],
    this.youtubeChannel,
    this.imageUrl,
  });

  /// المعرّف الأساسي (يستخدم في روابط السيرفر).
  final String id;

  /// الاسم بالعربية.
  final String nameAr;

  /// مفاتيح بحث إضافية (عربية وإنجليزية).
  final List<String> searchKeys;

  /// معرّفات بديلة مستخدمة في قواعد بيانات قديمة.
  final List<String> altIds;

  /// معرّف قناة يوتيوب (يُستخدم لاحقاً).
  final String? youtubeChannel;

  /// صورة الرادد من السيرفر.
  final String? imageUrl;

  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = _norm(query);
    if (_norm(nameAr).contains(q)) return true;
    for (final key in searchKeys) {
      if (_norm(key).contains(q)) return true;
    }
    return _norm(id).contains(q);
  }

  factory Reciter.fromJson(Map<String, dynamic> json) => Reciter(
        id: json['id'] as String,
        nameAr: json['name_ar'] as String? ?? json['id'] as String? ?? '',
        searchKeys: _stringList(json['search_keys']),
        altIds: _stringList(json['alt_ids']),
        youtubeChannel: json['youtube_channel'] as String?,
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_ar': nameAr,
        'search_keys': searchKeys,
        'alt_ids': altIds,
        if (youtubeChannel != null) 'youtube_channel': youtubeChannel,
        if (imageUrl != null) 'image_url': imageUrl,
      };

  static String _norm(String s) {
    var t = s.toLowerCase().trim();
    t = t.replaceAll(RegExp('[ً-ْٰ]'), '');
    t = t
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
    return t;
  }

  static List<String> _stringList(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : const [];
}

/// مقطع صوتي.
class Track {
  const Track({
    required this.id,
    required this.reciterId,
    required this.titleAr,
    required this.audioUrl,
    this.duration,
    this.artUrl,
    this.reciterName,
  });

  final String id;
  final String reciterId;
  final String titleAr;
  final String audioUrl;
  final Duration? duration;
  final String? artUrl;
  final String? reciterName;

  String get durationLabel {
    final d = duration;
    if (d == null) return '';
    final total = d.inSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    final durationSec = json['duration_sec'];
    return Track(
      id: json['id'] as String,
      reciterId: json['reciter_id'] as String? ?? '',
      titleAr: json['title_ar'] as String? ?? 'بدون عنوان',
      audioUrl: json['audio_url'] as String,
      duration: durationSec is num ? Duration(seconds: durationSec.toInt()) : null,
      artUrl: json['art_url'] as String?,
      reciterName: json['reciter_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reciter_id': reciterId,
        'title_ar': titleAr,
        'audio_url': audioUrl,
        if (duration != null) 'duration_sec': duration!.inSeconds,
        if (artUrl != null) 'art_url': artUrl,
        if (reciterName != null) 'reciter_name': reciterName,
      };
}
