// lib/data/sample_data.dart
// ─────────────────────────────────────────────────────────────
// Hard-coded seed data used to initialise providers.
// In production these would come from your REST API / database.
// ─────────────────────────────────────────────────────────────

import '../models/menu_item.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';

// ── Menu ──────────────────────────────────────────────────────
final List<MenuItem> seedMenu = [
  const MenuItem(id: 'm1',  name: 'Espresso',        category: MenuCategory.coffee,     price: 3.50, icon: '☕'),
  const MenuItem(id: 'm2',  name: 'Cappuccino',       category: MenuCategory.coffee,     price: 4.80, icon: '☕'),
  const MenuItem(id: 'm3',  name: 'Flat White',       category: MenuCategory.coffee,     price: 4.50, icon: '☕'),
  const MenuItem(id: 'm4',  name: 'Caramel Latte',    category: MenuCategory.coffee,     price: 5.20, icon: '☕'),
  const MenuItem(id: 'm5',  name: 'Cold Brew',        category: MenuCategory.coldDrinks, price: 5.50, icon: '🧊'),
  const MenuItem(id: 'm6',  name: 'Iced Matcha Latte',category: MenuCategory.coldDrinks, price: 5.80, icon: '🍵'),
  const MenuItem(id: 'm7',  name: 'Mango Smoothie',   category: MenuCategory.coldDrinks, price: 6.20, icon: '🥭'),
  const MenuItem(id: 'm8',  name: 'Tiramisu',         category: MenuCategory.desserts,   price: 6.50, icon: '🍰'),
  const MenuItem(id: 'm9',  name: 'Cheesecake',       category: MenuCategory.desserts,   price: 5.80, icon: '🍰'),
  const MenuItem(id: 'm10', name: 'Chocolate Brownie',category: MenuCategory.desserts,   price: 4.50, icon: '🍫'),
  const MenuItem(id: 'm11', name: 'Croissant',        category: MenuCategory.snacks,     price: 3.80, icon: '🥐'),
  const MenuItem(id: 'm12', name: 'Club Sandwich',    category: MenuCategory.snacks,     price: 8.50, icon: '🥪'),
  const MenuItem(id: 'm13', name: 'Avocado Toast',    category: MenuCategory.snacks,     price: 9.00, icon: '🥑'),
];

// ── Tables ────────────────────────────────────────────────────
final List<CoffeeTable> seedTables = [
  const CoffeeTable(id: 1,  name: 'Table 1',  seats: 2, status: TableStatus.available),
  const CoffeeTable(id: 2,  name: 'Table 2',  seats: 2, status: TableStatus.available),
  const CoffeeTable(id: 3,  name: 'Table 3',  seats: 4, status: TableStatus.occupied,  activeOrderId: 'act-1'),
  const CoffeeTable(id: 4,  name: 'Table 4',  seats: 4, status: TableStatus.reserved),
  const CoffeeTable(id: 5,  name: 'Table 5',  seats: 4, status: TableStatus.available),
  const CoffeeTable(id: 6,  name: 'Table 6',  seats: 6, status: TableStatus.occupied,  activeOrderId: 'act-2'),
  const CoffeeTable(id: 7,  name: 'Table 7',  seats: 6, status: TableStatus.available),
  const CoffeeTable(id: 8,  name: 'Table 8',  seats: 2, status: TableStatus.available),
  const CoffeeTable(id: 9,  name: 'Table 9',  seats: 4, status: TableStatus.occupied,  activeOrderId: 'act-3'),
  const CoffeeTable(id: 10, name: 'Table 10', seats: 4, status: TableStatus.available),
  const CoffeeTable(id: 11, name: 'Table 11', seats: 6, status: TableStatus.reserved),
  const CoffeeTable(id: 12, name: 'Table 12', seats: 2, status: TableStatus.available),
];

// ── Active Orders ─────────────────────────────────────────────
final List<Order> seedActiveOrders = [
  Order(
    id: 'act-1', tableId: 3,
    items: [
      const OrderItem(menuItemId: 'm2', quantity: 2),
      const OrderItem(menuItemId: 'm8', quantity: 1),
    ],
  ),
  Order(
    id: 'act-2', tableId: 6,
    items: [
      const OrderItem(menuItemId: 'm4', quantity: 1, note: 'oat milk'),
      const OrderItem(menuItemId: 'm11', quantity: 2),
    ],
  ),
  Order(
    id: 'act-3', tableId: 9,
    items: [
      const OrderItem(menuItemId: 'm5', quantity: 3),
    ],
  ),
];

// ── Completed Orders ──────────────────────────────────────────
final List<Order> seedCompletedOrders = [
  Order(
    id: 'ORD-001', tableId: 3,
    items: [
      const OrderItem(menuItemId: 'm2', quantity: 2),
      const OrderItem(menuItemId: 'm8', quantity: 1),
    ],
    status: OrderStatus.completed, paymentMethod: PaymentMethod.card,
    total: 16.10, completedTime: '09:15',
  ),
  Order(
    id: 'ORD-002', tableId: 6,
    items: [
      const OrderItem(menuItemId: 'm1', quantity: 3),
      const OrderItem(menuItemId: 'm11', quantity: 2),
    ],
    status: OrderStatus.completed, paymentMethod: PaymentMethod.cash,
    total: 18.10, completedTime: '09:32',
  ),
  Order(
    id: 'ORD-003', tableId: 9,
    items: [
      const OrderItem(menuItemId: 'm4', quantity: 1),
      const OrderItem(menuItemId: 'm13', quantity: 1),
    ],
    status: OrderStatus.completed, paymentMethod: PaymentMethod.card,
    total: 14.20, completedTime: '10:05',
  ),
  Order(
    id: 'ORD-004', tableId: 3,
    items: [
      const OrderItem(menuItemId: 'm5', quantity: 2),
      const OrderItem(menuItemId: 'm10', quantity: 2),
    ],
    status: OrderStatus.completed, paymentMethod: PaymentMethod.cash,
    total: 20.00, completedTime: '10:45',
  ),
  Order(
    id: 'ORD-005', tableId: 6,
    items: [
      const OrderItem(menuItemId: 'm6', quantity: 1),
      const OrderItem(menuItemId: 'm9', quantity: 1),
    ],
    status: OrderStatus.completed, paymentMethod: PaymentMethod.card,
    total: 11.60, completedTime: '11:20',
  ),
];

// ── Analytics helpers ─────────────────────────────────────────
class DayRevenue {
  final String day;
  final double revenue;
  final int orders;
  const DayRevenue(this.day, this.revenue, this.orders);
}

class HourRevenue {
  final String hour;
  final double revenue;
  const HourRevenue(this.hour, this.revenue);
}

final List<DayRevenue> seedWeekly = [
  const DayRevenue('Mon', 380, 22),
  const DayRevenue('Tue', 510, 30),
  const DayRevenue('Wed', 430, 26),
  const DayRevenue('Thu', 620, 38),
  const DayRevenue('Fri', 780, 47),
  const DayRevenue('Sat', 940, 58),
  const DayRevenue('Sun', 860, 52),
];

final List<HourRevenue> seedHourly = [
  const HourRevenue('7am', 30),
  const HourRevenue('8am', 85),
  const HourRevenue('9am', 140),
  const HourRevenue('10am', 175),
  const HourRevenue('11am', 210),
  const HourRevenue('12pm', 195),
  const HourRevenue('1pm', 165),
  const HourRevenue('2pm', 130),
  const HourRevenue('3pm', 110),
  const HourRevenue('4pm', 90),
  const HourRevenue('5pm', 70),
  const HourRevenue('6pm', 45),
];
