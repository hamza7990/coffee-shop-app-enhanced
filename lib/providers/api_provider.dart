// lib/providers/api_provider.dart
// ─────────────────────────────────────────────────────────────
// Riverpod providers for the API layer.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_client.dart';
import '../data/api_repository.dart';
import '../data/auth_repository.dart';
import '../data/order_repository.dart';
import '../utils/app_config.dart';
import 'local_storage_provider.dart';
import 'auth_provider.dart';

/// The base API client – override in main() to customize the base URL.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: AppConfig.apiUrl,
    onUnauthorized: () {
      ref.read(authProvider.notifier).logout();
    },
  );
});

/// Repository that wraps the client with typed model methods.
final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return ApiRepository(ref.read(apiClientProvider));
});

/// Auth Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider), ref.read(localStorageProvider));
});

/// Order Repository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(apiClientProvider), ref.read(localStorageProvider));
});
