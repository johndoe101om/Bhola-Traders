using System.Text.Json;
using AgriLedger.API.DTOs;
using AgriLedger.API.Middleware;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace AgriLedger.Tests;

public class MiddlewareTests
{
    [Theory]
    [InlineData("/health")]
    [InlineData("/api/keepalive")]
    [InlineData("/swagger/index.html")]
    [InlineData("/api/v1/auth/verify")]
    public async Task PinAuthMiddleware_AllowsPublicPaths_WithoutPin(string path)
    {
        // Arrange
        var context = new DefaultHttpContext();
        context.Request.Path = path;

        bool nextCalled = false;
        RequestDelegate next = (ctx) =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        };

        var config = new ConfigurationBuilder().Build();
        var middleware = new PinAuthMiddleware(next, config);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        nextCalled.Should().BeTrue();
        context.Response.StatusCode.Should().Be(200);
    }

    [Fact]
    public async Task PinAuthMiddleware_RejectsProtectedPath_WithoutPin_With401()
    {
        // Arrange
        var context = new DefaultHttpContext();
        context.Request.Path = "/api/v1/parties";
        context.Response.Body = new MemoryStream();

        bool nextCalled = false;
        RequestDelegate next = (ctx) =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        };

        var config = new ConfigurationBuilder().Build();
        var middleware = new PinAuthMiddleware(next, config);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        nextCalled.Should().BeFalse();
        context.Response.StatusCode.Should().Be(401);
    }

    [Fact]
    public async Task PinAuthMiddleware_AllowsProtectedPath_WithCorrectPin()
    {
        // Arrange
        var context = new DefaultHttpContext();
        context.Request.Path = "/api/v1/parties";
        context.Request.Headers["X-PIN"] = "1234";

        bool nextCalled = false;
        RequestDelegate next = (ctx) =>
        {
            nextCalled = true;
            return Task.CompletedTask;
        };

        var inMemorySettings = new Dictionary<string, string?> { { "Auth:Pin", "1234" } };
        var config = new ConfigurationBuilder().AddInMemoryCollection(inMemorySettings).Build();
        var middleware = new PinAuthMiddleware(next, config);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        nextCalled.Should().BeTrue();
    }

    [Fact]
    public async Task ExceptionHandlingMiddleware_CatchesUnhandledException_Returns500WithSafeMessage()
    {
        // Arrange
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();

        RequestDelegate next = (ctx) => throw new InvalidOperationException("Sensitive internal database connection string leaked");

        var middleware = new ExceptionHandlingMiddleware(next, NullLogger<ExceptionHandlingMiddleware>.Instance);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        context.Response.StatusCode.Should().Be(500);

        context.Response.Body.Seek(0, SeekOrigin.Begin);
        using var reader = new StreamReader(context.Response.Body);
        var responseBody = await reader.ReadToEndAsync();

        var apiResponse = JsonSerializer.Deserialize<ApiResponse<object>>(responseBody, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        apiResponse.Should().NotBeNull();
        apiResponse!.Success.Should().BeFalse();
        apiResponse.Message.Should().Be("An unexpected error occurred while processing your request.");
        responseBody.Should().NotContain("Sensitive internal database connection string leaked");
    }
}
