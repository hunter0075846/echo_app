import 'dart:math' show pi, cos, sin;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/color_tokens.dart';

/// OpenClaw 品牌形象 — 连接节点
///
/// 几何风格的网络节点图标，替代原有的龙虾 emoji。
/// 中心圆 + 三条辐射线，外围有状态色环。
class OpenClawAvatar extends StatelessWidget {
  final double size;
  final String? status; // 'connected' | 'disconnected' | 'pending'

  const OpenClawAvatar({
    super.key,
    this.size = 48,
    this.status,
  });

  Color get _statusColor {
    switch (status) {
      case 'connected':
        return EchoColors.accent;
      case 'pending':
        return EchoColors.warning;
      case 'disconnected':
      default:
        return EchoColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = size.w;
    final statusColor = _statusColor;

    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: EchoColors.darkSurface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(s, s),
        painter: _NodePainter(
          nodeColor: EchoColors.accent,
          lineColor: EchoColors.accent.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _NodePainter extends CustomPainter {
  final Color nodeColor;
  final Color lineColor;

  _NodePainter({
    required this.nodeColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final nodeRadius = size.width * 0.12;
    final lineLength = size.width * 0.28;

    // 三条辐射线（120° 分布）
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final angle = (i * 120 + 30) * pi / 180;
      final start = Offset(
        center.dx + nodeRadius * cos(angle),
        center.dy + nodeRadius * sin(angle),
      );
      final end = Offset(
        center.dx + lineLength * cos(angle),
        center.dy + lineLength * sin(angle),
      );
      canvas.drawLine(start, end, linePaint);

      // 末端小圆点
      final dotPaint = Paint()
        ..color = nodeColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 2.5, dotPaint);
    }

    // 中心发光圆
    final glowPaint = Paint()
      ..color = nodeColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, nodeRadius * 1.8, glowPaint);

    // 中心实心圆
    final nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, nodeRadius, nodePaint);

    // 中心高光
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - nodeRadius * 0.3, center.dy - nodeRadius * 0.3),
      nodeRadius * 0.35,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
