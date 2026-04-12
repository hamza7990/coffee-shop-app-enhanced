// lib/models/order.dart
// ─────────────────────────────────────────────────────────────
// Order and OrderItem models.
//
// OrderItem  – one line inside an order (menuItemId, qty, note)
// Order      – full order with a list of OrderItems
// ─────────────────────────────────────────────────────────────

enum OrderStatus { active, completed }
enum PaymentMethod { cash, card }

class OrderItem {
  final String menuItemId;
  final int quantity;
  final String note;

  const OrderItem({
    required this.menuItemId,
    this.quantity = 1,
    this.note = '',
  });

  OrderItem copyWith({String? menuItemId, int? quantity, String? note}) =>
      OrderItem(
        menuItemId: menuItemId ?? this.menuItemId,
        quantity: quantity ?? this.quantity,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItemId,
        'quantity': quantity,
        'note': note,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        menuItemId: json['menuItemId'] as String,
        quantity: json['quantity'] as int? ?? 1,
        note: json['note'] as String? ?? '',
      );

  /// Convert from backend API format (OrderItemDto)
  /// Backend uses: Id, MenuItemId, MenuItemName, Quantity, UnitPrice, SubTotal, Notes
  factory OrderItem.fromApiJson(Map<String, dynamic> json) => OrderItem(
        menuItemId: json['menuItemId']?.toString() ?? json['MenuItemId']?.toString() ?? '0',
        quantity: json['quantity'] as int? ?? json['Quantity'] as int? ?? 1,
        note: json['notes'] as String? ?? json['Notes'] as String? ?? '',
      );

  /// Convert to backend CreateOrderItemRequest format
  Map<String, dynamic> toApiJson() => {
        'menuItemId': int.tryParse(menuItemId) ?? 0,
        'quantity': quantity,
        'notes': note,
      };
}

class Order {
  final String id;
  final int tableId;
  final List<OrderItem> items;
  final OrderStatus status;
  final PaymentMethod? paymentMethod;
  final double? total;          // set when completed
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? completedTime;  // human-readable "HH:mm"

  Order({
    required this.id,
    required this.tableId,
    required this.items,
    this.status = OrderStatus.active,
    this.paymentMethod,
    this.total,
    DateTime? createdAt,
    this.completedAt,
    this.completedTime,
  }) : createdAt = createdAt ?? DateTime.now();

  Order copyWith({
    String? id,
    int? tableId,
    List<OrderItem>? items,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    double? total,
    DateTime? completedAt,
    String? completedTime,
  }) =>
      Order(
        id: id ?? this.id,
        tableId: tableId ?? this.tableId,
        items: items ?? this.items,
        status: status ?? this.status,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        total: total ?? this.total,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
        completedTime: completedTime ?? this.completedTime,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableId': tableId,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'paymentMethod': paymentMethod?.name,
        'total': total,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'completedTime': completedTime,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        tableId: json['tableId'] as int,
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        status: OrderStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => OrderStatus.active),
        paymentMethod: json['paymentMethod'] != null
            ? PaymentMethod.values.firstWhere(
                (e) => e.name == json['paymentMethod'],
                orElse: () => PaymentMethod.cash)
            : null,
        total: (json['total'] as num?)?.toDouble(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        completedTime: json['completedTime'] as String?,
      );

  /// Convert from backend API format (OrderDto)
  /// Backend uses: Id, OrderNumber, Status, Type, TotalAmount, CreatedAt, TableId, Items, etc.
  factory Order.fromApiJson(Map<String, dynamic> json) => Order(
        id: json['orderNumber'] as String? ?? json['OrderNumber'] as String? ?? json['id']?.toString() ?? '0',
        tableId: json['tableId'] as int? ?? json['TableId'] as int? ?? 0,
        items: (json['items'] as List<dynamic>? ?? json['Items'] as List<dynamic>?)
                ?.map((i) => OrderItem.fromApiJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        status: _parseOrderStatus(json['status'] as String? ?? json['Status'] as String? ?? 'Pending'),
        paymentMethod: null, // Backend doesn't include this in list view
        total: (json['totalAmount'] as num? ?? json['TotalAmount'] as num?)?.toDouble(),
        createdAt: json['createdAt'] != null || json['CreatedAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String? ?? json['CreatedAt'] as String? ?? '')
            : DateTime.now(),
        completedAt: null,
        completedTime: null,
      );

  /// Convert to backend CreateOrderRequest format
  Map<String, dynamic> toOrderApiJson() => {
        'tableId': tableId,
        'type': 'DineIn',
        'items': items.map((i) => i.toApiJson()).toList(),
      };

  static OrderStatus _parseOrderStatus(String status) {
    switch (status) {
      case 'Pending':
      case 'Preparing':
        return OrderStatus.active;
      case 'Ready':
      case 'Delivered':
        return OrderStatus.completed;
      case 'Cancelled':
      default:
        return OrderStatus.active;
    }
  }
}
