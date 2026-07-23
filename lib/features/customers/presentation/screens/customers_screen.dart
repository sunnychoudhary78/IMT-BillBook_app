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

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerListProvider);
    final canCreate = ref.watch(authProvider).hasPermission('customer.create');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: const AppAppBar(title: 'Customers'),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              heroTag: 'customers_screen_fab',
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/customers/form',
                );
                if (result == true) {
                  ref.read(customerListProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Add Customer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Column(
        children: [
        
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name..',
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant.withOpacity(0.7),
                ),
                prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(customerListProvider.notifier).setSearch('');
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
              onChanged: (value) {
                ref.read(customerListProvider.notifier).setSearch(value);
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 4),

          // 3. Customer List
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    items: state.items,
                    isLoadingMore: state.isLoadingMore,
                    hasMore: state.hasMore,
                    onRefresh: () =>
                        ref.read(customerListProvider.notifier).refresh(),
                    onLoadMore: () =>
                        ref.read(customerListProvider.notifier).loadMore(),
                    empty: const PremiumEmptyState(
                      title: 'No customers found',
                      subtitle:
                          'Add your first customer to manage contacts and orders.',
                      icon: Icons.people_outline_rounded,
                    ),
                    itemBuilder: (context, customer, index) {
                      return _CustomerCard(
                        customer: customer,
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/customers/form',
                            arguments: customer.id,
                          );
                          if (result == true) {
                            ref.read(customerListProvider.notifier).refresh();
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

/// Refactored Modern Customer Card Component
class _CustomerCard extends StatelessWidget {
  final dynamic customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'C';
    final parts = trimmed.split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initials = _getInitials(customer.name ?? '');

    final phone = customer.phone ?? customer.mobile;
    final email = customer.email;
    final hasSubtitle =
        customer.subtitle != null &&
        customer.subtitle.toString().isNotEmpty &&
        customer.subtitle != 'No contact info';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
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
            child: Row(
              children: [
                // Generated Avatar Badge
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Customer Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name ?? 'Unnamed Customer',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasSubtitle
                            ? customer.subtitle
                            : (phone ?? email ?? 'No direct contact info'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Traversal Affordance Indicator
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
