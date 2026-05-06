import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/table_provider.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/coffee_table.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/async_widgets.dart';
import '../utils/extensions.dart';

class NewOrderSheet extends ConsumerStatefulWidget {
  final int? preselectedTableId;
  const NewOrderSheet({super.key, this.preselectedTableId});
  @override
  ConsumerState<NewOrderSheet> createState() => _NewOrderSheetState();
}

class _NewOrderSheetState extends ConsumerState<NewOrderSheet> {
  int? _selectedTableId;
  MenuCategory _activeCategory = MenuCategory.coffee;
  final List<OrderItem> _items = [];
  bool _isSubmitting = false;

  // Global key to animate items sliding into the order list
  final _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _selectedTableId = widget.preselectedTableId;
  }

  void _addItem(String menuItemId) {
    setState(() {
      final existingIndex = _items.indexWhere((i) => i.menuItemId == menuItemId);
      if (existingIndex != -1) {
        // Update existing item quantity
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity + 1,
        );
      } else {
        // Add new item - prevent duplicate entries
        final newItem = OrderItem(menuItemId: menuItemId, quantity: 1);
        _items.add(newItem);
        _listKey.currentState?.insertItem(_items.length - 1);
      }
    });
  }

  void _updateQty(String menuItemId, int delta) {
    setState(() {
      final idx = _items.indexWhere((i) => i.menuItemId == menuItemId);
      if (idx == -1) return; // Safety: item not found
      
      final newQty = _items[idx].quantity + delta;
      
      if (newQty <= 0) {
        // Remove item when quantity reaches zero
        final removedItem = _items[idx];
        _items.removeAt(idx);
        _listKey.currentState?.removeItem(
          idx, 
          (context, animation) => _buildAnimatedOrderItem(context, removedItem, animation),
          duration: const Duration(milliseconds: 300),
        );
      } else {
        // Update quantity safely
        _items[idx] = _items[idx].copyWith(quantity: newQty);
      }
    });
  }

  double _total(List<MenuItem> menuItems) {
    // Use safe extension to find menu items
    return _items.fold<double>(0, (sum, item) {
      final menuItem = menuItems.findById(item.menuItemId);
      return sum + (menuItem?.price ?? 0) * item.quantity;
    });
  }

  Future<void> _placeOrder() async {
    if (_selectedTableId == null || _items.isEmpty || _isSubmitting) return;
    
    setState(() => _isSubmitting = true);

    try {
      final orderNotifier = ref.read(orderProvider.notifier);
      final tableNotifier = ref.read(tableProvider.notifier);

      final orderId = await orderNotifier.createOrder(_selectedTableId!, List.from(_items));
      await tableNotifier.assignOrder(_selectedTableId!, orderId);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order created!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildAnimatedOrderItem(BuildContext context, OrderItem oi, Animation<double> animation) {
    final menuItems = ref.read(menuProvider).value ?? [];
    
    // Use safe extension to find menu item
    final mi = menuItems.findById(oi.menuItemId);
    final cs = Theme.of(context).colorScheme;

    if (mi == null) return const SizedBox.shrink();
    
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${mi.icon}  ${mi.name}',
                  style: AppTextStyles.body(context, weight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                _QtyBtn(onTap: () => _updateQty(mi.id, -1), icon: Icons.remove),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${oi.quantity}',
                      style: AppTextStyles.body(context, weight: FontWeight.w600)),
                ),
                _QtyBtn(onTap: () => _updateQty(mi.id, 1), icon: Icons.add),
                const Spacer(),
                Text('\$${(mi.price * oi.quantity).toStringAsFixed(2)}',
                    style: AppTextStyles.body(context, weight: FontWeight.w600).copyWith(color: cs.primary)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync      = ref.watch(menuProvider);
    final tableAsync     = ref.watch(tableProvider);
    final cs             = Theme.of(context).colorScheme;
    
    final isWide = MediaQuery.of(context).size.width > 700;

    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight - viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: LoadingOverlay(
        isLoading: _isSubmitting,
        child: Column(
          children: [
            Center(child: Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              width: 48, height: 4,
              decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)),
            )),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Row(children: [
                Text('New Order', style: AppTextStyles.title(context, size: 22)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            Divider(height: 1, color: cs.outline),

            Expanded(
              child: menuAsync.when(
                loading: () => const LoadingIndicator(message: 'Loading menu…'),
                error: (e, _) => ErrorDisplay(message: e.toString()),
                data: (menuList) {
                  final tableList = tableAsync.value ?? [];
                  final availableTables = tableList.where((t) => t.status != TableStatus.occupied).toList();
                  
                  // CRITICAL FIX: Validate selected table still exists in available tables
                  // If not, reset selection to prevent dropdown crash
                  if (_selectedTableId != null && 
                      !availableTables.any((t) => t.id == _selectedTableId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedTableId = null);
                    });
                  }
                  
                  final catItems = menuList.where((m) => m.category == _activeCategory && m.enabled).toList();

                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Menu Section ──────────────────────────────
                      Expanded(
                        flex: isWide ? 5 : 1,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // DEFENSIVE: Only show dropdown if value is valid or null
                                  DropdownButtonFormField<int?>(
                                    isExpanded: true,
                                    initialValue: _selectedTableId != null && 
                                            availableTables.any((t) => t.id == _selectedTableId)
                                        ? _selectedTableId 
                                        : null,
                                    hint: const Text('Select a table...'),
                                    decoration: InputDecoration(
                                      labelText: 'Table',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onChanged: availableTables.isEmpty 
                                        ? null 
                                        : (v) => setState(() => _selectedTableId = v),
                                    items: availableTables.isEmpty
                                        ? [const DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text('No tables available', 
                                              style: TextStyle(color: Colors.grey)),
                                          )]
                                        : availableTables.map((t) => DropdownMenuItem(
                                            value: t.id,
                                            child: Text('${t.name} (${t.seats} seats) – ${t.status.label}', 
                                                overflow: TextOverflow.ellipsis),
                                          )).toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: MenuCategory.values.map((c) => Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: CategoryChip(
                                          label: '${c.emoji} ${c.label}',
                                          selected: _activeCategory == c,
                                          onTap: () => setState(() => _activeCategory = c),
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? 4 : 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: isWide ? 1.4 : 1.15,
                                ),
                                itemCount: catItems.length,
                                itemBuilder: (_, i) {
                                  final item = catItems[i];
                                  final inOrder = _items.any((o) => o.menuItemId == item.id);
                                  
                                  return GestureDetector(
                                    onTap: () => _addItem(item.id),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: inOrder ? cs.primary.withValues(alpha: 0.08) : cs.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: inOrder ? cs.primary : cs.outline, width: inOrder ? 1.5 : 1),
                                        boxShadow: inOrder ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AnimatedScale(
                                            scale: inOrder ? 1.1 : 1.0,
                                            duration: const Duration(milliseconds: 200),
                                            child: Text(item.icon, style: const TextStyle(fontSize: 28)),
                                          ),
                                          const Spacer(),
                                          Text(item.name, style: AppTextStyles.body(context, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text('\$${item.price.toStringAsFixed(2)}',
                                              style: AppTextStyles.body(context, weight: FontWeight.w700).copyWith(color: cs.primary)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Order Summary Section ────────────────────
                      Container(
                        width: isWide ? 320 : double.infinity,
                        constraints: BoxConstraints(
                          maxHeight: isWide ? double.infinity : 280,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          border: Border(
                            left: isWide ? BorderSide(color: cs.outline) : BorderSide.none,
                            top: !isWide ? BorderSide(color: cs.outline) : BorderSide.none,
                          ),
                          boxShadow: isWide ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), offset: const Offset(-5, 0), blurRadius: 10)] : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text('Summary', style: AppTextStyles.title(context, size: 18)),
                            ),
                            Flexible(
                              child: _items.isEmpty
                                  ? Center(child: Text('No items yet', style: AppTextStyles.muted(context)))
                                  : AnimatedList(
                                      key: _listKey,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      shrinkWrap: true,
                                      initialItemCount: _items.length,
                                      itemBuilder: (context, i, animation) {
                                        if (i >= _items.length) return const SizedBox.shrink();
                                        return _buildAnimatedOrderItem(context, _items[i], animation);
                                      },
                                    ),
                            ),
                            Divider(height: 1, color: cs.outline),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('Total Amount', style: AppTextStyles.title(context, size: 15)),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: _total(menuList)),
                                    duration: const Duration(milliseconds: 400),
                                    builder: (context, value, child) {
                                      return Text('\$${value.toStringAsFixed(2)}',
                                        style: AppTextStyles.displayStyle(ctx: context, size: 24, color: cs.primary));
                                    },
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: (_selectedTableId != null && _items.isNotEmpty && !_isSubmitting) ? _placeOrder : null,
                                    child: _isSubmitting
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('Confirm Order'),
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const _QtyBtn({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}