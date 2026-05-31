import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../providers/assistant_chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../utils/animation_utils.dart';
import '../../widgets/avatars/ai_avatar.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/echo_error_state.dart';
import '../../widgets/forward_to_group_dialog.dart';
import '../../widgets/gradient_scaffold.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const AiAssistantScreen({super.key, this.groupId});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assistantChatNotifierProvider(widget.groupId).notifier).loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels == 0) {
      ref.read(assistantChatNotifierProvider(widget.groupId).notifier).loadMore();
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    await ref.read(assistantChatNotifierProvider(widget.groupId).notifier).send(content);
    _scrollToBottom();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(maxExtent);
      }
    });
  }

  void _showForwardDialog(String content, String? sourceMessageId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ForwardToGroupDialog(
        content: content,
        sourceMessageId: sourceMessageId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 监听消息变化，自动滚动到底部
    ref.listen(assistantChatNotifierProvider(widget.groupId), (previous, next) {
      if (previous == null) return;

      // 加载完成（首次进入或加载更多结束）→ 直接跳到底部
      if (previous.isLoadingMore && !next.isLoadingMore) {
        _scrollToBottom(animate: false);
        return;
      }

      if (next.isLoadingMore) return; // 加载历史中不自动滚动

      final shouldScroll = previous.messages.length != next.messages.length ||
          (next.isStreaming &&
              next.messages.isNotEmpty &&
              previous.messages.isNotEmpty &&
              previous.messages.last.content != next.messages.last.content);

      if (shouldScroll) {
        _scrollToBottom(animate: true);
      }
    });

    final chatState = ref.watch(assistantChatNotifierProvider(widget.groupId));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            AIAvatar(size: 36.w),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('小E', style: theme.textTheme.titleLarge),
                Text(
                  'AI助手',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.echoTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (chatState.isLoadingMore)
            Padding(
              padding: EdgeInsets.only(right: EchoSpacing.md),
              child: SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 错误 Banner
          if (chatState.errorMessage != null)
            EchoErrorBanner(
              message: chatState.errorMessage!,
              onRetry: () => ref
                  .read(assistantChatNotifierProvider(widget.groupId).notifier)
                  .clearError(),
            ),

          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(EchoSpacing.md),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                final isLast = index == chatState.messages.length - 1;
                final isStreaming = isLast &&
                    message.role == 'assistant' &&
                    chatState.isStreaming;

                return EchoAnimations.chatMessage(
                  isUser: message.isUser,
                  child: ChatBubble(
                    message: message,
                    isStreaming: isStreaming,
                    onRetry: message.status == MessageStatus.failed
                        ? () => ref
                            .read(assistantChatNotifierProvider(widget.groupId).notifier)
                            .retry(message.id)
                        : null,
                    onForward: message.role == 'assistant' && !message.isWelcome
                        ? () => _showForwardDialog(message.content, message.id)
                        : null,
                  ),
                );
              },
            ),
          ),

          // 输入区
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
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
                      enabled: !chatState.isStreaming,
                      decoration: InputDecoration(
                        hintText: chatState.isStreaming ? '小E正在回复...' : '给小E发消息...',
                        filled: true,
                        fillColor: colorScheme.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(EchoRadius.full),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: EchoSpacing.md,
                          vertical: 10.h,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: chatState.isStreaming
                          ? theme.echoTextTertiary
                          : colorScheme.primary,
                    ),
                    onPressed: chatState.isStreaming
                        ? null
                        : () {
                            EchoHaptics.light();
                            _sendMessage();
                          },
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
