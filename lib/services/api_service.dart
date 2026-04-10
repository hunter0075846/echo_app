import 'package:dio/dio.dart';
import 'log_service.dart';

class ApiService {
  late final Dio _dio;
  
  static String get baseUrl => 'https://echo-backend-beta.vercel.app/api';
  
  String? _authToken;

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
        // 只接受 200-299 状态码为成功
        return status != null && status >= 200 && status < 300;
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 记录网络请求日志
        logService.logNetworkRequest(
          options.method,
          '${options.baseUrl}${options.path}',
          headers: options.headers.cast<String, dynamic>(),
          body: options.data,
        );
        
        // 添加 JWT Token
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 记录网络响应日志
        logService.logNetworkResponse(
          response.requestOptions.method,
          '${response.requestOptions.baseUrl}${response.requestOptions.path}',
          response.statusCode ?? 0,
          body: response.data,
        );
        
        return handler.next(response);
      },
      onError: (error, handler) {
        // 记录网络错误日志
        logService.logNetworkError(
          error.requestOptions.method,
          '${error.requestOptions.baseUrl}${error.requestOptions.path}',
          error.message,
          stackTrace: error.stackTrace,
        );
        
        return handler.next(error);
      },
    ));
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }
}
