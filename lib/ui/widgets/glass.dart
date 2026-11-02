import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// عنصر زجاجي عائم (Glassmorphism) بروح العتبة الزجاجية.
///
/// خلفية بيضاء شفافة 6% + حدّ رفيع 10% + ضوء أحمر كربلاوي تحت البطاقة.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.blur = false,
    this.glow = false,
    this.color,
    this.alignment,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// تمويه حقيقي لما خلف البطاقة (يُستخدم في الشاشات الرئيسية فقط).
  final bool blur;

  /// وهج أحمر حول البطاقة (للعناصر الرئيسية).
  final bool glow;

  /// لون تعبئة مخصّص (يحل محل الشفاف الافتراضي).
  final Color? color;

  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    // نقرأ الثيم كي تُعاد البطاقة عند تغيير ألوان الثيم من صفحة الضبط.
    Theme.of(context);
    Widget card = Container(
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.glassFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          if (glow) ...[
            BoxShadow(
              color: AppColors.redGlow,
              blurRadius: 42,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (blur) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: card,
        ),
      );
    }
    return card;
  }
}

/// كبسولة زجاجية صغيرة (للاستخدامات في الصفوف والبطاقات).
class GlassCapsule extends StatelessWidget {
  const GlassCapsule({
    super.key,
    required this.child,
    this.padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    this.radius = 999,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.glassFillStrong,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: child,
    );
  }
}

/// ختم دائري زجاجي للرادد — صورته داخل حلقة بضوء أحمر خفيف
/// كأنها شمعة أمام الصحن. عند غياب الصورة تظهر شارة التطبيق (بدون حرف).
class GlassSeal extends StatelessWidget {
  const GlassSeal({
    super.key,
    required this.label,
    this.size = 64,
    this.image,
    this.tint,
  });

  final String label;
  final double size;
  final String? image;

  /// لون الهالة المحيطة. افتراضياً أحمر كربلائي (للرثاء)؛
  /// يُمرَّر أخضر للمناسبات الفرح كالمواليد.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final base = tint ?? AppColors.red;
    final deep = _deepOf(base);
    final glow = _glowOf(base);

    final ring = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            base.withValues(alpha: 0.18),
            deep.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: AppColors.glassBorderStrong),
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: size * 0.35,
            spreadRadius: size * 0.04,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ClipOval(child: _content()),
    );
    return ring;
  }

  /// يعيد درجة أغمق من اللون الممرَّر (لطبقة التدرّج الداخلية).
  static Color _deepOf(Color c) => Color.from(
        alpha: c.a,
        red: c.r * 0.78,
        green: c.g * 0.78,
        blue: c.b * 0.78,
      );

  /// يعيد وهجاً شبه شفاف من اللون الممرَّر (للظلال).
  static Color _glowOf(Color c) => c.withValues(alpha: 0.20);

  Widget _content() {
    final img = image;
    if (img != null && img.isNotEmpty) {
      return img.startsWith('assets/')
          ? Image.asset(
              img,
              width: size * 0.94,
              height: size * 0.94,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _badge(),
            )
          : Image.network(
              img,
              width: size * 0.82,
              height: size * 0.82,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _badge(),
            );
    }
    return _badge();
  }

  /// البديل: شارة التطبيق — صورة دائماً وبدون حروف.
  Widget _badge() => Image.asset(
        'assets/icon/app_icon.png',
        width: size * 0.94,
        height: size * 0.94,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.decorative,
            fontSize: size * 0.40,
            fontWeight: FontWeight.w700,
            color: AppColors.goldLight,
          ),
        ),
      );
}

/// خلفية العتبة: أسود صلب مع هالة حمراء خفيفة من المنتصف (vignette).
class AtabaBackground extends StatelessWidget {
  const AtabaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.25),
          radius: 1.15,
          colors: [AppColors.vignette, AppColors.background],
          stops: const [0.0, 0.65],
        ),
      ),
      child: child,
    );
  }
}

/// شريط تنقل زجاجي عائم (3 عناصر) مع تمويه 40.
class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final List<({IconData icon, String label})> items;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.glassFillStrong,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.glassBorderStrong),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BarItem(
                    icon: items[i].icon,
                    label: items[i].label,
                    selected: i == index,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.red.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.red.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  selected ? AppColors.goldLight : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            // flexible + FittedBox: على الشاشات الضيقة (أو الخطوط العريضة)
            // يُصغَّر النص بدل أن يتجاوز حدود التبويب ويظهر شريط تحذيري.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// أيقونة داخل خلفية دائرية شفافة (نمط الأيقونات في القالب).
class GlassIcon extends StatelessWidget {
  const GlassIcon({
    super.key,
    required this.icon,
    this.size = 20,
    this.color = AppColors.textPrimary,
    this.background = true,
  });

  final IconData icon;
  final double size;
  final Color color;
  final bool background;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: size, color: color);
    if (!background) return iconWidget;
    return Container(
      width: size * 2.1,
      height: size * 2.1,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Icon(icon, size: size, color: color),
    );
  }
}

/// توهّج ذهبي للنصوص الرسمية (مثل "السلام عليك يا أبا عبد الله").
class GoldGlowText extends StatelessWidget {
  const GoldGlowText(
    this.text, {
    super.key,
    this.fontSize = 24,
    this.maxLines = 1,
  });

  final String text;
  final double fontSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.decorative,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.goldLight,
        shadows: [
          Shadow(
            color: AppColors.gold.withValues(alpha: 0.55),
            blurRadius: 18,
          ),
          Shadow(
            color: AppColors.redGlow,
            blurRadius: 30,
          ),
        ],
      ),
    );
  }
}
