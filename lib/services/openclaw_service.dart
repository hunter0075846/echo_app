import 'package:dio/dio.dart';
import '../models/openclaw_message_model.dart';
import 'api_service.dart';

/// OpenClaw 服务
class OpenClawService {
  final ApiService _api;

  OpenClawService(this._api);

  /// 生成关联Token
  Future<Map<String, dynamic>> generateToken() async {
    try {
      final response = await _api.post('/openclaw/connect');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      final msg = e.response?.data?['error'] ?? e.message;
      throw Exception('生成Token失败: $msg');
    } catch (e) {
      throw Exception('生成Token失败: $e');
    }
  }

  /// 获取关联状态
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _api.get('/openclaw/status');
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

  /// 解除关联
  Future<void> disconnect() async {
    try {
      await _api.delete('/openclaw/disconnect');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('登录已过期，请重新登录');
      }
      final msg = e.response?.data?['error'] ?? e.message;
      throw Exception('解除关联失败: $msg');
    } catch (e) {
      throw Exception('解除关联失败: $e');
    }
  }

  /// 获取聊天记录
  Future<List<OpenClawMessageModel>> getMessages() async {
    try {
      final response = await _api.get('/openclaw/messages');
      final List<dynamic> messages = response.data['messages'] ?? [];
      return messages
          .map((e) => OpenClawMessageModel.fromJson(e as Map<String, dynamic>))
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

  /// 发送消息
  Future<OpenClawMessageModel> sendMessage(String content) async {
    try {
      final response = await _api.post('/openclaw/messages', data: {
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
