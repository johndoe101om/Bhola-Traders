using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using AgriLedger.API.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AgriLedger.API.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[Produces("application/json")]
public class AttendanceController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly INotificationService _notifications;

    public AttendanceController(AppDbContext db, INotificationService notifications)
    {
        _db = db;
        _notifications = notifications;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResponse<AttendanceDetail>>>> GetAll(
        [FromQuery] string? employeeId,
        [FromQuery] DateOnly? date,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = _db.Attendances.Include(a => a.Employee).AsQueryable();

        if (!string.IsNullOrEmpty(employeeId))
            query = query.Where(a => a.EmployeeId == employeeId);

        if (date.HasValue)
            query = query.Where(a => a.AttendanceDate == date.Value);

        if (from.HasValue)
            query = query.Where(a => a.AttendanceDate >= from.Value);

        if (to.HasValue)
            query = query.Where(a => a.AttendanceDate <= to.Value);

        if (!string.IsNullOrEmpty(status))
            query = query.Where(a => a.Status == status.ToLower());

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(a => a.AttendanceDate)
            .ThenByDescending(a => a.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(a => new AttendanceDetail
            {
                Id = a.Id,
                EmployeeId = a.EmployeeId,
                EmployeeName = a.Employee != null ? a.Employee.Name : "",
                AttendanceDate = a.AttendanceDate,
                Status = a.Status,
                CheckInTime = a.CheckInTime,
                CheckOutTime = a.CheckOutTime,
                AbsenceReason = a.AbsenceReason,
                VoiceRaw = a.VoiceRaw,
                OvertimeHours = a.OvertimeHours,
                NotificationSent = a.NotificationSent,
                Notes = a.Notes
            })
            .ToListAsync();

        return Ok(ApiResponse<PagedResponse<AttendanceDetail>>.Ok(new PagedResponse<AttendanceDetail>
        {
            Items = items,
            TotalCount = total,
            Page = page,
            PageSize = pageSize
        }));
    }

    [HttpGet("today")]
    public async Task<ActionResult<ApiResponse<TodayAttendanceDashboard>>> GetTodayDashboard()
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var activeEmployees = await _db.Employees.Where(e => e.IsActive).ToListAsync();
        var totalEmployees = activeEmployees.Count;

        var todayAttendances = await _db.Attendances
            .Where(a => a.AttendanceDate == today)
            .ToListAsync();

        var presentCount = todayAttendances.Count(a => a.Status == "present");
        var absentCount = todayAttendances.Count(a => a.Status == "absent");
        var halfDayCount = todayAttendances.Count(a => a.Status == "half_day");
        var notMarkedCount = totalEmployees - todayAttendances.Count;

        decimal totalWagesToday = 0;
        foreach (var att in todayAttendances)
        {
            var emp = activeEmployees.FirstOrDefault(e => e.Id == att.EmployeeId);
            if (emp != null)
            {
                if (att.Status == "present") totalWagesToday += emp.DailyWageRate;
                else if (att.Status == "half_day") totalWagesToday += emp.DailyWageRate * 0.5m;

                if (att.OvertimeHours.HasValue && att.OvertimeHours.Value > 0)
                {
                    totalWagesToday += emp.DailyWageRate * (att.OvertimeHours.Value / 8m);
                }
            }
        }

        return Ok(ApiResponse<TodayAttendanceDashboard>.Ok(new TodayAttendanceDashboard
        {
            Date = today,
            TotalEmployees = totalEmployees,
            PresentCount = presentCount,
            AbsentCount = absentCount,
            HalfDayCount = halfDayCount,
            NotMarkedCount = notMarkedCount,
            TotalWagesToday = totalWagesToday
        }));
    }

    [HttpGet("summary")]
    public async Task<ActionResult<ApiResponse<List<AttendanceSummary>>>> GetSummary(
        [FromQuery] DateOnly from,
        [FromQuery] DateOnly to)
    {
        var attendances = await _db.Attendances
            .Include(a => a.Employee)
            .Where(a => a.AttendanceDate >= from && a.AttendanceDate <= to)
            .ToListAsync();

        var summary = attendances
            .GroupBy(a => new { a.EmployeeId, Name = a.Employee != null ? a.Employee.Name : "Unknown" })
            .Select(g =>
            {
                var present = g.Count(x => x.Status == "present");
                var absent = g.Count(x => x.Status == "absent");
                var half = g.Count(x => x.Status == "half_day");
                var overtime = g.Sum(x => (x.OvertimeHours ?? 0m) / 8m);
                return new AttendanceSummary
                {
                    EmployeeId = g.Key.EmployeeId,
                    EmployeeName = g.Key.Name,
                    DaysPresent = present,
                    DaysAbsent = absent,
                    HalfDays = half,
                    OvertimeDays = overtime,
                    TotalWorkDays = present + (half * 0.5m) + overtime
                };
            })
            .ToList();

        return Ok(ApiResponse<List<AttendanceSummary>>.Ok(summary));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<AttendanceDetail>>> Create([FromBody] CreateAttendanceRequest req)
    {
        var emp = await _db.Employees.FindAsync(req.EmployeeId);
        if (emp == null || !emp.IsActive)
            return BadRequest(ApiResponse<AttendanceDetail>.Fail("Employee not found or inactive."));

        if (!AllowedValues.AttendanceStatuses.Contains(req.Status.ToLower()))
            return BadRequest(ApiResponse<AttendanceDetail>.Fail(
                $"Invalid status. Allowed: {string.Join(", ", AllowedValues.AttendanceStatuses)}"));

        var date = req.AttendanceDate ?? DateOnly.FromDateTime(DateTime.UtcNow);

        var existing = await _db.Attendances
            .FirstOrDefaultAsync(a => a.EmployeeId == req.EmployeeId && a.AttendanceDate == date);
        if (existing != null)
            return Conflict(ApiResponse<AttendanceDetail>.Fail($"Attendance already marked for {date}."));

        var attendance = new Attendance
        {
            Id = req.Id ?? Guid.NewGuid().ToString(),
            EmployeeId = req.EmployeeId,
            AttendanceDate = date,
            Status = req.Status.ToLower(),
            CheckInTime = req.CheckInTime,
            CheckOutTime = req.CheckOutTime,
            AbsenceReason = req.AbsenceReason?.Trim(),
            VoiceRaw = req.VoiceRaw?.Trim(),
            OvertimeHours = req.OvertimeHours,
            Notes = req.Notes?.Trim(),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        if (attendance.Status == "absent")
        {
            var sent = await _notifications.SendAbsenceNotificationAsync(emp, attendance);
            attendance.NotificationSent = sent;
        }

        _db.Attendances.Add(attendance);
        await _db.SaveChangesAsync();

        return Ok(ApiResponse<AttendanceDetail>.Ok(new AttendanceDetail
        {
            Id = attendance.Id,
            EmployeeId = attendance.EmployeeId,
            EmployeeName = emp.Name,
            AttendanceDate = attendance.AttendanceDate,
            Status = attendance.Status,
            CheckInTime = attendance.CheckInTime,
            CheckOutTime = attendance.CheckOutTime,
            AbsenceReason = attendance.AbsenceReason,
            VoiceRaw = attendance.VoiceRaw,
            OvertimeHours = attendance.OvertimeHours,
            NotificationSent = attendance.NotificationSent,
            Notes = attendance.Notes
        }, "Attendance marked successfully."));
    }

    [HttpPost("bulk")]
    public async Task<ActionResult<ApiResponse<object>>> CreateBulk([FromBody] BulkAttendanceRequest req)
    {
        var results = new List<string>();
        int added = 0;

        foreach (var item in req.Items)
        {
            var emp = await _db.Employees.FindAsync(item.EmployeeId);
            if (emp == null || !emp.IsActive)
            {
                results.Add($"Employee {item.EmployeeId} not found or inactive.");
                continue;
            }

            if (!AllowedValues.AttendanceStatuses.Contains(item.Status.ToLower()))
            {
                results.Add($"Invalid status '{item.Status}' for {item.EmployeeId}.");
                continue;
            }

            var existing = await _db.Attendances
                .FirstOrDefaultAsync(a => a.EmployeeId == item.EmployeeId && a.AttendanceDate == req.Date);
            if (existing != null)
            {
                results.Add($"Attendance already marked for {emp.Name} on {req.Date}.");
                continue;
            }

            var attendance = new Attendance
            {
                Id = Guid.NewGuid().ToString(),
                EmployeeId = item.EmployeeId,
                AttendanceDate = req.Date,
                Status = item.Status.ToLower(),
                AbsenceReason = item.AbsenceReason?.Trim(),
                VoiceRaw = item.VoiceRaw?.Trim(),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            if (attendance.Status == "absent")
            {
                var sent = await _notifications.SendAbsenceNotificationAsync(emp, attendance);
                attendance.NotificationSent = sent;
            }

            _db.Attendances.Add(attendance);
            added++;
        }

        await _db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { added, warnings = results }, $"Successfully added {added} records."));
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<AttendanceDetail>>> Update(string id, [FromBody] UpdateAttendanceRequest req)
    {
        var attendance = await _db.Attendances.Include(a => a.Employee).FirstOrDefaultAsync(a => a.Id == id);
        if (attendance == null)
            return NotFound(ApiResponse<AttendanceDetail>.Fail("Attendance record not found."));

        if (!AllowedValues.AttendanceStatuses.Contains(req.Status.ToLower()))
            return BadRequest(ApiResponse<AttendanceDetail>.Fail(
                $"Invalid status. Allowed: {string.Join(", ", AllowedValues.AttendanceStatuses)}"));

        attendance.Status = req.Status.ToLower();
        attendance.CheckInTime = req.CheckInTime;
        attendance.CheckOutTime = req.CheckOutTime;
        attendance.AbsenceReason = req.AbsenceReason?.Trim();
        attendance.VoiceRaw = req.VoiceRaw?.Trim();
        attendance.OvertimeHours = req.OvertimeHours;
        attendance.Notes = req.Notes?.Trim();
        attendance.UpdatedAt = DateTime.UtcNow;

        if (attendance.Status == "absent" && !attendance.NotificationSent && attendance.Employee != null)
        {
            var sent = await _notifications.SendAbsenceNotificationAsync(attendance.Employee, attendance);
            attendance.NotificationSent = sent;
        }

        await _db.SaveChangesAsync();

        return Ok(ApiResponse<AttendanceDetail>.Ok(new AttendanceDetail
        {
            Id = attendance.Id,
            EmployeeId = attendance.EmployeeId,
            EmployeeName = attendance.Employee?.Name ?? "",
            AttendanceDate = attendance.AttendanceDate,
            Status = attendance.Status,
            CheckInTime = attendance.CheckInTime,
            CheckOutTime = attendance.CheckOutTime,
            AbsenceReason = attendance.AbsenceReason,
            VoiceRaw = attendance.VoiceRaw,
            OvertimeHours = attendance.OvertimeHours,
            NotificationSent = attendance.NotificationSent,
            Notes = attendance.Notes
        }, "Attendance updated successfully."));
    }

    [HttpPost("{id}/notify")]
    public async Task<ActionResult<ApiResponse<object>>> SendNotification(string id)
    {
        var attendance = await _db.Attendances.Include(a => a.Employee).FirstOrDefaultAsync(a => a.Id == id);
        if (attendance == null)
            return NotFound(ApiResponse<object>.Fail("Attendance record not found."));

        if (attendance.Employee == null)
            return BadRequest(ApiResponse<object>.Fail("Associated employee record not found."));

        var sent = await _notifications.SendAbsenceNotificationAsync(attendance.Employee, attendance);
        attendance.NotificationSent = sent;
        await _db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(
            new { notificationSent = sent },
            sent ? "Notification sent successfully." : "Notification could not be dispatched (check SMS/Email settings)."));
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> Delete(string id)
    {
        var attendance = await _db.Attendances.FindAsync(id);
        if (attendance == null)
            return NotFound(ApiResponse<object>.Fail("Attendance record not found."));

        _db.Attendances.Remove(attendance);
        await _db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { }, "Attendance record deleted."));
    }
}
