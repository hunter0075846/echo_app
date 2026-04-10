import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于回响'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Logo
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 48.w,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '回响',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '版本 1.0.0',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 32.h),
            // 功能介绍
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '功能介绍',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildFeatureItem(
                      icon: Icons.explore,
                      title: '热门话题广场',
                      description: '浏览、搜索和转发热门话题',
                    ),
                    _buildFeatureItem(
                      icon: Icons.chat,
                      title: '私密群聊',
                      description: '与好友一起讨论感兴趣的话题',
                    ),
                    _buildFeatureItem(
                      icon: Icons.theater_comedy,
                      title: '匿名发言',
                      description: '以"有人说"的身份匿名表达观点',
                    ),
                    _buildFeatureItem(
                      icon: Icons.history,
                      title: '群回忆',
                      description: '自动记录群内的精彩瞬间',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // 协议和条款
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('用户协议'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _launchUrl('https://echo.app/terms'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('隐私政策'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _launchUrl('https://echo.app/privacy'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            // 版权信息
            Text(
              '© 2024 回响 All Rights Reserved',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textTertiaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryLightColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 20.w, color: AppTheme.primaryColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
