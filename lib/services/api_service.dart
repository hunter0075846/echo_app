import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import 'log_service.dart';

class ApiService {
  late final Dio _dio;

  /// 后端 API 基础地址，从 AppConfig 获取
  /// 支持通过 --dart-define=API_BASE_URL=xxx 在编译时覆盖
  static String get baseUrl => AppConfig.apiBaseUrl;

  String? _authToken;

  /// 401 处理回调；由上层（AuthNotifier）注入，触发 logout + 跳登录页。
  /// 用回调避免反向依赖。
  void Function()? _onUnauthorized;

  // 单例模式
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status != null && status >= 200 && status < 300;
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        logService.logNetworkRequest(
          options.method,
          '${options.baseUrl}${options.path}',
          headers: options.headers.cast<String, dynamic>(),
          body: options.data,
        );

        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        logService.logNetworkResponse(
          response.requestOptions.method,
          '${response.requestOptions.baseUrl}${response.requestOptions.path}',
          response.statusCode ?? 0,
          body: response.data,
        );

        return handler.next(response);
      },
      onError: (error, handler) {
        logService.logNetworkError(
          error.requestOptions.method,
          '${error.requestOptions.baseUrl}${error.requestOptions.path}',
          error.message,
          stackTrace: error.stackTrace,
        );

        if (error.response?.statusCode == 401) {
          _onUnauthorized?.call();
        }

        return handler.next(error);
      },
    ));
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// 注册 401 处理回调（通常由 AuthNotifier 注入）
  void setUnauthorizedHandler(void Function()? handler) {
    _onUnauthorized = handler;
  }

  Future<Response> _safe(Future<Response> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _safe(() => _dio.get(path, queryParameters: queryParameters));

  Future<Response> post(String path, {dynamic data}) =>
      _safe(() => _dio.post(path, data: data));

  Future<Response> put(String path, {dynamic data}) =>
      _safe(() => _dio.put(path, data: data));

  Future<Response> delete(String path) =>
      _safe(() => _dio.delete(path));

  Future<Response> patch(String path, {dynamic data}) =>
      _safe(() => _dio.patch(path, data: data));
}
