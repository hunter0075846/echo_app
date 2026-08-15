import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';

/// 系统设置（v1：修改密码 + 本地通知开关 + 关于）
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _kNotifyKey = 'settings_notify_enabled';

  bool _notifyEnabled = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() => _notifyEnabled = prefs.getBool(_kNotifyKey) ?? true);
      }
    });
  }

  Future<void> _toggleNotify(bool value) async {
    setState(() => _notifyEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifyKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _sectionHeader('账号与安全'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('修改密码'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context),
          ),
          _sectionHeader('通知'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('接收消息提醒'),
            subtitle: const Text('当前仅本机生效'),
            value: _notifyEnabled,
            onChanged: _toggleNotify,
          ),
          _sectionHeader('通用'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于回响'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textTertiaryColor,
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldController = TextEditingController();
    final newController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '原密码'),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '新密码（6-72位）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ApiService().post('/auth/change-password', data: {
                  'oldPassword': oldController.text,
                  'newPassword': newController.text,
                });
                messenger.showSnackBar(
                  const SnackBar(content: Text('密码已修改')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('修改失败: $e')),
                );
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
