using System.ComponentModel.DataAnnotations;

namespace AgriLedger.API.DTOs;

// ─────────────────────────────────────────────
// EMPLOYEE DTOs
// ─────────────────────────────────────────────

public class CreateEmployeeRequest
{
    public string? Id { get; set; }

    [Required(ErrorMessage = "Name is required")]
    [StringLength(200, MinimumLength = 1, ErrorMessage = "Name must be between 1 and 200 characters")]
    public required string Name { get; set; }

    [StringLength(15, ErrorMessage = "Phone cannot exceed 15 digits")]
    [RegularExpression(@"^[0-9+\s-]*$", ErrorMessage = "Invalid phone format")]
    public string? Phone { get; set; }

    [EmailAddress(ErrorMessage = "Invalid email address format")]
    [StringLength(100, ErrorMessage = "Email cannot exceed 100 characters")]
    public string? Email { get; set; }

    [Required(ErrorMessage = "DailyWageRate is required")]
    [Range(0, 1000000, ErrorMessage = "DailyWageRate must be between 0 and 1,000,000")]
    public required decimal DailyWageRate { get; set; }

    [StringLength(20, ErrorMessage = "AadhaarNumber cannot exceed 20 characters")]
    public string? AadhaarNumber { get; set; }

    [StringLength(500, ErrorMessage = "Address cannot exceed 500 characters")]
    public string? Address { get; set; }

    public DateOnly? JoiningDate { get; set; }

    [Required(ErrorMessage = "EmployeeType is required")]
    [StringLength(20, ErrorMessage = "EmployeeType cannot exceed 20 characters")]
    public required string EmployeeType { get; set; }

    [StringLength(50, ErrorMessage = "TeamGroup cannot exceed 50 characters")]
    public string? TeamGroup { get; set; }

    [StringLength(100, ErrorMessage = "EmergencyContact cannot exceed 100 characters")]
    public string? EmergencyContact { get; set; }

    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters")]
    public string? Notes { get; set; }
}

public class UpdateEmployeeRequest
{
    [Required(ErrorMessage = "Name is required")]
    [StringLength(200, MinimumLength = 1, ErrorMessage = "Name must be between 1 and 200 characters")]
    public required string Name { get; set; }

    [StringLength(15, ErrorMessage = "Phone cannot exceed 15 digits")]
    [RegularExpression(@"^[0-9+\s-]*$", ErrorMessage = "Invalid phone format")]
    public string? Phone { get; set; }

    [EmailAddress(ErrorMessage = "Invalid email address format")]
    [StringLength(100, ErrorMessage = "Email cannot exceed 100 characters")]
    public string? Email { get; set; }

    [Required(ErrorMessage = "DailyWageRate is required")]
    [Range(0, 1000000, ErrorMessage = "DailyWageRate must be between 0 and 1,000,000")]
    public required decimal DailyWageRate { get; set; }

    [StringLength(20, ErrorMessage = "AadhaarNumber cannot exceed 20 characters")]
    public string? AadhaarNumber { get; set; }

    [StringLength(500, ErrorMessage = "Address cannot exceed 500 characters")]
    public string? Address { get; set; }

    [Required(ErrorMessage = "EmployeeType is required")]
    [StringLength(20, ErrorMessage = "EmployeeType cannot exceed 20 characters")]
    public required string EmployeeType { get; set; }

    [StringLength(50, ErrorMessage = "TeamGroup cannot exceed 50 characters")]
    public string? TeamGroup { get; set; }

    [StringLength(100, ErrorMessage = "EmergencyContact cannot exceed 100 characters")]
    public string? EmergencyContact { get; set; }

    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters")]
    public string? Notes { get; set; }
}

public class EmployeeListItem
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public decimal DailyWageRate { get; set; }
    public string EmployeeType { get; set; } = "";
    public string? TeamGroup { get; set; }
    public DateOnly JoiningDate { get; set; }
    public decimal DaysPresent { get; set; }
    public decimal TotalPaid { get; set; }
    public decimal Balance { get; set; }
}

public class EmployeeDetail
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public decimal DailyWageRate { get; set; }
    public string? AadhaarNumber { get; set; }
    public string? Address { get; set; }
    public DateOnly JoiningDate { get; set; }
    public string EmployeeType { get; set; } = "";
    public string? TeamGroup { get; set; }
    public bool IsActive { get; set; }
    public string? EmergencyContact { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class EmployeeLedgerResponse
{
    public EmployeeDetail Employee { get; set; } = new();
    public WageSummary WageSummary { get; set; } = new();
    public List<EmployeePaymentDetail> Payments { get; set; } = new();
    public List<AttendanceDetail> Attendances { get; set; } = new();
}

public class WageSummary
{
    public decimal TotalDaysPresent { get; set; }
    public decimal TotalHalfDays { get; set; }
    public decimal TotalOvertimeHours { get; set; }
    public decimal GrossEarned { get; set; }
    public decimal TotalPaid { get; set; }
    public decimal TotalAdvances { get; set; }
    public decimal BalanceDue { get; set; }
}

// ─────────────────────────────────────────────
// ATTENDANCE DTOs
// ─────────────────────────────────────────────

public class CreateAttendanceRequest
{
    public string? Id { get; set; }

    [Required(ErrorMessage = "EmployeeId is required")]
    [StringLength(36, ErrorMessage = "EmployeeId must be a valid identifier")]
    public required string EmployeeId { get; set; }

    public DateOnly? AttendanceDate { get; set; }

    [Required(ErrorMessage = "Status is required")]
    [StringLength(20, ErrorMessage = "Status cannot exceed 20 characters")]
    public required string Status { get; set; }

    public TimeOnly? CheckInTime { get; set; }
    public TimeOnly? CheckOutTime { get; set; }

    [StringLength(1000, ErrorMessage = "AbsenceReason cannot exceed 1000 characters")]
    public string? AbsenceReason { get; set; }

    [StringLength(1000, ErrorMessage = "VoiceRaw cannot exceed 1000 characters")]
    public string? VoiceRaw { get; set; }

    [Range(0, 24, ErrorMessage = "OvertimeHours must be between 0 and 24")]
    public decimal? OvertimeHours { get; set; }

    [StringLength(500, ErrorMessage = "Notes cannot exceed 500 characters")]
    public string? Notes { get; set; }
}

public class BulkAttendanceItem
{
    [Required(ErrorMessage = "EmployeeId is required")]
    [StringLength(36)]
    public required string EmployeeId { get; set; }

    [Required(ErrorMessage = "Status is required")]
    [StringLength(20)]
    public required string Status { get; set; }

    [StringLength(1000)]
    public string? AbsenceReason { get; set; }

    [StringLength(1000)]
    public string? VoiceRaw { get; set; }
}

public class BulkAttendanceRequest
{
    [Required(ErrorMessage = "Date is required")]
    public required DateOnly Date { get; set; }

    public List<BulkAttendanceItem> Items { get; set; } = new();
}

public class UpdateAttendanceRequest
{
    [Required(ErrorMessage = "Status is required")]
    [StringLength(20)]
    public required string Status { get; set; }

    public TimeOnly? CheckInTime { get; set; }
    public TimeOnly? CheckOutTime { get; set; }

    [StringLength(1000)]
    public string? AbsenceReason { get; set; }

    [StringLength(1000)]
    public string? VoiceRaw { get; set; }

    [Range(0, 24)]
    public decimal? OvertimeHours { get; set; }

    [StringLength(500)]
    public string? Notes { get; set; }
}

public class AttendanceDetail
{
    public string Id { get; set; } = "";
    public string EmployeeId { get; set; } = "";
    public string EmployeeName { get; set; } = "";
    public DateOnly AttendanceDate { get; set; }
    public string Status { get; set; } = "";
    public TimeOnly? CheckInTime { get; set; }
    public TimeOnly? CheckOutTime { get; set; }
    public string? AbsenceReason { get; set; }
    public string? VoiceRaw { get; set; }
    public decimal? OvertimeHours { get; set; }
    public bool NotificationSent { get; set; }
    public string? Notes { get; set; }
}

public class AttendanceSummary
{
    public string EmployeeId { get; set; } = "";
    public string EmployeeName { get; set; } = "";
    public decimal DaysPresent { get; set; }
    public decimal DaysAbsent { get; set; }
    public decimal HalfDays { get; set; }
    public decimal OvertimeDays { get; set; }
    public decimal TotalWorkDays { get; set; }
}

public class TodayAttendanceDashboard
{
    public DateOnly Date { get; set; }
    public int TotalEmployees { get; set; }
    public int PresentCount { get; set; }
    public int AbsentCount { get; set; }
    public int HalfDayCount { get; set; }
    public int NotMarkedCount { get; set; }
    public decimal TotalWagesToday { get; set; }
}

// ─────────────────────────────────────────────
// PAYMENT DTOs
// ─────────────────────────────────────────────

public class CreateEmployeePaymentRequest
{
    public string? Id { get; set; }

    [Required(ErrorMessage = "EmployeeId is required")]
    [StringLength(36)]
    public required string EmployeeId { get; set; }

    public DateOnly? PaymentDate { get; set; }

    [Required(ErrorMessage = "Amount is required")]
    [Range(0.01, 100000000, ErrorMessage = "Amount must be greater than 0")]
    public required decimal Amount { get; set; }

    [Required(ErrorMessage = "PaymentMode is required")]
    [StringLength(20)]
    public required string PaymentMode { get; set; }

    [Required(ErrorMessage = "PaymentType is required")]
    [StringLength(20)]
    public required string PaymentType { get; set; }

    [StringLength(100)]
    public string? ReferenceNumber { get; set; }

    [StringLength(500)]
    public string? Notes { get; set; }

    [StringLength(1000)]
    public string? VoiceRaw { get; set; }
}

public class UpdateEmployeePaymentRequest
{
    [Required(ErrorMessage = "Amount is required")]
    [Range(0.01, 100000000, ErrorMessage = "Amount must be greater than 0")]
    public required decimal Amount { get; set; }

    [Required(ErrorMessage = "PaymentMode is required")]
    [StringLength(20)]
    public required string PaymentMode { get; set; }

    [Required(ErrorMessage = "PaymentType is required")]
    [StringLength(20)]
    public required string PaymentType { get; set; }

    [StringLength(100)]
    public string? ReferenceNumber { get; set; }

    [StringLength(500)]
    public string? Notes { get; set; }
}

public class EmployeePaymentDetail
{
    public string Id { get; set; } = "";
    public string EmployeeId { get; set; } = "";
    public string EmployeeName { get; set; } = "";
    public DateOnly PaymentDate { get; set; }
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = "";
    public string PaymentType { get; set; } = "";
    public string? ReferenceNumber { get; set; }
    public string? Notes { get; set; }
    public string? VoiceRaw { get; set; }
}

public class PaymentSummary
{
    public string EmployeeId { get; set; } = "";
    public string EmployeeName { get; set; } = "";
    public decimal TotalWagePaid { get; set; }
    public decimal TotalAdvances { get; set; }
    public decimal TotalBonus { get; set; }
    public decimal TotalDeductions { get; set; }
    public decimal NetPaid { get; set; }
}

// ─────────────────────────────────────────────
// NOTIFICATION DTOs
// ─────────────────────────────────────────────

public class SendAbsenceNotificationRequest
{
    [Required(ErrorMessage = "AttendanceId is required")]
    [StringLength(36)]
    public required string AttendanceId { get; set; }
}

public class NotificationResult
{
    public bool Success { get; set; }
    public string Channel { get; set; } = "";
    public string Message { get; set; } = "";
}
