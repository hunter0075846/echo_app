import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';

class AuthErrorInfo {
  final String message;
  final int? statusCode;
  final String? code;

  const AuthErrorInfo({required this.message, this.statusCode, this.code});

  bool get isPhoneTaken => statusCode == 409 || code == 'PHONE_TAKEN';
  bool get isInvalidCredentials => statusCode == 401;
  bool get isRateLimited => statusCode == 429;
}

String _friendlyAuthMessage(Object error, {required bool isRegister}) {
  if (error is ApiException) {
    if (error.isNetworkError) return error.message;
    switch (error.statusCode) {
      case 400:
        return error.message;
      case 401:
        return '手机号或密码错误';
      case 409:
        return '该手机号已注册，请直接登录';
      case 429:
        return error.message;
      default:
        if (error.statusCode != null && error.statusCode! >= 500) {
          return '服务器错误，请稍后重试';
        }
        return error.message;
    }
  }
  return isRegister ? '注册失败，请稍后重试' : '登录失败，请稍后重试';
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  AuthErrorInfo? _lastErrorInfo;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _authService.apiService.setUnauthorizedHandler(_handleUnauthorized);
    _init();
  }

  AuthErrorInfo? get lastErrorInfo => _lastErrorInfo;
  String? get lastError => _lastErrorInfo?.message;

  Future<void> _init() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _handleUnauthorized() {
    if (state.value == null) return;
    _authService.logout();
    _lastErrorInfo = null;
    state = const AsyncValue.data(null);
  }

  Future<void> register(String phone, String password, {String? nickname}) async {
    state = const AsyncValue.loading();
    _lastErrorInfo = null;
    try {
      final user = await _authService.register(phone, password, nickname: nickname);
      state = AsyncValue.data(user);
    } on ApiException catch (e, st) {
      _lastErrorInfo = AuthErrorInfo(
        message: _friendlyAuthMessage(e, isRegister: true),
        statusCode: e.statusCode,
        code: e.code,
      );
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      _lastErrorInfo = AuthErrorInfo(
        message: _friendlyAuthMessage(e, isRegister: true),
      );
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncValue.loading();
    _lastErrorInfo = null;
    try {
      final user = await _authService.login(phone, password);
      state = AsyncValue.data(user);
    } on ApiException catch (e, st) {
      _lastErrorInfo = AuthErrorInfo(
        message: _friendlyAuthMessage(e, isRegister: false),
        statusCode: e.statusCode,
        code: e.code,
      );
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      _lastErrorInfo = AuthErrorInfo(
        message: _friendlyAuthMessage(e, isRegister: false),
      );
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _lastErrorInfo = null;
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile({
    String? nickname,
    String? avatar,
    String? gender,
    DateTime? birthday,
  }) async {
    _lastErrorInfo = null;
    try {
      final user = await _authService.updateProfile(
        nickname: nickname,
        avatar: avatar,
        gender: gender,
        birthday: birthday,
      );
      state = AsyncValue.data(user);
    } on ApiException catch (e, st) {
      _lastErrorInfo = AuthErrorInfo(
        message: e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      _lastErrorInfo = const AuthErrorInfo(message: '更新资料失败，请稍后重试');
      state = AsyncValue.error(e, st);
    }
  }

  void clearError() {
    _lastErrorInfo = null;
  }
}
