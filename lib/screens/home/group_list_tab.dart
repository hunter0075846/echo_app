import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/group_model.dart';
import '../../models/openclaw_connection_model.dart';
import '../../providers/group_provider.dart';
import '../../services/openclaw_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatars/ai_avatar.dart';
import '../../widgets/avatars/openclaw_avatar.dart';
import '../../widgets/avatars/user_avatar.dart';
import '../../widgets/loading_shimmer.dart';

class GroupListTab extends ConsumerStatefulWidget {
  const GroupListTab({super.key});

  @override
  ConsumerState<GroupListTab> createState() => _GroupListTabState();
}

class _GroupListTabState extends ConsumerState<GroupListTab> {
  late final OpenClawService _openClawService;
  List<OpenClawConnectionModel> _openClawConnections = [];
  Map<String, bool> _openClawOnlineStatus = {};
  bool _openClawLoading = true;

  @override
  void initState() {
    super.initState();
    _openClawService = OpenClawService(ApiService());
    _loadOpenClawConnections();
  }

  Future<void> _loadOpenClawConnections() async {
    try {
      final connections = await _openClawService.getConnections();
      final statusFutures = connections.map((conn) async {
        try {
          final status = await _openClawService.getConnectionStatus(conn.id);
          return MapEntry(conn.id, status['connected'] == true);
        } catch (e) {
          return MapEntry(conn.id, false);
        }
      });
      final statuses = await Future.wait(statusFutures);
      final statusMap = Map.fromEntries(statuses);
      if (mounted) {
        setState(() {
          _openClawConnections = connections;
          _openClawOnlineStatus = statusMap;
          _openClawLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _openClawLoading = false);
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(groupListProvider.notifier).loadGroups(),
      _loadOpenClawConnections(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的群聊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateGroupDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _showJoinGroupDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: _buildBody(context, ref, groupState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, GroupListState state) {
    if (state.isLoading && state.groups.isEmpty && _openClawLoading) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 5,
        itemBuilder: (context, index) => const GroupCardShimmer(),
      );
    }

    if (state.error != null && state.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.w,
              color: Theme.of(context).echoTextTertiary,
            ),
            SizedBox(height: 16.h),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).echoTextSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: _refreshAll,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // ========== AI助手区域 ==========
        _buildSectionHeader(
          context,
          title: 'AI助手',
          action: const SizedBox.shrink(),
        ),
        SizedBox(height: 12.h),

        // 小安卡片
        _buildXiaoAnCard(context),
        SizedBox(height: 16.h),
        const Divider(),
        SizedBox(height: 16.h),

        // ========== OpenClaw 区域 ==========
        _buildSectionHeader(
          context,
          title: 'OpenClaw',
          action: TextButton(
            onPressed: () => context.push('/openclaw'),
            child: Text(
              _openClawConnections.isNotEmpty ? '管理' : '去关联',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
        ),
        SizedBox(height: 12.h),

        if (_openClawLoading)
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_openClawConnections.isEmpty)
          _buildOpenClawConnectPrompt(context)
        else
          ..._openClawConnections.take(2).map(
                (conn) => _buildOpenClawConnectionCard(context, conn),
              ),

        if (_openClawConnections.length > 2)
          TextButton(
            onPressed: () => context.push('/openclaw'),
            child: Text(
              '查看全部 ${_openClawConnections.length} 个连接',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),

        SizedBox(height: 16.h),
        const Divider(),
        SizedBox(height: 16.h),

        // ========== 群聊区域 ==========
        _buildSectionHeader(
          context,
          title: '群聊',
          action: TextButton.icon(
            onPressed: () => _showCreateGroupDialog(context, ref),
            icon: Icon(Icons.add, size: 16.sp),
            label: Text('创建', style: TextStyle(fontSize: 13.sp)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        if (state.groups.isEmpty)
          _buildEmptyGroupState(context, ref)
        else
          ...state.groups.map((group) => GroupCard(
                group: group,
                onTap: () => context.push('/group/${group.id}'),
              )),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required Widget action,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).echoTextPrimary,
          ),
        ),
        action,
      ],
    );
  }

  // 小安卡片
  Widget _buildXiaoAnCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/ai-assistant'),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              AIAvatar(size: 48.w),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '小安',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).echoTextPrimary,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '官方',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '推荐话题、分析群聊氛围、生成回忆总结',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).echoTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).echoTextTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // OpenClaw 连接卡片
  Widget _buildOpenClawConnectionCard(BuildContext context, OpenClawConnectionModel connection) {
    final isOnline = _openClawOnlineStatus[connection.id] ?? false;
    final statusColor = isOnline ? AppTheme.successColor : AppTheme.warningColor;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (connection.isPending) {
              context.push('/openclaw/setup?id=${connection.id}').then((_) => _loadOpenClawConnections());
            } else {
              context.push('/openclaw/chat?id=${connection.id}');
            }
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                OpenClawAvatar(
                  size: 48,
                  status: isOnline ? 'connected' : 'disconnected',
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
                              color: Theme.of(context).echoTextPrimary,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              isOnline ? '在线' : (connection.isPending ? '等待连接' : '离线'),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        isOnline
                            ? '点击开始对话'
                            : (connection.isPending
                                ? '请在设备上执行安装脚本'
                                : '设备已离线'),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).echoTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).echoTextTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 未关联时的引导
  Widget _buildOpenClawConnectPrompt(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/openclaw/setup').then((_) => _loadOpenClawConnections()),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.borderColor, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(
              Icons.link,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                '关联我的 OpenClaw',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).echoTextPrimary,
                ),
              ),
            ),
            Text(
              '去关联',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.primaryColor,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // 空群聊状态
  Widget _buildEmptyGroupState(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48.w,
              color: Theme.of(context).echoTextTertiary,
            ),
            SizedBox(height: 12.h),
            Text(
              '还没有群聊',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).echoTextSecondary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              '创建群聊或扫码加入',
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).echoTextTertiary,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('创建群聊'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建群聊'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '群聊名称',
                hintText: '输入群聊名称',
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '群聊描述（可选）',
                hintText: '输入群聊描述',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入群聊名称')),
                );
                return;
              }

              Navigator.pop(context);
              try {
                await ref.read(groupListProvider.notifier).createGroup(
                  name: name,
                  description: descController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('群聊创建成功')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('创建失败: $e')),
                  );
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入群聊'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: '邀请码',
            hintText: '输入6位邀请码',
          ),
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入6位邀请码')),
                );
                return;
              }

              Navigator.pop(context);
              try {
                await ref.read(groupListProvider.notifier).joinGroupByCode(code);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('加入群聊成功')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('加入失败: $e')),
                  );
                }
              }
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                UserAvatar(
                  id: group.id,
                  name: group.name.isNotEmpty ? group.name : '群',
                  size: 48,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).echoTextPrimary,
                        ),
                      ),
                      if (group.description != null && group.description!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            group.description!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Theme.of(context).echoTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      SizedBox(height: 4.h),
                      Text(
                        '${group.currentMembers}/${group.maxMembers} 人',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).echoTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).echoTextTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
