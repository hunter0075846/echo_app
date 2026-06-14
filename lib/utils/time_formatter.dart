import 'package:intl/intl.dart';

/// 聊天时间戳格式化工具
class TimeFormatter {
  TimeFormatter._();

  /// 格式化消息时间
  /// - 当天：HH:mm
  /// - 昨天：昨天 HH:mm
  /// - 同年非当天：M月d日 HH:mm
  /// - 跨年：yyyy/M/d HH:mm
  static String formatChatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final dt = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(messageDay).inDays;
    final timeStr = DateFormat('HH:mm').format(dt);

    if (diffDays == 0) {
      return timeStr;
    } else if (diffDays == 1) {
      return '昨天 $timeStr';
    } else if (dt.year == now.year) {
      return '${DateFormat('M月d日').format(dt)} $timeStr';
    } else {
      return '${DateFormat('yyyy/M/d').format(dt)} $timeStr';
    }
  }

  /// 判断两条消息是否属于同一时间组（5 分钟内、同一天、同一发送者逻辑由调用方控制）
  static bool shouldGroup(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.difference(localB).abs().inMinutes < 5;
  }

  /// 判断两条消息是否在同一天
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }
}
