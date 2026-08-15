import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/group_model.dart';
import 'api_service.dart';

class GroupService {
  final ApiService _api = ApiService();

  // 获取我的群聊列表
  Future<List<GroupModel>> getMyGroups() async {
    final response = await _api.get('/groups');
    return (response.data as List)
        .map((json) => GroupModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // 获取群聊详情
  Future<GroupModel> getGroupDetail(String groupId) async {
    final response = await _api.get('/groups/$groupId');
    return GroupModel.fromJson(response.data as Map<String, dynamic>);
  }

  // 创建群聊
  Future<GroupModel> createGroup({
    required String name,
    String? description,
  }) async {
    final response = await _api.post('/groups', data: {
      'name': name,
      if (description != null) 'description': description,
    });
    return GroupModel.fromJson(response.data as Map<String, dynamic>);
  }

  // 获取群成员
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final response = await _api.get('/groups/$groupId/members');
    return (response.data as List)
        .map((json) => GroupMemberModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // 获取群消息（cardId 不为空时只看该话题卡片下的讨论消息）
  Future<List<GroupMessageModel>> getGroupMessages(String groupId, {String? cardId}) async {
    final response = await _api.get(
      '/groups/$groupId/messages',
      queryParameters: {if (cardId != null) 'cardId': cardId},
    );
    return (response.data as List)
        .map((json) => GroupMessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // 获取话题卡片详情（含话题信息）
  Future<Map<String, dynamic>> getTopicCard(String groupId, String cardId) async {
    final response = await _api.get('/groups/$groupId/topic-cards/$cardId');
    return response.data as Map<String, dynamic>;
  }

  // 加入话题卡片讨论（参与数 +1）
  Future<int> joinTopicCard(String groupId, String cardId) async {
    final response = await _api.post('/groups/$groupId/topic-cards/$cardId/join');
    return response.data['participantCount'] as int;
  }

  // 获取群回忆时间线
  Future<List<Map<String, dynamic>>> getMemories(String groupId) async {
    final response = await _api.get('/groups/$groupId/memories');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // 手动加入回忆
  Future<void> addMemory({
    required String groupId,
    required String content,
    String? title,
  }) async {
    await _api.post('/groups/$groupId/memories', data: {
      'content': content,
      if (title != null) 'title': title,
    });
  }

  // 删除回忆（群主任意删，成员仅删涉及自己的）
  Future<void> deleteMemory(String groupId, String memoryId) async {
    await _api.delete('/groups/$groupId/memories/$memoryId');
  }

  // 获取群内某话题的投票状态
  Future<Map<String, dynamic>?> getVote(String groupId, String topicId) async {
    final response = await _api.get(
      '/groups/$groupId/votes',
      queryParameters: {'topicId': topicId},
    );
    return response.data as Map<String, dynamic>?;
  }

  // 投票 / 改投
  Future<Map<String, dynamic>> submitVote({
    required String groupId,
    required String topicId,
    required String option,
  }) async {
    final response = await _api.post('/groups/$groupId/votes', data: {
      'topicId': topicId,
      'option': option,
    });
    return response.data as Map<String, dynamic>;
  }

  // 在话题卡片讨论页发言（带 cardId 的普通文本消息）
  Future<GroupMessageModel> sendCardMessage({
    required String groupId,
    required String cardId,
    required String content,
  }) async {
    final response = await _api.post('/groups/$groupId/messages', data: {
      'content': content,
      'type': 'text',
      'metadata': {'cardId': cardId},
    });
    return GroupMessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  // 发送消息
  // 发送消息（voteOptions：匿名消息附 1-2 个简单投票选项）
  Future<GroupMessageModel> sendMessage({
    required String groupId,
    required String content,
    String? mediaUrl,
    bool isAnonymous = false,
    List<String>? voteOptions,
  }) async {
    final response = await _api.post('/groups/$groupId/messages', data: {
      'content': content,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      'isAnonymous': isAnonymous,
      if (voteOptions != null && voteOptions.isNotEmpty)
        'metadata': {'voteOptions': voteOptions},
    });
    return GroupMessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  // 对「有人说」附带的投票投票/改投
  Future<Map<String, dynamic>> voteOnMessage({
    required String groupId,
    required String messageId,
    required String option,
  }) async {
    final response = await _api.post(
      '/groups/$groupId/messages/$messageId/vote',
      data: {'option': option},
    );
    return response.data as Map<String, dynamic>;
  }

  // 生成邀请码
  Future<String> generateInviteCode(String groupId) async {
    final response = await _api.post('/groups/$groupId/invite');
    return response.data['code'] as String;
  }

  // 通过邀请码查群信息（只读，不加入）
  Future<Map<String, dynamic>> getGroupByInviteCode(String code) async {
    final response = await _api.get('/groups/invite/${code.toUpperCase()}');
    return response.data as Map<String, dynamic>;
  }

  // 通过邀请码加入群聊
  Future<GroupModel> joinGroupByCode(String code) async {
    final response = await _api.post('/groups/join', data: {
      'code': code,
    });
    return GroupModel.fromJson(response.data as Map<String, dynamic>);
  }

  // 退出群聊
  Future<void> leaveGroup(String groupId) async {
    await _api.post('/groups/$groupId/leave');
  }

  // 删除群聊（仅群主）
  Future<void> deleteGroup(String groupId) async {
    await _api.delete('/groups/$groupId');
  }

  // 转发话题到群聊（以 topic_card 类型发送）
  Future<void> forwardTopic({
    required String groupId,
    required String topicId,
    String? guideText,
  }) async {
    await _api.post('/groups/$groupId/messages', data: {
      'content': guideText ?? '转发了一个话题',
      'type': 'topic_card',
      'metadata': {
        'topicId': topicId,
        if (guideText != null) 'guideText': guideText,
      },
    });
  }

  // 转发小E回复到群聊（以 agent_quote 类型发送）
  Future<void> forwardAssistantMessage({
    required String groupId,
    required String content,
    String? sourceMessageId,
    String? prompt,
  }) async {
    await _api.post('/groups/$groupId/messages', data: {
      'content': content,
      'type': 'agent_quote',
      'metadata': {
        if (sourceMessageId != null) 'sourceId': sourceMessageId,
        if (prompt != null) 'prompt': prompt,
      },
    });
  }

  // ---- OpenClaw Bot 管理 ----

  Future<List<GroupBotModel>> getGroupBots(String groupId) async {
    final response = await _api.get('/groups/$groupId/bots');
    final List<dynamic> list = response.data['bots'] ?? [];
    return list.map((e) => GroupBotModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addBot(String groupId, String connectionId) async {
    await _api.post('/groups/$groupId/bots', data: {
      'connectionId': connectionId,
    });
  }

  Future<void> removeBot(String groupId, String botId) async {
    await _api.delete('/groups/$groupId/bots/$botId');
  }

  // ---- 群成员管理 ----

  Future<void> removeMember(String groupId, String userId) async {
    await _api.delete('/groups/$groupId/members', queryParameters: {
      'userId': userId,
    });
  }

  Future<void> updateMemberRole(String groupId, String userId, String role) async {
    await _api.patch('/groups/$groupId/members', data: {
      'userId': userId,
      'role': role,
    });
  }

  Future<void> transferOwnership(String groupId, String newOwnerId) async {
    await _api.post('/groups/$groupId/members/transfer', data: {
      'newOwnerId': newOwnerId,
    });
  }

  /// 建立群聊 SSE 连接，实时接收新消息
  Stream<GroupMessageModel> connectSSE(String groupId) async* {
    final response = await _api.dio.get(
      '/groups/$groupId/events',
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    final stream = response.data.stream as Stream<List<int>>;
    await for (final line in utf8.decoder.bind(stream).transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6);
        if (jsonStr.trim().isEmpty) continue;
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          if (data['type'] == 'message') {
            yield GroupMessageModel.fromJson(data['message'] as Map<String, dynamic>);
          }
        } catch (_) {
          // 忽略无法解析的行
        }
      }
    }
  }
}
