import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.forStatus(String status) {
    final normalized = status.toLowerCase();
    late Color color;
    late String label;

    switch (normalized) {
      case 'draft':
        color = Colors.blueGrey;
        label = 'Draft';
      case 'pending':
      case 'pending_approval':
        color = Colors.orange;
        label = normalized == 'pending' ? 'Pending' : 'Pending Approval';
      case 'approved':
        color = Colors.green;
        label = 'Approved';
      case 'sent':
        color = Colors.teal;
        label = 'Sent';
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
      default:
        color = Colors.grey;
        label = status;
    }

    return StatusBadge(label: label, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
