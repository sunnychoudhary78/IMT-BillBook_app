import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:solar_erp_app/features/customers/presentation/screens/customers_screen.dart';
import 'package:solar_erp_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:solar_erp_app/features/inventory/presentation/screens/inventory_hub_screen.dart';
import 'package:solar_erp_app/features/invoices/presentation/providers/invoice_providers.dart';
import 'package:solar_erp_app/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:solar_erp_app/features/quotations/presentation/providers/quotation_providers.dart';
import 'package:solar_erp_app/features/quotations/presentation/screens/quotations_screen.dart';
import 'package:solar_erp_app/features/shell/presentation/shell_scope.dart';
import 'package:solar_erp_app/features/shell/presentation/widgets/app_drawer.dart';

class _ShellTab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String permission;
  final Widget screen;

  const _ShellTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
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
        label: 'Home',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
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
        selectedIcon: Icons.people_rounded,
        permission: 'customer.read',
        screen: CustomersScreen(),
      ),
    );
    addIf(
      'quotation.read',
      const _ShellTab(
        label: 'Quotes',
        icon: Icons.request_quote_outlined,
        selectedIcon: Icons.request_quote_rounded,
        permission: 'quotation.read',
        screen: QuotationsScreen(),
      ),
    );
    addIf(
      'inventory.read',
      const _ShellTab(
        label: 'Stock',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2_rounded,
        permission: 'inventory.read',
        screen: InventoryHubScreen(),
      ),
    );
    addIf(
      'invoice.read',
      const _ShellTab(
        label: 'Invoices',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        permission: 'invoice.read',
        screen: InvoicesScreen(),
      ),
    );

    return tabs;
  }

  void _selectTab(int index, List<_ShellTab> tabs) {
    if (index == _index || index < 0 || index >= tabs.length) return;
    setState(() => _index = index);
    final label = tabs[index].label;
    if (label == 'Quotes') {
      ref.read(quotationListProvider.notifier).refresh();
    } else if (label == 'Invoices') {
      ref.read(invoiceListProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();
    if (_index >= tabs.length) _index = 0;
    final scheme = Theme.of(context).colorScheme;

    return ShellScope(
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(
          mainDestinations: [
            for (var i = 0; i < tabs.length; i++)
              DrawerMainDestination(
                label: tabs[i].label == 'Home' ? 'Dashboard' : tabs[i].label,
                icon: tabs[i].icon,
                index: i,
              ),
          ],
          selectedMainIndex: _index,
          onSelectMain: (i) => _selectTab(i, tabs),
        ),
        body: IndexedStack(
          index: _index,
          children: [for (final tab in tabs) tab.screen],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => _selectTab(i, tabs),
          destinations: [
            for (final tab in tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
          ],
        ),
        backgroundColor: scheme.surfaceContainerLowest,
      ),
    );
  }
}
