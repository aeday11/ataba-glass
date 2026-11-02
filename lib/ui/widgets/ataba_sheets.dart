import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/islamic_utils.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/iraq_locations.dart';
import '../../state/location_provider.dart';
import 'glass.dart';

/// مواقيت الصلاة اليوم في الموقع المختار مع زر تغيير الموقع.
void showPrayerTimesSheet(BuildContext context) {
  final location = context.read<LocationProvider>().current;
  final now = DateTime.now();
  final times = IslamicUtils.todayPrayerTimes(now, location.lat, location.lng);
  final next = IslamicUtils.nextPrayer(now, location.lat, location.lng);
  final nextIndex = IslamicUtils.prayerNames.indexOf(next.name);

  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مواقيت الصلاة', style: Theme.of(sheetContext).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'في محافظة ${location.nameAr} — ${location.seatAr}',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < times.length; i++)
              _PrayerRow(
                name: IslamicUtils.prayerNames[i],
                time: times[i],
                highlighted: i == nextIndex,
              ),
            const SizedBox(height: 14),
            GlassCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${next.name} بعد ${AppUtils.durationWords(next.remaining)}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  showLocationPickerSheet(context);
                },
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: const Text('تغيير الموقع'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// بوصلة القبلة: الاتجاه والمسافة إلى الكعبة من الموقع المختار.
void showQiblaSheet(BuildContext context) {
  final location = context.read<LocationProvider>().current;
  final bearing = IslamicUtils.qiblaBearing(lat: location.lat, lng: location.lng);
  final distance = IslamicUtils.distanceToKaaba(
    lat: location.lat,
    lng: location.lng,
  );

  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اتجاه القبلة', style: Theme.of(sheetContext).textTheme.headlineMedium),
            const SizedBox(height: 2),
            Text(
              'من محافظة ${location.nameAr}',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            _QiblaCompass(bearing: bearing),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                GlassCapsule(
                  child: Text(
                    '${bearing.round()}° من الشمال',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
                GlassCapsule(
                  child: Text(
                    'المسافة إلى الكعبة ≈ ${distance.round()} كم',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'أضِب طرف هاتفك واتّجه حتى يستقيم السهم مع الذهب.',
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  showLocationPickerSheet(context);
                },
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: const Text('تغيير الموقع'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// بطاقة الزيارة اليومية.
void showZiyarahSheet(BuildContext context, {DateTime? now}) {
  final current = IslamicUtils.dailyZiyaratFor(now);
  final tomorrow = IslamicUtils.dailyZiyaratFor(
    (now ?? DateTime.now()).add(const Duration(days: 1)),
  );

  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            GoldGlowText(current, fontSize: 28),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              'السلام عليك يا أبا عبد الله — زيارتك مقبولة عند الله.',
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.8,
                  ),
            ),
            const SizedBox(height: 14),
            GlassCapsule(
              child: Text(
                'غداً: $tomorrow',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// اختيار الموقع من كل محافظات العراق.
void showLocationPickerSheet(BuildContext context) {
  final currentId = context.read<LocationProvider>().current.id;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
              child: Text(
                'اختر محافظتك',
                style: Theme.of(sheetContext).textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text(
                'تُحسب المواقيت والقبلة حسب اختيارك — كل محافظات العراق.',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                itemCount: iraqGovernorates.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final g = iraqGovernorates[index];
                  final selected = g.id == currentId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GlassCard(
                      radius: 16,
                      color: selected
                          ? AppColors.red.withValues(alpha: 0.14)
                          : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          context.read<LocationProvider>().select(g);
                          Navigator.of(sheetContext).pop();
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 22,
                              color: selected
                                  ? AppColors.red
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.nameAr,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (g.seatAr.isNotEmpty) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      g.seatAr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontSize: 11.5),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.gold,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.name,
    required this.time,
    required this.highlighted,
  });

  final String name;
  final DateTime time;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final timeText = AppUtils.arabicDigits(
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}',
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlighted ? AppColors.red : Colors.transparent,
              boxShadow: highlighted
                  ? [BoxShadow(color: AppColors.redGlow, blurRadius: 8)]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                color: highlighted
                    ? AppColors.goldLight
                    : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
              color: highlighted ? AppColors.goldLight : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// بوصلة القبلة الحية: حسّاسات الهاتف (مغناطيسي + تسارع) تحرّك السهم
/// فعلياً مع دوران الجهاز — مع مسار احتياطي ثابت إن غابت الحسّاسات.
class _QiblaCompass extends StatefulWidget {
  const _QiblaCompass({required this.bearing});

  final double bearing;

  @override
  State<_QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<_QiblaCompass> {
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<AccelerometerEvent>? _accSub;

  double? _mx, _my, _mz, _ax, _ay, _az;
  double? _heading;
  double _lastSet = -999;

  @override
  void initState() {
    super.initState();
    // الحسّاسات متوفرة على الهواتف فقط (لا في الاختبارات أو سطح المكتب).
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _accSub = accelerometerEventStream().listen(
      (e) {
        _ax = e.x;
        _ay = e.y;
        _az = e.z;
        _recompute();
      },
      onError: (_) {},
    );
    _magSub = magnetometerEventStream().listen(
      (e) {
        _mx = e.x;
        _my = e.y;
        _mz = e.z;
        _recompute();
      },
      onError: (_) {},
    );
  }

  /// حساب اتجاه الجهاز من الشمال بتعويض الميل (tilt-compensated).
  void _recompute() {
    final mx = _mx, my = _my, mz = _mz, ax = _ax, ay = _ay, az = _az;
    if (mx == null ||
        my == null ||
        mz == null ||
        ax == null ||
        ay == null ||
        az == null) {
      return;
    }

    // متجه "أعلى" = اتجاه التسارع المعاكس للجاذبية.
    final al = math.sqrt(ax * ax + ay * ay + az * az);
    if (al < 1e-6) return;
    final ux = ax / al, uy = ay / al, uz = az / al;

    // إسقاط المجال المغناطيسي على المستوى الأفقي.
    final d = mx * ux + my * uy + mz * uz;
    final hx = mx - ux * d, hy = my - uy * d, hz = mz - uz * d;
    if (math.sqrt(hx * hx + hy * hy + hz * hz) < 1e-6) return;

    var heading = math.atan2(-hx, hy) * 180 / math.pi;
    if (heading < 0) heading += 360;

    // تحديث مقتصد: درجة واحدة تكفي للعين.
    if (_lastSet >= 0 && (heading - _lastSet).abs() < 0.9) return;
    _lastSet = heading;
    if (mounted) setState(() => _heading = heading);
  }

  @override
  void dispose() {
    _magSub?.cancel();
    _accSub?.cancel();
    super.dispose();
  }

  double get _diff {
    final h = _heading;
    if (h == null) return widget.bearing;
    return (widget.bearing - h + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    final live = _heading != null;
    final aligned = live && (_diff < 6 || _diff > 354);
    final rotation = _heading == null ? widget.bearing : _diff;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glassFillStrong,
                  border: Border.all(color: AppColors.glassBorderStrong),
                  boxShadow: [
                    BoxShadow(
                      color: aligned
                          ? AppColors.gold.withValues(alpha: 0.45)
                          : AppColors.redGlow,
                      blurRadius: aligned ? 46 : 36,
                    ),
                  ],
                ),
              ),
              // الاتجاهات القياسية (فيزيائية).
              const Positioned(top: 10, child: Text('ش', style: _dirStyle)),
              const Positioned(bottom: 10, child: Text('ج', style: _dirStyle)),
              const Positioned(left: 14, child: Text('غ', style: _dirStyle)),
              const Positioned(right: 14, child: Text('ق', style: _dirStyle)),
              // السهم الذهبي نحو القبلة — يتبع دوران الهاتف.
              Transform.rotate(
                angle: rotation * math.pi / 180,
                child: Icon(
                  Icons.navigation_rounded,
                  size: 62,
                  color: aligned ? AppColors.gold : AppColors.goldLight,
                  shadows: [
                    Shadow(color: AppColors.redGlow, blurRadius: 16),
                  ],
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (aligned)
          Text(
            'أنت تواجه القبلة الآن ✓',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.goldLight,
            ),
          )
        else if (live)
          Text(
            'اتجاهك من الشمال: ${AppUtils.arabicDigits('${_heading!.round()}')}°',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  static const TextStyle _dirStyle = TextStyle(
    fontFamily: AppFonts.decorative,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );
}
