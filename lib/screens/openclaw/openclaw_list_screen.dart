import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/openclaw_connection_model.dart';
import '../../services/openclaw_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// OpenClaw 连接列表页
class OpenClawListScreen extends StatefulWidget {
  const OpenClawListScreen({super.key});

  @override
  State<OpenClawListScreen> createState() => _OpenClawListScreenState();
}

class _OpenClawListScreenState extends State<OpenClawListScreen> {
  final OpenClawService _service = OpenClawService(ApiService());

  List<OpenClawConnectionModel> _connections = [];
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final connections = await _service.getConnections();
      if (mounted) {
        setState(() {
          _connections = connections;
          _isLoading = false;
        });
      }

      // 如果有 pending 状态的连接，开始轮询
      _startPollingIfNeeded();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _startPollingIfNeeded() {
    _pollTimer?.cancel();
    final hasPending = _connections.any((c) => c.isPending);
    if (!hasPending) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final connections = await _service.getConnections();
        if (mounted) {
          setState(() => _connections = connections);
        }

        // 所有连接都不是 pending 了，停止轮询
        if (!connections.any((c) => c.isPending)) {
          _pollTimer?.cancel();
        }
      } catch (e) {
        // 静默失败
      }
    });
  }

  Future<void> _deleteConnection(OpenClawConnectionModel connection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除连接'),
        content: Text('确定要删除 "${connection.displayName}" 吗？相关聊天记录也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteConnection(connection.id);
      if (mounted) {
        _loadConnections();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  void _goToChat(OpenClawConnectionModel connection) {
    if (connection.isPending) {
      context.push('/openclaw/setup?id=${connection.id}');
    } else {
      context.push('/openclaw/chat?id=${connection.id}');
    }
  }

  void _goToDetail(OpenClawConnectionModel connection) {
    context.push('/openclaw/${connection.id}/edit').then((_) => _loadConnections());
  }

  void _goToSetup() {
    context.push('/openclaw/setup').then((_) => _loadConnections());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的 OpenClaw'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToSetup,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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
              onPressed: _loadConnections,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_connections.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadConnections,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _connections.length,
        itemBuilder: (context, index) {
          final connection = _connections[index];
          return _ConnectionCard(
            connection: connection,
            onTap: () => _goToChat(connection),
            onEdit: () => _goToDetail(connection),
            onDelete: () => _deleteConnection(connection),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🦞',
              style: TextStyle(fontSize: 48.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              '还没有 OpenClaw 连接',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '关联你的 OpenClaw，在回响中与 AI 助手对话',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _goToSetup,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加连接'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final OpenClawConnectionModel connection;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ConnectionCard({
    required this.connection,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = connection.status == 'connected';
    final displayAvatar = connection.avatar ?? '🦞';

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isOnline ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    displayAvatar,
                    style: TextStyle(fontSize: 22.sp),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          connection.displayName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            isOnline ? '在线' : (connection.isPending ? '等待连接' : '离线'),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isOnline ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    if (connection.deviceName != null)
                      Text(
                        connection.deviceName!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 18),
                        SizedBox(width: 8),
                        Text('设置'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
