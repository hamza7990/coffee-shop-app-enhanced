// lib/providers/api_provider.dart
// ─────────────────────────────────────────────────────────────
// Riverpod providers for the API layer.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_client.dart';
import '../data/api_repository.dart';

/// The base API client – override in main() to customize the base URL.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: 'http://localhost:5000/api');
});

/// Repository that wraps the client with typed model methods.
final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return ApiRepository(ref.read(apiClientProvider));
});
