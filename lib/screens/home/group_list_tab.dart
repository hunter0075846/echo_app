import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';

class GroupListTab extends ConsumerWidget {
  const GroupListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(groupListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的群聊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreateGroupDialog(context, ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              _showJoinGroupDialog(context, ref);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(groupListProvider.notifier).loadGroups(),
        child: _buildGroupList(groupState),
      ),
    );
  }

  Widget _buildGroupList(GroupListState state) {
    if (state.isLoading) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 5,
        itemBuilder: (context, index) => const GroupCardShimmer(),
      );
    }

    if (state.error != null && state.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.w,
              color: AppTheme.textTertiaryColor,
            ),
            SizedBox(height: 16.h),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () {},
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64.w,
              color: AppTheme.textTertiaryColor,
            ),
            SizedBox(height: 16.h),
            Text(
              '还没有群聊',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '创建群聊或扫码加入',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 创建群聊
              },
              icon: const Icon(Icons.add),
              label: const Text('创建群聊'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: state.groups.length,
      itemBuilder: (context, index) {
        final group = state.groups[index];
        return GroupCard(
          group: group,
          onTap: () {
            context.push('/group/${group.id}');
          },
        );
      },
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建群聊'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '群聊名称',
                hintText: '输入群聊名称',
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '群聊描述（可选）',
                hintText: '输入群聊描述',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入群聊名称')),
                );
                return;
              }

              Navigator.pop(context);
              try {
                await ref.read(groupListProvider.notifier).createGroup(
                  name: name,
                  description: descController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('群聊创建成功')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('创建失败: $e')),
                  );
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入群聊'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: '邀请码',
            hintText: '输入6位邀请码',
          ),
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入6位邀请码')),
                );
                return;
              }

              Navigator.pop(context);
              try {
                await ref.read(groupListProvider.notifier).joinGroupByCode(code);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('加入群聊成功')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('加入失败: $e')),
                  );
                }
              }
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // 群头像
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    group.name.isNotEmpty ? group.name[0] : '群',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // 群信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (group.description != null && group.description!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          group.description!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    SizedBox(height: 4.h),
                    Text(
                      '${group.currentMembers}/${group.maxMembers} 人',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textTertiaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // 箭头
              Icon(
                Icons.chevron_right,
                color: AppTheme.textTertiaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
