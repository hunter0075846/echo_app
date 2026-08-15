import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/echo_empty_state.dart';
import '../../widgets/echo_error_state.dart';
import '../../widgets/echo_loading_state.dart';
import '../../widgets/gradient_scaffold.dart';

final _memoriesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, groupId) {
  return ref.watch(groupServiceProvider).getMemories(groupId);
});

class MemoryTimelineScreen extends ConsumerWidget {
  final String groupId;

  const MemoryTimelineScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(_memoriesProvider(groupId));

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('群回忆'),
      ),
      body: memoriesAsync.when(
        data: (memories) {
          if (memories.isEmpty) {
            return const EchoEmptyState(
              icon: Icons.auto_stories_outlined,
              title: '还没有回忆',
              subtitle: '和朋友聊聊话题，你们的精彩讨论会出现在这里~',
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: memories.length,
            itemBuilder: (context, index) {
              return _MemoryCard(
                memory: memories[index],
                onLongPress: () => _showDeleteSheet(context, ref, memories[index]),
              );
            },
          );
        },
        loading: () => const EchoLoadingState.list(),
        error: (err, _) => EchoErrorState(
          message: '加载失败: $err',
          onRetry: () => ref.invalidate(_memoriesProvider(groupId)),
        ),
      ),
    );
  }

  void _showDeleteSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> memory,
  ) {
    final currentUserId = ref.read(authStateProvider).value?.id;
    final isMine = memory['relatedUserId'] == currentUserId;

    // 是否群主需异步确认；先只给"涉及我的"入口，群主入口由删除接口兜底鉴权
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.errorColor),
                title: const Text('删除涉及我的回忆'),
                onTap: () {
                  Navigator.pop(context);
                  _delete(context, ref, memory['id'] as String);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined,
                  color: AppTheme.errorColor),
              title: const Text('删除该回忆（群主）'),
              onTap: () {
                Navigator.pop(context);
                _delete(context, ref, memory['id'] as String);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String memoryId,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(groupServiceProvider).deleteMemory(groupId, memoryId);
      ref.invalidate(_memoriesProvider(groupId));
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }
}

class _MemoryCard extends StatelessWidget {
  final Map<String, dynamic> memory;
  final VoidCallback onLongPress;

  const _MemoryCard({required this.memory, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        margin: EdgeInsets.only(bottom: 12.h),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(),
                  SizedBox(width: 8.w),
                  Text(
                    memory['title'] as String? ?? _defaultTitle(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(memory['createdAt'] as String?),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textTertiaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                memory['content'] as String? ?? '',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _defaultTitle() {
    switch (memory['type']) {
      case 'topic_forward':
        return '话题转发';
      case 'vote_result':
        return '投票结果';
      case 'anonymous_comment':
        return '有人说';
      case 'chat_highlight':
        return '精彩发言';
      case 'manual':
        return '手动标记';
      default:
        return '回忆';
    }
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (memory['type']) {
      case 'topic_forward':
        icon = Icons.share;
        color = AppTheme.primaryColor;
        break;
      case 'vote_result':
        icon = Icons.poll;
        color = AppTheme.successColor;
        break;
      case 'anonymous_comment':
        icon = Icons.theater_comedy;
        color = AppTheme.anonymousColor;
        break;
      case 'chat_highlight':
        icon = Icons.chat_bubble;
        color = AppTheme.infoColor;
        break;
      default:
        icon = Icons.star;
        color = AppTheme.warningColor;
    }

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(icon, size: 16.w, color: color),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}月${date.day}日';
  }
}
