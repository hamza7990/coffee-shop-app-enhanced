import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import '../providers/table_provider.dart';
import '../providers/menu_provider.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/async_widgets.dart';
import '../utils/extensions.dart';

class PaymentSheet extends ConsumerStatefulWidget {
  final String orderId;
  const PaymentSheet({super.key, required this.orderId});
  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  PaymentMethod _method = PaymentMethod.card;
  final _cashCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() { _cashCtrl.dispose(); super.dispose(); }

  double? get _cashAmount => double.tryParse(_cashCtrl.text);

  Future<void> _confirm() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final orderNotifier = ref.read(orderProvider.notifier);
      final tableNotifier = ref.read(tableProvider.notifier);
      final menuItems     = ref.read(menuProvider).value ?? [];

      // Use safe extension for menu lookup
      MenuItem? menuLookup(String id) => menuItems.findById(id);

      final completed = await orderNotifier.completeOrder(
        widget.orderId,
        _method,
        menuLookup,
      );
      await tableNotifier.freeTable(completed.tableId);
      
      if (mounted) {
        Navigator.pop(context); // close payment sheet
        showDialog(
          context: context,
          builder: (_) => ReceiptDialog(order: completed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider);
    final menuAsync  = ref.watch(menuProvider);
    final cs         = Theme.of(context).colorScheme;
    final isDark     = Theme.of(context).brightness == Brightness.dark;

    // Safely access order and menu data
    final orderData = orderAsync.value;
    final menuItems = menuAsync.value ?? [];

    Order? order;
    if (orderData != null) {
      try {
        order = orderData.active.firstWhere((o) => o.id == widget.orderId);
      } catch (_) {
        order = null;
      }
    }

    if (order == null) return const SizedBox.shrink();

    // Use safe extension for menu lookup
    MenuItem? menuLookup(String id) => menuItems.findById(id);

    final total = order.items.fold<double>(0, (s, i) {
      final m = menuLookup(i.menuItemId);
      return s + (m?.price ?? 0) * i.quantity;
    });
    final change = (_cashAmount ?? 0) - total;
    final cashValid = _method == PaymentMethod.card || ((_cashAmount ?? 0) >= total);

    return Container(
      padding: EdgeInsets.fromLTRB(28, 24, 28, MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: LoadingOverlay(
        isLoading: _isProcessing,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(
                width: 48, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)),
              )),

              Row(children: [
                Text('Payment', style: AppTextStyles.title(context, size: 24)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 20),

              // Order summary box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${order.id}  ·  Table ${order.tableId}',
                        style: AppTextStyles.muted(context, size: 14)),
                    const SizedBox(height: 16),
                    
                    ...order.items.map((oi) {
                      final mi = menuLookup(oi.menuItemId);
                      if (mi == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Expanded(
                            child: Text('${mi.icon}  ${mi.name} ×${oi.quantity}',
                                style: AppTextStyles.body(context),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text('\$${(mi.price * oi.quantity).toStringAsFixed(2)}',
                              style: AppTextStyles.body(context, weight: FontWeight.w600)),
                        ]),
                      );
                    }),
                    Divider(height: 28, color: cs.outline),
                    Row(children: [
                      Text('Total', style: AppTextStyles.title(context, size: 16)),
                      const Spacer(),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: total),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Text('\$${value.toStringAsFixed(2)}',
                            style: AppTextStyles.displayStyle(ctx: context, size: 26, color: cs.primary));
                        },
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Method selector
              Row(children: [
                Expanded(child: _MethodTile(
                  label: '💳 Card', selected: _method == PaymentMethod.card,
                  color: AppColors.info,
                  bg: AppColors.info.withOpacity(0.12),
                  onTap: () => setState(() => _method = PaymentMethod.card),
                )),
                const SizedBox(width: 16),
                Expanded(child: _MethodTile(
                  label: '💵 Cash', selected: _method == PaymentMethod.cash,
                  color: AppColors.success,
                  bg: AppColors.success.withOpacity(0.12),
                  onTap: () => setState(() => _method = PaymentMethod.cash),
                )),
              ]),
              const SizedBox(height: 20),

              if (_method == PaymentMethod.cash) ...[
                AppTextField(
                  label: 'Cash Received (\$)',
                  hint: total.toStringAsFixed(2),
                  controller: _cashCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                if (_cashAmount != null && _cashAmount! >= total) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Change: \$${change.toStringAsFixed(2)}',
                        style: AppTextStyles.title(context).copyWith(color: AppColors.success)),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (cashValid && !_isProcessing) ? _confirm : null,
                  child: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Complete Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _MethodTile({required this.label, required this.selected, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? bg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : cs.outline, width: selected ? 2 : 1),
        ),
        child: Center(
          child: Text(label,
            style: AppTextStyles.title(context, size: 15).copyWith(
              color: selected ? color : cs.onSurface.withOpacity(0.5)
            )
          ),
        ),
      ),
    );
  }
}

class ReceiptDialog extends ConsumerWidget {
  final Order order;
  const ReceiptDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.read(menuProvider).value ?? [];
    final cs   = Theme.of(context).colorScheme;

    // Use safe extension for menu lookup
    MenuItem? findById(String id) => menuItems.findById(id);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15), shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.success, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Payment Complete!', style: AppTextStyles.title(context, size: 22)),
            const SizedBox(height: 6),
            Text('Thank you for visiting Brewhaus', style: AppTextStyles.muted(context), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                children: [
                  Text(order.id, style: AppTextStyles.label(context)),
                  Text('${order.completedTime}  ·  Table ${order.tableId}', style: AppTextStyles.muted(context)),
                  Divider(height: 24, color: cs.outline),
                  
                  ...order.items.map((oi) {
                    final mi = findById(oi.menuItemId);
                    if (mi == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                          child: Text('${mi.name} ×${oi.quantity}', 
                            style: AppTextStyles.body(context),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text('\$${(mi.price * oi.quantity).toStringAsFixed(2)}',
                            style: AppTextStyles.body(context, weight: FontWeight.w600)),
                      ]),
                    );
                  }),
                  
                  Divider(height: 24, color: cs.outline),
                  Row(children: [
                    Text('Total', style: AppTextStyles.title(context, size: 16)),
                    const Spacer(),
                    Text('\$${order.total?.toStringAsFixed(2) ?? '—'}',
                        style: AppTextStyles.displayStyle(ctx: context, size: 22, color: cs.primary)),
                  ]),
                  const SizedBox(height: 12),
                  Text(order.paymentMethod == PaymentMethod.card ? '💳 Paid by card' : '💵 Paid by cash',
                      style: AppTextStyles.muted(context, size: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}