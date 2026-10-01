using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AgriLedger.API.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[Produces("application/json")]
public class TransactionsController : ControllerBase
{
    private readonly AppDbContext _db;

    public TransactionsController(AppDbContext db) => _db = db;

    // ── GET /api/v1/transactions ──────────────────────────────────────
    /// <summary>List transactions with filters. Supports party, date range, type.</summary>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResponse<TransactionDetail>>>> GetAll(
        [FromQuery] string? partyId,
        [FromQuery] string? type,
        [FromQuery] string? commodity,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        var query = _db.Transactions
            .Include(t => t.Party)
            .Where(t => !t.IsDeleted);

        if (!string.IsNullOrWhiteSpace(partyId))
            query = query.Where(t => t.PartyId == partyId);

        if (!string.IsNullOrWhiteSpace(type))
            query = query.Where(t => t.TxnType == type.ToLower());

        if (!string.IsNullOrWhiteSpace(commodity))
            query = query.Where(t => t.Commodity == commodity.ToLower());

        if (from.HasValue) query = query.Where(t => t.EntryDate >= from.Value);
        if (to.HasValue)   query = query.Where(t => t.EntryDate <= to.Value);

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(t => t.EntryDate)
            .ThenByDescending(t => t.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(t => new TransactionDetail
            {
                Id = t.Id,
                PartyId = t.PartyId,
                PartyName = t.Party!.Name,
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

        return Ok(ApiResponse<PagedResponse<TransactionDetail>>.Ok(new PagedResponse<TransactionDetail>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        }));
    }

    // ── GET /api/v1/transactions/{id} ─────────────────────────────────
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<TransactionDetail>>> GetById(string id)
    {
        var t = await _db.Transactions
            .Include(t => t.Party)
            .FirstOrDefaultAsync(t => t.Id == id && !t.IsDeleted);

        if (t == null)
            return NotFound(ApiResponse<TransactionDetail>.Fail("Transaction not found."));

        return Ok(ApiResponse<TransactionDetail>.Ok(new TransactionDetail
        {
            Id = t.Id,
            PartyId = t.PartyId,
            PartyName = t.Party!.Name,
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
        }));
    }

    // ── GET /api/v1/transactions/summary ─────────────────────────────
    /// <summary>Daily/range summary of purchases, sales, cash in/out.</summary>
    [HttpGet("summary")]
    public async Task<ActionResult<ApiResponse<List<TransactionSummary>>>> GetSummary(
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to)
    {
        var startDate = from ?? DateOnly.FromDateTime(DateTime.Today.AddDays(-30));
        var endDate   = to   ?? DateOnly.FromDateTime(DateTime.Today);

        var summaries = await _db.Transactions
            .Where(t => !t.IsDeleted && t.EntryDate >= startDate && t.EntryDate <= endDate)
            .GroupBy(t => t.EntryDate)
            .Select(g => new TransactionSummary
            {
                Date = g.Key,
                TotalPurchaseAmount = g.Where(t => t.TxnType == "purchase").Sum(t => t.Amount),
                TotalSaleAmount     = g.Where(t => t.TxnType == "sale").Sum(t => t.Amount),
                TotalCashIn         = g.Where(t => t.TxnType == "cash_in").Sum(t => t.Amount),
                TotalCashOut        = g.Where(t => t.TxnType == "cash_out").Sum(t => t.Amount),
                NetCash             = g.Sum(t => t.Direction == "in" ? t.Amount : -t.Amount),
                TotalTransactions   = g.Count()
            })
            .OrderByDescending(s => s.Date)
            .ToListAsync();

        return Ok(ApiResponse<List<TransactionSummary>>.Ok(summaries));
    }

    // ── POST /api/v1/transactions ─────────────────────────────────────
    /// <summary>Record a new transaction (purchase/sale/cash).</summary>
    [HttpPost]
    public async Task<ActionResult<ApiResponse<TransactionDetail>>> Create(
        [FromBody] CreateTransactionRequest req)
    {
        // Validate
        var validationError = await ValidateTransactionRequest(req.PartyId, req.TxnType, req.Amount, req.Commodity);
        if (validationError != null)
            return BadRequest(ApiResponse<TransactionDetail>.Fail(validationError));

        // Auto-calculate amount if not provided but qty+rate are
        var amount = req.Amount;
        if (amount == 0 && req.QuantityKg.HasValue && req.RatePerKg.HasValue)
            amount = req.QuantityKg.Value * req.RatePerKg.Value;

        var txn = new Transaction
        {
            Id = req.Id ?? Guid.NewGuid().ToString(),
            PartyId = req.PartyId,
            TxnType = req.TxnType.ToLower(),
            Commodity = req.Commodity?.ToLower(),
            QuantityKg = req.QuantityKg,
            RatePerKg = req.RatePerKg,
            Amount = amount,
            Direction = AllowedValues.DirectionForTxnType(req.TxnType.ToLower()),
            PaymentMode = req.PaymentMode?.ToLower() ?? "cash",
            Notes = req.Notes?.Trim(),
            VoiceRaw = req.VoiceRaw,
            EntryDate = req.EntryDate ?? DateOnly.FromDateTime(DateTime.Today),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Transactions.Add(txn);
        await _db.SaveChangesAsync();

        var party = await _db.Parties.FindAsync(txn.PartyId);

        return CreatedAtAction(nameof(GetById), new { id = txn.Id },
            ApiResponse<TransactionDetail>.Ok(new TransactionDetail
            {
                Id = txn.Id,
                PartyId = txn.PartyId,
                PartyName = party?.Name ?? "",
                TxnType = txn.TxnType,
                Commodity = txn.Commodity,
                QuantityKg = txn.QuantityKg,
                RatePerKg = txn.RatePerKg,
                Amount = txn.Amount,
                Direction = txn.Direction,
                PaymentMode = txn.PaymentMode,
                Notes = txn.Notes,
                VoiceRaw = txn.VoiceRaw,
                EntryDate = txn.EntryDate,
                CreatedAt = txn.CreatedAt
            }, "Transaction recorded."));
    }

    // ── PUT /api/v1/transactions/{id} ─────────────────────────────────
    /// <summary>Correct a transaction (edit quantity, rate, amount, notes).</summary>
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<TransactionDetail>>> Update(
        string id,
        [FromBody] UpdateTransactionRequest req)
    {
        var txn = await _db.Transactions
            .Include(t => t.Party)
            .FirstOrDefaultAsync(t => t.Id == id && !t.IsDeleted);

        if (txn == null)
            return NotFound(ApiResponse<TransactionDetail>.Fail("Transaction not found."));

        // Allow editing correction fields only
        txn.Commodity = req.Commodity?.ToLower() ?? txn.Commodity;
        txn.QuantityKg = req.QuantityKg ?? txn.QuantityKg;
        txn.RatePerKg = req.RatePerKg ?? txn.RatePerKg;
        txn.Amount = req.Amount > 0 ? req.Amount : txn.Amount;
        txn.PaymentMode = req.PaymentMode?.ToLower() ?? txn.PaymentMode;
        txn.Notes = req.Notes ?? txn.Notes;
        txn.EntryDate = req.EntryDate ?? txn.EntryDate;
        txn.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(ApiResponse<TransactionDetail>.Ok(new TransactionDetail
        {
            Id = txn.Id,
            PartyId = txn.PartyId,
            PartyName = txn.Party?.Name ?? "",
            TxnType = txn.TxnType,
            Commodity = txn.Commodity,
            QuantityKg = txn.QuantityKg,
            RatePerKg = txn.RatePerKg,
            Amount = txn.Amount,
            Direction = txn.Direction,
            PaymentMode = txn.PaymentMode,
            Notes = txn.Notes,
            EntryDate = txn.EntryDate,
            CreatedAt = txn.CreatedAt
        }, "Transaction updated."));
    }

    // ── DELETE /api/v1/transactions/{id} ──────────────────────────────
    /// <summary>Soft-delete a transaction.</summary>
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> Delete(string id)
    {
        var txn = await _db.Transactions.FindAsync(id);
        if (txn == null || txn.IsDeleted)
            return NotFound(ApiResponse<object>.Fail("Transaction not found."));

        txn.IsDeleted = true;
        txn.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { }, "Transaction deleted."));
    }

    // ── HELPERS ───────────────────────────────────────────────────────

    private async Task<string?> ValidateTransactionRequest(
        string partyId, string txnType, decimal amount, string? commodity)
    {
        if (!await _db.Parties.AnyAsync(p => p.Id == partyId && p.IsActive))
            return "Party not found.";

        if (!AllowedValues.TxnTypes.Contains(txnType.ToLower()))
            return $"Invalid txn_type. Allowed: {string.Join(", ", AllowedValues.TxnTypes)}";

        if (amount <= 0)
            return "Amount must be greater than zero.";

        // Grain transactions need commodity
        if ((txnType == "purchase" || txnType == "sale") &&
            !string.IsNullOrEmpty(commodity) &&
            !AllowedValues.Commodities.Contains(commodity.ToLower()))
            return $"Invalid commodity. Allowed: {string.Join(", ", AllowedValues.Commodities)}";

        return null;
    }
}
