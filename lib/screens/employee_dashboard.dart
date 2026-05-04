import 'package:flutter/material.dart';
import 'shared_dashboard_layout.dart';
import 'dashboard_screen.dart';
import 'tables_screen.dart';
import 'orders_screen.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SharedDashboardLayout(
      title: 'Employee Dashboard',
      items: [
        NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, screen: DashboardScreen()),
        NavItem(label: 'Tables', icon: Icons.table_restaurant_outlined, activeIcon: Icons.table_restaurant, screen: TablesScreen()),
        NavItem(label: 'Orders', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, screen: OrdersScreen()),
      ],
    );
  }
}
