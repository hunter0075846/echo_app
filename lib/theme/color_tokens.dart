import 'package:flutter/material.dart';

/// 回响品牌色彩系统
///
/// 提供 light / dark 两套语义化颜色 token，以及品牌渐变池。
/// 所有组件应优先通过 Theme.of(context).colorScheme 获取颜色，
/// 静态常量仅用于不便获取 context 的场景（如 provider、model 层）。
class EchoColors {
  EchoColors._();

  // ==================== Light Theme ====================

  static const Color primary = Color(0xFFA78BFA);
  static const Color primaryLight = Color(0xFFC4B5FD);
  static const Color primaryDark = Color(0xFF8B5CF6);

  static const Color accent = Color(0xFFF4A261);
  static const Color accentLight = Color(0xFFFCE8D8);

  static const Color background = Color(0xFFF0EBF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF2D2A32);
  static const Color textSecondary = Color(0xFF8B8494);
  static const Color textTertiary = Color(0xFFB5AEB8);

  static const Color border = Color(0xFFEDE8F0);
  static const Color divider = Color(0xFFF3EEF5);

  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color anonymous = Color(0xFF8B5CF6);
  static const Color anonymousBg = Color(0xFFEDE9FE);

  static const Color shadowLight = Color(0x14A78BFA);
  static const Color shadowMedium = Color(0x1FA78BFA);

  // ==================== Dark Theme ====================

  static const Color darkPrimary = Color(0xFFA78BFA);
  static const Color darkPrimaryLight = Color(0xFFC4B5FD);
  static const Color darkPrimaryDark = Color(0xFF8B5CF6);

  static const Color darkAccent = Color(0xFFF4A261);
  static const Color darkAccentLight = Color(0x26FCE8D8);

  static const Color darkBackground = Color(0xFF1A1428);
  static const Color darkSurface = Color(0xFF1E1830);
  static const Color darkCard = Color(0xFF282040);

  static const Color darkTextPrimary = Color(0xFFF5F0FA);
  static const Color darkTextSecondary = Color(0xFFB0A8C0);
  static const Color darkTextTertiary = Color(0xFF7A7088);

  static const Color darkBorder = Color(0xFF3D3050);
  static const Color darkDivider = Color(0xFF2E2040);

  static const Color darkError = Color(0xFFF87171);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkInfo = Color(0xFF60A5FA);

  static const Color darkAnonymous = Color(0xFFA78BFA);
  static const Color darkAnonymousBg = Color(0xFF3B2F7A);

  static const Color darkShadow = Color(0x4D000000);

  // ==================== Brand Gradients ====================

  static const List<List<Color>> brandGradients = [
    [Color(0xFFA78BFA), Color(0xFFC4B5FD)],
    [Color(0xFFF4A261), Color(0xFFE76F51)],
    [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
    [Color(0xFF8B5CF6), Color(0xFFD946EF)],
    [Color(0xFFE9C46A), Color(0xFFF4A261)],
  ];

  /// 根据用户 ID 的 hash 选取一个品牌渐变
  static List<Color> gradientForId(String id) {
    final hash = id.hashCode.abs();
    return brandGradients[hash % brandGradients.length];
  }

  /// 根据字符串（如昵称）的 hash 选取一个品牌渐变
  static List<Color> gradientForString(String? value) {
    if (value == null || value.isEmpty) {
      return brandGradients[0];
    }
    final hash = value.hashCode.abs();
    return brandGradients[hash % brandGradients.length];
  }
}
