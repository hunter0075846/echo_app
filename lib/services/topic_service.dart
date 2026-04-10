import '../models/topic_model.dart';
import 'api_service.dart';

class TopicListResult {
  final List<TopicModel> topics;
  final int totalPages;

  TopicListResult({
    required this.topics,
    required this.totalPages,
  });
}

class TopicService {
  final ApiService _api = ApiService();

  // 获取话题列表
  Future<TopicListResult> getTopics({
    required int page,
    required int limit,
    String sort = 'latest',
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _api.get(
      '/topics',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final topics = (data['topics'] as List)
        .map((json) => TopicModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return TopicListResult(
      topics: topics,
      totalPages: data['pagination']['totalPages'] as int,
    );
  }

  // 获取话题详情
  Future<TopicModel> getTopicDetail(String topicId) async {
    final response = await _api.get('/topics/$topicId');
    return TopicModel.fromJson(response.data as Map<String, dynamic>);
  }

  // 获取话题评论
  Future<List<TopicCommentModel>> getTopicComments(String topicId) async {
    final response = await _api.get('/topics/$topicId/comments');
    return (response.data as List)
        .map((json) => TopicCommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // 添加评论
  Future<TopicCommentModel> addComment({
    required String topicId,
    required String content,
    String? parentId,
  }) async {
    final response = await _api.post('/topics/$topicId/comments', data: {
      'content': content,
      if (parentId != null) 'parentId': parentId,
    });
    return TopicCommentModel.fromJson(response.data as Map<String, dynamic>);
  }

  // 点赞话题
  Future<void> likeTopic(String topicId) async {
    await _api.post('/topics/$topicId/like');
  }

  // 创建话题
  Future<TopicModel> createTopic({
    required String sourceType,
    String? sourceUrl,
    String? imageUrl,
    required String content,
  }) async {
    final response = await _api.post('/topics', data: {
      'sourceType': sourceType,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'content': content,
    });
    return TopicModel.fromJson(response.data as Map<String, dynamic>);
  }

  // 删除话题
  Future<void> deleteTopic(String topicId) async {
    await _api.delete('/topics/$topicId');
  }

  // 转发话题到群
  Future<void> forwardToGroup({
    required String topicId,
    required String groupId,
    String? guideText,
  }) async {
    await _api.post('/topics/$topicId/forward', data: {
      'groupId': groupId,
      if (guideText != null) 'guideText': guideText,
    });
  }
}
