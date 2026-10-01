using AgriLedger.API.Controllers;
using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Xunit;

namespace AgriLedger.Tests;

public class EmployeePaymentsControllerTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly SqliteConnection _connection;
    private readonly EmployeePaymentsController _controller;
    private readonly string _employeeId = "emp-pay-test-1";

    public EmployeePaymentsControllerTests()
    {
        (_context, _connection) = TestDbContextFactory.CreateInMemoryDbContext();
        _controller = new EmployeePaymentsController(_context);

        _context.Employees.Add(new Employee
        {
            Id = _employeeId,
            Name = "Vikas Sharma",
            DailyWageRate = 500m,
            EmployeeType = "accountant",
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
    public async Task Create_WagePayment_SavesSuccessfully()
    {
        // Arrange
        var request = new CreateEmployeePaymentRequest
        {
            EmployeeId = _employeeId,
            Amount = 3000m,
            PaymentMode = "bank_transfer",
            PaymentType = "wage",
            ReferenceNumber = "UPI987654321"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();
        okResult!.StatusCode.Should().Be(200);

        var apiResponse = okResult.Value as ApiResponse<EmployeePaymentDetail>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.Amount.Should().Be(3000m);
        apiResponse.Data.PaymentType.Should().Be("wage");
    }

    [Fact]
    public async Task Create_WithInvalidPaymentType_ReturnsBadRequest()
    {
        // Arrange
        var request = new CreateEmployeePaymentRequest
        {
            EmployeeId = _employeeId,
            Amount = 1000m,
            PaymentMode = "cash",
            PaymentType = "lottery_winnings"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var badRequestResult = result.Result as BadRequestObjectResult;
        badRequestResult.Should().NotBeNull();
        badRequestResult!.StatusCode.Should().Be(400);
    }

    [Fact]
    public async Task GetSummary_AggregatesWagesAndAdvancesProperly()
    {
        // Arrange
        _context.EmployeePayments.AddRange(
            new EmployeePayment { Id = "ep1", EmployeeId = _employeeId, Amount = 4000m, PaymentType = "wage", PaymentMode = "cash", PaymentDate = new DateOnly(2026, 1, 15) },
            new EmployeePayment { Id = "ep2", EmployeeId = _employeeId, Amount = 1000m, PaymentType = "advance", PaymentMode = "cash", PaymentDate = new DateOnly(2026, 1, 20) },
            new EmployeePayment { Id = "ep3", EmployeeId = _employeeId, Amount = 500m, PaymentType = "bonus", PaymentMode = "cash", PaymentDate = new DateOnly(2026, 1, 25) }
        );
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.GetSummary(new DateOnly(2026, 1, 1), new DateOnly(2026, 1, 31));

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();
        var apiResponse = okResult!.Value as ApiResponse<List<PaymentSummary>>;
        apiResponse.Should().NotBeNull();
        var summary = apiResponse!.Data!.First();
        summary.TotalWagePaid.Should().Be(4000m);
        summary.TotalAdvances.Should().Be(1000m);
        summary.TotalBonus.Should().Be(500m);
        summary.NetPaid.Should().Be(5500m);
    }
}
