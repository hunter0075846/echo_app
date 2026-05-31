import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/topic_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/topic_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../utils/animation_utils.dart';
import '../../widgets/avatars/user_avatar.dart';
import '../../widgets/echo_card.dart';
import '../../widgets/echo_empty_state.dart';
import '../../widgets/echo_error_state.dart';
import '../../widgets/echo_loading_state.dart';
import '../../widgets/gradient_scaffold.dart';

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
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 顶部问候区域
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.echoTextTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _greeting(),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.echoTextPrimary,
                          ),
                        ),
                        if (user?.nickname != null) ...[
                          TextSpan(
                            text: '\n${user!.nickname}',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 搜索栏
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(EchoRadius.lg),
                  boxShadow: [EchoShadows.cardFloat],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索话题',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.echoTextTertiary,
                    ),
                    prefixIcon: Icon(Icons.search, color: theme.echoTextTertiary),
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
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  ),
                  onSubmitted: (value) {
                    ref.read(topicListProvider.notifier).setSearchQuery(value);
                    ref.read(topicListProvider.notifier).search();
                  },
                ),
              ),
            ),
          ),
          // TabBar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '最新'),
                  Tab(text: '最热'),
                ],
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: theme.textTheme.labelLarge,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
              ),
            ),
          ),
          // 内容区域
          _buildContent(topicState),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          EchoHaptics.light();
          context.push('/topic/create');
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EchoRadius.lg),
        ),
        child: const Icon(Icons.add),
      ).animate(onPlay: (c) => c.stop()).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: EchoDurations.slow,
            curve: EchoCurves.spring,
          ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good night,';
  }

  Widget _buildContent(TopicListState state) {
    // 显示错误
    if (state.error != null && state.topics.isEmpty) {
      return SliverFillRemaining(
        child: EchoErrorState(
          message: '加载失败: ${state.error}',
          onRetry: () {
            ref.read(topicListProvider.notifier).loadTopics(refresh: true);
          },
        ),
      );
    }

    // 首次加载中
    if (state.isLoading && state.topics.isEmpty) {
      return const SliverFillRemaining(
        child: EchoLoadingState.list(),
      );
    }

    // 空数据
    if (state.topics.isEmpty) {
      return SliverFillRemaining(
        child: EchoEmptyState(
          icon: Icons.inbox_outlined,
          title: '暂无话题',
          subtitle: '成为第一个发起讨论的人吧',
          actionLabel: '发布话题',
          onAction: () => context.push('/topic/create'),
        ),
      );
    }

    // 显示列表
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      sliver: SliverList.builder(
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
          return EchoAnimations.staggeredItem(
            index: index,
            child: _TopicCard(topic: topic),
          );
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
    final theme = Theme.of(context);

    return EchoCard(
      margin: EdgeInsets.only(bottom: EchoSpacing.md),
      onTap: () {
        context.push('/topic/${topic.id}');
      },
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 17.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (topic.description != null) ...[
              SizedBox(height: EchoSpacing.sm),
              Text(
                topic.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.echoTextSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: EchoSpacing.md),
            Row(
              children: [
                UserAvatar(
                  id: topic.author.id,
                  name: topic.author.nickname,
                  imageUrl: topic.author.avatar,
                  size: 28,
                ),
                SizedBox(width: EchoSpacing.sm),
                Text(
                  topic.author.nickname ?? '匿名用户',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.echoTextSecondary,
                  ),
                ),
                const Spacer(),
                _buildStatItem(context, Icons.visibility_outlined, topic.viewCount),
                SizedBox(width: EchoSpacing.md),
                _buildStatItem(context, Icons.comment_outlined, topic.commentCount),
                SizedBox(width: EchoSpacing.md),
                _buildStatItem(context, Icons.favorite_outline, topic.likeCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, int count) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14.w,
          color: theme.echoTextTertiary,
        ),
        SizedBox(width: 4.w),
        Text(
          count.toString(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.echoTextTertiary,
          ),
        ),
      ],
    );
  }
}
