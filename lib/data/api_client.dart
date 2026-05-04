// lib/data/api_client.dart
// ─────────────────────────────────────────────────────────────
// Centralized HTTP client for all REST API calls.
// Handles headers, timeouts, error mapping, auth tokens, and ApiResponse wrapper using Dio.
// ─────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';

/// Custom exception thrown for all API errors.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
}

/// Thrown when there is no network connectivity.
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Backend API response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String> errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors = const [],
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: (json['errors'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class ApiClient {
  final String baseUrl;
  final void Function()? onUnauthorized;
  final void Function()? onForbidden;
  late final Dio _dio;
  String? _authToken;

  ApiClient({
    required this.baseUrl,
    this.onUnauthorized,
    this.onForbidden,
    Dio? dio,
  }) {
    _dio = dio ?? Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    );
  }

  // ── Auth ────────────────────────────────────────────────────
  void setAuthToken(String? token) => _authToken = token;
  String? get authToken => _authToken;
  bool get isAuthenticated => _authToken != null;

  // ── GET ─────────────────────────────────────────────────────
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    return _safeRequest(() => _dio.get(path, queryParameters: queryParams));
  }

  // ── POST ────────────────────────────────────────────────────
  Future<dynamic> post(String path, {dynamic body}) async {
    return _safeRequest(() => _dio.post(path, data: body));
  }

  // ── PUT ─────────────────────────────────────────────────────
  Future<dynamic> put(String path, {dynamic body}) async {
    return _safeRequest(() => _dio.put(path, data: body));
  }

  // ── PATCH ───────────────────────────────────────────────────
  Future<dynamic> patch(String path, {dynamic body}) async {
    return _safeRequest(() => _dio.patch(path, data: body));
  }

  // ── DELETE ──────────────────────────────────────────────────
  Future<dynamic> delete(String path) async {
    return _safeRequest(() => _dio.delete(path));
  }

  // ── Internals ───────────────────────────────────────────────
  Future<dynamic> _safeRequest(Future<Response> Function() request) async {
    try {
      final response = await request();
      return _handleResponse(response);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException('Unable to reach the server. Check your connection.');
      }
      
      if (e.response != null) {
        if (e.response!.statusCode == 401) onUnauthorized?.call();
        if (e.response!.statusCode == 403) onForbidden?.call();
        return _handleResponse(e.response!);
      }
      
      throw NetworkException('Request failed: ${e.message}');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Unexpected error: $e');
    }
  }

  dynamic _handleResponse(Response response) {
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      if (response.data == null || response.data == '') return null;

      if (response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;

        // Handle ApiResponse wrapper format if present
        if (body.containsKey('success') && body.containsKey('data')) {
          final success = body['success'] as bool? ?? false;
          final message = body['message'] as String? ?? 'Unknown error';

          if (!success) {
            throw ApiException(response.statusCode!, message);
          }

          return body['data'];
        }
      }
      
      // Return raw body if not wrapped or not a map
      return response.data;
    }

    // Try to extract error message from JSON body
    String message;
    try {
      if (response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;
        message = body['message'] ?? body['error'] ?? 'Unknown error';
      } else {
        message = response.statusMessage ?? 'Request failed';
      }
    } catch (_) {
      message = response.statusMessage ?? 'Request failed';
    }

    throw ApiException(response.statusCode ?? 500, message);
  }

  void dispose() => _dio.close();
}
