// lib/models/coffee_table.dart
// ─────────────────────────────────────────────────────────────
// Represents a physical table in the coffee shop.
// Named CoffeeTable to avoid conflict with Flutter's Table widget.
// ─────────────────────────────────────────────────────────────

enum TableStatus { available, occupied, reserved }

extension TableStatusExt on TableStatus {
  String get label {
    switch (this) {
      case TableStatus.available: return 'Available';
      case TableStatus.occupied:  return 'Occupied';
      case TableStatus.reserved:  return 'Reserved';
    }
  }
}

class CoffeeTable {
  final int id;
  final String name;
  final int seats;
  final TableStatus status;
  final String? activeOrderId; // null when not occupied

  const CoffeeTable({
    required this.id,
    required this.name,
    required this.seats,
    this.status = TableStatus.available,
    this.activeOrderId,
  });

  CoffeeTable copyWith({
    int? id,
    String? name,
    int? seats,
    TableStatus? status,
    String? activeOrderId,
    bool clearOrder = false,
  }) =>
      CoffeeTable(
        id: id ?? this.id,
        name: name ?? this.name,
        seats: seats ?? this.seats,
        status: status ?? this.status,
        activeOrderId: clearOrder ? null : (activeOrderId ?? this.activeOrderId),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'seats': seats,
        'status': status.name,
        'activeOrderId': activeOrderId,
      };

  factory CoffeeTable.fromJson(Map<String, dynamic> json) => CoffeeTable(
        id: json['id'] as int,
        name: json['name'] as String,
        seats: json['seats'] as int,
        status: TableStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => TableStatus.available),
        activeOrderId: json['activeOrderId'] as String?,
      );

  /// Convert from backend API format (TableDto)
  /// Backend uses: Id, TableNumber, Capacity, Status, QrCode
  factory CoffeeTable.fromApiJson(Map<String, dynamic> json) => CoffeeTable(
        id: json['id'] as int? ?? json['Id'] as int? ?? 0,
        name: json['tableNumber'] as String? ?? json['TableNumber'] as String? ?? 'T${json['id'] ?? json['Id'] ?? 0}',
        seats: json['capacity'] as int? ?? json['Capacity'] as int? ?? 2,
        status: _parseTableStatus(json['status'] as String? ?? json['Status'] as String? ?? 'Available'),
        activeOrderId: json['activeOrderId'] as String? ?? json['ActiveOrderId'] as String?,
      );

  /// Convert to backend API format
  Map<String, dynamic> toApiJson() => {
        'tableNumber': name,
        'capacity': seats,
      };

  static TableStatus _parseTableStatus(String status) {
    switch (status) {
      case 'Available':
        return TableStatus.available;
      case 'Occupied':
        return TableStatus.occupied;
      case 'Reserved':
        return TableStatus.reserved;
      default:
        return TableStatus.available;
    }
  }
}
