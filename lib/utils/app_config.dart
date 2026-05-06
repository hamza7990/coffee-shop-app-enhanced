// lib/utils/app_config.dart

import '../core/config.dart';

class AppConfig {
  /// Base API URL including the `/api` path prefix.
  /// Reads from [Config.apiBaseUrl] for centralized environment switching.
  static String get apiUrl => Config.apiBaseUrl;
}
