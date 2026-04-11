import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 解析错误信息，返回友好的错误提示
String parseAuthError(dynamic error, {required bool isRegister}) {
  final errorMsg = error.toString();

  if (isRegister) {
    // 注册时的错误
    if (errorMsg.contains('409')) {
      return '该手机号已注册，请直接登录';
    } else if (errorMsg.contains('400')) {
      return '请求参数错误，请检查输入';
    } else if (errorMsg.contains('500')) {
      return '服务器错误，请稍后重试';
    } else if (errorMsg.contains('DioException') ||
        errorMsg.contains('SocketException') ||
        errorMsg.contains('XMLHttpRequest')) {
      return '网络错误，请检查网络连接';
    }
    return '注册失败，请稍后重试';
  } else {
    // 登录时的错误
    if (errorMsg.contains('401') || errorMsg.contains('400')) {
      return '手机号或密码错误';
    } else if (errorMsg.contains('500')) {
      return '服务器错误，请稍后重试';
    } else if (errorMsg.contains('DioException') ||
        errorMsg.contains('SocketException') ||
        errorMsg.contains('XMLHttpRequest')) {
      return '网络错误，请检查网络连接';
    }
    return '登录失败，请稍后重试';
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  String? _lastError;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  /// 获取最后一次错误信息
  String? get lastError => _lastError;

  Future<void> _init() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> register(String phone, String password) async {
    state = const AsyncValue.loading();
    _lastError = null;
    try {
      final user = await _authService.register(phone, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      _lastError = parseAuthError(e, isRegister: true);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncValue.loading();
    _lastError = null;
    try {
      final user = await _authService.login(phone, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      _lastError = parseAuthError(e, isRegister: false);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _lastError = null;
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile({String? nickname, String? avatar}) async {
    _lastError = null;
    try {
      final user = await _authService.updateProfile(
        nickname: nickname,
        avatar: avatar,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      _lastError = '更新资料失败，请稍后重试';
      state = AsyncValue.error(e, st);
    }
  }

  /// 清除错误信息
  void clearError() {
    _lastError = null;
  }
}
