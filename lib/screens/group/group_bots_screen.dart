import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/group_model.dart';
import '../../models/openclaw_connection_model.dart';
import '../../services/group_service.dart';
import '../../services/openclaw_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// 群 OpenClaw 管理页面
class GroupBotsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupBotsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupBotsScreen> createState() => _GroupBotsScreenState();
}

class _GroupBotsScreenState extends ConsumerState<GroupBotsScreen> {
  final GroupService _groupService = GroupService();
  final OpenClawService _openclawService = OpenClawService(ApiService());

  List<GroupBotModel> _bots = [];
  List<OpenClawConnectionModel> _myConnections = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        _groupService.getGroupBots(widget.groupId),
        _openclawService.getConnections(),
      ]);
      if (!mounted) return;
      setState(() {
        _bots = results[0] as List<GroupBotModel>;
        _myConnections = results[1] as List<OpenClawConnectionModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _addBot(String connectionId) async {
    try {
      await _groupService.addBot(widget.groupId, connectionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('添加成功')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  Future<void> _removeBot(String botId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除 OpenClaw'),
        content: const Text('确定要移除这个 OpenClaw 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _groupService.removeBot(widget.groupId, botId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已移除')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: $e')),
        );
      }
    }
  }

  void _showAddBotSheet() {
    // 过滤掉已经添加的连接
    final addedConnectionIds = _bots.map((b) => b.connectionId).toSet();
    final available = _myConnections
        .where((c) => !addedConnectionIds.contains(c.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可添加的 OpenClaw（已添加全部）')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择要添加的 OpenClaw',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ...available.map((conn) => ListTile(
                  leading: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        conn.avatar ?? '🤖',
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    ),
                  ),
                  title: Text(conn.displayName),
                  subtitle: Text(
                    conn.isConnected ? '在线' : (conn.isPending ? '等待连接' : '离线'),
                    style: TextStyle(
                      color: conn.isConnected
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addBot(conn.id);
                    },
                    child: const Text('添加'),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('群 OpenClaw'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBotSheet,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
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
            const Icon(Icons.error_outline, size: 48),
            const Text('加载失败'),
            TextButton(
              onPressed: _loadData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_bots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🤖', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 16.h),
            Text(
              '还没有 OpenClaw',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Text(
              '添加你的 OpenClaw，让它在群里与大家互动',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _bots.length,
      itemBuilder: (context, index) {
        final bot = _bots[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  bot.avatar ?? bot.connection?['avatar'] ?? '🤖',
                  style: TextStyle(fontSize: 20.sp),
                ),
              ),
            ),
            title: Text(bot.displayName),
            subtitle: Text('添加者: ${bot.ownerName}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              onPressed: () => _removeBot(bot.id),
            ),
          ),
        );
      },
    );
  }
}
