import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/agent_model.dart';
import '../../services/agent_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// 与第三方AI Agent 一对一对话页面
class AgentChatScreen extends ConsumerStatefulWidget {
  final String agentId;

  const AgentChatScreen({
    super.key,
    required this.agentId,
  });

  @override
  ConsumerState<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends ConsumerState<AgentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  AgentModel? _agent;
  bool _isInitLoading = true;

  late final AgentService _agentService;

  @override
  void initState() {
    super.initState();
    _agentService = AgentService(ApiService());
    _loadAgentAndHistory();
  }

  Future<void> _loadAgentAndHistory() async {
    try {
      final agent = await _agentService.getAgent(widget.agentId);
      final history = await _agentService.getChatHistory(widget.agentId);

      if (mounted) {
        setState(() {
          _agent = agent;
          _messages.addAll(
            history.map((m) => _ChatMessage(
                  content: m.content,
                  isUser: m.isUser,
                  timestamp: m.createdAt,
                )),
          );
          _isInitLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _agent == null) return;

    setState(() {
      _messages.add(_ChatMessage(
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // 构建对话历史（最近20条）
      final history = _messages
          .takeLast(20)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final reply = await _agentService.chat(
        agentId: widget.agentId,
        message: content,
        history: history,
      );

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            content: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            content: '对话失败: $e\n\n请检查Agent配置（API地址、Key、模型名）是否正确。',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_agent == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI助手')),
        body: const Center(child: Text('Agent不存在')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: _agent!.avatar != null && _agent!.avatar!.isNotEmpty
                    ? Text(
                        _agent!.avatar!,
                        style: TextStyle(fontSize: 18.sp),
                      )
                    : Icon(
                        Icons.smart_toy,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _agent!.name,
                    style: TextStyle(fontSize: 16.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _agent!.model,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/agents/${widget.agentId}/edit'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _messages.isEmpty
                ? _EmptyChatState(agent: _agent!)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _ChatBubble(
                        message: message,
                        agentName: _agent!.name,
                        agentAvatar: _agent!.avatar,
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
                    '${_agent!.name} 正在思考...',
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
                      decoration: InputDecoration(
                        hintText: '给 ${_agent!.name} 发消息...',
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
                    onPressed: _isLoading ? null : _sendMessage,
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

class _EmptyChatState extends StatelessWidget {
  final AgentModel agent;

  const _EmptyChatState({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: agent.avatar != null && agent.avatar!.isNotEmpty
                    ? Text(agent.avatar!, style: TextStyle(fontSize: 32.sp))
                    : Icon(
                        Icons.smart_toy,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              agent.name,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              agent.description ?? '开始和你的AI助手对话吧',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            if (agent.systemPrompt != null && agent.systemPrompt!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '角色设定: ${agent.systemPrompt}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textTertiaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  _ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final String agentName;
  final String? agentAvatar;

  const _ChatBubble({
    required this.message,
    required this.agentName,
    this.agentAvatar,
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
            // AI头像
            if (!message.isUser) ...[
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: message.isError
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: agentAvatar != null && agentAvatar!.isNotEmpty
                      ? Text(
                          agentAvatar!,
                          style: TextStyle(fontSize: 16.sp),
                        )
                      : Icon(
                          Icons.smart_toy,
                          color: message.isError
                              ? AppTheme.errorColor
                              : AppTheme.primaryColor,
                          size: 18,
                        ),
                ),
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
                      : message.isError
                          ? AppTheme.errorColor.withOpacity(0.05)
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
                        : message.isError
                            ? AppTheme.errorColor
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

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return List.from(this);
    return sublist(length - n);
  }
}
