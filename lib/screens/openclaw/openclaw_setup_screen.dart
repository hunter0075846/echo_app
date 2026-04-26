import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../services/openclaw_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// OpenClaw 关联引导页面
class OpenClawSetupScreen extends StatefulWidget {
  const OpenClawSetupScreen({super.key});

  @override
  State<OpenClawSetupScreen> createState() => _OpenClawSetupScreenState();
}

class _OpenClawSetupScreenState extends State<OpenClawSetupScreen> {
  final OpenClawService _service = OpenClawService(ApiService());

  bool _isLoading = true;
  bool _hasError = false;
  String? _token;
  String? _installScript;
  String _status = 'none';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await _service.generateToken();
      _token = result['token'] as String?;
      _installScript = result['installScript'] as String?;
      _status = result['status'] as String? ?? 'pending';

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (_status == 'pending') {
        _startPolling();
      } else if (_status == 'connected') {
        _goToChat();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final status = await _service.getStatus();
        final newStatus = status['status'] as String? ?? 'none';
        final connected = status['connected'] == true;

        if (mounted) {
          setState(() => _status = newStatus);
        }

        if (connected) {
          _pollTimer?.cancel();
          _goToChat();
        }
      } catch (e) {
        // 轮询失败静默处理
      }
    });
  }

  void _goToChat() {
    if (mounted) {
      context.replace('/openclaw/chat');
    }
  }

  Future<void> _copyScript() async {
    if (_installScript == null) return;
    await Clipboard.setData(ClipboardData(text: _installScript!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('安装命令已复制')),
      );
    }
  }

  Future<void> _copyToken() async {
    if (_token == null) return;
    await Clipboard.setData(ClipboardData(text: _token!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token 已复制')),
      );
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解除关联'),
        content: const Text('确定要解除与 OpenClaw 的关联吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('解除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.disconnect();
      if (mounted) {
        _pollTimer?.cancel();
        _init();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解除关联失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关联 OpenClaw'),
        actions: [
          if (_status == 'connected')
            TextButton(
              onPressed: _disconnect,
              child: const Text('解除关联', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.w, color: AppTheme.textTertiaryColor),
            SizedBox(height: 16.h),
            Text(
              '加载失败',
              style: TextStyle(fontSize: 16.sp, color: AppTheme.textSecondaryColor),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: _init,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_status == 'connected') {
      return _buildConnectedState();
    }

    return _buildSetupSteps();
  }

  Widget _buildSetupSteps() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            '关联你的 OpenClaw',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '只需 2 步，即可在回响中与你的 OpenClaw 对话',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 32.h),

          // 步骤 1
          _buildStep(
            number: 1,
            title: '复制安装命令',
            description: '在运行 OpenClaw 的设备（电脑/服务器）上执行以下命令',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        _installScript ?? '',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFFD4D4D4),
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _copyScript,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('复制命令'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 28.h),

          // 步骤 2
          _buildStep(
            number: 2,
            title: '等待连接',
            description: '命令执行成功后，OpenClaw 会自动连接回响',
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 40.w,
                    height: 40.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Colors.orange),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '等待 OpenClaw 连接...',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '请在 OpenClaw 设备上执行安装命令',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Token 信息（可展开）
                  _buildTokenSection(),
                ],
              ),
            ),
          ),

          SizedBox(height: 32.h),

          // 帮助提示
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '常见问题',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 10.h),
                _buildFaqItem(
                  '什么是 OpenClaw？',
                  'OpenClaw 是一个开源的 AI Agent 平台，你可以在自己的设备上部署和运行 AI 助手。',
                ),
                _buildFaqItem(
                  '命令执行失败怎么办？',
                  '请确保设备已安装 Node.js 和 OpenClaw CLI，并且网络可以访问回响服务器。',
                ),
                _buildFaqItem(
                  '如何确认已连接？',
                  '执行命令后，如果看到 "Connected to Echo" 字样，即表示关联成功。',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.only(left: 40.w),
          child: child,
        ),
      ],
    );
  }

  Widget _buildTokenSection() {
    return InkWell(
      onTap: _copyToken,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.vpn_key, size: 16, color: AppTheme.textTertiaryColor),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _token ?? '',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryColor,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.copy, size: 16, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            answer,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.check,
                  size: 40.w,
                  color: Colors.green,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'OpenClaw 已连接',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '你的 OpenClaw 已成功关联到回响',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: _goToChat,
              icon: const Icon(Icons.chat, size: 20),
              label: const Text('开始对话'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
              ),
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: _disconnect,
              child: const Text('解除关联', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
