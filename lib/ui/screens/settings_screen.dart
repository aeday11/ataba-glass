import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/security.dart';
import '../../core/theme.dart';
import '../../state/player_provider.dart';
import '../../state/store_provider.dart';
import '../widgets/glass.dart';
import 'certificate_screen.dart';

/// صفحة الضبط: ألوان الثيم، مستوى الصوت، معلومات المبرمج وشهادة التوثيق.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final player = context.watch<PlayerProvider>();
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 150),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الضبط', style: textTheme.displaySmall),
              const SizedBox(height: 3),
              Text(
                'ألوان التطبيق، مستوى الصوت، وشهادة التوثيق',
                style: textTheme.bodySmall?.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),

        _SectionTitle(
          icon: Icons.palette_outlined,
          title: 'ألوان الثيم',
          subtitle: 'اختر لوناً يغيّر إضاءة التطبيق فوراً',
        ),
        const SizedBox(height: 10),
        GlassCard(
          blur: true,
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in appThemePresets)
                _ThemePresetTile(
                  preset: preset,
                  selected: store.themeId == preset.id,
                  onTap: () => context.read<StoreProvider>().setThemeId(preset.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _SectionTitle(
          icon: Icons.volume_up_rounded,
          title: 'مستوى الصوت',
          subtitle: 'يُحفظ تلقائياً ويُطبّق على كل المقاطع',
        ),
        const SizedBox(height: 10),
        GlassCard(
          blur: true,
          radius: 24,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  GlassIcon(
                    icon: player.volume == 0
                        ? Icons.volume_off_rounded
                        : Icons.graphic_eq_rounded,
                    color: AppColors.goldLight,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _volumeLabel(player.volume),
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'صوت التشغيل الحالي',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(player.volume * 100).round()}%',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.volume_mute_rounded,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                  Expanded(
                    child: Slider(
                      value: player.volume,
                      divisions: 100,
                      label: '${(player.volume * 100).round()}%',
                      onChanged: (value) {
                        context.read<PlayerProvider>().previewVolume(value);
                      },
                      onChangeEnd: (_) {
                        context.read<PlayerProvider>().persistVolume();
                      },
                    ),
                  ),
                  Icon(
                    Icons.volume_up_rounded,
                    size: 19,
                    color: AppColors.goldLight,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _SectionTitle(
          icon: Icons.verified_user_outlined,
          title: 'المبرمج والتوثيق',
          subtitle: 'معلومات الإصدار وشهادة الأصالة',
        ),
        const SizedBox(height: 10),
        GlassCard(
          blur: true,
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'دمعه عشق',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'برمجة وتصميم: عدي رويح الحاتمي',
                          style: textTheme.bodySmall?.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 14),
              _InfoRow(
                label: 'رقم التوثيق',
                value: SecurityStatus.verificationCode,
                ltr: true,
              ),
              const SizedBox(height: 10),
              FutureBuilder<PackageInfo>(
                future: _packageInfo,
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  final version = info == null
                      ? '—'
                      : '${info.version}+${info.buildNumber}';
                  return _InfoRow(label: 'إصدار التطبيق', value: version, ltr: true);
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CertificateScreen(),
                  ),
                ),
                icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                label: const Text('عرض شهادة التوثيق'),
              ),
              const SizedBox(height: 8),
              Text(
                'تُعتمد الشهادة بمطابقة بصمة توقيع التطبيق مع النسخة الموثّقة لدى المبرمج.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(fontSize: 11.5, height: 1.7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _volumeLabel(double value) {
    if (value <= 0) return 'صامت';
    if (value < 0.35) return 'هادئ';
    if (value < 0.75) return 'متوسط';
    return 'عالٍ';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Row(
        children: [
          GlassIcon(icon: icon, size: 17, color: AppColors.goldLight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 1),
                Text(subtitle, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 88,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? preset.primary.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? preset.primary.withValues(alpha: 0.75)
                  : AppColors.glassBorder,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [preset.primary, preset.secondary],
                  ),
                  border: Border.all(color: AppColors.glassBorderStrong),
                  boxShadow: [
                    BoxShadow(
                      color: preset.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 21,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                preset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.ltr = false,
  });

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(label, style: textTheme.bodySmall),
        const Spacer(),
        Directionality(
          textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.goldLight,
            ),
          ),
        ),
      ],
    );
  }
}
