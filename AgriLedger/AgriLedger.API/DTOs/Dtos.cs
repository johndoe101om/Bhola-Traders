namespace AgriLedger.API.DTOs;

// ─────────────────────────────────────────────
// PARTY DTOs
// ─────────────────────────────────────────────

public class CreatePartyRequest
{
    public string? Id { get; set; }          // client-generated UUID (optional)
    public required string Name { get; set; }
    public required string PartyType { get; set; }  // farmer | supplier | customer
    public string? Phone { get; set; }
    public string? Village { get; set; }
    public string? Notes { get; set; }
}

public class UpdatePartyRequest
{
    public required string Name { get; set; }
    public required string PartyType { get; set; }
    public string? Phone { get; set; }
    public string? Village { get; set; }
    public string? Notes { get; set; }
}

public class PartyListItem
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string PartyType { get; set; } = "";
    public string? Phone { get; set; }
    public string? Village { get; set; }
    public decimal Balance { get; set; }            // +ve = they owe us, -ve = we owe them
    public int BagsOutstanding { get; set; }        // +ve = bags still with them
    public int TotalTransactions { get; set; }
}

public class PartyLedgerResponse
{
    public PartyDetail Party { get; set; } = new();
    public BalanceSummary Balance { get; set; } = new();
    public int BagsOutstanding { get; set; }
    public List<TransactionDetail> Transactions { get; set; } = new();
    public List<BagMovementDetail> BagMovements { get; set; } = new();
}

public class PartyDetail
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string PartyType { get; set; } = "";
    public string? Phone { get; set; }
    public string? Village { get; set; }
    public string? Notes { get; set; }
}

public class BalanceSummary
{
    public decimal Amount { get; set; }
    /// <summary>they_owe_us | we_owe_them | settled</summary>
    public string Direction { get; set; } = "settled";
}

// ─────────────────────────────────────────────
// TRANSACTION DTOs
// ─────────────────────────────────────────────

public class CreateTransactionRequest
{
    public string? Id { get; set; }
    public required string PartyId { get; set; }

    /// <summary>purchase | sale | cash_in | cash_out</summary>
    public required string TxnType { get; set; }

    public string? Commodity { get; set; }
    public decimal? QuantityKg { get; set; }
    public decimal? RatePerKg { get; set; }
    public required decimal Amount { get; set; }

    /// <summary>cash | upi | credit</summary>
    public string PaymentMode { get; set; } = "cash";

    public string? Notes { get; set; }
    public string? VoiceRaw { get; set; }
    public DateOnly? EntryDate { get; set; }
}

public class UpdateTransactionRequest
{
    public string? Commodity { get; set; }
    public decimal? QuantityKg { get; set; }
    public decimal? RatePerKg { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = "cash";
    public string? Notes { get; set; }
    public DateOnly? EntryDate { get; set; }
}

public class TransactionDetail
{
    public string Id { get; set; } = "";
    public string PartyId { get; set; } = "";
    public string PartyName { get; set; } = "";
    public string TxnType { get; set; } = "";
    public string? Commodity { get; set; }
    public decimal? QuantityKg { get; set; }
    public decimal? RatePerKg { get; set; }
    public decimal Amount { get; set; }
    public string Direction { get; set; } = "";
    public string PaymentMode { get; set; } = "";
    public string? Notes { get; set; }
    public string? VoiceRaw { get; set; }
    public DateOnly EntryDate { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class TransactionSummary
{
    public DateOnly Date { get; set; }
    public decimal TotalPurchaseAmount { get; set; }
    public decimal TotalSaleAmount { get; set; }
    public decimal TotalCashIn { get; set; }
    public decimal TotalCashOut { get; set; }
    public decimal NetCash { get; set; }
    public int TotalTransactions { get; set; }
}

// ─────────────────────────────────────────────
// BAG MOVEMENT DTOs
// ─────────────────────────────────────────────

public class CreateBagMovementRequest
{
    public string? Id { get; set; }
    public required string PartyId { get; set; }

    /// <summary>given | returned</summary>
    public required string Movement { get; set; }

    public required int Quantity { get; set; }
    public string? LinkedTxnId { get; set; }
    public string? Notes { get; set; }
    public DateOnly? EntryDate { get; set; }
}

public class BagMovementDetail
{
    public string Id { get; set; } = "";
    public string PartyId { get; set; } = "";
    public string PartyName { get; set; } = "";
    public string Movement { get; set; } = "";
    public int Quantity { get; set; }
    public string? LinkedTxnId { get; set; }
    public string? Notes { get; set; }
    public DateOnly EntryDate { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class BagOutstandingSummary
{
    public string PartyId { get; set; } = "";
    public string PartyName { get; set; } = "";
    public string? Village { get; set; }
    public int BagsGiven { get; set; }
    public int BagsReturned { get; set; }
    public int BagsOutstanding { get; set; }
}

// ─────────────────────────────────────────────
// SYNC DTOs
// ─────────────────────────────────────────────

public class SyncPushRequest
{
    public string DeviceId { get; set; } = "";
    public List<SyncChangeItem> Changes { get; set; } = new();
}

public class SyncChangeItem
{
    public string EntityType { get; set; } = "";
    public string EntityId { get; set; } = "";
    public string Operation { get; set; } = "";
    public object Payload { get; set; } = new();
    public DateTime ClientTimestamp { get; set; }
}

public class SyncPushResponse
{
    public List<string> Accepted { get; set; } = new();
    public List<SyncConflict> Conflicts { get; set; } = new();
    public DateTime ServerTime { get; set; } = DateTime.UtcNow;
}

public class SyncConflict
{
    public string EntityId { get; set; } = "";
    public string Reason { get; set; } = "";
}

// ─────────────────────────────────────────────
// COMMON
// ─────────────────────────────────────────────

public class ApiResponse<T>
{
    public bool Success { get; set; } = true;
    public string? Message { get; set; }
    public T? Data { get; set; }

    public static ApiResponse<T> Ok(T data, string? message = null) =>
        new() { Success = true, Data = data, Message = message };

    public static ApiResponse<T> Fail(string message) =>
        new() { Success = false, Message = message };
}

public class PagedResponse<T>
{
    public List<T> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
}
