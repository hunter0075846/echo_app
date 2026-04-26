import 'package:dio/dio.dart';
import '../models/agent_model.dart';
import 'api_service.dart';

/// AI Agent 服务
class AgentService {
  final ApiService _api;

  AgentService(this._api);

  /// 获取当前用户的所有Agent
  Future<List<AgentModel>> getAgents() async {
    try {
      final response = await _api.get('/agents');
      final List<dynamic> agents = response.data['agents'] ?? [];
      return agents.map((e) => AgentModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('获取Agent列表失败: ${e.message}');
    } catch (e) {
      throw Exception('获取Agent列表失败: $e');
    }
  }

  /// 创建Agent
  Future<AgentModel> createAgent({
    required String name,
    String? description,
    String? avatar,
    required String baseUrl,
    required String apiKey,
    required String model,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    try {
      final response = await _api.post('/agents', data: {
        'name': name,
        'description': description,
        'avatar': avatar,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
        'systemPrompt': systemPrompt,
        'temperature': temperature,
        'maxTokens': maxTokens,
      });

      return AgentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      final msg = e.response?.data?['error'] ?? e.message;
      throw Exception('创建Agent失败: $msg');
    } catch (e) {
      throw Exception('创建Agent失败: $e');
    }
  }

  /// 获取Agent详情
  Future<AgentModel> getAgent(String agentId) async {
    try {
      final response = await _api.get('/agents/$agentId');
      return AgentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('获取Agent详情失败: ${e.message}');
    } catch (e) {
      throw Exception('获取Agent详情失败: $e');
    }
  }

  /// 更新Agent
  Future<AgentModel> updateAgent(
    String agentId, {
    String? name,
    String? description,
    String? avatar,
    String? baseUrl,
    String? apiKey,
    String? model,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (avatar != null) data['avatar'] = avatar;
      if (baseUrl != null) data['baseUrl'] = baseUrl;
      if (apiKey != null) data['apiKey'] = apiKey;
      if (model != null) data['model'] = model;
      if (systemPrompt != null) data['systemPrompt'] = systemPrompt;
      if (temperature != null) data['temperature'] = temperature;
      if (maxTokens != null) data['maxTokens'] = maxTokens;
      if (isActive != null) data['isActive'] = isActive;

      final response = await _api.patch('/agents/$agentId', data: data);
      return AgentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      final msg = e.response?.data?['error'] ?? e.message;
      throw Exception('更新Agent失败: $msg');
    } catch (e) {
      throw Exception('更新Agent失败: $e');
    }
  }

  /// 删除Agent
  Future<void> deleteAgent(String agentId) async {
    try {
      await _api.delete('/agents/$agentId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('删除Agent失败: ${e.message}');
    } catch (e) {
      throw Exception('删除Agent失败: $e');
    }
  }

  /// 与Agent对话
  Future<String> chat({
    required String agentId,
    required String message,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await _api.post('/agents/$agentId/chat', data: {
        'message': message,
        'history': history ?? [],
      });

      return response.data['reply'] ?? '抱歉，我暂时没有回复。';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      final msg = e.response?.data?['error'] ?? e.message;
      throw Exception('对话失败: $msg');
    } catch (e) {
      throw Exception('对话失败: $e');
    }
  }

  /// 获取聊天记录
  Future<List<AgentChatMessageModel>> getChatHistory(String agentId) async {
    try {
      final response = await _api.get('/agents/$agentId/chat');
      final List<dynamic> messages = response.data['messages'] ?? [];
      return messages
          .map((e) => AgentChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('获取聊天记录失败: ${e.message}');
    } catch (e) {
      throw Exception('获取聊天记录失败: $e');
    }
  }
}
