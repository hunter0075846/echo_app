import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'api_exception.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final ApiService _api = ApiService();
  final SecureStorageService _secure = SecureStorageService.instance;
  String? _token;
  UserModel? _currentUser;
  bool _initialized = false;

  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  ApiService get apiService => _api;

  Future<void> init() async {
    if (_initialized) return;

    await _migrateFromSharedPreferencesIfNeeded();

    _token = await _secure.read(_tokenKey);
    if (_token != null) _api.setAuthToken(_token);

    final userData = await _secure.read(_userKey);
    if (userData != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userData));
      } catch (_) {
        await _secure.delete(_userKey);
      }
    }

    _initialized = true;
  }

  /// 把旧版 SharedPreferences 中的 token / user 搬到 SecureStorage 后清理。
  /// 一次性逻辑，老用户升级时执行；之后 SecureStorage 已有值就不再触发。
  Future<void> _migrateFromSharedPreferencesIfNeeded() async {
    final existingToken = await _secure.read(_tokenKey);
    if (existingToken != null) return;

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey);
    final legacyUser = prefs.getString(_userKey);

    if (legacyToken != null) {
      await _secure.write(_tokenKey, legacyToken);
      await prefs.remove(_tokenKey);
    }
    if (legacyUser != null) {
      await _secure.write(_userKey, legacyUser);
      await prefs.remove(_userKey);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    await init();
    if (_token == null) return null;
    if (_currentUser != null) return _currentUser;

    try {
      final response = await _api.get('/auth/me');
      _currentUser = UserModel.fromJson(response.data);
      await _saveUser(_currentUser!);
      return _currentUser;
    } on ApiException catch (e) {
      if (e.isUnauthorized) await logout();
      return null;
    }
  }

  Future<UserModel> register(String phone, String password, {String? nickname}) async {
    final response = await _api.post('/auth/register', data: {
      'phone': phone,
      'password': password,
      if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
    });
    return _persistAuth(response.data);
  }

  Future<UserModel> login(String phone, String password) async {
    final response = await _api.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return _persistAuth(response.data);
  }

  Future<UserModel> _persistAuth(dynamic data) async {
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user']);

    _token = token;
    _currentUser = user;
    _api.setAuthToken(token);

    await _saveToken(token);
    await _saveUser(user);

    return user;
  }

  Future<void> logout() async {
    final tokenSnapshot = _token;

    // 1. best-effort 通知后端把 token 加入黑名单（断网/超时/401 都吞掉）
    if (tokenSnapshot != null) {
      try {
        await _api.post('/auth/logout');
      } on ApiException {
        // ignore
      }
    }

    // 2. 清 Dio 上的 token，否则后续请求仍会带旧凭证
    _api.setAuthToken(null);

    // 3. 清持久化与内存状态
    await _secure.delete(_tokenKey);
    await _secure.delete(_userKey);
    _token = null;
    _currentUser = null;
  }

  Future<UserModel> updateProfile({
    String? nickname,
    String? avatar,
    String? gender,
    DateTime? birthday,
  }) async {
    final response = await _api.patch('/auth/me', data: {
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
      if (gender != null) 'gender': gender,
      if (birthday != null) 'birthday': birthday.toUtc().toIso8601String(),
    });

    _currentUser = UserModel.fromJson(response.data);
    await _saveUser(_currentUser!);

    return _currentUser!;
  }

  Future<void> _saveToken(String token) => _secure.write(_tokenKey, token);

  Future<void> _saveUser(UserModel user) =>
      _secure.write(_userKey, jsonEncode(user.toJson()));
}
