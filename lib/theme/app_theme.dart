import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'color_tokens.dart';

class AppTheme {
  // ==================== 向后兼容的静态常量 (Light) ====================

  static const Color primaryColor = EchoColors.primary;
  static const Color primaryLightColor = EchoColors.primaryLight;
  static const Color primaryDarkColor = EchoColors.primaryDark;

  static const Color backgroundColor = EchoColors.background;
  static const Color surfaceColor = EchoColors.surface;
  static const Color cardColor = EchoColors.card;

  static const Color textPrimaryColor = EchoColors.textPrimary;
  static const Color textSecondaryColor = EchoColors.textSecondary;
  static const Color textTertiaryColor = EchoColors.textTertiary;

  static const Color successColor = EchoColors.success;
  static const Color warningColor = EchoColors.warning;
  static const Color errorColor = EchoColors.error;
  static const Color infoColor = EchoColors.info;

  static const Color borderColor = EchoColors.border;
  static const Color dividerColor = EchoColors.divider;

  static const Color anonymousColor = EchoColors.anonymous;
  static const Color anonymousBgColor = EchoColors.anonymousBg;

  static const Color accentColor = EchoColors.accent;
  static const Color accentLightColor = EchoColors.accentLight;

  // ==================== 通用渐变 ====================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [EchoColors.primary, EchoColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [EchoColors.accent, EchoColors.info],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== Light Theme ====================

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        primary: EchoColors.primary,
        primaryLight: EchoColors.primaryLight,
        primaryDark: EchoColors.primaryDark,
        accent: EchoColors.accent,
        accentLight: EchoColors.accentLight,
        background: EchoColors.background,
        surface: EchoColors.surface,
        card: EchoColors.card,
        textPrimary: EchoColors.textPrimary,
        textSecondary: EchoColors.textSecondary,
        textTertiary: EchoColors.textTertiary,
        border: EchoColors.border,
        divider: EchoColors.divider,
        error: EchoColors.error,
        success: EchoColors.success,
        warning: EchoColors.warning,
        info: EchoColors.info,
        anonymous: EchoColors.anonymous,
        anonymousBg: EchoColors.anonymousBg,
        shadow: EchoColors.shadowLight,
      );

  // ==================== Dark Theme ====================

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        primary: EchoColors.darkPrimary,
        primaryLight: EchoColors.darkPrimaryLight,
        primaryDark: EchoColors.darkPrimaryDark,
        accent: EchoColors.darkAccent,
        accentLight: EchoColors.darkAccentLight,
        background: EchoColors.darkBackground,
        surface: EchoColors.darkSurface,
        card: EchoColors.darkCard,
        textPrimary: EchoColors.darkTextPrimary,
        textSecondary: EchoColors.darkTextSecondary,
        textTertiary: EchoColors.darkTextTertiary,
        border: EchoColors.darkBorder,
        divider: EchoColors.darkDivider,
        error: EchoColors.darkError,
        success: EchoColors.darkSuccess,
        warning: EchoColors.darkWarning,
        info: EchoColors.darkInfo,
        anonymous: EchoColors.darkAnonymous,
        anonymousBg: EchoColors.darkAnonymousBg,
        shadow: EchoColors.darkShadow,
      );

  // ==================== Theme Builder ====================

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color primaryLight,
    required Color primaryDark,
    required Color accent,
    required Color accentLight,
    required Color background,
    required Color surface,
    required Color card,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color border,
    required Color divider,
    required Color error,
    required Color success,
    required Color warning,
    required Color info,
    required Color anonymous,
    required Color anonymousBg,
    required Color shadow,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: divider,
      canvasColor: surface,
      shadowColor: shadow,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: textPrimary,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
        surfaceContainerHighest: card,
        outline: border,
      ),

      // ----- AppBar -----
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: surface,
        foregroundColor: textPrimary,
        surfaceTintColor: isDark ? Colors.transparent : primary.withValues(alpha: 0.05),
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // ----- Typography -----
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: textPrimary),
        displaySmall: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textPrimary),
        headlineLarge: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: textPrimary),
        titleMedium: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: textPrimary),
        titleSmall: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: textSecondary),
        bodyLarge: TextStyle(fontSize: 16.sp, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14.sp, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12.sp, color: textSecondary),
        labelLarge: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: textSecondary),
        labelMedium: TextStyle(fontSize: 12.sp, color: textTertiary),
        labelSmall: TextStyle(fontSize: 10.sp, color: textTertiary),
      ),

      // ----- ElevatedButton -----
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
      ),

      // ----- OutlinedButton -----
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
      ),

      // ----- TextButton -----
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ),

      // ----- InputDecoration -----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surface : card,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: error),
        ),
        hintStyle: TextStyle(fontSize: 14.sp, color: textTertiary),
      ),

      // ----- BottomNavigationBar -----
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.92),
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        selectedLabelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 11.sp),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ----- Divider -----
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // ----- Card -----
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        margin: EdgeInsets.zero,
      ),

      // ----- Chip -----
      chipTheme: ChipThemeData(
        backgroundColor: primary.withValues(alpha: 0.08),
        selectedColor: primary,
        labelStyle: TextStyle(fontSize: 12.sp, color: textSecondary),
        secondaryLabelStyle: TextStyle(fontSize: 12.sp, color: Colors.white),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
      ),

      // ----- SnackBar -----
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surface : textPrimary,
        contentTextStyle: TextStyle(fontSize: 14.sp, color: isDark ? textPrimary : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        behavior: SnackBarBehavior.floating,
      ),

      // ----- Dialog -----
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        titleTextStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: textPrimary),
        contentTextStyle: TextStyle(fontSize: 14.sp, color: textSecondary),
      ),

      // ----- BottomSheet -----
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
      ),

      // ----- Icon -----
      iconTheme: IconThemeData(color: textSecondary, size: 24),

      // ----- ProgressIndicator -----
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: divider,
        circularTrackColor: divider,
      ),
    );
  }
}

/// 语义化文字颜色扩展，自动适配当前亮/暗主题
extension EchoTextColors on ThemeData {
  Color get echoTextPrimary => colorScheme.onSurface;
  Color get echoTextSecondary => brightness == Brightness.dark
      ? EchoColors.darkTextSecondary
      : EchoColors.textSecondary;
  Color get echoTextTertiary => brightness == Brightness.dark
      ? EchoColors.darkTextTertiary
      : EchoColors.textTertiary;
}
