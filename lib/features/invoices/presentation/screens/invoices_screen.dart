import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/theme/app_design.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/paginated_list_view.dart';
import 'package:solar_erp_app/shared/widgets/premium_feature_components.dart';
import 'package:solar_erp_app/shared/widgets/premium_ui.dart';

import '../providers/invoice_providers.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  static const _filters = [
    FilterChipItem(value: '', label: 'All'),
    FilterChipItem(value: 'draft', label: 'Draft'),
    FilterChipItem(value: 'pending_approval', label: 'Pending'),
    FilterChipItem(value: 'sent', label: 'Sent'),
    FilterChipItem(value: 'rejected', label: 'Rejected'),
  ];

  static Future<void> _showCreateMenu(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.receipt_long_outlined, color: scheme.primary),
                ),
                title: const Text(
                  'From quotation',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Create from an approved quotation'),
                onTap: () => Navigator.pop(context, 'quotation'),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.add_circle_outline, color: scheme.tertiary),
                ),
                title: const Text(
                  'Direct invoice',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Customer + line items, no quotation'),
                onTap: () => Navigator.pop(context, 'direct'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'quotation') {
      final result = await Navigator.pushNamed(context, '/invoices/create');
      if (result == true) {
        ref.read(invoiceListProvider.notifier).refresh();
      }
    } else if (choice == 'direct') {
      await Navigator.pushNamed(context, '/invoices/new');
      ref.read(invoiceListProvider.notifier).refresh();
    }
  }

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
              onPressed: () => _showCreateMenu(context, ref),
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
                .read(invoiceListProvider.notifier)
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
                        empty: const PremiumEmptyState(
                          title: 'No invoices',
                          subtitle: 'Create an invoice from a quotation',
                          icon: Icons.receipt_long_outlined,
                        ),
                        itemBuilder: (context, inv, index) {
                          final reason = inv.rejectionReason?.trim();
                          final subtitle = inv.status == 'rejected' &&
                                  reason != null &&
                                  reason.isNotEmpty
                              ? '${inv.customerName}\nRejected: $reason'
                              : inv.customerName;
                          return DocumentListTile(
                            title: inv.invoiceNumber,
                            subtitle: subtitle,
                            amount: formatInr(inv.totalAmount),
                            status: inv.status,
                            leadingIcon: Icons.receipt_long_outlined,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/invoices/detail',
                              arguments: inv.id,
                            ),
                          ).appFadeSlide(index: index);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
