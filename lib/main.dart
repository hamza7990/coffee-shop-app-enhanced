import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/local_storage_provider.dart';
import 'providers/api_provider.dart';
import 'data/local_storage_repository.dart';
import 'data/api_client.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/manager_dashboard.dart';
import 'screens/employee_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final repo = await LocalStorageRepository.init();
  final apiClient = ApiClient();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(repo),
        apiClientProvider.overrideWithValue(apiClient),
      ],
      child: const BrewhausApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!loggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (loggedIn && isLoggingIn) {
        final role = authState.role;
        if (role == 'Admin') return '/admin';
        if (role == 'Manager') return '/manager';
        if (role == 'User') return '/employee';
        return '/login'; // Fallback
      }

      // Protect routes based on roles
      if (state.matchedLocation.startsWith('/admin') && authState.role != 'Admin') return '/login';
      if (state.matchedLocation.startsWith('/manager') && authState.role != 'Manager') return '/login';
      if (state.matchedLocation.startsWith('/employee') && authState.role != 'User') return '/login';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(key: ValueKey('login')),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerDashboard(),
      ),
      GoRoute(
        path: '/employee',
        builder: (context, state) => const EmployeeDashboard(),
      ),
    ],
  );
});

class BrewhausApp extends ConsumerWidget {
  const BrewhausApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Brewhaus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
