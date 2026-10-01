namespace AgriLedger.API.Models;

public class Employee
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public decimal DailyWageRate { get; set; }
    public string? AadhaarNumber { get; set; }
    public string? Address { get; set; }
    public DateOnly JoiningDate { get; set; }

    /// <summary>labour | driver | supervisor | other</summary>
    public string EmployeeType { get; set; } = string.Empty;
    public string? TeamGroup { get; set; }
    public bool IsActive { get; set; } = true;
    public string? EmergencyContact { get; set; }
    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? SyncedAt { get; set; }

    // Navigation
    public ICollection<Attendance> Attendances { get; set; } = new List<Attendance>();
    public ICollection<EmployeePayment> EmployeePayments { get; set; } = new List<EmployeePayment>();
}
