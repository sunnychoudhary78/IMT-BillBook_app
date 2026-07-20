import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/features/customers/presentation/screens/customers_screen.dart';
import 'package:solar_erp_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:solar_erp_app/features/inventory/presentation/screens/inventory_hub_screen.dart';
import 'package:solar_erp_app/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:solar_erp_app/features/quotations/presentation/screens/quotations_screen.dart';
import 'package:solar_erp_app/features/shell/presentation/shell_scope.dart';
import 'package:solar_erp_app/features/shell/presentation/widgets/app_drawer.dart';

class _ShellTab {
  final String label;
  final IconData icon;
  final String permission;
  final Widget screen;

  const _ShellTab({
    required this.label,
    required this.icon,
    required this.permission,
    required this.screen,
  });
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  List<_ShellTab> _buildTabs() {
    final auth = ref.watch(authProvider);
    final tabs = <_ShellTab>[
      const _ShellTab(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        permission: '',
        screen: DashboardScreen(),
      ),
    ];

    void addIf(String permission, _ShellTab tab) {
      if (auth.hasPermission(permission)) tabs.add(tab);
    }

    addIf(
      'customer.read',
      const _ShellTab(
        label: 'Customers',
        icon: Icons.people_outline,
        permission: 'customer.read',
        screen: CustomersScreen(),
      ),
    );
    addIf(
      'quotation.read',
      const _ShellTab(
        label: 'Quotations',
        icon: Icons.request_quote_outlined,
        permission: 'quotation.read',
        screen: QuotationsScreen(),
      ),
    );
    addIf(
      'inventory.read',
      const _ShellTab(
        label: 'Inventory',
        icon: Icons.inventory_2_outlined,
        permission: 'inventory.read',
        screen: InventoryHubScreen(),
      ),
    );
    addIf(
      'invoice.read',
      const _ShellTab(
        label: 'Invoices',
        icon: Icons.receipt_long_outlined,
        permission: 'invoice.read',
        screen: InvoicesScreen(),
      ),
    );

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();
    if (_index >= tabs.length) _index = 0;

    return ShellScope(
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(
          mainDestinations: [
            for (var i = 0; i < tabs.length; i++)
              DrawerMainDestination(
                label: tabs[i].label,
                icon: tabs[i].icon,
                index: i,
              ),
          ],
          selectedMainIndex: _index,
          onSelectMain: (i) => setState(() => _index = i),
        ),
        body: IndexedStack(
          index: _index,
          children: [for (final tab in tabs) tab.screen],
        ),
      ),
    );
  }
}
