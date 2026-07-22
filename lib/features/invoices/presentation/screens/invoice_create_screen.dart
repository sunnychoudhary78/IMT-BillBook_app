import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/providers/global_loading_provider.dart';
import 'package:solar_erp_app/features/quotations/data/models/quotation_model.dart';
import 'package:solar_erp_app/features/quotations/presentation/providers/quotation_providers.dart';
import 'package:solar_erp_app/shared/models/party_address_model.dart';
import 'package:solar_erp_app/shared/providers/branding_providers.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/utils/validators.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/invoice_dispatch_fields.dart';
import 'package:solar_erp_app/shared/widgets/party_address_fields.dart';

import '../providers/invoice_providers.dart';

class InvoiceCreateScreen extends ConsumerStatefulWidget {
  final String? quotationId;

  const InvoiceCreateScreen({super.key, this.quotationId});

  @override
  ConsumerState<InvoiceCreateScreen> createState() =>
      _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends ConsumerState<InvoiceCreateScreen> {
  String? _quotationId;
  final _notes = TextEditingController();
  final _invoiceNumber = TextEditingController();
  final _motorVehicleNo = TextEditingController();
  final _ewayBillNo = TextEditingController();
  bool _loading = false;
  PartyAddressModel _billTo = PartyAddressModel.empty();
  PartyAddressModel _shipTo = PartyAddressModel.empty();
  String? _fromBranchId = '';
  bool _shipSameAsBill = true;
  String? _paymentMode;
  QuotationModel? _preview;

  @override
  void initState() {
    super.initState();
    _quotationId = widget.quotationId;
    if (_quotationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _invoiceNumber.dispose();
    _motorVehicleNo.dispose();
    _ewayBillNo.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    if (_quotationId == null) {
      setState(() => _preview = null);
      return;
    }
    try {
      final q = await ref
          .read(quotationRepositoryProvider)
          .getById(_quotationId!);
      if (!mounted) return;
      setState(() {
        _preview = q;
        _billTo = q.billTo ?? PartyAddressModel.fromCustomer(q.customer);
        _shipTo = q.shipTo ?? _billTo;
        _fromBranchId = q.fromBranchId ?? '';
        _shipSameAsBill = true;
        if (_notes.text.isEmpty && q.notes != null) {
          _notes.text = q.notes!;
        }
      });
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    }
  }

  Map<String, dynamic> _fromPartyPayload() {
    final branding = ref.read(solarBrandingProvider).value;
    if (branding == null) return {};
    return branding.fromPartyPayload(_fromBranchId);
  }

  Future<void> _create() async {
    if (_quotationId == null) {
      ref
          .read(globalLoadingProvider.notifier)
          .showError('Select a sent (invoiceable) quotation');
      return;
    }

    setState(() => _loading = true);
    ref
        .read(globalLoadingProvider.notifier)
        .showLoading('Creating invoice...');

    try {
      final inv = await ref.read(invoiceRepositoryProvider).createFromQuotation(
            quotationId: _quotationId!,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            invoiceNumber: _invoiceNumber.text.trim().isEmpty
                ? null
                : _invoiceNumber.text.trim(),
            paymentMode: _paymentMode,
            motorVehicleNo: _motorVehicleNo.text.trim().isEmpty
                ? null
                : _motorVehicleNo.text.trim(),
            ewayBillNo: _ewayBillNo.text.trim().isEmpty
                ? null
                : _ewayBillNo.text.trim(),
            billTo: _billTo,
            shipTo: _shipSameAsBill ? _billTo : _shipTo,
            shipSameAsBill: _shipSameAsBill,
            fromParty: _fromPartyPayload(),
          );
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('Invoice created');
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/invoices/detail',
        arguments: inv.id,
      );
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(invoiceableQuotationsProvider);
    final brandingAsync = ref.watch(solarBrandingProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Create Invoice'),
      body: SafeArea(
        child: async.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(
            message: cleanError(e),
            onRetry: () => ref.invalidate(invoiceableQuotationsProvider),
          ),
          data: (quotations) {
            if (quotations.isEmpty) {
              return const EmptyState(
                title: 'No invoiceable quotations',
                subtitle: 'Approve a quotation first',
                icon: Icons.request_quote_outlined,
              );
            }

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _quotationId,
                    decoration: const InputDecoration(
                      labelText: 'Approved quotation *',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: quotations.map((q) {
                      final formattedText =
                          '${q.quotationNumber} • ${q.customerName} (${formatInr(q.totalAmount)})';
                      return DropdownMenuItem<String>(
                        value: q.id,
                        child: Text(
                          formattedText,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) async {
                      setState(() => _quotationId = v);
                      await _loadPreview();
                    },
                  ),
                  if (_preview != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _preview!.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Total: ${formatInr(_preview!.totalAmount)}'),
                            Text('Items: ${_preview!.items.length}'),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 4),
                            ..._preview!.items.map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• ${line.displayName} · ${line.quantity} x ${formatInr(line.unitPrice)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  brandingAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (branding) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FromAddressSelector(
                          branchId: _fromBranchId,
                          companyAddress: branding.companyAddress,
                          branches: branding.branchAddresses,
                          onChanged: (v) => setState(() => _fromBranchId = v),
                        ),
                        const SizedBox(height: 16),
                        PartyAddressEditor(
                          key: ValueKey(
                            'bill_${_billTo.name}_${_billTo.address}',
                          ),
                          title: 'Bill To',
                          party: _billTo,
                          onChanged: (p) => setState(() {
                            _billTo = p;
                            if (_shipSameAsBill) _shipTo = p;
                          }),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Ship To same as Bill To'),
                          value: _shipSameAsBill,
                          onChanged: (v) => setState(() {
                            _shipSameAsBill = v ?? true;
                            if (_shipSameAsBill) _shipTo = _billTo;
                          }),
                        ),
                        if (!_shipSameAsBill) ...[
                          const SizedBox(height: 12),
                          PartyAddressEditor(
                            key: ValueKey(
                              'ship_${_shipTo.name}_${_shipTo.address}',
                            ),
                            title: 'Ship To',
                            party: _shipTo,
                            onChanged: (p) => setState(() => _shipTo = p),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _invoiceNumber,
                    decoration: const InputDecoration(
                      labelText: 'Invoice number (optional)',
                      hintText: 'Auto-generated if blank',
                    ),
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    validator: (v) => AppValidators.maxLength(
                      v,
                      max: 50,
                      field: 'Invoice number',
                    ),
                  ),
                  const SizedBox(height: 16),
                  InvoiceDispatchFields(
                    paymentMode: _paymentMode,
                    motorVehicleNo: _motorVehicleNo,
                    ewayBillNo: _ewayBillNo,
                    onPaymentModeChanged: (v) =>
                        setState(() => _paymentMode = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                    inputFormatters: [LengthLimitingTextInputFormatter(500)],
                    validator: (v) => AppValidators.maxLength(
                      v,
                      max: 500,
                      field: 'Notes',
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _create,
                      child: const Text(
                        'Create invoice',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}