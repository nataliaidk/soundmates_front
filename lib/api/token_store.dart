import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) => _storage.write(key: _accessKey, value: token);
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<void> deleteAccessToken() => _storage.delete(key: _accessKey);

  Future<void> saveRefreshToken(String token) => _storage.write(key: _refreshKey, value: token);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);
  Future<void> deleteRefreshToken() => _storage.delete(key: _refreshKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
