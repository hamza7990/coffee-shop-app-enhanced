// lib/models/app_user.dart
// ─────────────────────────────────────────────────────────────
// User model for admin user management.
// ─────────────────────────────────────────────────────────────

enum AppUserRole { user, manager, admin }

class AppUser {
  final int id;
  final String name;
  final String email;
  final AppUserRole role;
  final bool isActive;
  final DateTime? lockedUntil;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.lockedUntil,
    required this.createdAt,
  });

  factory AppUser.fromApiJson(Map<String, dynamic> json) {
    AppUserRole parseRole(String? r) {
      switch (r?.toLowerCase()) {
        case 'admin':
          return AppUserRole.admin;
        case 'manager':
          return AppUserRole.manager;
        default:
          return AppUserRole.user;
      }
    }

    return AppUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: parseRole(json['role'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      lockedUntil: json['lockedUntil'] != null
          ? DateTime.tryParse(json['lockedUntil'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String get roleLabel {
    switch (role) {
      case AppUserRole.admin:
        return 'Admin';
      case AppUserRole.manager:
        return 'Manager';
      case AppUserRole.user:
        return 'User';
    }
  }

  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now().toUtc());
}
