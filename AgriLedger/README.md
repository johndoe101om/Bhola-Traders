# 🌾 AgriLedger — Phase 1: Backend API

ASP.NET Core 8 REST API for agricultural ledger management.
Tracks grain purchases/sales, cash transactions, and jute bag movements.

---

## 📁 Project Structure

```
AgriLedger/
├── AgriLedger.sln
└── AgriLedger.API/
    ├── Controllers/
    │   ├── AuthController.cs          ← PIN verification
    │   ├── PartiesController.cs       ← Farmers, suppliers, customers
    │   ├── TransactionsController.cs  ← Grain & cash transactions
    │   ├── BagsController.cs          ← Jute bag (bori) tracking
    │   └── SyncController.cs          ← Offline sync push/pull
    ├── Data/
    │   ├── AppDbContext.cs            ← EF Core context + config
    │   └── AllowedValues.cs           ← Validation constants
    ├── DTOs/
    │   └── Dtos.cs                    ← All request/response types
    ├── Middleware/
    │   └── PinAuthMiddleware.cs       ← Simple PIN auth
    ├── Migrations/                    ← EF Core migrations (ready to apply)
    ├── Models/
    │   ├── Party.cs
    │   ├── Transaction.cs
    │   ├── BagMovement.cs
    │   └── SyncQueueItem.cs
    ├── appsettings.json
    ├── appsettings.Development.json
    └── Program.cs
```

---

## 🚀 Quick Start

### Prerequisites
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- That's it! SQLite is bundled, no extra DB setup needed.

### Run the API

```bash
cd AgriLedger/AgriLedger.API
dotnet restore
dotnet run
```

API starts at: **http://localhost:5000**
Swagger UI at: **http://localhost:5000** (root URL)

---

## 🔐 Authentication

All API requests require the header:
```
X-PIN: 1234
```

Change the PIN in `appsettings.json`:
```json
{
  "Auth": {
    "Pin": "9876"
  }
}
```

To verify PIN from the app:
```
POST /api/v1/auth/verify
Body: { "pin": "1234" }
```

---

## 📡 API Endpoints

### Health
```
GET  /health         → Check if server is running (no auth needed)
```

### Auth
```
POST /api/v1/auth/verify      → Verify PIN
```

### Parties (किसान / ग्राहक)
```
GET    /api/v1/parties                    → List all (with balance + bag summary)
GET    /api/v1/parties?type=farmer        → Filter by type
GET    /api/v1/parties?q=ram              → Search by name/village
GET    /api/v1/parties/{id}               → Party detail
GET    /api/v1/parties/{id}/ledger        → Full khata (transactions + bags + balance)
GET    /api/v1/parties/{id}/ledger?from=2025-11-01&to=2025-11-30  → Date filtered
POST   /api/v1/parties                    → Create party
PUT    /api/v1/parties/{id}               → Update party
DELETE /api/v1/parties/{id}               → Soft delete
```

### Transactions (लेन-देन)
```
GET    /api/v1/transactions               → List (paginated)
GET    /api/v1/transactions?partyId=X     → Filter by party
GET    /api/v1/transactions?type=purchase → Filter by type
GET    /api/v1/transactions?from=2025-11-01&to=2025-11-30
GET    /api/v1/transactions/summary       → Daily totals (last 30 days)
GET    /api/v1/transactions/summary?from=2025-11-01&to=2025-11-30
GET    /api/v1/transactions/{id}          → Single transaction
POST   /api/v1/transactions               → Create transaction
PUT    /api/v1/transactions/{id}          → Correct transaction
DELETE /api/v1/transactions/{id}          → Soft delete
```

### Bags / Bori (बोरी)
```
GET    /api/v1/bags                       → List all bag movements
GET    /api/v1/bags/outstanding           → All parties with bags pending return
GET    /api/v1/bags/party/{partyId}       → Bag history + summary for party
POST   /api/v1/bags                       → Record given/returned
```

### Sync (offline support)
```
POST   /api/v1/sync/push                  → Push offline queue to server
GET    /api/v1/sync/pull?since=<ISO date> → Pull server changes since timestamp
```

---

## 📦 Sample API Calls

### Create a Farmer
```bash
curl -X POST http://localhost:5000/api/v1/parties \
  -H "X-PIN: 1234" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ram Lal Yadav",
    "partyType": "farmer",
    "phone": "9876543210",
    "village": "Sitapur"
  }'
```

### Record Grain Purchase (खरीदी)
```bash
curl -X POST http://localhost:5000/api/v1/transactions \
  -H "X-PIN: 1234" \
  -H "Content-Type: application/json" \
  -d '{
    "partyId": "<party-id>",
    "txnType": "purchase",
    "commodity": "rice",
    "quantityKg": 200.5,
    "ratePerKg": 22.00,
    "amount": 4411.00,
    "paymentMode": "cash",
    "notes": "Good quality paddy"
  }'
```

### Record Cash Payment
```bash
curl -X POST http://localhost:5000/api/v1/transactions \
  -H "X-PIN: 1234" \
  -H "Content-Type: application/json" \
  -d '{
    "partyId": "<party-id>",
    "txnType": "cash_out",
    "amount": 5000,
    "paymentMode": "cash",
    "notes": "Payment for last week"
  }'
```

### Give 5 Jute Bags
```bash
curl -X POST http://localhost:5000/api/v1/bags \
  -H "X-PIN: 1234" \
  -H "Content-Type: application/json" \
  -d '{
    "partyId": "<party-id>",
    "movement": "given",
    "quantity": 5,
    "notes": "For wheat storage"
  }'
```

### Get Full Ledger (Khata) for a Party
```bash
curl -X GET "http://localhost:5000/api/v1/parties/<party-id>/ledger" \
  -H "X-PIN: 1234"
```

---

## 🔄 Switching to PostgreSQL (Phase 2)

1. In `appsettings.json`, set:
```json
{
  "Database": {
    "UsePostgres": true
  },
  "ConnectionStrings": {
    "PostgreSQL": "Host=your-server;Database=agriledger;Username=user;Password=pass"
  }
}
```

2. Run migrations:
```bash
dotnet ef database update
```

That's it — zero code changes needed.

---

## 📊 Balance Logic

| txn_type   | direction | meaning |
|---|---|---|
| purchase   | out       | We paid money out (bought grain from farmer) |
| sale       | in        | We received money (sold grain to supplier) |
| cash_in    | in        | Farmer/customer gave us cash |
| cash_out   | out       | We gave cash to someone |

**Party balance** = SUM(amount where direction='in') - SUM(amount where direction='out')
- Positive = they owe us money
- Negative = we owe them money

---

## 🧪 Testing with Swagger

Open **http://localhost:5000** in browser after running the API.
Click "Authorize" → enter PIN `1234` → test all endpoints interactively.

---

## 📅 Phase Roadmap

| Phase | Status | Description |
|---|---|---|
| Phase 1 | ✅ **Current** | Backend API + SQLite + all endpoints |
| Phase 2 | 🔜 Next | Flutter mobile app + local offline DB |
| Phase 3 | 🔜 | Voice input (Hindi STT) + sync engine |
| Phase 4 | 🔜 | Reports, PDF receipts, thermal printing |
