import 'api_service.dart';

/// 举报服务
class ReportService {
  final ApiService _api = ApiService();

  /// targetType: topic, topic_comment, group_message
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    await _api.post('/reports', data: {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
    });
  }
}
