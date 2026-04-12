// lib/screens/tables_screen.dart
// ─────────────────────────────────────────────────────────────
// Displays all tables in a responsive grid.
// Each card shows status, seat count, and context actions.
// Opening a new order delegates to NewOrderSheet (bottom sheet).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/table_provider.dart';
import '../providers/order_provider.dart';
import '../providers/menu_provider.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/async_widgets.dart';
import 'new_order_sheet.dart';
import '../utils/extensions.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableAsync = ref.watch(tableProvider);
    final cs         = Theme.of(context).colorScheme;
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    
    // Get screen width for responsive design
    final isWide = MediaQuery.of(context).size.width > 600;

    return tableAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading tables…'),
      error: (e, _) => ErrorDisplay(
        message: e.toString(),
        onRetry: () => ref.invalidate(tableProvider),
      ),
      data: (tableList) {
        final tableProv = ref.read(tableProvider.notifier);
        final orderAsync = ref.watch(orderProvider);
        final menuAsync  = ref.watch(menuProvider);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Table Management', subtitle: 'Manage table status and assignments'),
              const SizedBox(height: 24),

              // ── Summary ────────────────────────────────────────
              // Use horizontal scroll on narrow screens to prevent overflow
              isWide 
                ? Row(children: [
                    Expanded(child: _SummaryTile(label: 'Available', count: tableProv.availableCount,
                        color: AppColors.success, bg: isDark ? AppColors.successDarkBg : AppColors.successLight, icon: Icons.check_circle_outline)),
                    const SizedBox(width: 14),
                    Expanded(child: _SummaryTile(label: 'Occupied', count: tableProv.occupiedCount,
                        color: cs.primary, bg: AppColors.accentLight, icon: Icons.people_outline)),
                    const SizedBox(width: 14),
                    Expanded(child: _SummaryTile(label: 'Reserved', count: tableProv.reservedCount,
                        color: AppColors.accentGold, bg: isDark ? AppColors.warningDarkBg : AppColors.warningLight, icon: Icons.bookmark_outline)),
                  ])
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(width: 140, child: _SummaryTile(label: 'Available', count: tableProv.availableCount,
                            color: AppColors.success, bg: isDark ? AppColors.successDarkBg : AppColors.successLight, icon: Icons.check_circle_outline)),
                        const SizedBox(width: 14),
                        SizedBox(width: 140, child: _SummaryTile(label: 'Occupied', count: tableProv.occupiedCount,
                            color: cs.primary, bg: AppColors.accentLight, icon: Icons.people_outline)),
                        const SizedBox(width: 14),
                        SizedBox(width: 140, child: _SummaryTile(label: 'Reserved', count: tableProv.reservedCount,
                            color: AppColors.accentGold, bg: isDark ? AppColors.warningDarkBg : AppColors.warningLight, icon: Icons.bookmark_outline)),
                      ],
                    ),
                  ),
              const SizedBox(height: 24),

              // ── Table Grid ─────────────────────────────────────
              LayoutBuilder(builder: (ctx, box) {
                int cols = 2;
                double ratio = 0.85;

                // Control column count and card ratio based on screen size
                if (box.maxWidth >= 900) {
                  cols = 4;
                  ratio = 0.95;
                } else if (box.maxWidth >= 600) {
                  cols = 3;
                  ratio = 0.9;
                } else {
                  cols = 2;
                  ratio = 0.75; // Taller cards on mobile
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: ratio,
                  ),
                  itemCount: tableList.length,
                  itemBuilder: (_, i) {
                    final table = tableList[i];
                    
                    // Safely access order data from AsyncValue
                    final orderData = orderAsync.value;
                    final menuData  = menuAsync.value;
                    
                    final activeOrder = (table.activeOrderId != null && orderData != null)
                        ? orderData.active.firstWhereOrNull((o) => o.id == table.activeOrderId!)
                        : null;
                    final double? orderTotal;
                    if (activeOrder != null && menuData != null) {
                      double sum = 0;
                      for (final it in activeOrder.items) {
                        final m = menuData.findById(it.menuItemId);
                        sum += (m?.price ?? 0) * it.quantity;
                      }
                      orderTotal = sum;
                    } else {
                      orderTotal = null;
                    }
                    return _TableCard(
                      table: table,
                      orderTotal: orderTotal,
                      orderItemCount: activeOrder?.items.length,
                      onNewOrder: () => _openNewOrder(context, table.id),
                      onReserve: () => tableProv.setStatus(table.id, TableStatus.reserved),
                      onFree: () => tableProv.setStatus(table.id, TableStatus.available),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }


  void _openNewOrder(BuildContext context, int tableId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewOrderSheet(preselectedTableId: tableId),
    );
  }
}

// ── Summary tile ──────────────────────────────────────────────
class _SummaryTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;
  final IconData icon;
  const _SummaryTile({required this.label, required this.count, required this.color, required this.bg, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12), 
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$count',
                    style: AppTextStyles.displayStyle(ctx: context, size: 22, color: Theme.of(context).colorScheme.onSurface)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, 
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  maxLines: 1,
                ),
              ),
            ]
          ),
        ),
      ]),
    );
  }
}

// ── Table card ────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  final CoffeeTable table;
  final double? orderTotal;
  final int? orderItemCount;
  final VoidCallback onNewOrder;
  final VoidCallback onReserve;
  final VoidCallback onFree;
  const _TableCard({
    required this.table,
    this.orderTotal, this.orderItemCount,
    required this.onNewOrder, required this.onReserve, required this.onFree,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (statusColor, statusBg, statusLabel) = switch (table.status) {
      TableStatus.available => (AppColors.success, isDark ? AppColors.successDarkBg : AppColors.successLight, 'Available'),
      TableStatus.occupied  => (cs.primary, AppColors.accentLight, 'Occupied'),
      TableStatus.reserved  => (AppColors.accentGold, isDark ? AppColors.warningDarkBg : AppColors.warningLight, 'Reserved'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: table.status == TableStatus.occupied
              ? cs.primary.withOpacity(0.4) : cs.outline,
          width: table.status == TableStatus.occupied ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('T${table.id}',
                      style: AppTextStyles.displayStyle(ctx: context, size: 22, color: cs.onSurface)),
                  Text('${table.seats} seats',
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.45)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const SizedBox(width: 4),
              StatusBadge(label: statusLabel, color: statusColor, bg: statusBg),
            ],
          ),

          if (orderTotal != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Active order', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('\$${orderTotal!.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.primary)),
                ),
                Text('$orderItemCount items', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
              ]),
            ),
          ],

          const Spacer(),

          // ── Actions ─────────────────────────────────────
          if (table.status == TableStatus.available)
            Row(children: [
              Expanded(child: AppButton(label: '+ Order', small: true, onPressed: onNewOrder)),
              const SizedBox(width: 6),
              Expanded(child: AppButton(label: 'Reserve', small: true, outlined: true,
                  color: AppColors.accentGold, onPressed: onReserve)),
            ]),
          if (table.status == TableStatus.reserved)
            SizedBox(
              width: double.infinity,
              child: AppButton(label: 'Mark Available', small: true, color: AppColors.success, onPressed: onFree)
            ),
          if (table.status == TableStatus.occupied)
            Text('Order in progress', style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }
}