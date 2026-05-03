import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_assistant_service.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';

/// 消息状态
enum MessageStatus { sent, sending, failed }

/// 客户端消息模型（含 UI 状态）
class ChatMessage {
  final String id;
  final String role; // user | assistant
  final String content;
  final String? groupId;
  final DateTime? createdAt;
  final MessageStatus status;
  final bool isWelcome;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.groupId,
    this.createdAt,
    this.status = MessageStatus.sent,
    this.isWelcome = false,
  });

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    String? groupId,
    DateTime? createdAt,
    MessageStatus? status,
    bool? isWelcome,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isWelcome: isWelcome ?? this.isWelcome,
    );
  }

  /// 是否为用户消息
  bool get isUser => role == 'user';
}

/// 错误文案映射
String _errorMessage(ApiException? e) {
  if (e == null) return '';
  if (e.statusCode == 429) return '请求太频繁，请稍后再试';
  if (e.statusCode == 502) return 'AI 服务暂时不可用，请稍后重试';
  if (e.statusCode == 504) return '网络较慢，请稍后重试';
  if (e.isNetworkError) return '网络错误，请检查网络连接';
  if (e.statusCode != null && e.statusCode! >= 500) return '服务器错误，请稍后重试';
  return e.message;
}

/// Provider 层状态
class AssistantChatState {
  final List<ChatMessage> messages;
  final bool isLoadingMore;
  final bool isStreaming;
  final ApiException? error;
  final String? nextCursor;
  final bool hasMore;

  const AssistantChatState({
    this.messages = const [],
    this.isLoadingMore = false,
    this.isStreaming = false,
    this.error,
    this.nextCursor,
    this.hasMore = false,
  });

  AssistantChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoadingMore,
    bool? isStreaming,
    ApiException? error,
    String? nextCursor,
    bool? hasMore,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// 供 UI 直接展示的错误文案
  String? get errorMessage => error != null ? _errorMessage(error) : null;
}

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  return AiAssistantService(ApiService());
});

final assistantChatNotifierProvider =
    StateNotifierProvider.family<AssistantChatNotifier, AssistantChatState, String?>(
  (ref, groupId) {
    final service = ref.watch(aiAssistantServiceProvider);
    return AssistantChatNotifier(service, groupId);
  },
);

class AssistantChatNotifier extends StateNotifier<AssistantChatState> {
  final AiAssistantService _service;
  final String? _groupId;

  AssistantChatNotifier(this._service, this._groupId)
      : super(const AssistantChatState());

  /// 首次加载历史 + 插入 welcome（本地 UI 层，不落库）
  Future<void> loadInitial() async {
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final page = await _service.getHistory(limit: 50);
      final messages = page.messages.map((m) => ChatMessage(
            id: m.id,
            role: m.role,
            content: m.content,
            groupId: m.groupId,
            createdAt: m.createdAt,
          )).toList();

      // 如果没有任何历史，插入本地 welcome
      if (messages.isEmpty) {
        messages.add(_welcomeMessage());
      }

      state = state.copyWith(
        messages: messages,
        isLoadingMore: false,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      );
    } catch (e) {
      final err = e is ApiException ? e : ApiException(message: e.toString());
      state = state.copyWith(
        isLoadingMore: false,
        error: err,
      );
    }
  }

  /// 下拉加载更早消息
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final page = await _service.getHistory(
        cursor: state.nextCursor,
        limit: 50,
      );
      final olderMessages = page.messages.map((m) => ChatMessage(
            id: m.id,
            role: m.role,
            content: m.content,
            groupId: m.groupId,
            createdAt: m.createdAt,
          )).toList();

      state = state.copyWith(
        messages: [...olderMessages, ...state.messages],
        isLoadingMore: false,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      );
    } catch (e) {
      final err = e is ApiException ? e : ApiException(message: e.toString());
      state = state.copyWith(
        isLoadingMore: false,
        error: err,
      );
    }
  }

  /// 发送消息（流式）
  Future<void> send(String content) async {
    if (state.isStreaming) return;

    // 过滤掉 welcome，保留真实历史
    final currentMessages = state.messages.where((m) => !m.isWelcome).toList();

    // 乐观插入用户消息
    final userMsg = ChatMessage(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content,
      groupId: _groupId,
      status: MessageStatus.sending,
    );

    // 插入占位 AI 消息
    final assistantMsg = ChatMessage(
      id: 'streaming_${DateTime.now().millisecondsSinceEpoch}',
      role: 'assistant',
      content: '',
      groupId: _groupId,
      status: MessageStatus.sending,
    );

    state = state.copyWith(
      messages: [...currentMessages, userMsg, assistantMsg],
      isStreaming: true,
      error: null,
    );

    final stream = _service.chatStream(
      message: content,
      groupId: _groupId,
    );

    String assistantContent = '';
    String? finalId;
    ApiException? streamError;

    await for (final event in stream) {
      if (event is Delta) {
        assistantContent += event.content;
        final messages = [...state.messages];
        final lastIndex = messages.length - 1;
        if (lastIndex >= 0 && messages[lastIndex].role == 'assistant') {
          messages[lastIndex] = messages[lastIndex].copyWith(
            content: assistantContent,
          );
          state = state.copyWith(messages: messages);
        }
      } else if (event is StreamDone) {
        finalId = event.messageId;
      } else if (event is StreamError) {
        streamError = event.error;
      }
    }

    if (streamError != null) {
      final messages = [...state.messages];
      final lastIndex = messages.length - 1;
      if (lastIndex >= 0 && messages[lastIndex].role == 'assistant') {
        messages[lastIndex] = messages[lastIndex].copyWith(
          status: MessageStatus.failed,
          content: assistantContent.isEmpty
              ? '发送失败，请重试'
              : assistantContent,
        );
      }
      if (messages.length >= 2 && messages[messages.length - 2].role == 'user') {
        final userIndex = messages.length - 2;
        messages[userIndex] = messages[userIndex].copyWith(
          status: MessageStatus.failed,
        );
      }
      state = state.copyWith(
        messages: messages,
        isStreaming: false,
        error: streamError,
      );
      return;
    }

    // 成功：替换 placeholder id
    final messages = [...state.messages];
    final lastIndex = messages.length - 1;
    if (lastIndex >= 0 && messages[lastIndex].role == 'assistant') {
      messages[lastIndex] = messages[lastIndex].copyWith(
        id: finalId ?? messages[lastIndex].id,
        status: MessageStatus.sent,
        content: assistantContent,
      );
    }
    if (messages.length >= 2 && messages[messages.length - 2].role == 'user') {
      final userIndex = messages.length - 2;
      messages[userIndex] = messages[userIndex].copyWith(
        status: MessageStatus.sent,
      );
    }
    state = state.copyWith(
      messages: messages,
      isStreaming: false,
      error: null,
    );
  }

  /// 重发失败的消息
  Future<void> retry(String messageId) async {
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;

    final msg = state.messages[index];
    if (msg.role != 'user' || msg.status != MessageStatus.failed) return;

    // 移除失败的 user + assistant 对
    final messages = [...state.messages];
    messages.removeAt(index + 1); // assistant
    messages.removeAt(index);     // user

    state = state.copyWith(messages: messages, error: null);

    // 重新发送
    await send(msg.content);
  }

  /// 清除错误 banner
  void clearError() {
    state = state.copyWith(error: null);
  }

  ChatMessage _welcomeMessage() {
    final content = _groupId != null
        ? '你好！我是小安，你的群聊AI助手。\n\n我可以帮你：\n• 推荐热门话题\n• 分析群聊氛围\n• 生成回忆总结\n• 回答关于群聊的问题\n\n有什么我可以帮你的吗？'
        : '你好！我是小安，你的AI助手。\n\n我可以帮你：\n• 推荐热门话题\n• 分析群聊氛围\n• 生成回忆总结\n• 回答关于群聊的问题\n\n有什么我可以帮你的吗？';

    return ChatMessage(
      id: 'welcome',
      role: 'assistant',
      content: content,
      groupId: _groupId,
      isWelcome: true,
    );
  }
}
