import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that automatically retries requests on transient network failures
/// using exponential backoff (e.g. timeouts, connection drops, socket errors).
class NetworkRetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;

  NetworkRetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 1000),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final int retryCount = (extra['retry_count'] as int?) ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      final nextRetry = retryCount + 1;
      final delay = initialDelay * (1 << (nextRetry - 1)); // 1s, 2s, 4s

      debugPrint('[NetworkRetry] Request failed (${err.type}). Retrying ($nextRetry/$maxRetries) in ${delay.inMilliseconds}ms for ${err.requestOptions.uri}');

      await Future.delayed(delay);

      final newOptions = err.requestOptions;
      newOptions.extra['retry_count'] = nextRetry;

      try {
        final response = await dio.fetch(newOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return super.onError(retryErr, handler);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        return status != null && (status == 429 || status == 502 || status == 503 || status == 504);
      default:
        return false;
    }
  }
}
