import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/friend_model.dart';
import '../../models/group_model.dart';
import '../../models/openclaw_connection_model.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/friend_service.dart';
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
  final FriendService _friendService = FriendService();
  List<OpenClawConnectionModel> _openClawConnections = [];
  Map<String, bool> _openClawOnlineStatus = {};
  bool _openClawLoading = true;
  List<FriendRequestModel> _friendRequests = [];
  bool _showAddFriendSheet = false;
  String _phoneInput = '';

  @override
  void initState() {
    super.initState();
    _openClawService = OpenClawService(ApiService());
    _loadOpenClawConnections();
    _loadFriendRequests();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationProvider.notifier).loadConversations();
    });
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

  Future<void> _loadFriendRequests() async {
    try {
      final requests = await _friendService.getFriendRequests();
      if (mounted) {
        setState(() => _friendRequests = requests);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _handleSendFriendRequest() async {
    if (_phoneInput.isEmpty) return;
    try {
      await _friendService.sendFriendRequest(_phoneInput);
      if (mounted) {
        setState(() {
          _showAddFriendSheet = false;
          _phoneInput = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('好友请求已发送')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    }
  }

  Future<void> _handleAcceptRequest(String userId) async {
    try {
      await _friendService.acceptFriendRequest(userId);
      await _loadFriendRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加好友')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _handleRejectRequest(String userId) async {
    try {
      await _friendService.rejectFriendRequest(userId);
      await _loadFriendRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(groupListProvider.notifier).loadGroups(),
      _loadOpenClawConnections(),
      _loadFriendRequests(),
    ]);
    ref.read(conversationProvider.notifier).loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              switch (value) {
                case 'create_group':
                  _showCreateGroupDialog(context, ref);
                  break;
                case 'scan_join':
                  _showJoinGroupDialog(context, ref);
                  break;
                case 'connect_openclaw':
                  context.push('/openclaw/setup').then((_) => _loadOpenClawConnections());
                  break;
                case 'add_friend':
                  setState(() => _showAddFriendSheet = true);
                  break;
                case 'my_friends':
                  context.push('/friends');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create_group',
                child: Row(
                  children: [
                    const Icon(Icons.group_add, size: 18),
                    SizedBox(width: 8.w),
                    const Text('创建群聊'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'scan_join',
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 18),
                    SizedBox(width: 8.w),
                    const Text('扫码加入'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'connect_openclaw',
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 18),
                    SizedBox(width: 8.w),
                    const Text('关联 OpenClaw'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_friend',
                child: Row(
                  children: [
                    const Icon(Icons.person_add, size: 18),
                    SizedBox(width: 8.w),
                    const Text('添加好友'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'my_friends',
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 18),
                    SizedBox(width: 8.w),
                    const Text('我的好友'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: _buildBody(context, ref, groupState),
      ),
      bottomSheet: _showAddFriendSheet
          ? Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '添加好友',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '请输入手机号',
                    ),
                    onChanged: (value) => _phoneInput = value,
                    autofocus: true,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _showAddFriendSheet = false),
                          child: const Text('取消'),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSendFriendRequest,
                          child: const Text('发送请求'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, GroupListState state) {
    final conversationState = ref.watch(conversationProvider);

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

    final hasAnyChat = conversationState.conversations.isNotEmpty || state.groups.isNotEmpty;

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // 小安卡片
        _buildXiaoAnCard(context),
        SizedBox(height: 8.h),
        const Divider(),
        SizedBox(height: 8.h),

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

        SizedBox(height: 8.h),
        const Divider(),
        SizedBox(height: 8.h),

        // 聊天区域标题
        Text(
          '聊天',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).echoTextPrimary,
          ),
        ),
        SizedBox(height: 12.h),

        // 好友请求提示
        if (_friendRequests.isNotEmpty)
          _buildFriendRequestBanner(context),

        // 聊天列表：私聊会话 + 群聊
        if (hasAnyChat) ...[
          ...conversationState.conversations.map(
            (conv) => _buildConversationTile(context, conv),
          ),
          ...state.groups.map(
            (group) => _buildGroupTile(context, group),
          ),
        ] else
          _buildEmptyChatState(context, ref),
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

  // 空聊天状态
  Widget _buildEmptyChatState(BuildContext context, WidgetRef ref) {
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
              '还没有聊天',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).echoTextSecondary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              '创建群聊或添加好友',
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

  // 私聊会话项
  Widget _buildConversationTile(BuildContext context, ConversationModel conversation) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.h),
      leading: UserAvatar(
        id: conversation.userId,
        name: conversation.nickname,
        imageUrl: conversation.avatar,
        size: 48,
      ),
      title: Text(
        conversation.nickname ?? conversation.phone,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).echoTextPrimary,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage,
        style: TextStyle(
          fontSize: 13.sp,
          color: Theme.of(context).echoTextSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.lastMessageAt),
            style: TextStyle(
              fontSize: 11.sp,
              color: Theme.of(context).echoTextTertiary,
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              margin: EdgeInsets.only(top: 4.h),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      onTap: () => context.push('/chat/${conversation.userId}', extra: {
        'userId': conversation.userId,
        'nickname': conversation.nickname,
        'avatar': conversation.avatar,
      }),
    );
  }

  // 群聊项（ListTile 样式）
  Widget _buildGroupTile(BuildContext context, GroupModel group) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4.h),
      leading: UserAvatar(
        id: group.id,
        name: group.name.isNotEmpty ? group.name : '群',
        size: 48,
      ),
      title: Text(
        group.name,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).echoTextPrimary,
        ),
      ),
      subtitle: Text(
        group.description != null && group.description!.isNotEmpty
            ? '${group.description} · ${group.currentMembers}人'
            : '${group.currentMembers}人',
        style: TextStyle(
          fontSize: 13.sp,
          color: Theme.of(context).echoTextSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: Theme.of(context).echoTextTertiary,
      ),
      onTap: () => context.push('/group/${group.id}'),
    );
  }

  // 好友请求提示横幅
  Widget _buildFriendRequestBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        // 点击展开好友请求处理
        _showFriendRequestsSheet(context);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_add,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                '${_friendRequests.length} 条好友请求',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
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

  void _showFriendRequestsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '好友请求',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            ..._friendRequests.map((req) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(
                id: req.userId,
                name: req.nickname,
                imageUrl: req.avatar,
                size: 40,
              ),
              title: Text(req.nickname ?? req.phone),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _handleRejectRequest(req.userId),
                    child: Text(
                      '拒绝',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleAcceptRequest(req.userId),
                    child: const Text('接受'),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
