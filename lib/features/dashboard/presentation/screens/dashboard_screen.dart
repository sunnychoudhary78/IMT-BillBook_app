import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:solar_erp_app/core/theme/app_design.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/constants/role_taglines.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/premium_feature_components.dart';
import 'package:solar_erp_app/shared/widgets/premium_ui.dart';

import '../../data/models/dashboard_model.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    final auth = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;
    final firstName = auth.profile?.name.split(' ').first ?? 'there';
    final subtitle = RoleTaglines.forRole(auth.profile?.roleName);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: cleanError(e),
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                PremiumFeatureHeader(
                  icon: Icons.waving_hand_rounded,
                  title: 'Hello, $firstName',
                  subtitle: subtitle,
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm + 4,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                ).appFadeSlide(index: 0),
                if (auth.hasPermission('stats.read')) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _KpiCard(
                          label: 'Total sales',
                          value: formatInr(data.totalSales),
                          icon: Icons.currency_rupee,
                          color: scheme.primary,
                          onTap: () => Navigator.pushNamed(context, '/reports_screen'),
                        ).appFadeSlide(index: 1),

                        _KpiCard(
                          label: 'Customers',
                          value: '${data.customersCount}',
                          icon: Icons.people_outline,
                          color: scheme.secondary,
                          onTap: () =>
                              Navigator.pushNamed(context, '/customers'),
                        ).appFadeSlide(index: 2),

                        _KpiCard(
                          label: 'Quotations',
                          value: '${data.quotationsCount}',
                          icon: Icons.request_quote_outlined,
                          color: scheme.tertiary,
                          onTap: () =>
                              Navigator.pushNamed(context, '/quotations'),
                        ).appFadeSlide(index: 3),

                        _KpiCard(
                          label: 'Invoices',
                          value: '${data.invoicesCount}',
                          icon: Icons.receipt_long_outlined,
                          color: scheme.primaryContainer,
                          iconColor: scheme.onPrimaryContainer,
                          onTap: () =>
                              Navigator.pushNamed(context, '/invoices'),
                        ).appFadeSlide(index: 4),

                        _KpiCard(
                          label: 'Pending approvals',
                          value:
                              '${data.pendingQuotations + data.pendingInvoices + data.pendingItemsCount}',
                          icon: Icons.pending_actions,
                          color: scheme.tertiaryContainer,
                          iconColor: scheme.onTertiaryContainer,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/quotations/approvals',
                          ),
                        ).appFadeSlide(index: 5),

                        _KpiCard(
                          label: 'Low stock',
                          value: '${data.lowStockCount}',
                          icon: Icons.warning_amber_outlined,
                          color: scheme.error,
                          onTap: () =>
                              Navigator.pushNamed(context, '/inventory/low-stock'),
                        ).appFadeSlide(index: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: const PremiumSectionTitle(title: 'Sales trend'),
                  ).appFadeSlide(index: 7),
                  const SizedBox(height: AppSpacing.sm + 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: SizedBox(
                      height: 220,
                      child: data.salesTrend.isEmpty
                          ? PremiumCard(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.show_chart,
                                      size: 36,
                                      color: scheme.primary.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'No sales data yet',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Trend appears after invoices land',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _SalesChart(points: data.salesTrend),
                    ),
                  ).appFadeSlide(index: 7),
                ],
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: const PremiumSectionTitle(title: 'Quick actions'),
                ).appFadeSlide(index: 8),
                const SizedBox(height: AppSpacing.sm + 4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (auth.hasPermission('customer.create'))
                        _QuickAction(
                          label: 'New customer',
                          icon: Icons.person_add_alt,
                          onTap: () =>
                              Navigator.pushNamed(context, '/customers/form'),
                        ).appFadeSlide(index: 1),
                      if (auth.hasPermission('quotation.create'))
                        _QuickAction(
                          label: 'New quotation',
                          icon: Icons.note_add_outlined,
                          onTap: () =>
                              Navigator.pushNamed(context, '/quotations/form'),
                        ).appFadeSlide(index: 2),
                      if (auth.hasPermission('invoice.create')) ...[
                        _QuickAction(
                          label: 'From quotation',
                          icon: Icons.receipt,
                          onTap: () =>
                              Navigator.pushNamed(context, '/invoices/create'),
                        ).appFadeSlide(index: 3),
                        _QuickAction(
                          label: 'Direct invoice',
                          icon: Icons.receipt_long_outlined,
                          onTap: () =>
                              Navigator.pushNamed(context, '/invoices/new'),
                        ).appFadeSlide(index: 4),
                      ],
                      if (auth.hasPermission('report.read'))
                        _QuickAction(
                          label: 'Reports',
                          icon: Icons.analytics_outlined,
                          onTap: () => Navigator.pushNamed(context, '/reports'),
                        ).appFadeSlide(index: 5),
                      if (auth.hasPermission('item.create'))
                        _QuickAction(
                          label: 'New item',
                          icon: Icons.add_box_outlined,
                          onTap: () =>
                              Navigator.pushNamed(context, '/items/form'),
                        ).appFadeSlide(index: 6),
                      if (auth.hasPermission('inventory.read'))
                        _QuickAction(
                          label: 'Inventory',
                          icon: Icons.inventory_2_outlined,
                          onTap: () =>
                              Navigator.pushNamed(context, '/inventory'),
                        ).appFadeSlide(index: 7),
                      if (auth.hasPermission('item.approve'))
                        _QuickAction(
                          label: 'Item approvals',
                          icon: Icons.fact_check_outlined,
                          onTap: () =>
                              Navigator.pushNamed(context, '/items/approvals'),
                        ).appFadeSlide(index: 8),
                      if (auth.hasPermission('quotation.approve'))
                        _QuickAction(
                          label: 'Quotation approvals',
                          icon: Icons.approval,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/quotations/approvals',
                          ),
                        ).appFadeSlide(index: 8),
                      if (auth.hasPermission('invoice.approve'))
                        _QuickAction(
                          label: 'Invoice approvals',
                          icon: Icons.verified_outlined,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/invoices/approvals',
                          ),
                        ).appFadeSlide(index: 8),
                    ],
                  ),
                ),
                if (data.lowStock.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: PremiumSectionTitle(title: 'Low stock alerts'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...data.lowStock
                      .take(5)
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: PremiumCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: scheme.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    s.itemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                PremiumStatusPill(
                                  label: '${s.totalQuantity}',
                                  color: scheme.error,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? iconColor;
  final VoidCallback? onTap; // 1. Yaha onTap add kiya

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.iconColor,
    this.onTap, // 2. Constructor me add kiya
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 44) / 2;
    final accent = iconColor ?? color;

    return SizedBox(
      width: width.clamp(140, 220),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: iconColor != null ? 1 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = (MediaQuery.sizeOf(context).width - 44) / 2;

    return SizedBox(
      width: width.clamp(140, 220),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: PremiumCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  final List<SalesPoint> points;

  const _SalesChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monthFmt = DateFormat('MMM');
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].totalSales));
    }

    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => Text(
                  NumberFormat.compact().format(value),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final month = points[i].month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      month == null ? '' : monthFmt.format(month),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: scheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: scheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
