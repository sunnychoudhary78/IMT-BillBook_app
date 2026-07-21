import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/theme/app_design.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/widgets/dialogs.dart';

class DrawerMainDestination {
  final String label;
  final IconData icon;
  final int index;

  const DrawerMainDestination({
    required this.label,
    required this.icon,
    required this.index,
  });
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    required this.mainDestinations,
    required this.selectedMainIndex,
    required this.onSelectMain,
  });

  final List<DrawerMainDestination> mainDestinations;
  final int selectedMainIndex;
  final ValueChanged<int> onSelectMain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final route = ModalRoute.of(context)?.settings.name;
    final drawerRadius = Radius.circular(isIOS ? 16 : 24);

    var index = 0;

    final catalogItems = <Widget>[
      if (auth.hasPermission('item.read'))
        _DrawerTile(
          index: index++,
          icon: Icons.category_outlined,
          title: 'Items',
          isActive: route == '/items',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/items');
          },
        ),
    ];

    final approvalItems = <Widget>[
      if (auth.hasPermission('item.approve'))
        _DrawerTile(
          index: index++,
          icon: Icons.fact_check_outlined,
          title: 'Item Approvals',
          isActive: route == '/items/approvals',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/items/approvals');
          },
        ),
      if (auth.hasPermission('quotation.approve'))
        _DrawerTile(
          index: index++,
          icon: Icons.approval,
          title: 'Quotation Approvals',
          isActive: route == '/quotations/approvals',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/quotations/approvals');
          },
        ),
      if (auth.hasPermission('invoice.approve'))
        _DrawerTile(
          index: index++,
          icon: Icons.verified_outlined,
          title: 'Invoice Approvals',
          isActive: route == '/invoices/approvals',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/invoices/approvals');
          },
        ),
    ];

    return Drawer(
      backgroundColor: scheme.surface,
      elevation: isIOS ? 6 : 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: drawerRadius,
          bottomRight: drawerRadius,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: isIOS
                    ? const BouncingScrollPhysics()
                    : const ClampingScrollPhysics(),
                children: [
                  _DrawerHeader(
                    name: auth.profile?.name ?? 'User',
                    email: auth.profile?.email ?? '',
                    role: auth.profile?.roleName,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _SectionLabel('Main'),
                  for (final dest in mainDestinations)
                    _DrawerTile(
                      index: index++,
                      icon: dest.icon,
                      title: dest.label,
                      isActive: selectedMainIndex == dest.index,
                      onTap: () {
                        Navigator.pop(context);
                        onSelectMain(dest.index);
                      },
                    ),
                  if (catalogItems.isNotEmpty) ...[
                    const _SectionLabel('Catalog'),
                    ...catalogItems,
                  ],
                  if (approvalItems.isNotEmpty) ...[
                    const _SectionLabel('Approvals'),
                    ...approvalItems,
                  ],
                  const _SectionLabel('App'),
                  if (auth.hasPermission('report.read'))
                    _DrawerTile(
                      index: index++,
                      icon: Icons.analytics_outlined,
                      title: 'Reports',
                      isActive: route == '/reports',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/reports');
                      },
                    ),
                  _DrawerTile(
                    index: index++,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    isActive: route == '/settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            Divider(color: scheme.outlineVariant, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _DrawerTile(
                index: index++,
                icon: Icons.logout_rounded,
                title: 'Logout',
                onTap: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Logout',
                    message: 'Are you sure you want to sign out?',
                    confirmLabel: 'Logout',
                    isDestructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.name,
    required this.email,
    this.role,
  });

  final String name;
  final String email;
  final String? role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final onHeader = isDark ? scheme.onSurface : scheme.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? const Color(0xFF1E1E2E) : scheme.primary,
            isDark ? const Color(0xFF2A2A40) : scheme.primaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_long_rounded, color: scheme.primary),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: onHeader,
            ),
          ),
          if (role != null && role!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              role!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: onHeader.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: onHeader.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.index,
    this.isActive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int index;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final tileRadius = BorderRadius.circular(isIOS ? 12 : 14);
    final isLogout = title == 'Logout';
    final accent = isLogout ? scheme.error : scheme.primary;
    final muted = isLogout ? scheme.error : scheme.onSurfaceVariant;
    final label = isLogout ? scheme.error : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Material(
        color: isActive
            ? scheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: tileRadius,
        child: InkWell(
          borderRadius: tileRadius,
          splashFactory:
              isIOS ? NoSplash.splashFactory : InkSplash.splashFactory,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? accent : muted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: isActive ? accent : label,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 40).ms)
        .fade(duration: 280.ms)
        .slideX(begin: -0.12, end: 0, curve: Curves.easeOutCubic);
  }
}
