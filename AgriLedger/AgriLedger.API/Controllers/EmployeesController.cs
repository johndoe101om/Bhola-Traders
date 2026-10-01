using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AgriLedger.API.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[Produces("application/json")]
public class EmployeesController : ControllerBase
{
    private readonly AppDbContext _db;

    public EmployeesController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<EmployeeListItem>>>> GetAll(
        [FromQuery] string? type,
        [FromQuery] string? team,
        [FromQuery] string? q,
        [FromQuery] bool? isActive)
    {
        var query = _db.Employees.AsQueryable();

        if (isActive.HasValue)
            query = query.Where(e => e.IsActive == isActive.Value);

        if (!string.IsNullOrWhiteSpace(type))
            query = query.Where(e => e.EmployeeType == type.ToLower());

        if (!string.IsNullOrWhiteSpace(team))
            query = query.Where(e => e.TeamGroup != null && EF.Functions.Like(e.TeamGroup, $"%{team}%"));

        if (!string.IsNullOrWhiteSpace(q))
            query = query.Where(e =>
                EF.Functions.Like(e.Name, $"%{q}%") ||
                (e.Phone != null && e.Phone.Contains(q)) ||
                (e.TeamGroup != null && EF.Functions.Like(e.TeamGroup, $"%{q}%")));

        var employees = await query
            .Include(e => e.Attendances)
            .Include(e => e.EmployeePayments)
            .OrderBy(e => e.Name)
            .ToListAsync();

        var list = employees.Select(e =>
        {
            var presentDays = e.Attendances.Count(a => a.Status == "present");
            var halfDays = e.Attendances.Count(a => a.Status == "half_day") * 0.5m;
            var overtimeDays = e.Attendances.Sum(a => (a.OvertimeHours ?? 0m) / 8m); // assuming 8hr day
            var totalDaysPresent = presentDays + halfDays + overtimeDays;

            var grossEarned = totalDaysPresent * e.DailyWageRate;
            var totalPaid = e.EmployeePayments.Sum(p => p.Amount);

            return new EmployeeListItem
            {
                Id = e.Id,
                Name = e.Name,
                Phone = e.Phone,
                Email = e.Email,
                DailyWageRate = e.DailyWageRate,
                EmployeeType = e.EmployeeType,
                TeamGroup = e.TeamGroup,
                JoiningDate = e.JoiningDate,
                DaysPresent = totalDaysPresent,
                TotalPaid = totalPaid,
                Balance = grossEarned - totalPaid
            };
        }).ToList();

        return Ok(ApiResponse<List<EmployeeListItem>>.Ok(list));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<EmployeeDetail>>> GetById(string id)
    {
        var emp = await _db.Employees.FindAsync(id);
        if (emp == null)
            return NotFound(ApiResponse<EmployeeDetail>.Fail("Employee not found."));

        return Ok(ApiResponse<EmployeeDetail>.Ok(new EmployeeDetail
        {
            Id = emp.Id,
            Name = emp.Name,
            Phone = emp.Phone,
            Email = emp.Email,
            DailyWageRate = emp.DailyWageRate,
            AadhaarNumber = emp.AadhaarNumber,
            Address = emp.Address,
            JoiningDate = emp.JoiningDate,
            EmployeeType = emp.EmployeeType,
            TeamGroup = emp.TeamGroup,
            IsActive = emp.IsActive,
            EmergencyContact = emp.EmergencyContact,
            Notes = emp.Notes,
            CreatedAt = emp.CreatedAt
        }));
    }

    [HttpGet("{id}/ledger")]
    public async Task<ActionResult<ApiResponse<EmployeeLedgerResponse>>> GetLedger(
        string id,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to)
    {
        var emp = await _db.Employees.FindAsync(id);
        if (emp == null)
            return NotFound(ApiResponse<EmployeeLedgerResponse>.Fail("Employee not found."));

        var attQuery = _db.Attendances.Where(a => a.EmployeeId == id);
        if (from.HasValue) attQuery = attQuery.Where(a => a.AttendanceDate >= from.Value);
        if (to.HasValue) attQuery = attQuery.Where(a => a.AttendanceDate <= to.Value);
        var attendances = await attQuery.OrderByDescending(a => a.AttendanceDate).ToListAsync();

        var payQuery = _db.EmployeePayments.Where(p => p.EmployeeId == id);
        if (from.HasValue) payQuery = payQuery.Where(p => p.PaymentDate >= from.Value);
        if (to.HasValue) payQuery = payQuery.Where(p => p.PaymentDate <= to.Value);
        var payments = await payQuery.OrderByDescending(p => p.PaymentDate).ToListAsync();

        var presentDays = attendances.Count(a => a.Status == "present");
        var halfDays = attendances.Count(a => a.Status == "half_day");
        var overtimeHours = attendances.Sum(a => a.OvertimeHours ?? 0m);
        var totalDaysPresent = presentDays + (halfDays * 0.5m) + (overtimeHours / 8m);
        var grossEarned = totalDaysPresent * emp.DailyWageRate;

        var totalAdvances = payments.Where(p => p.PaymentType == "advance").Sum(p => p.Amount);
        var totalPaid = payments.Sum(p => p.Amount);

        return Ok(ApiResponse<EmployeeLedgerResponse>.Ok(new EmployeeLedgerResponse
        {
            Employee = new EmployeeDetail
            {
                Id = emp.Id,
                Name = emp.Name,
                Phone = emp.Phone,
                Email = emp.Email,
                DailyWageRate = emp.DailyWageRate,
                AadhaarNumber = emp.AadhaarNumber,
                Address = emp.Address,
                JoiningDate = emp.JoiningDate,
                EmployeeType = emp.EmployeeType,
                TeamGroup = emp.TeamGroup,
                IsActive = emp.IsActive,
                EmergencyContact = emp.EmergencyContact,
                Notes = emp.Notes,
                CreatedAt = emp.CreatedAt
            },
            WageSummary = new WageSummary
            {
                TotalDaysPresent = totalDaysPresent,
                TotalHalfDays = halfDays,
                TotalOvertimeHours = overtimeHours,
                GrossEarned = grossEarned,
                TotalPaid = totalPaid,
                TotalAdvances = totalAdvances,
                BalanceDue = grossEarned - totalPaid
            },
            Payments = payments.Select(p => new EmployeePaymentDetail
            {
                Id = p.Id,
                EmployeeId = p.EmployeeId,
                EmployeeName = emp.Name,
                PaymentDate = p.PaymentDate,
                Amount = p.Amount,
                PaymentMode = p.PaymentMode,
                PaymentType = p.PaymentType,
                ReferenceNumber = p.ReferenceNumber,
                Notes = p.Notes,
                VoiceRaw = p.VoiceRaw
            }).ToList(),
            Attendances = attendances.Select(a => new AttendanceDetail
            {
                Id = a.Id,
                EmployeeId = a.EmployeeId,
                EmployeeName = emp.Name,
                AttendanceDate = a.AttendanceDate,
                Status = a.Status,
                CheckInTime = a.CheckInTime,
                CheckOutTime = a.CheckOutTime,
                AbsenceReason = a.AbsenceReason,
                VoiceRaw = a.VoiceRaw,
                OvertimeHours = a.OvertimeHours,
                NotificationSent = a.NotificationSent,
                Notes = a.Notes
            }).ToList()
        }));
    }

    [HttpGet("{id}/attendance-summary")]
    public async Task<ActionResult<ApiResponse<AttendanceSummary>>> GetAttendanceSummary(
        string id,
        [FromQuery] int? month,
        [FromQuery] int? year)
    {
        var emp = await _db.Employees.FindAsync(id);
        if (emp == null)
            return NotFound(ApiResponse<AttendanceSummary>.Fail("Employee not found."));

        var m = month ?? DateTime.UtcNow.Month;
        var y = year ?? DateTime.UtcNow.Year;

        var start = new DateOnly(y, m, 1);
        var end = start.AddMonths(1).AddDays(-1);

        var attendances = await _db.Attendances
            .Where(a => a.EmployeeId == id && a.AttendanceDate >= start && a.AttendanceDate <= end)
            .ToListAsync();

        var presentCount = attendances.Count(a => a.Status == "present");
        var absentCount = attendances.Count(a => a.Status == "absent");
        var halfDayCount = attendances.Count(a => a.Status == "half_day");
        var overtimeDays = attendances.Sum(a => (a.OvertimeHours ?? 0m) / 8m);

        return Ok(ApiResponse<AttendanceSummary>.Ok(new AttendanceSummary
        {
            EmployeeId = emp.Id,
            EmployeeName = emp.Name,
            DaysPresent = presentCount,
            DaysAbsent = absentCount,
            HalfDays = halfDayCount,
            OvertimeDays = overtimeDays,
            TotalWorkDays = presentCount + (halfDayCount * 0.5m) + overtimeDays
        }));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<EmployeeDetail>>> Create([FromBody] CreateEmployeeRequest req)
    {
        if (!AllowedValues.EmployeeTypes.Contains(req.EmployeeType.ToLower()))
            return BadRequest(ApiResponse<EmployeeDetail>.Fail(
                $"Invalid employee_type. Allowed: {string.Join(", ", AllowedValues.EmployeeTypes)}"));

        var duplicate = await _db.Employees
            .AnyAsync(e => e.Name == req.Name && e.Phone == req.Phone && e.IsActive);
        if (duplicate)
            return Conflict(ApiResponse<EmployeeDetail>.Fail(
                $"Employee '{req.Name}' with phone '{req.Phone}' already exists."));

        var emp = new Employee
        {
            Id = req.Id ?? Guid.NewGuid().ToString(),
            Name = req.Name.Trim(),
            Phone = req.Phone?.Trim(),
            Email = req.Email?.Trim(),
            DailyWageRate = req.DailyWageRate,
            AadhaarNumber = req.AadhaarNumber?.Trim(),
            Address = req.Address?.Trim(),
            JoiningDate = req.JoiningDate ?? DateOnly.FromDateTime(DateTime.UtcNow),
            EmployeeType = req.EmployeeType.ToLower(),
            TeamGroup = req.TeamGroup?.Trim(),
            IsActive = true,
            EmergencyContact = req.EmergencyContact?.Trim(),
            Notes = req.Notes?.Trim(),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Employees.Add(emp);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = emp.Id },
            ApiResponse<EmployeeDetail>.Ok(new EmployeeDetail
            {
                Id = emp.Id,
                Name = emp.Name,
                Phone = emp.Phone,
                Email = emp.Email,
                DailyWageRate = emp.DailyWageRate,
                AadhaarNumber = emp.AadhaarNumber,
                Address = emp.Address,
                JoiningDate = emp.JoiningDate,
                EmployeeType = emp.EmployeeType,
                TeamGroup = emp.TeamGroup,
                IsActive = emp.IsActive,
                EmergencyContact = emp.EmergencyContact,
                Notes = emp.Notes,
                CreatedAt = emp.CreatedAt
            }, "Employee created successfully."));
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<EmployeeDetail>>> Update(string id, [FromBody] UpdateEmployeeRequest req)
    {
        var emp = await _db.Employees.FindAsync(id);
        if (emp == null || !emp.IsActive)
            return NotFound(ApiResponse<EmployeeDetail>.Fail("Employee not found."));

        if (!AllowedValues.EmployeeTypes.Contains(req.EmployeeType.ToLower()))
            return BadRequest(ApiResponse<EmployeeDetail>.Fail(
                $"Invalid employee_type. Allowed: {string.Join(", ", AllowedValues.EmployeeTypes)}"));

        emp.Name = req.Name.Trim();
        emp.Phone = req.Phone?.Trim();
        emp.Email = req.Email?.Trim();
        emp.DailyWageRate = req.DailyWageRate;
        emp.AadhaarNumber = req.AadhaarNumber?.Trim();
        emp.Address = req.Address?.Trim();
        emp.EmployeeType = req.EmployeeType.ToLower();
        emp.TeamGroup = req.TeamGroup?.Trim();
        emp.EmergencyContact = req.EmergencyContact?.Trim();
        emp.Notes = req.Notes?.Trim();
        emp.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return Ok(ApiResponse<EmployeeDetail>.Ok(new EmployeeDetail
        {
            Id = emp.Id,
            Name = emp.Name,
            Phone = emp.Phone,
            Email = emp.Email,
            DailyWageRate = emp.DailyWageRate,
            AadhaarNumber = emp.AadhaarNumber,
            Address = emp.Address,
            JoiningDate = emp.JoiningDate,
            EmployeeType = emp.EmployeeType,
            TeamGroup = emp.TeamGroup,
            IsActive = emp.IsActive,
            EmergencyContact = emp.EmergencyContact,
            Notes = emp.Notes,
            CreatedAt = emp.CreatedAt
        }, "Employee updated."));
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> Delete(string id)
    {
        var emp = await _db.Employees.FindAsync(id);
        if (emp == null || !emp.IsActive)
            return NotFound(ApiResponse<object>.Fail("Employee not found."));

        emp.IsActive = false;
        emp.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { }, "Employee deleted."));
    }
}
