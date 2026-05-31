import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/design_tokens.dart';
import '../utils/animation_utils.dart';

/// 统一按钮组件
///
/// 提供 primary / secondary / ghost / destructive 四种变体。
/// 所有变体均带按压 scale 动效和触觉反馈。
class EchoButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final EchoButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets? padding;

  const EchoButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  }) : variant = EchoButtonVariant.primary;

  const EchoButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  }) : variant = EchoButtonVariant.secondary;

  const EchoButton.outline({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  }) : variant = EchoButtonVariant.outline;

  const EchoButton.ghost({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  }) : variant = EchoButtonVariant.ghost;

  const EchoButton.destructive({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  }) : variant = EchoButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget button;
    switch (variant) {
      case EchoButtonVariant.primary:
        button = ElevatedButton.icon(
          onPressed: _handlePress,
          icon: _buildIcon(colorScheme.onPrimary),
          label: _buildLabel(colorScheme.onPrimary),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            padding: padding ??
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EchoRadius.lg),
            ),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case EchoButtonVariant.secondary:
        button = ElevatedButton.icon(
          onPressed: _handlePress,
          icon: _buildIcon(colorScheme.onSurface),
          label: _buildLabel(colorScheme.onSurface),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            padding: padding ??
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EchoRadius.lg),
            ),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case EchoButtonVariant.outline:
        button = OutlinedButton.icon(
          onPressed: _handlePress,
          icon: _buildIcon(colorScheme.primary),
          label: _buildLabel(colorScheme.primary),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
            padding: padding ??
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EchoRadius.lg),
            ),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case EchoButtonVariant.ghost:
        button = TextButton.icon(
          onPressed: _handlePress,
          icon: _buildIcon(colorScheme.primary),
          label: _buildLabel(colorScheme.primary),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: padding ??
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case EchoButtonVariant.destructive:
        button = ElevatedButton.icon(
          onPressed: _handlePress,
          icon: _buildIcon(Colors.white),
          label: _buildLabel(Colors.white),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: padding ??
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EchoRadius.lg),
            ),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }

    button = button.animate(target: onPressed == null ? 0 : 1).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.97, 0.97),
          duration: EchoDurations.fast,
          curve: EchoCurves.easeInOut,
        );

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildIcon(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 18.w,
        height: 18.w,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }
    if (icon != null) {
      return Icon(icon, size: 18.w);
    }
    return const SizedBox.shrink();
  }

  Widget _buildLabel(Color color) {
    return Text(
      isLoading ? '加载中...' : label,
      style: TextStyle(color: color),
    );
  }

  VoidCallback? get _handlePress {
    if (isLoading || onPressed == null) return null;
    return () {
      EchoHaptics.light();
      onPressed!();
    };
  }
}

enum EchoButtonVariant { primary, secondary, outline, ghost, destructive }
