using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace AgriLedger.API.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[Produces("application/json")]
public class SyncController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ILogger<SyncController> _logger;

    public SyncController(AppDbContext db, ILogger<SyncController> logger)
    {
        _db = db;
        _logger = logger;
    }

    // ── POST /api/v1/sync/push ────────────────────────────────────────
    /// <summary>
    /// Mobile app pushes queued offline changes.
    /// Server applies them and returns accepted/conflict IDs.
    /// </summary>
    [HttpPost("push")]
    public async Task<ActionResult<ApiResponse<SyncPushResponse>>> Push([FromBody] SyncPushRequest req)
    {
        var accepted = new List<string>();
        var conflicts = new List<SyncConflict>();

        foreach (var change in req.Changes)
        {
            try
            {
                await ApplyChange(change);
                accepted.Add(change.EntityId);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Sync conflict for entity {EntityId}", change.EntityId);
                conflicts.Add(new SyncConflict
                {
                    EntityId = change.EntityId,
                    Reason = ex.Message
                });

                // Log to sync queue for audit
                _db.SyncQueue.Add(new SyncQueueItem
                {
                    EntityType = change.EntityType,
                    EntityId = change.EntityId,
                    Operation = change.Operation,
                    Payload = JsonSerializer.Serialize(change.Payload),
                    LastError = ex.Message,
                    CreatedAt = DateTime.UtcNow
                });
            }
        }

        await _db.SaveChangesAsync();

        return Ok(ApiResponse<SyncPushResponse>.Ok(new SyncPushResponse
        {
            Accepted = accepted,
            Conflicts = conflicts,
            ServerTime = DateTime.UtcNow
        }));
    }

    // ── POST /api/v1/sync/pull ────────────────────────────────────────
    /// <summary>
    /// Mobile app pulls server changes since last sync timestamp.
    /// Used for multi-device sync.
    /// </summary>
    [HttpGet("pull")]
    public async Task<ActionResult<ApiResponse<object>>> Pull(
        [FromQuery] DateTime? since)
    {
        var cutoff = since ?? DateTime.UtcNow.AddDays(-7);

        var parties = await _db.Parties
            .Where(p => p.UpdatedAt > cutoff)
            .ToListAsync();

        var transactions = await _db.Transactions
            .Where(t => t.UpdatedAt > cutoff)
            .ToListAsync();

        var bags = await _db.BagMovements
            .Where(b => b.UpdatedAt > cutoff)
            .ToListAsync();

        return Ok(ApiResponse<object>.Ok(new
        {
            server_time = DateTime.UtcNow,
            changes = new
            {
                parties,
                transactions,
                bag_movements = bags
            },
            counts = new
            {
                parties = parties.Count,
                transactions = transactions.Count,
                bag_movements = bags.Count
            }
        }));
    }

    // ── HELPERS ───────────────────────────────────────────────────────

    private async Task ApplyChange(SyncChangeItem change)
    {
        var payload = JsonSerializer.Serialize(change.Payload);
        var opts = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };

        switch (change.EntityType.ToLower())
        {
            case "party":
                var party = JsonSerializer.Deserialize<Party>(payload, opts)
                    ?? throw new Exception("Invalid party payload");
                await UpsertParty(party);
                break;

            case "transaction":
                var txn = JsonSerializer.Deserialize<Transaction>(payload, opts)
                    ?? throw new Exception("Invalid transaction payload");
                await UpsertTransaction(txn);
                break;

            case "bag_movement":
                var bag = JsonSerializer.Deserialize<BagMovement>(payload, opts)
                    ?? throw new Exception("Invalid bag_movement payload");
                await UpsertBagMovement(bag);
                break;

            default:
                throw new Exception($"Unknown entity type: {change.EntityType}");
        }
    }

    private async Task UpsertParty(Party incoming)
    {
        var existing = await _db.Parties.FindAsync(incoming.Id);
        if (existing == null)
        {
            _db.Parties.Add(incoming);
        }
        else
        {
            // Last-write-wins by UpdatedAt
            if (incoming.UpdatedAt > existing.UpdatedAt)
            {
                existing.Name = incoming.Name;
                existing.PartyType = incoming.PartyType;
                existing.Phone = incoming.Phone;
                existing.Village = incoming.Village;
                existing.Notes = incoming.Notes;
                existing.IsActive = incoming.IsActive;
                existing.UpdatedAt = incoming.UpdatedAt;
                existing.SyncedAt = DateTime.UtcNow;
            }
        }
    }

    private async Task UpsertTransaction(Transaction incoming)
    {
        var existing = await _db.Transactions.FindAsync(incoming.Id);
        if (existing == null)
        {
            incoming.SyncedAt = DateTime.UtcNow;
            _db.Transactions.Add(incoming);
        }
        else
        {
            if (incoming.UpdatedAt > existing.UpdatedAt)
            {
                existing.Commodity = incoming.Commodity;
                existing.QuantityKg = incoming.QuantityKg;
                existing.RatePerKg = incoming.RatePerKg;
                existing.Amount = incoming.Amount;
                existing.Notes = incoming.Notes;
                existing.IsDeleted = incoming.IsDeleted;
                existing.UpdatedAt = incoming.UpdatedAt;
                existing.SyncedAt = DateTime.UtcNow;
            }
        }
    }

    private async Task UpsertBagMovement(BagMovement incoming)
    {
        var existing = await _db.BagMovements.FindAsync(incoming.Id);
        if (existing == null)
        {
            incoming.SyncedAt = DateTime.UtcNow;
            _db.BagMovements.Add(incoming);
        }
        else
        {
            if (incoming.UpdatedAt > existing.UpdatedAt)
            {
                existing.Quantity = incoming.Quantity;
                existing.Notes = incoming.Notes;
                existing.UpdatedAt = incoming.UpdatedAt;
                existing.SyncedAt = DateTime.UtcNow;
            }
        }
    }
}
