// lib/providers/dashboard_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order_provider.dart';
import 'menu_provider.dart';
import 'table_provider.dart';
import '../models/menu_item.dart';
import '../utils/extensions.dart';

class DashboardStats {
  final double totalRevenue;
  final double avgOrderValue;
  final int occupancyPercentage;
  final List<({MenuItem? item, int qty})> popularItems;

  const DashboardStats({
    required this.totalRevenue,
    required this.avgOrderValue,
    required this.occupancyPercentage,
    required this.popularItems,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final orderAsync = ref.watch(orderProvider);
  final menuAsync = ref.watch(menuProvider);
  final tableAsync = ref.watch(tableProvider);

  // If any provider is not loaded, return zero-ed stats
  if (orderAsync.value == null || menuAsync.value == null || tableAsync.value == null) {
    return const DashboardStats(
      totalRevenue: 0.0,
      avgOrderValue: 0.0,
      occupancyPercentage: 0,
      popularItems: [],
    );
  }

  final orders = orderAsync.value!;
  final menuItems = menuAsync.value!;
  final tableList = tableAsync.value!;
  final tableProv = ref.read(tableProvider.notifier); // Safely reading notifier for occupiedCount

  MenuItem? findMenuItem(String id) => menuItems.findById(id);

  final completed = orders.completed;
  final totalRev = completed.fold<double>(0, (s, o) => s + (o.total ?? 0));
  final avgOrder = completed.isEmpty ? 0.0 : totalRev / completed.length;
  
  final occupancy = tableList.isEmpty
      ? 0
      : (tableProv.occupiedCount / tableList.length * 100).round();

  final Map<String, int> counts = {};
  for (final o in completed) {
    for (final i in o.items) {
      counts[i.menuItemId] = (counts[i.menuItemId] ?? 0) + i.quantity;
    }
  }
  
  final popular = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
    
  final top5 = popular.take(5).map((e) {
    final item = findMenuItem(e.key);
    return (item: item, qty: e.value);
  }).where((e) => e.item != null).toList();

  return DashboardStats(
    totalRevenue: totalRev,
    avgOrderValue: avgOrder,
    occupancyPercentage: occupancy,
    popularItems: top5,
  );
});
