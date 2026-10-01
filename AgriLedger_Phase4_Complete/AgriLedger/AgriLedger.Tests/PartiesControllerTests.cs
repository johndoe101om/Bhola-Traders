using AgriLedger.API.Controllers;
using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Xunit;

namespace AgriLedger.Tests;

public class PartiesControllerTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly SqliteConnection _connection;
    private readonly PartiesController _controller;

    public PartiesControllerTests()
    {
        (_context, _connection) = TestDbContextFactory.CreateInMemoryDbContext();
        _controller = new PartiesController(_context);
    }

    public void Dispose()
    {
        _context.Dispose();
        _connection.Dispose();
    }

    [Fact]
    public async Task Create_WithValidFarmer_ReturnsCreated()
    {
        // Arrange
        var request = new CreatePartyRequest
        {
            Name = "Ramesh Kumar",
            PartyType = "farmer",
            Phone = "9876543210",
            Village = "Sitapur"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var createdResult = result.Result as CreatedAtActionResult;
        createdResult.Should().NotBeNull();
        createdResult!.StatusCode.Should().Be(201);

        var apiResponse = createdResult.Value as ApiResponse<PartyDetail>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.Name.Should().Be("Ramesh Kumar");
        apiResponse.Data.PartyType.Should().Be("farmer");
        apiResponse.Data.Village.Should().Be("Sitapur");
    }

    [Fact]
    public async Task Create_WithInvalidPartyType_ReturnsBadRequest()
    {
        // Arrange
        var request = new CreatePartyRequest
        {
            Name = "Invalid Party",
            PartyType = "unknown_type",
            Village = "Sitapur"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var badRequestResult = result.Result as BadRequestObjectResult;
        badRequestResult.Should().NotBeNull();
        badRequestResult!.StatusCode.Should().Be(400);

        var apiResponse = badRequestResult.Value as ApiResponse<PartyDetail>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeFalse();
        apiResponse.Message.Should().Contain("Invalid party_type");
    }

    [Fact]
    public async Task Create_WithDuplicateInSameVillage_ReturnsConflict()
    {
        // Arrange
        var request1 = new CreatePartyRequest
        {
            Name = "Suresh Patel",
            PartyType = "farmer",
            Village = "Sitapur"
        };
        await _controller.Create(request1);

        var duplicateRequest = new CreatePartyRequest
        {
            Name = "Suresh Patel",
            PartyType = "farmer",
            Village = "Sitapur"
        };

        // Act
        var result = await _controller.Create(duplicateRequest);

        // Assert
        var conflictResult = result.Result as ConflictObjectResult;
        conflictResult.Should().NotBeNull();
        conflictResult!.StatusCode.Should().Be(409);

        var apiResponse = conflictResult.Value as ApiResponse<PartyDetail>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeFalse();
        apiResponse.Message.Should().Contain("already exists in");
    }

    [Fact]
    public async Task GetAll_FiltersByPartyTypeAndSearchQuery()
    {
        // Arrange
        _context.Parties.AddRange(
            new Party { Id = "p1", Name = "Ram Lal", PartyType = "farmer", Village = "Village A", IsActive = true },
            new Party { Id = "p2", Name = "Shyam Singh", PartyType = "supplier", Village = "Village B", IsActive = true },
            new Party { Id = "p3", Name = "Ram Prasad", PartyType = "farmer", Village = "Village C", IsActive = true }
        );
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.GetAll("farmer", "Ram", null);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();
        var apiResponse = okResult!.Value as ApiResponse<List<PartyListItem>>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Data.Should().HaveCount(2);
        apiResponse.Data!.All(p => p.PartyType == "farmer" && p.Name.Contains("Ram")).Should().BeTrue();
    }

    [Fact]
    public async Task GetById_ReturnsNotFound_WhenPartyDoesNotExistOrIsInactive()
    {
        // Act
        var result = await _controller.GetById("non-existent-id");

        // Assert
        var notFoundResult = result.Result as NotFoundObjectResult;
        notFoundResult.Should().NotBeNull();
        notFoundResult!.StatusCode.Should().Be(404);
    }

    [Fact]
    public async Task GetLedger_CalculatesCorrectBalanceAndBags()
    {
        // Arrange
        var party = new Party
        {
            Id = "party-ledger-1",
            Name = "Kisan Ram",
            PartyType = "farmer",
            Village = "Village D",
            IsActive = true
        };
        _context.Parties.Add(party);

        // Add Transactions:
        // direction 'out' = we paid farmer 2000
        // direction 'in' = farmer gave us cash 500
        _context.Transactions.AddRange(
            new Transaction
            {
                Id = "t1",
                PartyId = party.Id,
                TxnType = "purchase",
                Amount = 2000m,
                Direction = "out",
                EntryDate = DateOnly.FromDateTime(DateTime.UtcNow),
                IsDeleted = false
            },
            new Transaction
            {
                Id = "t2",
                PartyId = party.Id,
                TxnType = "cash_in",
                Amount = 500m,
                Direction = "in",
                EntryDate = DateOnly.FromDateTime(DateTime.UtcNow),
                IsDeleted = false
            }
        );

        // Add Bags:
        // given 10, returned 3 => outstanding 7
        _context.BagMovements.AddRange(
            new BagMovement
            {
                Id = "b1",
                PartyId = party.Id,
                Movement = "given",
                Quantity = 10,
                EntryDate = DateOnly.FromDateTime(DateTime.UtcNow)
            },
            new BagMovement
            {
                Id = "b2",
                PartyId = party.Id,
                Movement = "returned",
                Quantity = 3,
                EntryDate = DateOnly.FromDateTime(DateTime.UtcNow)
            }
        );

        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.GetLedger(party.Id, null, null);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();
        var apiResponse = okResult!.Value as ApiResponse<PartyLedgerResponse>;
        apiResponse.Should().NotBeNull();

        // Net balance: 500 (in) - 2000 (out) = -1500 (we_owe_them)
        apiResponse!.Data!.Balance.Amount.Should().Be(1500m);
        apiResponse.Data.Balance.Direction.Should().Be("we_owe_them");
        apiResponse.Data.BagsOutstanding.Should().Be(7);
        apiResponse.Data.Transactions.Should().HaveCount(2);
        apiResponse.Data.BagMovements.Should().HaveCount(2);
    }

    [Fact]
    public async Task Delete_SoftDeletesParty()
    {
        // Arrange
        var party = new Party
        {
            Id = "delete-party-1",
            Name = "To Delete",
            PartyType = "farmer",
            IsActive = true
        };
        _context.Parties.Add(party);
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.Delete(party.Id);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();

        var updatedParty = await _context.Parties.FindAsync(party.Id);
        updatedParty.Should().NotBeNull();
        updatedParty!.IsActive.Should().BeFalse();
    }
}
