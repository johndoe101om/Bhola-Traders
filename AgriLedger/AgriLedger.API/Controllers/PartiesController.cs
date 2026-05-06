using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AgriLedger.API.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[Produces("application/json")]
public class PartiesController : ControllerBase
{
    private readonly AppDbContext _db;

    public PartiesController(AppDbContext db) => _db = db;

    // ── GET /api/v1/parties ───────────────────────────────────────────
    /// <summary>List all parties with balance and bag summary.</summary>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<PartyListItem>>>> GetAll(
        [FromQuery] string? type,
        [FromQuery] string? q,
        [FromQuery] string? village)
    {
        var query = _db.Parties.Where(p => p.IsActive);

        if (!string.IsNullOrWhiteSpace(type))
            query = query.Where(p => p.PartyType == type.ToLower());

        if (!string.IsNullOrWhiteSpace(village))
            query = query.Where(p => p.Village != null && EF.Functions.Like(p.Village, $"%{village}%"));

        if (!string.IsNullOrWhiteSpace(q))
            query = query.Where(p =>
                EF.Functions.Like(p.Name, $"%{q}%") ||
                (p.Village != null && EF.Functions.Like(p.Village, $"%{q}%")) ||
                (p.Phone != null && p.Phone.Contains(q)));

        var parties = await query
            .OrderBy(p => p.Name)
            .Select(p => new PartyListItem
            {
                Id = p.Id,
                Name = p.Name,
                PartyType = p.PartyType,
                Phone = p.Phone,
                Village = p.Village,
                Balance = p.Transactions
                    .Where(t => !t.IsDeleted)
                    .Sum(t => t.Direction == "in" ? t.Amount : -t.Amount),
                BagsOutstanding = p.BagMovements
                    .Sum(b => b.Movement == "given" ? b.Quantity : -b.Quantity),
                TotalTransactions = p.Transactions.Count(t => !t.IsDeleted)
            })
            .ToListAsync();

        return Ok(ApiResponse<List<PartyListItem>>.Ok(parties));
    }

    // ── GET /api/v1/parties/{id} ──────────────────────────────────────
    /// <summary>Get single party detail.</summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<PartyDetail>>> GetById(string id)
    {
        var party = await _db.Parties.FindAsync(id);
        if (party == null || !party.IsActive)
            return NotFound(ApiResponse<PartyDetail>.Fail("Party not found."));

        return Ok(ApiResponse<PartyDetail>.Ok(new PartyDetail
        {
            Id = party.Id,
            Name = party.Name,
            PartyType = party.PartyType,
            Phone = party.Phone,
            Village = party.Village,
            Notes = party.Notes
        }));
    }

    // ── GET /api/v1/parties/{id}/ledger ──────────────────────────────
    /// <summary>Full khata (ledger) for a party — transactions + bags + balance.</summary>
    [HttpGet("{id}/ledger")]
    public async Task<ActionResult<ApiResponse<PartyLedgerResponse>>> GetLedger(
        string id,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to)
    {
        var party = await _db.Parties.FindAsync(id);
        if (party == null || !party.IsActive)
            return NotFound(ApiResponse<PartyLedgerResponse>.Fail("Party not found."));

        // Transactions query
        var txnQuery = _db.Transactions
            .Where(t => t.PartyId == id && !t.IsDeleted);

        if (from.HasValue) txnQuery = txnQuery.Where(t => t.EntryDate >= from.Value);
        if (to.HasValue)   txnQuery = txnQuery.Where(t => t.EntryDate <= to.Value);

        var transactions = await txnQuery
            .OrderByDescending(t => t.EntryDate)
            .ThenByDescending(t => t.CreatedAt)
            .Select(t => new TransactionDetail
            {
                Id = t.Id,
                PartyId = t.PartyId,
                PartyName = party.Name,
                TxnType = t.TxnType,
                Commodity = t.Commodity,
                QuantityKg = t.QuantityKg,
                RatePerKg = t.RatePerKg,
                Amount = t.Amount,
                Direction = t.Direction,
                PaymentMode = t.PaymentMode,
                Notes = t.Notes,
                VoiceRaw = t.VoiceRaw,
                EntryDate = t.EntryDate,
                CreatedAt = t.CreatedAt
            })
            .ToListAsync();

        // Bag movements
        var bags = await _db.BagMovements
            .Where(b => b.PartyId == id)
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

        // Balance calculation
        var rawBalance = transactions.Sum(t => t.Direction == "in" ? t.Amount : -t.Amount);
        var bagsOut = bags.Sum(b => b.Movement == "given" ? b.Quantity : -b.Quantity);

        var balanceDirection = rawBalance > 0 ? "they_owe_us"
                             : rawBalance < 0 ? "we_owe_them"
                             : "settled";

        return Ok(ApiResponse<PartyLedgerResponse>.Ok(new PartyLedgerResponse
        {
            Party = new PartyDetail
            {
                Id = party.Id,
                Name = party.Name,
                PartyType = party.PartyType,
                Phone = party.Phone,
                Village = party.Village,
                Notes = party.Notes
            },
            Balance = new BalanceSummary
            {
                Amount = Math.Abs(rawBalance),
                Direction = balanceDirection
            },
            BagsOutstanding = bagsOut,
            Transactions = transactions,
            BagMovements = bags
        }));
    }

    // ── POST /api/v1/parties ──────────────────────────────────────────
    /// <summary>Create a new party (farmer/supplier/customer).</summary>
    [HttpPost]
    public async Task<ActionResult<ApiResponse<PartyDetail>>> Create([FromBody] CreatePartyRequest req)
    {
        // Validate party type
        if (!AllowedValues.PartyTypes.Contains(req.PartyType.ToLower()))
            return BadRequest(ApiResponse<PartyDetail>.Fail(
                $"Invalid party_type. Allowed: {string.Join(", ", AllowedValues.PartyTypes)}"));

        // Check duplicate name in same village
        var duplicate = await _db.Parties
            .AnyAsync(p => p.Name == req.Name && p.Village == req.Village && p.IsActive);
        if (duplicate)
            return Conflict(ApiResponse<PartyDetail>.Fail(
                $"Party '{req.Name}' already exists in '{req.Village}'."));

        var party = new Party
        {
            Id = req.Id ?? Guid.NewGuid().ToString(),
            Name = req.Name.Trim(),
            PartyType = req.PartyType.ToLower(),
            Phone = req.Phone?.Trim(),
            Village = req.Village?.Trim(),
            Notes = req.Notes?.Trim(),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Parties.Add(party);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = party.Id },
            ApiResponse<PartyDetail>.Ok(new PartyDetail
            {
                Id = party.Id,
                Name = party.Name,
                PartyType = party.PartyType,
                Phone = party.Phone,
                Village = party.Village,
                Notes = party.Notes
            }, "Party created successfully."));
    }

    // ── PUT /api/v1/parties/{id} ──────────────────────────────────────
    /// <summary>Update party details.</summary>
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<PartyDetail>>> Update(string id, [FromBody] UpdatePartyRequest req)
    {
        var party = await _db.Parties.FindAsync(id);
        if (party == null || !party.IsActive)
            return NotFound(ApiResponse<PartyDetail>.Fail("Party not found."));

        if (!AllowedValues.PartyTypes.Contains(req.PartyType.ToLower()))
            return BadRequest(ApiResponse<PartyDetail>.Fail(
                $"Invalid party_type. Allowed: {string.Join(", ", AllowedValues.PartyTypes)}"));

        party.Name = req.Name.Trim();
        party.PartyType = req.PartyType.ToLower();
        party.Phone = req.Phone?.Trim();
        party.Village = req.Village?.Trim();
        party.Notes = req.Notes?.Trim();
        party.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(ApiResponse<PartyDetail>.Ok(new PartyDetail
        {
            Id = party.Id,
            Name = party.Name,
            PartyType = party.PartyType,
            Phone = party.Phone,
            Village = party.Village,
            Notes = party.Notes
        }, "Party updated."));
    }

    // ── DELETE /api/v1/parties/{id} ───────────────────────────────────
    /// <summary>Soft-delete a party (data is preserved).</summary>
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> Delete(string id)
    {
        var party = await _db.Parties.FindAsync(id);
        if (party == null || !party.IsActive)
            return NotFound(ApiResponse<object>.Fail("Party not found."));

        party.IsActive = false;
        party.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { }, "Party deleted."));
    }
}
