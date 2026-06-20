import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/avatars/user_avatar.dart';
import '../../widgets/echo_dialog.dart';
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

  String? get _operatorRole {
    final currentUser = ref.read(authStateProvider).value;
    final state = ref.read(groupDetailProvider(widget.groupId));
    final membership = state.members.cast<GroupMemberModel?>().firstWhere(
          (m) => m?.user.id == currentUser?.id,
          orElse: () => null,
        );
    return membership?.role;
  }

  Future<void> _handleSetAdmin(String userId, String nickname) async {
    final confirmed = await EchoDialog.confirm(
      context: context,
      title: '设置管理员',
      content: '确定将 "$nickname" 设为管理员吗？',
      confirmLabel: '设为管理员',
    );
    if (!confirmed) return;

    try {
      await ref.read(groupDetailProvider(widget.groupId).notifier).setMemberRole(userId, 'admin');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已设为管理员')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败: $e')),
        );
      }
    }
  }

  Future<void> _handleRemoveAdmin(String userId, String nickname) async {
    final confirmed = await EchoDialog.confirm(
      context: context,
      title: '取消管理员',
      content: '确定取消 "$nickname" 的管理员身份吗？',
      confirmLabel: '取消管理员',
    );
    if (!confirmed) return;

    try {
      await ref.read(groupDetailProvider(widget.groupId).notifier).setMemberRole(userId, 'member');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消管理员')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('取消失败: $e')),
        );
      }
    }
  }

  Future<void> _handleRemove(String userId, String nickname) async {
    final confirmed = await EchoDialog.confirm(
      context: context,
      title: '移出群聊',
      content: '确定将 "$nickname" 移出群聊吗？',
      confirmLabel: '移出',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(groupDetailProvider(widget.groupId).notifier).removeMember(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已移出群聊')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移出失败: $e')),
        );
      }
    }
  }

  Future<void> _handleTransfer(String userId, String nickname) async {
    final confirmed = await EchoDialog.confirm(
      context: context,
      title: '转让群主',
      content: '确定将群主转让给 "$nickname" 吗？转让后你将成为管理员。',
      confirmLabel: '转让',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await ref.read(groupDetailProvider(widget.groupId).notifier).transferOwnership(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('群主转让成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('转让失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupDetailProvider(widget.groupId));
    final currentUser = ref.watch(authStateProvider).value;
    final members = _sortedMembers(groupState.members);
    final operatorRole = _operatorRole;

    return GradientScaffold(
      appBar: AppBar(
        title: Text('群成员 (${members.length})'),
      ),
      body: _buildBody(context, groupState, members, currentUser?.id, operatorRole),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GroupDetailState state,
    List<GroupMemberModel> members,
    String? currentUserId,
    String? operatorRole,
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
            operatorRole: operatorRole,
            onSetAdmin: () => _handleSetAdmin(member.user.id, member.user.nickname ?? '该用户'),
            onRemoveAdmin: () => _handleRemoveAdmin(member.user.id, member.user.nickname ?? '该用户'),
            onRemove: () => _handleRemove(member.user.id, member.user.nickname ?? '该用户'),
            onTransferOwner: () => _handleTransfer(member.user.id, member.user.nickname ?? '该用户'),
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
  final String? operatorRole;
  final VoidCallback? onSetAdmin;
  final VoidCallback? onRemoveAdmin;
  final VoidCallback? onRemove;
  final VoidCallback? onTransferOwner;

  const _MemberTile({
    required this.member,
    this.isMe = false,
    this.operatorRole,
    this.onSetAdmin,
    this.onRemoveAdmin,
    this.onRemove,
    this.onTransferOwner,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _buildActionItems();

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
            if (actions.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleAction(value),
                itemBuilder: (_) => actions,
              ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildActionItems() {
    final items = <PopupMenuEntry<String>>[];
    if (isMe || operatorRole == null) return items;

    final operatorIsOwner = operatorRole == 'owner';
    final operatorIsAdmin = operatorRole == 'admin';

    // 群主可设/取消管理员
    if (operatorIsOwner && member.role == 'member') {
      items.add(
        const PopupMenuItem(
          value: 'set_admin',
          child: Text('设为管理员'),
        ),
      );
    }
    if (operatorIsOwner && member.role == 'admin') {
      items.add(
        const PopupMenuItem(
          value: 'remove_admin',
          child: Text('取消管理员'),
        ),
      );
    }

    // 移除成员：群主可移除 admin/member；管理员可移除 member
    final canRemove = operatorIsOwner ||
        (operatorIsAdmin && member.role == 'member');
    if (canRemove && member.role != 'owner') {
      items.add(
        PopupMenuItem(
          value: 'remove',
          child: Text(
            '移出群聊',
            style: TextStyle(color: AppTheme.errorColor),
          ),
        ),
      );
    }

    // 转让群主：仅群主可操作，目标不能是自己
    if (operatorIsOwner && member.role != 'owner') {
      items.add(
        const PopupMenuItem(
          value: 'transfer',
          child: Text('转让群主'),
        ),
      );
    }

    return items;
  }

  void _handleAction(String value) {
    switch (value) {
      case 'set_admin':
        onSetAdmin?.call();
      case 'remove_admin':
        onRemoveAdmin?.call();
      case 'remove':
        onRemove?.call();
      case 'transfer':
        onTransferOwner?.call();
    }
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
