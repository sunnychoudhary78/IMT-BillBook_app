# Solar ERP App

Flutter mobile client for Solar ERP (Imt-Billbook — sales & operations).

## Architecture

Mirrors the LMS Flutter stack:

- `app/` — root, routes, navigator
- `core/` — network (plain JSON Dio), storage, theme, providers
- `shared/` — widgets, validators, formatters
- `features/` — auth, dashboard, customers, items, quotations, invoices, inventory, reports, settings, shell

State: **Riverpod 3** (manual providers). HTTP: **Dio** with JWT bearer auth (no AES encryption).

## Setup

1. Start the Node backend (`Solar_erp_Backend`) — default UAT URL in app: `http://10.0.2.2:3004/api` (Android emulator → host).
2. For a physical device, change `ApiConstants` in `lib/core/network/api_constants.dart` to your machine LAN IP.
3. Run:

```bash
flutter pub get
flutter run
```

## Feature scope (sales/ops parity with web)

Login, Dashboard (KPIs + role taglines), Customers (incl. Aadhar), Items (+HSN/SAC, approvals), Quotations (+custom number, CGST/SGST, approvals, PDF/email), Invoices (from quotation + **direct**, dispatch fields, approvals, stock check), Inventory (stock in/out/transfer/adjustment with guards, filtered ledger, low stock, warehouses), **Reports** (sales, stock, quotations, invoices), Settings (theme + change password).

**Web-only admin** (not in mobile): Employees, Roles & Permissions, Company Settings (logo/SMTP/branding tabs).

## Tests

```bash
flutter test
```
