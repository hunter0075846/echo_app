import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

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
          // AI助手小安
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'AI助手',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: () {
                    context.push('/group/${widget.groupId}/ai-chat');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '安',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '小安',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              '点击与我对话',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              onTap: () {
                Navigator.pop(context);
                _showInviteDialog(context, ref);
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

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('邀请好友'),
        content: const Text('生成邀请码，好友输入即可加入'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(groupDetailProvider(widget.groupId).notifier).generateInviteCode();
                if (context.mounted) {
                  Navigator.pop(context);
                  final code = ref.read(groupDetailProvider(widget.groupId)).inviteCode;
                  if (code != null) {
                    _showInviteCode(context, code);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('生成失败: $e')),
                  );
                }
              }
            },
            child: const Text('生成邀请码'),
          ),
        ],
      ),
    );
  }

  void _showInviteCode(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('邀请码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            SizedBox(height: 16.h),
            const Text('有效期24小时，最多10人使用'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 复制邀请码
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('邀请码已复制')),
              );
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出群聊'),
        content: const Text('确定要退出这个群聊吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(groupDetailProvider(widget.groupId).notifier).leaveGroup();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
        title: const Text('解散群聊'),
        content: const Text('确定要解散这个群聊吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(groupDetailProvider(widget.groupId).notifier).deleteGroup();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('解散失败: $e')),
                  );
                }
              }
            },
            child: Text('解散', style: TextStyle(color: AppTheme.errorColor)),
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
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: EdgeInsets.only(left: 8.w, bottom: 4.h),
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
    );
  }
}
