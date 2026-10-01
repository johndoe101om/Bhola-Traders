# 🖨️ AgriLedger — Phase 4: PDF Receipts + Thermal Printing + Reports

## New in Phase 4

```
lib/
├── services/printing/
│   ├── pdf_generator.dart       ← Pure-Dart PDF: receipt, party ledger, business report
│   ├── thermal_printer.dart     ← BLE ESC/POS thermal printer (58mm/80mm)
│   └── print_service.dart       ← Unified facade: PDF share / system print / thermal
├── features/
│   ├── receipts/
│   │   ├── screens/printer_setup_screen.dart  ← BT scan, connect, test print
│   │   └── widgets/print_action_sheet.dart    ← Bottom sheet: share/print/thermal options
│   ├── reports/screens/reports_screen.dart    ← Full rewrite with date picker + export
│   └── settings/screens/settings_screen.dart ← PIN, server URL, printer, sync
android/
├── AndroidManifest.xml          ← All BT permissions (Android 10–14)
└── res/xml/file_paths.xml       ← FileProvider for PDF sharing
```

---

## 🧾 PDF Generation

Three PDF types, all generated offline:

### 1. Transaction Receipt (A5)
```dart
final file = await PdfGenerator.generateReceipt(
  txn: txn,
  partyName: 'Ram Lal',
  businessName: 'My Grain Store',
);
```
Contains: business header, party name, date, transaction type badge, commodity/qty/rate, **large amount**, payment mode, footer.

### 2. Party Ledger (A4, multi-page)
```dart
final file = await PdfGenerator.generatePartyLedger(
  party: party,
  transactions: txns,
  bagMovements: bags,
  balance: 4500.0,
  bagsOutstanding: 3,
);
```
Contains: party header + balance card, full transaction table with running balance, bag movement table.

### 3. Business Report (A4)
```dart
final file = await PdfGenerator.generateBusinessReport(
  transactions: allTxns,
  from: DateTime(2025, 11, 1),
  to: DateTime(2025, 11, 30),
);
```
Contains: P&L summary cards, commodity breakdown, daily breakdown table.

---

## 🖨️ Thermal Printer Setup

### Step 1 — Buy a printer
Recommended (₹1,500–₹3,000):
- **Xprinter XP-58IIH** (58mm, BLE) — most common
- **GOOJPRT PT-200** (58mm, BLE)
- **MUNBYN ITPP941** (80mm, BLE)

> ⚠️ Most cheap printers use **Classic Bluetooth SPP**, not BLE.
> For SPP printers, replace `flutter_blue_plus` with `bluetooth_print` package.
> The `ThermalPrinterService` API stays the same.

### Step 2 — Connect in app
1. Open **Settings → Bluetooth Thermal Printer**
2. Tap **Scan** → select your printer from list
3. Tap **Connect**
4. Tap **Test Slip** to confirm printing works

### Step 3 — Print from any screen
- **Transaction entry** → Save → long-press any entry → Print
- **Party ledger** → tap PDF icon in app bar → Thermal Print
- **Reports screen** → Export PDF → share/print

---

## 📤 Sharing Options (all in PrintActionSheet)

| Option | How |
|---|---|
| WhatsApp | `share_plus` — opens native share sheet |
| System Print | `printing` package — Wi-Fi printers, Google Cloud Print |
| Thermal | BLE write via `flutter_blue_plus` |
| View PDF | `open_file` — opens in phone's PDF viewer |

---

## 📱 Settings Screen

| Setting | What it does |
|---|---|
| Business Name | Appears on all printed receipts |
| Server URL | Change if server IP/port changes |
| Sync Now | Force push all pending offline entries |
| Change PIN | 4-digit PIN for app lock |
| Printer Setup | Bluetooth printer connect/test |
| Clear Sync Queue | Emergency: clear stuck sync items |

---

## 🔧 Build Steps (Phase 4)

```bash
# 1. Get new packages
flutter pub get

# 2. Regenerate Drift code (always required)
dart run build_runner build --delete-conflicting-outputs

# 3. Build APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
# Install: adb install app-release.apk
```

---

## 📋 Complete Feature List (All 4 Phases)

| Feature | Phase | Status |
|---|---|---|
| Party management (farmer/supplier/customer) | 1+2 | ✅ |
| Grain transactions (purchase/sale) | 1+2 | ✅ |
| Cash in / out tracking | 1+2 | ✅ |
| Jute bag (bori) tracking | 1+2 | ✅ |
| Running balance per party | 1+2 | ✅ |
| Offline-first SQLite | 2 | ✅ |
| Auto sync when online | 3 | ✅ |
| Hindi voice entry | 3 | ✅ |
| Voice parse + confirm flow | 3 | ✅ |
| PDF receipt generation | 4 | ✅ |
| Party ledger PDF export | 4 | ✅ |
| Business P&L report PDF | 4 | ✅ |
| WhatsApp / email sharing | 4 | ✅ |
| Bluetooth thermal printing | 4 | ✅ |
| Date range reports | 4 | ✅ |
| Settings (PIN, server, printer) | 4 | ✅ |
