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
      baseUrl: defaultBaseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    d.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.baseUrl = defaultBaseUrl;
        final token = await _storage.read(key: _tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
    return d;
  }

  Future<String> getBaseUrl() async => defaultBaseUrl;
  Future<void> setBaseUrl(String url) async {}

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
