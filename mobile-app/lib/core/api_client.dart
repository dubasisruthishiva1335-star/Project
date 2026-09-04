import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central Dio client configured for live Railway production backend.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'myvault_jwt';
  static const _baseUrlKey = 'myvault_base_url';
  static const defaultBaseUrl = 'https://project-9zrh.onrender.com';

  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final d = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    d.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.baseUrl = await getBaseUrl();
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
    return d;
  }

  Future<String> getBaseUrl() async {
    return await _storage.read(key: _baseUrlKey) ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) => _storage.write(key: _baseUrlKey, value: url);

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
