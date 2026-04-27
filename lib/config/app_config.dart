/// 应用配置文件
/// 环境变量可以通过 --dart-define 传入
class AppConfig {
  /// 后端 API 基础地址
  /// 默认值为 api.wudiclaw.cloud
  /// 可以通过 --dart-define=API_BASE_URL=https://xxx.com/api 覆盖
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    // 如果环境变量为空，使用默认值
    return envUrl.isEmpty
        ? 'https://api.wudiclaw.cloud/api'
        : envUrl;
  }

  /// 是否开启调试日志
  static const bool enableDebugLog = bool.fromEnvironment(
    'ENABLE_DEBUG_LOG',
    defaultValue: false,
  );

  /// 应用名称
  static const String appName = '回响';

  /// 应用版本
  static const String appVersion = '1.0.0';
}
