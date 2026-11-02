import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';

/// أيقونة دائرية ملوّنة للرادد (أو صورته من السيرفر إن وُجدت).
class ReciterAvatar extends StatelessWidget {
  const ReciterAvatar({super.key, required this.reciter, this.size = 56});

  final Reciter reciter;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = reciter.imageUrl;

    // البديل: شارة التطبيق — بدون حروف.
    Widget badge() => ClipOval(
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );

    if (image == null || image.isEmpty) return badge();

    return ClipOval(
      child: image.startsWith('assets/')
          ? Image.asset(
              image,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => badge(),
            )
          : Image.network(
              image,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => badge(),
            ),
    );
  }
}

/// أشرطة الحركة التي تشير للمقطع قيد التشغيل.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    this.color,
    this.height = 16,
  });

  final Color? color;
  final double height;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            final phase = i * 0.31;
            final wave =
                0.5 + 0.5 * math.sin(2 * math.pi * (_controller.value + phase));
            final h = 4.0 + (widget.height - 4) * (0.3 + 0.7 * wave);
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 2.5),
              child: Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: widget.color ?? AppColors.gold,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// حالة فارغة موحّدة.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.glassFillStrong,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.divider),
              ),
              child: Icon(icon, size: 34, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(height: 1.7),
              ),
            ],
            if (action != null) const SizedBox(height: 22),
            ?action,
          ],
        ),
      ),
    );
  }
}

/// عنوان قسم مع خيار إجراء.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
