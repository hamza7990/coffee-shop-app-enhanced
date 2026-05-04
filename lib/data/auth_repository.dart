// lib/data/auth_repository.dart
import 'api_client.dart';
import 'local_storage_repository.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final LocalStorageRepository _localStorage;

  const AuthRepository(this._apiClient, this._localStorage);

  Future<void> checkSavedToken() async {
    final savedToken = await _localStorage.loadAuthToken();
    if (savedToken != null && savedToken.isNotEmpty) {
      _apiClient.setAuthToken(savedToken);
    }
  }

  Future<void> login(String email, String password) async {
    final data = await _apiClient.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final token = data['token'] as String?;
    if (token != null) {
      _apiClient.setAuthToken(token);
      await _localStorage.saveAuthToken(token);
    }
  }

  Future<void> register(String name, String email, String password) async {
    final data = await _apiClient.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': 'Employee',
    });
    final token = data['token'] as String?;
    if (token != null) {
      _apiClient.setAuthToken(token);
      await _localStorage.saveAuthToken(token);
    }
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.post('/auth/forgot-password', body: {
      'email': email,
    });
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _apiClient.post('/auth/reset-password', body: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() async {
    _apiClient.setAuthToken(null);
    await _localStorage.clearAuthToken();
  }
}
