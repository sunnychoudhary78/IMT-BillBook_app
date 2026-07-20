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
  bool _loading = false;
  PartyAddressModel _billTo = PartyAddressModel.empty();
  PartyAddressModel _shipTo = PartyAddressModel.empty();
  String? _fromBranchId = '';
  bool _shipSameAsBill = true;
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
      body: async.when(
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                value: _quotationId,
                decoration: const InputDecoration(
                  labelText: 'Approved quotation *',
                ),
                items: quotations
                    .map(
                      (q) => DropdownMenuItem(
                        value: q.id,
                        child: Text(
                          '${q.quotationNumber} · ${q.customerName}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) async {
                  setState(() => _quotationId = v);
                  await _loadPreview();
                },
              ),
              if (_preview != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _preview!.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('Total: ${formatInr(_preview!.totalAmount)}'),
                        Text('Items: ${_preview!.items.length}'),
                        const SizedBox(height: 8),
                        ..._preview!.items.map(
                          (line) => Text(
                            '${line.displayName} · ${line.quantity} x ${formatInr(line.unitPrice)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              brandingAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (branding) => Column(
                  children: [
                    FromAddressSelector(
                      branchId: _fromBranchId,
                      companyAddress: branding.companyAddress,
                      branches: branding.branchAddresses,
                      onChanged: (v) => setState(() => _fromBranchId = v),
                    ),
                    const SizedBox(height: 16),
                    PartyAddressEditor(
                      key: ValueKey('bill_${_billTo.name}_${_billTo.address}'),
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
                    if (!_shipSameAsBill)
                      PartyAddressEditor(
                        key: ValueKey(
                          'ship_${_shipTo.name}_${_shipTo.address}',
                        ),
                        title: 'Ship To',
                        party: _shipTo,
                        onChanged: (p) => setState(() => _shipTo = p),
                      ),
                  ],
                ),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _create,
                child: const Text('Create invoice'),
              ),
            ],
          );
        },
      ),
    );
  }
}
