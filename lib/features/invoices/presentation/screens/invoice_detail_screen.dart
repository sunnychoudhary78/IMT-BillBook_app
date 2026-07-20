import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/providers/global_loading_provider.dart';
import 'package:solar_erp_app/core/widgets/status_badge.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:solar_erp_app/shared/utils/document_workflow.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/utils/pdf_helper.dart';
import 'package:solar_erp_app/shared/utils/validators.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/dialogs.dart';

import '../../data/models/invoice_model.dart';
import '../providers/invoice_providers.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(invoiceDetailProvider(invoiceId));
    final auth = ref.watch(authProvider);

    return async.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (e, _) => Scaffold(
        appBar: const AppAppBar(title: 'Invoice'),
        body: ErrorState(
          message: cleanError(e),
          onRetry: () => ref.invalidate(invoiceDetailProvider(invoiceId)),
        ),
      ),
      data: (inv) {
        final canCreate = auth.hasPermission('invoice.create');
        final canApprove = auth.hasPermission('invoice.approve');
        final canSubmit = DocumentWorkflow.canSubmitInvoice(inv.status);
        final canEdit = DocumentWorkflow.canEditInvoice(
          inv.status,
          canCreate: canCreate,
          canApprove: canApprove,
          stockDeducted: inv.stockDeducted,
        );
        final isPending =
            DocumentWorkflow.canApproveOrRejectInvoice(inv.status);

        return Scaffold(
          appBar: AppAppBar(
            title: inv.invoiceNumber,
            actions: [
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/invoices/form',
                      arguments: inv.id,
                    );
                    if (result == true) {
                      ref.invalidate(invoiceDetailProvider(invoiceId));
                    }
                  },
                ),
              if (DocumentWorkflow.canDownloadInvoice(inv.status))
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => _downloadPdf(ref),
                ),
              if (DocumentWorkflow.canEmailInvoice(inv.status))
                IconButton(
                  icon: const Icon(Icons.email_outlined),
                  onPressed: () =>
                      _sendEmail(context, ref, inv.customer?.email),
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
                      inv.customerName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusBadge.forStatus(inv.status),
                ],
              ),
              if (inv.quotationNumber != null)
                Text('Quotation: ${inv.quotationNumber}'),
              if (inv.rejectionReason != null &&
                  inv.rejectionReason!.isNotEmpty)
                Text(
                  'Rejection: ${inv.rejectionReason}',
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              ...inv.items.map(
                (line) => Card(
                  child: ListTile(
                    title: Text(line.displayName),
                    subtitle: Text(
                      '${line.quantity} × ${formatInr(line.unitPrice)}',
                    ),
                    trailing: Text(formatInr(line.lineTotal)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _AmountRow('Subtotal', formatInr(inv.subtotal)),
              _AmountRow('GST', formatInr(inv.gstAmount)),
              _AmountRow('Total', formatInr(inv.totalAmount), bold: true),
              const SizedBox(height: 24),
              if (canCreate && canSubmit)
                FilledButton(
                  onPressed: () => _submit(context, ref),
                  child: const Text('Submit for approval'),
                ),
              if (canApprove && isPending) ...[
                FilledButton(
                  onPressed: () => _approve(context, ref),
                  child: const Text('Approve'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _reject(context, ref),
                  child: const Text('Reject'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Submit invoice',
      message: 'Submit this invoice for approval?',
      confirmLabel: 'Submit',
    );
    if (!ok) return;
    ref.read(globalLoadingProvider.notifier).showLoading('Submitting...');
    try {
      await ref.read(invoiceRepositoryProvider).submit(invoiceId);
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('Submitted');
      ref.invalidate(invoiceDetailProvider(invoiceId));
      ref.invalidate(invoiceListProvider);
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final warehouses = await ref.read(warehousesProvider.future);
    if (!context.mounted) return;
    if (warehouses.isEmpty) {
      ref
          .read(globalLoadingProvider.notifier)
          .showError('No warehouses available');
      return;
    }

    String? warehouseId = warehouses.first.id;
    StockCheckResult? stockCheck;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Approve invoice',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: warehouseId,
                    decoration:
                        const InputDecoration(labelText: 'Warehouse *'),
                    items: warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      setModalState(() {
                        warehouseId = v;
                        stockCheck = null;
                      });
                      if (v == null) return;
                      try {
                        final result = await ref
                            .read(invoiceRepositoryProvider)
                            .stockCheck(invoiceId, v);
                        setModalState(() => stockCheck = result);
                      } catch (e) {
                        setModalState(
                          () => stockCheck = StockCheckResult(
                            ok: false,
                            message: cleanError(e),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (stockCheck != null) ...[
                    Text(
                      stockCheck!.ok
                          ? 'Stock available'
                          : (stockCheck!.message ?? 'Insufficient stock'),
                      style: TextStyle(
                        color: stockCheck!.ok ? Colors.green : Colors.red,
                      ),
                    ),
                    ...stockCheck!.lines.map(
                      (l) => Text(
                        '${l.itemName ?? 'Item'}: need ${l.requiredQty}, have ${l.availableQty}',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: warehouseId == null ||
                            (stockCheck != null && !stockCheck!.ok)
                        ? null
                        : () => Navigator.pop(context, true),
                    child: const Text('Approve & deduct stock'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || warehouseId == null) return;

    // Run stock check if user didn't change dropdown
    if (stockCheck == null) {
      try {
        stockCheck = await ref
            .read(invoiceRepositoryProvider)
            .stockCheck(invoiceId, warehouseId!);
      } catch (e) {
        ref.read(globalLoadingProvider.notifier).showApiError(e);
        return;
      }
      if (stockCheck != null && !stockCheck!.ok) {
        ref
            .read(globalLoadingProvider.notifier)
            .showError(stockCheck!.message ?? 'Insufficient stock');
        return;
      }
    }

    ref.read(globalLoadingProvider.notifier).showLoading('Approving...');
    try {
      await ref
          .read(invoiceRepositoryProvider)
          .approve(invoiceId, warehouseId!);
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('Invoice approved');
      ref.invalidate(invoiceDetailProvider(invoiceId));
      ref.invalidate(pendingInvoicesProvider);
      ref.invalidate(invoiceListProvider);
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showReasonSheet(
      context,
      title: 'Reject invoice',
      hint: 'Reason for rejection',
    );
    if (reason == null || reason.isEmpty) return;
    ref.read(globalLoadingProvider.notifier).showLoading('Rejecting...');
    try {
      await ref.read(invoiceRepositoryProvider).reject(invoiceId, reason);
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('Rejected');
      ref.invalidate(invoiceDetailProvider(invoiceId));
      ref.invalidate(pendingInvoicesProvider);
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }

  Future<void> _downloadPdf(WidgetRef ref) async {
    ref.read(globalLoadingProvider.notifier).showLoading('Downloading PDF...');
    try {
      final bytes =
          await ref.read(invoiceRepositoryProvider).downloadPdf(invoiceId);
      await PdfHelper.saveAndOpen(bytes, filename: 'invoice-$invoiceId.pdf');
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('PDF opened');
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }

  Future<void> _sendEmail(
    BuildContext context,
    WidgetRef ref,
    String? defaultEmail,
  ) async {
    final controller = TextEditingController(text: defaultEmail ?? '');
    final email = await showModalBottomSheet<String>(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send invoice email',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Email (optional override)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isNotEmpty &&
                      AppValidators.optionalEmail(value) != null) {
                    return;
                  }
                  Navigator.pop(context, value);
                },
                child: const Text('Send'),
              ),
            ],
          ),
        );
      },
    );
    if (email == null) return;
    ref.read(globalLoadingProvider.notifier).showLoading('Sending email...');
    try {
      await ref.read(invoiceRepositoryProvider).sendEmail(
            invoiceId,
            email: email.isEmpty ? null : email,
          );
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('Email sent');
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _AmountRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}
