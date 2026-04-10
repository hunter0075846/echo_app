import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/topic_model.dart';
import '../services/topic_service.dart';

class TopicListState {
  final List<TopicModel> topics;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final int totalPages;
  final int limit;
  final String? error;
  final String sort;
  final String searchQuery;

  const TopicListState({
    this.topics = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.limit = 20,
    this.error,
    this.sort = 'latest',
    this.searchQuery = '',
  });

  TopicListState copyWith({
    List<TopicModel>? topics,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    int? totalPages,
    int? limit,
    String? error,
    String? sort,
    String? searchQuery,
  }) {
    return TopicListState(
      topics: topics ?? this.topics,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      limit: limit ?? this.limit,
      error: error ?? this.error,
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TopicDetailState {
  final TopicModel? topic;
  final List<TopicCommentModel> comments;
  final bool isLoading;
  final bool isLoadingComments;
  final String? error;

  const TopicDetailState({
    this.topic,
    this.comments = const [],
    this.isLoading = false,
    this.isLoadingComments = false,
    this.error,
  });

  TopicDetailState copyWith({
    TopicModel? topic,
    List<TopicCommentModel>? comments,
    bool? isLoading,
    bool? isLoadingComments,
    String? error,
  }) {
    return TopicDetailState(
      topic: topic ?? this.topic,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      error: error ?? this.error,
    );
  }
}

final topicServiceProvider = Provider<TopicService>((ref) {
  return TopicService();
});

final topicListProvider = StateNotifierProvider<TopicListNotifier, TopicListState>((ref) {
  final topicService = ref.watch(topicServiceProvider);
  return TopicListNotifier(topicService);
});

final topicDetailProvider = StateNotifierProvider.family<TopicDetailNotifier, TopicDetailState, String>((ref, topicId) {
  final topicService = ref.watch(topicServiceProvider);
  return TopicDetailNotifier(topicService, topicId);
});

class TopicListNotifier extends StateNotifier<TopicListState> {
  final TopicService _topicService;

  TopicListNotifier(this._topicService) : super(const TopicListState()) {
    loadTopics();
  }

  Future<void> loadTopics({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        currentPage: 1,
        topics: [],
        error: null,
      );
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _topicService.getTopics(
        page: state.currentPage,
        limit: state.limit,
        sort: state.sort,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );

      state = state.copyWith(
        topics: refresh ? result.topics : [...state.topics, ...result.topics],
        totalPages: result.totalPages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.currentPage >= state.totalPages) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _topicService.getTopics(
        page: nextPage,
        limit: state.limit,
        sort: state.sort,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );

      state = state.copyWith(
        topics: [...state.topics, ...result.topics],
        currentPage: nextPage,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void setSort(String sort) {
    if (state.sort == sort) return;
    state = state.copyWith(sort: sort);
    loadTopics(refresh: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> search() async {
    await loadTopics(refresh: true);
  }
}

class TopicDetailNotifier extends StateNotifier<TopicDetailState> {
  final TopicService _topicService;
  final String _topicId;

  TopicDetailNotifier(this._topicService, this._topicId) : super(const TopicDetailState()) {
    loadTopic();
  }

  Future<void> loadTopic() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final topic = await _topicService.getTopicDetail(_topicId);
      state = state.copyWith(
        topic: topic,
        isLoading: false,
      );
      // 加载评论
      loadComments();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadComments() async {
    state = state.copyWith(isLoadingComments: true);

    try {
      final comments = await _topicService.getTopicComments(_topicId);
      state = state.copyWith(
        comments: comments,
        isLoadingComments: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingComments: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addComment(String content, {String? parentId}) async {
    try {
      final comment = await _topicService.addComment(
        topicId: _topicId,
        content: content,
        parentId: parentId,
      );
      state = state.copyWith(
        comments: [comment, ...state.comments],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> likeTopic() async {
    try {
      await _topicService.likeTopic(_topicId);
      if (state.topic != null) {
        state = state.copyWith(
          topic: state.topic!.copyWith(
            likeCount: state.topic!.likeCount + 1,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTopic() async {
    try {
      await _topicService.deleteTopic(_topicId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}
