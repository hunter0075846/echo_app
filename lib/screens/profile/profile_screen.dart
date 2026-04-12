import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          if (user != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        user.nickname?.substring(0, 1).toUpperCase() ??
                            user.phone.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.nickname ?? '用户${user.phone.substring(7)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '手机号: ${user.phone}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            ),

          // 设置列表
          const Divider(),

          // 退出登录按钮
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              '退出登录',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showLogoutConfirmDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出后需要重新登录，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text(
              '退出',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
