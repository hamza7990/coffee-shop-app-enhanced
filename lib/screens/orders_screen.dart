// lib/screens/orders_screen.dart
// ─────────────────────────────────────────────────────────────
// Two tabs: Active orders (cards with qty controls + pay button)
//           Completed orders (data table)
// Tapping "Pay" opens PaymentSheet bottom sheet.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import '../providers/menu_provider.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/async_widgets.dart';
import '../utils/extensions.dart';
import 'new_order_sheet.dart';
import 'payment_sheet.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider);
    final cs     = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;
    final hPadding = isWide ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: orderAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading orders…'),
        error: (e, _) => ErrorDisplay(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderProvider),
        ),
        data: (orders) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPadding, 28, hPadding, 0),
              child: SectionHeader(
                title: 'Orders',
                subtitle: 'Track and manage all orders',
                action: AppButton(
                  label: 'New Order',
                  icon: Icons.add,
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const NewOrderSheet(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tabs
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'Active (${orders.active.length})'),
                    Tab(text: 'Completed (${orders.completed.length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ActiveOrdersTab(orders: orders.active, hPadding: hPadding),
                  _CompletedOrdersTab(orders: orders.completed, hPadding: hPadding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active Orders Tab ─────────────────────────────────────────
class _ActiveOrdersTab extends StatelessWidget {
  final List<Order> orders;
  final double hPadding;
  const _ActiveOrdersTab({required this.orders, required this.hPadding});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    int cols = 1; 
    double ratio = 1.3; 

    if (width >= 1000) {
      cols = 3;
      ratio = 0.85;
    } else if (width >= 600) {
      cols = 2;
      ratio = 0.85;
    }

    if (orders.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, size: 60, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text('No active orders', style: AppTextStyles.muted(context)),
      ]));
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: ratio, 
      ),
      itemCount: orders.length,
      itemBuilder: (_, i) => _ActiveOrderCard(order: orders[i]),
    );
  }
}

class _ActiveOrderCard extends ConsumerWidget {
  final Order order;
  const _ActiveOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    final cs        = Theme.of(context).colorScheme;
    
    // Safely get menu data
    final menuItems = menuAsync.value ?? [];
    
    // Use safe extension to find menu items
    MenuItem? findMenuItem(String id) => menuItems.findById(id);

    final total = order.items.fold<double>(0, (s, i) {
      final m = findMenuItem(i.menuItemId);
      return s + (m?.price ?? 0) * i.quantity;
    });

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outline))),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text('Table ${order.tableId}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              ]),
              const Spacer(),
              Text('\$${total.toStringAsFixed(2)}',
                  style: AppTextStyles.displayStyle(ctx: context, size: 20, color: cs.primary)),
            ]),
          ),

          // Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: order.items.map((oi) {
                final mi = findMenuItem(oi.menuItemId);
                if (mi == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Text(mi.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(mi.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('\$${mi.price.toStringAsFixed(2)} ea.',
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                    ])),
                    // Qty controls
                    _SmallQtyBtn(icon: Icons.remove, onTap: () {
                      ref.read(orderProvider.notifier).updateItemQty(order.id, mi.id, oi.quantity - 1);
                    }),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('${oi.quantity}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    _SmallQtyBtn(icon: Icons.add, onTap: () {
                      ref.read(orderProvider.notifier).updateItemQty(order.id, mi.id, oi.quantity + 1);
                    }),
                    const SizedBox(width: 8),
                    SizedBox(width: 48, child: Text('\$${(mi.price * oi.quantity).toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  ]),
                );
              }).toList(),
            ),
          ),

          // Footer buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Expanded(child: AppButton(
                label: '+ Item', small: true, outlined: true,
                onPressed: () => showModalBottomSheet(
                  context: context, isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => NewOrderSheet(preselectedTableId: order.tableId),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: AppButton(
                label: 'Pay \$${total.toStringAsFixed(2)}', small: true,
                onPressed: () => showModalBottomSheet(
                  context: context, isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => PaymentSheet(orderId: order.id),
                ),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Completed Orders Tab ──────────────────────────────────────
class _CompletedOrdersTab extends StatelessWidget {
  final List<Order> orders;
  final double hPadding;
  const _CompletedOrdersTab({required this.orders, required this.hPadding});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(cs.outline.withValues(alpha: 0.3)),
              columns: const [
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Table')),
                DataColumn(label: Text('Items')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('Status')),
              ],
              rows: orders.map((o) => DataRow(cells: [
                DataCell(Text(o.id, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text('Table ${o.tableId}')),
                DataCell(Text('${o.items.length} items')),
                DataCell(Text('\$${o.total?.toStringAsFixed(2) ?? '—'}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary))),
                DataCell(Row(children: [
                  Text(o.paymentMethod == PaymentMethod.card ? '💳' : '💵'),
                  const SizedBox(width: 4),
                  StatusBadge(
                    label: o.paymentMethod == PaymentMethod.card ? 'Card' : 'Cash',
                    color: o.paymentMethod == PaymentMethod.card
                        ? (isDark ? AppColors.infoDark : AppColors.info)
                        : AppColors.success,
                    bg: o.paymentMethod == PaymentMethod.card
                        ? (isDark ? AppColors.infoDarkBg : AppColors.infoLight)
                        : (isDark ? AppColors.successDarkBg : AppColors.successLight),
                  ),
                ])),
                DataCell(Text(o.completedTime ?? '—')),
                DataCell(StatusBadge(label: '✓ Done', color: AppColors.success,
                    bg: isDark ? AppColors.successDarkBg : AppColors.successLight)),
              ])).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallQtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallQtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Icon(icon, size: 12),
    ),
  );
}