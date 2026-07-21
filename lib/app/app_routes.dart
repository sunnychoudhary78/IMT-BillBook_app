import 'package:flutter/material.dart';

import 'package:solar_erp_app/app/app_root.dart';
import 'package:solar_erp_app/features/auth/presentation/screens/login_screen.dart'
    show LoginScreen, ChangePasswordScreen;
import 'package:solar_erp_app/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:solar_erp_app/features/customers/presentation/screens/customers_screen.dart';
import 'package:solar_erp_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:solar_erp_app/features/inventory/presentation/screens/inventory_hub_screen.dart';
import 'package:solar_erp_app/features/inventory/presentation/screens/low_stock_screen.dart';
import 'package:solar_erp_app/features/inventory/presentation/screens/stock_ledger_screen.dart';
import 'package:solar_erp_app/features/inventory/presentation/screens/stock_screen.dart';
import 'package:solar_erp_app/features/inventory/presentation/screens/warehouses_screen.dart';
import 'package:solar_erp_app/features/invoices/presentation/screens/invoice_approvals_screen.dart';
import 'package:solar_erp_app/features/invoices/presentation/screens/invoice_create_screen.dart';
import 'package:solar_erp_app/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:solar_erp_app/features/invoices/presentation/screens/invoice_direct_form_screen.dart';
import 'package:solar_erp_app/features/invoices/presentation/screens/invoice_form_screen.dart';
import 'package:solar_erp_app/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:solar_erp_app/features/items/presentation/screens/item_approvals_screen.dart';
import 'package:solar_erp_app/features/items/presentation/screens/item_detail_screen.dart';
import 'package:solar_erp_app/features/items/presentation/screens/item_form_screen.dart';
import 'package:solar_erp_app/features/items/presentation/screens/items_screen.dart';
import 'package:solar_erp_app/features/quotations/presentation/screens/quotation_approvals_screen.dart';
import 'package:solar_erp_app/features/quotations/presentation/screens/quotation_detail_screen.dart';
import 'package:solar_erp_app/features/quotations/presentation/screens/quotation_form_screen.dart';
import 'package:solar_erp_app/features/quotations/presentation/screens/quotations_screen.dart';
import 'package:solar_erp_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:solar_erp_app/features/settings/presentation/screens/settings_screen.dart';
class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
        '/': (_) => const AppRoot(),
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/change-password': (_) => const ChangePasswordScreen(),
        '/customers': (_) => const CustomersScreen(),
        '/customers/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final id = args is String ? args : null;
          return CustomerFormScreen(customerId: id);
        },
        '/items': (_) => const ItemsScreen(),
        '/items/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final id = args is String ? args : null;
          return ItemFormScreen(itemId: id);
        },
        '/items/detail': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          return ItemDetailScreen(itemId: id);
        },
        '/items/approvals': (_) => const ItemApprovalsScreen(),
        '/quotations': (_) => const QuotationsScreen(),
        '/quotations/form': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final id = args is String ? args : null;
          return QuotationFormScreen(quotationId: id);
        },
        '/quotations/detail': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          return QuotationDetailScreen(quotationId: id);
        },
        '/quotations/approvals': (_) => const QuotationApprovalsScreen(),
        '/invoices': (_) => const InvoicesScreen(),
        '/invoices/create': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? quotationId;
          if (args is String) {
            quotationId = args;
          } else if (args is Map) {
            quotationId = args['quotationId']?.toString();
          }
          return InvoiceCreateScreen(quotationId: quotationId);
        },
        '/invoices/new': (_) => const InvoiceDirectFormScreen(),
        '/invoices/form': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          return InvoiceFormScreen(invoiceId: id);
        },
        '/invoices/detail': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          return InvoiceDetailScreen(invoiceId: id);
        },
        '/invoices/approvals': (_) => const InvoiceApprovalsScreen(),
        '/reports': (_) => const ReportsScreen(),
        '/inventory': (_) => const InventoryHubScreen(),
        '/inventory/stock': (_) => const StockScreen(),
        '/inventory/ledger': (_) => const StockLedgerScreen(),
        '/inventory/low-stock': (_) => const LowStockScreen(),
        '/inventory/warehouses': (_) => const WarehousesScreen(),
      };
}
