import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/admin.dart';
import '../../core/github_stats.dart';
import '../../core/security.dart';
import '../../core/theme.dart';
import '../widgets/glass.dart';

/// لوحة المطوّر المخفية: عدّاد تنزيلات التطبيق من GitHub + إحصائيات الجهاز.
/// لا تظهر في أي مكان من الواجهة — تُفتح بخمس ضغطات على العنوان ثم كلمة السر.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();

  ReleaseStats? _stats;
  bool _configured = false;
  bool _loading = false;
  String? _error;
  String? _notice;

  String? _deviceId;
  String _version = '—';
  DateTime? _firstLaunch;
  int _launchCount = 0;
  SecurityStatus _security = SecurityStatus.unknown;
  (int, int)? _localDownloads; // (عدد الملفات، الحجم بالبايت)

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _repoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final (owner, repo) = await GithubCounter.savedRepo();
    _configured = owner.isNotEmpty && repo.isNotEmpty;
    if (_configured) {
      _ownerController.text = owner;
      _repoController.text = repo;
    }
    _stats = await GithubCounter.cached();

    final deviceId = await readDeviceId();
    var version = '—';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {}

    DateTime? firstLaunch;
    var launches = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt('admin_first_launch');
      firstLaunch = millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis);
      launches = prefs.getInt('admin_launch_count') ?? 0;
    } catch (_) {}

    final security = await SecurityStatus.check();
    final local = await _localDownloadsStats();

    if (!mounted) return;
    setState(() {
      _deviceId = deviceId;
      _version = version;
      _firstLaunch = firstLaunch;
      _launchCount = launches;
      _security = security;
      _localDownloads = local;
    });

    if (_configured) await _refresh();
  }

  Future<(int, int)> _localDownloadsStats() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}${Platform.pathSeparator}downloads');
      if (!dir.existsSync()) return (0, 0);
      var files = 0;
      var bytes = 0;
      await for (final entry in dir.list()) {
        if (entry is File) {
          files++;
          bytes += await entry.length();
        }
      }
      return (files, bytes);
    } catch (_) {
      return (0, 0);
    }
  }

  Future<void> _refresh() async {
    final owner = _ownerController.text.trim();
    final repo = _repoController.text.trim();
    if (owner.isEmpty || repo.isEmpty) {
      setState(() => _error = 'أدخل مالك المستودع واسمها أولاً');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    try {
      final stats =
          await GithubCounter.fetch(owner: owner, repo: repo);
      await GithubCounter.saveRepo(owner, repo);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _configured = true;
        _loading = false;
        _notice = 'حُدِّث العدد بنجاح';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###', 'en');

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // الترويسة
                      Text(
                        'لوحة المطوّر',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.decorative,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'الأعداد والإحصائيات — مخفية عن غيرك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // عدّاد التنزيلات
                      GlassCard(
                        blur: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'عدد من نزّل التطبيق',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _stats == null
                                  ? '—'
                                  : numberFormat.format(_stats!.downloads),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: AppColors.goldLight,
                              ),
                            ),
                            if (_stats != null &&
                                _stats!.tagName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'الإصدار: ${_stats!.tagName}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (_stats?.publishedAt != null)
                              Text(
                                'آخر تحديث: ${_date(_stats!.publishedAt!)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 14),
                            if (!_configured) ...[
                              _repoField('المالك (اسم المستخدم)', _ownerController),
                              const SizedBox(height: 8),
                              _repoField('اسم المستودع', _repoController),
                            ] else
                              Text(
                                'github.com/${_ownerController.text}/${_repoController.text}',
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _loading ? null : _refresh,
                                    icon: _loading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF12060A),
                                            ),
                                          )
                                        : const Icon(Icons.refresh_rounded,
                                            size: 18),
                                    label: Text(
                                      _configured ? 'تحديث' : 'تفعيل العدّاد',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: const Color(0xFF12060A),
                                      textStyle: const TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_configured) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _configured = false),
                                    child: const Text(
                                      'تغيير',
                                      style: TextStyle(
                                        fontFamily: AppFonts.body,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontSize: 12,
                                    color: AppColors.red,
                                  ),
                                ),
                              ),
                            if (_notice != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _notice!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontSize: 12,
                                    color: AppColors.goldLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // إحصائيات الجهاز
                      GlassCard(
                        blur: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'إحصائيات الجهاز',
                              style: TextStyle(
                                fontFamily: AppFonts.decorative,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _stat('نسخة التطبيق', _version, ltr: true),
                            _stat(
                              'أول تشغيل',
                              _firstLaunch == null
                                  ? '—'
                                  : _date(_firstLaunch!),
                            ),
                            _stat('مرات التشغيل', '$_launchCount', ltr: true),
                            _stat(
                              'حالة الجهاز',
                              _security.rooted == null
                                  ? 'يُفحص على الهاتف'
                                  : (_security.rooted!
                                      ? 'تنبيه: مُتجذّر ⚠'
                                      : 'سليم ✓'),
                              tone: _security.rooted == true
                                  ? AppColors.red
                                  : AppColors.goldLight,
                            ),
                            _stat(
                              'وضع المطوّر',
                              _security.debugger == null
                                  ? 'يُفحص على الهاتف'
                                  : (_security.debugger! ? 'مفتوح ⚠' : 'مغلق ✓'),
                              tone: _security.debugger == true
                                  ? AppColors.red
                                  : AppColors.goldLight,
                            ),
                            _stat(
                              'تنزيلات داخل التطبيق',
                              _localDownloads == null
                                  ? '—'
                                  : '${_localDownloads!.$1} ملف — ${_mb(_localDownloads!.$2)}',
                            ),
                            _stat(
                              'بصمة توقيع التطبيق',
                              SecurityStatus.expectedSignature,
                              ltr: true,
                              small: true,
                            ),
                            const SizedBox(height: 8),
                            // معرّف الجهاز (لربطه بالمطوّر).
                            const Text(
                              'معرّف هذا الجهاز',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _deviceId ?? 'غير متاح على هذه المنصة',
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _deviceId == null
                                      ? null
                                      : () async {
                                          await Clipboard.setData(
                                            ClipboardData(text: _deviceId!),
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'نُسخ معرّف الجهاز',
                                                  style: TextStyle(
                                                    fontFamily: AppFonts.body,
                                                  ),
                                                ),
                                                duration:
                                                    Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                  icon: Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                    color: AppColors.gold,
                                  ),
                                  tooltip: 'نسخ المعرّف',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _repoField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      style: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.glassBorderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.gold),
        ),
      ),
    );
  }

  Widget _stat(
    String label,
    String value, {
    bool ltr = false,
    bool small = false,
    Color? tone,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                fontSize: small ? 11 : 13,
                fontWeight: FontWeight.w700,
                color: tone ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime d) {
    try {
      return DateFormat('d MMMM y — HH:mm', 'ar').format(d);
    } catch (_) {
      return '${d.year}/${d.month}/${d.day}';
    }
  }

  static String _mb(int bytes) {
    if (bytes <= 0) return '0 م.ب';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';
  }
}
