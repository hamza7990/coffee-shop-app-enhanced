import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage_provider.dart';

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Load saved theme from local storage, default to light mode
    final savedTheme = ref.read(localStorageProvider).loadThemeMode();
    return savedTheme ?? false;
  }

  void toggleTheme() {
    state = !state;
    // Persist the theme change
    ref.read(localStorageProvider).saveThemeMode(state);
  }

  void setDarkMode(bool isDark) {
    state = isDark;
    ref.read(localStorageProvider).saveThemeMode(isDark);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});
