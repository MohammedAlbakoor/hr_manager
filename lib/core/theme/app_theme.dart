import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette._();

  static const Color primary = Color(0xFF2446D8);
  static const Color primaryDark = Color(0xFF172554);
  static const Color secondary = Color(0xFF0F766E);
  static const Color accent = Color(0xFFF59E0B);
  static const Color background = Color(0xFFF4F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEFF6FF);
  static const Color text = Color(0xFF111827);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFDDE6F3);
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);
  static const Color danger = Color(0xFFDC2626);
  static const Color shadow = Color(0x1A0F172A);
}

class AppTheme {
  const AppTheme._();

  static const List<String> _arabicFallbackFonts = [
    'Tajawal',
    'Cairo',
    'Noto Sans Arabic',
    'Segoe UI',
    'Arial',
  ];

  static TextStyle _textStyle({
    required Color color,
    required double size,
    required FontWeight weight,
    double height = 1.45,
  }) {
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
      fontFamilyFallback: _arabicFallbackFonts,
    );
  }

  static ThemeData light() {
    const primary = AppPalette.primary;
    const secondary = AppPalette.secondary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      tertiary: AppPalette.accent,
      surface: AppPalette.surface,
      error: AppPalette.danger,
    );

    final textTheme = TextTheme(
      displaySmall: _textStyle(
        color: AppPalette.text,
        size: 34,
        weight: FontWeight.w800,
        height: 1.22,
      ),
      headlineLarge: _textStyle(
        color: AppPalette.text,
        size: 30,
        weight: FontWeight.w800,
        height: 1.25,
      ),
      headlineMedium: _textStyle(
        color: AppPalette.text,
        size: 24,
        weight: FontWeight.w800,
        height: 1.3,
      ),
      headlineSmall: _textStyle(
        color: AppPalette.text,
        size: 21,
        weight: FontWeight.w800,
        height: 1.3,
      ),
      titleLarge: _textStyle(
        color: AppPalette.text,
        size: 19,
        weight: FontWeight.w800,
        height: 1.35,
      ),
      titleMedium: _textStyle(
        color: AppPalette.text,
        size: 16,
        weight: FontWeight.w700,
        height: 1.4,
      ),
      titleSmall: _textStyle(
        color: AppPalette.text,
        size: 14,
        weight: FontWeight.w700,
        height: 1.4,
      ),
      bodyLarge: _textStyle(
        color: AppPalette.text,
        size: 16,
        weight: FontWeight.w500,
      ),
      bodyMedium: _textStyle(
        color: AppPalette.textMuted,
        size: 14,
        weight: FontWeight.w500,
      ),
      bodySmall: _textStyle(
        color: AppPalette.textMuted,
        size: 12,
        weight: FontWeight.w600,
      ),
      labelLarge: _textStyle(
        color: AppPalette.text,
        size: 14,
        weight: FontWeight.w800,
        height: 1.25,
      ),
      labelMedium: _textStyle(
        color: AppPalette.textMuted,
        size: 12,
        weight: FontWeight.w700,
        height: 1.25,
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppPalette.background,
      fontFamilyFallback: _arabicFallbackFonts,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppPalette.text,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppPalette.text, size: 24),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppPalette.textMuted,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: primary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF94A3B8),
        ),
        prefixIconColor: AppPalette.textMuted,
        suffixIconColor: AppPalette.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppPalette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppPalette.danger, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppPalette.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppPalette.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(44, 46),
          side: const BorderSide(color: AppPalette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: primary),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 10,
        focusElevation: 10,
        hoverElevation: 10,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : AppPalette.textMuted,
            size: selected ? 25 : 23,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? primary : AppPalette.textMuted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.primaryDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppPalette.surface,
        showDragHandle: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: primary.withValues(alpha: 0.12),
        disabledColor: const Color(0xFFE2E8F0),
        side: const BorderSide(color: AppPalette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.border,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      extensions: const <ThemeExtension<dynamic>>[AppSpacing()],
    );
  }
}

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.xs = 6,
    this.sm = 10,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) {
      return this;
    }

    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
