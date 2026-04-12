// lib/data/api_client.dart
// ─────────────────────────────────────────────────────────────
// Centralized HTTP client for all REST API calls.
// Handles headers, timeouts, error mapping, auth tokens, and ApiResponse wrapper.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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
  final http.Client _client;
  final Duration timeout;
  String? _authToken;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  // ── Auth ────────────────────────────────────────────────────
  void setAuthToken(String? token) => _authToken = token;
  String? get authToken => _authToken;
  bool get isAuthenticated => _authToken != null;

  // ── Headers ─────────────────────────────────────────────────
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ── GET ─────────────────────────────────────────────────────
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = _buildUri(path, queryParams);
    final response = await _safeRequest(() =>
        _client.get(uri, headers: _headers).timeout(timeout));
    return _handleResponse(response);
  }

  // ── POST ────────────────────────────────────────────────────
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await _safeRequest(() =>
        _client.post(uri, headers: _headers, body: jsonEncode(body ?? {})).timeout(timeout));
    return _handleResponse(response);
  }

  // ── PUT ─────────────────────────────────────────────────────
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await _safeRequest(() =>
        _client.put(uri, headers: _headers, body: jsonEncode(body ?? {})).timeout(timeout));
    return _handleResponse(response);
  }

  // ── PATCH ───────────────────────────────────────────────────
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await _safeRequest(() =>
        _client.patch(uri, headers: _headers, body: jsonEncode(body ?? {})).timeout(timeout));
    return _handleResponse(response);
  }

  // ── DELETE ──────────────────────────────────────────────────
  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    final response = await _safeRequest(() =>
        _client.delete(uri, headers: _headers).timeout(timeout));
    return _handleResponse(response);
  }

  // ── Internals ───────────────────────────────────────────────
  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final fullPath = '$baseUrl$path';
    final uri = Uri.parse(fullPath);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<http.Response> _safeRequest(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on SocketException {
      throw const NetworkException('Unable to reach the server. Check your connection.');
    } on HttpException {
      throw const NetworkException('HTTP error occurred.');
    } on FormatException {
      throw const ApiException(0, 'Invalid response format.');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Request failed: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // Handle ApiResponse wrapper format
      if (body.containsKey('success') && body.containsKey('data')) {
        final success = body['success'] as bool? ?? false;
        final message = body['message'] as String? ?? 'Unknown error';

        if (!success) {
          throw ApiException(response.statusCode, message);
        }

        return body['data'];
      }

      // Return raw body if not wrapped
      return body;
    }

    // Try to extract error message from JSON body
    String message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] ?? body['error'] ?? 'Unknown error';
    } catch (_) {
      message = response.reasonPhrase ?? 'Request failed';
    }

    throw ApiException(response.statusCode, message);
  }

  void dispose() => _client.close();
}
