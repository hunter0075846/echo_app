import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';

class VersionInfo {
  final String latestVersion;
  final String minVersion;
  final String downloadUrl;
  final String releaseNotes;

  VersionInfo({
    required this.latestVersion,
    required this.minVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      latestVersion: json['latestVersion'] as String,
      minVersion: json['minVersion'] as String,
      downloadUrl: json['downloadUrl'] as String,
      releaseNotes: json['releaseNotes'] as String,
    );
  }
}

class AppService {
  final ApiService _api = ApiService();

  /// 获取服务器最新版本信息
  Future<VersionInfo> checkUpdate() async {
    final response = await _api.get('/app/version');
    return VersionInfo.fromJson(response.data as Map<String, dynamic>);
  }

  /// 获取本地当前版本号
  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// 比较两个版本号
  /// 返回值: -1 表示 v1 < v2, 0 表示相等, 1 表示 v1 > v2
  static int compareVersion(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();
    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLen; i++) {
      final n1 = i < parts1.length ? parts1[i] : 0;
      final n2 = i < parts2.length ? parts2[i] : 0;
      if (n1 < n2) return -1;
      if (n1 > n2) return 1;
    }
    return 0;
  }

  /// 是否需要强制更新（当前版本低于最低支持版本）
  static bool isForceUpdate(String currentVersion, String minVersion) {
    return compareVersion(currentVersion, minVersion) < 0;
  }

  /// 是否有新版本
  static bool hasNewVersion(String currentVersion, String latestVersion) {
    return compareVersion(currentVersion, latestVersion) < 0;
  }
}
