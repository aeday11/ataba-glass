import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

/// كلمة سر لوحة المطوّر — اللوحة نفسها مخفية وراء ضغطات سرّية على العنوان،
/// ولا تُفتح بدون هذه العبارة (لا تظهر لأي مستخدم عادي).
const String adminPassphrase = 'Khadem1447';

/// معرّف جهاز المطوّر — المرحلة الثانية: انسخ المعرّف المعروض في اللوحة
/// وضعه هنا ليصبح الدخول حصراً بجهازك (فارغ = تكتفي اللوحة بكلمة السر).
const String ownerDeviceId = '';

/// قناة أندرويد (MainActivity) لجلب معرّف الجهاز.
const MethodChannel _securityChannel = MethodChannel('rihal/security');

/// معرّف الجهاز الحالي على أندرويد، أو `null` عند عدم التوفّر.
Future<String?> readDeviceId() async {
  try {
    final id = await _securityChannel.invokeMethod<String>('deviceId');
    return (id == null || id.isEmpty) ? null : id;
  } catch (_) {
    return null;
  }
}

/// تسجيل أول تشغيل وعدد مرات التشغيل (إحصائيات لوحة المطوّر).
Future<void> registerLaunch() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('admin_first_launch')) {
      await prefs.setInt(
        'admin_first_launch',
        DateTime.now().millisecondsSinceEpoch,
      );
    }
    await prefs.setInt(
      'admin_launch_count',
      (prefs.getInt('admin_launch_count') ?? 0) + 1,
    );
  } catch (_) {}
}

/// نافذة كلمة سر اللوحة — تُرجع `true` عند النجاح فقط.
///
/// المتحكّم يعيش داخل ودجت النافذة نفسه، فلا يُغلق إلا بعد اكتمال حركة
/// خروج المسار (وإلا بقي `TextField` يستخدمه بعد التخلّي — خطأ في الاختبارات).
Future<bool> askAdminPassphrase(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _AdminPassphraseDialog(),
  );
  return ok ?? false;
}

class _AdminPassphraseDialog extends StatefulWidget {
  const _AdminPassphraseDialog();

  @override
  State<_AdminPassphraseDialog> createState() => _AdminPassphraseDialogState();
}

class _AdminPassphraseDialogState extends State<_AdminPassphraseDialog> {
  final _controller = TextEditingController();
  String _errorText = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    String? err;
    if (_controller.text != adminPassphrase) {
      err = 'كلمة سر غير صحيحة';
    } else if (ownerDeviceId.isNotEmpty &&
        await readDeviceId() != ownerDeviceId) {
      err = 'هذا الجهاز غير مفعّل';
    }
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      final message = err;
      setState(() => _errorText = message);
    }
  }

  void _cancel() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    final errorText = _errorText;
    return AlertDialog(
      backgroundColor: const Color(0xFF171014),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.glassBorderStrong),
      ),
      title: Text(
        'لوحة المطوّر',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.decorative,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.gold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'أدخل كلمة السر للمتابعة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 16,
              letterSpacing: 2,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.glassBorderStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.gold),
              ),
            ),
          ),
          if (errorText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                errorText,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: AppColors.red,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text(
            'إلغاء',
            style: TextStyle(
              fontFamily: AppFonts.body,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            'دخول',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}
