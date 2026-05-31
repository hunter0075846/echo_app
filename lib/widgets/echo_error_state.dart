import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'echo_button.dart';

/// 统一错误态组件
///
/// 用于加载失败、网络错误、SSE 断开等场景。
/// 进入时带有抖动 + 淡入动画。
class EchoErrorState extends StatelessWidget {
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;
  final double iconSize;

  const EchoErrorState({
    super.key,
    required this.message,
    this.retryLabel,
    this.onRetry,
    this.icon = Icons.cloud_off_outlined,
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
              color: colorScheme.error.withValues(alpha: 0.4),
            )
                .animate()
                .shake(duration: EchoDurations.normal, hz: 3)
                .fadeIn(duration: EchoDurations.normal),
            SizedBox(height: EchoSpacing.md),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.echoTextSecondary,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: const Duration(milliseconds: 100))
                .fadeIn(duration: EchoDurations.normal),
            if (onRetry != null) ...[
              SizedBox(height: EchoSpacing.lg),
              EchoButton.outline(
                label: retryLabel ?? '重试',
                icon: Icons.refresh,
                onPressed: onRetry,
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

/// 内联错误横幅（用于聊天界面等需要非侵入式错误提示的场景）
class EchoErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const EchoErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: EchoSpacing.md,
        vertical: EchoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18.w,
            color: colorScheme.error,
          ),
          SizedBox(width: EchoSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                padding: EdgeInsets.symmetric(horizontal: EchoSpacing.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '重试',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: EchoDurations.fast)
        .slideY(
          begin: -0.5,
          end: 0,
          duration: EchoDurations.normal,
          curve: EchoCurves.easeOut,
        );
  }
}
