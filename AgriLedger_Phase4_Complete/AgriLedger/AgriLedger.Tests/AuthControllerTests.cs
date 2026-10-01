using AgriLedger.API.Controllers;
using AgriLedger.API.DTOs;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace AgriLedger.Tests;

public class AuthControllerTests
{
    private readonly IConfiguration _config;
    private readonly AuthController _controller;

    public AuthControllerTests()
    {
        var inMemorySettings = new Dictionary<string, string?>
        {
            {"Auth:Pin", "1234"}
        };

        _config = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings)
            .Build();

        _controller = new AuthController(_config);
    }

    [Fact]
    public void VerifyPin_WithCorrectPin_ReturnsOkWithSuccess()
    {
        // Arrange
        var request = new PinVerifyRequest { Pin = "1234" };

        // Act
        var result = _controller.VerifyPin(request);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();
        okResult!.StatusCode.Should().Be(200);

        var apiResponse = okResult.Value as ApiResponse<object>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeTrue();
        apiResponse.Message.Should().Contain("PIN correct");
    }

    [Fact]
    public void VerifyPin_WithIncorrectPin_ReturnsUnauthorized()
    {
        // Arrange
        var request = new PinVerifyRequest { Pin = "9999" };

        // Act
        var result = _controller.VerifyPin(request);

        // Assert
        var unauthorizedResult = result.Result as UnauthorizedObjectResult;
        unauthorizedResult.Should().NotBeNull();
        unauthorizedResult!.StatusCode.Should().Be(401);

        var apiResponse = unauthorizedResult.Value as ApiResponse<object>;
        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeFalse();
        apiResponse.Message.Should().Contain("Incorrect PIN");
    }

    [Fact]
    public void VerifyPin_WithDefaultConfigWhenMissing_UsesDefault1234()
    {
        // Arrange
        var emptyConfig = new ConfigurationBuilder().Build();
        var controllerWithDefault = new AuthController(emptyConfig);
        var request = new PinVerifyRequest { Pin = "1234" };

        // Act
        var result = controllerWithDefault.VerifyPin(request);

        // Assert
        var okResult = result.Result as OkObjectResult;
        okResult.Should().NotBeNull();
        okResult!.StatusCode.Should().Be(200);
    }
}
