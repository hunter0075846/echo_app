import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/update_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';

class ForceUpdateScreen extends StatelessWidget {
  final UpdateInfo info;

  const ForceUpdateScreen({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {},
      child: GradientScaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              children: [
                SizedBox(height: 80.h),
                // Logo
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 40.w,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  '发现新版本',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  info.latestVersion,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 40.h),
                // 更新内容
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '更新内容：',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        info.releaseNotes,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondaryColor,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 提示文案
                Text(
                  '当前版本已不可用，更新后才能继续使用',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppTheme.errorColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                // 下载按钮
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: FilledButton(
                    onPressed: _openDownloadUrl,
                    child: Text(
                      '立即下载',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDownloadUrl() async {
    final uri = Uri.parse(info.downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
