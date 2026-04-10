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

  // 转发话题到群聊
  Future<void> forwardTopic({
    required String groupId,
    required String topicId,
    String? guideText,
  }) async {
    await _api.post('/groups/$groupId/forward', data: {
      'topicId': topicId,
      if (guideText != null) 'guideText': guideText,
    });
  }
}
