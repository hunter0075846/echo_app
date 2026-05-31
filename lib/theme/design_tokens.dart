import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 回响设计令牌系统
///
/// 集中定义所有设计常量：颜色、间距、圆角、阴影、动效时长、渐变。
/// 所有屏幕和组件应优先引用此文件中的令牌，禁止硬编码。
class EchoTokens {
  EchoTokens._();

  // ==================== 颜色令牌 ====================

  static const Color primary = Color(0xFFA78BFA);
  static const Color primaryLight = Color(0xFFC4B5FD);
  static const Color primaryDark = Color(0xFF8B5CF6);

  static const Color accent = Color(0xFFF4A261);
  static const Color accentLight = Color(0xFFFCE8D8);

  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color anonymous = Color(0xFF8B5CF6);
  static const Color anonymousBg = Color(0xFFEDE9FE);

  static const List<List<Color>> brandGradients = [
    [Color(0xFFA78BFA), Color(0xFFC4B5FD)],
    [Color(0xFFF4A261), Color(0xFFE76F51)],
    [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
    [Color(0xFF8B5CF6), Color(0xFFD946EF)],
    [Color(0xFFE9C46A), Color(0xFFF4A261)],
  ];

  static List<Color> gradientForId(String id) {
    final hash = id.hashCode.abs();
    return brandGradients[hash % brandGradients.length];
  }

  static List<Color> gradientForString(String? value) {
    if (value == null || value.isEmpty) {
      return brandGradients[0];
    }
    final hash = value.hashCode.abs();
    return brandGradients[hash % brandGradients.length];
  }
}

/// Light Mode 语义化颜色
class EchoLightColors {
  EchoLightColors._();

  static const Color background = Color(0xFFF0EBF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F5FA);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF2D2A32);
  static const Color textSecondary = Color(0xFF8B8494);
  static const Color textTertiary = Color(0xFFB5AEB8);

  static const Color border = Color(0xFFEDE8F0);
  static const Color divider = Color(0xFFF3EEF5);

  static const Color shadowLight = Color(0x14A78BFA);
  static const Color shadowMedium = Color(0x1FA78BFA);
}

/// Dark Mode 语义化颜色（暖紫调深海风格）
class EchoDarkColors {
  EchoDarkColors._();

  static const Color background = Color(0xFF1A1428);
  static const Color surface = Color(0xFF1E1830);
  static const Color surfaceVariant = Color(0xFF2A2040);
  static const Color card = Color(0xFF282040);

  static const Color textPrimary = Color(0xFFF5F0FA);
  static const Color textSecondary = Color(0xFFB0A8C0);
  static const Color textTertiary = Color(0xFF7A7088);

  static const Color border = Color(0xFF3D3050);
  static const Color divider = Color(0xFF2E2040);

  static const Color shadow = Color(0x4D000000);
}

// ==================== 间距令牌 ====================

class EchoSpacing {
  EchoSpacing._();

  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;
}

// ==================== 圆角令牌 ====================

class EchoRadius {
  EchoRadius._();

  static double get sm => 8.r;
  static double get md => 12.r;
  static double get lg => 16.r;
  static double get xl => 20.r;
  static double get xxl => 24.r;
  static double get xxxl => 28.r;
  static double get card => 24.r;
  static double get full => 9999.r;
}

// ==================== 阴影令牌 ====================

class EchoShadows {
  EchoShadows._();

  static BoxShadow get sm => BoxShadow(
        color: const Color(0x14A78BFA),
        blurRadius: 4,
        offset: const Offset(0, 2),
      );

  static BoxShadow get md => BoxShadow(
        color: const Color(0x1FA78BFA),
        blurRadius: 12,
        offset: const Offset(0, 4),
      );

  static BoxShadow get lg => BoxShadow(
        color: const Color(0x29000000),
        blurRadius: 24,
        offset: const Offset(0, 8),
      );

  /// 卡片漂浮阴影
  static BoxShadow get cardFloat => BoxShadow(
        color: const Color(0x14A78BFA),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      );

  /// AI 元素发光效果
  static BoxShadow get glow => BoxShadow(
        color: EchoTokens.primary.withValues(alpha: 0.3),
        blurRadius: 16,
        spreadRadius: 2,
        offset: Offset.zero,
      );

  /// 品牌色微弱发光
  static BoxShadow get brandGlow => BoxShadow(
        color: EchoTokens.accent.withValues(alpha: 0.15),
        blurRadius: 20,
        spreadRadius: 4,
        offset: Offset.zero,
      );
}

// ==================== 渐变令牌 ====================

class EchoGradients {
  EchoGradients._();

  /// 全局背景渐变（淡紫 → 暖米白）
  static const LinearGradient background = LinearGradient(
    colors: [Color(0xFFF0EBF5), Color(0xFFFAF5EF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 暗色模式背景渐变（深紫 → 深褐）
  static const LinearGradient darkBackground = LinearGradient(
    colors: [Color(0xFF1A1428), Color(0xFF251E35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 卡片顶部装饰渐变
  static const LinearGradient cardTop = LinearGradient(
    colors: [Color(0xFFF8F5FA), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 主色渐变
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 强调色渐变
  static const LinearGradient accent = LinearGradient(
    colors: [Color(0xFFF4A261), Color(0xFFE76F51)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ==================== 动效时长令牌 ====================

class EchoDurations {
  EchoDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);
}

// ==================== 动效曲线令牌 ====================

class EchoCurves {
  EchoCurves._();

  static const Curve spring = Curves.elasticOut;
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.decelerate;
}
