import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/providers/global_loading_provider.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/utils/validators.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/dialogs.dart';

import '../../data/models/inventory_models.dart';
import '../providers/inventory_providers.dart';

class WarehousesScreen extends ConsumerWidget {
  const WarehousesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(warehousesProvider);
    final canCreate =
        ref.watch(authProvider).hasPermission('inventory.create');
    final canUpdate =
        ref.watch(authProvider).hasPermission('inventory.update');

    return Scaffold(
      appBar: const AppAppBar(title: 'Warehouses'),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _showForm(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: cleanError(e),
          onRetry: () => ref.invalidate(warehousesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(warehousesProvider),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    title: 'No warehouses',
                    icon: Icons.warehouse_outlined,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(warehousesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final w = items[index];
                return Card(
                  child: ListTile(
                    title: Text(w.name),
                    subtitle: Text(
                      w.location == null || w.location!.isEmpty
                          ? 'No location'
                          : w.location!,
                    ),
                    trailing: canUpdate
                        ? PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _showForm(context, ref, warehouse: w);
                              } else if (value == 'deactivate') {
                                final ok = await showConfirmDialog(
                                  context,
                                  title: 'Deactivate warehouse',
                                  message:
                                      'Deactivate ${w.name}? This cannot be undone easily.',
                                  confirmLabel: 'Deactivate',
                                  isDestructive: true,
                                );
                                if (!ok) return;
                                ref
                                    .read(globalLoadingProvider.notifier)
                                    .showLoading('Deactivating...');
                                try {
                                  await ref
                                      .read(inventoryRepositoryProvider)
                                      .deactivateWarehouse(w.id);
                                  ref
                                      .read(globalLoadingProvider.notifier)
                                      .hide();
                                  ref
                                      .read(globalLoadingProvider.notifier)
                                      .showSuccess('Warehouse deactivated');
                                  ref.invalidate(warehousesProvider);
                                } catch (e) {
                                  ref
                                      .read(globalLoadingProvider.notifier)
                                      .hide();
                                  ref
                                      .read(globalLoadingProvider.notifier)
                                      .showApiError(e);
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'deactivate',
                                child: Text('Deactivate'),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref, {
    WarehouseModel? warehouse,
  }) async {
    final name = TextEditingController(text: warehouse?.name ?? '');
    final location = TextEditingController(text: warehouse?.location ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  warehouse == null ? 'New warehouse' : 'Edit warehouse',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  validator: (v) => AppValidators.entityName(v, 'Name'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: location,
                  decoration: const InputDecoration(labelText: 'Location'),
                  inputFormatters: [LengthLimitingTextInputFormatter(150)],
                  validator: (v) => AppValidators.maxLength(
                    v,
                    max: 150,
                    field: 'Location',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context, true);
                  },
                  child: Text(warehouse == null ? 'Create' : 'Update'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved != true) return;

    ref.read(globalLoadingProvider.notifier).showLoading(
          warehouse == null ? 'Creating...' : 'Updating...',
        );
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      if (warehouse == null) {
        await repo.createWarehouse(
          name: name.text.trim(),
          location:
              location.text.trim().isEmpty ? null : location.text.trim(),
        );
      } else {
        await repo.updateWarehouse(
          id: warehouse.id,
          name: name.text.trim(),
          location:
              location.text.trim().isEmpty ? null : location.text.trim(),
        );
      }
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess(
            warehouse == null ? 'Warehouse created' : 'Warehouse updated',
          );
      ref.invalidate(warehousesProvider);
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }
}
