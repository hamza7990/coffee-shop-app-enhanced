// lib/providers/order_provider.dart
// ─────────────────────────────────────────────────────────────
// AsyncNotifier for orders – API-first with local cache
// fallback. Manages active + completed orders.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../data/api_client.dart';
import 'api_provider.dart';
import 'local_storage_provider.dart';

class OrderState {
  final List<Order> active;
  final List<Order> completed;
  final int counter;

  const OrderState({
    required this.active,
    required this.completed,
    required this.counter,
  });

  OrderState copyWith({
    List<Order>? active,
    List<Order>? completed,
    int? counter,
  }) {
    return OrderState(
      active: active ?? this.active,
      completed: completed ?? this.completed,
      counter: counter ?? this.counter,
    );
  }
}

class OrderNotifier extends AsyncNotifier<OrderState> {
  @override
  Future<OrderState> build() async {
    return _fetchOrders();
  }

  Future<OrderState> _fetchOrders() async {
    final repo = ref.read(orderRepositoryProvider);
    
    final active = await repo.fetchActiveOrders();
    final completed = await repo.fetchCompletedOrders();

    return OrderState(
      active: active,
      completed: completed,
      counter: completed.length + 1,
    );
  }

  /// Pull-to-refresh / manual refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchOrders());
  }

  // ── Read Helpers ────────────────────────────────────────────
  Order? findActive(String id) {
    final data = state.value;
    if (data == null) return null;
    try {
      return data.active.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  double getOrderTotal(String orderId, MenuItem? Function(String) menuLookup) {
    final order = findActive(orderId);
    if (order == null) return 0;
    return _calcTotal(order.items, menuLookup);
  }

  double _calcTotal(List<OrderItem> items, MenuItem? Function(String) menuLookup) {
    return items.fold(0, (sum, item) {
      final m = menuLookup(item.menuItemId);
      return sum + (m?.price ?? 0) * item.quantity;
    });
  }

  // ── Create ──────────────────────────────────────────────────
  Future<String> createOrder(int tableId, List<OrderItem> items) async {
    final repo = ref.read(orderRepositoryProvider);
    final localRepo = ref.read(localStorageProvider);

    try {
      // Create via API – server assigns the ID
      final newOrder = await repo.createOrder(tableId, items);

      final current = state.value;
      if (current != null) {
        final updatedActive = [...current.active, newOrder];
        state = AsyncData(current.copyWith(active: updatedActive));
        localRepo.saveActiveOrders(updatedActive);
      }
      return newOrder.id;
    } on NetworkException {
      // Offline fallback – create locally
      return _createLocal(tableId, items, localRepo);
    } on ApiException {
      return _createLocal(tableId, items, localRepo);
    }
  }

  String _createLocal(int tableId, List<OrderItem> items, dynamic localRepo) {
    final id = 'act-${DateTime.now().millisecondsSinceEpoch}';
    final newOrder = Order(id: id, tableId: tableId, items: items);

    final current = state.value;
    if (current != null) {
      final updatedActive = [...current.active, newOrder];
      state = AsyncData(current.copyWith(active: updatedActive));
      localRepo.saveActiveOrders(updatedActive);
    }
    return id;
  }

  // ── Update Items ────────────────────────────────────────────
  Future<void> addItemToOrder(String orderId, OrderItem newItem) async {
    _updateActiveLocal(orderId, (o) {
      final existing = o.items.indexWhere((i) => i.menuItemId == newItem.menuItemId);
      if (existing != -1) {
        final updated = List<OrderItem>.from(o.items);
        updated[existing] = updated[existing].copyWith(
          quantity: updated[existing].quantity + newItem.quantity,
        );
        return o.copyWith(items: updated);
      }
      return o.copyWith(items: [...o.items, newItem]);
    });

    // Sync to API in background
    _syncOrderItems(orderId);
  }

  void updateItemQty(String orderId, String menuItemId, int qty) {
    _updateActiveLocal(orderId, (o) {
      final updated = o.items
          .map((i) => i.menuItemId == menuItemId ? i.copyWith(quantity: qty) : i)
          .where((i) => i.quantity > 0)
          .toList();
      return o.copyWith(items: updated);
    });

    // Sync to API in background
    _syncOrderItems(orderId);
  }

  Future<void> _syncOrderItems(String orderId) async {
    final order = findActive(orderId);
    if (order == null) return;

    try {
      await ref.read(orderRepositoryProvider).updateOrderItems(orderId, order.items);
    } catch (_) {
      // Silently fail – local state is already updated
    }
  }

  // ── Complete ────────────────────────────────────────────────
  Future<Order> completeOrder(
    String orderId,
    PaymentMethod method,
    MenuItem? Function(String) menuLookup,
  ) async {
    final repo = ref.read(orderRepositoryProvider);
    final localRepo = ref.read(localStorageProvider);
    final current = state.value;

    final order = findActive(orderId)!;
    final total = _calcTotal(order.items, menuLookup);

    try {
      final completed = await repo.completeOrder(orderId, method, total);

      if (current != null) {
        final updatedActive = current.active.where((o) => o.id != orderId).toList();
        final updatedCompleted = [...current.completed, completed];
        state = AsyncData(current.copyWith(
          active: updatedActive,
          completed: updatedCompleted,
          counter: current.counter + 1,
        ));
        localRepo.saveActiveOrders(updatedActive);
        localRepo.saveCompletedOrders(updatedCompleted);
      }
      return completed;
    } on NetworkException {
      return _completeLocal(orderId, method, total, order, current, localRepo);
    } on ApiException {
      return _completeLocal(orderId, method, total, order, current, localRepo);
    }
  }

  Order _completeLocal(
    String orderId,
    PaymentMethod method,
    double total,
    Order order,
    OrderState? current,
    dynamic localRepo,
  ) {
    final completed = order.copyWith(
      id: 'ORD-${(current?.counter ?? 1).toString().padLeft(3, '0')}',
      status: OrderStatus.completed,
      paymentMethod: method,
      total: total,
      completedAt: DateTime.now(),
      completedTime: DateFormat('HH:mm').format(DateTime.now()),
    );

    if (current != null) {
      final updatedActive = current.active.where((o) => o.id != orderId).toList();
      final updatedCompleted = [...current.completed, completed];
      state = AsyncData(current.copyWith(
        active: updatedActive,
        completed: updatedCompleted,
        counter: current.counter + 1,
      ));
      localRepo.saveActiveOrders(updatedActive);
      localRepo.saveCompletedOrders(updatedCompleted);
    }
    return completed;
  }

  // ── Internal ────────────────────────────────────────────────
  void _updateActiveLocal(String id, Order Function(Order) fn) {
    final current = state.value;
    if (current == null) return;

    final updatedActive = [
      for (final order in current.active)
        if (order.id == id) fn(order) else order
    ];

    state = AsyncData(current.copyWith(active: updatedActive));
    ref.read(localStorageProvider).saveActiveOrders(updatedActive);
  }
}

final orderProvider = AsyncNotifierProvider<OrderNotifier, OrderState>(() {
  return OrderNotifier();
});
