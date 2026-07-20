import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/theme/app_design.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/premium_feature_components.dart';

class InventoryHubScreen extends ConsumerWidget {
  const InventoryHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;
    final canRead = auth.hasPermission('inventory.read');
    final canUpdate = auth.hasPermission('inventory.update');
    final canCreate = auth.hasPermission('inventory.create');

    final tiles = <_HubTile>[
      if (canRead)
        const _HubTile(
          title: 'Current Stock',
          subtitle: 'View stock by warehouse',
          icon: Icons.inventory_2_outlined,
          route: '/inventory/stock',
        ),
      if (canRead)
        const _HubTile(
          title: 'Stock Ledger',
          subtitle: 'Movement history',
          icon: Icons.history,
          route: '/inventory/ledger',
        ),
      if (canRead)
        const _HubTile(
          title: 'Low Stock',
          subtitle: 'Items below minimum',
          icon: Icons.warning_amber_outlined,
          route: '/inventory/low-stock',
        ),
      if (canRead || canCreate || canUpdate)
        const _HubTile(
          title: 'Warehouses',
          subtitle: 'Manage locations',
          icon: Icons.warehouse_outlined,
          route: '/inventory/warehouses',
        ),
    ];

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: const AppAppBar(title: 'Inventory'),
      body: tiles.isEmpty
          ? const PremiumEmptyState(
              icon: Icons.lock_outline,
              title: 'No inventory access',
              subtitle: 'Ask an admin to grant inventory permissions.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                const PremiumFeatureHeader(
                  icon: Icons.inventory_2_rounded,
                  title: 'Inventory hub',
                  subtitle: 'Stock levels, movements, and warehouses',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    children: [
                      for (final tile in tiles) ...[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            onTap: () =>
                                Navigator.pushNamed(context, tile.route),
                            child: PremiumCard(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: scheme.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                    ),
                                    child: Icon(
                                      tile.icon,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tile.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tile.subtitle,
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _HubTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _HubTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}
