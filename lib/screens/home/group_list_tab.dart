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
        child: _buildGroupList(context, ref, groupState),
      ),
    );
  }

  Widget _buildGroupList(BuildContext context, WidgetRef ref, GroupListState state) {
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

    // 空状态：只显示小安
    if (state.groups.isEmpty) {
      return ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // 小安卡片
          _buildXiaoAnCard(context),
          // 空状态提示
          SizedBox(height: 32.h),
          Center(
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
                    _showCreateGroupDialog(context, ref);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('创建群聊'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 有群聊时：显示小安 + 群聊列表
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: state.groups.length + 1, // +1 为小安
      itemBuilder: (context, index) {
        // 第一个位置显示小安
        if (index == 0) {
          return _buildXiaoAnCard(context);
        }
        final group = state.groups[index - 1];
        return GroupCard(
          group: group,
          onTap: () {
            context.push('/group/${group.id}');
          },
        );
      },
    );
  }

  // 构建小安卡片
  Widget _buildXiaoAnCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // 进入小安对话页面（不传groupId，表示全局对话）
          context.push('/ai-assistant');
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // 小安头像
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    '安',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // 小安信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '小安',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'AI助手',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '点击与我对话，我可以帮你推荐话题、分析群聊氛围',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
