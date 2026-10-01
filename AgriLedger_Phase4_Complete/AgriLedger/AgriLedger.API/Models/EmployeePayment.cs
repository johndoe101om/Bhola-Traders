namespace AgriLedger.API.Models;

public class EmployeePayment
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string EmployeeId { get; set; } = string.Empty;
    public DateOnly PaymentDate { get; set; }
    public decimal Amount { get; set; }

    /// <summary>cash | upi | bank_transfer</summary>
    public string PaymentMode { get; set; } = string.Empty;

    /// <summary>wage | advance | bonus | deduction | settlement</summary>
    public string PaymentType { get; set; } = string.Empty;

    public string? ReferenceNumber { get; set; }
    public string? Notes { get; set; }
    public string? VoiceRaw { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? SyncedAt { get; set; }

    // Navigation
    public Employee? Employee { get; set; }
}
