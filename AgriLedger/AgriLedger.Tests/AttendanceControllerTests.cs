using AgriLedger.API.Controllers;
using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using AgriLedger.API.Services;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Moq;
using Xunit;

namespace AgriLedger.Tests;

public class AttendanceControllerTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly SqliteConnection _connection;
    private readonly Mock<INotificationService> _mockNotificationService;
    private readonly AttendanceController _controller;
    private readonly string _employeeId = "emp-att-test-1";

    public AttendanceControllerTests()
    {
        (_context, _connection) = TestDbContextFactory.CreateInMemoryDbContext();
        _mockNotificationService = new Mock<INotificationService>();

        _mockNotificationService
            .Setup(s => s.SendAbsenceNotificationAsync(It.IsAny<Employee>(), It.IsAny<Attendance>()))
            .ReturnsAsync(true);

        _controller = new AttendanceController(_context, _mockNotificationService.Object);

        _context.Employees.Add(new Employee
        {
            Id = _employeeId,
            Name = "Sita Ram",
            DailyWageRate = 450m,
            EmployeeType = "laborer",
            IsActive = true
        });
        _context.SaveChanges();
    }

    public void Dispose()
    {
        _context.Dispose();
        _connection.Dispose();
    }

    [Fact]
    public async Task MarkAttendance_Present_SavesSuccessfully()
    {
        // Arrange
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var request = new CreateAttendanceRequest
        {
            EmployeeId = _employeeId,
            AttendanceDate = today,
            Status = "present"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();
        var apiResponse = okResult!.Value as ApiResponse<AttendanceDetail>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.Status.Should().Be("present");
    }

    [Fact]
    public async Task MarkAttendance_Absent_TriggersNotification_AndRequiresAbsenceReason()
    {
        // Arrange
        var testDate = new DateOnly(2026, 2, 10);
        var request = new CreateAttendanceRequest
        {
            EmployeeId = _employeeId,
            AttendanceDate = testDate,
            Status = "absent",
            AbsenceReason = "Illness / तबीयत खराब"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();

        // Verify notification service was called
        _mockNotificationService.Verify(
            s => s.SendAbsenceNotificationAsync(It.IsAny<Employee>(), It.IsAny<Attendance>()),
            Times.Once);
    }

    [Fact]
    public async Task MarkAttendance_DuplicateDate_ReturnsConflict()
    {
        // Arrange
        var date = new DateOnly(2026, 2, 11);
        _context.Attendances.Add(new Attendance
        {
            Id = "att-dup-1",
            EmployeeId = _employeeId,
            AttendanceDate = date,
            Status = "present"
        });
        await _context.SaveChangesAsync();

        var request = new CreateAttendanceRequest
        {
            EmployeeId = _employeeId,
            AttendanceDate = date,
            Status = "present"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var conflictResult = result.Result as ConflictObjectResult;
        conflictResult.Should().NotBeNull();
        conflictResult!.StatusCode.Should().Be(409);
    }

    [Fact]
    public async Task BulkMark_RecordsMultipleEmployees()
    {
        // Arrange
        var emp2 = new Employee
        {
            Id = "emp-att-test-2",
            Name = "Radha Devi",
            DailyWageRate = 400m,
            EmployeeType = "grader",
            IsActive = true
        };
        _context.Employees.Add(emp2);
        await _context.SaveChangesAsync();

        var date = new DateOnly(2026, 3, 1);
        var request = new BulkAttendanceRequest
        {
            Date = date,
            Items = new List<BulkAttendanceItem>
            {
                new() { EmployeeId = _employeeId, Status = "present" },
                new() { EmployeeId = emp2.Id, Status = "half_day" }
            }
        };

        // Act
        var result = await _controller.CreateBulk(request);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();

        var count = _context.Attendances.Count(a => a.AttendanceDate == date);
        count.Should().Be(2);
    }
}
