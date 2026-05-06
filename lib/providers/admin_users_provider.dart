// lib/providers/admin_users_provider.dart
// ─────────────────────────────────────────────────────────────
// State management for the admin user management screen.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../data/api_client.dart';
import 'api_provider.dart';

class AdminUsersState {
  final List<AppUser> users;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AdminUsersState copyWith({
    List<AppUser>? users,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AdminUsersNotifier extends Notifier<AdminUsersState> {
  @override
  AdminUsersState build() {
    return const AdminUsersState();
  }

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final client = ref.read(apiClientProvider);
    try {
      final data = await client.get('/users') as List<dynamic>;
      final users = data.map((e) => AppUser.fromApiJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(isLoading: false, users: users);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load users.');
    }
  }

  Future<void> updateUserRole(int id, AppUserRole role) async {
    state = state.copyWith(clearError: true, clearSuccess: true);

    final client = ref.read(apiClientProvider);
    try {
      await client.patch('/users/$id/role', body: {
        'role': role.name[0].toUpperCase() + role.name.substring(1),
      });
      await fetchUsers();
      state = state.copyWith(
        successMessage: 'Role updated to ${role.name}.',
      );
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update role.');
    }
  }

  Future<void> lockUser(int id, {bool lock = true, int? minutes}) async {
    state = state.copyWith(clearError: true, clearSuccess: true);

    final client = ref.read(apiClientProvider);
    try {
      await client.patch('/users/$id/lock', body: {
        'lock': lock,
        if (minutes != null) 'minutes': minutes,
      });
      await fetchUsers();
      state = state.copyWith(
        successMessage: lock ? 'User locked.' : 'User unlocked.',
      );
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update lock status.');
    }
  }

  Future<void> deleteUser(int id) async {
    state = state.copyWith(clearError: true, clearSuccess: true);

    final client = ref.read(apiClientProvider);
    try {
      await client.delete('/users/$id');
      await fetchUsers();
      state = state.copyWith(
        successMessage: 'User deactivated.',
      );
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to deactivate user.');
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final adminUsersProvider = NotifierProvider<AdminUsersNotifier, AdminUsersState>(() {
  return AdminUsersNotifier();
});
