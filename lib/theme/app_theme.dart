import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_tokens.dart';
import 'design_tokens.dart';

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
    colors: [EchoColors.accent, Color(0xFFE76F51)],
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
        background: EchoLightColors.background,
        surface: EchoLightColors.surface,
        surfaceVariant: EchoLightColors.surfaceVariant,
        card: EchoLightColors.card,
        textPrimary: EchoLightColors.textPrimary,
        textSecondary: EchoLightColors.textSecondary,
        textTertiary: EchoLightColors.textTertiary,
        border: EchoLightColors.border,
        divider: EchoLightColors.divider,
        error: EchoColors.error,
        success: EchoColors.success,
        warning: EchoColors.warning,
        info: EchoColors.info,
        anonymous: EchoColors.anonymous,
        anonymousBg: EchoColors.anonymousBg,
        shadow: EchoLightColors.shadowMedium,
      );

  // ==================== Dark Theme ====================

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        primary: EchoColors.darkPrimary,
        primaryLight: EchoColors.darkPrimaryLight,
        primaryDark: EchoColors.darkPrimaryDark,
        accent: EchoColors.darkAccent,
        accentLight: EchoColors.darkAccentLight,
        background: EchoDarkColors.background,
        surface: EchoDarkColors.surface,
        surfaceVariant: EchoDarkColors.surfaceVariant,
        card: EchoDarkColors.card,
        textPrimary: EchoDarkColors.textPrimary,
        textSecondary: EchoDarkColors.textSecondary,
        textTertiary: EchoDarkColors.textTertiary,
        border: EchoDarkColors.border,
        divider: EchoDarkColors.divider,
        error: EchoColors.darkError,
        success: EchoColors.darkSuccess,
        warning: EchoColors.darkWarning,
        info: EchoColors.darkInfo,
        anonymous: EchoColors.darkAnonymous,
        anonymousBg: EchoColors.darkAnonymousBg,
        shadow: EchoDarkColors.shadow,
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
    required Color surfaceVariant,
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
    final playfair = GoogleFonts.playfairDisplay;
    final jakarta = GoogleFonts.plusJakartaSans;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: Colors.transparent,
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
        surfaceContainer: surfaceVariant,
        outline: border,
      ),

      // ----- AppBar -----
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: playfair(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // ----- Typography -----
      textTheme: TextTheme(
        displayLarge: playfair(fontSize: 32.sp, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: playfair(fontSize: 28.sp, fontWeight: FontWeight.bold, color: textPrimary),
        displaySmall: playfair(fontSize: 24.sp, fontWeight: FontWeight.bold, color: textPrimary),
        headlineLarge: playfair(fontSize: 22.sp, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: playfair(fontSize: 18.sp, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: playfair(fontSize: 16.sp, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: jakarta(fontSize: 16.sp, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: jakarta(fontSize: 14.sp, fontWeight: FontWeight.w500, color: textPrimary),
        titleSmall: jakarta(fontSize: 12.sp, fontWeight: FontWeight.w500, color: textSecondary),
        bodyLarge: jakarta(fontSize: 16.sp, color: textPrimary),
        bodyMedium: jakarta(fontSize: 14.sp, color: textPrimary),
        bodySmall: jakarta(fontSize: 12.sp, color: textSecondary),
        labelLarge: jakarta(fontSize: 14.sp, fontWeight: FontWeight.w500, color: textSecondary),
        labelMedium: jakarta(fontSize: 12.sp, color: textTertiary),
        labelSmall: jakarta(fontSize: 10.sp, color: textTertiary),
      ),

      // ----- ElevatedButton -----
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EchoRadius.lg)),
          textStyle: jakarta(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      // ----- OutlinedButton -----
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EchoRadius.lg)),
          textStyle: jakarta(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      // ----- TextButton -----
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          textStyle: jakarta(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ),

      // ----- InputDecoration -----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: EchoSpacing.md, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadius.lg),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadius.lg),
          borderSide: BorderSide(color: error),
        ),
        hintStyle: jakarta(fontSize: 14.sp, color: textTertiary),
      ),

      // ----- BottomNavigationBar -----
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        selectedLabelStyle: jakarta(fontSize: 11.sp, fontWeight: FontWeight.w500),
        unselectedLabelStyle: jakarta(fontSize: 11.sp),
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
          borderRadius: BorderRadius.circular(EchoRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),

      // ----- Chip -----
      chipTheme: ChipThemeData(
        backgroundColor: primary.withValues(alpha: 0.08),
        selectedColor: primary,
        labelStyle: jakarta(fontSize: 12.sp, color: textSecondary),
        secondaryLabelStyle: jakarta(fontSize: 12.sp, color: Colors.white),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
      ),

      // ----- SnackBar -----
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surface : textPrimary,
        contentTextStyle: jakarta(fontSize: 14.sp, color: isDark ? textPrimary : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EchoRadius.md)),
        behavior: SnackBarBehavior.floating,
      ),

      // ----- Dialog -----
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EchoRadius.xl)),
        titleTextStyle: playfair(fontSize: 18.sp, fontWeight: FontWeight.w600, color: textPrimary),
        contentTextStyle: jakarta(fontSize: 14.sp, color: textSecondary),
      ),

      // ----- BottomSheet -----
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(EchoRadius.xxl),
            topRight: Radius.circular(EchoRadius.xxl),
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

      // ----- Page Transitions -----
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// 语义化文字颜色扩展，自动适配当前亮/暗主题
extension EchoTextColors on ThemeData {
  Color get echoTextPrimary => colorScheme.onSurface;
  Color get echoTextSecondary => brightness == Brightness.dark
      ? EchoDarkColors.textSecondary
      : EchoLightColors.textSecondary;
  Color get echoTextTertiary => brightness == Brightness.dark
      ? EchoDarkColors.textTertiary
      : EchoLightColors.textTertiary;
}
