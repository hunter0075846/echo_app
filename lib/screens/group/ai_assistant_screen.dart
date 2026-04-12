import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/ai_assistant_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// AI助手小安服务Provider
final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  final api = ApiService();
  return AiAssistantService(api);
});

/// AI助手小安对话页面
class AiAssistantScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const AiAssistantScreen({
    super.key,
    this.groupId,
  });

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 添加欢迎消息
    final welcomeContent = widget.groupId != null
        ? '你好！我是小安，你的群聊AI助手。\n\n我可以帮你：\n• 推荐热门话题\n• 分析群聊氛围\n• 生成回忆总结\n• 回答关于群聊的问题\n\n有什么我可以帮你的吗？'
        : '你好！我是小安，你的AI助手。\n\n我可以帮你：\n• 推荐热门话题\n• 分析群聊氛围\n• 生成回忆总结\n• 回答关于群聊的问题\n\n有什么我可以帮你的吗？';
    _messages.add(
      ChatMessage(
        content: welcomeContent,
        isUser: false,
        timestamp: DateTime.now(),
        isWelcome: true,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // 构建对话历史
      final history = _messages
          .where((m) => m.isUser || !m.isWelcome) // 排除欢迎消息
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      // 调用小安API
      final aiService = ref.read(aiAssistantServiceProvider);
      final reply = await aiService.chat(
        message: content,
        groupId: widget.groupId,
        history: history,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
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
          _messages.add(ChatMessage(
            content: '抱歉，我遇到了一些问题：$e\n\n请稍后再试~',
            isUser: false,
            timestamp: DateTime.now(),
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '安',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '小安',
                  style: TextStyle(fontSize: 16.sp),
                ),
                Text(
                  'AI助手',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '小安正在思考...',
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '给小安发消息...',
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
}

/// 聊天消息模型
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isWelcome;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isWelcome = false,
  });
}

/// 聊天气泡组件
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

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
          left: message.isUser ? 64.w : 0,
          right: message.isUser ? 0 : 64.w,
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
