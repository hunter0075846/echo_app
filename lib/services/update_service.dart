import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';
import 'app_service.dart';
import 'log_service.dart';

class UpdateService {
  static final ApiService _api = ApiService();

  /// 检查更新，返回需要更新的信息或 null
  static Future<UpdateInfo?> checkUpdate() async {
    if (kDebugMode) {
      return null;
    }

    try {
      final response = await _api.get('/app/version');
      final data = response.data as Map<String, dynamic>;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final latestVersion = data['latestVersion'] as String;

      final hasNewVersion = _shouldUpdate(currentVersion, latestVersion);
      final isForceUpdate = AppService.isMajorMinorUpgrade(currentVersion, latestVersion);

      if (!hasNewVersion) {
        return null;
      }

      return UpdateInfo(
        latestVersion: latestVersion,
        downloadUrl: data['downloadUrl'] as String,
        releaseNotes: data['releaseNotes'] as String,
        isForce: isForceUpdate,
      );
    } catch (e) {
      logService.error('UpdateService', '版本检查失败', error: e);
      return null;
    }
  }

  /// 打开下载链接（调用系统浏览器）
  static Future<void> openDownloadUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 比较版本号，返回 true 表示需要更新
  static bool _shouldUpdate(String current, String latest) {
    try {
      // 使用统一的版本比较逻辑
      return AppService.compareVersion(current, latest) < 0;
    } catch (_) {
      // 解析失败时按字符串比较
      return latest != current;
    }
  }
}

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isForce;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isForce,
  });
}
