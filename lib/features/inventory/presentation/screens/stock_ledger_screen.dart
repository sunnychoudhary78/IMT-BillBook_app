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
    final theme = Theme.of(context);
    final state = ref.watch(ledgerListProvider);
    final warehouses = ref.watch(warehousesProvider);
    final itemsAsync = ref.watch(approvedItemsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: const AppAppBar(title: 'Stock Ledger'),
      body: Column(
        children: [
          // Filter Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                TextField(
                  controller: _invoiceSearch,
                  decoration: InputDecoration(
                    hintText: 'Search invoice or reference...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _invoiceSearch.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _invoiceSearch.clear();
                              ref
                                  .read(ledgerListProvider.notifier)
                                  .setInvoiceNumber('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHigh,
                  ),
                  onSubmitted: (v) =>
                      ref.read(ledgerListProvider.notifier).setInvoiceNumber(v),
                ),
                const SizedBox(height: 12),

                // Warehouse & Item Selection Row
                Row(
                  children: [
                    // Warehouse Picker
                    Expanded(
                      child: warehouses.when(
                        loading: () => const SizedBox(
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (e, _) => TextButton(
                          onPressed: () => ref.invalidate(warehousesProvider),
                          child: Text(
                            'Warehouses failed — Retry',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        data:
                            (list) => // Warehouse Picker
                            _buildStyledDropdown<String?>(
                              context: context,
                              value: state.warehouseId,
                              hint: 'Warehouse',
                              icon: Icons.storefront,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'All Warehouses',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                ...list.map(
                                  (w) => DropdownMenuItem(
                                    value: w.id,
                                    child: Text(
                                      w.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) => ref
                                  .read(ledgerListProvider.notifier)
                                  .setWarehouse(v),
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Item Picker
                    Expanded(
                      child: itemsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data:
                            (items) => // Item Picker
                            _buildStyledDropdown<String?>(
                              context: context,
                              value: state.itemId,
                              hint: 'Item',
                              icon: Icons.inventory_2_outlined,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'All Items',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                ...items.map(
                                  (i) => DropdownMenuItem(
                                    value: i.id,
                                    child: Text(
                                      i.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) => ref
                                  .read(ledgerListProvider.notifier)
                                  .setItem(v),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transaction Type Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: state.transType == null,
                          label: const Text('All Types'),
                          onSelected: (_) => ref
                              .read(ledgerListProvider.notifier)
                              .setTransType(null),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      ...DocumentWorkflow.inventoryTransTypes.map((type) {
                        final isSelected = state.transType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(type.toUpperCase()),
                            onSelected: (selected) {
                              ref
                                  .read(ledgerListProvider.notifier)
                                  .setTransType(selected ? type : null);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ledger Transactions List
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
                    padding: const EdgeInsets.all(16),
                    items: state.items,
                    isLoadingMore: state.isLoadingMore,
                    hasMore: state.hasMore,
                    onRefresh: () =>
                        ref.read(ledgerListProvider.notifier).refresh(),
                    onLoadMore: () =>
                        ref.read(ledgerListProvider.notifier).loadMore(),
                    empty: const EmptyState(
                      title: 'No Transactions Found',
                      icon: Icons.history_toggle_off,
                    ),
                    itemBuilder: (context, tx, _) {
                      final config = _getTransConfig(tx.transType, theme);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Type Badge Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: config.color.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      config.icon,
                                      color: config.color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Item Name and Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.itemName,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.storefront,
                                              size: 14,
                                              color: theme.colorScheme.outline,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              tx.warehouseName,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .outline,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quantity Change
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${tx.quantity > 0 && tx.transType == 'in' ? '+' : ''}${tx.quantity}',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: config.color,
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .surfaceContainer,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'Bal: ${tx.balanceAfter}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1),
                              ),

                              // Footer Metadata (Type / Ref / Date)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: config.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tx.transType.toUpperCase(),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: config.color,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (tx.referenceNumber != null &&
                                      tx.referenceNumber!.isNotEmpty)
                                    InkWell(
                                      onTap: tx.isInvoiceReference
                                          ? () => Navigator.pushNamed(
                                                context,
                                                '/invoices/detail',
                                                arguments: tx.referenceId,
                                              )
                                          : null,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.receipt_long,
                                            size: 14,
                                            color: tx.isInvoiceReference
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.outline,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            tx.referenceNumber!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: tx.isInvoiceReference
                                                  ? theme.colorScheme.primary
                                                  : null,
                                              decoration: tx.isInvoiceReference
                                                  ? TextDecoration.underline
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Text(
                                      '—',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                  if (tx.createdAt != null) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      formatDateTime(tx.createdAt),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (tx.notes != null &&
                                  tx.notes!.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  tx.notes!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
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

  // Styled Dropdown builder
  Widget _buildStyledDropdown<T>({
    required BuildContext context,
    required T value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true, // Prevents text from pushing past border limits
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
      style: theme.textTheme.bodyMedium?.copyWith(
        overflow: TextOverflow.ellipsis,
      ),
      borderRadius: BorderRadius.circular(16), // Clean rounded dropdown overlay
      dropdownColor: theme.colorScheme.surface,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 6),
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 0),
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  // Helpers for Transaction styling
  _TransConfig _getTransConfig(String type, ThemeData theme) {
    switch (type.toLowerCase()) {
      case 'in':
        return _TransConfig(Colors.green, Icons.arrow_downward_rounded);
      case 'out':
        return _TransConfig(Colors.redAccent, Icons.arrow_upward_rounded);
      case 'transfer':
        return _TransConfig(Colors.blueAccent, Icons.swap_horiz_rounded);
      default:
        return _TransConfig(Colors.orangeAccent, Icons.compare_arrows_rounded);
    }
  }
}

class _TransConfig {
  final Color color;
  final IconData icon;
  _TransConfig(this.color, this.icon);
}
