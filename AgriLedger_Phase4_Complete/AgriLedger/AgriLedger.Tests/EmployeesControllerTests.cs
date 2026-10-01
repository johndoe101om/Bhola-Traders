using AgriLedger.API.Controllers;
using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Xunit;

namespace AgriLedger.Tests;

public class EmployeesControllerTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly SqliteConnection _connection;
    private readonly EmployeesController _controller;

    public EmployeesControllerTests()
    {
        (_context, _connection) = TestDbContextFactory.CreateInMemoryDbContext();
        _controller = new EmployeesController(_context);
    }

    public void Dispose()
    {
        _context.Dispose();
        _connection.Dispose();
    }

    [Fact]
    public async Task Create_WithValidWorker_ReturnsCreated()
    {
        // Arrange
        var request = new CreateEmployeeRequest
        {
            Name = "Sohan Pal",
            DailyWageRate = 500m,
            EmployeeType = "labour",
            Phone = "9123456780",
            TeamGroup = "Loading"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var createdResult = result.Result as CreatedAtActionResult;
        createdResult.Should().NotBeNull();
        createdResult!.StatusCode.Should().Be(201);

        var apiResponse = createdResult.Value as ApiResponse<EmployeeDetail>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.Name.Should().Be("Sohan Pal");
        apiResponse.Data.DailyWageRate.Should().Be(500m);
        apiResponse.Data.EmployeeType.Should().Be("labour");
    }

    [Fact]
    public async Task Create_WithInvalidEmployeeType_ReturnsBadRequest()
    {
        // Arrange
        var request = new CreateEmployeeRequest
        {
            Name = "Unknown Worker",
            DailyWageRate = 400m,
            EmployeeType = "astronaut"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var badRequestResult = result.Result as BadRequestObjectResult;
        badRequestResult.Should().NotBeNull();
        badRequestResult!.StatusCode.Should().Be(400);
    }

    [Fact]
    public async Task GetAll_CalculatesDaysPresentAndBalanceAccurately()
    {
        // Arrange
        var employee = new Employee
        {
            Id = "emp-wage-test",
            Name = "Mohan Lal",
            DailyWageRate = 400m,
            EmployeeType = "labour",
            IsActive = true
        };
        _context.Employees.Add(employee);

        // 2 full days present (400*2 = 800)
        // 1 half day (400*0.5 = 200)
        // Total earned = 1000
        _context.Attendances.AddRange(
            new Attendance { Id = "att1", EmployeeId = employee.Id, AttendanceDate = new DateOnly(2026, 1, 1), Status = "present" },
            new Attendance { Id = "att2", EmployeeId = employee.Id, AttendanceDate = new DateOnly(2026, 1, 2), Status = "present" },
            new Attendance { Id = "att3", EmployeeId = employee.Id, AttendanceDate = new DateOnly(2026, 1, 3), Status = "half_day" }
        );

        // Paid 600
        // Balance due = 1000 - 600 = 400
        _context.EmployeePayments.Add(new EmployeePayment
        {
            Id = "pay1",
            EmployeeId = employee.Id,
            PaymentDate = new DateOnly(2026, 1, 3),
            Amount = 600m,
            PaymentMode = "cash",
            PaymentType = "wage"
        });

        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.GetAll(null, null, null, null);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();
        var apiResponse = okResult!.Value as ApiResponse<List<EmployeeListItem>>;
        apiResponse.Should().NotBeNull();

        var empItem = apiResponse!.Data!.FirstOrDefault(e => e.Id == employee.Id);
        empItem.Should().NotBeNull();
        empItem!.DaysPresent.Should().Be(2.5m);
        empItem.TotalPaid.Should().Be(600m);
        empItem.Balance.Should().Be(400m);
    }

    [Fact]
    public async Task Delete_SoftDeletesEmployee()
    {
        // Arrange
        var emp = new Employee
        {
            Id = "emp-del-1",
            Name = "Temp Worker",
            EmployeeType = "labour",
            DailyWageRate = 350m,
            IsActive = true
        };
        _context.Employees.Add(emp);
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.Delete(emp.Id);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();

        var updated = await _context.Employees.FindAsync(emp.Id);
        updated.Should().NotBeNull();
        updated!.IsActive.Should().BeFalse();
    }
}
