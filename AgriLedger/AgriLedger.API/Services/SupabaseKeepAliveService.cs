using System.Diagnostics;
using System.Net.Http.Headers;

namespace AgriLedger.API.Services;

/// <summary>
/// Hosted background service that periodically pings Supabase and optionally self-pings the backend
/// to prevent inactive sleeping/pausing on free-tier cloud platforms.
/// </summary>
public class SupabaseKeepAliveService : BackgroundService, ISupabaseKeepAliveService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _config;
    private readonly ILogger<SupabaseKeepAliveService> _logger;

    public SupabaseKeepAliveService(
        IHttpClientFactory httpClientFactory,
        IConfiguration config,
        ILogger<SupabaseKeepAliveService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _config = config;
        _logger = logger;
    }

    public SupabaseKeepAliveService(
        HttpClient httpClient,
        IConfiguration config,
        ILogger<SupabaseKeepAliveService> logger)
        : this(new SimpleHttpClientFactory(httpClient), config, logger)
    {
    }

    /// <inheritdoc />
    public async Task<KeepAliveResult> PingSupabaseAsync(CancellationToken cancellationToken = default)
    {
        var (supabaseUrl, anonKey) = ResolveSupabaseCredentials();

        if (string.IsNullOrWhiteSpace(supabaseUrl) || string.IsNullOrWhiteSpace(anonKey))
        {
            _logger.LogWarning("Supabase keep-alive skipped: URL or AnonKey not configured.");
            return new KeepAliveResult(
                Success: false,
                StatusCode: 0,
                Message: "Supabase URL or AnonKey not configured",
                Duration: TimeSpan.Zero,
                Timestamp: DateTime.UtcNow);
        }

        var sw = Stopwatch.StartNew();
        try
        {
            var targetUri = BuildSupabasePingUri(supabaseUrl);
            using var request = new HttpRequestMessage(HttpMethod.Get, targetUri);
            request.Headers.Add("apikey", anonKey);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", anonKey);

            var client = _httpClientFactory.CreateClient("SupabaseKeepAlive");
            using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            sw.Stop();

            var isSuccess = response.IsSuccessStatusCode;
            var statusCode = (int)response.StatusCode;

            if (isSuccess)
            {
                _logger.LogInformation("Supabase keep-alive ping succeeded ({StatusCode}) in {ElapsedMs}ms",
                    statusCode, sw.ElapsedMilliseconds);
            }
            else
            {
                _logger.LogWarning("Supabase keep-alive ping returned non-success code {StatusCode} in {ElapsedMs}ms",
                    statusCode, sw.ElapsedMilliseconds);
            }

            return new KeepAliveResult(
                Success: isSuccess,
                StatusCode: statusCode,
                Message: isSuccess ? "Supabase active" : $"Supabase returned HTTP {statusCode}",
                Duration: sw.Elapsed,
                Timestamp: DateTime.UtcNow);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            return new KeepAliveResult(false, 0, "Operation canceled", sw.Elapsed, DateTime.UtcNow);
        }
        catch (Exception ex)
        {
            sw.Stop();
            _logger.LogError(ex, "Supabase keep-alive ping failed after {ElapsedMs}ms", sw.ElapsedMilliseconds);
            return new KeepAliveResult(
                Success: false,
                StatusCode: 0,
                Message: $"Connection failed: {ex.Message}",
                Duration: sw.Elapsed,
                Timestamp: DateTime.UtcNow);
        }
    }

    /// <inheritdoc />
    public async Task<KeepAliveResult> PingBackendAsync(CancellationToken cancellationToken = default)
    {
        var pingUrl = _config["KeepAlive:BackendSelfPingUrl"]
            ?? Environment.GetEnvironmentVariable("BACKEND_SELF_PING_URL");

        if (string.IsNullOrWhiteSpace(pingUrl))
        {
            return new KeepAliveResult(
                Success: true,
                StatusCode: 200,
                Message: "Self-ping not configured (running locally or disabled)",
                Duration: TimeSpan.Zero,
                Timestamp: DateTime.UtcNow);
        }

        var sw = Stopwatch.StartNew();
        try
        {
            var client = _httpClientFactory.CreateClient("SupabaseKeepAlive");
            using var response = await client.GetAsync(pingUrl, cancellationToken);
            sw.Stop();

            var isSuccess = response.IsSuccessStatusCode;
            var statusCode = (int)response.StatusCode;

            _logger.LogInformation("Backend self-ping returned {StatusCode} in {ElapsedMs}ms",
                statusCode, sw.ElapsedMilliseconds);

            return new KeepAliveResult(
                Success: isSuccess,
                StatusCode: statusCode,
                Message: isSuccess ? "Backend active" : $"Backend returned HTTP {statusCode}",
                Duration: sw.Elapsed,
                Timestamp: DateTime.UtcNow);
        }
        catch (Exception ex)
        {
            sw.Stop();
            _logger.LogWarning(ex, "Backend self-ping failed after {ElapsedMs}ms", sw.ElapsedMilliseconds);
            return new KeepAliveResult(false, 0, ex.Message, sw.Elapsed, DateTime.UtcNow);
        }
    }

    /// <inheritdoc />
    public async Task<OverallHealthResult> CheckHealthAsync(CancellationToken cancellationToken = default)
    {
        var supabase = await PingSupabaseAsync(cancellationToken);
        var selfPing = _config.GetValue<bool>("KeepAlive:EnableBackendSelfPing")
            ? await PingBackendAsync(cancellationToken)
            : null;

        return new OverallHealthResult(
            BackendHealthy: true,
            Supabase: supabase,
            SelfPing: selfPing,
            Timestamp: DateTime.UtcNow);
    }

    /// <summary>
    /// Background execution loop running scheduled keep-alive pulses.
    /// </summary>
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var enableKeepAlive = _config.GetValue<bool>("KeepAlive:EnableSupabaseKeepAlive", true);
        if (!enableKeepAlive)
        {
            _logger.LogInformation("Supabase keep-alive background worker is disabled by configuration.");
            return;
        }

        var intervalHours = Math.Max(1, _config.GetValue<int>("KeepAlive:SupabaseIntervalHours", 6));
        var supabaseInterval = TimeSpan.FromHours(intervalHours);

        var enableSelfPing = _config.GetValue<bool>("KeepAlive:EnableBackendSelfPing", false);
        var selfPingInterval = TimeSpan.FromMinutes(
            Math.Max(5, _config.GetValue<int>("KeepAlive:BackendSelfPingIntervalMinutes", 14)));

        _logger.LogInformation(
            "Supabase keep-alive background worker started. Supabase interval: {IntervalHours}h, Self-ping: {SelfPingEnabled}",
            intervalHours, enableSelfPing);

        // Initial delay of 15 seconds to allow app and network to fully initialize, then immediate ping
        await Task.Delay(TimeSpan.FromSeconds(15), stoppingToken);
        await PingSupabaseAsync(stoppingToken);

        var lastSupabasePing = DateTime.UtcNow;
        var lastBackendPing = DateTime.UtcNow;

        // Loop checking on minute intervals
        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(1));
        while (!stoppingToken.IsCancellationRequested && await timer.WaitForNextTickAsync(stoppingToken))
        {
            var now = DateTime.UtcNow;

            if (now - lastSupabasePing >= supabaseInterval)
            {
                lastSupabasePing = now;
                await PingSupabaseAsync(stoppingToken);
            }

            if (enableSelfPing && (now - lastBackendPing >= selfPingInterval))
            {
                lastBackendPing = now;
                await PingBackendAsync(stoppingToken);
            }
        }
    }

    private (string? url, string? key) ResolveSupabaseCredentials()
    {
        var url = _config["KeepAlive:SupabaseUrl"]
            ?? _config["Supabase:Url"]
            ?? Environment.GetEnvironmentVariable("SUPABASE_URL");

        var key = _config["KeepAlive:SupabaseAnonKey"]
            ?? _config["Supabase:AnonKey"]
            ?? Environment.GetEnvironmentVariable("SUPABASE_ANON_KEY");

        return (url, key);
    }

    private static Uri BuildSupabasePingUri(string baseUrl)
    {
        var cleanUrl = baseUrl.TrimEnd('/');
        return new Uri($"{cleanUrl}/rest/v1/parties?select=id&limit=1");
    }

    private sealed class SimpleHttpClientFactory : IHttpClientFactory
    {
        private readonly HttpClient _client;
        public SimpleHttpClientFactory(HttpClient client) => _client = client;
        public HttpClient CreateClient(string name) => _client;
    }
}
