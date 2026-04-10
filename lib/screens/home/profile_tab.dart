import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: 打开设置
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // 用户信息卡片
            Card(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    // 头像
                    CircleAvatar(
                      radius: 40.r,
                      backgroundColor: AppTheme.primaryLightColor,
                      child: user?.avatar != null
                          ? null
                          : Icon(
                              Icons.person,
                              size: 40.w,
                              color: AppTheme.primaryColor,
                            ),
                    ),
                    SizedBox(width: 16.w),
                    // 昵称和手机号
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nickname ?? '未设置昵称',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            user?.phone ?? '',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 编辑按钮
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        // TODO: 编辑资料
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // 今日配额
            Card(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日配额',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _QuotaItem(
                            icon: Icons.add_circle_outline,
                            title: '发话题',
                            used: user?.dailyTopicQuota ?? 0,
                            total: user?.maxDailyTopicQuota ?? 10,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _QuotaItem(
                            icon: Icons.visibility_off_outlined,
                            title: '匿名发言',
                            used: user?.anonymousMessageCount ?? 0,
                            total: 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // 功能列表
            Card(
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.help_outline,
                    title: '帮助与反馈',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.info_outline,
                    title: '关于回响',
                    onTap: () {
                      context.push('/about');
                    },
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.logout,
                    title: '退出登录',
                    textColor: AppTheme.errorColor,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('确认退出'),
                          content: const Text('确定要退出登录吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        await ref.read(authStateProvider.notifier).logout();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final int used;
  final int total;

  const _QuotaItem({
    required this.icon,
    required this.title,
    required this.used,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final progress = used / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20.w, color: AppTheme.primaryColor),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          '$remaining',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 4.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              remaining > 0 ? AppTheme.primaryColor : AppTheme.errorColor,
            ),
            minHeight: 6.h,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '剩余 $remaining / $total',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppTheme.textTertiaryColor,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.textSecondaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppTheme.textPrimaryColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
