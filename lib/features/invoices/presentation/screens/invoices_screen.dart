import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/theme/app_design.dart';
import 'package:solar_erp_app/core/widgets/status_badge.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/paginated_list_view.dart';
import 'package:solar_erp_app/shared/widgets/premium_feature_components.dart';

import '../providers/invoice_providers.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(invoiceListProvider);
    final canCreate = ref.watch(authProvider).hasPermission('invoice.create');
    final canApprove = ref.watch(authProvider).hasPermission('invoice.approve');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppAppBar(
        title: 'Invoices',
        actions: [
          if (canApprove)
            IconButton(
              tooltip: 'Approvals',
              onPressed: () =>
                  Navigator.pushNamed(context, '/invoices/approvals'),
              icon: const Icon(Icons.fact_check_outlined),
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/invoices/create');
                if (result == true) {
                  ref.read(invoiceListProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('New'),
            )
          : null,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm + 4,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                for (final entry in [
                  (null, 'All'),
                  ('draft', 'Draft'),
                  ('pending_approval', 'Pending'),
                  ('sent', 'Sent'),
                  ('rejected', 'Rejected'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.$2),
                      selected: state.status == entry.$1,
                      onSelected: (_) => ref
                          .read(invoiceListProvider.notifier)
                          .setStatus(entry.$1),
                    ),
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
                            ref.read(invoiceListProvider.notifier).refresh(),
                      )
                    : PaginatedListView(
                        items: state.items,
                        isLoadingMore: state.isLoadingMore,
                        hasMore: state.hasMore,
                        onRefresh: () =>
                            ref.read(invoiceListProvider.notifier).refresh(),
                        onLoadMore: () =>
                            ref.read(invoiceListProvider.notifier).loadMore(),
                        empty: const EmptyState(
                          title: 'No invoices',
                          subtitle: 'Create an invoice from a quotation',
                          icon: Icons.receipt_long_outlined,
                        ),
                        itemBuilder: (context, inv, _) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/invoices/detail',
                                  arguments: inv.id,
                                ),
                                child: PremiumCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              inv.invoiceNumber,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${inv.customerName} · ${formatInr(inv.totalAmount)}',
                                              style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusBadge.forStatus(inv.status),
                                    ],
                                  ),
                                ),
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
