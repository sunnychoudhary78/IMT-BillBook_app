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
        _HubTile(
          title: 'Current Stock',
          subtitle: 'Real-time warehouse stock',
          icon: Icons.inventory_2_rounded,
          route: '/inventory/stock',
          accent: _HubAccent.primary,
        ),
      if (canRead)
        _HubTile(
          title: 'Stock Ledger',
          subtitle: 'Audit & movement history',
          icon: Icons.history_rounded,
          route: '/inventory/ledger',
          accent: _HubAccent.secondary,
        ),
      if (canRead)
        _HubTile(
          title: 'Low Stock',
          subtitle: 'Alerts & reorder levels',
          icon: Icons.warning_amber_rounded,
          route: '/inventory/low-stock',
          accent: _HubAccent.error,
          badgeText: 'Alerts',
        ),
      if (canRead || canCreate || canUpdate)
        _HubTile(
          title: 'Warehouses',
          subtitle: 'Locations & sites',
          icon: Icons.warehouse_rounded,
          route: '/inventory/warehouses',
          accent: _HubAccent.tertiary,
        ),
    ];

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: const AppAppBar(title: 'Inventory Hub'),
      body: tiles.isEmpty
          ? const PremiumEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'No Access Granted',
              subtitle:
                  'Please contact your workspace admin to enable inventory permissions.',
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: PremiumFeatureHeader(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventory Operations',
                    subtitle:
                        'Manage materials, track ledger history & monitor stock alerts',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5, // Clean balanced proportion
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _ModernHubCard(
                        tile: tiles[index],
                        scheme: scheme,
                      );
                    }, childCount: tiles.length),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
    );
  }
}

class _ModernHubCard extends StatelessWidget {
  final _HubTile tile;
  final ColorScheme scheme;

  const _ModernHubCard({required this.tile, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final primaryColor = _accentFor(scheme, tile.accent);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => Navigator.pushNamed(context, tile.route),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header: Icon + Option Badge/Chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(tile.icon, color: primaryColor, size: 22),
                    ),
                    if (tile.badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tile.badgeText!,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                  ],
                ),

                // Bottom Header: Title + Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tile.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
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

enum _HubAccent { primary, secondary, tertiary, error }

Color _accentFor(ColorScheme scheme, _HubAccent accent) {
  return switch (accent) {
    _HubAccent.primary => scheme.primary,
    _HubAccent.secondary => scheme.secondary,
    _HubAccent.tertiary => scheme.tertiary,
    _HubAccent.error => scheme.error,
  };
}

class _HubTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final _HubAccent accent;
  final String? badgeText;

  const _HubTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.accent,
    this.badgeText,
  });
}
