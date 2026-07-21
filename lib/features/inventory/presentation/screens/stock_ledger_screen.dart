import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/features/items/presentation/providers/item_providers.dart';
import 'package:solar_erp_app/shared/utils/document_workflow.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/paginated_list_view.dart';

import '../providers/inventory_providers.dart';

class StockLedgerScreen extends ConsumerStatefulWidget {
  const StockLedgerScreen({super.key});

  @override
  ConsumerState<StockLedgerScreen> createState() => _StockLedgerScreenState();
}

class _StockLedgerScreenState extends ConsumerState<StockLedgerScreen> {
  final _invoiceSearch = TextEditingController();

  @override
  void dispose() {
    _invoiceSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerListProvider);
    final warehouses = ref.watch(warehousesProvider);
    final itemsAsync = ref.watch(approvedItemsProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Stock Ledger'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                warehouses.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (list) => DropdownButtonFormField<String?>(
                    value: state.warehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Warehouse',
                      isDense: true,
                    ),
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
                        ref.read(ledgerListProvider.notifier).setWarehouse(v),
                  ),
                ),
                const SizedBox(height: 8),
                itemsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (items) => DropdownButtonFormField<String?>(
                    value: state.itemId,
                    decoration: const InputDecoration(
                      labelText: 'Item',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All items'),
                      ),
                      ...items.map(
                        (i) => DropdownMenuItem(
                          value: i.id,
                          child: Text(i.name),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        ref.read(ledgerListProvider.notifier).setItem(v),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: state.transType,
                  decoration: const InputDecoration(
                    labelText: 'Transaction type',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All types'),
                    ),
                    ...DocumentWorkflow.inventoryTransTypes.map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    ),
                  ],
                  onChanged: (v) =>
                      ref.read(ledgerListProvider.notifier).setTransType(v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _invoiceSearch,
                  decoration: InputDecoration(
                    labelText: 'Invoice / reference',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => ref
                          .read(ledgerListProvider.notifier)
                          .setInvoiceNumber(_invoiceSearch.text),
                    ),
                  ),
                  onSubmitted: (v) => ref
                      .read(ledgerListProvider.notifier)
                      .setInvoiceNumber(v),
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
                            ref.read(ledgerListProvider.notifier).refresh(),
                      )
                    : PaginatedListView(
                        items: state.items,
                        isLoadingMore: state.isLoadingMore,
                        hasMore: state.hasMore,
                        onRefresh: () =>
                            ref.read(ledgerListProvider.notifier).refresh(),
                        onLoadMore: () =>
                            ref.read(ledgerListProvider.notifier).loadMore(),
                        empty: const EmptyState(
                          title: 'No transactions',
                          icon: Icons.history,
                        ),
                        itemBuilder: (context, tx, _) {
                          final color = switch (tx.transType) {
                            'in' => Colors.green,
                            'out' => Colors.red,
                            'transfer' => Colors.blue,
                            _ => Colors.orange,
                          };
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    color.withValues(alpha: 0.15),
                                child: Text(
                                  tx.transType.isNotEmpty
                                      ? tx.transType[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(color: color),
                                ),
                              ),
                              title: Text(tx.itemName),
                              subtitle: Text(
                                [
                                  tx.warehouseName,
                                  tx.transType,
                                  if (tx.referenceNumber != null &&
                                      tx.referenceNumber!.isNotEmpty)
                                    tx.referenceNumber,
                                  if (tx.createdAt != null)
                                    formatDateTime(tx.createdAt),
                                ].whereType<String>().join(' · '),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${tx.quantity > 0 && tx.transType == 'in' ? '+' : ''}${tx.quantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    'Bal ${tx.balanceAfter}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
