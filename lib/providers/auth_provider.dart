// lib/providers/auth_provider.dart
// ─────────────────────────────────────────────────────────────
// Auth state + notifier – wired to API login endpoint.
// Falls back to local demo mode if API is unreachable.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_client.dart';
import 'api_provider.dart';
import 'local_storage_provider.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
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
    final storage = ref.read(localStorageProvider);
    final savedToken = storage.loadAuthToken();

    if (savedToken != null && savedToken.isNotEmpty) {
      // Restore the token to API client
      ref.read(apiClientProvider).setAuthToken(savedToken);
      // Mark as logged in (token exists)
      state = state.copyWith(isLoggedIn: true);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final api = ref.read(apiRepositoryProvider);

    try {
      final result = await api.login(email, password);
      // Save token to local storage for auto-login
      final token = result['token'] as String?;
      if (token != null) {
        await ref.read(localStorageProvider).saveAuthToken(token);
      }
      state = state.copyWith(isLoggedIn: true, isLoading: false);
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

    final api = ref.read(apiRepositoryProvider);

    try {
      final result = await api.register(name, email, password);
      // Save token to local storage for auto-login
      final token = result['token'] as String?;
      if (token != null) {
        await ref.read(localStorageProvider).saveAuthToken(token);
      }
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        successMessage: 'Registration successful! Welcome to Brewhaus.',
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } on NetworkException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Server unreachable. Please check your connection.',
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

    final api = ref.read(apiRepositoryProvider);

    try {
      await api.forgotPassword(email);
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
        errorMessage: 'Server unreachable. Please check your connection.',
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

    final api = ref.read(apiRepositoryProvider);

    try {
      await api.resetPassword(token, newPassword);
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
        errorMessage: 'Server unreachable. Please check your connection.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password reset failed. The link may have expired.',
      );
    }
  }

  void logout() async {
    ref.read(apiClientProvider).setAuthToken(null);
    await ref.read(localStorageProvider).clearAuthToken();
    state = const AuthState(isLoggedIn: false);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
