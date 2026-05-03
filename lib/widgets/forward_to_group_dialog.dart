import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/group_provider.dart';
import '../theme/app_theme.dart';

class ForwardToGroupDialog extends ConsumerStatefulWidget {
  final String content;
  final String? sourceMessageId;
  final String? prompt;

  const ForwardToGroupDialog({
    super.key,
    required this.content,
    this.sourceMessageId,
    this.prompt,
  });

  @override
  ConsumerState<ForwardToGroupDialog> createState() =>
      _ForwardToGroupDialogState();
}

class _ForwardToGroupDialogState
    extends ConsumerState<ForwardToGroupDialog> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('转发到群'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
      body: groupState.isLoading
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
                              group.name.isNotEmpty
                                  ? group.name[0]
                                  : '?',
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
    );
  }

  Future<void> _forward(String groupId) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(groupServiceProvider).forwardAssistantMessage(
            groupId: groupId,
            content: widget.content,
            sourceMessageId: widget.sourceMessageId,
            prompt: widget.prompt,
          );

      if (mounted) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('已转发')),
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
