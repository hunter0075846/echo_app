import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/topic_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/topic_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';

class TopicDetailScreen extends ConsumerWidget {
  final String topicId;

  const TopicDetailScreen({
    super.key,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicState = ref.watch(topicDetailProvider(topicId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('话题详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              _showShareSheet(context, topicId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreMenu(context, ref, topicState);
            },
          ),
        ],
      ),
      body: topicState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : topicState.error != null
              ? _buildErrorWidget(context, ref, topicState.error!)
              : topicState.topic == null
                  ? const Center(child: Text('话题不存在'))
                  : _buildContent(context, ref, topicState),
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, String error) {
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
          Text(
            error,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textTertiaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              ref.read(topicDetailProvider(topicId).notifier).loadTopic();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, TopicDetailState state) {
    final topic = state.topic!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 话题信息
                Text(
                  topic.title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 16.h),
                // 配图
                if (topic.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(
                      topic.imageUrl!,
                      height: 200.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200.h,
                          width: double.infinity,
                          color: AppTheme.dividerColor,
                          child: Icon(
                            Icons.image,
                            size: 64.w,
                            color: AppTheme.textTertiaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 16.h),
                // AI生成的描述
                if (topic.description != null && topic.description!.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLightColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 20.w,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'AI生成的描述：${topic.description}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 24.h),
                // 评论区
                Row(
                  children: [
                    Text(
                      '评论 (${topic.commentCount})',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        _showCommentInput(context, ref);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('写评论'),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // 评论列表
                if (state.isLoadingComments)
                  const Center(child: CircularProgressIndicator())
                else if (state.comments.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48.w,
                            color: AppTheme.textTertiaryColor,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            '暂无评论，来抢沙发吧',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.comments.length,
                    itemBuilder: (context, index) {
                      return _CommentItem(
                        comment: state.comments[index],
                        onReply: () {
                          _showCommentInput(
                            context,
                            ref,
                            parentId: state.comments[index].id,
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        // 底部操作栏
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showForwardDialog(context, topicId);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('转发到群聊'),
                ),
              ),
              SizedBox(width: 12.w),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: 复制链接
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('链接已复制')),
                  );
                },
                icon: const Icon(Icons.link),
                label: const Text('复制链接'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showShareSheet(BuildContext context, String topicId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '分享话题',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享到微信'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 微信分享
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('复制链接'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('链接已复制')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref, TopicDetailState state) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('举报'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 举报
              },
            ),
            if (state.topic?.author.id == ref.read(authStateProvider).value?.id)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                title: Text('删除', style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirm(context, ref);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后话题将无法恢复，确定要删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(topicDetailProvider(topicId).notifier).deleteTopic();
                if (context.mounted) {
                  Navigator.pop(context);
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
            child: Text('删除', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showCommentInput(BuildContext context, WidgetRef ref, {String? parentId}) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: parentId != null ? '回复评论...' : '写下你的评论...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () async {
                      final content = textController.text.trim();
                      if (content.isEmpty) return;

                      Navigator.pop(context);
                      try {
                        await ref.read(topicDetailProvider(topicId).notifier).addComment(
                          content,
                          parentId: parentId,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('评论失败: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('发送'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForwardDialog(BuildContext context, String topicId) {
    // TODO: 实现转发到群的对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('转发到群聊'),
        content: const Text('选择要转发到的群聊'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('转发成功')),
              );
            },
            child: const Text('转发'),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final TopicCommentModel comment;
  final VoidCallback onReply;

  const _CommentItem({
    required this.comment,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundImage: comment.author.avatar != null
                ? NetworkImage(comment.author.avatar!)
                : null,
            backgroundColor: AppTheme.primaryLightColor,
            child: comment.author.avatar == null
                ? Icon(
                    Icons.person,
                    size: 24.w,
                    color: AppTheme.primaryColor,
                  )
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.author.nickname ?? '用户${comment.author.phone.substring(comment.author.phone.length - 4)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textTertiaryColor,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    InkWell(
                      onTap: onReply,
                      child: Text(
                        '回复',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textTertiaryColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up_outlined,
                        size: 16.w,
                        color: AppTheme.textTertiaryColor,
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      comment.likeCount.toString(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textTertiaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}-${time.day}';
  }
}
