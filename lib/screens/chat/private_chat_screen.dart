import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/private_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/friend_service.dart';
import '../../services/message_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatars/user_avatar.dart';

class PrivateChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? nickname;
  final String? avatar;

  const PrivateChatScreen({
    super.key,
    required this.userId,
    this.nickname,
    this.avatar,
  });

  @override
  ConsumerState<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends ConsumerState<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();
  List<PrivateMessageModel> _messages = [];
  bool _isLoading = true;
  late String? _nickname;
  late String? _avatar;

  @override
  void initState() {
    super.initState();
    _nickname = widget.nickname;
    _avatar = widget.avatar;
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      _messages = await _messageService.getMessages(widget.userId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载消息失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      final message = await _messageService.sendMessage(
        receiverId: widget.userId,
        content: content,
      );
      setState(() {
        _messages.add(message);
        _messageController.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                context.push('/friend/detail/${widget.userId}', extra: {
                  'nickname': _nickname,
                  'avatar': _avatar,
                });
              },
              child: UserAvatar(
                id: widget.userId,
                name: _nickname,
                imageUrl: _avatar,
                size: 36,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nickname ?? '好友',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  Text(
                    '在线',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    reverse: false,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == currentUser?.id;
                      return _ChatMessage(
                        message: message,
                        isMe: isMe,
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
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
          ),
        ],
      ),
    );
  }

  void _showChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: Text('删除好友', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteFriendConfirm(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteFriendConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友 ${_nickname ?? widget.userId} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FriendService().deleteFriend(widget.userId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已删除好友')),
                );
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除失败: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final PrivateMessageModel message;
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
            if (!isMe) ...[
              UserAvatar(
                id: message.senderId,
                size: 40,
              ),
              SizedBox(width: 8.w),
            ],
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isMe ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    if (!isMe)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isMe ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ),
            if (isMe) ...[
              SizedBox(width: 8.w),
              UserAvatar(
                id: message.senderId,
                size: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }
}