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
    // 去掉可能的 v 前缀（如 v1.0.5 -> 1.0.5）
    String cleanV1 = v1.trim().toLowerCase();
    String cleanV2 = v2.trim().toLowerCase();
    if (cleanV1.startsWith('v')) cleanV1 = cleanV1.substring(1);
    if (cleanV2.startsWith('v')) cleanV2 = cleanV2.substring(1);
    
    // 去掉 +buildNumber 后缀，只比较主版本号
    cleanV1 = cleanV1.split('+').first;
    cleanV2 = cleanV2.split('+').first;
    
    final parts1 = cleanV1.split('.').map(int.parse).toList();
    final parts2 = cleanV2.split('.').map(int.parse).toList();
    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLen; i++) {
      final n1 = i < parts1.length ? parts1[i] : 0;
      final n2 = i < parts2.length ? parts2[i] : 0;
      if (n1 < n2) return -1;
      if (n1 > n2) return 1;
    }
    return 0;
  }

  /// 是否有新版本
  static bool hasNewVersion(String currentVersion, String latestVersion) {
    return compareVersion(currentVersion, latestVersion) < 0;
  }

  /// 是否为 major/minor 升级（x.y 任一变化即视为大版本升级，需要强制更新）
  static bool isMajorMinorUpgrade(String currentVersion, String latestVersion) {
    if (!hasNewVersion(currentVersion, latestVersion)) {
      return false;
    }

    String c = currentVersion.trim().toLowerCase();
    String l = latestVersion.trim().toLowerCase();
    if (c.startsWith('v')) c = c.substring(1);
    if (l.startsWith('v')) l = l.substring(1);
    c = c.split('+').first;
    l = l.split('+').first;

    final cParts = c.split('.');
    final lParts = l.split('.');

    final cMajor = int.tryParse(cParts[0]) ?? 0;
    final lMajor = int.tryParse(lParts[0]) ?? 0;
    if (cMajor != lMajor) return true;

    final cMinor = cParts.length > 1 ? int.tryParse(cParts[1]) ?? 0 : 0;
    final lMinor = lParts.length > 1 ? int.tryParse(lParts[1]) ?? 0 : 0;
    if (cMinor != lMinor) return true;

    return false;
  }
}
