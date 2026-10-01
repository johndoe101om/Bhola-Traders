namespace AgriLedger.API.Models;

public class BagMovement
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string PartyId { get; set; } = string.Empty;

    /// <summary>given | returned</summary>
    public string Movement { get; set; } = string.Empty;

    public int Quantity { get; set; }

    /// <summary>Optional link to a grain transaction</summary>
    public string? LinkedTxnId { get; set; }

    public string? Notes { get; set; }

    public DateOnly EntryDate { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? SyncedAt { get; set; }

    // Navigation
    public Party? Party { get; set; }
    public Transaction? LinkedTransaction { get; set; }
}
