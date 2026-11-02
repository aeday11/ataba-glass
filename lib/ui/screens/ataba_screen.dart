import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/admin.dart';
import '../../core/islamic_utils.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/iraq_locations.dart';
import '../../state/library_provider.dart';
import '../../state/location_provider.dart';
import '../../state/player_provider.dart';
import '../widgets/ataba_sheets.dart';
import '../widgets/glass.dart';
import 'admin_screen.dart';
import 'certificate_screen.dart';
import 'player_screen.dart';
import 'qibla_screen.dart';
import 'reciter_screen.dart';
import 'reciters_screen.dart';

/// صورة الصحن الحسيني (ويميديا كومنز — رخصة حرة).
const String kShrineImageUrl =
    'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/'
    'Kerbela_Hussein_Moschee.jpg/960px-Kerbela_Hussein_Moschee.jpg';

/// شاشة العتبة: ساعة زجاجية + بث كربلاء + كبسولات اليوم.
class AtabaScreen extends StatefulWidget {
  const AtabaScreen({super.key});

  @override
  State<AtabaScreen> createState() => _AtabaScreenState();
}

class _AtabaScreenState extends State<AtabaScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _suggesting = false;
  int _secretTaps = 0;
  DateTime _secretStart = DateTime.fromMillisecondsSinceEpoch(0);

  /// خمس ضغطات سريعة على العنوان (خلال ٤ ثوانٍ) تفتح لوحة المطوّر
  /// بعد كلمة السر — لا يظهر أي أثر اللوحة للمستخدم العادي.
  void _onSecretTap() {
    final now = DateTime.now();
    if (now.difference(_secretStart) > const Duration(seconds: 4)) {
      _secretTaps = 0;
      _secretStart = now;
    }
    _secretTaps++;
    if (_secretTaps >= 5) {
      _secretTaps = 0;
      _openAdmin();
    }
  }

  Future<void> _openAdmin() async {
    final ok = await askAdminPassphrase(context);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _suggestCouncil() async {
    if (_suggesting) return;
    setState(() => _suggesting = true);
    final library = context.read<LibraryProvider>();
    final player = context.read<PlayerProvider>();
    final reciters = List.of(library.reciters)..shuffle();
    for (final reciter in reciters.take(6)) {
      final tracks = await library.tracksFor(reciter);
      if (tracks.isEmpty) continue;
      final track = tracks[math.Random().nextInt(tracks.length)];
      await player.playQueue([track]);
      if (mounted) openPlayerScreen(context);
      break;
    }
    if (mounted) setState(() => _suggesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final library = context.watch<LibraryProvider>();
    final reciters = library.reciters;
    final location = context.watch<LocationProvider>().current;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
      children: [
        // الترويسة
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onSecretTap,
                child: Text('دمعه عشق', style: textTheme.displaySmall),
              ),
              const SizedBox(height: 2),
              Text(
                'جميع الحقوق محفوظة 2026 — الإصدار الأول',
                style: textTheme.bodySmall?.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),

        // الساعة الزجاجية
        GlassCard(
          blur: true,
          glow: true,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            children: [
              // توقيع المبرمج فوق الساعة — يفتح شهادة التوثيق.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CertificateScreen(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 22,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'برمجة عدي رويح الحاتمي',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.decorative,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _clockText(),
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'كربلاء والنجف',
                    style: textTheme.bodySmall?.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(width: 8),
                  GlassCapsule(
                    child: Text(
                      IslamicUtils.isFridayEve(_now)
                          ? 'ليلة الجمعة'
                          : IslamicUtils.weekdayName(_now),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                ],
              ),
              if (IslamicUtils.hijriDate(_now).isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  IslamicUtils.hijriDate(_now),
                  style: TextStyle(
                    fontFamily: AppFonts.decorative,
                    fontSize: 16,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // بث كربلاء
        _LiveShrineCard(now: _now),

        const SizedBox(height: 14),

        // كبسولات اليوم
        _TodayCapsules(
          now: _now,
          location: location,
          suggesting: _suggesting,
          onSuggest: _suggestCouncil,
        ),

        const SizedBox(height: 20),

        // قسم الرواديد — يظهر من فتح التطبيق مباشرة
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'الرواديد الحسينيون',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _AllRecitersPage()),
                ),
                child: GlassCapsule(
                  child: Text(
                    '${reciters.length} رادداً',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // شريط الختمائط الأفقية — كل رادد بختمه
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: reciters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final reciter = reciters[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReciterScreen(reciter: reciter),
                  ),
                ),
                child: SizedBox(
                  width: 74,
                  child: Column(
                    children: [
                      GlassSeal(
                        label: AppUtils.initial(reciter.nameAr),
                        image: reciter.imageUrl,
                        size: 60,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reciter.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // شبكة الرواديد المختارة (أول 6)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            final reciter = reciters[index];
            final count = library.trackCountOf(reciter.id);
            return GlassCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReciterScreen(reciter: reciter),
                  ),
                ),
                child: Row(
                  children: [
                    GlassSeal(
                      label: AppUtils.initial(reciter.nameAr),
                      image: reciter.imageUrl,
                      size: 50,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reciter.nameAr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            count > 0 ? '$count مجلس' : 'روادد حسيني',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 11.5,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // عرض كل الرواديد
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _AllRecitersPage()),
            ),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: Text('عرض كل الرواديد (${reciters.length})'),
          ),
        ),
      ],
    );
  }

  String _clockText() {
    final local = _now.toUtc().add(
          const Duration(hours: IslamicUtils.baghdadOffsetHours),
        );
    final raw = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return AppUtils.arabicDigits(raw);
  }
}

/// بطاقة "بث مباشر من كربلاء" مع حركة تنفّس خفيفة للصورة.
class _LiveShrineCard extends StatefulWidget {
  const _LiveShrineCard({required this.now});

  final DateTime now;

  @override
  State<_LiveShrineCard> createState() => _LiveShrineCardState();
}

class _LiveShrineCardState extends State<_LiveShrineCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      glow: true,
      radius: 24,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: SizedBox(
          height: 190,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // الصورة تتحرك ببطء (Ken Burns).
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final scale = 1.04 + 0.06 * _controller.value;
                  return Transform.scale(
                    scale: scale,
                    child: Image.network(
                      kShrineImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AppColors.redDark,
                              AppColors.background,
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.mosque_rounded,
                          size: 54,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // تعتيم سفلي لوضوح النص.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0xCC0A0A0A),
                    ],
                  ),
                ),
              ),
              // النص الذهبي المضيء.
              Positioned(
                left: 12,
                right: 12,
                bottom: 14,
                child: Column(
                  children: [
                    GoldGlowText(
                      'السلام عليك يا أبا عبد الله',
                      fontSize: 23,
                    ),
                    const SizedBox(height: 4),
                    GlassCapsule(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_rounded,
                            size: 14,
                            color: AppColors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'زيارة ${IslamicUtils.weekdayName(widget.now)} — كربلاء',
                            style: textTheme.bodySmall?.copyWith(fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// كبسولات اليوم الأربع: الأذان، القبلة، الزيارة، المجلس المقترح.
/// كل كبسولة تفتح تفاصيلها عند الضغط.
class _TodayCapsules extends StatelessWidget {
  const _TodayCapsules({
    required this.now,
    required this.location,
    required this.suggesting,
    required this.onSuggest,
  });

  final DateTime now;
  final Governorate location;
  final bool suggesting;
  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final next = IslamicUtils.nextPrayer(now, location.lat, location.lng);
    final qibla = IslamicUtils.qiblaBearing(
      lat: location.lat,
      lng: location.lng,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Capsule(
                icon: Icons.notifications_active_outlined,
                title: 'الأذان القادم',
                value:
                    '${next.name} بعد ${AppUtils.durationWords(next.remaining)}',
                onTap: () => showPrayerTimesSheet(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Capsule(
                icon: Icons.explore_outlined,
                iconRotation: qibla * math.pi / 180,
                title: 'القبلة',
                value: '${qibla.round()}° من الشمال',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QiblaScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Capsule(
                icon: Icons.menu_book_outlined,
                title: 'الزيارة اليومية',
                value: IslamicUtils.dailyZiyaratFor(now),
                onTap: () => showZiyarahSheet(context, now: now),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Capsule(
                icon: suggesting
                    ? Icons.hourglass_top_rounded
                    : Icons.casino_outlined,
                title: 'مجلس اليوم',
                value: suggesting
                    ? 'نبحث عن مجلس...'
                    : 'اضغط لاقتراح لطمية',
                gold: true,
                onTap: onSuggest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'الموقع: ${location.nameAr} — اضغط الكبسولات للتفاصيل',
            style: textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule({
    required this.icon,
    required this.title,
    required this.value,
    this.iconRotation = 0,
    this.gold = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final double iconRotation;
  final bool gold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Transform.rotate(
                  angle: iconRotation,
                  child: Icon(
                    icon,
                    size: 17,
                    color: gold ? AppColors.gold : AppColors.red,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(fontSize: 12),
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_left_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: gold ? AppColors.goldLight : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// صفحة "كل الرواديد" — تُفتح من العتبة لعرض الشبكة الكاملة.
class _AllRecitersPage extends StatelessWidget {
  const _AllRecitersPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AtabaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        size: 32,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: RecitersScreen()),
            ],
          ),
        ),
      ),
    );
  }
}
