import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/avatars/user_avatar.dart';
import '../../widgets/gradient_scaffold.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            children: [
              // 顶部设置按钮
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.settings_outlined, color: theme.echoTextSecondary),
                  onPressed: () {
                    // TODO: 打开设置
                  },
                ),
              ),
              SizedBox(height: 8.h),
              // 头像和用户名
              UserAvatar(
                id: user?.id,
                name: user?.nickname,
                imageUrl: user?.avatar,
                size: 100,
              ),
              SizedBox(height: 16.h),
              Text(
                user?.nickname ?? '未设置昵称',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(EchoRadius.full),
                ),
                child: Text(
                  '回响用户',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              // 统计卡片
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: '${user?.dailyTopicQuota ?? 0}',
                      label: '今日话题',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _StatCard(
                      value: '12',
                      label: '连续登录',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _StatCard(
                      value: '3',
                      label: '好友',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // 今日配额
              _buildQuotaCard(context, ref, user),
              SizedBox(height: 16.h),
              // 功能列表
              _buildSettingsCard(context, ref),
              SizedBox(height: 24.h),
              // 退出登录
              TextButton(
                onPressed: () async {
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
                child: Text(
                  '退出登录',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaCard(BuildContext context, WidgetRef ref, dynamic user) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EchoRadius.card),
        boxShadow: [EchoShadows.cardFloat],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日配额',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EchoRadius.card),
        boxShadow: [EchoShadows.cardFloat],
      ),
      child: Column(
        children: [
          _SettingsItem(
            icon: Icons.help_outline,
            title: '帮助与反馈',
            onTap: () {},
          ),
          Divider(height: 1, indent: 56.w, color: AppTheme.dividerColor),
          _SettingsItem(
            icon: Icons.info_outline,
            title: '关于回响',
            onTap: () {
              context.push('/about');
            },
          ),
        ],
      ),
    );
  }

}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EchoRadius.lg),
        boxShadow: [EchoShadows.cardFloat],
      ),
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.echoTextTertiary,
            ),
          ),
        ],
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

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          size: 20.w,
          color: colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textPrimaryColor,
          fontSize: 15.sp,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
