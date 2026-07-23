import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/theme/app_design.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/paginated_list_view.dart';
import 'package:solar_erp_app/shared/widgets/premium_feature_components.dart';
import 'package:solar_erp_app/shared/widgets/premium_ui.dart';

import '../providers/customer_providers.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerListProvider);
    final canCreate = ref.watch(authProvider).hasPermission('customer.create');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: const AppAppBar(title: 'Customers'),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/customers/form');
                if (result == true) {
                  ref.read(customerListProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm + 4,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surfaceContainerLow,
              ),
              onChanged: ref.read(customerListProvider.notifier).setSearch,
            ),
          ),
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const LoadingState()
                : state.error != null && state.items.isEmpty
                    ? ErrorState(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(customerListProvider.notifier).refresh(),
                      )
                    : PaginatedListView(
                        items: state.items,
                        isLoadingMore: state.isLoadingMore,
                        hasMore: state.hasMore,
                        onRefresh: () =>
                            ref.read(customerListProvider.notifier).refresh(),
                        onLoadMore: () =>
                            ref.read(customerListProvider.notifier).loadMore(),
                        empty: const PremiumEmptyState(
                          title: 'No customers found',
                          subtitle: 'Add a customer to get started',
                          icon: Icons.people_outline,
                        ),
                        itemBuilder: (context, customer, index) {
                          return DocumentListTile(
                            title: customer.name,
                            subtitle: customer.subtitle.isEmpty
                                ? 'No contact info'
                                : customer.subtitle,
                            leadingLabel: customer.name,
                            onTap: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/customers/form',
                                arguments: customer.id,
                              );
                              if (result == true) {
                                ref
                                    .read(customerListProvider.notifier)
                                    .refresh();
                              }
                            },
                          ).appFadeSlide(index: index);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
