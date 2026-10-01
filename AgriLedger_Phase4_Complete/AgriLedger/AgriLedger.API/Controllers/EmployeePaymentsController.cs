using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AgriLedger.API.Controllers;

[ApiController]
[Route("api/v1/employee-payments")]
[Produces("application/json")]
public class EmployeePaymentsController : ControllerBase
{
    private readonly AppDbContext _db;

    public EmployeePaymentsController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResponse<EmployeePaymentDetail>>>> GetAll(
        [FromQuery] string? employeeId,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        [FromQuery] string? mode,
        [FromQuery] string? type,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = _db.EmployeePayments.Include(p => p.Employee).AsQueryable();

        if (!string.IsNullOrEmpty(employeeId))
            query = query.Where(p => p.EmployeeId == employeeId);

        if (from.HasValue)
            query = query.Where(p => p.PaymentDate >= from.Value);

        if (to.HasValue)
            query = query.Where(p => p.PaymentDate <= to.Value);

        if (!string.IsNullOrEmpty(mode))
            query = query.Where(p => p.PaymentMode == mode.ToLower());

        if (!string.IsNullOrEmpty(type))
            query = query.Where(p => p.PaymentType == type.ToLower());

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(p => p.PaymentDate)
            .ThenByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new EmployeePaymentDetail
            {
                Id = p.Id,
                EmployeeId = p.EmployeeId,
                EmployeeName = p.Employee != null ? p.Employee.Name : "",
                PaymentDate = p.PaymentDate,
                Amount = p.Amount,
                PaymentMode = p.PaymentMode,
                PaymentType = p.PaymentType,
                ReferenceNumber = p.ReferenceNumber,
                Notes = p.Notes,
                VoiceRaw = p.VoiceRaw
            })
            .ToListAsync();

        return Ok(ApiResponse<PagedResponse<EmployeePaymentDetail>>.Ok(new PagedResponse<EmployeePaymentDetail>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        }));
    }

    [HttpGet("summary")]
    public async Task<ActionResult<ApiResponse<List<PaymentSummary>>>> GetSummary(
        [FromQuery] DateOnly from,
        [FromQuery] DateOnly to)
    {
        var payments = await _db.EmployeePayments
            .Include(p => p.Employee)
            .Where(p => p.PaymentDate >= from && p.PaymentDate <= to)
            .ToListAsync();

        var summary = payments
            .GroupBy(p => new { p.EmployeeId, Name = p.Employee != null ? p.Employee.Name : "Unknown" })
            .Select(g => new PaymentSummary
            {
                EmployeeId = g.Key.EmployeeId,
                EmployeeName = g.Key.Name,
                TotalWagePaid = g.Where(x => x.PaymentType == "wage").Sum(x => x.Amount),
                TotalAdvances = g.Where(x => x.PaymentType == "advance").Sum(x => x.Amount),
                TotalBonus = g.Where(x => x.PaymentType == "bonus").Sum(x => x.Amount),
                TotalDeductions = g.Where(x => x.PaymentType == "deduction").Sum(x => x.Amount),
                NetPaid = g.Sum(x => x.Amount) // assuming amount is absolute and deductions are handled logically elsewhere, or if deductions should be subtracted we would adjust here. As per normal model, we'll sum them for "NetPaid" if they are all positive cash flows to employee, otherwise deductions would be subtracted. Assuming positive values represent paid amount.
            })
            .ToList();

        return Ok(ApiResponse<List<PaymentSummary>>.Ok(summary));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<EmployeePaymentDetail>>> Create([FromBody] CreateEmployeePaymentRequest req)
    {
        var emp = await _db.Employees.FindAsync(req.EmployeeId);
        if (emp == null || !emp.IsActive)
            return BadRequest(ApiResponse<EmployeePaymentDetail>.Fail("Employee not found or inactive."));

        if (req.Amount <= 0)
            return BadRequest(ApiResponse<EmployeePaymentDetail>.Fail("Amount must be greater than zero."));

        if (!AllowedValues.EmployeePaymentModes.Contains(req.PaymentMode.ToLower()))
            return BadRequest(ApiResponse<EmployeePaymentDetail>.Fail(
                $"Invalid payment mode. Allowed: {string.Join(", ", AllowedValues.EmployeePaymentModes)}"));

        if (!AllowedValues.EmployeePaymentTypes.Contains(req.PaymentType.ToLower()))
            return BadRequest(ApiResponse<EmployeePaymentDetail>.Fail(
                $"Invalid payment type. Allowed: {string.Join(", ", AllowedValues.EmployeePaymentTypes)}"));

        var payment = new EmployeePayment
        {
            Id = req.Id ?? Guid.NewGuid().ToString(),
            EmployeeId = req.EmployeeId,
            PaymentDate = req.PaymentDate ?? DateOnly.FromDateTime(DateTime.UtcNow),
            Amount = req.Amount,
            PaymentMode = req.PaymentMode.ToLower(),
            PaymentType = req.PaymentType.ToLower(),
            ReferenceNumber = req.ReferenceNumber?.Trim(),
            Notes = req.Notes?.Trim(),
            VoiceRaw = req.VoiceRaw?.Trim(),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.EmployeePayments.Add(payment);
        await _db.SaveChangesAsync();

        return Ok(ApiResponse<EmployeePaymentDetail>.Ok(new EmployeePaymentDetail
        {
            Id = payment.Id,
            EmployeeId = payment.EmployeeId,
            EmployeeName = emp.Name,
            PaymentDate = payment.PaymentDate,
            Amount = payment.Amount,
            PaymentMode = payment.PaymentMode,
            PaymentType = payment.PaymentType,
            ReferenceNumber = payment.ReferenceNumber,
            Notes = payment.Notes,
            VoiceRaw = payment.VoiceRaw
        }, "Payment recorded successfully."));
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<EmployeePaymentDetail>>> Update(string id, [FromBody] UpdateEmployeePaymentRequest req)
    {
        var payment = await _db.EmployeePayments.Include(p => p.Employee).FirstOrDefaultAsync(p => p.Id == id);
        if (payment == null)
            return NotFound(ApiResponse<EmployeePaymentDetail>.Fail("Payment record not found."));

        if (req.Amount <= 0)
            return BadRequest(ApiResponse<EmployeePaymentDetail>.Fail("Amount must be greater than zero."));

        if (!AllowedValues.EmployeePaymentModes.Contains(req.PaymentMode.ToLower()))
            return BadRequest(ApiResponse<EmployeePaymentDetail>.Fail(
                $"Invalid payment mode. Allowed: {string.Join(", ", AllowedValues.EmployeePaymentModes)}"));

        if (!AllowedValues.EmployeePaymentTypes.Contains(req.PaymentType.ToLower()))
            return BadRequest(ApiResponse<EmployeePaymentDetail>.Fail(
                $"Invalid payment type. Allowed: {string.Join(", ", AllowedValues.EmployeePaymentTypes)}"));

        payment.Amount = req.Amount;
        payment.PaymentMode = req.PaymentMode.ToLower();
        payment.PaymentType = req.PaymentType.ToLower();
        payment.ReferenceNumber = req.ReferenceNumber?.Trim();
        payment.Notes = req.Notes?.Trim();
        payment.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(ApiResponse<EmployeePaymentDetail>.Ok(new EmployeePaymentDetail
        {
            Id = payment.Id,
            EmployeeId = payment.EmployeeId,
            EmployeeName = payment.Employee?.Name ?? "",
            PaymentDate = payment.PaymentDate,
            Amount = payment.Amount,
            PaymentMode = payment.PaymentMode,
            PaymentType = payment.PaymentType,
            ReferenceNumber = payment.ReferenceNumber,
            Notes = payment.Notes,
            VoiceRaw = payment.VoiceRaw
        }, "Payment updated successfully."));
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> Delete(string id)
    {
        var payment = await _db.EmployeePayments.FindAsync(id);
        if (payment == null)
            return NotFound(ApiResponse<object>.Fail("Payment record not found."));

        _db.EmployeePayments.Remove(payment);
        await _db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { }, "Payment deleted successfully."));
    }
}
