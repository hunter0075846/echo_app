import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color_tokens.dart';

/// AI 助手「小E」品牌头像
///
/// 圆形 + 品牌渐变 + 中心「E」字。
/// [animated] 为 true 时播放脉冲光环动画。
class AIAvatar extends StatefulWidget {
  final double size;
  final bool animated;

  const AIAvatar({
    super.key,
    this.size = 48,
    this.animated = false,
  });

  @override
  State<AIAvatar> createState() => _AIAvatarState();
}

class _AIAvatarState extends State<AIAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AIAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size.w;
    final fontSize = (widget.size * 0.5).sp;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseScale = widget.animated
            ? 1.0 + _pulseAnimation.value * 0.08
            : 1.0;
        final pulseAlpha = widget.animated
            ? 0.15 + _pulseAnimation.value * 0.15
            : 0.0;

        return SizedBox(
          width: size * 1.3,
          height: size * 1.3,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 脉冲光环
                if (widget.animated)
                  Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EchoColors.primary.withValues(alpha: pulseAlpha),
                      ),
                    ),
                  ),
                // 圆形主体
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [EchoColors.primary, EchoColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                ),
                // 中心文字
                Text(
                  'E',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
