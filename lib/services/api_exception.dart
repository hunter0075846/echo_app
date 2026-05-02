import 'dart:io';
import 'package:dio/dio.dart';

/// 统一的 API 异常类型。
/// 所有业务层代码应该 catch 这个，而不是 catch DioException + 字符串匹配。
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? code;
  final dynamic details;
  final bool isNetworkError;

  ApiException({
    this.statusCode,
    required this.message,
    this.code,
    this.details,
    this.isNetworkError = false,
  });

  factory ApiException.network(String message) =>
      ApiException(message: message, isNetworkError: true);

  factory ApiException.fromDio(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException.network('网络超时，请检查网络连接');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return ApiException.network('网络错误，请检查网络连接');
    }

    String message = '服务器错误，请稍后重试';
    String? code;
    dynamic details;

    if (data is Map) {
      final err = data['error'];
      if (err is Map) {
        if (err['message'] is String) message = err['message'];
        if (err['code'] is String) code = err['code'];
        details = err['details'];
      } else if (err is String) {
        message = err;
      } else if (data['message'] is String) {
        message = data['message'];
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      code: code,
      details: details,
    );
  }

  /// 是否需要触发自动登出（401）
  bool get isUnauthorized => statusCode == 401;

  /// 服务端给出的 Retry-After 秒数（429 时通常带）
  int? get retryAfterSeconds {
    final raw = details;
    if (raw is Map && raw['retryAfter'] is int) return raw['retryAfter'];
    return null;
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
