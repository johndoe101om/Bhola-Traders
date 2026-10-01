using System.Net;
using System.Net.Mail;
using System.Text.RegularExpressions;
using AgriLedger.API.Models;

namespace AgriLedger.API.Services;

/// <summary>
/// Service implementing employee notification delivery via SMTP Email and SMS.
/// </summary>
public partial class NotificationService : INotificationService
{
    private readonly IConfiguration _config;
    private readonly ILogger<NotificationService> _logger;
    private readonly HttpClient _httpClient;

    public NotificationService(
        IConfiguration config,
        ILogger<NotificationService> logger,
        HttpClient httpClient)
    {
        _config = config;
        _logger = logger;
        _httpClient = httpClient;
    }

    /// <inheritdoc/>
    public async Task<bool> SendAbsenceNotificationAsync(Employee employee, Attendance attendance)
    {
        if (employee == null) return false;

        var dateStr = attendance.AttendanceDate.ToString("dd/MM/yyyy");
        var reason = string.IsNullOrWhiteSpace(attendance.AbsenceReason)
            ? "विवरण उपलब्ध नहीं / Not specified"
            : attendance.AbsenceReason;

        var smsText = $"नमस्ते {employee.Name}, आप {dateStr} को अनुपस्थित दर्ज हुए हैं। कारण: {reason}। - भोला ट्रेडर्स";
        var emailSubject = $"अनुपस्थिति सूचना / Absence Notification ({dateStr}) - Bhola Traders";
        var emailBody = BuildAbsenceEmailHtml(employee.Name, dateStr, reason);

        bool smsSent = false;
        bool emailSent = false;

        if (!string.IsNullOrWhiteSpace(employee.Phone))
        {
            smsSent = await SendSmsAsync(employee.Phone, smsText);
        }

        if (!string.IsNullOrWhiteSpace(employee.Email))
        {
            emailSent = await SendEmailAsync(employee.Email, emailSubject, emailBody);
        }

        return smsSent || emailSent;
    }

    /// <inheritdoc/>
    public async Task<bool> SendSmsAsync(string toPhone, string message)
    {
        var cleanPhone = CleanPhoneNumber(toPhone);
        if (string.IsNullOrWhiteSpace(cleanPhone))
        {
            _logger.LogWarning("Cannot send SMS: invalid phone number provided.");
            return false;
        }

        var isEnabled = _config.GetValue<bool>("Notifications:Sms:Enabled");
        if (!isEnabled)
        {
            _logger.LogInformation("SMS disabled in settings. Simulated SMS to {Phone}: {Message}", cleanPhone, message);
            return true;
        }

        try
        {
            var apiKey = _config["Notifications:Sms:ApiKey"];
            var senderId = _config["Notifications:Sms:SenderId"] ?? "BHTRAD";
            var url = _config["Notifications:Sms:GatewayUrl"];

            if (string.IsNullOrWhiteSpace(url) || string.IsNullOrWhiteSpace(apiKey))
            {
                _logger.LogWarning("SMS gateway URL or ApiKey not configured. Skipping SMS.");
                return false;
            }

            var requestData = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["to"] = cleanPhone,
                ["message"] = message,
                ["sender"] = senderId,
                ["apikey"] = apiKey
            });

            var response = await _httpClient.PostAsync(url, requestData);
            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("SMS dispatched successfully to {Phone}", cleanPhone);
                return true;
            }

            _logger.LogWarning("SMS dispatch returned status: {StatusCode}", response.StatusCode);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send SMS to {Phone}", cleanPhone);
            return false;
        }
    }

    /// <inheritdoc/>
    public async Task<bool> SendEmailAsync(string toEmail, string subject, string htmlBody)
    {
        if (string.IsNullOrWhiteSpace(toEmail) || !toEmail.Contains('@'))
        {
            _logger.LogWarning("Cannot send email: invalid email provided.");
            return false;
        }

        var isEnabled = _config.GetValue<bool>("Notifications:Email:Enabled");
        if (!isEnabled)
        {
            _logger.LogInformation("Email disabled in settings. Simulated email to {Email}, Subject: {Subject}", toEmail, subject);
            return true;
        }

        try
        {
            var host = _config["Notifications:Email:SmtpHost"] ?? "smtp.gmail.com";
            var port = _config.GetValue<int>("Notifications:Email:SmtpPort", 587);
            var username = _config["Notifications:Email:Username"];
            var password = _config["Notifications:Email:Password"];
            var fromAddress = _config["Notifications:Email:FromAddress"];
            var fromName = _config["Notifications:Email:FromName"] ?? "Bhola Traders";

            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(fromAddress))
            {
                _logger.LogWarning("SMTP credentials not configured. Skipping email dispatch.");
                return false;
            }

            using var client = new SmtpClient(host, port)
            {
                EnableSsl = true,
                Credentials = new NetworkCredential(username, password)
            };

            using var mail = new MailMessage
            {
                From = new MailAddress(fromAddress, fromName),
                Subject = subject,
                Body = htmlBody,
                IsBodyHtml = true
            };
            mail.To.Add(toEmail);

            await client.SendMailAsync(mail);
            _logger.LogInformation("Absence notification email sent to {Email}", toEmail);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email to {Email}", toEmail);
            return false;
        }
    }

    private static string CleanPhoneNumber(string phone)
    {
        var cleaned = Regex.Replace(phone, @"[^\d+]", "");
        return cleaned.Trim();
    }

    private static string BuildAbsenceEmailHtml(string name, string date, string reason)
    {
        return $@"
            <div style='font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;'>
                <h2 style='color: #2E7D32; margin-top: 0;'>भोला ट्रेडर्स (Bhola Traders)</h2>
                <h3 style='color: #C62828;'>अनुपस्थिति सूचना / Absence Notification</h3>
                <p>नमस्ते <b>{name}</b>,</p>
                <p>आपको सूचित किया जाता है कि आज <b>{date}</b> को आपकी अनुपस्थिति (Absent) दर्ज की गई है।</p>
                <div style='background-color: #f5f5f5; padding: 12px; border-radius: 6px; margin: 15px 0;'>
                    <b>कारण (Reason):</b> {reason}
                </div>
                <p style='color: #666; font-size: 13px;'>यदि यह गलत दर्ज हुआ है, तो कृपया मुंशी या व्यवस्थापक से संपर्क करें।</p>
                <hr style='border: none; border-top: 1px solid #eee; margin: 20px 0;'/>
                <p style='color: #999; font-size: 11px;'>Bhola Traders - Trust, Quality & Growth</p>
            </div>";
    }
}
