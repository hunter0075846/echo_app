import 'package:flutter/material.dart';

/// 回响品牌色彩系统
///
/// 提供 light / dark 两套语义化颜色 token，以及品牌渐变池。
/// 所有组件应优先通过 Theme.of(context).colorScheme 获取颜色，
/// 静态常量仅用于不便获取 context 的场景（如 provider、model 层）。
class EchoColors {
  EchoColors._();

  // ==================== Light Theme ====================

  static const Color primary = Color(0xFF5B6EE1);
  static const Color primaryLight = Color(0xFF7B8FF0);
  static const Color primaryDark = Color(0xFF4A5BD0);

  static const Color accent = Color(0xFF00D4AA);
  static const Color accentLight = Color(0xFFE6FFF9);

  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color anonymous = Color(0xFF8B5CF6);
  static const Color anonymousBg = Color(0xFFEDE9FE);

  static const Color shadowLight = Color(0x145B6EE1);
  static const Color shadowMedium = Color(0x1F5B6EE1);

  // ==================== Dark Theme ====================

  static const Color darkPrimary = Color(0xFF6B7FE8);
  static const Color darkPrimaryLight = Color(0xFF8B9FFF);
  static const Color darkPrimaryDark = Color(0xFF5B6ED8);

  static const Color darkAccent = Color(0xFF00E5B8);
  static const Color darkAccentLight = Color(0x2600E5B8);

  static const Color darkBackground = Color(0xFF0A0A1A);
  static const Color darkSurface = Color(0xFF141428);
  static const Color darkCard = Color(0xFF1A1A2E);

  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  static const Color darkBorder = Color(0xFF2D2D44);
  static const Color darkDivider = Color(0xFF1E1E32);

  static const Color darkError = Color(0xFFF87171);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkInfo = Color(0xFF60A5FA);

  static const Color darkAnonymous = Color(0xFFA78BFA);
  static const Color darkAnonymousBg = Color(0xFF3B2F7A);

  static const Color darkShadow = Color(0x4D000000);

  // ==================== Brand Gradients ====================

  static const List<List<Color>> brandGradients = [
    [Color(0xFF5B6EE1), Color(0xFF7B5CFF)],
    [Color(0xFF00D4AA), Color(0xFF00B4D8)],
    [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
    [Color(0xFF8B5CF6), Color(0xFFD946EF)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
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
