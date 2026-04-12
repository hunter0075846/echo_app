import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/group_service.dart';
import 'auth_provider.dart';

class GroupListState {
  final List<GroupModel> groups;
  final bool isLoading;
  final String? error;

  const GroupListState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  GroupListState copyWith({
    List<GroupModel>? groups,
    bool? isLoading,
    String? error,
  }) {
    return GroupListState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class GroupDetailState {
  final GroupModel? group;
  final List<GroupMemberModel> members;
  final List<GroupMessageModel> messages;
  final bool isLoading;
  final bool isLoadingMessages;
  final String? error;
  final String? inviteCode;

  const GroupDetailState({
    this.group,
    this.members = const [],
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMessages = false,
    this.error,
    this.inviteCode,
  });

  GroupDetailState copyWith({
    GroupModel? group,
    List<GroupMemberModel>? members,
    List<GroupMessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMessages,
    String? error,
    String? inviteCode,
  }) {
    return GroupDetailState(
      group: group ?? this.group,
      members: members ?? this.members,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      error: error ?? this.error,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService();
});

final groupListProvider = StateNotifierProvider<GroupListNotifier, GroupListState>((ref) {
  final groupService = ref.watch(groupServiceProvider);
  final authState = ref.watch(authStateProvider);
  return GroupListNotifier(groupService, authState);
});

final groupDetailProvider = StateNotifierProvider.family<GroupDetailNotifier, GroupDetailState, String>((ref, groupId) {
  final groupService = ref.watch(groupServiceProvider);
  return GroupDetailNotifier(groupService, groupId);
});

class GroupListNotifier extends StateNotifier<GroupListState> {
  final GroupService _groupService;
  final AsyncValue<UserModel?> _authState;

  GroupListNotifier(this._groupService, this._authState) : super(const GroupListState()) {
    // 只在登录状态下加载群聊
    _authState.whenOrNull(
      data: (user) {
        if (user != null) {
          loadGroups();
        }
      },
    );
  }

  Future<void> loadGroups() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final groups = await _groupService.getMyGroups();
      state = state.copyWith(
        groups: groups,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final group = await _groupService.createGroup(
        name: name,
        description: description,
      );
      state = state.copyWith(
        groups: [group, ...state.groups],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> joinGroupByCode(String code) async {
    try {
      final group = await _groupService.joinGroupByCode(code);
      state = state.copyWith(
        groups: [group, ...state.groups],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> removeGroup(String groupId) async {
    state = state.copyWith(
      groups: state.groups.where((g) => g.id != groupId).toList(),
    );
  }
}

class GroupDetailNotifier extends StateNotifier<GroupDetailState> {
  final GroupService _groupService;
  final String _groupId;

  GroupDetailNotifier(this._groupService, this._groupId) : super(const GroupDetailState()) {
    loadGroup();
  }

  Future<void> loadGroup() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final group = await _groupService.getGroupDetail(_groupId);
      state = state.copyWith(
        group: group,
        isLoading: false,
      );
      // 加载成员和消息
      loadMembers();
      loadMessages();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMembers() async {
    try {
      final members = await _groupService.getGroupMembers(_groupId);
      state = state.copyWith(members: members);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoadingMessages: true);

    try {
      final messages = await _groupService.getGroupMessages(_groupId);
      state = state.copyWith(
        messages: messages,
        isLoadingMessages: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMessages: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage({
    required String content,
    String? mediaUrl,
    bool isAnonymous = false,
  }) async {
    try {
      final message = await _groupService.sendMessage(
        groupId: _groupId,
        content: content,
        mediaUrl: mediaUrl,
        isAnonymous: isAnonymous,
      );
      state = state.copyWith(
        messages: [message, ...state.messages],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> generateInviteCode() async {
    try {
      final code = await _groupService.generateInviteCode(_groupId);
      state = state.copyWith(inviteCode: code);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> leaveGroup() async {
    try {
      await _groupService.leaveGroup(_groupId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteGroup() async {
    try {
      await _groupService.deleteGroup(_groupId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}
