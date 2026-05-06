// lib/core/config.dart
// ─────────────────────────────────────────────────────────────
// Centralized API configuration with environment switching.
// Toggle [env] between [Environment.dev] and [Environment.prod].
// ─────────────────────────────────────────────────────────────

enum Environment { dev, prod }

class Config {
  static Environment env = Environment.prod;

  static String get baseUrl {
    switch (env) {
      case Environment.dev:
        return "http://10.0.2.2:8080";
      case Environment.prod:
        return "http://34.42.89.195:8080";
    }
  }

  /// Full API base URL including the `/api` path prefix.
  static String get apiBaseUrl => "$baseUrl/api";
}
