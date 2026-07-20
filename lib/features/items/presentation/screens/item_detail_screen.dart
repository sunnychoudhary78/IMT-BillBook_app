import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/providers/global_loading_provider.dart';
import 'package:solar_erp_app/core/widgets/status_badge.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/constants/item_categories.dart';
import 'package:solar_erp_app/shared/constants/item_units.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/dialogs.dart';

import '../providers/item_providers.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(itemDetailProvider(itemId));
    final auth = ref.watch(authProvider);

    return async.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (e, _) => Scaffold(
        appBar: const AppAppBar(title: 'Item'),
        body: ErrorState(
          message: cleanError(e),
          onRetry: () => ref.invalidate(itemDetailProvider(itemId)),
        ),
      ),
      data: (item) {
        final canEdit = auth.hasPermission('item.update') &&
            item.status != 'approved';
        final canApprove =
            auth.hasPermission('item.approve') && item.status == 'pending';

        return Scaffold(
          appBar: AppAppBar(
            title: item.name,
            actions: [
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/items/form',
                      arguments: item.id,
                    );
                    if (result == true) {
                      ref.invalidate(itemDetailProvider(itemId));
                    }
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  StatusBadge.forStatus(item.status),
                ],
              ),
              if (item.rejectionReason != null &&
                  item.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Rejection: ${item.rejectionReason}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              _InfoRow('SKU', item.sku ?? '—'),
              _InfoRow('Category', ItemCategories.labelFor(item.category)),
              _InfoRow('HSN', item.hsnCode ?? '—'),
              _InfoRow('SAC', item.sacCode ?? '—'),
              _InfoRow('Unit', ItemUnits.labelFor(item.unit)),
              _InfoRow('GST', '${item.gstPercent}%'),
              _InfoRow('Price', formatInr(item.sellingPrice)),
              _InfoRow('Min stock', '${item.minStockLevel}'),
              if (item.totalQuantity != null)
                _InfoRow('Total qty', '${item.totalQuantity}'),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Description',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(item.description!),
              ],
              const SizedBox(height: 20),
              Text('Stock by warehouse',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (item.stockLevels.isEmpty)
                const Text('No stock records yet')
              else
                ...item.stockLevels.map(
                  (s) => Card(
                    child: ListTile(
                      title: Text(s.warehouseName ?? s.warehouseId),
                      trailing: Text(
                        '${s.currentQuantity}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              if (canApprove) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _approve(context, ref),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _reject(context, ref),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Approve item',
      message: 'Approve this item for use in quotations and inventory?',
      confirmLabel: 'Approve',
    );
    if (!ok) return;
    ref.read(globalLoadingProvider.notifier).showLoading('Approving...');
    try {
      await ref.read(itemRepositoryProvider).approve(itemId);
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('Item approved');
      ref.invalidate(itemDetailProvider(itemId));
      ref.invalidate(pendingItemsProvider);
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showReasonSheet(
      context,
      title: 'Reject item',
      hint: 'Reason for rejection',
    );
    if (reason == null || reason.isEmpty) return;
    ref.read(globalLoadingProvider.notifier).showLoading('Rejecting...');
    try {
      await ref.read(itemRepositoryProvider).reject(itemId, reason);
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('Item rejected');
      ref.invalidate(itemDetailProvider(itemId));
      ref.invalidate(pendingItemsProvider);
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
