using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AgriLedger.API.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[Produces("application/json")]
public class BagsController : ControllerBase
{
    private readonly AppDbContext _db;

    public BagsController(AppDbContext db) => _db = db;

    // ── GET /api/v1/bags ──────────────────────────────────────────────
    /// <summary>List all bag movements with optional filters.</summary>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResponse<BagMovementDetail>>>> GetAll(
        [FromQuery] string? partyId,
        [FromQuery] string? movement,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        var query = _db.BagMovements.Include(b => b.Party).AsQueryable();

        if (!string.IsNullOrWhiteSpace(partyId))
            query = query.Where(b => b.PartyId == partyId);

        if (!string.IsNullOrWhiteSpace(movement))
            query = query.Where(b => b.Movement == movement.ToLower());

        if (from.HasValue) query = query.Where(b => b.EntryDate >= from.Value);
        if (to.HasValue) query = query.Where(b => b.EntryDate <= to.Value);

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(b => b.EntryDate)
            .ThenByDescending(b => b.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(b => new BagMovementDetail
            {
                Id = b.Id,
                PartyId = b.PartyId,
                PartyName = b.Party!.Name,
                Movement = b.Movement,
                Quantity = b.Quantity,
                LinkedTxnId = b.LinkedTxnId,
                Notes = b.Notes,
                EntryDate = b.EntryDate,
                CreatedAt = b.CreatedAt
            })
            .ToListAsync();

        return Ok(ApiResponse<PagedResponse<BagMovementDetail>>.Ok(new PagedResponse<BagMovementDetail>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        }));
    }

    // ── GET /api/v1/bags/outstanding ──────────────────────────────────
    /// <summary>All parties with bags still outstanding (bori not returned).</summary>
    [HttpGet("outstanding")]
    public async Task<ActionResult<ApiResponse<List<BagOutstandingSummary>>>> GetOutstanding()
    {
        var summary = await _db.BagMovements
            .Include(b => b.Party)
            .Where(b => b.Party!.IsActive)
            .GroupBy(b => new { b.PartyId, b.Party!.Name, b.Party.Village })
            .Select(g => new BagOutstandingSummary
            {
                PartyId = g.Key.PartyId,
                PartyName = g.Key.Name,
                Village = g.Key.Village,
                BagsGiven = g.Where(b => b.Movement == "given").Sum(b => b.Quantity),
                BagsReturned = g.Where(b => b.Movement == "returned").Sum(b => b.Quantity),
                BagsOutstanding = g.Sum(b => b.Movement == "given" ? b.Quantity : -b.Quantity)
            })
            .Where(s => s.BagsOutstanding > 0)
            .OrderByDescending(s => s.BagsOutstanding)
            .ToListAsync();

        return Ok(ApiResponse<List<BagOutstandingSummary>>.Ok(summary));
    }

    // ── GET /api/v1/bags/party/{partyId} ─────────────────────────────
    /// <summary>Bag history for a specific party.</summary>
    [HttpGet("party/{partyId}")]
    public async Task<ActionResult<ApiResponse<object>>> GetForParty(string partyId)
    {
        var party = await _db.Parties.FindAsync(partyId);
        if (party == null || !party.IsActive)
            return NotFound(ApiResponse<object>.Fail("Party not found."));

        var movements = await _db.BagMovements
            .Where(b => b.PartyId == partyId)
            .OrderByDescending(b => b.EntryDate)
            .Select(b => new BagMovementDetail
            {
                Id = b.Id,
                PartyId = b.PartyId,
                PartyName = party.Name,
                Movement = b.Movement,
                Quantity = b.Quantity,
                LinkedTxnId = b.LinkedTxnId,
                Notes = b.Notes,
                EntryDate = b.EntryDate,
                CreatedAt = b.CreatedAt
            })
            .ToListAsync();

        var totalGiven = movements.Where(m => m.Movement == "given").Sum(m => m.Quantity);
        var totalReturned = movements.Where(m => m.Movement == "returned").Sum(m => m.Quantity);

        return Ok(ApiResponse<object>.Ok(new
        {
            party = new { party.Id, party.Name, party.Village },
            summary = new
            {
                total_given = totalGiven,
                total_returned = totalReturned,
                outstanding = totalGiven - totalReturned
            },
            movements
        }));
    }

    // ── POST /api/v1/bags ─────────────────────────────────────────────
    /// <summary>Record a bag given or returned.</summary>
    [HttpPost]
    public async Task<ActionResult<ApiResponse<BagMovementDetail>>> Create(
        [FromBody] CreateBagMovementRequest req)
    {
        // Validate
        if (!await _db.Parties.AnyAsync(p => p.Id == req.PartyId && p.IsActive))
            return NotFound(ApiResponse<BagMovementDetail>.Fail("Party not found."));

        if (!AllowedValues.BagMovements.Contains(req.Movement.ToLower()))
            return BadRequest(ApiResponse<BagMovementDetail>.Fail(
                "Invalid movement. Allowed: given, returned"));

        if (req.Quantity <= 0)
            return BadRequest(ApiResponse<BagMovementDetail>.Fail(
                "Quantity must be greater than 0."));

        // If returning, check they actually have bags outstanding
        if (req.Movement.ToLower() == "returned")
        {
            var outstanding = await _db.BagMovements
                .Where(b => b.PartyId == req.PartyId)
                .SumAsync(b => b.Movement == "given" ? b.Quantity : -b.Quantity);

            if (req.Quantity > outstanding)
                return BadRequest(ApiResponse<BagMovementDetail>.Fail(
                    $"Cannot return {req.Quantity} bags. Only {outstanding} outstanding."));
        }

        // Validate linked transaction if provided
        if (!string.IsNullOrEmpty(req.LinkedTxnId))
        {
            if (!await _db.Transactions.AnyAsync(t => t.Id == req.LinkedTxnId && !t.IsDeleted))
                return BadRequest(ApiResponse<BagMovementDetail>.Fail(
                    "Linked transaction not found."));
        }

        var bag = new BagMovement
        {
            Id = req.Id ?? Guid.NewGuid().ToString(),
            PartyId = req.PartyId,
            Movement = req.Movement.ToLower(),
            Quantity = req.Quantity,
            LinkedTxnId = req.LinkedTxnId,
            Notes = req.Notes?.Trim(),
            EntryDate = req.EntryDate ?? DateOnly.FromDateTime(DateTime.Today),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.BagMovements.Add(bag);
        await _db.SaveChangesAsync();

        var party = await _db.Parties.FindAsync(bag.PartyId);

        return CreatedAtAction(nameof(GetAll), new { },
            ApiResponse<BagMovementDetail>.Ok(new BagMovementDetail
            {
                Id = bag.Id,
                PartyId = bag.PartyId,
                PartyName = party?.Name ?? "",
                Movement = bag.Movement,
                Quantity = bag.Quantity,
                LinkedTxnId = bag.LinkedTxnId,
                Notes = bag.Notes,
                EntryDate = bag.EntryDate,
                CreatedAt = bag.CreatedAt
            }, $"{req.Quantity} bag(s) {req.Movement} recorded."));
    }
}
