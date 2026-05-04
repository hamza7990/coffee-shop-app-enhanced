// lib/screens/tables_screen.dart
// ─────────────────────────────────────────────────────────────
// Displays all tables in a responsive grid.
// Each card shows status, seat count, and context actions.
// Admin can add/delete tables. Opening a new order delegates
// to NewOrderSheet (bottom sheet).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/table_provider.dart';
import '../providers/order_provider.dart';
import '../providers/menu_provider.dart';
import '../models/coffee_table.dart';
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
              SectionHeader(
                title: 'Table Management',
                subtitle: 'Manage table status and assignments',
                action: AppButton(
                  label: '+ Add Table',
                  icon: Icons.add,
                  onPressed: () => _openAddTableSheet(context, ref),
                ),
              ),
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

              // ── Empty state ─────────────────────────────────────
              if (tableList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.table_restaurant_outlined, size: 64,
                            color: cs.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('No tables yet',
                            style: AppTextStyles.title(context, size: 18)),
                        const SizedBox(height: 8),
                        Text('Tap "+ Add Table" to create your first table',
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ),

              // ── Table Grid ─────────────────────────────────────
              if (tableList.isNotEmpty)
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
                        onDelete: () => _confirmDeleteTable(context, ref, table),
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

  void _openAddTableSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTableSheet(tableNotifier: ref.read(tableProvider.notifier)),
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

  void _confirmDeleteTable(BuildContext context, WidgetRef ref, CoffeeTable table) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Table',
      message: 'Remove table "${table.name}" permanently?\nThis cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (ok && context.mounted) {
      try {
        await ref.read(tableProvider.notifier).deleteTable(table.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✓ Table "${table.name}" deleted'),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
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
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
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
  final VoidCallback onDelete;
  const _TableCard({
    required this.table,
    this.orderTotal, this.orderItemCount,
    required this.onNewOrder, required this.onReserve, required this.onFree,
    required this.onDelete,
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
              ? cs.primary.withValues(alpha: 0.4) : cs.outline,
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
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const SizedBox(width: 4),
              // Delete button
              if (table.status == TableStatus.available)
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                  ),
                ),
              const SizedBox(width: 6),
              StatusBadge(label: statusLabel, color: statusColor, bg: statusBg),
            ],
          ),

          if (orderTotal != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Active order', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('\$${orderTotal!.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.primary)),
                ),
                Text('$orderItemCount items', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
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
            Text('Order in progress', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

// ── Add Table Sheet ───────────────────────────────────────────
class _AddTableSheet extends StatefulWidget {
  final TableNotifier tableNotifier;
  const _AddTableSheet({required this.tableNotifier});
  @override
  State<_AddTableSheet> createState() => _AddTableSheetState();
}

class _AddTableSheetState extends State<_AddTableSheet> {
  late final _numberCtrl   = TextEditingController();
  late final _capacityCtrl = TextEditingController(text: '4');
  bool _saving = false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    final number   = _numberCtrl.text.trim();
    final capacity = int.tryParse(_capacityCtrl.text);
    if (number.isEmpty || capacity == null || capacity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')));
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.tableNotifier.addTable(number, capacity);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ Table "$number" added'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Added locally (API error: $e)'),
          backgroundColor: AppColors.accentGold,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(28, 20, 28, MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(
              width: 48, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)),
            )),
            Row(children: [
              Text('Add Table', style: AppTextStyles.title(context, size: 22)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 24),

            AppTextField(
              label: 'Table Number / Name',
              hint: 'e.g. T1, Window-A, Patio-3',
              controller: _numberCtrl,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Capacity (seats)',
              hint: '4',
              controller: _capacityCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Table'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}