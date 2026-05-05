import 'package:flutter/material.dart';

import '../services/update_service.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !info.isForce,
      child: AlertDialog(
        title: Text('发现新版本 v${info.latestVersion}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '更新内容：',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(info.releaseNotes),
            if (info.isForce) ...[
              const SizedBox(height: 12),
              const Text(
                '当前版本已不可用，必须更新后才能继续使用。',
                style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          if (!info.isForce)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('以后再说'),
            ),
          FilledButton(
            onPressed: () {
              UpdateService.openDownloadUrl(info.downloadUrl);
              if (!info.isForce) Navigator.of(context).pop();
            },
            child: const Text('立即下载'),
          ),
        ],
      ),
    );
  }

  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: !info.isForce,
      builder: (_) => UpdateDialog(info: info),
    );
  }
}
