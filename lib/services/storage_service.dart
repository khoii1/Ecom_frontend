import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String tokenKey, String tokenValue) async {
    await _storage.write(key: tokenKey, value: tokenValue);
  }

  Future<String?> readToken(String tokenKey) async {
    return await _storage.read(key: tokenKey);
  }

  Future<void> deleteToken(String tokenKey) async {
    await _storage.delete(key: tokenKey);
  }

  Future<void> deleteAllTokens() async {
    await _storage.deleteAll();
  }
}
