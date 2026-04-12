// lib/utils/extensions.dart
// ─────────────────────────────────────────────────────────────
// Safe collection extensions to prevent crashes and duplicates.
// ─────────────────────────────────────────────────────────────

import '../models/menu_item.dart';
import '../models/order.dart';

/// Safe list extensions
extension SafeList<T> on List<T> {
  /// Safely finds first element matching predicate, returns null if not found.
  /// Replaces firstWhere with orElse pattern.
  T? firstWhereOrNull(bool Function(T) predicate) {
    for (final item in this) {
      if (predicate(item)) return item;
    }
    return null;
  }

  /// Safely gets element at index, returns null if out of bounds.
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Removes duplicates based on a key extractor function.
  List<T> distinctBy<K>(K Function(T) keyExtractor) {
    final seen = <K>{};
    return where((item) {
      final key = keyExtractor(item);
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }
}

/// Order item duplicate prevention helper
extension OrderItemList on List<OrderItem> {
  /// Adds or updates an item in the list.
  /// If item with same menuItemId exists, increments quantity.
  /// Otherwise adds new item.
  List<OrderItem> addOrUpdateItem(OrderItem newItem) {
    final index = indexWhere((i) => i.menuItemId == newItem.menuItemId);
    if (index != -1) {
      // Update existing
      final updated = List<OrderItem>.from(this);
      updated[index] = this[index].copyWith(
        quantity: this[index].quantity + newItem.quantity,
      );
      return updated;
    }
    // Add new
    return [...this, newItem];
  }

  /// Updates quantity for an item. Removes if quantity <= 0.
  List<OrderItem> updateQuantity(String menuItemId, int newQuantity) {
    if (newQuantity <= 0) {
      return where((i) => i.menuItemId != menuItemId).toList();
    }
    return map((i) =>
      i.menuItemId == menuItemId ? i.copyWith(quantity: newQuantity) : i
    ).toList();
  }
}

/// Menu item helper extensions
extension MenuItemList on List<MenuItem> {
  /// Safely finds menu item by ID.
  MenuItem? findById(String id) {
    return firstWhereOrNull((m) => m.id == id);
  }

  /// Gets items by category.
  List<MenuItem> byCategory(MenuCategory category) {
    return where((m) => m.category == category).toList();
  }

  /// Gets only enabled items.
  List<MenuItem> get enabled => where((m) => m.enabled).toList();
}

/// String validation extensions
extension StringValidation on String? {
  /// Checks if string is null or empty.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Checks if string is not null and not empty.
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
