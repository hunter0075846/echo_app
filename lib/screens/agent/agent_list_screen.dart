import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/agent_model.dart';
import '../../services/agent_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/echo_empty_state.dart';
import '../../widgets/echo_error_state.dart';
import '../../widgets/echo_loading_state.dart';
import '../../widgets/gradient_scaffold.dart';

final agentServiceProvider = Provider<AgentService>((ref) {
  return AgentService(ApiService());
});

final agentsProvider = FutureProvider.autoDispose<List<AgentModel>>((ref) async {
  final service = ref.watch(agentServiceProvider);
  return service.getAgents();
});

class AgentListScreen extends ConsumerWidget {
  const AgentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsProvider);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('我的AI助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/agents/create'),
          ),
        ],
      ),
      body: agentsAsync.when(
        data: (agents) {
          if (agents.isEmpty) {
            return _EmptyState(
              onCreate: () => context.push('/agents/create'),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              return _AgentCard(
                agent: agent,
                onTap: () => context.push('/agents/${agent.id}/chat'),
                onEdit: () => context.push('/agents/${agent.id}/edit'),
                onDelete: () => _confirmDelete(context, ref, agent),
              );
            },
          );
        },
        loading: () => const EchoLoadingState.list(),
        error: (err, _) => EchoErrorState(
          message: '加载失败: $err',
          onRetry: () => ref.invalidate(agentsProvider),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AgentModel agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${agent.name}" 吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(agentServiceProvider);
                await service.deleteAgent(agent.id);
                ref.invalidate(agentsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return EchoEmptyState(
      icon: Icons.smart_toy_outlined,
      title: '还没有AI助手',
      subtitle: '添加你自己的AI助手，支持任何OpenAI API兼容的服务',
      actionLabel: '添加AI助手',
      onAction: onCreate,
    );
  }
}

class _AgentCard extends StatelessWidget {
  final AgentModel agent;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AgentCard({
    required this.agent,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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
              // 头像
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: agent.avatar != null && agent.avatar!.isNotEmpty
                      ? Text(
                          agent.avatar!,
                          style: TextStyle(fontSize: 24.sp),
                        )
                      : Icon(
                          Icons.smart_toy,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                ),
              ),
              SizedBox(width: 12.w),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      agent.description ?? agent.model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        agent.model,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textTertiaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 操作
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: AppTheme.errorColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
