// 平台特定的日志存储接口存根
// 使用条件导入在编译时选择正确的实现

/// 获取日志存储目录路径
/// 在 Web 平台返回 null，在移动端返回实际路径
Future<String?> getLogDirectoryPath() async {
  throw UnsupportedError('Platform not supported');
}

/// 写入日志到文件
/// 在 Web 平台使用 localStorage，在移动端使用文件
Future<void> writeLogToFile(String filePath, String content) async {
  throw UnsupportedError('Platform not supported');
}

/// 从文件读取日志
/// 在 Web 平台使用 localStorage，在移动端使用文件
Future<List<String>> readLogsFromFile(String filePath) async {
  throw UnsupportedError('Platform not supported');
}
