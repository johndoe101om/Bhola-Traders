using AgriLedger.API.Models;
using AgriLedger.API.Services;
using FluentAssertions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace AgriLedger.Tests;

public class NotificationServiceTests
{
    private readonly NotificationService _service;

    public NotificationServiceTests()
    {
        var settings = new Dictionary<string, string?>
        {
            {"Notifications:Sms:Enabled", "false"},
            {"Notifications:Email:Enabled", "false"}
        };

        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(settings)
            .Build();

        var httpClient = new HttpClient();
        _service = new NotificationService(config, NullLogger<NotificationService>.Instance, httpClient);
    }

    [Fact]
    public async Task SendAbsenceNotificationAsync_WithValidEmployee_ReturnsTrueInSimulatedMode()
    {
        // Arrange
        var employee = new Employee
        {
            Id = "emp-notif-1",
            Name = "Ram Lal",
            Phone = "+91 98765 43210",
            Email = "ramlal@example.com",
            DailyWageRate = 400m,
            EmployeeType = "laborer"
        };

        var attendance = new Attendance
        {
            Id = "att-notif-1",
            EmployeeId = employee.Id,
            AttendanceDate = new DateOnly(2026, 4, 15),
            Status = "absent",
            AbsenceReason = "Fever / बुखार"
        };

        // Act
        var result = await _service.SendAbsenceNotificationAsync(employee, attendance);

        // Assert
        result.Should().BeTrue();
    }

    [Fact]
    public async Task SendAbsenceNotificationAsync_WithNullEmployee_ReturnsFalse()
    {
        // Act
        var result = await _service.SendAbsenceNotificationAsync(null!, new Attendance());

        // Assert
        result.Should().BeFalse();
    }

    [Fact]
    public async Task SendSmsAsync_WithInvalidPhone_ReturnsFalse()
    {
        // Act
        var result = await _service.SendSmsAsync("   ", "Test message");

        // Assert
        result.Should().BeFalse();
    }

    [Fact]
    public async Task SendEmailAsync_WithInvalidEmail_ReturnsFalse()
    {
        // Act
        var result = await _service.SendEmailAsync("not-an-email", "Subject", "Body");

        // Assert
        result.Should().BeFalse();
    }
}
