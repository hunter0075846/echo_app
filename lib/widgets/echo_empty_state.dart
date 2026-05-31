import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'echo_button.dart';

/// 统一空态组件
///
/// 用于列表为空、搜索结果为空、无数据等场景。
/// 进入时带有淡入 + 缩放动画。
class EchoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  const EchoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(EchoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize.w,
              color: colorScheme.primary.withValues(alpha: 0.3),
            )
                .animate()
                .fadeIn(duration: EchoDurations.slow)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: EchoDurations.slow,
                  curve: EchoCurves.spring,
                ),
            SizedBox(height: EchoSpacing.md),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: const Duration(milliseconds: 100))
                .fadeIn(duration: EchoDurations.normal),
            if (subtitle != null) ...[
              SizedBox(height: EchoSpacing.sm),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.echoTextSecondary,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(delay: const Duration(milliseconds: 150))
                  .fadeIn(duration: EchoDurations.normal),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: EchoSpacing.lg),
              EchoButton.primary(
                label: actionLabel!,
                onPressed: onAction,
              )
                  .animate(delay: const Duration(milliseconds: 200))
                  .fadeIn(duration: EchoDurations.normal)
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    duration: EchoDurations.normal,
                    curve: EchoCurves.easeOut,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
