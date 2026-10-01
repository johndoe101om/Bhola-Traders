namespace AgriLedger.API.Models;

public class Party
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;

    /// <summary>farmer | supplier | customer</summary>
    public string PartyType { get; set; } = string.Empty;

    public string? Phone { get; set; }
    public string? Village { get; set; }
    public string? Notes { get; set; }
    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? SyncedAt { get; set; }

    // Navigation
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    public ICollection<BagMovement> BagMovements { get; set; } = new List<BagMovement>();
}
