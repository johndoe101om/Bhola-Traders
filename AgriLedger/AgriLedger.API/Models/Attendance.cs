namespace AgriLedger.API.Models;

public class Attendance
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string EmployeeId { get; set; } = string.Empty;
    public DateOnly AttendanceDate { get; set; }

    /// <summary>present | absent | half_day | overtime | holiday</summary>
    public string Status { get; set; } = string.Empty;

    public TimeOnly? CheckInTime { get; set; }
    public TimeOnly? CheckOutTime { get; set; }
    public string? AbsenceReason { get; set; }
    public string? VoiceRaw { get; set; }
    public decimal? OvertimeHours { get; set; }
    public bool NotificationSent { get; set; } = false;
    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? SyncedAt { get; set; }

    // Navigation
    public Employee? Employee { get; set; }
}
