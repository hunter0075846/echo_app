import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 薄封装 flutter_secure_storage：
/// - Android 默认使用 EncryptedSharedPreferences
/// - iOS 使用 Keychain（accessibility: first_unlock）
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  static const _options = AndroidOptions(encryptedSharedPreferences: true);
  static const _iosOptions = IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _options,
    iOptions: _iosOptions,
  );

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();
}
