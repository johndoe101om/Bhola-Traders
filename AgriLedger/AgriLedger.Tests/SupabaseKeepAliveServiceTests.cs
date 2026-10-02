using System.Net;
using AgriLedger.API.Services;
using FluentAssertions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace AgriLedger.Tests;

public class SupabaseKeepAliveServiceTests
{
    private class MockHttpMessageHandler : HttpMessageHandler
    {
        private readonly Func<HttpRequestMessage, HttpResponseMessage> _handler;

        public MockHttpMessageHandler(Func<HttpRequestMessage, HttpResponseMessage> handler)
        {
            _handler = handler;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            return Task.FromResult(_handler(request));
        }
    }

    [Fact]
    public async Task PingSupabaseAsync_WhenCredentialsMissing_ReturnsFailureGracefully()
    {
        // Arrange
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            { "KeepAlive:SupabaseUrl", "" },
            { "KeepAlive:SupabaseAnonKey", "" }
        }).Build();

        var client = new HttpClient();
        var service = new SupabaseKeepAliveService(client, config, NullLogger<SupabaseKeepAliveService>.Instance);

        // Act
        var result = await service.PingSupabaseAsync();

        // Assert
        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(0);
        result.Message.Should().Contain("not configured");
    }

    [Fact]
    public async Task PingSupabaseAsync_WhenSupabaseReturns200_ReturnsSuccess()
    {
        // Arrange
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            { "KeepAlive:SupabaseUrl", "https://example.supabase.co" },
            { "KeepAlive:SupabaseAnonKey", "test-anon-key" }
        }).Build();

        var handler = new MockHttpMessageHandler(req =>
        {
            req.Headers.Contains("apikey").Should().BeTrue();
            req.Headers.Authorization.Should().NotBeNull();
            return new HttpResponseMessage(HttpStatusCode.OK);
        });

        var client = new HttpClient(handler);
        var service = new SupabaseKeepAliveService(client, config, NullLogger<SupabaseKeepAliveService>.Instance);

        // Act
        var result = await service.PingSupabaseAsync();

        // Assert
        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(200);
        result.Message.Should().Be("Supabase active");
    }

    [Fact]
    public async Task PingSupabaseAsync_WhenSupabaseReturns500_ReturnsFailure()
    {
        // Arrange
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            { "KeepAlive:SupabaseUrl", "https://example.supabase.co" },
            { "KeepAlive:SupabaseAnonKey", "test-anon-key" }
        }).Build();

        var handler = new MockHttpMessageHandler(_ => new HttpResponseMessage(HttpStatusCode.InternalServerError));
        var client = new HttpClient(handler);
        var service = new SupabaseKeepAliveService(client, config, NullLogger<SupabaseKeepAliveService>.Instance);

        // Act
        var result = await service.PingSupabaseAsync();

        // Assert
        result.Success.Should().BeFalse();
        result.StatusCode.Should().Be(500);
        result.Message.Should().Contain("500");
    }

    [Fact]
    public async Task PingSupabaseAsync_WhenHttpThrowsException_CatchesAndReturnsFailure()
    {
        // Arrange
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            { "KeepAlive:SupabaseUrl", "https://example.supabase.co" },
            { "KeepAlive:SupabaseAnonKey", "test-anon-key" }
        }).Build();

        var handler = new MockHttpMessageHandler(_ => throw new HttpRequestException("Network down"));
        var client = new HttpClient(handler);
        var service = new SupabaseKeepAliveService(client, config, NullLogger<SupabaseKeepAliveService>.Instance);

        // Act
        var result = await service.PingSupabaseAsync();

        // Assert
        result.Success.Should().BeFalse();
        result.Message.Should().Contain("Connection failed");
    }

    [Fact]
    public async Task PingBackendAsync_WhenNotConfigured_ReturnsSuccessWithNotice()
    {
        // Arrange
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            { "KeepAlive:BackendSelfPingUrl", "" }
        }).Build();

        var client = new HttpClient();
        var service = new SupabaseKeepAliveService(client, config, NullLogger<SupabaseKeepAliveService>.Instance);

        // Act
        var result = await service.PingBackendAsync();

        // Assert
        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(200);
        result.Message.Should().Contain("not configured");
    }

    [Fact]
    public async Task PingBackendAsync_WhenConfiguredAndReturns200_ReturnsSuccess()
    {
        // Arrange
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            { "KeepAlive:BackendSelfPingUrl", "https://agriledger-api.onrender.com/health" }
        }).Build();

        var handler = new MockHttpMessageHandler(_ => new HttpResponseMessage(HttpStatusCode.OK));
        var client = new HttpClient(handler);
        var service = new SupabaseKeepAliveService(client, config, NullLogger<SupabaseKeepAliveService>.Instance);

        // Act
        var result = await service.PingBackendAsync();

        // Assert
        result.Success.Should().BeTrue();
        result.StatusCode.Should().Be(200);
        result.Message.Should().Be("Backend active");
    }

    [Fact]
    public async Task CheckHealthAsync_ReturnsOverallHealthStatus()
    {
        // Arrange
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            { "KeepAlive:SupabaseUrl", "https://example.supabase.co" },
            { "KeepAlive:SupabaseAnonKey", "test-anon-key" },
            { "KeepAlive:EnableBackendSelfPing", "true" },
            { "KeepAlive:BackendSelfPingUrl", "https://agriledger-api.onrender.com/health" }
        }).Build();

        var handler = new MockHttpMessageHandler(_ => new HttpResponseMessage(HttpStatusCode.OK));
        var client = new HttpClient(handler);
        var service = new SupabaseKeepAliveService(client, config, NullLogger<SupabaseKeepAliveService>.Instance);

        // Act
        var health = await service.CheckHealthAsync();

        // Assert
        health.BackendHealthy.Should().BeTrue();
        health.Supabase.Success.Should().BeTrue();
        health.SelfPing.Should().NotBeNull();
        health.SelfPing!.Success.Should().BeTrue();
    }
}
