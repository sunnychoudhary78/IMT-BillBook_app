import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/core/providers/global_loading_provider.dart';
import 'package:solar_erp_app/core/theme/app_design.dart';
import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/shared/utils/validators.dart';
import 'package:solar_erp_app/shared/widgets/app_bar.dart';
import 'package:solar_erp_app/shared/widgets/async_states.dart';
import 'package:solar_erp_app/shared/widgets/premium_feature_components.dart';

import '../../data/models/customer_model.dart';
import '../providers/customer_providers.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _gst = TextEditingController();
  final _aadhar = TextEditingController();

  bool _loading = false;
  bool _initialized = false;

  bool get isEdit => widget.customerId != null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _gst.dispose();
    _aadhar.dispose();
    super.dispose();
  }

  void _fill(CustomerModel c) {
    _name.text = c.name;
    _email.text = c.email ?? '';
    _phone.text = c.phone ?? '';
    _address.text = c.address ?? '';
    _city.text = c.city ?? '';
    _state.text = c.state ?? '';
    _pincode.text = c.pincode ?? '';
    _gst.text = c.gstNumber ?? '';
    _aadhar.text = c.aadharNumber ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final canCreate = ref.read(authProvider).hasPermission('customer.create');
    final canUpdate = ref.read(authProvider).hasPermission('customer.update');
    if (isEdit && !canUpdate) return;
    if (!isEdit && !canCreate) return;

    final model = CustomerModel(
      id: widget.customerId ?? '',
      name: _name.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      state: _state.text.trim().isEmpty ? null : _state.text.trim(),
      pincode: _pincode.text.trim().isEmpty ? null : _pincode.text.trim(),
      gstNumber:
          _gst.text.trim().isEmpty ? null : _gst.text.trim().toUpperCase(),
      aadharNumber: _aadhar.text.trim().isEmpty
          ? null
          : _aadhar.text.replaceAll(RegExp(r'\D'), ''),
    );

    setState(() => _loading = true);
    ref.read(globalLoadingProvider.notifier).showLoading(
          isEdit ? 'Updating customer...' : 'Creating customer...',
        );

    try {
      final repo = ref.read(customerRepositoryProvider);
      if (isEdit) {
        await repo.update(widget.customerId!, model);
      } else {
        await repo.create(model);
      }
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess(
            isEdit ? 'Customer updated' : 'Customer created',
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
      final async = ref.watch(customerDetailProvider(widget.customerId!));
      return async.when(
        loading: () => const Scaffold(body: LoadingState()),
        error: (e, _) => Scaffold(
          appBar: AppAppBar(title: isEdit ? 'Edit Customer' : 'New Customer'),
          body: ErrorState(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(customerDetailProvider(widget.customerId!)),
          ),
        ),
        data: (customer) {
          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _initialized) return;
              _fill(customer);
              setState(() => _initialized = true);
            });
          }
          return _buildForm();
        },
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    final scheme = Theme.of(context).colorScheme;
    final canSave = isEdit
        ? ref.watch(authProvider).hasPermission('customer.update')
        : ref.watch(authProvider).hasPermission('customer.create');

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppAppBar(title: isEdit ? 'Edit Customer' : 'New Customer'),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const PremiumSectionTitle(
              title: 'Basic',
              subtitle: 'Customer identity',
            ),
            const SizedBox(height: AppSpacing.sm),
            PremiumCard(
              child: TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *'),
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                validator: (v) => AppValidators.entityName(v, 'Name'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const PremiumSectionTitle(
              title: 'Contact',
              subtitle: 'Phone and email for sales follow-up',
            ),
            const SizedBox(height: AppSpacing.sm),
            PremiumCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: '10-digit mobile',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: AppValidators.optionalPhone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [LengthLimitingTextInputFormatter(100)],
                    validator: AppValidators.optionalEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const PremiumSectionTitle(title: 'Address'),
            const SizedBox(height: AppSpacing.sm),
            PremiumCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                    inputFormatters: [LengthLimitingTextInputFormatter(250)],
                    validator: (v) => AppValidators.maxLength(
                      v,
                      max: 250,
                      field: 'Address',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _city,
                          decoration: const InputDecoration(labelText: 'City'),
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          validator: (v) => AppValidators.maxLength(
                            v,
                            max: 50,
                            field: 'City',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _state,
                          decoration: const InputDecoration(labelText: 'State'),
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          validator: (v) => AppValidators.maxLength(
                            v,
                            max: 50,
                            field: 'State',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _pincode,
                    decoration: const InputDecoration(labelText: 'Pincode'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: AppValidators.pincode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const PremiumSectionTitle(title: 'Tax'),
            const SizedBox(height: AppSpacing.sm),
            PremiumCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _gst,
                    decoration: const InputDecoration(
                      labelText: 'GST Number',
                      hintText: '15-character GSTIN',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(15),
                      _UpperCaseTextFormatter(),
                    ],
                    validator: AppValidators.gstNumber,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _aadhar,
                    decoration: const InputDecoration(
                      labelText: 'Aadhar Number',
                      hintText: '12-digit Aadhar',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    validator: AppValidators.aadharNumber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (canSave)
              FilledButton(
                onPressed: _loading ? null : _save,
                child: Text(isEdit ? 'Update' : 'Create'),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
