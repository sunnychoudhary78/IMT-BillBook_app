import 'package:flutter/material.dart';

import 'package:solar_erp_app/shared/utils/formatters.dart';
import 'package:solar_erp_app/shared/utils/gst_breakdown.dart';

class DocumentTotalsSummary extends StatelessWidget {
  final List<LineTotalsInput> lines;

  const DocumentTotalsSummary({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    final totals = calcDocumentTotals(lines);
    final b = totals.breakdown;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Subtotal', formatInr(totals.subtotal)),
            _row('CGST (${b.cgstRate}%)', formatInr(b.cgstAmount)),
            _row('SGST (${b.sgstRate}%)', formatInr(b.sgstAmount)),
            _row('Total GST', formatInr(totals.gstAmount)),
            const Divider(),
            _row(
              'Grand Total',
              formatInr(totals.totalAmount),
              bold: true,
              color: scheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: color,
    );
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

/// Read-only totals from server amounts.
class DocumentTotalsDisplay extends StatelessWidget {
  final double subtotal;
  final double gstAmount;
  final double totalAmount;

  const DocumentTotalsDisplay({
    super.key,
    required this.subtotal,
    required this.gstAmount,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final b = splitCgstSgst(gstAmount, subtotal);
    return Column(
      children: [
        _AmountRow('Subtotal', formatInr(subtotal)),
        _AmountRow('CGST (${b.cgstRate}%)', formatInr(b.cgstAmount)),
        _AmountRow('SGST (${b.sgstRate}%)', formatInr(b.sgstAmount)),
        _AmountRow('Total GST', formatInr(gstAmount)),
        _AmountRow('Total', formatInr(totalAmount), bold: true),
      ],
    );
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
