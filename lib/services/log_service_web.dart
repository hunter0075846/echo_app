// Web 端日志存储实现
// 使用 localStorage 存储日志
import 'dart:html' as html;

const String _logStorageKey = 'echo_app_logs';

/// 获取日志存储目录路径
/// Web 端不使用文件路径，返回 null
Future<String?> getLogDirectoryPath() async {
  return null;
}

/// 写入日志到 localStorage
Future<void> writeLogToFile(String filePath, String content) async {
  try {
    final storage = html.window.localStorage;
    final existingLogs = storage[_logStorageKey] ?? '';
    storage[_logStorageKey] = existingLogs + content;
  } catch (e) {
    // localStorage 可能不可用或已满
    print('Failed to write log to localStorage: $e');
  }
}

/// 从 localStorage 读取日志
Future<List<String>> readLogsFromFile(String filePath) async {
  try {
    final storage = html.window.localStorage;
    final logs = storage[_logStorageKey] ?? '';
    if (logs.isEmpty) return [];
    return logs.split('\n').where((line) => line.trim().isNotEmpty).toList();
  } catch (e) {
    print('Failed to read logs from localStorage: $e');
    return [];
  }
}
