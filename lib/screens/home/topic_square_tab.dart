import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../models/topic_model.dart';
import '../../providers/topic_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';

class TopicSquareTab extends ConsumerStatefulWidget {
  const TopicSquareTab({super.key});

  @override
  ConsumerState<TopicSquareTab> createState() => _TopicSquareTabState();
}

class _TopicSquareTabState extends ConsumerState<TopicSquareTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final sort = _tabController.index == 0 ? 'latest' : 'hottest';
      ref.read(topicListProvider.notifier).setSort(sort);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(topicListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicState = ref.watch(topicListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '话题广场',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '最新'),
            Tab(text: '最热'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索话题',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(topicListProvider.notifier).setSearchQuery('');
                          ref.read(topicListProvider.notifier).search();
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                ref.read(topicListProvider.notifier).setSearchQuery(value);
                ref.read(topicListProvider.notifier).search();
              },
            ),
          ),
          // 话题列表
          Expanded(
            child: _buildContent(topicState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/topic/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(TopicListState state) {
    // 显示错误
    if (state.error != null && state.topics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.w,
              color: AppTheme.errorColor,
            ),
            SizedBox(height: 16.h),
            Text(
              '加载失败: ${state.error}',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                ref.read(topicListProvider.notifier).loadTopics(refresh: true);
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 首次加载中
    if (state.isLoading && state.topics.isEmpty) {
      return LoadingShimmer();
    }

    // 空数据
    if (state.topics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48.w,
              color: AppTheme.textTertiaryColor,
            ),
            SizedBox(height: 16.h),
            Text(
              '暂无话题',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                context.push('/topic/create');
              },
              child: const Text('发布第一个话题'),
            ),
          ],
        ),
      );
    }

    // 显示列表
    return RefreshIndicator(
      onRefresh: () => ref.read(topicListProvider.notifier).loadTopics(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: state.topics.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.topics.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final topic = state.topics[index];
          return _TopicCard(topic: topic);
        },
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final TopicModel topic;

  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          context.push('/topic/${topic.id}');
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                topic.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (topic.description != null) ...[
                SizedBox(height: 8.h),
                Text(
                  topic.description!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 12.h),
              // 底部信息
              Row(
                children: [
                  // 作者头像
                  if (topic.author.avatar != null)
                    CircleAvatar(
                      radius: 12.w,
                      backgroundImage: NetworkImage(topic.author.avatar!),
                    )
                  else
                    CircleAvatar(
                      radius: 12.w,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        topic.author.nickname?.substring(0, 1) ?? 'U',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  SizedBox(width: 8.w),
                  // 作者名
                  Text(
                    topic.author.nickname ?? '匿名用户',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const Spacer(),
                  // 统计数据
                  _buildStatItem(Icons.visibility_outlined, topic.viewCount),
                  SizedBox(width: 16.w),
                  _buildStatItem(Icons.comment_outlined, topic.commentCount),
                  SizedBox(width: 16.w),
                  _buildStatItem(Icons.favorite_outline, topic.likeCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14.w,
          color: AppTheme.textTertiaryColor,
        ),
        SizedBox(width: 4.w),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12.sp,
            color: AppTheme.textTertiaryColor,
          ),
        ),
      ],
    );
  }
}
