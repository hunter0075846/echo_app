import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/log_model.dart';

// 仅在非 Web 平台导入 dart:io 和 path_provider
import 'log_service_stub.dart'
    if (dart.library.io) 'log_service_io.dart'
    if (dart.library.html) 'log_service_web.dart';

/// 日志服务类
/// 支持内存存储和文件存储，提供日志记录、查询、导出等功能
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  // 内存日志存储（最多保留1000条）
  final List<LogEntry> _logs = [];
  final int _maxMemoryLogs = 1000;

  // 日志流控制器，用于实时更新
  final _logController = StreamController<List<LogEntry>>.broadcast();
  Stream<List<LogEntry>> get logStream => _logController.stream;

  // 日志级别过滤
  LogLevel _minLevel = LogLevel.debug;
  LogLevel get minLevel => _minLevel;
  set minLevel(LogLevel level) {
    _minLevel = level;
    _notifyListeners();
  }

  // 是否启用文件存储
  bool _enableFileStorage = true;
  bool get enableFileStorage => _enableFileStorage;

  // 日志文件路径
  String? _logFilePath;

  /// 初始化日志服务
  Future<void> initialize() async {
    if (_enableFileStorage) {
      await _initLogFile();
      await _loadLogsFromFile();
    }
    _logSystem('LogService initialized');
  }

  /// 从文件加载历史日志
  Future<void> _loadLogsFromFile() async {
    if (_logFilePath == null) return;

    try {
      final lines = await readLogsFromFile(_logFilePath!);
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final entry = LogEntry.fromJson(json);
          _logs.add(entry);
        } catch (e) {
          debugPrint('❌ Failed to parse log line: $e');
        }
      }
      // 限制内存日志数量
      if (_logs.length > _maxMemoryLogs) {
        _logs.removeRange(0, _logs.length - _maxMemoryLogs);
      }
      _notifyListeners();
      debugPrint('📁 Loaded ${_logs.length} logs from storage');
    } catch (e) {
      debugPrint('❌ Failed to load logs from storage: $e');
    }
  }

  /// 初始化日志文件
  Future<void> _initLogFile() async {
    try {
      final logDir = await getLogDirectoryPath();

      if (logDir != null) {
        // 移动端：使用文件系统
        // 确保日志目录存在
        final directory = Directory(logDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final now = DateTime.now();
        final fileName = 'app_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.log';
        _logFilePath = '$logDir/$fileName';
        debugPrint('📁 Log file path: $_logFilePath');
      } else {
        // Web 端：使用 localStorage
        _logFilePath = 'web_logs';
        debugPrint('📁 Using localStorage for logs');
      }
    } catch (e) {
      debugPrint('❌ Failed to init log file: $e');
    }
  }

  // ==================== 日志记录方法 ====================

  /// 记录 Debug 级别日志
  void debug(String tag, String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.debug, LogType.system, tag, message, data: data);
  }

  /// 记录 Info 级别日志
  void info(String tag, String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.info, LogType.system, tag, message, data: data);
  }

  /// 记录 Warning 级别日志
  void warning(String tag, String message, {Map<String, dynamic>? data, String? error}) {
    _log(LogLevel.warning, LogType.system, tag, message, data: data, error: error);
  }

  /// 记录 Error 级别日志
  void error(String tag, String message, {dynamic error, StackTrace? stackTrace}) {
    _log(
      LogLevel.error, 
      LogType.error, 
      tag, 
      message, 
      error: error?.toString(),
      stackTrace: stackTrace,
    );
  }

  /// 记录网络请求日志
  void logNetworkRequest(String method, String url, {Map<String, dynamic>? headers, dynamic body}) {
    _log(
      LogLevel.info,
      LogType.network,
      'HTTP_REQUEST',
      '$method $url',
      data: {
        'method': method,
        'url': url,
        'headers': headers,
        'body': body?.toString(),
      },
    );
  }

  /// 记录网络响应日志
  void logNetworkResponse(String method, String url, int statusCode, {dynamic body, int? durationMs}) {
    final level = statusCode >= 400 ? LogLevel.warning : LogLevel.info;
    _log(
      level,
      LogType.network,
      'HTTP_RESPONSE',
      '$method $url [$statusCode]',
      data: {
        'method': method,
        'url': url,
        'statusCode': statusCode,
        'durationMs': durationMs,
        'body': body?.toString()?.substring(0, body.toString().length > 1000 ? 1000 : body.toString().length),
      },
    );
  }

  /// 记录网络错误日志
  void logNetworkError(String method, String url, dynamic error, {StackTrace? stackTrace}) {
    _log(
      LogLevel.error,
      LogType.network,
      'HTTP_ERROR',
      '$method $url failed',
      error: error?.toString(),
      stackTrace: stackTrace,
    );
  }

  /// 记录功能使用打点
  void logFunction(String functionName, {String? action, Map<String, dynamic>? params}) {
    _log(
      LogLevel.info,
      LogType.function,
      'FUNCTION',
      '$functionName${action != null ? ' - $action' : ''}',
      data: {
        'function': functionName,
        'action': action,
        'params': params,
      },
    );
  }

  /// 记录 UI 交互
  void logUI(String widget, String action, {Map<String, dynamic>? params}) {
    _log(
      LogLevel.debug,
      LogType.ui,
      'UI',
      '$widget - $action',
      data: {
        'widget': widget,
        'action': action,
        'params': params,
      },
    );
  }

  /// 记录后端服务消息
  void logBackendMessage(String event, {dynamic data, String? source}) {
    _log(
      LogLevel.info,
      LogType.backend,
      'BACKEND',
      'Backend message: $event',
      data: {
        'event': event,
        'source': source ?? 'unknown',
        'data': data?.toString(),
      },
    );
  }

  /// 记录后端服务错误
  void logBackendError(String event, dynamic error, {StackTrace? stackTrace, String? source}) {
    _log(
      LogLevel.error,
      LogType.backend,
      'BACKEND_ERROR',
      'Backend error: $event',
      error: error?.toString(),
      stackTrace: stackTrace,
      data: {
        'event': event,
        'source': source ?? 'unknown',
      },
    );
  }

  // ==================== 内部方法 ====================

  /// 核心日志记录方法
  void _log(
    LogLevel level,
    LogType type,
    String tag,
    String message, {
    Map<String, dynamic>? data,
    String? error,
    StackTrace? stackTrace,
  }) {
    // 检查日志级别
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      level: level,
      type: type,
      tag: tag,
      message: message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );

    // 添加到内存
    _logs.add(entry);
    
    // 限制内存日志数量
    if (_logs.length > _maxMemoryLogs) {
      _logs.removeAt(0);
    }

    // 写入文件
    if (_enableFileStorage) {
      _writeToFile(entry);
    }

    // 通知监听器
    _notifyListeners();

    // 输出到控制台（调试用）
    _printToConsole(entry);
  }

  /// 写入文件
  Future<void> _writeToFile(LogEntry entry) async {
    if (_logFilePath == null) return;

    try {
      final line = '${jsonEncode(entry.toJson())}\n';
      await writeLogToFile(_logFilePath!, line);
    } catch (e) {
      debugPrint('❌ Failed to write log to storage: $e');
    }
  }

  /// 输出到控制台
  void _printToConsole(LogEntry entry) {
    final emoji = {
      LogLevel.debug: '🐛',
      LogLevel.info: 'ℹ️',
      LogLevel.warning: '⚠️',
      LogLevel.error: '❌',
    }[entry.level];

    debugPrint('$emoji [${entry.level.name.toUpperCase()}] ${entry.tag}: ${entry.message}');
    if (entry.error != null) {
      debugPrint('   Error: ${entry.error}');
    }
  }

  /// 通知监听器
  void _notifyListeners() {
    _logController.add(List.unmodifiable(_logs));
  }

  /// 记录系统日志
  void _logSystem(String message) {
    _log(LogLevel.info, LogType.system, 'SYSTEM', message);
  }

  // ==================== 查询和导出方法 ====================

  /// 获取所有日志
  List<LogEntry> getAllLogs() {
    return List.unmodifiable(_logs);
  }

  /// 根据级别过滤日志
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// 根据类型过滤日志
  List<LogEntry> getLogsByType(LogType type) {
    return _logs.where((log) => log.type == type).toList();
  }

  /// 根据标签过滤日志
  List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag.contains(tag)).toList();
  }

  /// 搜索日志
  List<LogEntry> searchLogs(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return _logs.where((log) {
      return log.message.toLowerCase().contains(lowerKeyword) ||
          log.tag.toLowerCase().contains(lowerKeyword) ||
          (log.error?.toLowerCase().contains(lowerKeyword) ?? false);
    }).toList();
  }

  /// 清空日志
  void clearLogs() {
    _logs.clear();
    _notifyListeners();
    _logSystem('Logs cleared');
  }

  /// 导出日志为文本
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== App Logs Export ===');
    buffer.writeln('Export Time: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Logs: ${_logs.length}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final log in _logs) {
      buffer.writeln(log.toString());
      buffer.writeln('-' * 50);
    }

    return buffer.toString();
  }

  /// 获取日志文件路径
  String? get logFilePath => _logFilePath;

  /// 获取日志统计信息
  Map<String, int> getLogStats() {
    final stats = <String, int>{};
    
    for (final level in LogLevel.values) {
      stats['${level.name}_count'] = _logs.where((l) => l.level == level).length;
    }
    
    for (final type in LogType.values) {
      stats['${type.name}_count'] = _logs.where((l) => l.type == type).length;
    }
    
    stats['total_count'] = _logs.length;
    
    return stats;
  }

  /// 销毁资源
  void dispose() {
    _logController.close();
  }
}

/// 全局日志服务实例
final logService = LogService();
