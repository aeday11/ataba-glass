import 'package:flutter/material.dart';

/// لون ثيم كامل: لون أساسي + لون مساعد + خلفية وهالة.
class AppThemePreset {
  const AppThemePreset({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.vignette,
  });

  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color vignette;
}

/// ثيمات التطبيق الجاهزة — يختار المستخدم أحدها من صفحة الضبط.
const List<AppThemePreset> appThemePresets = [
  AppThemePreset(
    id: 'karbala',
    name: 'كربلاء',
    primary: Color(0xFFF12727),
    secondary: Color(0xFFD4AF37),
    background: Color(0xFF0A0A0A),
    vignette: Color(0xFF1A0505),
  ),
  AppThemePreset(
    id: 'gold',
    name: 'ذهب العتبة',
    primary: Color(0xFFD8A93A),
    secondary: Color(0xFFF3DE9A),
    background: Color(0xFF0B0904),
    vignette: Color(0xFF211805),
  ),
  AppThemePreset(
    id: 'emerald',
    name: 'زمرد أهل البيت',
    primary: Color(0xFF2FBF71),
    secondary: Color(0xFFD4AF37),
    background: Color(0xFF06100B),
    vignette: Color(0xFF082015),
  ),
  AppThemePreset(
    id: 'nile',
    name: 'ليل النجف',
    primary: Color(0xFF4D8DFF),
    secondary: Color(0xFFC9D7FF),
    background: Color(0xFF060A14),
    vignette: Color(0xFF0A1630),
  ),
  AppThemePreset(
    id: 'violet',
    name: 'أرجوان الحزن',
    primary: Color(0xFFB56BFF),
    secondary: Color(0xFFE9D5FF),
    background: Color(0xFF0A0712),
    vignette: Color(0xFF1A0B2A),
  ),
  AppThemePreset(
    id: 'silver',
    name: 'فضة العتبة',
    primary: Color(0xFFC9CCD6),
    secondary: Color(0xFFF4F4F8),
    background: Color(0xFF08090C),
    vignette: Color(0xFF15171F),
  ),
];

/// ألوان قالب "العتبة الزجاجية":
/// أسود عميق + هالة كربلاء + لون أساسي قابل للتغيير من صفحة الضبط.
class AppColors {
  AppColors._();

  static AppThemePreset _preset = appThemePresets.first;

  static AppThemePreset get themePreset => _preset;

  /// يطبّق ثيماً بالمعرّف، ويعود إلى «كربلاء» عند معرّف غير معروف.
  static void applyPreset(String id) {
    _preset = appThemePresets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => appThemePresets.first,
    );
  }

  static Color _darken(Color color, double amount) =>
      Color.lerp(color, Colors.black, amount) ?? color;

  static Color _lighten(Color color, double amount) =>
      Color.lerp(color, Colors.white, amount) ?? color;

  /// الخلفية الأساسية.
  static Color get background => _preset.background;

  /// هالة حول الشاشة (vignette).
  static Color get vignette => _preset.vignette;

  /// اللون الأساسي للثيم.
  static Color get red => _preset.primary;
  static Color get redDeep => _darken(_preset.primary, 0.18);
  static Color get redDark => _darken(_preset.primary, 0.48);

  /// وهج اللون الأساسي (ظلال).
  static Color get redGlow => _preset.primary.withValues(alpha: 0.20);

  /// اللون المساعد للثيم.
  static Color get gold => _preset.secondary;
  static Color get goldLight => _lighten(_preset.secondary, 0.28);
  static Color get goldDeep => _darken(_preset.secondary, 0.42);

  /// أخضر أهل البيت (ع) — لون السرور والمواليد والأفراح.
  static const Color green = Color(0xFF3BC46A);
  static const Color greenDeep = Color(0xFF1F9A4D);
  static const Color greenDark = Color(0xFF0F5A2B);

  /// وهج أخضر (ظلال المواليد).
  static const Color greenGlow = Color(0x331F9A4D);

  /// أسطح زجاجية شفافة.
  static const Color glassFill = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color glassFillStrong = Color(0x14FFFFFF); // 0.08
  static const Color glassBorder = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const Color glassBorderStrong = Color(0x2EFFFFFF); // 0.18
  static Color get glassShadow => _preset.primary.withValues(alpha: 0.15);

  /// النصوص.
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF); // rgba(255,255,255,0.6)
  static const Color divider = Color(0x14FFFFFF);

  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF5FD08A);

  /// تدرّج مساعد زخرفي.
  static LinearGradient get goldGradient => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [goldLight, gold, goldDeep],
      );

  /// تدرّج اللون الأساسي للأزرار والتوهجات.
  static LinearGradient get redGradient => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [red, redDeep, redDark],
      );

  /// تدرّج أخضر أهل البيت للاحتفال والمواليد.
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [green, greenDeep, greenDark],
  );
}

/// أنماط الخطوط: أميري للزينة الذهبية، وجَدول (Cairo) للنصوص.
class AppFonts {
  AppFonts._();

  static const String decorative = 'Amiri';
  static const String body = 'Cairo';
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.redDeep,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: const Color(0xFF231A02),
      surface: Colors.transparent,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: const Color(0xFF2A0B0B),
      outline: AppColors.glassBorder,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFonts.body,
    );

    TextStyle decorativeStyle(
      double size, {
      FontWeight weight = FontWeight.w700,
      Color color = AppColors.textPrimary,
      double height = 1.4,
    }) {
      return TextStyle(
        fontFamily: AppFonts.decorative,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
    }

    TextStyle bodyStyle(
      double size, {
      FontWeight weight = FontWeight.w400,
      Color color = AppColors.textPrimary,
      double height = 1.6,
    }) {
      return TextStyle(
        fontFamily: AppFonts.body,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
    }

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: decorativeStyle(34),
        displayMedium: decorativeStyle(30),
        displaySmall: decorativeStyle(26),
        headlineLarge: bodyStyle(23, weight: FontWeight.w700),
        headlineMedium: bodyStyle(21, weight: FontWeight.w700),
        headlineSmall: bodyStyle(19, weight: FontWeight.w700),
        titleLarge: decorativeStyle(19),
        titleMedium: bodyStyle(16.5, weight: FontWeight.w700),
        titleSmall: bodyStyle(15, weight: FontWeight.w600),
        bodyLarge: bodyStyle(16),
        bodyMedium: bodyStyle(14),
        bodySmall: bodyStyle(12, color: AppColors.textSecondary, height: 1.5),
        labelLarge: bodyStyle(15, weight: FontWeight.w700),
        labelMedium: bodyStyle(13,
            weight: FontWeight.w600, color: AppColors.textSecondary),
        labelSmall: bodyStyle(11, color: AppColors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: decorativeStyle(24, color: AppColors.goldLight),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassFill,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFillStrong,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.gold, width: 1.2),
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
        thumbColor: AppColors.goldLight,
        overlayColor: AppColors.red.withValues(alpha: 0.20),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.goldLight
                : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.red.withValues(alpha: 0.4)
                : AppColors.glassFillStrong),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xE6111114),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.gold,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xF21B0A0A),
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: AppFonts.body,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.redDeep,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: BorderSide(color: AppColors.gold, width: 1.2),
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xF2141418),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: AppFonts.body,
          fontSize: 14,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.goldLight,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.red,
        dividerColor: AppColors.divider,
        labelStyle: const TextStyle(
          fontFamily: AppFonts.body,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(fontFamily: AppFonts.body),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF2111114),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: decorativeStyle(20),
        contentTextStyle: bodyStyle(15, color: AppColors.textSecondary),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
