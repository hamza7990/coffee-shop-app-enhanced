// lib/data/api_repository.dart
// ─────────────────────────────────────────────────────────────
// Repository that translates API JSON responses into typed
// domain models. Acts as the single gateway between the
// data/network layer and the provider/logic layer.
//
// Note: Backend returns ApiResponse<T> wrapper, extracted in ApiClient.
// ─────────────────────────────────────────────────────────────

import '../models/coffee_table.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import 'api_client.dart';

class ApiRepository {
  final ApiClient _client;

  const ApiRepository(this._client);

  // ── Auth ────────────────────────────────────────────────────
  /// Returns `{ 'token': '...', 'user': { ... } }` on success.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final token = data['token'] as String?;
    if (token != null) {
      _client.setAuthToken(token);
    }
    return data as Map<String, dynamic>;
  }

  /// Register new user and returns auth response with token.
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final data = await _client.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': 'Cashier',
    });
    final token = data['token'] as String?;
    if (token != null) {
      _client.setAuthToken(token);
    }
    return data as Map<String, dynamic>;
  }

  /// Request password reset email.
  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', body: {
      'email': email,
    });
  }

  /// Reset password with token.
  Future<void> resetPassword(String token, String newPassword) async {
    await _client.post('/auth/reset-password', body: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  void logout() => _client.setAuthToken(null);

  // ── Tables ──────────────────────────────────────────────────
  Future<List<CoffeeTable>> fetchTables() async {
    final data = await _client.get('/tables');
    final list = data as List<dynamic>;
    return list
        .map((e) => CoffeeTable.fromApiJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CoffeeTable> createTable(String tableNumber, int capacity) async {
    final data = await _client.post('/tables', body: {
      'tableNumber': tableNumber,
      'capacity': capacity,
    });
    return CoffeeTable.fromApiJson(data as Map<String, dynamic>);
  }

  Future<void> deleteTable(int tableId) async {
    await _client.delete('/tables/$tableId');
  }

  Future<CoffeeTable> updateTableStatus(
      int tableId, TableStatus status, {String? activeOrderId, bool clearOrder = false}) async {
    // Backend expects PascalCase enum: Available, Occupied, Reserved
    final statusStr = status.name[0].toUpperCase() + status.name.substring(1);
    final data = await _client.patch('/tables/$tableId/status', body: {
      'status': statusStr,
    });
    return CoffeeTable.fromApiJson(data as Map<String, dynamic>);
  }

  // ── Menu ────────────────────────────────────────────────────
  /// Fetch menu items from /menu/items endpoint (returns PagedResult)
  Future<List<MenuItem>> fetchMenu() async {
    final data = await _client.get('/menu/items', queryParams: {
      'pageSize': '1000',
    });
    // Backend returns PagedResult { items, totalCount, page, pageSize }
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => MenuItem.fromApiJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MenuItem> createMenuItem(MenuItem item) async {
    final data = await _client.post('/menu/items', body: item.toApiJson());
    return MenuItem.fromApiJson(data as Map<String, dynamic>);
  }

  Future<MenuItem> updateMenuItem(MenuItem item) async {
    final data = await _client.put('/menu/items/${item.id}', body: item.toApiJson());
    return MenuItem.fromApiJson(data as Map<String, dynamic>);
  }

  Future<void> deleteMenuItem(String id) async {
    await _client.delete('/menu/items/$id');
  }

  // ── Orders ──────────────────────────────────────────────────
  /// Fetch orders from /orders endpoint (returns PagedResult)
  Future<List<Order>> fetchOrders({OrderStatus? status}) async {
    final query = <String, String>{
      'pageSize': '1000',
    };
    if (status != null) query['status'] = status.name;

    final data = await _client.get('/orders', queryParams: query);
    // Backend returns PagedResult { items, totalCount, page, pageSize }
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => Order.fromApiJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> createOrder(int tableId, List<OrderItem> items) async {
    final data = await _client.post('/orders', body: {
      'tableId': tableId,
      'type': 'DineIn',
      'items': items.map((i) => i.toApiJson()).toList(),
    });
    return Order.fromApiJson(data as Map<String, dynamic>);
  }

  Future<Order> updateOrder(String orderId, List<OrderItem> items) async {
    // Note: Backend uses PATCH /orders/{id}/status for status updates
    // Full order updates not directly supported - items handled separately
    final order = await _client.get('/orders/$orderId');
    return Order.fromApiJson(order as Map<String, dynamic>);
  }

  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    final data = await _client.patch('/orders/$orderId/status', body: {
      'status': status.name,
    });
    return Order.fromApiJson(data as Map<String, dynamic>);
  }

  Future<Order> completeOrder(
      String orderId, PaymentMethod method, double total) async {
    // Backend uses status updates; marking as Delivered/Completed
    final data = await _client.patch('/orders/$orderId/status', body: {
      'status': 'Delivered',
    });
    return Order.fromApiJson(data as Map<String, dynamic>);
  }

  Future<void> deleteOrder(String orderId) async {
    await _client.delete('/orders/$orderId');
  }
}
