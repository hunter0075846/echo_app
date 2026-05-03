import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'api_service.dart';

/// 流式事件
sealed class AssistantStreamEvent {}

class Delta extends AssistantStreamEvent {
  final String content;
  Delta(this.content);
}

class StreamDone extends AssistantStreamEvent {
  final String messageId;
  StreamDone(this.messageId);
}

class StreamError extends AssistantStreamEvent {
  final ApiException error;
  StreamError(this.error);
}

/// 单条聊天消息（服务端 AssistantMessage 镜像）
class AssistantMessageModel {
  final String id;
  final String userId;
  final String role; // user | assistant
  final String content;
  final String? groupId;
  final DateTime? createdAt;

  AssistantMessageModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.content,
    this.groupId,
    this.createdAt,
  });

  factory AssistantMessageModel.fromJson(Map<String, dynamic> json) {
    return AssistantMessageModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      groupId: json['groupId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

/// 历史分页
class AssistantHistoryPage {
  final List<AssistantMessageModel> messages;
  final String? nextCursor;
  final bool hasMore;

  AssistantHistoryPage({
    required this.messages,
    this.nextCursor,
    required this.hasMore,
  });
}

/// AI助手小安服务
class AiAssistantService {
  final ApiService _api;

  AiAssistantService(this._api);

  /// 流式对话
  Stream<AssistantStreamEvent> chatStream({
    required String message,
    String? groupId,
  }) {
    final controller = StreamController<AssistantStreamEvent>();

    _runStream(controller, message, groupId);

    return controller.stream;
  }

  Future<void> _runStream(
    StreamController<AssistantStreamEvent> controller,
    String message,
    String? groupId,
  ) async {
    try {
      final response = await _api.dio.post(
        '/ai/assistant',
        data: {
          'message': message,
          if (groupId != null) 'groupId': groupId,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;
      await for (final line in utf8.decoder
          .bind(stream)
          .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr.trim().isEmpty) continue;

          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;

            if (data.containsKey('delta')) {
              controller.add(Delta(data['delta'] as String));
            } else if (data.containsKey('done')) {
              final id = data['id'] as String? ?? '';
              controller.add(StreamDone(id));
            } else if (data.containsKey('error')) {
              final err = data['error'] as Map<String, dynamic>;
              controller.add(StreamError(ApiException(
                message: err['message'] as String? ?? 'AI 服务错误',
                code: err['code'] as String?,
                statusCode: 502,
              )));
            }
          } catch (_) {
            // 忽略无法解析的行
          }
        }
      }

      if (!controller.isClosed) {
        controller.close();
      }
    } on DioException catch (e) {
      if (!controller.isClosed) {
        controller.add(StreamError(ApiException.fromDio(e)));
        controller.close();
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.add(StreamError(ApiException(
          message: '网络错误，请检查网络连接',
          isNetworkError: true,
        )));
        controller.close();
      }
    }
  }

  /// 拉取历史消息（cursor 分页）
  Future<AssistantHistoryPage> getHistory({
    String? cursor,
    int limit = 50,
  }) async {
    final response = await _api.get('/ai/assistant/messages', queryParameters: {
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });

    final data = response.data as Map<String, dynamic>;
    final messages = (data['messages'] as List)
        .map((json) =>
            AssistantMessageModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return AssistantHistoryPage(
      messages: messages,
      nextCursor: data['nextCursor'] as String?,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  /// 获取小安信息
  Future<Map<String, dynamic>> getAssistantInfo() async {
    final response = await _api.get('/ai/assistant');
    return response.data as Map<String, dynamic>;
  }
}
