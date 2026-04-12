import 'package:dio/dio.dart';
import 'api_service.dart';

/// AI助手小安服务
class AiAssistantService {
  final ApiService _api;

  AiAssistantService(this._api);

  /// 与小安对话
  /// 
  /// [message] 用户消息
  /// [groupId] 群聊ID（可选）
  /// [history] 对话历史
  /// 
  /// 返回小安的回复
  Future<String> chat({
    required String message,
    String? groupId,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await _api.post('/ai/assistant', data: {
        'message': message,
        'groupId': groupId,
        'history': history ?? [],
      });

      return response.data['reply'] ?? '抱歉，我暂时无法回复，请稍后再试~';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('对话失败: ${e.message}');
    } catch (e) {
      throw Exception('对话失败: $e');
    }
  }

  /// 获取小安信息
  Future<Map<String, dynamic>> getAssistantInfo() async {
    try {
      final response = await _api.get('/ai/assistant');
      return response.data;
    } catch (e) {
      throw Exception('获取信息失败: $e');
    }
  }
}
