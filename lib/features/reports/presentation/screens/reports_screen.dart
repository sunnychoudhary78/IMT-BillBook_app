import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:solar_erp_app/core/theme/app_design.dart';
import 'package:solar_erp_app/core/widgets/status_badge.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/premium_feature_components.dart';

import '../providers/reports_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppAppBar(
        title: 'Reports',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(reportsProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: cleanError(e),
          onRetry: () => ref.invalidate(reportsProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(reportsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const PremiumFeatureHeader(
                icon: Icons.analytics_outlined,
                title: 'Analytics',
                subtitle: 'Quotations, invoices, stock and sales',
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Sales by Month',
                subtitle: 'Revenue from approved invoices',
                child: data.sales.isEmpty
                    ? const EmptyState(
                        title: 'No sales data',
                        icon: Icons.show_chart,
                      )
                    : Column(
                        children: data.sales.map((row) {
                          final label = row.month != null
                              ? DateFormat.yMMMM().format(row.month!)
                              : '—';
                          return ListTile(
                            title: Text(label),
                            subtitle: Text('${row.invoiceCount} invoices'),
                            trailing: Text(
                              formatInr(row.totalSales),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Stock Report',
                subtitle: 'Current inventory levels',
                child: data.stock.isEmpty
                    ? const EmptyState(
                        title: 'No stock data',
                        icon: Icons.inventory_2_outlined,
                      )
                    : Column(
                        children: data.stock.map((s) {
                          return ListTile(
                            title: Text(s.itemName),
                            subtitle: Text(s.warehouseName),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${s.currentQuantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  s.isLowStock ? 'Low' : 'OK',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: s.isLowStock
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Recent Quotations',
                child: data.quotations.isEmpty
                    ? const EmptyState(
                        title: 'No quotations',
                        icon: Icons.description_outlined,
                      )
                    : Column(
                        children: data.quotations.take(8).map((q) {
                          return ListTile(
                            title: Text(q.quotationNumber),
                            subtitle: Text(q.customerName ?? '—'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatInr(q.totalAmount)),
                                StatusBadge.forStatus(q.status),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Recent Invoices',
                child: data.invoices.isEmpty
                    ? const EmptyState(
                        title: 'No invoices',
                        icon: Icons.receipt_long_outlined,
                      )
                    : Column(
                        children: data.invoices.take(8).map((inv) {
                          return ListTile(
                            title: Text(inv.invoiceNumber),
                            subtitle: Text(inv.customerName ?? '—'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatInr(inv.totalAmount)),
                                StatusBadge.forStatus(inv.status),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
