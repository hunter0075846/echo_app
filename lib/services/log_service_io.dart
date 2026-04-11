// 移动端（Android/iOS）日志存储实现
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 获取日志存储目录路径
Future<String?> getLogDirectoryPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/logs';
}

/// 写入日志到文件
Future<void> writeLogToFile(String filePath, String content) async {
  final file = File(filePath);
  await file.writeAsString(content, mode: FileMode.append);
}

/// 从文件读取日志
Future<List<String>> readLogsFromFile(String filePath) async {
  final file = File(filePath);
  if (await file.exists()) {
    return await file.readAsLines();
  }
  return [];
}
