import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/widgets/status_badge.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/constants/item_categories.dart';
import 'package:solar_erp_app/shared/constants/item_units.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';

import '../providers/item_providers.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(itemListProvider.notifier).setSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemListProvider);
    final authState = ref.watch(authProvider);
    final canCreate = authState.hasPermission('item.create');
    final canApprove = authState.hasPermission('item.approve');
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              elevation: 3,
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/items/form');
                if (result == true) {
                  ref.read(itemListProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.read(itemListProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern Collapsible App Bar
            SliverAppBar.medium(
              title: const Text(
                'Inventory Items',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
              actions: [
                if (canApprove) ...[
                  IconButton.filledTonal(
                    tooltip: 'Approvals',
                    onPressed: () => Navigator.pushNamed(context, '/items/approvals'),
                    icon: const Icon(Icons.fact_check_outlined, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),

            // Search Bar & Filters Zone
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    SearchBar(
                      controller: _searchController,
                      hintText: 'Search by item name, SKU, or category...',
                      onChanged: _onSearchChanged,
                      elevation: const WidgetStatePropertyAll(0),
                      side: WidgetStatePropertyAll(
                        BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Modern Pill Filter Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          _FilterSegmentPill(
                            label: 'All Items',
                            selected: state.status == null,
                            onTap: () => ref.read(itemListProvider.notifier).setStatus(null),
                          ),
                          _FilterSegmentPill(
                            label: 'Pending',
                            selected: state.status == 'pending',
                            onTap: () => ref.read(itemListProvider.notifier).setStatus('pending'),
                          ),
                          _FilterSegmentPill(
                            label: 'Approved',
                            selected: state.status == 'approved',
                            onTap: () => ref.read(itemListProvider.notifier).setStatus('approved'),
                          ),
                          _FilterSegmentPill(
                            label: 'Rejected',
                            selected: state.status == 'rejected',
                            onTap: () => ref.read(itemListProvider.notifier).setStatus('rejected'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Content Area handling states smoothly
            if (state.isLoading && state.items.isEmpty)
              const SliverFillRemaining(
                child: LoadingState(),
              )
            else if (state.error != null && state.items.isEmpty)
              SliverFillRemaining(
                child: ErrorState(
                  message: state.error!,
                  onRetry: () => ref.read(itemListProvider.notifier).refresh(),
                ),
              )
            else if (state.items.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  title: 'No items match your criteria',
                  icon: Icons.inventory_2_outlined,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == state.items.length) {
                        // Bottom Infinite Scroll Loading Indicator
                        if (state.hasMore) {
                          ref.read(itemListProvider.notifier).loadMore();
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator.adaptive()),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final item = state.items[index];
                      return _ItemTileCard(
                        item: item,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/items/detail',
                          arguments: item.id,
                        ),
                      );
                    },
                    childCount: state.items.length + (state.hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Filter Pills with smooth Material 3 visual feedback
class _FilterSegmentPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterSegmentPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          selectedColor: theme.colorScheme.primaryContainer,
          backgroundColor: theme.colorScheme.surface,
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1.0,
          ),
        ),
      ),
    );
  }
}

/// Modern Information-Dense Inventory Card
class _ItemTileCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _ItemTileCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
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
                // Top Row: Item Name & Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge.forStatus(item.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Tags Row: Category & SKU
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (item.category != null)
                      _MetaChip(
                        icon: Icons.category_outlined,
                        label: ItemCategories.labelFor(item.category),
                      ),
                    if (item.sku != null)
                      _MetaChip(
                        icon: Icons.qr_code_rounded,
                        label: 'SKU: ${item.sku}',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 12),

                // Bottom Row: Price & Unit display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELLING PRICE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatInr(item.sellingPrice),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ItemUnits.labelFor(item.unit),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper tag chip for card metadata
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}