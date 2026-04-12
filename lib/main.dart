import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/local_storage_provider.dart';
import 'providers/api_provider.dart';
import 'data/local_storage_repository.dart';
import 'data/api_client.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final repo = await LocalStorageRepository.init();
  final apiClient = ApiClient(baseUrl: 'http://localhost:5000/api');

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

class BrewhausApp extends ConsumerWidget {
  const BrewhausApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Brewhaus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: authState.isLoggedIn
            ? const HomeScreen(key: ValueKey('home'))
            : const LoginScreen(key: ValueKey('login')),
      ),
    );
  }
}
