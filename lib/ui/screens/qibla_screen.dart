import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/islamic_utils.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/iraq_locations.dart';
import '../../state/location_provider.dart';
import '../widgets/glass.dart';

/// صفحة "اتجاه القبلة" — بوصلة تفاعلية + اتجاه القبلة المحسوب (كعبة 21.4225° N / 39.8262° E).
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const double _circleSize = 250;
  static const double _needleSize = 132;
  static const double _tolerance = 6;

  StreamSubscription<CompassEvent>? _compassSub;
  bool _compassReady = false;
  double? _heading;

  /// وضع العرض: true = البوصلة (تفعيل مباشر بالمغناطيس)، false = الواقع المعزز (حساب دقيق).
  bool _compassMode = true;
  double? _deviceLat;
  double? _deviceLng;

  @override
  void initState() {
    super.initState();
    _startCompass();
    _loadDeviceLocation();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  Future<void> _startCompass() async {
    // الحساسات متوفرة على الهواتف فقط (لا في الاختبارات أو سطح المكتب).
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (mounted) {
        setState(() => _compassReady = false);
      }
      return;
    }
    final stream = FlutterCompass.events;
    if (stream == null) {
      if (mounted) {
        setState(() => _compassReady = false);
      }
      return;
    }
    _compassSub = stream.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _compassReady = true;
          _heading = event.heading;
        });
      },
      onError: (_) {
        if (mounted) {
          setState(() => _compassReady = false);
        }
      },
    );
  }

  Future<void> _loadDeviceLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled && mounted) {
        var status = await Geolocator.checkPermission();
        if (status == LocationPermission.denied ||
            status == LocationPermission.deniedForever) {
          status = await Geolocator.requestPermission();
        }
        if ((status == LocationPermission.always ||
                status == LocationPermission.whileInUse) &&
            mounted) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
          );
          if (mounted) {
            setState(() {
              _deviceLat = pos.latitude;
              _deviceLng = pos.longitude;
            });
          }
        }
      }
    } catch (_) {
      // نتجاهل أي خطأ في طلب/قراءة الموقع.
    }
  }

  Governorate get _location => context.read<LocationProvider>().current;

  double get _lat => _compassMode ? _location.lat : (_deviceLat ?? _location.lat);

  double get _lng => _compassMode ? _location.lng : (_deviceLng ?? _location.lng);

  /// زاوية القبلة بالدرجات (قانون atan2 من موقع المستخدم إلى الكعبة).
  double get _bearing => IslamicUtils.qiblaBearing(lat: _lat, lng: _lng);

  /// الانحراف بين اتجاه الجهاز الحالي والقبلة.
  double get _deviation {
    final heading = _heading;
    if (heading == null) return _bearing;
    final d = _bearing - heading;
    return d < 0 ? d + 360 : d;
  }

  bool get _aligned => _compassMode
      ? (_heading != null && (_deviation < _tolerance || _deviation > 360 - _tolerance))
      : true;

  double get _rotation => _compassMode ? _deviation : _bearing;

  /// النص العمودي فوق البوصلة: "X° من الشرق" — يتغير حسب موقع المستخدم.
  String get _qiblaAngleText {
    final bearing = _bearing % 360;
    final fromEast = ((bearing - 90) % 360 + 360) % 360;
    return '${AppUtils.arabicDigits(fromEast.toStringAsFixed(1))}° من الشرق';
  }

  void _resetCompass() {
    setState(() {
      _heading = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AtabaBackground(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              children: [
                // الترويسة.
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اتجاه القبلة', style: textTheme.displaySmall),
                      const SizedBox(height: 2),
                      Text(
                        'من محافظة ${context.watch<LocationProvider>().current.nameAr}',
                        style: textTheme.bodySmall?.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _ModeSwitch(
                  compassMode: _compassMode,
                  onSelect: (value) => setState(() => _compassMode = value),
                ),
                const SizedBox(height: 16),

                // النص فوق البوصلة + البوصلة + التنبيه تحتها.
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _QiblaAngleText(text: _qiblaAngleText),
                      const SizedBox(height: 18),
                      _QiblaCompass(
                        size: _circleSize,
                        needleSize: _needleSize,
                        rotation: _rotation,
                        aligned: _aligned,
                      ),
                      const SizedBox(height: 12),
                      _QiblaStatus(aligned: _aligned, compassReady: _compassReady),
                    ],
                  ),
                ),

                // زر تغيير وجهة البوصلة.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetCompass,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('تغيير وجهة البوصلة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// زران أعلى الصفحة: "البوصلة" باللون الأخضر (فعّال) و"الواقع المعزز" بجانبه.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.compassMode,
    required this.onSelect,
  });

  final bool compassMode;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            label: 'البوصلة',
            icon: Icons.navigation_rounded,
            active: compassMode,
            onPressed: () => onSelect(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeButton(
            label: 'الواقع المعزز',
            icon: Icons.gps_fixed_rounded,
            active: !compassMode,
            onPressed: () => onSelect(false),
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: active
                ? AppColors.green.withValues(alpha: 0.16)
                : AppColors.glassFillStrong,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.green.withValues(alpha: 0.55) : AppColors.glassBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.green : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.green : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// النص العمودي فوق البوصلة: "X° من الشرق".
class _QiblaAngleText extends StatelessWidget {
  const _QiblaAngleText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.decorative,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.goldLight,
        height: 1.2,
      ),
    );
  }
}

/// البوصلة الكبيرة: دائرة داكنة + حروف الاتجاهات (E, S, W, N) + سهم أبيض وأخضر نحو القبلة
/// + أيقونة الكعبة الخضراء على محيط الدائرة.
class _QiblaCompass extends StatelessWidget {
  const _QiblaCompass({
    required this.size,
    required this.needleSize,
    required this.rotation,
    required this.aligned,
  });

  final double size;
  final double needleSize;
  final double rotation;
  final bool aligned;

  static const TextStyle _dirStyle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF141414),
              border: Border.all(color: AppColors.glassBorderStrong),
              boxShadow: [
                BoxShadow(
                  color: aligned ? AppColors.green.withValues(alpha: 0.55) : AppColors.redGlow,
                  blurRadius: aligned ? 46 : 36,
                ),
              ],
            ),
          ),
          // حروف الاتجاهات الأربع على محيط الدائرة.
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: Center(child: Text('N', style: _dirStyle)),
          ),
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(child: Text('S', style: _dirStyle)),
          ),
          Positioned(
            right: 6,
            top: 6,
            bottom: 6,
            child: Center(child: Text('E', style: _dirStyle)),
          ),
          Positioned(
            left: 6,
            top: 6,
            bottom: 6,
            child: Center(child: Text('W', style: _dirStyle)),
          ),
          // السهم الأبيض والأخضر نحو اتجاه القبلة.
          Transform.rotate(
            angle: rotation * math.pi / 180,
            child: SizedBox(
              width: needleSize,
              height: needleSize,
              child: CustomPaint(painter: _NeedlePainter()),
            ),
          ),
          // أيقونة الكعبة الخضراء على محيط الدائرة.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.mosque_rounded, size: 18, color: AppColors.green),
            ),
          ),
        ],
      ),
    );
  }
}

/// سهم البوصلة: خيط أخضر مع حد أبيض — يشير إلى اتجاه القبلة.
class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, -h * 0.40)
      ..lineTo(w * 0.7, -h * 0.14)
      ..lineTo(w * 0.3, -h * 0.14)
      ..close();
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.green;
    canvas.drawPath(path, fill);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter oldDelegate) => false;
}

/// التنبيه تحت البوصلة: تذكير بالأفقي أو نص النجاح عند تمركز القبلة.
class _QiblaStatus extends StatelessWidget {
  const _QiblaStatus({required this.aligned, required this.compassReady});

  final bool aligned;
  final bool compassReady;

  @override
  Widget build(BuildContext context) {
    if (compassReady && aligned) {
      return Text(
        'أنت تواجه القبلة الآن ✓',
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: AppColors.goldLight,
        ),
      );
    }
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'اجعل الهاتف بوضع أفقي للحصول على نتائج دقيقة',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
