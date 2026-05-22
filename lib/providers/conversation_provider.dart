import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../services/message_service.dart';
import 'auth_provider.dart';

class ConversationState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;

  const ConversationState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService();
});

final conversationProvider = StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  final messageService = ref.watch(messageServiceProvider);
  final authState = ref.watch(authStateProvider);
  return ConversationNotifier(messageService, authState);
});

class ConversationNotifier extends StateNotifier<ConversationState> {
  final MessageService _messageService;
  final AsyncValue<UserModel?> _authState;

  ConversationNotifier(this._messageService, this._authState) : super(const ConversationState()) {
    _authState.whenOrNull(
      data: (user) {
        if (user != null) {
          loadConversations();
        }
      },
    );
  }

  Future<void> loadConversations() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final conversations = await _messageService.getConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
