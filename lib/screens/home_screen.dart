import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'tables_screen.dart';
import 'orders_screen.dart';
import 'menu_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final _navItems = const [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined,     activeIcon: Icons.dashboard),
    _NavItem(label: 'Tables',    icon: Icons.table_restaurant_outlined, activeIcon: Icons.table_restaurant),
    _NavItem(label: 'Orders',    icon: Icons.receipt_long_outlined,   activeIcon: Icons.receipt_long),
    _NavItem(label: 'Menu',      icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu),
    _NavItem(label: 'Analytics', icon: Icons.bar_chart_outlined,      activeIcon: Icons.bar_chart),
  ];

  final _screens = const [
    DashboardScreen(),
    TablesScreen(),
    OrdersScreen(),
    MenuScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useSidebar = width >= 800; 
    
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      appBar: !useSidebar ? AppBar(
        title: Text(_navItems[_selectedIndex].label, style: AppTextStyles.title(context)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ) : null,
      body: Row(
        children: [
          if (useSidebar) _SideBar(
            items: _navItems,
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: useSidebar ? null : _BottomBar(
        items: _navItems,
        selectedIndex: _selectedIndex,
        onSelect: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class _SideBar extends ConsumerWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _SideBar({required this.items, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final sidebarBg = isDark ? AppColors.sidebarDark : AppColors.sidebarLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      width: 260,
      color: sidebarBg,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.coffee, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Brewhaus', style: AppTextStyles.displayStyle(ctx: context, size: 20)),
                    Text('POS System', style: AppTextStyles.muted(context, size: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 12),
                    child: Text('MAIN MENU', style: AppTextStyles.label(context)),
                  ),
                  ...items.asMap().entries.map((e) => _SidebarTile(
                        item: e.value,
                        selected: selectedIndex == e.key,
                        onTap: () => onSelect(e.key),
                      )),
                ],
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: [
                _SidebarActionTile(
                  icon: isDark ? Icons.light_mode : Icons.dark_mode,
                  label: isDark ? 'Light Mode' : 'Dark Mode',
                  onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                ),
                _SidebarActionTile(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  onTap: () => ref.read(authProvider.notifier).logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = cs.primary;
    final inactiveColor = cs.onSurface.withOpacity(0.6);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(selected ? item.activeIcon : item.icon,
                size: 20, color: selected ? activeColor : inactiveColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? activeColor : inactiveColor,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SidebarActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 20, color: cs.onSurface.withOpacity(0.6)),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontSize: 15, fontFamily: 'Inter', fontWeight: FontWeight.w500, color: cs.onSurface.withOpacity(0.7))),
        ]),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _BottomBar({required this.items, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onSelect,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Inter', fontSize: 12),
      items: items.map((e) => BottomNavigationBarItem(icon: Icon(e.icon), activeIcon: Icon(e.activeIcon), label: e.label)).toList(),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem({required this.label, required this.icon, required this.activeIcon});
}