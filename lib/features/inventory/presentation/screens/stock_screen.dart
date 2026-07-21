import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/providers/global_loading_provider.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/features/items/data/models/item_model.dart';
import 'package:solar_erp_app/features/items/presentation/providers/item_providers.dart';
import 'package:solar_erp_app/shared/utils/validators.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';

import '../../data/models/inventory_models.dart';
import '../providers/inventory_providers.dart';

enum _MoveType { stockIn, stockOut, transfer, adjustment }

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockListProvider);
    final warehouses = ref.watch(warehousesProvider);
    final canUpdate = ref.watch(authProvider).hasPermission('inventory.update');

    return Scaffold(
      appBar: AppAppBar(
        title: 'Stock',
        actions: [
          if (canUpdate)
            PopupMenuButton<_MoveType>(
              icon: const Icon(Icons.more_vert),
              onSelected: (type) => _showMoveSheet(context, ref, type),
              itemBuilder: (_) => const [
                PopupMenuItem(value: _MoveType.stockIn, child: Text('Stock In')),
                PopupMenuItem(value: _MoveType.stockOut, child: Text('Stock Out')),
                PopupMenuItem(value: _MoveType.transfer, child: Text('Transfer')),
                PopupMenuItem(
                  value: _MoveType.adjustment,
                  child: Text('Adjustment'),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: canUpdate
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _showMoveSheet(context, ref, _MoveType.stockIn),
              icon: const Icon(Icons.add),
              label: const Text('Stock In'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: warehouses.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) => DropdownButtonFormField<String?>(
                      value: state.warehouseId,
                      decoration:
                          const InputDecoration(labelText: 'Warehouse'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All warehouses'),
                        ),
                        ...list.map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          ref.read(stockListProvider.notifier).setWarehouse(v),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low only'),
                  selected: state.lowStockOnly,
                  onSelected: (v) =>
                      ref.read(stockListProvider.notifier).setLowStockOnly(v),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const LoadingState()
                : state.error != null && state.items.isEmpty
                    ? ErrorState(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(stockListProvider.notifier).refresh(),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(stockListProvider.notifier).refresh(),
                        child: state.items.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 120),
                                  EmptyState(
                                    title: 'No stock records',
                                    icon: Icons.inventory_2_outlined,
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final s = state.items[index];
                                  return Card(
                                    color: s.isLowStock
                                        ? Colors.orange.withValues(alpha: 0.08)
                                        : null,
                                    child: ListTile(
                                      title: Text(s.itemName),
                                      subtitle: Text(
                                        '${s.warehouseName} · Min ${s.minStock}',
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${s.currentQuantity}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: s.isLowStock
                                                  ? Colors.orange
                                                  : null,
                                            ),
                                          ),
                                          if (s.isLowStock)
                                            const Text(
                                              'Low',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showMoveSheet(
  BuildContext context,
  WidgetRef ref,
  _MoveType type,
) async {
  final stockableItems = await ref.read(stockableItemsProvider.future);
  final approvedItems = await ref.read(approvedItemsProvider.future);
  final warehouses = await ref.read(warehousesProvider.future);
  if (!context.mounted) return;

  final moveItems = (type == _MoveType.stockIn || type == _MoveType.adjustment)
      ? stockableItems
      : approvedItems;

  if (moveItems.isEmpty || warehouses.isEmpty) {
    ref.read(globalLoadingProvider.notifier).showError(
          moveItems.isEmpty
              ? (type == _MoveType.stockIn || type == _MoveType.adjustment
                  ? 'No stockable items'
                  : 'No approved items')
              : 'No warehouses',
        );
    return;
  }

  final stockLevels = await ref.read(inventoryRepositoryProvider).getStock();
  if (!context.mounted) return;

  int availableQty(String? iId, String? wId) {
    if (iId == null || wId == null) return 0;
    for (final s in stockLevels) {
      if (s.itemId == iId && s.warehouseId == wId) {
        return s.currentQuantity;
      }
    }
    return 0;
  }

  final formKey = GlobalKey<FormState>();
  String? itemId = moveItems.first.id;
  String? warehouseId = warehouses.first.id;
  String? fromWarehouseId = warehouses.first.id;
  String? toWarehouseId =
      warehouses.length > 1 ? warehouses[1].id : warehouses.first.id;
  final qty = TextEditingController();
  final notes = TextEditingController();

  final title = switch (type) {
    _MoveType.stockIn => 'Stock In',
    _MoveType.stockOut => 'Stock Out',
    _MoveType.transfer => 'Transfer',
    _MoveType.adjustment => 'Adjustment',
  };

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final available = type == _MoveType.stockOut
              ? availableQty(itemId, warehouseId)
              : 0;

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: itemId,
                      decoration: const InputDecoration(labelText: 'Item *'),
                      items: moveItems
                          .map(
                            (ItemModel i) => DropdownMenuItem(
                              value: i.id,
                              child: Text(
                                i.status == 'pending'
                                    ? '${i.name} (pending)'
                                    : i.name,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => itemId = v),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select an item' : null,
                    ),
                    const SizedBox(height: 8),
                    if (type == _MoveType.transfer) ...[
                      DropdownButtonFormField<String>(
                        value: fromWarehouseId,
                        decoration:
                            const InputDecoration(labelText: 'From *'),
                        items: warehouses
                            .map(
                              (w) => DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => fromWarehouseId = v),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Select source warehouse'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: toWarehouseId,
                        decoration: const InputDecoration(labelText: 'To *'),
                        items: warehouses
                            .map(
                              (w) => DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => toWarehouseId = v),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Select destination warehouse';
                          }
                          if (v == fromWarehouseId) {
                            return 'Source and destination must differ';
                          }
                          return null;
                        },
                      ),
                    ] else
                      DropdownButtonFormField<String>(
                        value: warehouseId,
                        decoration:
                            const InputDecoration(labelText: 'Warehouse *'),
                        items: warehouses
                            .map(
                              (WarehouseModel w) => DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => warehouseId = v),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Select a warehouse'
                            : null,
                      ),
                    if (type == _MoveType.stockOut) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Available: $available',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: qty,
                      decoration: InputDecoration(
                        labelText: type == _MoveType.adjustment
                            ? 'New quantity *'
                            : 'Quantity *',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: (v) {
                        if (type == _MoveType.adjustment) {
                          return AppValidators.nonNegativeNumber(v, 'Quantity');
                        }
                        final base = AppValidators.positiveNumber(v, 'Quantity');
                        if (base != null) return base;
                        if (type == _MoveType.stockOut) {
                          final q = int.tryParse(v?.trim() ?? '') ?? 0;
                          if (q > available) {
                            return 'Quantity exceeds available stock ($available)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notes,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(250),
                      ],
                      validator: (v) => AppValidators.maxLength(
                        v,
                        max: 250,
                        field: 'Notes',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        if (type == _MoveType.transfer &&
                            fromWarehouseId == toWarehouseId) {
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  if (saved != true) return;

  if (type == _MoveType.transfer && fromWarehouseId == toWarehouseId) {
    ref.read(globalLoadingProvider.notifier).showError(
          'Source and destination warehouses must differ',
        );
    return;
  }

  final quantity = int.parse(qty.text.trim());
  final note = notes.text.trim().isEmpty ? null : notes.text.trim();
  final repo = ref.read(inventoryRepositoryProvider);

  ref.read(globalLoadingProvider.notifier).showLoading('Updating stock...');
  try {
    switch (type) {
      case _MoveType.stockIn:
        await repo.stockIn(
          itemId: itemId!,
          warehouseId: warehouseId!,
          quantity: quantity,
          notes: note,
        );
      case _MoveType.stockOut:
        await repo.stockOut(
          itemId: itemId!,
          warehouseId: warehouseId!,
          quantity: quantity,
          notes: note,
        );
      case _MoveType.transfer:
        await repo.stockTransfer(
          itemId: itemId!,
          fromWarehouseId: fromWarehouseId!,
          toWarehouseId: toWarehouseId!,
          quantity: quantity,
          notes: note,
        );
      case _MoveType.adjustment:
        await repo.stockAdjustment(
          itemId: itemId!,
          warehouseId: warehouseId!,
          quantity: quantity,
          notes: note,
        );
    }
    ref.read(globalLoadingProvider.notifier).hide();
    ref.read(globalLoadingProvider.notifier).showSuccess('Stock updated');
    ref.read(stockListProvider.notifier).refresh();
    ref.invalidate(lowStockProvider);
    ref.invalidate(ledgerListProvider);
  } catch (e) {
    ref.read(globalLoadingProvider.notifier).hide();
    ref.read(globalLoadingProvider.notifier).showApiError(e);
  }
}
