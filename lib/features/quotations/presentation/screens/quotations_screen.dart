import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/paginated_list_view.dart';
import 'package:solar_erp_app/shared/widgets/premium_feature_components.dart';
import 'package:solar_erp_app/shared/widgets/premium_ui.dart';

import '../providers/quotation_providers.dart';

class QuotationsScreen extends ConsumerWidget {
  const QuotationsScreen({super.key});

  static const _filters = [
    FilterChipItem(value: '', label: 'All'),
    FilterChipItem(value: 'draft', label: 'Draft'),
    FilterChipItem(value: 'pending_approval', label: 'Pending'),
    FilterChipItem(value: 'sent', label: 'Sent'),
    FilterChipItem(value: 'rejected', label: 'Rejected'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quotationListProvider);
    final canCreate = ref.watch(authProvider).hasPermission('quotation.create');
    final canApprove =
        ref.watch(authProvider).hasPermission('quotation.approve');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppAppBar(
        title: 'Quotations',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(quotationListProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (canApprove)
            IconButton(
              tooltip: 'Approvals',
              onPressed: () =>
                  Navigator.pushNamed(context, '/quotations/approvals'),
              icon: const Icon(Icons.fact_check_outlined),
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              heroTag: 'quotations_screen_fab',
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/quotations/form',
                );
                if (result == true) {
                  ref.read(quotationListProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('New'),
            )
          : null,
      body: Column(
        children: [
          const SizedBox(height: 8),
          FilterChipBar(
            items: _filters,
            selected: state.status ?? '',
            onSelected: (v) => ref
                .read(quotationListProvider.notifier)
                .setStatus(v.isEmpty ? null : v),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const LoadingState()
                : state.error != null && state.items.isEmpty
                    ? ErrorState(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(quotationListProvider.notifier).refresh(),
                      )
                    : PaginatedListView(
                        items: state.items,
                        isLoadingMore: state.isLoadingMore,
                        hasMore: state.hasMore,
                        onRefresh: () =>
                            ref.read(quotationListProvider.notifier).refresh(),
                        onLoadMore: () =>
                            ref.read(quotationListProvider.notifier).loadMore(),
                        empty: const PremiumEmptyState(
                          title: 'No quotations',
                          subtitle: 'Create a quotation to get started',
                          icon: Icons.request_quote_outlined,
                        ),
                        itemBuilder: (context, q, index) {
                          final reason = q.rejectionReason?.trim();
                          final subtitle = q.status == 'rejected' &&
                                  reason != null &&
                                  reason.isNotEmpty
                              ? '${q.customerName}\nRejected: $reason'
                              : q.customerName;
                          return DocumentListTile(
                            title: q.quotationNumber,
                            subtitle: subtitle,
                            amount: formatInr(q.totalAmount),
                            status: q.status,
                            leadingIcon: Icons.request_quote_outlined,
                            onTap: () async {
                              await Navigator.pushNamed(
                                context,
                                '/quotations/detail',
                                arguments: q.id,
                              );
                              if (!context.mounted) return;
                              ref
                                  .read(quotationListProvider.notifier)
                                  .refresh();
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
