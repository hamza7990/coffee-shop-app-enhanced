// lib/screens/analytics_screen.dart
// ─────────────────────────────────────────────────────────────
// Sales Analytics: summary cards, hourly line chart,
// weekly bar chart, category revenue bars, payment pie.
// Uses fl_chart package.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/order_provider.dart';
import '../providers/menu_provider.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/async_widgets.dart';
import '../data/sample_data.dart';
import '../utils/extensions.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider);
    final menuAsync  = ref.watch(menuProvider);
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Handle loading/error states
    if (orderAsync.isLoading || menuAsync.isLoading) {
      return const LoadingIndicator(message: 'Loading analytics…');
    }
    if (orderAsync.hasError) {
      return ErrorDisplay(
        message: orderAsync.error.toString(),
        onRetry: () => ref.invalidate(orderProvider),
      );
    }

    final orders = orderAsync.value;
    final menuItems = menuAsync.value ?? <MenuItem>[];
    final completed = orders?.completed ?? [];

    // Use safe extension for menu lookup
    MenuItem? findMenuItem(String id) => menuItems.findById(id);

    // Summary (Fixed initial value to 0.0)
    final totalRev = completed.fold<double>(0.0, (s, o) => s + (o.total ?? 0.0));
    final avgOrder = completed.isEmpty ? 0.0 : totalRev / completed.length;

    // Popular
    final Map<String, int> counts = {};
    for (final o in completed) {
      for (final i in o.items) {
        counts[i.menuItemId] = (counts[i.menuItemId] ?? 0) + i.quantity;
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final bestSeller = sorted.isEmpty ? 'N/A' : (findMenuItem(sorted.first.key)?.name ?? 'N/A');

    // Payment split
    final cardCount = completed.where((o) => o.paymentMethod == PaymentMethod.card).length;
    final cashCount = completed.where((o) => o.paymentMethod == PaymentMethod.cash).length;

    // Category revenue (Iterating through categories safely & fixing fold type)
    final catRevenue = <String, double>{};
    final categories = menuItems.map((m) => m.category).toSet();
    for (final cat in categories) {
      final items = menuItems.where((m) => m.category == cat).map((m) => m.id).toSet();
      catRevenue[cat.toString()] = completed.fold<double>(0.0, (s, o) =>
          s + o.items.where((i) => items.contains(i.menuItemId))
              .fold<double>(0.0, (ss, i) => ss + (findMenuItem(i.menuItemId)?.price ?? 0.0) * i.quantity));
    }

    final chartColors = isDark ? AppColors.chartDark : AppColors.chartLight;

    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Analytics', subtitle: 'Revenue and performance insights'),
          const SizedBox(height: 24),

          // ── Summary Row ────────────────────────────────────
          LayoutBuilder(builder: (ctx, box) {
            final cols = box.maxWidth > 700 ? 4 : 2;
            double ratio = 2.0;
            if (box.maxWidth <= 400) {
              ratio = 1.6;
            } else if (box.maxWidth <= 600) {
               ratio = 1.8;
            }
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: ratio,
              children: [
                _MiniStat(label: "Today's Revenue",  value: '\$${totalRev.toStringAsFixed(2)}', color: cs.primary),
                _MiniStat(label: 'Total Orders',     value: '${completed.length}', color: AppColors.success),
                _MiniStat(label: 'Avg. Order',       value: '\$${avgOrder.toStringAsFixed(2)}', color: AppColors.accentGold),
                _MiniStat(label: 'Best Seller',      value: bestSeller, color: isDark ? AppColors.infoDark : AppColors.info),
              ],
            );
          }),
          const SizedBox(height: 24),

          // ── Charts Row 1 ───────────────────────────────────
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth > 700;
            
            final hourlyChart = AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hourly Revenue', style: AppTextStyles.title(context, size: 15)),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: 180,
                    width: wide ? null : 500, // إعطاء عرض ثابت للسكرول في الموبايل
                    child: LineChart(LineChartData(
                      lineBarsData: [LineChartBarData(
                        spots: seedHourly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue)).toList(),
                        isCurved: true,
                        color: cs.primary, barWidth: 2.5,
                        belowBarData: BarAreaData(show: true, color: cs.primary.withOpacity(0.1)),
                        dotData: const FlDotData(show: false),
                      )],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, reservedSize: 22, interval: 2,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            return i < seedHourly.length
                                ? Text(seedHourly[i].hour, style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.5)))
                                : const SizedBox.shrink();
                          },
                        )),
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, reservedSize: 40,
                          getTitlesWidget: (v, _) => Text('\$${v.toInt()}',
                              style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.5))),
                        )),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(color: cs.outline, strokeWidth: 0.5)),
                      borderData: FlBorderData(show: false),
                    ))
                  ),
                ),
              ]),
            );

            final weeklyChart = AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Weekly Orders', style: AppTextStyles.title(context, size: 15)),
                const SizedBox(height: 20),
                SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: SizedBox(
                      height: 180,
                      width: wide ? null : 400,
                      child: BarChart(BarChartData(
                        barGroups: seedWeekly.asMap().entries.map((e) => BarChartGroupData(
                          x: e.key,
                          barRods: [BarChartRodData(toY: e.value.orders.toDouble(),
                              color: AppColors.accentGold, width: 18,
                              borderRadius: BorderRadius.circular(5))],
                        )).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 22,
                            getTitlesWidget: (v, _) => Text(seedWeekly[v.toInt()].day,
                                style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
                          )),
                          leftTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 30,
                            getTitlesWidget: (v, _) => Text('${v.toInt()}',
                                style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.5))),
                          )),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(color: cs.outline, strokeWidth: 0.5)),
                        borderData: FlBorderData(show: false),
                      ))
                   ),
                ),
              ]),
            );

            // Row vs Column to avoid unconstrained Flex vertical heights
            return wide 
                ? Row(children: [Expanded(child: hourlyChart), const SizedBox(width: 16), Expanded(child: weeklyChart)])
                : Column(children: [hourlyChart, const SizedBox(height: 16), weeklyChart]);
          }),
          const SizedBox(height: 20),

          // ── Charts Row 2 ───────────────────────────────────
          LayoutBuilder(builder: (ctx, box) {
            final wide = box.maxWidth > 700;
            
            final categoryChart = AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Revenue by Category', style: AppTextStyles.title(context, size: 15)),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: 180,
                    width: wide ? null : 400,
                    child: BarChart(BarChartData(
                      barGroups: catRevenue.entries.toList().asMap().entries.map((e) => BarChartGroupData(
                        x: e.key,
                        barRods: [BarChartRodData(
                          toY: e.value.value,
                          color: chartColors[e.key % chartColors.length],
                          width: 20,
                          borderRadius: BorderRadius.circular(5),
                        )],
                      )).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, reservedSize: 30,
                          getTitlesWidget: (v, _) {
                            final keys = catRevenue.keys.toList();
                            final i = v.toInt();
                            return i < keys.length
                                ? Text(keys[i], style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.5)))
                                : const SizedBox.shrink();
                          },
                        )),
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, reservedSize: 44,
                          getTitlesWidget: (v, _) => Text('\$${v.toInt()}',
                              style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.5))),
                        )),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(color: cs.outline, strokeWidth: 0.5)),
                      borderData: FlBorderData(show: false),
                    ))
                  ),
                ),
              ]),
            );

            final paymentChart = AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Payment Methods', style: AppTextStyles.title(context, size: 15)),
                const SizedBox(height: 16),
                Row(children: [
                  SizedBox(height: 160, width: wide ? 160 : 140, child: PieChart(PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: wide ? 44 : 35,
                    // Safe fallback for an empty order state
                    sections: (cardCount == 0 && cashCount == 0)
                      ? [
                          PieChartSectionData(
                            value: 1, color: cs.outline.withOpacity(0.2),
                            title: 'No Data', titleStyle: TextStyle(fontSize: 11, color: cs.onSurface),
                            radius: wide ? 50 : 40,
                          )
                        ]
                      : [
                          if (cardCount > 0)
                            PieChartSectionData(
                              value: cardCount.toDouble(), color: isDark ? AppColors.infoDark : AppColors.info,
                              title: '$cardCount', titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                              radius: wide ? 50 : 40,
                            ),
                          if (cashCount > 0)
                            PieChartSectionData(
                              value: cashCount.toDouble(), color: AppColors.success,
                              title: '$cashCount', titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                              radius: wide ? 50 : 40,
                            ),
                        ],
                  ))),
                  const SizedBox(width: 20),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _LegendTile(color: isDark ? AppColors.infoDark : AppColors.info, label: '💳 Card', value: '$cardCount'),
                    const SizedBox(height: 14),
                    _LegendTile(color: AppColors.success, label: '💵 Cash', value: '$cashCount'),
                    Divider(height: 24, color: cs.outline),
                    Text('Total', style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
                    // Preserved your custom AppTextStyles format
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('${completed.length}',
                          style: AppTextStyles.displayStyle(ctx: context, size: 22, color: cs.onSurface)),
                    ),
                  ])),
                ]),
              ]),
            );

            return wide 
                ? Row(children: [Expanded(child: categoryChart), const SizedBox(width: 16), Expanded(child: paymentChart)])
                : Column(children: [categoryChart, const SizedBox(height: 16), paymentChart]);
          }),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 6),
      // Preserved your custom AppTextStyles format
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(value, style: AppTextStyles.displayStyle(ctx: context, size: 20, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ]),
  );
}

class _LegendTile extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendTile({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 8),
    Expanded(child: Text(label, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis,)),
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  ]);
}