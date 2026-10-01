namespace AgriLedger.API.Models;

public class SyncQueueItem
{
    public int Id { get; set; }

    /// <summary>party | transaction | bag_movement</summary>
    public string EntityType { get; set; } = string.Empty;

    public string EntityId { get; set; } = string.Empty;

    /// <summary>insert | update | delete</summary>
    public string Operation { get; set; } = string.Empty;

    /// <summary>Full JSON snapshot of the entity</summary>
    public string Payload { get; set; } = string.Empty;

    public int RetryCount { get; set; } = 0;
    public string? LastError { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}
