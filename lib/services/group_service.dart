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

  // 获取群消息
  Future<List<GroupMessageModel>> getGroupMessages(String groupId) async {
    final response = await _api.get('/groups/$groupId/messages');
    return (response.data as List)
        .map((json) => GroupMessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // 发送消息
  Future<GroupMessageModel> sendMessage({
    required String groupId,
    required String content,
    String? mediaUrl,
    bool isAnonymous = false,
  }) async {
    final response = await _api.post('/groups/$groupId/messages', data: {
      'content': content,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      'isAnonymous': isAnonymous,
    });
    return GroupMessageModel.fromJson(response.data as Map<String, dynamic>);
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
