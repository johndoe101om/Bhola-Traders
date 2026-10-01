using AgriLedger.API.Models;

namespace AgriLedger.API.Services;

/// <summary>
/// Service interface for dispatching notifications (SMS and Email) to employees.
/// </summary>
public interface INotificationService
{
    /// <summary>
    /// Sends an absence notification to the employee via SMS and/or Email.
    /// </summary>
    /// <param name="employee">The employee who is absent.</param>
    /// <param name="attendance">The attendance record containing date and reason.</param>
    /// <returns>True if at least one notification was successfully dispatched, false otherwise.</returns>
    Task<bool> SendAbsenceNotificationAsync(Employee employee, Attendance attendance);

    /// <summary>
    /// Sends a transactional SMS to a destination phone number.
    /// </summary>
    /// <param name="toPhone">Destination phone number.</param>
    /// <param name="message">The SMS message content.</param>
    /// <returns>True if sent successfully, false otherwise.</returns>
    Task<bool> SendSmsAsync(string toPhone, string message);

    /// <summary>
    /// Sends an email notification.
    /// </summary>
    /// <param name="toEmail">Recipient email address.</param>
    /// <param name="subject">Email subject.</param>
    /// <param name="htmlBody">HTML or plain text body.</param>
    /// <returns>True if sent successfully, false otherwise.</returns>
    Task<bool> SendEmailAsync(string toEmail, string subject, string htmlBody);
}
