import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/widgets/status_badge.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/constants/item_categories.dart';
import 'package:solar_erp_app/shared/constants/item_units.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/paginated_list_view.dart';

import '../providers/item_providers.dart';

class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itemListProvider);
    final canCreate = ref.watch(authProvider).hasPermission('item.create');
    final canApprove = ref.watch(authProvider).hasPermission('item.approve');

    return Scaffold(
      appBar: AppAppBar(
        title: 'Items',
        actions: [
          if (canApprove)
            IconButton(
              tooltip: 'Approvals',
              onPressed: () =>
                  Navigator.pushNamed(context, '/items/approvals'),
              icon: const Icon(Icons.fact_check_outlined),
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/items/form');
                if (result == true) {
                  ref.read(itemListProvider.notifier).refresh();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: ref.read(itemListProvider.notifier).setSearch,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: state.status == null,
                  onTap: () =>
                      ref.read(itemListProvider.notifier).setStatus(null),
                ),
                _FilterChip(
                  label: 'Pending',
                  selected: state.status == 'pending',
                  onTap: () =>
                      ref.read(itemListProvider.notifier).setStatus('pending'),
                ),
                _FilterChip(
                  label: 'Approved',
                  selected: state.status == 'approved',
                  onTap: () =>
                      ref.read(itemListProvider.notifier).setStatus('approved'),
                ),
                _FilterChip(
                  label: 'Rejected',
                  selected: state.status == 'rejected',
                  onTap: () =>
                      ref.read(itemListProvider.notifier).setStatus('rejected'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const LoadingState()
                : state.error != null && state.items.isEmpty
                    ? ErrorState(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(itemListProvider.notifier).refresh(),
                      )
                    : PaginatedListView(
                        items: state.items,
                        isLoadingMore: state.isLoadingMore,
                        hasMore: state.hasMore,
                        onRefresh: () =>
                            ref.read(itemListProvider.notifier).refresh(),
                        onLoadMore: () =>
                            ref.read(itemListProvider.notifier).loadMore(),
                        empty: const EmptyState(
                          title: 'No items found',
                          icon: Icons.inventory_2_outlined,
                        ),
                        itemBuilder: (context, item, _) {
                          return Card(
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                [
                                  if (item.category != null)
                                    ItemCategories.labelFor(item.category),
                                  if (item.sku != null) 'SKU: ${item.sku}',
                                  formatInr(item.sellingPrice),
                                  ItemUnits.labelFor(item.unit),
                                ].join(' · '),
                              ),
                              trailing: StatusBadge.forStatus(item.status),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/items/detail',
                                arguments: item.id,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
