import 'package:flutter/material.dart';

/// Exposes the [AppShell] scaffold so nested screens can open the side drawer.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  static ShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellScope>();
  }

  static void openDrawer(BuildContext context) {
    maybeOf(context)?.scaffoldKey.currentState?.openDrawer();
  }

  static bool hasDrawer(BuildContext context) {
    return maybeOf(context) != null;
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) {
    return scaffoldKey != oldWidget.scaffoldKey;
  }
}
