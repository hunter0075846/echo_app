import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color_tokens.dart';

/// Agent 头像组件
///
/// 圆角方形容器 + 品牌渐变背景，中心保留 emoji 或默认图标。
class AgentAvatar extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final double size;
  final String? label;

  const AgentAvatar({
    super.key,
    this.emoji,
    this.icon,
    this.size = 48,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final s = size.w;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [EchoColors.primary, EchoColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: EchoColors.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: emoji != null && emoji!.isNotEmpty
                ? Text(
                    emoji!,
                    style: TextStyle(fontSize: (size * 0.5).sp),
                  )
                : Icon(
                    icon ?? Icons.smart_toy,
                    color: Colors.white,
                    size: (size * 0.5).w,
                  ),
          ),
        ),
        if (label != null) ...[
          SizedBox(height: 4.h),
          Text(
            label!,
            style: TextStyle(
              fontSize: 10.sp,
              color: EchoColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
