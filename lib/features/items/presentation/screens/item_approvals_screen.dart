import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/providers/global_loading_provider.dart';
import 'package:solar_erp_app/core/widgets/status_badge.dart';
import 'package:solar_erp_app/shared/constants/item_categories.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/dialogs.dart';

import '../providers/item_providers.dart';

class ItemApprovalsScreen extends ConsumerWidget {
  const ItemApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingItemsProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Item Approvals'),
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: cleanError(e),
          onRetry: () => ref.invalidate(pendingItemsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(pendingItemsProvider),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    title: 'No pending items',
                    subtitle: 'All caught up',
                    icon: Icons.verified_outlined,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingItemsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            StatusBadge.forStatus(item.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (item.category != null)
                              ItemCategories.labelFor(item.category),
                            if (item.sku != null) 'SKU: ${item.sku}',
                            formatInr(item.sellingPrice),
                          ].join(' · '),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _approve(context, ref, item.id),
                                child: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _reject(context, ref, item.id),
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/items/form',
                              arguments: item.id,
                            );
                            if (result == true) {
                              ref.invalidate(pendingItemsProvider);
                              ref.invalidate(itemListProvider);
                            }
                          },
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Approve item',
      message: 'Approve this item?',
      confirmLabel: 'Approve',
    );
    if (!ok) return;
    ref.read(globalLoadingProvider.notifier).showLoading('Approving...');
    try {
      await ref.read(itemRepositoryProvider).approve(id);
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('Approved');
      ref.invalidate(pendingItemsProvider);
      ref.invalidate(itemListProvider);
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final reason = await showReasonSheet(
      context,
      title: 'Reject item',
      hint: 'Reason for rejection',
    );
    if (reason == null || reason.isEmpty) return;
    ref.read(globalLoadingProvider.notifier).showLoading('Rejecting...');
    try {
      await ref.read(itemRepositoryProvider).reject(id, reason);
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('Rejected');
      ref.invalidate(pendingItemsProvider);
      ref.invalidate(itemListProvider);
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }
}
