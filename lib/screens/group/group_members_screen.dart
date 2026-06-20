import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/avatars/user_avatar.dart';
import '../../widgets/echo_error_state.dart';
import '../../widgets/echo_loading_state.dart';
import '../../widgets/gradient_scaffold.dart';

class GroupMembersScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends ConsumerState<GroupMembersScreen> {
  @override
  void initState() {
    super.initState();
    _loadMembersIfNeeded();
  }

  Future<void> _loadMembersIfNeeded() async {
    final state = ref.read(groupDetailProvider(widget.groupId));
    if (state.members.isEmpty && state.error == null) {
      await ref.read(groupDetailProvider(widget.groupId).notifier).loadMembers();
    }
  }

  Future<void> _refresh() async {
    await ref.read(groupDetailProvider(widget.groupId).notifier).loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupDetailProvider(widget.groupId));
    final currentUser = ref.watch(authStateProvider).value;
    final members = _sortedMembers(groupState.members);

    return GradientScaffold(
      appBar: AppBar(
        title: Text('群成员 (${members.length})'),
      ),
      body: _buildBody(context, groupState, members, currentUser?.id),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GroupDetailState state,
    List<GroupMemberModel> members,
    String? currentUserId,
  ) {
    if (state.isLoading && members.isEmpty) {
      return const EchoLoadingState.list();
    }

    if (state.error != null && members.isEmpty) {
      return EchoErrorState(
        message: '加载失败：${state.error}',
        onRetry: _refresh,
      );
    }

    if (members.isEmpty) {
      return const EchoErrorState(
        message: '暂无成员',
        icon: Icons.people_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: EdgeInsets.all(EchoSpacing.md),
        itemCount: members.length,
        separatorBuilder: (_, __) => SizedBox(height: EchoSpacing.sm),
        itemBuilder: (context, index) {
          final member = members[index];
          return _MemberTile(
            member: member,
            isMe: member.user.id == currentUserId,
          );
        },
      ),
    );
  }

  List<GroupMemberModel> _sortedMembers(List<GroupMemberModel> members) {
    return members.toList()
      ..sort((a, b) {
        final roleCompare = _rolePriority(a.role).compareTo(_rolePriority(b.role));
        if (roleCompare != 0) return roleCompare;
        final aJoined = a.joinedAt ?? DateTime.now();
        final bJoined = b.joinedAt ?? DateTime.now();
        return aJoined.compareTo(bJoined);
      });
  }

  int _rolePriority(String role) {
    return switch (role) {
      'owner' => 0,
      'admin' => 1,
      _ => 2,
    };
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMemberModel member;
  final bool isMe;

  const _MemberTile({
    required this.member,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: EchoSpacing.md,
          vertical: EchoSpacing.sm,
        ),
        child: Row(
          children: [
            UserAvatar(
              id: member.user.id,
              name: member.user.nickname,
              imageUrl: member.user.avatar,
              size: 48,
            ),
            SizedBox(width: EchoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (member.joinedAt != null)
                    Text(
                      '加入于 ${_formatDate(member.joinedAt!)}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textTertiaryColor,
                      ),
                    ),
                ],
              ),
            ),
            _RoleChip(role: member.role),
          ],
        ),
      ),
    );
  }

  String get _displayName {
    final nickname = member.user.nickname;
    if (nickname != null && nickname.isNotEmpty) {
      return isMe ? '$nickname（我）' : nickname;
    }
    return isMe ? '我' : '未知用户';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: config.gradient,
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: config.foregroundColor,
        ),
      ),
    );
  }

  _RoleChipConfig _configFor(BuildContext context) {
    return switch (role) {
      'owner' => const _RoleChipConfig(
          label: '群主',
          gradient: AppTheme.primaryGradient,
          foregroundColor: Colors.white,
        ),
      'admin' => _RoleChipConfig(
          label: '管理员',
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          foregroundColor: AppTheme.primaryColor,
        ),
      _ => _RoleChipConfig(
          label: '成员',
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: AppTheme.textSecondaryColor,
        ),
    };
  }
}

class _RoleChipConfig {
  final String label;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color foregroundColor;

  const _RoleChipConfig({
    required this.label,
    this.gradient,
    this.backgroundColor,
    required this.foregroundColor,
  });
}
