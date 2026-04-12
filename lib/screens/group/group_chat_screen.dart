import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChatScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAnonymous = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await ref.read(groupDetailProvider(widget.groupId).notifier).sendMessage(
        content: content,
        isAnonymous: _isAnonymous,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupDetailProvider(widget.groupId));
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: groupState.group != null
            ? Column(
                children: [
                  Text(
                    groupState.group!.name,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  Text(
                    '${groupState.group!.currentMembers}人',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              )
            : const Text('群聊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              context.push('/group/${widget.groupId}/memories');
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showGroupMenu(context, ref, groupState);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: groupState.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    reverse: true,
                    itemCount: groupState.messages.length,
                    itemBuilder: (context, index) {
                      final message = groupState.messages[index];
                      final isMe = message.senderId == currentUser?.id;
                      return _ChatMessage(
                        message: message,
                        isMe: isMe,
                      );
                    },
                  ),
          ),
          // 输入框
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // 匿名发言开关
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.theater_comedy,
                        color: _isAnonymous ? AppTheme.anonymousColor : AppTheme.textTertiaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isAnonymous = !_isAnonymous;
                        });
                      },
                    ),
                    if (_isAnonymous)
                      Text(
                        '匿名发言中',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.anonymousColor,
                        ),
                      ),
                    const Spacer(),
                    // 转发话题按钮
                    TextButton.icon(
                      onPressed: () {
                        // TODO: 转发话题到群
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('转发话题'),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: _isAnonymous ? '匿名发言...' : '输入消息...',
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupMenu(BuildContext context, WidgetRef ref, GroupDetailState state) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('邀请好友'),
              onTap: () async {
                Navigator.pop(context);
                await _shareGroupInvite(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('群成员'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 显示群成员列表
              },
            ),
            if (state.group?.ownerId == ref.read(authStateProvider).value?.id)
              ListTile(
                leading: Icon(Icons.delete, color: AppTheme.errorColor),
                title: Text('解散群聊', style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirm(context, ref);
                },
              )
            else
              ListTile(
                leading: Icon(Icons.exit_to_app, color: AppTheme.errorColor),
                title: Text('退出群聊', style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveConfirm(context, ref);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareGroupInvite(BuildContext parentContext, WidgetRef ref) async {
    try {
      // 生成邀请码
      await ref.read(groupDetailProvider(widget.groupId).notifier).generateInviteCode();
      final groupState = ref.read(groupDetailProvider(widget.groupId));
      final code = groupState.inviteCode;
      final groupName = groupState.group?.name ?? '群聊';

      if (code != null) {
        // 构建分享文本
        final inviteLink = 'https://echo.wudiclaw.cloud/join?code=$code';
        final shareText = '邀请你加入群聊 "$groupName"\n\n邀请码：$code\n点击链接加入：$inviteLink\n\n（有效期24小时）';

        // 直接调用系统分享
        await Share.share(
          shareText,
          subject: '邀请你加入群聊 "$groupName"',
        );
      }
    } catch (e) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('邀请失败: $e')),
        );
      }
    }
  }

  void _showLeaveConfirm(BuildContext parentContext, WidgetRef ref) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('退出群聊'),
        content: const Text('确定要退出这个群聊吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(groupDetailProvider(widget.groupId).notifier).leaveGroup();
                // 从群聊列表中移除该群聊
                await ref.read(groupListProvider.notifier).removeGroup(widget.groupId);
                if (parentContext.mounted) {
                  Navigator.pop(parentContext);
                }
              } catch (e) {
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('退出失败: $e')),
                  );
                }
              }
            },
            child: Text('退出', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 48.w),
        title: Text(
          '解散群聊',
          style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('此操作将永久删除该群聊，包括：'),
            SizedBox(height: 12.h),
            _buildRiskItem('所有聊天记录'),
            _buildRiskItem('所有群成员关系'),
            _buildRiskItem('群聊设置和数据'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.errorColor, size: 20.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '此操作不可恢复，请谨慎操作！',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
              Navigator.pop(context);
              // 二次确认
              _showFinalDeleteConfirm(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认解散'),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(Icons.remove_circle_outline, color: AppTheme.errorColor, size: 16.w),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirm(BuildContext parentContext, WidgetRef ref) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '最后确认',
          style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
        ),
        content: const Text('你真的确定要解散这个群聊吗？此操作一旦执行将无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(groupDetailProvider(widget.groupId).notifier).deleteGroup();
                // 从群聊列表中移除该群聊
                await ref.read(groupListProvider.notifier).removeGroup(widget.groupId);
                if (parentContext.mounted) {
                  Navigator.pop(parentContext);
                }
              } catch (e) {
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('解散失败: $e')),
                  );
                }
              }
            },
            child: Text('确认解散', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;

  const _ChatMessage({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: isMe ? 64.w : 0,
          right: isMe ? 0 : 64.w,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 左侧头像（非自己发送的消息）
            if (!isMe) ...[
              _buildAvatar(),
              SizedBox(width: 8.w),
            ],
            // 消息内容
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 发送者名称
                  if (!isMe)
                    Padding(
                      padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.isAnonymous) ...[
                            Icon(
                              Icons.theater_comedy,
                              size: 14.w,
                              color: AppTheme.anonymousColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '有人说',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.anonymousColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else
                            Text(
                              message.senderName ?? '未知用户',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  // 消息气泡
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppTheme.primaryColor
                          : message.isAnonymous
                              ? AppTheme.anonymousBgColor
                              : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        if (!isMe)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isMe
                            ? Colors.white
                            : message.isAnonymous
                                ? AppTheme.anonymousColor
                                : AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 右侧头像（自己发送的消息）
            if (isMe) ...[
              SizedBox(width: 8.w),
              _buildAvatar(),
            ],
          ],
        ),
      ),
    );
  }

  // 构建头像
  Widget _buildAvatar() {
    // 匿名消息显示匿名图标
    if (message.isAnonymous) {
      return Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppTheme.anonymousBgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.theater_comedy,
            size: 20.w,
            color: AppTheme.anonymousColor,
          ),
        ),
      );
    }

    // 有头像URL时显示网络图片
    if (message.senderAvatar != null && message.senderAvatar!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          message.senderAvatar!,
          width: 40.w,
          height: 40.w,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }

    // 默认头像
    return _buildDefaultAvatar();
  }

  // 构建默认头像
  Widget _buildDefaultAvatar() {
    final initial = (message.senderName?.isNotEmpty == true)
        ? message.senderName![0].toUpperCase()
        : '?';
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
