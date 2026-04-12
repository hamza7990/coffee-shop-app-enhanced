// lib/screens/dashboard_screen.dart
// ─────────────────────────────────────────────────────────────
// Dashboard: stat cards, revenue chart, popular items, active
// orders summary. Reads from OrderProvider, MenuProvider,
// TableProvider – all via context.watch (auto-rebuilds).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/order_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/table_provider.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/async_widgets.dart';
import '../data/sample_data.dart';
import '../utils/extensions.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider);
    final menuAsync  = ref.watch(menuProvider);
    final tableAsync = ref.watch(tableProvider);
    final cs         = Theme.of(context).colorScheme;
    final isDark     = Theme.of(context).brightness == Brightness.dark;

    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;

    // Show loading if any provider is still loading
    if (orderAsync.isLoading || menuAsync.isLoading || tableAsync.isLoading) {
      return const LoadingIndicator(message: 'Loading dashboard…');
    }

    // Show error if any critical provider failed
    if (orderAsync.hasError) {
      return ErrorDisplay(
        message: orderAsync.error.toString(),
        onRetry: () => ref.invalidate(orderProvider),
      );
    }

    // Safely unwrap data with fallbacks
    final orders     = orderAsync.value ?? const OrderState(active: [], completed: [], counter: 1);
    final menuItems  = menuAsync.value ?? <MenuItem>[];
    final tableList  = tableAsync.value ?? [];
    final tableProv  = ref.read(tableProvider.notifier);

    // Use safe extension for menu lookup
    MenuItem? findMenuItem(String id) => menuItems.findById(id);

    // ── Derived stats ────────────────────────────────────────
    final completed  = orders.completed;
    final totalRev   = completed.fold<double>(0, (s, o) => s + (o.total ?? 0));
    final avgOrder   = completed.isEmpty ? 0.0 : totalRev / completed.length;
    final occupancy  = tableList.isEmpty
        ? 0 : (tableProv.occupiedCount / tableList.length * 100).round();

    // Popular items from completed orders
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

    final chartColors = isDark ? AppColors.chartDark : AppColors.chartLight;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth < 600 ? 16.0 : 28.0), // Reduce padding on mobile
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Dashboard',
            subtitle: 'Good morning! ${DateFormat('EEEE, MMMM d').format(DateTime.now())}',
          ),
          const SizedBox(height: 24),

          // ── Stat Cards ───────────────────────────────────
          LayoutBuilder(builder: (ctx, box) {
            final cols = box.maxWidth > 700 ? 4 : 2;
            
            // Calculate aspect ratio based on screen width to avoid overflow
            double ratio = 1.35;
            if (box.maxWidth <= 400) {
              ratio = 1.0; // Square-ish card for very small screens
            } else if (box.maxWidth <= 600) {
              ratio = 1.15;
            } else if (box.maxWidth <= 900) {
              ratio = 1.25;
            }
            
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: ratio,
              children: [
                StatCard(
                  label: "Today's Revenue", value: '\$${totalRev.toStringAsFixed(2)}',
                  icon: Icons.attach_money, iconColor: cs.primary,
                  iconBg: AppColors.accentLight, badge: '+12.5%',
                ),
                StatCard(
                  label: 'Total Orders', value: '${completed.length}',
                  icon: Icons.receipt_long, iconColor: AppColors.success,
                  iconBg: isDark ? AppColors.successDarkBg : AppColors.successLight, badge: '+8.2%',
                ),
                StatCard(
                  label: 'Avg. Order Value', value: '\$${avgOrder.toStringAsFixed(2)}',
                  icon: Icons.trending_up, iconColor: AppColors.accentGold,
                  iconBg: isDark ? AppColors.warningDarkBg : AppColors.warningLight, badge: '+3.1%',
                ),
                StatCard(
                  label: 'Table Occupancy', value: '$occupancy%',
                  icon: Icons.table_restaurant, iconColor: isDark ? AppColors.infoDark : AppColors.info,
                  iconBg: isDark ? AppColors.infoDarkBg : AppColors.infoLight,
                  badge: '${tableProv.occupiedCount}/${tableList.length}',
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          // ── Charts Row ────────────────────────────────────
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth > 700;
            
            // 1. Weekly Revenue Card
            final revenueCard = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Revenue', style: AppTextStyles.title(context)),
                  const SizedBox(height: 4),
                  Text('Revenue for the past 7 days', style: AppTextStyles.muted(context)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        barGroups: seedWeekly.asMap().entries.map((e) => BarChartGroupData(
                          x: e.key,
                          barRods: [BarChartRodData(
                            toY: e.value.revenue,
                            color: cs.primary,
                            width: wide ? 20 : 14, // Narrower bars on mobile
                            borderRadius: BorderRadius.circular(6),
                          )],
                        )).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 22,
                            getTitlesWidget: (v, _) => Text(
                              seedWeekly[v.toInt()].day,
                              style: TextStyle(fontSize: wide ? 11 : 9, color: cs.onSurface.withOpacity(0.5)), // Smaller font on mobile
                            ),
                          )),
                          leftTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: wide ? 44 : 36,
                            getTitlesWidget: (v, _) => Text('\$${v.toInt()}',
                                style: TextStyle(fontSize: wide ? 10 : 8, color: cs.onSurface.withOpacity(0.5))),
                          )),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(color: cs.outline, strokeWidth: 0.5),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            );

            // 2. Popular Items Card
            final popularCard = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Popular Items', style: AppTextStyles.title(context)),
                  const SizedBox(height: 4),
                  Text('Top sellers today', style: AppTextStyles.muted(context)),
                  const SizedBox(height: 16),
                  ...top5.asMap().entries.map((e) {
                    final pct = ((e.value.qty / (top5.first.qty)) * 100).clamp(10, 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(children: [
                        Text(e.value.item!.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.item!.name, 
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct / 100, minHeight: 6,
                                backgroundColor: cs.outline,
                                color: chartColors[e.key % chartColors.length],
                              ),
                            ),
                          ],
                        )),
                        const SizedBox(width: 10),
                        FittedBox( // Protect number from overflow
                            fit: BoxFit.scaleDown,
                            child: Text('×${e.value.qty}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                          ),
                      ]),
                    );
                  }),
                ],
              ),
            );

            // 3. Return Row for wide screens, Column for narrow screens
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: revenueCard),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: popularCard),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      revenueCard,
                      const SizedBox(height: 16),
                      popularCard,
                    ],
                  );
          }),
          const SizedBox(height: 24),

          // ── Active Orders ─────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Active Orders', style: AppTextStyles.title(context)),
                  const Spacer(),
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.success,
                      boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 6, spreadRadius: 2)],
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('${orders.active.length} orders in progress', style: AppTextStyles.muted(context)),
                const SizedBox(height: 16),
                
                // Use horizontal scroll on mobile to prevent card overflow
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: orders.active.map((o) {
                      final tot = o.items.fold<double>(0, (s, i) {
                        final m = findMenuItem(i.menuItemId);
                        return s + (m?.price ?? 0) * i.quantity;
                      });
                      return Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded( // حماية النص
                              child: Text('Table ${o.tableId}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 4),
                            Text('${o.items.length} items',
                                style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
                          ]),
                          const SizedBox(height: 8),
                          FittedBox( // لحماية السعر من الـ Overflow
                            fit: BoxFit.scaleDown,
                            child: Text('\$${tot.toStringAsFixed(2)}',
                                style: AppTextStyles.displayStyle(ctx: context, size: 20, color: cs.onSurface)),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );  
  }
}