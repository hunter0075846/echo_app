import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/app_theme.dart';

class MemoryTimelineScreen extends ConsumerWidget {
  final String groupId;

  const MemoryTimelineScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: 实现回忆时间线数据获取
    final memories = _getMockMemories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('群回忆'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: memories.length,
        itemBuilder: (context, index) {
          final memory = memories[index];
          return _MemoryCard(memory: memory);
        },
      ),
    );
  }

  List<_MemoryItem> _getMockMemories() {
    return [
      _MemoryItem(
        type: 'topic_forward',
        title: '话题转发',
        content: '小明转发了话题"AI技术正在改变我们的生活方式"',
        date: DateTime.now().subtract(const Duration(days: 1)),
        userName: '小明',
      ),
      _MemoryItem(
        type: 'vote_result',
        title: '投票结果',
        content: '"周末去哪玩"投票结束，第一名：爬山（5票）',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      _MemoryItem(
        type: 'anonymous_comment',
        title: '有人说',
        content: '有人说：这个话题挺有意思的',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      _MemoryItem(
        type: 'chat_highlight',
        title: '精彩对话',
        content: '小红：我觉得这个主意不错！\n小李：我也同意',
        date: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }
}

class _MemoryItem {
  final String type;
  final String title;
  final String content;
  final DateTime date;
  final String? userName;

  _MemoryItem({
    required this.type,
    required this.title,
    required this.content,
    required this.date,
    this.userName,
  });
}

class _MemoryCard extends StatelessWidget {
  final _MemoryItem memory;

  const _MemoryCard({required this.memory});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  memory.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(memory.date),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textTertiaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              memory.content,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            if (memory.userName != null) ...[
              SizedBox(height: 8.h),
              Text(
                'by ${memory.userName}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textTertiaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (memory.type) {
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(icon, size: 16.w, color: color),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}月${date.day}日';
  }
}
