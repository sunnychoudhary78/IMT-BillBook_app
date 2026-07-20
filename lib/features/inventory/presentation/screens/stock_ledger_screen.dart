import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/paginated_list_view.dart';

import '../providers/inventory_providers.dart';

class StockLedgerScreen extends ConsumerWidget {
  const StockLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ledgerListProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Stock Ledger'),
      body: state.isLoading && state.items.isEmpty
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
                          backgroundColor: color.withValues(alpha: 0.15),
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
                            if (tx.createdAt != null)
                              formatDateTime(tx.createdAt),
                          ].join(' · '),
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
    );
  }
}
