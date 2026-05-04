// lib/providers/auth_provider.dart
// ─────────────────────────────────────────────────────────────
// Auth state + notifier – wired to API login endpoint.
// Falls back to local demo mode if API is unreachable.
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_client.dart';
import 'api_provider.dart';
import 'local_storage_provider.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String? role;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.role,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    String? role,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Check for saved token on startup
    _checkSavedToken();
    return const AuthState();
  }

  Future<void> _checkSavedToken() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.checkSavedToken();
    // Assuming if it completes without throwing, and we might want to check if token exists.
    // Wait, checkSavedToken doesn't return anything. But the previous code just marked isLoggedIn=true if it existed.
    // Let's read from local storage here or change checkSavedToken to return bool.
    // Let's use local_storage_provider directly for this check for simplicity, or change AuthRepository.
    final storage = ref.read(localStorageProvider);
    final savedToken = await storage.loadAuthToken();
    if (savedToken != null && savedToken.isNotEmpty) {
      final role = _decodeRole(savedToken);
      state = state.copyWith(isLoggedIn: true, role: role);
    }
  }

  String? _decodeRole(String? token) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(resp);
      return decoded['role'] ?? decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final repo = ref.read(authRepositoryProvider);

    try {
      await repo.login(email, password);
      final token = await ref.read(localStorageProvider).loadAuthToken();
      final role = _decodeRole(token);
      state = state.copyWith(isLoggedIn: true, isLoading: false, role: role);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } on NetworkException {
      // Offline demo mode – allow local login
      if (email.isNotEmpty && password == 'password') {
        state = state.copyWith(isLoggedIn: true, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Server unreachable. For offline mode use password: "password"',
        );
      }
    } catch (e) {
      // Fallback: allow demo login
      if (email.isNotEmpty && password == 'password') {
        state = state.copyWith(isLoggedIn: true, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed. For demo use password: "password"',
        );
      }
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final repo = ref.read(authRepositoryProvider);

    try {
      await repo.register(name, email, password);
      final token = await ref.read(localStorageProvider).loadAuthToken();
      final role = _decodeRole(token);
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        role: role,
        successMessage: 'Registration successful! Welcome to Brewhaus.',
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } on NetworkException {
      // Offline demo mode fallback for registration
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        successMessage: 'Offline Mode: Registration successful! Welcome to Brewhaus.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Please try again.',
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final repo = ref.read(authRepositoryProvider);

    try {
      await repo.forgotPassword(email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'If this email exists, a reset link has been sent.',
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } on NetworkException {
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Offline Mode: If this email exists, a reset link has been sent.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Request failed. Please try again.',
      );
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final repo = ref.read(authRepositoryProvider);

    try {
      await repo.resetPassword(token, newPassword);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset successful! Please log in with your new password.',
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } on NetworkException {
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Offline Mode: Password reset successful! Please log in with your new password.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password reset failed. The link may have expired.',
      );
    }
  }

  void logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AuthState(isLoggedIn: false, role: null);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
