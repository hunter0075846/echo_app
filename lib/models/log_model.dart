import 'package:flutter/foundation.dart';

/// 日志级别枚举
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 日志类型枚举
enum LogType {
  network,      // 网络请求/响应
  function,     // 功能使用
  ui,           // UI交互
  system,       // 系统事件
  error,        // 错误
  backend,      // 后端服务消息
}

/// 日志模型
class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final LogType type;
  final String tag;
  final String message;
  final Map<String, dynamic>? data;
  final String? error;
  final StackTrace? stackTrace;

  LogEntry({
    String? id,
    DateTime? timestamp,
    required this.level,
    required this.type,
    required this.tag,
    required this.message,
    this.data,
    this.error,
    this.stackTrace,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'type': type.name,
      'tag': tag,
      'message': message,
      'data': data,
      'error': error,
      'stackTrace': stackTrace?.toString(),
    };
  }

  /// 从JSON创建
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere((e) => e.name == json['level']),
      type: LogType.values.firstWhere((e) => e.name == json['type']),
      tag: json['tag'],
      message: json['message'],
      data: json['data'],
      error: json['error'],
      stackTrace: json['stackTrace'] != null 
          ? StackTrace.fromString(json['stackTrace']) 
          : null,
    );
  }

  /// 获取级别颜色
  String get levelColor {
    switch (level) {
      case LogLevel.debug:
        return '#9E9E9E'; // 灰色
      case LogLevel.info:
        return '#2196F3'; // 蓝色
      case LogLevel.warning:
        return '#FF9800'; // 橙色
      case LogLevel.error:
        return '#F44336'; // 红色
    }
  }

  /// 获取类型图标
  String get typeIcon {
    switch (type) {
      case LogType.network:
        return '🌐';
      case LogType.function:
        return '⚡';
      case LogType.ui:
        return '🖱️';
      case LogType.system:
        return '⚙️';
      case LogType.error:
        return '❌';
      case LogType.backend:
        return '📡';
    }
  }

  /// 格式化时间
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    final millisecond = timestamp.millisecond.toString().padLeft(3, '0');
    return '$hour:$minute:$second.$millisecond';
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('[${formattedTime}] ${level.name.toUpperCase()} | $tag');
    buffer.writeln('  Type: ${type.name} ${typeIcon}');
    buffer.writeln('  Message: $message');
    if (data != null) {
      buffer.writeln('  Data: $data');
    }
    if (error != null) {
      buffer.writeln('  Error: $error');
    }
    return buffer.toString();
  }
}
