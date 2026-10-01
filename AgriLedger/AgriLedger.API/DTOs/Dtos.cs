using System.ComponentModel.DataAnnotations;

namespace AgriLedger.API.DTOs;

// ─────────────────────────────────────────────
// PARTY DTOs
// ─────────────────────────────────────────────

public class CreatePartyRequest
{
    public string? Id { get; set; }          // client-generated UUID (optional)

    [Required(ErrorMessage = "Name is required")]
    [StringLength(200, MinimumLength = 1, ErrorMessage = "Name must be between 1 and 200 characters")]
    public required string Name { get; set; }

    [Required(ErrorMessage = "PartyType is required")]
    [StringLength(20, ErrorMessage = "PartyType cannot exceed 20 characters")]
    public required string PartyType { get; set; }  // farmer | supplier | customer

    [StringLength(15, ErrorMessage = "Phone cannot exceed 15 digits")]
    [RegularExpression(@"^[0-9+\s-]*$", ErrorMessage = "Invalid phone number format")]
    public string? Phone { get; set; }

    [StringLength(100, ErrorMessage = "Village cannot exceed 100 characters")]
    public string? Village { get; set; }

    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters")]
    public string? Notes { get; set; }
}

public class UpdatePartyRequest
{
    [Required(ErrorMessage = "Name is required")]
    [StringLength(200, MinimumLength = 1, ErrorMessage = "Name must be between 1 and 200 characters")]
    public required string Name { get; set; }

    [Required(ErrorMessage = "PartyType is required")]
    [StringLength(20, ErrorMessage = "PartyType cannot exceed 20 characters")]
    public required string PartyType { get; set; }

    [StringLength(15, ErrorMessage = "Phone cannot exceed 15 digits")]
    [RegularExpression(@"^[0-9+\s-]*$", ErrorMessage = "Invalid phone number format")]
    public string? Phone { get; set; }

    [StringLength(100, ErrorMessage = "Village cannot exceed 100 characters")]
    public string? Village { get; set; }

    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters")]
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

    [Required(ErrorMessage = "PartyId is required")]
    [StringLength(36, ErrorMessage = "PartyId must be a valid identifier")]
    public required string PartyId { get; set; }

    /// <summary>purchase | sale | cash_in | cash_out</summary>
    [Required(ErrorMessage = "TxnType is required")]
    [StringLength(20, ErrorMessage = "TxnType cannot exceed 20 characters")]
    public required string TxnType { get; set; }

    [StringLength(50, ErrorMessage = "Commodity cannot exceed 50 characters")]
    public string? Commodity { get; set; }

    [Range(0, 1000000, ErrorMessage = "QuantityKg must be between 0 and 1,000,000")]
    public decimal? QuantityKg { get; set; }

    [Range(0, 1000000, ErrorMessage = "RatePerKg must be between 0 and 1,000,000")]
    public decimal? RatePerKg { get; set; }

    [Required(ErrorMessage = "Amount is required")]
    [Range(0.01, 100000000, ErrorMessage = "Amount must be greater than 0")]
    public required decimal Amount { get; set; }

    /// <summary>cash | upi | credit</summary>
    [StringLength(20, ErrorMessage = "PaymentMode cannot exceed 20 characters")]
    public string PaymentMode { get; set; } = "cash";

    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters")]
    public string? Notes { get; set; }

    [StringLength(1000, ErrorMessage = "VoiceRaw cannot exceed 1000 characters")]
    public string? VoiceRaw { get; set; }

    public DateOnly? EntryDate { get; set; }
}

public class UpdateTransactionRequest
{
    [StringLength(50, ErrorMessage = "Commodity cannot exceed 50 characters")]
    public string? Commodity { get; set; }

    [Range(0, 1000000, ErrorMessage = "QuantityKg must be between 0 and 1,000,000")]
    public decimal? QuantityKg { get; set; }

    [Range(0, 1000000, ErrorMessage = "RatePerKg must be between 0 and 1,000,000")]
    public decimal? RatePerKg { get; set; }

    [Range(0.01, 100000000, ErrorMessage = "Amount must be greater than 0")]
    public decimal Amount { get; set; }

    [StringLength(20, ErrorMessage = "PaymentMode cannot exceed 20 characters")]
    public string PaymentMode { get; set; } = "cash";

    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters")]
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

    [Required(ErrorMessage = "PartyId is required")]
    [StringLength(36, ErrorMessage = "PartyId must be a valid identifier")]
    public required string PartyId { get; set; }

    /// <summary>given | returned</summary>
    [Required(ErrorMessage = "Movement is required")]
    [StringLength(10, ErrorMessage = "Movement cannot exceed 10 characters")]
    public required string Movement { get; set; }

    [Required(ErrorMessage = "Quantity is required")]
    [Range(1, 100000, ErrorMessage = "Quantity must be between 1 and 100,000")]
    public required int Quantity { get; set; }

    [StringLength(36)]
    public string? LinkedTxnId { get; set; }

    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters")]
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
    [Required(ErrorMessage = "DeviceId is required")]
    [StringLength(100)]
    public string DeviceId { get; set; } = "";

    public List<SyncChangeItem> Changes { get; set; } = new();
}

public class SyncChangeItem
{
    [Required]
    [StringLength(50)]
    public string EntityType { get; set; } = "";

    [Required]
    [StringLength(36)]
    public string EntityId { get; set; } = "";

    [Required]
    [StringLength(20)]
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
    public List<string> Errors { get; set; } = new();

    public static ApiResponse<T> Ok(T data, string? message = null) =>
        new() { Success = true, Data = data, Message = message, Errors = new() };

    public static ApiResponse<T> Fail(string message, List<string>? errors = null) =>
        new() { Success = false, Message = message, Errors = errors ?? (string.IsNullOrEmpty(message) ? new() : new() { message }) };
}

public class PagedResponse<T>
{
    public List<T> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)TotalCount / PageSize) : 0;
}
