import 'package:flutter/material.dart';

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const pill = 50.0;
}

class AppElevation {
  static const card = 2.0;
}

class AppShadows {
  static List<BoxShadow> card(ColorScheme scheme) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: .04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: scheme.primary.withValues(alpha: .04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> header(ColorScheme scheme) => [
        BoxShadow(
          color: scheme.primary.withValues(alpha: .10),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> floating(ColorScheme scheme) => [
        BoxShadow(
          color: scheme.primary.withValues(alpha: .18),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration stagger = Duration(milliseconds: 45);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutBack;

  /// Cap list stagger so long lists stay snappy.
  static Duration listDelay(int index, {int maxItems = 8}) {
    final i = index.clamp(0, maxItems);
    return stagger * i;
  }
}

/// Semantic status colors aligned with ColorScheme when possible.
class AppStatusColors {
  static Color forStatus(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'draft':
        return scheme.outline;
      case 'pending':
      case 'pending_approval':
        return const Color(0xFFD97706); // amber-600
      case 'approved':
        return const Color(0xFF059669); // emerald-600
      case 'sent':
        return scheme.primary;
      case 'rejected':
        return scheme.error;
      case 'active':
        return const Color(0xFF059669);
      case 'inactive':
        return scheme.outline;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  static String labelFor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'pending':
        return 'Pending';
      case 'pending_approval':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'sent':
        return 'Sent';
      case 'rejected':
        return 'Rejected';
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }
}
