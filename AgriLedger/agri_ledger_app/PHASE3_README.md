# 🎤 AgriLedger — Phase 3: Voice Input + Auto Sync

## New Files in Phase 3

```
lib/
├── services/
│   ├── voice_parser.dart          ← Hindi/English NLP — extracts txn fields from speech
│   └── voice_service.dart         ← speech_to_text lifecycle (init, listen, stop, errors)
├── features/voice/
│   ├── screens/voice_entry_screen.dart  ← Full voice → parse → confirm → save UI
│   └── widgets/
│       ├── voice_waveform.dart         ← Animated listening bars
│       └── parsed_result_card.dart     ← Shows extracted fields with confidence chips
└── core/sync/
    ├── sync_engine.dart           ← Auto-sync: connectivity watcher + retry + periodic
    └── sync_providers.dart        ← Riverpod provider + SyncStatusBar + SyncEngineIconButton
```

---

## 🎤 Voice Flow

```
User taps 🎤 Voice button on Home
        ↓
Dark listening screen appears
User speaks: "राम लाल से 200 किलो चावल 22 रुपये खरीदा"
        ↓
Live transcript shown while speaking (partialResults: true)
        ↓
VoiceParser.parse() called on final text
        ↓
Extracted fields:
  party=Ram Lal  type=purchase  commodity=rice
  qty=200kg  rate=22  amount=4400  confidence=85%
        ↓
Confirmation screen (white panel slides up)
  • Pre-filled editable fields
  • Party auto-matched (or user picks)
  • User can change any field
        ↓
Tap "Save" → offline-first write → sync queue
```

---

## 🌐 Auto Sync Flow

```
SyncEngine (ChangeNotifier) starts on app launch
        ↓
Watches: connectivity_plus stream
        ↓
Network comes back online?
  → syncNow() immediately
        ↓
Every 5 minutes + pending items?
  → syncNow()
        ↓
Sync fails?
  → schedule retry in 30 seconds
        ↓
SyncEngineIconButton in AppBar shows:
  ☁️ idle  |  🔄 syncing  |  ✓ success  |  ⚠️ failed  |  📵 offline
  + orange badge with pending count
```

---

## 📱 Voice Parser — Supported Patterns

| Hindi Input | Extracted |
|---|---|
| राम लाल से 200 किलो चावल 22 रुपये खरीदा | purchase, rice, 200kg, ₹22/kg |
| sharma ko 5000 rupees diya | cash_out, ₹5000 |
| suresh ko 3 bori di | bag_given, 3 bags |
| 150 kg gehu 21 rate pe becha | sale, wheat, 150kg, ₹21/kg |
| 500 cash mila ram se | cash_in, ₹500 |
| makka 100 kg liya 18 rupye | purchase, maize, 100kg, ₹18/kg |

### Confidence Scoring
- **>70%**: Green chip — safe to save directly
- **40-70%**: Orange chip — review fields before saving
- **<40%**: Red chip — manual correction needed

---

## 🔧 Setup for Phase 3

No new packages — all already in pubspec.yaml:
- `speech_to_text: ^6.6.2` → handles voice
- `connectivity_plus: ^6.0.3` → handles sync trigger

### Android: Mic permission already in AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### Run build_runner (still required for Drift):
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 📅 Phase Roadmap

| Phase | Status | Description |
|---|---|---|
| Phase 1 | ✅ Done | ASP.NET Core backend + SQLite + all APIs |
| Phase 2 | ✅ Done | Flutter app + offline DB + all screens |
| Phase 3 | ✅ **Current** | Voice input (Hindi STT) + auto sync engine |
| Phase 4 | 🔜 Next | PDF receipts + Bluetooth thermal printing + reports export |
