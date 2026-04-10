import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final ApiService _api = ApiService();
  String? _token;
  UserModel? _currentUser;

  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  ApiService get apiService => _api;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    // 设置 API Token
    if (_token != null) {
      _api.setAuthToken(_token);
    }

    final userData = prefs.getString(_userKey);
    if (userData != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userData));
    }
  }

  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    await init();
    if (_token == null) return null;

    try {
      final response = await _api.get('/auth/me');
      _currentUser = UserModel.fromJson(response.data);
      await _saveUser(_currentUser!);
      return _currentUser;
    } catch (e) {
      await logout();
      return null;
    }
  }

  Future<UserModel> register(String phone, String password) async {
    final response = await _api.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });

    _token = response.data['token'];
    _currentUser = UserModel.fromJson(response.data['user']);

    // 设置 API Token
    _api.setAuthToken(_token!);

    await _saveToken(_token!);
    await _saveUser(_currentUser!);

    return _currentUser!;
  }

  Future<UserModel> login(String phone, String password) async {
    final response = await _api.put('/auth/login', data: {
      'phone': phone,
      'password': password,
    });

    _token = response.data['token'];
    _currentUser = UserModel.fromJson(response.data['user']);

    await _saveToken(_token!);
    await _saveUser(_currentUser!);

    return _currentUser!;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _token = null;
    _currentUser = null;
  }

  Future<UserModel> updateProfile({String? nickname, String? avatar}) async {
    final response = await _api.patch('/auth/profile', data: {
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
    });

    _currentUser = UserModel.fromJson(response.data);
    await _saveUser(_currentUser!);

    return _currentUser!;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
