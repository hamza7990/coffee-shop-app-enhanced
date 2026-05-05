// lib/screens/users_management_screen.dart
// ─────────────────────────────────────────────────────────────
// Admin user management: list, roles, lock, delete.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../providers/admin_users_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/async_widgets.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUsersProvider.notifier).fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminUsersProvider.notifier).fetchUsers(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Management',
                        style: AppTextStyles.displayStyle(ctx: context, size: 24)),
                    const SizedBox(height: 4),
                    Text('Manage roles, lock accounts, and deactivate users.',
                        style: AppTextStyles.muted(context)),
                  ],
                ),
              ),
            ),
            if (state.successMessage != null)
              SliverToBoxAdapter(
                child: _MessageBanner(
                  message: state.successMessage!,
                  isError: false,
                  onDismiss: () => ref.read(adminUsersProvider.notifier).clearMessages(),
                ),
              ),
            if (state.errorMessage != null)
              SliverToBoxAdapter(
                child: _MessageBanner(
                  message: state.errorMessage!,
                  isError: true,
                  onDismiss: () => ref.read(adminUsersProvider.notifier).clearMessages(),
                ),
              ),
            if (state.isLoading && state.users.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.users.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No users found.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = state.users[index];
                      return _UserCard(
                        user: user,
                        onMakeAdmin: () => _confirmAction(
                          title: 'Promote to Admin?',
                          body: 'This will give ${user.name} full admin privileges.',
                          confirmText: 'Make Admin',
                          onConfirm: () => ref
                              .read(adminUsersProvider.notifier)
                              .updateUserRole(user.id, AppUserRole.admin),
                        ),
                        onMakeManager: () => _confirmAction(
                          title: 'Promote to Manager?',
                          body: 'This will give ${user.name} manager privileges.',
                          confirmText: 'Make Manager',
                          onConfirm: () => ref
                              .read(adminUsersProvider.notifier)
                              .updateUserRole(user.id, AppUserRole.manager),
                        ),
                        onDemote: () => _confirmAction(
                          title: 'Remove elevated role?',
                          body: 'This will set ${user.name} back to a standard User.',
                          confirmText: 'Demote',
                          onConfirm: () => ref
                              .read(adminUsersProvider.notifier)
                              .updateUserRole(user.id, AppUserRole.user),
                        ),
                        onToggleLock: () => _confirmAction(
                          title: user.isLocked ? 'Unlock Account?' : 'Lock Account?',
                          body: user.isLocked
                              ? '${user.name} will be able to log in again.'
                              : '${user.name} will be temporarily prevented from logging in.',
                          confirmText: user.isLocked ? 'Unlock' : 'Lock',
                          onConfirm: () => ref
                              .read(adminUsersProvider.notifier)
                              .lockUser(user.id, lock: !user.isLocked),
                        ),
                        onDelete: () => _confirmAction(
                          title: 'Deactivate ${user.name}?',
                          body: 'This user will no longer be able to log in. You can only do this if at least one other admin remains.',
                          confirmText: 'Deactivate',
                          isDanger: true,
                          onConfirm: () => ref
                              .read(adminUsersProvider.notifier)
                              .deleteUser(user.id),
                        ),
                      );
                    },
                    childCount: state.users.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAction({
    required String title,
    required String body,
    required String confirmText,
    required VoidCallback onConfirm,
    bool isDanger = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text(title, style: AppTextStyles.title(context, size: 18)),
        content: Text(body, style: AppTextStyles.body(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    if (confirmed == true) onConfirm();
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onMakeAdmin;
  final VoidCallback onMakeManager;
  final VoidCallback onDemote;
  final VoidCallback onToggleLock;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onMakeAdmin,
    required this.onMakeManager,
    required this.onDemote,
    required this.onToggleLock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color roleColor;
    switch (user.role) {
      case AppUserRole.admin:
        roleColor = AppColors.error;
        break;
      case AppUserRole.manager:
        roleColor = AppColors.info;
        break;
      case AppUserRole.user:
        roleColor = AppColors.success;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  foregroundColor: roleColor,
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: AppTextStyles.title(context, size: 15)),
                      const SizedBox(height: 2),
                      Text(user.email,
                          style: AppTextStyles.muted(context, size: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (!user.isActive || user.isLocked) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (!user.isActive)
                    _StatusChip(
                      label: 'Deactivated',
                      color: AppColors.error,
                      isDark: isDark,
                    ),
                  if (user.isLocked) ...[
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Locked',
                      color: AppColors.warning,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Joined ${DateFormat.yMMMd().format(user.createdAt)}',
              style: AppTextStyles.caption(context),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user.role != AppUserRole.admin)
                  _ActionChip(
                    label: 'Make Admin',
                    icon: Icons.admin_panel_settings,
                    color: AppColors.error,
                    onTap: onMakeAdmin,
                  ),
                if (user.role != AppUserRole.manager)
                  _ActionChip(
                    label: 'Make Manager',
                    icon: Icons.manage_accounts,
                    color: AppColors.info,
                    onTap: onMakeManager,
                  ),
                if (user.role != AppUserRole.user)
                  _ActionChip(
                    label: 'Make User',
                    icon: Icons.person_outline,
                    color: AppColors.success,
                    onTap: onDemote,
                  ),
                _ActionChip(
                  label: user.isLocked ? 'Unlock' : 'Lock',
                  icon: user.isLocked ? Icons.lock_open : Icons.lock_outline,
                  color: AppColors.warning,
                  onTap: onToggleLock,
                ),
                _ActionChip(
                  label: 'Deactivate',
                  icon: Icons.delete_outline,
                  color: AppColors.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _StatusChip({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onPressed: onTap,
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _MessageBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    final bg = isError ? AppColors.errorLight : AppColors.successLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: color, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
