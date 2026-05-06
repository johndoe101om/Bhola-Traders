# 📱 AgriLedger — Phase 2: Flutter Mobile App

Offline-first Android app with local SQLite, riverpod state management,
and full UI for parties, transactions, and bag tracking.

---

## 📁 Project Structure

```
agri_ledger_app/
├── lib/
│   ├── main.dart                          ← App entry + PIN router
│   ├── core/
│   │   ├── constants/app_constants.dart   ← Labels (Hindi/English), allowed values
│   │   ├── theme/app_theme.dart           ← Colors, fonts, component styles
│   │   └── utils/app_utils.dart           ← Formatters, helpers, snackbars
│   ├── data/
│   │   ├── models/app_models.dart         ← All data classes
│   │   ├── local/local_database.dart      ← Drift SQLite (offline DB)
│   │   ├── remote/api_service.dart        ← Dio HTTP client → backend
│   │   └── repositories/
│   │       ├── app_repository.dart        ← Business logic, offline-first writes
│   │       └── providers.dart             ← Riverpod providers (DI)
│   └── features/
│       ├── auth/screens/pin_screen.dart            ← PIN login
│       ├── home/
│       │   ├── screens/home_screen.dart            ← Dashboard + nav
│       │   └── widgets/                            ← Summary card, sync banner
│       ├── parties/screens/
│       │   ├── parties_screen.dart                 ← List + tabs + search
│       │   ├── add_party_screen.dart               ← Create party
│       │   └── party_ledger_screen.dart            ← Full khata view
│       ├── transactions/screens/
│       │   └── entry_screen.dart                   ← New transaction (manual)
│       ├── bags/screens/
│       │   ├── bags_screen.dart                    ← Outstanding bori
│       │   └── bag_entry_screen.dart               ← Give/return bags
│       └── reports/screens/
│           └── reports_screen.dart                 ← 7-day summary + leaderboard
├── android/app/src/main/AndroidManifest.xml
├── pubspec.yaml
└── build.yaml
```

---

## 🚀 Setup Instructions

### Step 1: Install Flutter
```bash
# Follow: https://docs.flutter.dev/get-started/install/linux/android
flutter --version  # Should be 3.16+
```

### Step 2: Install dependencies
```bash
cd agri_ledger_app
flutter pub get
```

### Step 3: Generate Drift database code
```bash
# IMPORTANT: Run this after any change to local_database.dart
dart run build_runner build --delete-conflicting-outputs
```

### Step 4: Configure server URL
Edit `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:5000';
// On same WiFi: use local IP e.g. http://192.168.1.100:5000
// On internet: use your domain/VPS IP
```

### Step 5: Run on Android device
```bash
flutter run --release   # or just: flutter run
```

---

## 🔑 PIN Setup

Default PIN: **1234**

To change: In `appsettings.json` on the backend server:
```json
{ "Auth": { "Pin": "9876" } }
```
And update the saved `SharedPreferences` key `user_pin` in the app,
or clear app data to reset.

---

## ⚡ Offline-First Flow

```
User taps "Save"
      ↓
Write to local SQLite (INSTANT — always works)
      ↓
Check internet connectivity
   ↓ Online              ↓ Offline
Push to server API    Add to sync_queue
   ↓ Success           
Mark syncedAt             
   ↓ Fail             
Add to sync_queue     
      ↓
Show "pending sync" badge in app bar
      ↓
Next time online → auto sync via Sync Now button
```

---

## 🏗️ Generate Drift Code (Required)

After `flutter pub get`, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `local_database.g.dart` which contains all the type-safe
query classes. **The app will not compile without this step.**

---

## 📱 Screens Overview

| Screen | Purpose |
|---|---|
| PIN Screen | 4-digit login, green numpad |
| Home Dashboard | Today's summary, quick action buttons, recent entries |
| Parties Screen | Tabbed list (All/Farmer/Supplier/Customer), search |
| Add Party | Form: name, type, phone, village |
| Party Ledger | Full khata: running balance, all txns, bag tab |
| New Entry | Transaction form: type → party → commodity → qty/rate → amount |
| Bags Screen | All parties with outstanding bori count |
| Bag Entry | Give/return bags for a party |
| Reports | 7-day P&L, highest outstanding party list |

---

## 🎨 Design Decisions

- **Noto Sans font** — excellent Hindi (Devanagari) + English support
- **18sp minimum text** — readable in bright sunlight
- **56dp+ button heights** — large tap targets for rough hands
- **Color coding** — Green = money in, Red = money out, Blue = bags
- **Hindi first** — all labels show Hindi then English below
- **No login complexity** — 4-digit PIN, no usernames/passwords

---

## 📅 Phase Roadmap

| Phase | Status | Description |
|---|---|---|
| Phase 1 | ✅ Done | ASP.NET Core backend + SQLite + all APIs |
| Phase 2 | ✅ **Current** | Flutter app + offline DB + all screens |
| Phase 3 | 🔜 Next | Voice input (Hindi STT) + auto sync engine |
| Phase 4 | 🔜 | PDF receipts + thermal printer + reports |
