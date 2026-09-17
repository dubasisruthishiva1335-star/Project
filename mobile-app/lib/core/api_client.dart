import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'load_balancer.dart';
import 'network_retry_interceptor.dart';

/// Central Dio client powered by the Adaptive Multi-Node Load Balancer
/// with automatic failover, circuit breaking, and retry resilience.
class ApiClient {
  ApiClient._internal() {
    LoadBalancer.instance.startHealthChecks();
  }
  static final ApiClient instance = ApiClient._internal();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'myvault_jwt';

  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final d = Dio(BaseOptions(
      baseUrl: LoadBalancer.instance.getOptimalBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // 1. Load Balancer & JWT Header Interceptor
    d.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final optimalBase = LoadBalancer.instance.getOptimalBaseUrl();
        options.baseUrl = optimalBase;

        final token = await _storage.read(key: _tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final uriStr = response.requestOptions.uri.toString();
        LoadBalancer.instance.recordRequestSuccess(uriStr, 45);
        handler.next(response);
      },
      onError: (err, handler) {
        final uriStr = err.requestOptions.uri.toString();
        LoadBalancer.instance.recordRequestFailure(uriStr);
        handler.next(err);
      },
    ));

    // 2. Exponential Backoff Retry Interceptor
    d.interceptors.add(NetworkRetryInterceptor(dio: d, maxRetries: 3));

    return d;
  }

  Future<String> getBaseUrl() async => LoadBalancer.instance.getOptimalBaseUrl();
  Future<void> setBaseUrl(String url) async {}

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
