import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/group_model.dart';
import '../../providers/group_provider.dart';
import '../../services/openclaw_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';

class GroupListTab extends ConsumerStatefulWidget {
  const GroupListTab({super.key});

  @override
  ConsumerState<GroupListTab> createState() => _GroupListTabState();
}

class _GroupListTabState extends ConsumerState<GroupListTab> {
  late final OpenClawService _openClawService;
  Map<String, dynamic> _openClawStatus = {};
  bool _openClawLoading = true;

  @override
  void initState() {
    super.initState();
    _openClawService = OpenClawService(ApiService());
    _loadOpenClawStatus();
  }

  Future<void> _loadOpenClawStatus() async {
    try {
      final status = await _openClawService.getStatus();
      if (mounted) {
        setState(() {
          _openClawStatus = status;
          _openClawLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _openClawLoading = false);
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(groupListProvider.notifier).loadGroups(),
      _loadOpenClawStatus(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的群聊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateGroupDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _showJoinGroupDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: _buildBody(context, ref, groupState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, GroupListState state) {
    if (state.isLoading && state.groups.isEmpty && _openClawLoading) {
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
              onPressed: _refreshAll,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // ========== AI助手区域 ==========
        _buildSectionHeader(
          context,
          title: 'AI助手',
          action: const SizedBox.shrink(),
        ),
        SizedBox(height: 12.h),

        // 小安卡片
        _buildXiaoAnCard(context),
        SizedBox(height: 10.h),

        // 我的OpenClaw
        if (_openClawLoading)
          const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
        else
          _buildOpenClawCard(context),

        SizedBox(height: 16.h),
        const Divider(),
        SizedBox(height: 16.h),

        // ========== 群聊区域 ==========
        _buildSectionHeader(
          context,
          title: '群聊',
          action: TextButton.icon(
            onPressed: () => _showCreateGroupDialog(context, ref),
            icon: Icon(Icons.add, size: 16.sp),
            label: Text('创建', style: TextStyle(fontSize: 13.sp)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        if (state.groups.isEmpty)
          _buildEmptyGroupState(context, ref)
        else
          ...state.groups.map((group) => GroupCard(
                group: group,
                onTap: () => context.push('/group/${group.id}'),
              )),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required Widget action,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        action,
      ],
    );
  }

  // 小安卡片
  Widget _buildXiaoAnCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/ai-assistant'),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryLightColor,
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
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '小安',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '官方',
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
                      '推荐话题、分析群聊氛围、生成回忆总结',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppTheme.textTertiaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 我的OpenClaw卡片
  Widget _buildOpenClawCard(BuildContext context) {
    final connected = _openClawStatus['connected'] == true;
    final status = _openClawStatus['status'] as String? ?? 'none';

    if (status == 'none') {
      return _buildOpenClawConnectPrompt(context);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: connected ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (connected) {
              context.push('/openclaw/chat');
            } else {
              _showOpenClawSetup(context);
            }
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      '🦞',
                      style: TextStyle(fontSize: 22.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '我的OpenClaw',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: connected
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              connected ? '在线' : '等待连接',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: connected ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        connected
                            ? '点击开始对话'
                            : '在OpenClaw设备上执行安装脚本以完成关联',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppTheme.textTertiaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 未关联时的引导
  Widget _buildOpenClawConnectPrompt(BuildContext context) {
    return InkWell(
      onTap: () => _showOpenClawSetup(context),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.borderColor, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(
              Icons.link,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                '关联我的OpenClaw',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            Text(
              '去关联',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.primaryColor,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showOpenClawSetup(BuildContext context) {
    context.push('/openclaw/setup').then((_) => _loadOpenClawStatus());
  }

  // 空群聊状态
  Widget _buildEmptyGroupState(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48.w,
              color: AppTheme.textTertiaryColor,
            ),
            SizedBox(height: 12.h),
            Text(
              '还没有群聊',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              '创建群聊或扫码加入',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textTertiaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('创建群聊'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              ),
            ),
          ],
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
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      group.name.isNotEmpty ? group.name[0] : '群',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 15.sp,
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
                              fontSize: 13.sp,
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
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppTheme.textTertiaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
