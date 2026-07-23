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

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quotationListProvider);
    final canCreate = ref.watch(authProvider).hasPermission('quotation.create');
    final canApprove = ref.watch(authProvider).hasPermission('quotation.approve');
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
              style: IconButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHigh,
              ),
              onPressed: () => Navigator.pushNamed(context, '/quotations/approvals'),
              icon: const Icon(Icons.fact_check_outlined),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              heroTag: 'quotations_screen_fab',
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/quotations/form',
                );
                if (result == true) {
                  ref.read(quotationListProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Quotation',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Column(
        children: [
          // 2. Search & Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                // Connect search query handler if implemented on your notifier
                // ref.read(quotationListProvider.notifier).setSearchQuery(query);
              },
              decoration: InputDecoration(
                hintText: 'Search by ID, customer...',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          // ref.read(quotationListProvider.notifier).setSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: scheme.surfaceContainerHigh.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                  .read(quotationListProvider.notifier)
                  .setStatus(v.isEmpty ? null : v),
            ),
          ),

          // 3. Document List View
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
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        items: state.items,
                        isLoadingMore: state.isLoadingMore,
                        hasMore: state.hasMore,
                        onRefresh: () =>
                            ref.read(quotationListProvider.notifier).refresh(),
                        onLoadMore: () =>
                            ref.read(quotationListProvider.notifier).loadMore(),
                        empty: const PremiumEmptyState(
                          title: 'No quotations found',
                          subtitle: 'Create a new quotation to kick off your workflow.',
                          icon: Icons.request_quote_outlined,
                        ),
                        itemBuilder: (context, q, index) {
                          return _QuotationCard(
                            quotation: q,
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

/// Refactored Item Card Component
class _QuotationCard extends StatelessWidget {
  final dynamic quotation;
  final VoidCallback onTap;

  const _QuotationCard({
    required this.quotation,
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
    final statusColor = _getStatusColor(quotation.status, scheme);
    final reason = quotation.rejectionReason?.trim();
    final isRejected = quotation.status == 'rejected' && reason != null && reason.isNotEmpty;

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
                // Header row: ID + Status Badge
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
                            Icons.request_quote_outlined,
                            size: 18,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          quotation.quotationNumber ?? 'N/A',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _StatusBadge(
                      label: (quotation.status ?? 'Unknown').replaceAll('_', ' ').toUpperCase(),
                      color: statusColor,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Customer & Amount row
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
                            quotation.customerName ?? 'Unnamed Customer',
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
                          'Total Value',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatInr(quotation.totalAmount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Rejection reason banner (if applicable)
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

/// Helper Status Badge Chip
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