import 'package:dio/dio.dart';
import '../models/openclaw_connection_model.dart';
import '../models/openclaw_message_model.dart';
import 'api_service.dart';

/// OpenClaw 服务
class OpenClawService {
  final ApiService _api;

  OpenClawService(this._api);

  /// 获取所有连接列表
  Future<List<OpenClawConnectionModel>> getConnections() async {
    try {
      final response = await _api.get('/openclaw');
      final List<dynamic> list = response.data['connections'] ?? [];
      return list
          .map((e) => OpenClawConnectionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('获取连接列表失败: ${e.message}');
    } catch (e) {
      throw Exception('获取连接列表失败: $e');
    }
  }

  /// 创建新连接（生成Token）
  Future<Map<String, dynamic>> createConnection({
    String? name,
    String? avatar,
    String? systemPrompt,
  }) async {
    try {
      final response = await _api.post('/openclaw/connect', data: {
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      final msg = e.response?.data?['error'] ?? e.message;
      throw Exception('创建连接失败: $msg');
    } catch (e) {
      throw Exception('创建连接失败: $e');
    }
  }

  /// 获取单个连接详情
  Future<OpenClawConnectionModel> getConnectionDetail(String connectionId) async {
    try {
      final response = await _api.get('/openclaw/$connectionId');
      return OpenClawConnectionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('获取连接详情失败: ${e.message}');
    } catch (e) {
      throw Exception('获取连接详情失败: $e');
    }
  }

  /// 获取单个连接状态
  Future<Map<String, dynamic>> getConnectionStatus(String connectionId) async {
    try {
      final response = await _api.get('/openclaw/$connectionId/status');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('查询状态失败: ${e.message}');
    } catch (e) {
      throw Exception('查询状态失败: $e');
    }
  }

  /// 更新连接配置
  Future<void> updateConnection(
    String connectionId, {
    String? name,
    String? avatar,
    String? systemPrompt,
  }) async {
    try {
      await _api.patch('/openclaw/$connectionId', data: {
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      final msg = e.response?.data?['error'] ?? e.message;
      throw Exception('更新配置失败: $msg');
    } catch (e) {
      throw Exception('更新配置失败: $e');
    }
  }

  /// 删除指定连接
  Future<void> deleteConnection(String connectionId) async {
    try {
      await _api.delete('/openclaw/$connectionId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      final msg = e.response?.data?['error'] ?? e.message;
      throw Exception('删除连接失败: $msg');
    } catch (e) {
      throw Exception('删除连接失败: $e');
    }
  }

  /// 获取聊天记录（指定连接）
  Future<List<OpenClawMessageModel>> getMessages(String connectionId) async {
    try {
      final response = await _api.get('/openclaw/messages', queryParameters: {
        'connectionId': connectionId,
      });
      final List<dynamic> messages = response.data['messages'] ?? [];
      return messages.map((e) => OpenClawMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      throw Exception('获取聊天记录失败: ${e.message}');
    } catch (e) {
      throw Exception('获取聊天记录失败: $e');
    }
  }

  /// 发送消息（指定连接）
  Future<OpenClawMessageModel> sendMessage(String connectionId, String content) async {
    try {
      final response = await _api.post('/openclaw/messages', data: {
        'connectionId': connectionId,
        'content': content,
      });
      return OpenClawMessageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      final msg = e.response?.data?['error'] ?? e.message;
      throw Exception('发送消息失败: $msg');
    } catch (e) {
      throw Exception('发送消息失败: $e');
    }
  }
}
