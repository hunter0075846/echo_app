import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/openclaw_connection_model.dart';
import '../../services/openclaw_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// OpenClaw 连接详情/设置页
class OpenClawDetailScreen extends StatefulWidget {
  final String connectionId;

  const OpenClawDetailScreen({
    super.key,
    required this.connectionId,
  });

  @override
  State<OpenClawDetailScreen> createState() => _OpenClawDetailScreenState();
}

class _OpenClawDetailScreenState extends State<OpenClawDetailScreen> {
  final OpenClawService _service = OpenClawService(ApiService());

  OpenClawConnectionModel? _connection;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;
  String? _token;
  String? _installScript;

  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();
  final _systemPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConnection();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadConnection() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final connection = await _service.getConnectionDetail(widget.connectionId);
      if (mounted) {
        setState(() {
          _connection = connection;
          _nameController.text = connection.name ?? '';
          _avatarController.text = connection.avatar ?? '';
          _systemPromptController.text = connection.systemPrompt ?? '';
          _isLoading = false;
        });
      }

      // pending 状态下额外拉取 token 和安装命令
      if (connection.isPending) {
        try {
          final statusResult = await _service.getConnectionStatus(widget.connectionId);
          if (mounted) {
            setState(() {
              _token = statusResult['token'] as String?;
              _installScript = statusResult['installScript'] as String?;
            });
          }
        } catch (_) {
          // 静默失败，不影响主流程
        }
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

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      await _service.updateConnection(
        widget.connectionId,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        avatar: _avatarController.text.trim().isEmpty ? null : _avatarController.text.trim(),
        systemPrompt: _systemPromptController.text.trim().isEmpty ? null : _systemPromptController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _regenerateToken() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新生成 Token'),
        content: const Text('重新生成 Token 后，原设备上的连接将失效。是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('重新生成', style: TextStyle(color: AppTheme.warningColor)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await _service.createConnection(
        name: _connection?.name,
        avatar: _connection?.avatar,
        systemPrompt: _connection?.systemPrompt,
      );

      // 删除旧连接
      await _service.deleteConnection(widget.connectionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已重新生成 Token')),
        );
        context.replace('/openclaw/setup?id=${result['id']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
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

  Future<void> _copyScript() async {
    if (_installScript == null) return;
    await Clipboard.setData(ClipboardData(text: _installScript!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('安装命令已复制')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('连接设置'),
        actions: [
          if (!_isLoading && !_hasError)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
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

    if (_hasError || _connection == null) {
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
              onPressed: _loadConnection,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final connection = _connection!;
    final isPending = connection.isPending;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像预览
          Center(
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Center(
                child: Text(
                  connection.avatar ?? '🦞',
                  style: TextStyle(fontSize: 36.sp),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // 状态
          _buildInfoRow('状态', _statusText(connection.status)),
          if (connection.deviceName != null)
            _buildInfoRow('设备', connection.deviceName!),
          if (connection.connectedAt != null)
            _buildInfoRow('关联时间', _formatDate(connection.connectedAt!)),

          SizedBox(height: 24.h),
          const Divider(),
          SizedBox(height: 16.h),

          // 编辑区域
          Text(
            '个性化设置',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 16.h),

          _buildTextField(
            label: '名称',
            hint: '给这个 OpenClaw 起个名字',
            controller: _nameController,
          ),
          SizedBox(height: 16.h),

          _buildTextField(
            label: '头像',
            hint: '输入一个 emoji 或头像 URL',
            controller: _avatarController,
          ),
          SizedBox(height: 16.h),

          _buildTextField(
            label: '系统提示词',
            hint: '自定义 OpenClaw 的角色和行为',
            controller: _systemPromptController,
            maxLines: 4,
          ),

          SizedBox(height: 32.h),
          const Divider(),
          SizedBox(height: 16.h),

          // 操作区域
          if (isPending) ...[
            Text(
              '关联信息',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 12.h),
            _buildCopyRow(
              label: 'Token',
              value: _token ?? '',
              onCopy: _copyToken,
            ),
            SizedBox(height: 8.h),
            _buildCopyRow(
              label: '安装命令',
              value: _installScript ?? '',
              onCopy: _copyScript,
            ),
            SizedBox(height: 24.h),
          ],

          // 重新生成 Token
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _regenerateToken,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重新生成 Token'),
            ),
          ),

          SizedBox(height: 16.h),

          // 删除连接
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _deleteConnection(),
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
              label: const Text('删除连接', style: TextStyle(color: AppTheme.errorColor)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Text(
            '$label：',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyRow({
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Text(
              '$label：',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textPrimaryColor,
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

  String _statusText(String status) {
    switch (status) {
      case 'connected':
        return '已连接';
      case 'pending':
        return '等待连接';
      case 'disconnected':
        return '已断开';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteConnection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除连接'),
        content: Text('确定要删除 "${_connection?.displayName ?? '这个连接'}" 吗？相关聊天记录也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteConnection(widget.connectionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }
}
