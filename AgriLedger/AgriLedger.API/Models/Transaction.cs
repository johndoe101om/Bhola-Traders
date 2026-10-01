namespace AgriLedger.API.Models;

public class Transaction
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string PartyId { get; set; } = string.Empty;

    /// <summary>purchase | sale | cash_in | cash_out</summary>
    public string TxnType { get; set; } = string.Empty;

    /// <summary>rice | wheat | maize — null for cash-only</summary>
    public string? Commodity { get; set; }

    public decimal? QuantityKg { get; set; }
    public decimal? RatePerKg { get; set; }

    /// <summary>Total money amount — always required</summary>
    public decimal Amount { get; set; }

    /// <summary>in | out (relative to our business)</summary>
    public string Direction { get; set; } = string.Empty;

    /// <summary>cash | upi | credit</summary>
    public string PaymentMode { get; set; } = "cash";

    public string? Notes { get; set; }

    /// <summary>Raw voice transcript for audit trail</summary>
    public string? VoiceRaw { get; set; }

    /// <summary>Business date (user can backdate)</summary>
    public DateOnly EntryDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? SyncedAt { get; set; }

    public bool IsDeleted { get; set; } = false;

    // Navigation
    public Party? Party { get; set; }
}
