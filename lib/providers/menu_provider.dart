// lib/providers/menu_provider.dart
// ─────────────────────────────────────────────────────────────
// AsyncNotifier for menu items – fetches from API, falls back
// to seed data. Supports CRUD operations.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import '../data/sample_data.dart';
import '../data/api_client.dart';
import 'api_provider.dart';

class MenuNotifier extends AsyncNotifier<List<MenuItem>> {
  @override
  Future<List<MenuItem>> build() async {
    return _fetchMenu();
  }

  Future<List<MenuItem>> _fetchMenu() async {
    final api = ref.read(apiRepositoryProvider);

    try {
      return await api.fetchMenu();
    } on NetworkException {
      return List.from(seedMenu);
    } on ApiException {
      return List.from(seedMenu);
    }
  }

  /// Pull-to-refresh / manual refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchMenu());
  }

  // ── Read Helpers ──────────────────────────────────────────────────
  List<MenuItem> itemsForCategory(MenuCategory cat) =>
      (state.value ?? []).where((m) => m.category == cat).toList();

  List<MenuItem> get enabledItems =>
      (state.value ?? []).where((m) => m.enabled).toList();

  MenuItem? findById(String id) {
    final data = state.value;
    if (data == null) return null;
    try {
      return data.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Write ─────────────────────────────────────────────────
  Future<void> addItem(MenuItem item) async {
    final current = state.value;
    if (current == null) return;

    // Optimistic update
    state = AsyncData([...current, item]);

    try {
      await ref.read(apiRepositoryProvider).createMenuItem(item);
    } catch (_) {
      // Keep local state even on API failure
    }
  }

  Future<void> updateItem(MenuItem updated) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData([
      for (final item in current)
        if (item.id == updated.id) updated else item
    ]);

    try {
      await ref.read(apiRepositoryProvider).updateMenuItem(updated);
    } catch (_) {
      // Keep local state
    }
  }

  Future<void> deleteItem(String id) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.where((item) => item.id != id).toList());

    try {
      await ref.read(apiRepositoryProvider).deleteMenuItem(id);
    } catch (_) {
      // Keep local state
    }
  }

  void toggleItem(String id) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData([
      for (final item in current)
        if (item.id == id) item.copyWith(enabled: !item.enabled) else item
    ]);
  }
}

final menuProvider = AsyncNotifierProvider<MenuNotifier, List<MenuItem>>(() {
  return MenuNotifier();
});
