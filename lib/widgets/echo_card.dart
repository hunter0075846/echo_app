import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/design_tokens.dart';
import '../utils/animation_utils.dart';

/// 统一卡片组件
///
/// 带主题化圆角、漂浮阴影、按压动效。替代各处重复的 Card + InkWell 组合。
class EchoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final bool floating;

  const EchoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.floating = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget card = Container(
      decoration: BoxDecoration(
        color: color ?? colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius ?? BorderRadius.circular(EchoRadius.card),
        boxShadow: boxShadow ??
            (floating
                ? [EchoShadows.cardFloat]
                : [
                    if (elevation != null && elevation! > 0)
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: elevation! * 4,
                        offset: Offset(0, elevation! * 2),
                      ),
                  ]),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(EchoRadius.card),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: () {
          EchoHaptics.light();
          onTap!();
        },
        child: card
            .animate(target: 0)
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(0.98, 0.98),
              duration: EchoDurations.fast,
              curve: EchoCurves.easeInOut,
            ),
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}
