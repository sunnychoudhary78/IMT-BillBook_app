import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:solar_erp_app/features/shell/presentation/shell_scope.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final blurSigma = isIOS ? 10.0 : 12.0;
    final inShell = ShellScope.hasDrawer(context);

    Widget? resolvedLeading = leading;
    if (resolvedLeading == null && inShell) {
      resolvedLeading = IconButton(
        tooltip: 'Menu',
        icon: Icon(isIOS ? Icons.menu_rounded : Icons.menu),
        onPressed: () => ShellScope.openDrawer(context),
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AppBar(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          actions: actions,
          leading: resolvedLeading,
          automaticallyImplyLeading:
              resolvedLeading == null && automaticallyImplyLeading,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          backgroundColor: scheme.surface.withValues(alpha: 0.55),
          foregroundColor: scheme.onSurface,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: scheme.outline.withValues(alpha: 0.15),
            ),
          ),
        ),
      ),
    );
  }
}
