// lib/data/order_repository.dart
import '../models/order.dart';
import 'api_client.dart';
import 'local_storage_repository.dart';

class OrderRepository {
  final ApiClient _apiClient;
  final LocalStorageRepository _localStorage;

  const OrderRepository(this._apiClient, this._localStorage);

  Future<List<Order>> fetchActiveOrders() async {
    try {
      // Fetch non-terminal orders (Pending, Preparing, Ready)
      final data = await _apiClient.get('/orders', queryParams: {'pageSize': '1000'});
      final items = data['items'] as List<dynamic>? ?? [];
      final orders = items
          .map((e) => Order.fromApiJson(e as Map<String, dynamic>))
          .where((o) => o.status == OrderStatus.active)
          .toList();
      await _localStorage.saveActiveOrders(orders);
      return orders;
    } catch (_) {
      return _localStorage.loadActiveOrders() ?? [];
    }
  }

  Future<List<Order>> fetchCompletedOrders() async {
    try {
      // Fetch delivered orders from backend
      final data = await _apiClient.get('/orders', queryParams: {
        'pageSize': '1000',
        'status': 'Delivered',
      });
      final items = data['items'] as List<dynamic>? ?? [];
      final orders = items.map((e) => Order.fromApiJson(e as Map<String, dynamic>)).toList();
      await _localStorage.saveCompletedOrders(orders);
      return orders;
    } catch (_) {
      return _localStorage.loadCompletedOrders() ?? [];
    }
  }

  Future<Order> createOrder(int tableId, List<OrderItem> items) async {
    final data = await _apiClient.post('/orders', body: {
      'tableId': tableId,
      'type': 'DineIn',
      'items': items.map((i) => i.toApiJson()).toList(),
    });
    return Order.fromApiJson(data as Map<String, dynamic>);
  }

  Future<Order> updateOrderItems(String orderId, List<OrderItem> items) async {
    final data = await _apiClient.get('/orders/$orderId'); // Placeholder for proper update
    return Order.fromApiJson(data as Map<String, dynamic>);
  }

  Future<Order> completeOrder(String orderId, PaymentMethod method, double total) async {
    final data = await _apiClient.patch('/orders/$orderId/status', body: {
      'status': 'Delivered',
    });
    return Order.fromApiJson(data as Map<String, dynamic>);
  }
}
