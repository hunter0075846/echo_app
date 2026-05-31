import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// 统一底部弹层组件
///
/// 自动处理 keyboard-aware、SafeArea、圆角和进入动效。
class EchoBottomSheet {
  EchoBottomSheet._();

  /// 显示标准底部弹层
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool enableDrag = true,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnimatedBottomSheet(
        child: builder(context),
      ),
    );
  }

  /// 显示列表型底部弹层（带拖拽指示条）
  static Future<T?> showList<T>({
    required BuildContext context,
    String? title,
    required List<Widget> children,
    bool isScrollControlled = false,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnimatedBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(context),
            if (title != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: EchoSpacing.lg),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              SizedBox(height: EchoSpacing.md),
            ],
            ...children,
            SizedBox(height: EchoSpacing.md),
          ],
        ),
      ),
    );
  }

  static Widget _buildDragHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 36.w,
        height: 4.h,
        margin: EdgeInsets.symmetric(vertical: EchoSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).echoTextTertiary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }
}

class _AnimatedBottomSheet extends StatelessWidget {
  final Widget child;

  const _AnimatedBottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          top: EchoSpacing.sm,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(EchoRadius.xxl),
              topRight: Radius.circular(EchoRadius.xxl),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(EchoRadius.xxl),
                topRight: Radius.circular(EchoRadius.xxl),
              ),
              child: child,
            ),
          ),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: 0.1,
          end: 0,
          duration: EchoDurations.normal,
          curve: EchoCurves.easeOut,
        )
        .fadeIn(duration: EchoDurations.normal);
  }
}
