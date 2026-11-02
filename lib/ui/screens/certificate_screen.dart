import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/security.dart';
import '../../core/theme.dart';
import '../widgets/glass.dart';

/// شهادة التوثيق — وثيقة زجاجية تُشهد بأصالة التطبيق وتوقيعه الرقمي،
/// صادرة عن المطوّر عدي رويح الحاتمي.
class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  late final Future<(_CertData data, SecurityStatus security)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(_CertData data, SecurityStatus security)> _load() async {
    var version = '1.0.0';
    var build = 1;
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      build = int.tryParse(info.buildNumber) ?? 1;
    } catch (_) {}
    final security = await SecurityStatus.check();
    return (_CertData(version, build), security);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AtabaBackground(
        child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8, top: 4),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'رجوع',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<(_CertData, SecurityStatus)>(
                future: _future,
                builder: (context, snapshot) {
                  final data = snapshot.data?.$1;
                  final security = snapshot.data?.$2 ?? SecurityStatus.unknown;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: GlassCard(
                      blur: true,
                      glow: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: Text(
                              'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'شهادة توثيق',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFonts.decorative,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تطبيق «دمعه عشق» — إصدار ${_ltr('${data?.version ?? '1.0.0'}+${data?.build ?? 1}')}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.divider, height: 1),
                          const SizedBox(height: 16),
                          const Text(
                            'يشهد المطوّر عدي رويح الحاتمي بأن هذا التطبيق '
                            'تطبيقٌ أصيلٌ موثّق، صُمِّم ورُوِّجَ وبُرِمِج بإشرافه '
                            'الكامل، مخصّصٌ للاستماع لمراسيم وأناشيد الرواديد '
                            'الحسينيين، ولم يُعَد تغليفه أو يُعدَّل بتوقيعٍ غير '
                            'المعتمد.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14.5,
                              height: 1.9,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _infoRow('المطوّر والمعتمِد:', 'عدي رويح الحاتمي',
                              emphasize: true),
                          _infoRow(
                            'رقم التوثيق:',
                            SecurityStatus.verificationCode,
                            ltr: true,
                          ),
                          _infoRow('تاريخ الشهادة:', _today()),
                          _infoRow(
                            'بصمة التوقيع:',
                            _shortHash(SecurityStatus.expectedSignature),
                            ltr: true,
                            small: true,
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.divider, height: 1),
                          const SizedBox(height: 12),
                          Text(
                            'حَالَةُ الحِمايَة والتوثيق',
                            style: TextStyle(
                              fontFamily: AppFonts.decorative,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _statusRow(
                            'النسخة:',
                            _authenticText(security.isAuthentic),
                            tone: _authenticTone(security.isAuthentic),
                          ),
                          _statusRow(
                            'جهازك:',
                            security.rooted == null
                                ? 'يُفحص على الهاتف'
                                : (security.rooted!
                                    ? 'تنبيه: جهاز مُتجذّر ⚠'
                                    : 'سليم ✓'),
                            tone: security.rooted == null
                                ? AppColors.textSecondary
                                : (security.rooted!
                                    ? AppColors.red
                                    : AppColors.goldLight),
                          ),
                          _statusRow(
                            'وضع المطوّر:',
                            security.debugger == null
                                ? 'يُفحص على الهاتف'
                                : (security.debugger! ? 'مفتوح ⚠' : 'مغلق ✓'),
                            tone: security.debugger == null
                                ? AppColors.textSecondary
                                : (security.debugger!
                                    ? AppColors.red
                                    : AppColors.goldLight),
                          ),
                          if (security.emulator == true)
                            _statusRow(
                              'الجهاز:',
                              'مُحاكي أندرويد',
                              tone: AppColors.textSecondary,
                            ),
                          if (security.signatureSha256?.isNotEmpty ?? false)
                            _statusRow(
                              'بصمة نسختك:',
                              _shortHash(security.signatureSha256!),
                              tone: AppColors.textSecondary,
                              ltr: true,
                              small: true,
                            ),
                          const SizedBox(height: 18),
                          // ختم الشهادة.
                          Center(
                            child: Transform.rotate(
                              angle: -0.12,
                              child: Container(
                                width: 108,
                                height: 108,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.red.withValues(alpha: 0.75),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.redGlow,
                                      blurRadius: 22,
                                    ),
                                  ],
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'مُوثَّق',
                                        style: TextStyle(
                                          fontFamily: AppFonts.decorative,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.red,
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_rounded,
                                        color: AppColors.red,
                                        size: 22,
                                      ),
                                      Text(
                                        'دمعه عشق',
                                        style: TextStyle(
                                          fontFamily: AppFonts.body,
                                          fontSize: 10,
                                          color: AppColors.red,
                                        ),
                                      ),
                                      Text(
                                        SecurityStatus.verificationCode,
                                        style: TextStyle(
                                          fontFamily: AppFonts.body,
                                          fontSize: 8,
                                          color: AppColors.red,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                           ),
                          const SizedBox(height: 16),
                          const Text(
                            'تُعتمد هذه الشهادة بمطابقة بصمة توقيع التطبيق '
                            'مع النسخة الموثّقة لدى المطوّر.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 11.5,
                              height: 1.7,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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

  static String _today() {
    try {
      return DateFormat('d MMMM y', 'ar').format(DateTime.now());
    } catch (_) {
      final now = DateTime.now();
      return '${now.year}/${now.month}/${now.day}';
    }
  }

  /// تغليف نص لاتيني/رقمي بعزل اتجاهي لئلا يعكسه النص العربي.
  static String _ltr(String s) => '\u2066$s\u2069';

  static String _shortHash(String hash) {
    if (hash.isEmpty) return 'تُفحص على الهاتف';
    final parts = hash.split(':');
    if (parts.length < 8) return hash;
    return '${parts.take(6).join(':')}…${parts.skip(parts.length - 3).join(':')}';
  }

  static String _authenticText(bool? v) => switch (v) {
        true => 'مُوثَّقة أصلية ✓',
        false => 'مُعاد توقيعها — غير موثّقة ⚠',
        null => 'تُفحص على الهاتف',
      };

  static Color _authenticTone(bool? v) => switch (v) {
        true => AppColors.goldLight,
        false => AppColors.red,
        null => AppColors.textSecondary,
      };

  Widget _infoRow(
    String label,
    String value, {
    bool emphasize = false,
    bool ltr = false,
    bool small = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textDirection: ltr ? TextDirection.ltr : null,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: small ? 11 : 13.5,
                fontWeight: FontWeight.w700,
                color: color ??
                    (emphasize ? AppColors.goldLight : AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(
    String label,
    String value, {
    required Color tone,
    bool ltr = false,
    bool small = false,
  }) {
    return _infoRow(label, value, color: tone, ltr: ltr, small: small);
  }
}

class _CertData {
  const _CertData(this.version, this.build);

  final String version;
  final int build;
}
