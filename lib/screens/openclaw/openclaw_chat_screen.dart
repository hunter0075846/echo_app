import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/openclaw_connection_model.dart';
import '../../models/openclaw_message_model.dart';
import '../../services/openclaw_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatars/openclaw_avatar.dart';

/// 与 OpenClaw 一对一对话页面
class OpenClawChatScreen extends ConsumerStatefulWidget {
  final String connectionId;

  const OpenClawChatScreen({
    super.key,
    required this.connectionId,
  });

  @override
  ConsumerState<OpenClawChatScreen> createState() => _OpenClawChatScreenState();
}

class _OpenClawChatScreenState extends ConsumerState<OpenClawChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<OpenClawMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isInitLoading = true;
  bool _isConnected = false;
  OpenClawConnectionModel? _connection;

  late final OpenClawService _service;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _service = OpenClawService(ApiService());
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final connection = await _service.getConnectionDetail(widget.connectionId);
      final status = await _service.getConnectionStatus(widget.connectionId);
      final connected = status['connected'] == true;

      List<OpenClawMessageModel> messages = [];
      if (connected || connection.status == 'connected' || connection.status == 'disconnected') {
        messages = await _service.getMessages(widget.connectionId);
      }

      if (mounted) {
        setState(() {
          _connection = connection;
          _isConnected = connected;
          _messages.addAll(messages);
          _isInitLoading = false;
        });
      }

      // 如果连接已建立，启动轮询获取新消息
      if (connected) {
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitLoading = false);
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final messages = await _service.getMessages(widget.connectionId);
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(messages);
          });
        }
      } catch (e) {
        // 静默失败
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || !_isConnected) return;

    setState(() {
      _messages.add(OpenClawMessageModel(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        role: 'user',
        content: content,
        createdAt: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      await _service.sendMessage(widget.connectionId, content);
      // 等待后刷新消息列表
      await Future.delayed(const Duration(seconds: 2));
      final messages = await _service.getMessages(widget.connectionId);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _refreshMessages() async {
    try {
      final messages = await _service.getMessages(widget.connectionId);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
        });
      }
    } catch (e) {
      // 静默失败
    }
  }

  void _goToDetail() {
    context.push('/openclaw/${widget.connectionId}/edit').then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _connection?.displayName ?? '我的OpenClaw';
    final status = _isConnected ? 'connected' : 'disconnected';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            OpenClawAvatar(size: 36.w, status: status),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? AppTheme.successColor
                              : AppTheme.textTertiaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _isConnected ? '在线' : '离线',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToDetail,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // 离线提示
          if (!_isConnected)
            Container(
              width: double.infinity,
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 18),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'OpenClaw 未连接，请检查设备状态',
                      style: TextStyle(fontSize: 13.sp, color: AppTheme.warningColor),
                    ),
                  ),
                ],
              ),
            ),

          // 消息列表
          Expanded(
            child: _isInitLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _EmptyState(
                        isConnected: _isConnected,
                        displayName: displayName,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _ChatBubble(
                            message: message,
                          );
                        },
                      ),
          ),

          // 加载指示器
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$displayName 思考中...',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
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
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: _isConnected,
                      decoration: InputDecoration(
                        hintText: _isConnected
                            ? '给 $displayName 发消息...'
                            : '请先关联 OpenClaw',
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
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isConnected ? _sendMessage : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isConnected;
  final String displayName;

  const _EmptyState({
    required this.isConnected,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OpenClawAvatar(
              size: 64.w,
              status: isConnected ? 'connected' : 'disconnected',
            ),
            SizedBox(height: 16.h),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              isConnected
                  ? '开始和 $displayName 对话吧'
                  : '关联后，在这里和 $displayName 一对一对话',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final OpenClawMessageModel message;

  const _ChatBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 16.h,
          left: message.isUser ? 48.w : 0,
          right: message.isUser ? 0 : 48.w,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // OpenClaw头像
            if (!message.isUser) ...[
              OpenClawAvatar(
                size: 36.w,
                status: 'connected',
              ),
              SizedBox(width: 8.w),
            ],

            // 消息内容
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? AppTheme.primaryColor
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    if (!message.isUser)
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
                    color: message.isUser
                        ? Colors.white
                        : AppTheme.textPrimaryColor,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
