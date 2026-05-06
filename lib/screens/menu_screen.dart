import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/menu_provider.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/async_widgets.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});
  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  MenuCategory? _activeCategory; // null = all

  void _openEditor(BuildContext context, WidgetRef ref, [MenuItem? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuEditorSheet(item: item, menuNotifier: ref.read(menuProvider.notifier)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);

    final isWide = MediaQuery.of(context).size.width > 600;
    final hPadding = isWide ? 28.0 : 16.0;

    return menuAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading menu…'),
      error: (e, _) => ErrorDisplay(
        message: e.toString(),
        onRetry: () => ref.invalidate(menuProvider),
      ),
      data: (menuItems) {
        final menuProv = ref.read(menuProvider.notifier);
        
        final displayed = _activeCategory == null
            ? menuItems
            : menuProv.itemsForCategory(_activeCategory!);

        return SingleChildScrollView(
          padding: EdgeInsets.all(hPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Menu Management',
                subtitle: 'Manage items, prices and categories',
                action: AppButton(
                  label: '+ New Item', icon: Icons.add,
                  onPressed: () => _openEditor(context, ref),
                ),
              ),
              const SizedBox(height: 24),

              // ── Category chips ─────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      label: 'All (${menuItems.length})',
                      selected: _activeCategory == null,
                      onTap: () => setState(() => _activeCategory = null),
                    ),
                  ),
                  ...MenuCategory.values.map((c) {
                    final count = menuProv.itemsForCategory(c).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: '${c.emoji} ${c.label} ($count)',
                        selected: _activeCategory == c,
                        onTap: () => setState(() => _activeCategory = c),
                      ),
                    );
                  }),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Items grid ─────────────────────────────────────
              LayoutBuilder(builder: (ctx, box) {
                int cols = 2; // عمودين للموبايل
                double ratio = 1.0;

                if (box.maxWidth >= 900) {
                  cols = 4;
                  ratio = 1.1;
                } else if (box.maxWidth >= 600) {
                  cols = 3;
                  ratio = 1.0;
                } else {
                  cols = 2;
                  ratio = 0.95; // كارت أطول قليلاً في الموبايل
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
                  itemCount: displayed.length,
                  itemBuilder: (_, i) => _MenuItemCard(
                    item: displayed[i],
                    onEdit: () => _openEditor(context, ref, displayed[i]),
                    onDelete: () async {
                      final ok = await showConfirmDialog(context,
                          title: 'Delete Item',
                          message: 'Remove "${displayed[i].name}" from the menu?',
                          confirmLabel: 'Delete', confirmColor: Colors.red);
                      if (ok && context.mounted) {
                        ref.read(menuProvider.notifier).deleteItem(displayed[i].id);
                      }
                    },
                    onToggle: () => ref.read(menuProvider.notifier).toggleItem(displayed[i].id),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ── Menu item card ────────────────────────────────────────────
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  const _MenuItemCard({required this.item, required this.onEdit, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;


    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: item.enabled ? 1 : 0.55,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.icon, style: const TextStyle(fontSize: 34)),
              const Spacer(),
              // Edit
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.edit_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(width: 8),
              // Delete
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(item.name, style: AppTextStyles.body(context, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(item.category.label, style: AppTextStyles.muted(context, size: 12)),
            const Spacer(),
            Row(children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('\$${item.price.toStringAsFixed(2)}',
                    style: AppTextStyles.displayStyle(ctx: context, size: 18, color: cs.primary)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.enabled
                        ? AppColors.success.withValues(alpha: 0.12)
                        : cs.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(item.enabled ? '● Active' : '○ Off',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: item.enabled ? AppColors.success : cs.onSurface.withValues(alpha: 0.5),
                      )),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit Sheet ──────────────────────────────────────────
class _MenuEditorSheet extends StatefulWidget {
  final MenuItem? item;
  final MenuNotifier menuNotifier;
  const _MenuEditorSheet({this.item, required this.menuNotifier});
  @override
  State<_MenuEditorSheet> createState() => _MenuEditorSheetState();
}

class _MenuEditorSheetState extends State<_MenuEditorSheet> {
  late final _nameCtrl  = TextEditingController(text: widget.item?.name ?? '');
  late final _priceCtrl = TextEditingController(text: widget.item?.price.toString() ?? '');
  late final _iconCtrl  = TextEditingController(text: widget.item?.icon ?? '☕');
  late MenuCategory _category = widget.item?.category ?? MenuCategory.coffee;

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _iconCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name  = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text);
    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')));
      return;
    }

    final menuProv = widget.menuNotifier;

    if (widget.item != null) {
      menuProv.updateItem(widget.item!.copyWith(
        name: name, price: price, category: _category, icon: _iconCtrl.text,
      ));
    } else {
      menuProv.addItem(MenuItem(
        id: const Uuid().v4(),
        name: name, price: price, category: _category, icon: _iconCtrl.text,
      ));
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.item != null ? '✓ Item updated' : '✓ Item added'),
      backgroundColor: AppColors.success,
    ));
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
              Text(widget.item != null ? 'Edit Item' : 'Add Menu Item',
                  style: AppTextStyles.title(context, size: 22)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 24),

            AppTextField(label: 'Item Name', hint: 'e.g. Flat White', controller: _nameCtrl),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category', style: AppTextStyles.body(context, weight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MenuCategory>(
                    isExpanded: true,
                    initialValue: _category,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cs.primary, width: 2)
                      ),
                    ),
                    onChanged: (v) => setState(() => _category = v!),
                    items: MenuCategory.values.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.emoji} ${c.label}', overflow: TextOverflow.ellipsis),
                    )).toList(),
                  ),
                ],
              )),
              const SizedBox(width: 16),
              Expanded(child: AppTextField(label: 'Price (\$)', hint: '0.00', controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true))),
            ]),
            const SizedBox(height: 16),

            AppTextField(label: 'Emoji Icon', hint: '☕', controller: _iconCtrl),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(widget.item != null ? 'Save Changes' : 'Add to Menu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}