import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/providers/global_loading_provider.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/features/customers/data/models/customer_model.dart';
import 'package:solar_erp_app/features/customers/presentation/providers/customer_providers.dart';
import 'package:solar_erp_app/features/items/data/models/item_model.dart';
import 'package:solar_erp_app/features/items/presentation/providers/item_providers.dart';
import 'package:solar_erp_app/shared/constants/item_units.dart';
import 'package:solar_erp_app/shared/models/party_address_model.dart';
import 'package:solar_erp_app/shared/providers/branding_providers.dart';
import 'package:solar_erp_app/shared/utils/document_workflow.dart';
import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/utils/validators.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/party_address_fields.dart';

import '../../data/models/quotation_model.dart';
import '../providers/quotation_providers.dart';

class _LineDraft {
  String? itemId;
  final qty = TextEditingController(text: '1');
  final price = TextEditingController();
  final gst = TextEditingController(text: '18');
  final description = TextEditingController();

  void dispose() {
    qty.dispose();
    price.dispose();
    gst.dispose();
    description.dispose();
  }
}

class QuotationFormScreen extends ConsumerStatefulWidget {
  final String? quotationId;

  const QuotationFormScreen({super.key, this.quotationId});

  @override
  ConsumerState<QuotationFormScreen> createState() =>
      _QuotationFormScreenState();
}

class _QuotationFormScreenState extends ConsumerState<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  String? _customerId;
  DateTime? _validUntil;
  final List<_LineDraft> _lines = [_LineDraft()];
  bool _initialized = false;
  bool _loading = false;
  String? _status;
  bool _editBlocked = false;
  PartyAddressModel _billTo = PartyAddressModel.empty();
  PartyAddressModel _shipTo = PartyAddressModel.empty();
  String? _fromBranchId = '';
  bool _shipSameAsBill = true;

  bool get isEdit => widget.quotationId != null;

  @override
  void dispose() {
    _notes.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _fill(QuotationModel q) {
    _status = q.status;
    _customerId = q.customerId;
    _notes.text = q.notes ?? '';
    _validUntil = q.validUntil;
    for (final l in _lines) {
      l.dispose();
    }
    _lines
      ..clear()
      ..addAll(q.items.map((item) {
        final line = _LineDraft();
        line.itemId = item.itemId;
        line.qty.text = item.quantity.toString();
        line.price.text = item.unitPrice.toString();
        line.gst.text = item.gstPercent.toString();
        line.description.text = item.description ?? '';
        return line;
      }));
    if (_lines.isEmpty) _lines.add(_LineDraft());
    _billTo = q.billTo ?? PartyAddressModel.fromCustomer(q.customer);
    _shipTo = q.shipTo ?? _billTo;
    _fromBranchId = q.fromBranchId ?? '';
    _shipSameAsBill = _shipTo.name == _billTo.name &&
        _shipTo.address == _billTo.address;
  }

  void _onCustomerChanged(String? id, List<CustomerModel> customers) {
    setState(() {
      _customerId = id;
      if (id != null) {
        CustomerModel? cust;
        for (final c in customers) {
          if (c.id == id) {
            cust = c;
            break;
          }
        }
        if (cust != null) {
          final party = PartyAddressModel.fromCustomer(cust);
          _billTo = party;
          _shipTo = party;
          _shipSameAsBill = true;
        }
      }
    });
  }

  Map<String, dynamic> _fromPartyPayload() {
    final branding = ref.read(solarBrandingProvider).value;
    if (branding == null) return {};
    return branding.fromPartyPayload(_fromBranchId);
  }

  bool _assertCanEdit() {
    if (!isEdit) return true;
    final auth = ref.read(authProvider);
    final canEdit = DocumentWorkflow.canEditQuotation(
      _status ?? '',
      canCreate: auth.hasPermission('quotation.create'),
      canApprove: auth.hasPermission('quotation.approve'),
    );
    if (!canEdit) {
      ref.read(globalLoadingProvider.notifier).showError(
            _status == 'pending_approval'
                ? 'Only approvers can edit quotations pending approval'
                : 'This quotation cannot be edited',
          );
      return false;
    }
    return true;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _validUntil = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_assertCanEdit()) return;
    if (_customerId == null) {
      ref
          .read(globalLoadingProvider.notifier)
          .showError('Select a customer');
      return;
    }
    if (_lines.isEmpty) {
      ref
          .read(globalLoadingProvider.notifier)
          .showError('Add at least one line item');
      return;
    }

    final items = <QuotationItemModel>[];
    for (final line in _lines) {
      if (line.itemId == null) {
        ref
            .read(globalLoadingProvider.notifier)
            .showError('Select an item for each line');
        return;
      }
      items.add(
        QuotationItemModel(
          itemId: line.itemId!,
          quantity: int.parse(line.qty.text.trim()),
          unitPrice: double.parse(line.price.text.trim()),
          gstPercent: double.parse(line.gst.text.trim()),
          description: line.description.text.trim().isEmpty
              ? null
              : line.description.text.trim(),
        ),
      );
    }

    setState(() => _loading = true);
    ref.read(globalLoadingProvider.notifier).showLoading(
          isEdit ? 'Updating quotation...' : 'Creating quotation...',
        );

    try {
      final repo = ref.read(quotationRepositoryProvider);
      final fromParty = _fromPartyPayload();
      if (isEdit) {
        await repo.update(
          id: widget.quotationId!,
          customerId: _customerId!,
          items: items,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          validUntil: _validUntil,
          billTo: _billTo,
          shipTo: _shipSameAsBill ? _billTo : _shipTo,
          shipSameAsBill: _shipSameAsBill,
          fromParty: fromParty,
        );
      } else {
        await repo.create(
          customerId: _customerId!,
          items: items,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          validUntil: _validUntil,
          billTo: _billTo,
          shipTo: _shipSameAsBill ? _billTo : _shipTo,
          shipSameAsBill: _shipSameAsBill,
          fromParty: fromParty,
        );
      }
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess(
            isEdit ? 'Quotation updated' : 'Quotation created',
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEdit && !_initialized) {
      final async = ref.watch(quotationDetailProvider(widget.quotationId!));
      return async.when(
        loading: () => const Scaffold(body: LoadingState()),
        error: (e, _) => Scaffold(
          appBar: const AppAppBar(title: 'Edit Quotation'),
          body: ErrorState(
            message: cleanError(e),
            onRetry: () =>
                ref.invalidate(quotationDetailProvider(widget.quotationId!)),
          ),
        ),
        data: (q) {
          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _initialized) return;
              final auth = ref.read(authProvider);
              final allowed = DocumentWorkflow.canEditQuotation(
                q.status,
                canCreate: auth.hasPermission('quotation.create'),
                canApprove: auth.hasPermission('quotation.approve'),
              );
              if (!allowed) {
                ref.read(globalLoadingProvider.notifier).showError(
                      q.status == 'pending_approval'
                          ? 'Only approvers can edit quotations pending approval'
                          : 'This quotation cannot be edited',
                    );
                setState(() {
                  _editBlocked = true;
                  _initialized = true;
                  _status = q.status;
                });
                Navigator.pop(context);
                return;
              }
              _fill(q);
              setState(() => _initialized = true);
            });
          }
          if (_editBlocked) {
            return const Scaffold(body: LoadingState());
          }
          return _buildForm();
        },
      );
    }
    return _buildForm();
  }

  Widget _buildForm() {
    final customersAsync = ref.watch(customerListProvider);
    final itemsAsync = ref.watch(approvedItemsProvider);
    final brandingAsync = ref.watch(solarBrandingProvider);
    final pendingLock = _status == 'pending_approval';

    return Scaffold(
      appBar: AppAppBar(title: isEdit ? 'Edit Quotation' : 'New Quotation'),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (customersAsync.isLoading && customersAsync.items.isEmpty)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                value: _customerId,
                decoration: const InputDecoration(labelText: 'Customer *'),
                items: customersAsync.items
                    .map(
                      (CustomerModel c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: pendingLock
                    ? null
                    : (v) => _onCustomerChanged(v, customersAsync.items),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Select a customer' : null,
              ),
            const SizedBox(height: 12),
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
                    readOnly: pendingLock,
                    onChanged: (v) => setState(() => _fromBranchId = v),
                  ),
                  const SizedBox(height: 16),
                  PartyAddressEditor(
                    key: ValueKey('bill_${_billTo.name}_${_billTo.address}'),
                    title: 'Bill To',
                    party: _billTo,
                    readOnly: pendingLock,
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
                    onChanged: pendingLock
                        ? null
                        : (v) => setState(() {
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
                      readOnly: pendingLock,
                      onChanged: (p) => setState(() => _shipTo = p),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Valid until'),
              subtitle: Text(
                _validUntil == null ? 'Not set' : formatDate(_validUntil),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: pendingLock ? null : _pickDate,
              ),
            ),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Line items',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _lines.add(_LineDraft())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            itemsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(cleanError(e)),
              data: (approved) => Column(
                children: [
                  for (var i = 0; i < _lines.length; i++)
                    _buildLineCard(i, approved),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineCard(int index, List<ItemModel> approved) {
    final line = _lines[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Line ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_lines.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _lines.removeAt(index).dispose();
                      });
                    },
                  ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: line.itemId,
              decoration: const InputDecoration(labelText: 'Item *'),
              items: approved
                  .map(
                    (it) => DropdownMenuItem(
                      value: it.id,
                      child: Text(
                        '${it.name} (${formatInr(it.sellingPrice)}, ${ItemUnits.labelFor(it.unit)}, GST ${it.gstPercent}%)',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  line.itemId = v;
                  ItemModel? item;
                  for (final it in approved) {
                    if (it.id == v) {
                      item = it;
                      break;
                    }
                  }
                  if (item != null) {
                    line.price.text = item.sellingPrice.toString();
                    line.gst.text = item.gstPercent.toString();
                    if (line.description.text.isEmpty) {
                      line.description.text = item.name;
                    }
                  }
                });
              },
              validator: (v) => v == null ? 'Select item' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.qty,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: (v) => AppValidators.positiveNumber(v, 'Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: line.price,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      LengthLimitingTextInputFormatter(12),
                    ],
                    validator: (v) =>
                        AppValidators.nonNegativeNumber(v, 'Price'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: line.gst,
                    decoration: const InputDecoration(labelText: 'GST %'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: AppValidators.gstPercent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: line.description,
              decoration: const InputDecoration(labelText: 'Description'),
              inputFormatters: [LengthLimitingTextInputFormatter(250)],
              validator: (v) => AppValidators.maxLength(
                v,
                max: 250,
                field: 'Description',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
