using AgriLedger.API.Controllers;
using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Models;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Xunit;

namespace AgriLedger.Tests;

public class BagsControllerTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly SqliteConnection _connection;
    private readonly BagsController _controller;
    private readonly string _partyId = "bag-test-party";

    public BagsControllerTests()
    {
        (_context, _connection) = TestDbContextFactory.CreateInMemoryDbContext();
        _controller = new BagsController(_context);

        _context.Parties.Add(new Party
        {
            Id = _partyId,
            Name = "Bhola Farmer",
            PartyType = "farmer",
            Village = "Kishanpur",
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
    public async Task Create_GivenBagMovement_SavesSuccessfully()
    {
        // Arrange
        var request = new CreateBagMovementRequest
        {
            PartyId = _partyId,
            Movement = "given",
            Quantity = 20,
            Notes = "Jute bags for wheat"
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var createdResult = result.Result as CreatedAtActionResult;
        createdResult.Should().NotBeNull();
        createdResult!.StatusCode.Should().Be(201);

        var apiResponse = createdResult.Value as ApiResponse<BagMovementDetail>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Data!.Quantity.Should().Be(20);
        apiResponse.Data.Movement.Should().Be("given");
    }

    [Fact]
    public async Task Create_WithInvalidMovement_ReturnsBadRequest()
    {
        // Arrange
        var request = new CreateBagMovementRequest
        {
            PartyId = _partyId,
            Movement = "invalid_move",
            Quantity = 10
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var badRequestResult = result.Result as BadRequestObjectResult;
        badRequestResult.Should().NotBeNull();
        badRequestResult!.StatusCode.Should().Be(400);
    }

    [Fact]
    public async Task Create_WithZeroOrNegativeQuantity_ReturnsBadRequest()
    {
        // Arrange
        var request = new CreateBagMovementRequest
        {
            PartyId = _partyId,
            Movement = "given",
            Quantity = 0
        };

        // Act
        var result = await _controller.Create(request);

        // Assert
        var badRequestResult = result.Result as BadRequestObjectResult;
        badRequestResult.Should().NotBeNull();
        badRequestResult!.StatusCode.Should().Be(400);
    }

    [Fact]
    public async Task GetOutstanding_ReturnsOnlyPartiesWithPendingBags()
    {
        // Arrange: give 15 bags, return 5 bags => 10 outstanding
        _context.BagMovements.AddRange(
            new BagMovement { Id = "bg1", PartyId = _partyId, Movement = "given", Quantity = 15, EntryDate = DateOnly.FromDateTime(DateTime.UtcNow) },
            new BagMovement { Id = "bg2", PartyId = _partyId, Movement = "returned", Quantity = 5, EntryDate = DateOnly.FromDateTime(DateTime.UtcNow) }
        );
        await _context.SaveChangesAsync();

        // Act
        var result = await _controller.GetOutstanding();

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();
        var apiResponse = okResult!.Value as ApiResponse<List<BagOutstandingSummary>>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Data.Should().HaveCount(1);
        apiResponse.Data!.First().BagsGiven.Should().Be(15);
        apiResponse.Data!.First().BagsReturned.Should().Be(5);
        apiResponse.Data!.First().BagsOutstanding.Should().Be(10);
    }
}
