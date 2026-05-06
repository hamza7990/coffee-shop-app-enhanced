import 'package:flutter/material.dart';
import 'shared_dashboard_layout.dart';
import 'dashboard_screen.dart';
import 'tables_screen.dart';
import 'orders_screen.dart';
import 'menu_screen.dart';
import 'analytics_screen.dart';
import 'users_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SharedDashboardLayout(
      title: 'Admin Dashboard',
      items: [
        NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, screen: DashboardScreen()),
        NavItem(label: 'Users', icon: Icons.group_outlined, activeIcon: Icons.group, screen: UsersManagementScreen()),
        NavItem(label: 'Tables', icon: Icons.table_restaurant_outlined, activeIcon: Icons.table_restaurant, screen: TablesScreen()),
        NavItem(label: 'Orders', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, screen: OrdersScreen()),
        NavItem(label: 'Menu', icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu, screen: MenuScreen()),
        NavItem(label: 'Analytics', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, screen: AnalyticsScreen()),
      ],
    );
  }
}
