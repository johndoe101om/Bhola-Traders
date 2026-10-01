using AgriLedger.API.Controllers;
using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Xunit;

namespace AgriLedger.Tests;

public class TransactionsControllerTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly SqliteConnection _connection;
    private readonly TransactionsController _controller;
    private readonly string _testPartyId = "party-txn-test-1";

    public TransactionsControllerTests()
    {
        (_context, _connection) = TestDbContextFactory.CreateInMemoryDbContext();
        _controller = new TransactionsController(_context);

        // Seed a test party
        _context.Parties.Add(new Party
        {
            Id = _testPartyId,
            Name = "Kisan Test",
            PartyType = "farmer",
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
    public async Task Create_PurchaseTransaction_SetsDirectionOut_AndSavesCorrectly()
    {
        // Arrange
        var request = new CreateTransactionRequest
        {
            PartyId = _testPartyId,
            TxnType = "purchase",
            Commodity = "wheat",
            QuantityKg = 100m,
            RatePerKg = 25m,
            Amount = 2500m,
            PaymentMode = "cash"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var createdResult = result.Result as CreatedAtActionResult;
        createdResult.Should().NotBeNull();
        createdResult!.StatusCode.Should().Be(201);

        var apiResponse = createdResult.Value as ApiResponse<TransactionDetail>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.Direction.Should().Be("out");
        apiResponse.Data.Amount.Should().Be(2500m);
        apiResponse.Data.Commodity.Should().Be("wheat");
    }

    [Fact]
    public async Task Create_SaleTransaction_SetsDirectionIn()
    {
        // Arrange
        var request = new CreateTransactionRequest
        {
            PartyId = _testPartyId,
            TxnType = "sale",
            Amount = 1000m,
            PaymentMode = "upi"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var createdResult = result.Result as CreatedAtActionResult;
        createdResult.Should().NotBeNull();
        var apiResponse = createdResult!.Value as ApiResponse<TransactionDetail>;
        apiResponse!.Data!.Direction.Should().Be("in");
    }

    [Fact]
    public async Task Create_WithInvalidTxnType_ReturnsBadRequest()
    {
        // Arrange
        var request = new CreateTransactionRequest
        {
            PartyId = _testPartyId,
            TxnType = "invalid_txn_type",
            Amount = 1000m
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var badRequestResult = result.Result as BadRequestObjectResult;
        badRequestResult.Should().NotBeNull();
        badRequestResult!.StatusCode.Should().Be(400);
    }

    [Fact]
    public async Task Create_WithNonExistentParty_ReturnsNotFound()
    {
        // Arrange
        var request = new CreateTransactionRequest
        {
            PartyId = "non-existent-party",
            TxnType = "purchase",
            Amount = 500m
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var notFoundResult = result.Result as NotFoundObjectResult;
        notFoundResult.Should().NotBeNull();
        notFoundResult!.StatusCode.Should().Be(404);
    }

    [Fact]
    public async Task GetSummary_AggregatesTotalsAccurately()
    {
        // Arrange
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        _context.Transactions.AddRange(
            new Transaction { Id = "tx1", PartyId = _testPartyId, TxnType = "purchase", Amount = 1000m, Direction = "out", EntryDate = today, IsDeleted = false },
            new Transaction { Id = "tx2", PartyId = _testPartyId, TxnType = "sale", Amount = 1500m, Direction = "in", EntryDate = today, IsDeleted = false },
            new Transaction { Id = "tx3", PartyId = _testPartyId, TxnType = "cash_in", Amount = 300m, Direction = "in", EntryDate = today, IsDeleted = false },
            new Transaction { Id = "tx4", PartyId = _testPartyId, TxnType = "cash_out", Amount = 200m, Direction = "out", EntryDate = today, IsDeleted = false }
        );
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.GetSummary(today, today);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();
        var apiResponse = okResult!.Value as ApiResponse<List<TransactionSummary>>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Data.Should().HaveCount(1);

        var summary = apiResponse.Data!.First();
        summary.TotalPurchaseAmount.Should().Be(1000m);
        summary.TotalSaleAmount.Should().Be(1500m);
        summary.TotalCashIn.Should().Be(300m);
        summary.TotalCashOut.Should().Be(200m);
        // Net cash = Total in (1500+300) - Total out (1000+200) = 600
        summary.NetCash.Should().Be(600m);
    }

    [Fact]
    public async Task Delete_SoftDeletesTransaction()
    {
        // Arrange
        var txn = new Transaction
        {
            Id = "txn-to-delete",
            PartyId = _testPartyId,
            TxnType = "purchase",
            Amount = 400m,
            Direction = "out",
            EntryDate = DateOnly.FromDateTime(DateTime.UtcNow),
            IsDeleted = false
        };
        _context.Transactions.Add(txn);
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.Delete(txn.Id);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();

        var updatedTxn = await _context.Transactions.FindAsync(txn.Id);
        updatedTxn.Should().NotBeNull();
        updatedTxn!.IsDeleted.Should().BeTrue();
    }
}
