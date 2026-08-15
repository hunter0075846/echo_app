import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/group_provider.dart';
import '../theme/app_theme.dart';

/// 转发话题到群：群选择器 + 可编辑引导语
class ForwardTopicDialog extends ConsumerStatefulWidget {
  final String topicId;

  const ForwardTopicDialog({super.key, required this.topicId});

  @override
  ConsumerState<ForwardTopicDialog> createState() => _ForwardTopicDialogState();
}

class _ForwardTopicDialogState extends ConsumerState<ForwardTopicDialog> {
  final _guideController = TextEditingController(text: '大家来聊聊这个话题吧！');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _guideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('转发到群聊'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _guideController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: '引导语（可选）',
                hintText: '说点什么邀请大家讨论',
              ),
            ),
          ),
          Expanded(
            child: groupState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupState.error != null
                    ? Center(child: Text('加载失败: ${groupState.error}'))
                    : groupState.groups.isEmpty
                        ? const Center(child: Text('你还没有加入任何群'))
                        : ListView.builder(
                            itemCount: groupState.groups.length,
                            itemBuilder: (context, index) {
                              final group = groupState.groups[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor,
                                  child: Text(
                                    group.name.isNotEmpty ? group.name[0] : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(group.name),
                                subtitle: Text('${group.currentMembers}人'),
                                onTap: _isSubmitting
                                    ? null
                                    : () => _forward(group.id),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _forward(String groupId) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final guide = _guideController.text.trim();
      await ref.read(groupServiceProvider).forwardTopic(
            groupId: groupId,
            topicId: widget.topicId,
            guideText: guide.isEmpty ? null : guide,
          );

      if (mounted) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('已转发到群')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('转发失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
