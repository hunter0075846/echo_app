import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import 'log_service.dart';

class UpdateService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// 检查更新，返回需要更新的信息或 null
  static Future<UpdateInfo?> checkUpdate() async {
    try {
      final response = await _dio.get('/app/version');
      final data = response.data as Map<String, dynamic>;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final latestVersion = data['latestVersion'] as String;
      final minVersion = data['minVersion'] as String;

      if (!_shouldUpdate(currentVersion, latestVersion)) {
        return null;
      }

      return UpdateInfo(
        latestVersion: latestVersion,
        downloadUrl: data['downloadUrl'] as String,
        releaseNotes: data['releaseNotes'] as String,
        isForce: _shouldUpdate(currentVersion, minVersion),
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
      // 去掉 +buildNumber 后缀
      final currentClean = current.split('+').first;
      final latestClean = latest.split('+').first;
      final currentParts = currentClean.split('.').map(int.parse).toList();
      final latestParts = latestClean.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final latestPart = latestParts[i];

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
      return false;
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
