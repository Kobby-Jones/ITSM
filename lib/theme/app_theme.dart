import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightSurface,
      surfaceContainerHighest: AppColors.lightSurfaceAlt,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.danger,
      outline: AppColors.lightBorder,
    );

    return _build(base, AppColors.lightBg, AppColors.lightTextPrimary,
        AppColors.lightTextSecondary, AppColors.lightBorder, AppColors.lightSurface);
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      surfaceContainerHighest: AppColors.darkSurfaceAlt,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.danger,
      outline: AppColors.darkBorder,
    );

    return _build(base, AppColors.darkBg, AppColors.darkTextPrimary,
        AppColors.darkTextSecondary, AppColors.darkBorder, AppColors.darkSurface);
  }

  static ThemeData _build(
    ColorScheme scheme,
    Color bg,
    Color textPrimary,
    Color textSecondary,
    Color border,
    Color surface,
  ) {
    final txt = GoogleFonts.interTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: txt.copyWith(
        displayLarge: txt.displayLarge?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: txt.displayMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineLarge: txt.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        headlineMedium:
            txt.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineSmall: txt.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        titleLarge: txt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: txt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: txt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: txt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: txt.bodyMedium?.copyWith(color: textPrimary),
        bodySmall: txt.bodySmall?.copyWith(color: textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: txt.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontSize: 18,
        ),
        systemOverlayStyle: scheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withOpacity(0.4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: textSecondary),
        labelStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: txt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: border),
          textStyle: txt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: txt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: txt.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withOpacity(0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return txt.labelSmall?.copyWith(
                color: scheme.primary, fontWeight: FontWeight.w600);
          }
          return txt.labelSmall?.copyWith(color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary, size: 22);
          }
          return IconThemeData(color: textSecondary, size: 22);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 24),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 22),
        selectedLabelTextStyle: txt.labelMedium?.copyWith(
            color: scheme.primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: txt.labelMedium?.copyWith(color: textSecondary),
        useIndicator: true,
        indicatorColor: scheme.primary.withOpacity(0.12),
        indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: textSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: txt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
      ),
    );
  }
}
