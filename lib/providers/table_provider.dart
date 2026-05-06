// lib/providers/table_provider.dart
// ─────────────────────────────────────────────────────────────
// AsyncNotifier for tables – fetches from API, falls back to
// local cache, then seed data. All mutations are optimistic
// with API sync.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_table.dart';
import '../data/sample_data.dart';
import '../data/api_client.dart';
import 'api_provider.dart';
import 'local_storage_provider.dart';

class TableNotifier extends AsyncNotifier<List<CoffeeTable>> {
  @override
  Future<List<CoffeeTable>> build() async {
    return _fetchTables();
  }

  Future<List<CoffeeTable>> _fetchTables() async {
    final api = ref.read(apiRepositoryProvider);
    final repo = ref.read(localStorageProvider);

    try {
      final tables = await api.fetchTables();
      // Cache the fresh data
      repo.saveTables(tables);
      return tables;
    } on NetworkException {
      // Offline – try cache
      return _fallbackToCache(repo);
    } on ApiException {
      return _fallbackToCache(repo);
    }
  }

  List<CoffeeTable> _fallbackToCache(dynamic repo) {
    final cached = repo.loadTables();
    if (cached != null && cached.isNotEmpty) return cached;
    return List.from(seedTables);
  }

  /// Pull-to-refresh / manual refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchTables());
  }

  // ── Read Helpers ──────────────────────────────────────────
  CoffeeTable? findById(int id) {
    final data = state.value;
    if (data == null) return null;
    try {
      return data.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  int get occupiedCount =>
      state.value?.where((t) => t.status == TableStatus.occupied).length ?? 0;

  int get availableCount =>
      state.value?.where((t) => t.status == TableStatus.available).length ?? 0;

  int get reservedCount =>
      state.value?.where((t) => t.status == TableStatus.reserved).length ?? 0;

  // ── Write ─────────────────────────────────────────────────
  Future<void> setStatus(int id, TableStatus status) async {
    final previous = state.value;
    if (previous == null) return;

    // Optimistic update
    _updateLocal(id, (t) => t.copyWith(status: status));

    try {
      await ref.read(apiRepositoryProvider).updateTableStatus(id, status);
    } catch (_) {
      // Silently fail - keep optimistic local state for offline mode
    }
  }

  Future<void> addTable(String name, int seats) async {
    final api = ref.read(apiRepositoryProvider);

    try {
      final newTable = await api.createTable(name, seats);
      final current = state.value ?? [];
      state = AsyncData([...current, newTable]);
      ref.read(localStorageProvider).saveTables([...current, newTable]);
    } catch (e) {
      // If API fails, add local placeholder
      final current = state.value ?? [];
      final localId = (current.isEmpty ? 0 : current.map((t) => t.id).reduce((a, b) => a > b ? a : b)) + 1;
      final local = CoffeeTable(id: localId, name: name, seats: seats);
      state = AsyncData([...current, local]);
      ref.read(localStorageProvider).saveTables([...current, local]);
      rethrow;
    }
  }

  Future<void> deleteTable(int id) async {
    final current = state.value;
    if (current == null) return;

    // Optimistic removal
    final updated = current.where((t) => t.id != id).toList();
    state = AsyncData(updated);
    ref.read(localStorageProvider).saveTables(updated);

    try {
      await ref.read(apiRepositoryProvider).deleteTable(id);
    } catch (_) {
      // Revert on failure
      state = AsyncData(current);
      ref.read(localStorageProvider).saveTables(current);
    }
  }

  Future<void> assignOrder(int tableId, String orderId) async {
    final previous = state.value;
    if (previous == null) return;

    _updateLocal(tableId, (t) => t.copyWith(
          status: TableStatus.occupied,
          activeOrderId: orderId,
        ));

    try {
      await ref.read(apiRepositoryProvider)
          .updateTableStatus(tableId, TableStatus.occupied, activeOrderId: orderId);
    } catch (_) {
      // Silently fail - keep optimistic local state for offline mode
    }
  }

  Future<void> freeTable(int tableId) async {
    final previous = state.value;
    if (previous == null) return;

    _updateLocal(tableId, (t) => t.copyWith(
          status: TableStatus.available,
          clearOrder: true,
        ));

    try {
      await ref.read(apiRepositoryProvider)
          .updateTableStatus(tableId, TableStatus.available, clearOrder: true);
    } catch (_) {
      // Silently fail - keep optimistic local state for offline mode
    }
  }

  void _updateLocal(int id, CoffeeTable Function(CoffeeTable) fn) {
    final current = state.value;
    if (current == null) return;

    final newState = [
      for (final table in current)
        if (table.id == id) fn(table) else table
    ];
    state = AsyncData(newState);
    ref.read(localStorageProvider).saveTables(newState);
  }
}

final tableProvider =
    AsyncNotifierProvider<TableNotifier, List<CoffeeTable>>(() {
  return TableNotifier();
});
