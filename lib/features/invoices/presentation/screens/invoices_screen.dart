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

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const _filters = [
    FilterChipItem(value: '', label: 'All'),
    FilterChipItem(value: 'draft', label: 'Draft'),
    FilterChipItem(value: 'pending_approval', label: 'Pending'),
    FilterChipItem(value: 'sent', label: 'Sent'),
    FilterChipItem(value: 'rejected', label: 'Rejected'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static Future<void> _showCreateMenu(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  'Create New Invoice',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.receipt_long_outlined, color: scheme.primary),
                ),
                title: const Text(
                  'From quotation',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Convert an existing approved quotation'),
                onTap: () => Navigator.pop(context, 'quotation'),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.add_circle_outline, color: scheme.tertiary),
                ),
                title: const Text(
                  'Direct invoice',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Select customer & line items directly'),
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
  Widget build(BuildContext context) {
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
              style: IconButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHigh,
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, '/invoices/approvals'),
              icon: const Icon(Icons.fact_check_outlined),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              heroTag: 'invoices_screen_fab',
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () => _showCreateMenu(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Invoice',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                // Hook search logic if available on provider:
                // ref.read(invoiceListProvider.notifier).setSearchQuery(query);
              },
              decoration: InputDecoration(
                hintText: 'Search invoice , customer...',
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant.withOpacity(0.7),
                ),
                prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          // ref.read(invoiceListProvider.notifier).setSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: scheme.surfaceContainerHigh.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FilterChipBar(
              items: _filters,
              selected: state.status ?? '',
              onSelected: (v) => ref
                  .read(invoiceListProvider.notifier)
                  .setStatus(v.isEmpty ? null : v),
            ),
          ),

          // 3. Main Document List View
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
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        items: state.items,
                        isLoadingMore: state.isLoadingMore,
                        hasMore: state.hasMore,
                        onRefresh: () =>
                            ref.read(invoiceListProvider.notifier).refresh(),
                        onLoadMore: () =>
                            ref.read(invoiceListProvider.notifier).loadMore(),
                        empty: const PremiumEmptyState(
                          title: 'No invoices found',
                          subtitle: 'Create your first invoice directly or convert a quotation.',
                          icon: Icons.receipt_long_outlined,
                        ),
                        itemBuilder: (context, inv, index) {
                          return _InvoiceCard(
                            invoice: inv,
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


/// Refactored Modern Invoice Card Component
class _InvoiceCard extends StatelessWidget {
  final dynamic invoice;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
  });

  Color _getStatusColor(String? status, ColorScheme scheme) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'pending_approval':
        return Colors.amber.shade700;
      case 'sent':
        return Colors.blue;
      case 'approved':
      case 'paid':
        return Colors.green;
      case 'rejected':
        return scheme.error;
      default:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = _getStatusColor(invoice.status, scheme);
    final reason = invoice.rejectionReason?.trim();
    final isRejected =
        invoice.status == 'rejected' && reason != null && reason.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Invoice # + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          invoice.invoiceNumber ?? 'N/A',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _StatusBadge(
                      label: (invoice.status ?? 'Unknown')
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      color: statusColor,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Customer & Total Amount Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            invoice.customerName ?? 'Unnamed Customer',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Invoice Amount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatInr(invoice.totalAmount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Rejection Reason Alert Box
                if (isRejected) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.error.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: scheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reason: $reason',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status Tag Badge Component
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}