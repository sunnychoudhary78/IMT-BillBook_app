# Solar ERP App

Flutter mobile client for Solar ERP (sales & operations).

## Architecture

Mirrors the LMS Flutter stack:

- `app/` — root, routes, navigator
- `core/` — network (plain JSON Dio), storage, theme, providers
- `shared/` — widgets, validators, formatters
- `features/` — auth, dashboard, customers, items, quotations, invoices, inventory, settings, shell

State: **Riverpod 3** (manual providers). HTTP: **Dio** with JWT bearer auth (no AES encryption).

## Setup

1. Start the Node backend (`Solar_erp_Backend`) — default UAT URL in app: `http://10.0.2.2:3004/api` (Android emulator → host).
2. For a physical device, change `ApiConstants` in `lib/core/network/api_constants.dart` to your machine LAN IP.
3. Run:

```bash
flutter pub get
flutter run
```

## V1 scope

Login, Dashboard, Customers, Items (+approvals), Quotations (+approvals/PDF/email), Invoices (+approvals/stock), Inventory (stock/ledger/low-stock/warehouses), Settings (theme + change password).

Employees / Roles / full company settings are deferred.
