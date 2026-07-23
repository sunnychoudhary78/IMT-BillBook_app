import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:solar_erp_app/core/theme/app_design.dart';
import 'package:solar_erp_app/shared/utils/validators.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(
        message,
        style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: scheme.error)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> showReasonSheet(
  BuildContext context, {
  required String title,
  String hint = 'Enter reason',
}) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please provide a clear reason for this action.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: hint,
                  labelText: 'Reason',
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
                validator: (v) => AppValidators.maxLength(
                  v,
                  max: 500,
                  min: 5,
                  field: 'Reason',
                  required: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(context, controller.text.trim());
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(controller.dispose);
}
