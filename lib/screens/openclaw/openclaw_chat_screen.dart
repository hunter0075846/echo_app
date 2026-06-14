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
import '../../utils/animation_utils.dart';
import '../../utils/time_formatter.dart';
import '../../widgets/avatars/openclaw_avatar.dart';
import '../../widgets/gradient_scaffold.dart';

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

class _OpenClawChatScreenState extends ConsumerState<OpenClawChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _firstUnreadKey = GlobalKey();
  final List<OpenClawMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isInitLoading = true;
  bool _isConnected = false;
  int? _firstUnreadIndex;
  OpenClawConnectionModel? _connection;

  late final OpenClawService _service;
  Timer? _pollTimer;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = OpenClawService(ApiService());
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    _sseSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 回到前台时刷新消息并重建 SSE，防止后台期间漏消息
      _refreshMessages();
      if (_isConnected) {
        _connectSSE();
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _service.getConnectionDetail(widget.connectionId),
        _service.getConnectionStatus(widget.connectionId),
      ]);
      final connection = results[0] as OpenClawConnectionModel;
      final status = results[1] as Map<String, dynamic>;
      final connected = status['connected'] == true;

      List<OpenClawMessageModel> messages = [];
      if (connected || connection.status == 'connected' || connection.status == 'disconnected') {
        messages = await _service.getMessages(widget.connectionId);
      }

      if (mounted) {
        setState(() {
          _connection = connection;
          _isConnected = connected;
          _messages
            ..clear()
            ..addAll(messages);
          _isInitLoading = false;
          _firstUnreadIndex = _findFirstUnreadIndex(messages);
        });
      }

      _scrollToFirstUnreadOrBottom();

      // 如果连接已建立，启动 SSE 实时推送 + 轮询兜底
      if (connected) {
        _connectSSE();
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitLoading = false);
      }
    }
  }

  void _connectSSE() {
    _sseSubscription?.cancel();
    _sseSubscription = _service.connectSSE(widget.connectionId).listen(
      (message) {
        if (mounted) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        }
      },
      onError: (e) {
        debugPrint('[OpenClawChat] SSE error: $e');
      },
      onDone: () {
        _sseSubscription = null;
        // 连接断开，3秒后重连
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isConnected) _connectSSE();
        });
      },
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final messages = await _service.getMessages(widget.connectionId);
        if (!mounted) return;
        final hadNewMessages = messages.length > _messages.length;
        setState(() {
          _messages
            ..clear()
            ..addAll(messages);
          _firstUnreadIndex = _findFirstUnreadIndex(messages);
        });
        if (hadNewMessages && _isNearBottom()) {
          _scrollToBottom();
        }
      } catch (e) {
        // 静默失败
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || !_isConnected) return;

    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _messages.add(OpenClawMessageModel(
        id: tempId,
        role: 'user',
        content: content,
        createdAt: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final sentMessage = await _service.sendMessage(widget.connectionId, content);
      if (mounted) {
        setState(() {
          // 替换 temp 为服务端正式消息，避免与 SSE 推送冲突
          final tempIndex = _messages.indexWhere((m) => m.id == tempId);
          if (tempIndex >= 0) {
            _messages[tempIndex] = sentMessage;
          }
          _isLoading = false;
        });
      }
      // 确保 SSE 已连接
      if (_sseSubscription == null) {
        _connectSSE();
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

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.pixels >= position.maxScrollExtent - 100;
  }

  int? _findFirstUnreadIndex(List<OpenClawMessageModel> messages) {
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].isUnread) return i;
    }
    return null;
  }

  void _scrollToFirstUnreadOrBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
        if (mounted) _markUnreadMessagesAsRead(_messages);
      });
    });
  }

  Future<void> _markUnreadMessagesAsRead(
      List<OpenClawMessageModel> messages) async {
    final unreadIds =
        messages.where((m) => m.isUnread).map((m) => m.id).toList();
    if (unreadIds.isEmpty) return;

    try {
      await _service.markMessagesRead(widget.connectionId, unreadIds);
      if (mounted) {
        setState(() {
          final updatedMessages = _messages.map((m) {
            if (m.isUnread) {
              return m.copyWith(status: 'read', readAt: DateTime.now());
            }
            return m;
          }).toList();
          _messages
            ..clear()
            ..addAll(updatedMessages);
          _firstUnreadIndex = null;
        });
      }
    } catch (e) {
      debugPrint('[OpenClawChat] mark read error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  Future<void> _refreshMessages() async {
    try {
      final messages = await _service.getMessages(widget.connectionId);
      if (mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(messages);
          _firstUnreadIndex = _findFirstUnreadIndex(messages);
        });
      }
      _scrollToFirstUnreadOrBottom();
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
    final connectionStatus = _connection?.status ?? 'disconnected';
    final isOnline = _isConnected;
    final status = isOnline ? 'connected' : 'disconnected';

    return GradientScaffold(
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
                          color: isOnline
                              ? AppTheme.successColor
                              : Theme.of(context).echoTextTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        isOnline ? '在线' : (connectionStatus == 'pending' ? '等待连接' : '离线'),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Theme.of(context).echoTextSecondary,
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
                          final prevMessage = index > 0 ? _messages[index - 1] : null;
                          final showTimestamp = prevMessage == null ||
                              message.isUser != prevMessage.isUser ||
                              !TimeFormatter.isSameDay(message.createdAt, prevMessage.createdAt) ||
                              !TimeFormatter.shouldGroup(message.createdAt, prevMessage.createdAt);
                          return _ChatBubble(
                            key: index == _firstUnreadIndex
                                ? _firstUnreadKey
                                : null,
                            message: message,
                            showUnreadDivider: index == _firstUnreadIndex,
                            showTimestamp: showTimestamp,
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
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
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
                        fillColor: Theme.of(context).colorScheme.surfaceContainer,
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
                    onPressed: _isConnected
                        ? () {
                            EchoHaptics.light();
                            _sendMessage();
                          }
                        : null,
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
  final bool showUnreadDivider;
  final bool showTimestamp;

  const _ChatBubble({
    super.key,
    required this.message,
    this.showUnreadDivider = false,
    this.showTimestamp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showUnreadDivider)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Expanded(
                    child: Divider(
                        height: 1.h, color: AppTheme.textTertiaryColor)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text(
                    '以下为新消息',
                    style: TextStyle(
                        fontSize: 12.sp, color: AppTheme.textTertiaryColor),
                  ),
                ),
                Expanded(
                    child: Divider(
                        height: 1.h, color: AppTheme.textTertiaryColor)),
              ],
            ),
          ),
        Align(
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
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
                  child: Column(
                    crossAxisAlignment: message.isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: message.isUser
                              ? AppTheme.primaryColor
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            if (!message.isUser)
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
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
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (showTimestamp)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 4.h,
                            left: message.isUser ? 0 : 4.w,
                            right: message.isUser ? 4.w : 0,
                          ),
                          child: Text(
                            TimeFormatter.formatChatTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.textTertiaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
