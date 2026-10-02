namespace AgriLedger.API.Services;

/// <summary>
/// Service contract for keeping Supabase and backend instances active to prevent idle sleeping.
/// </summary>
public interface ISupabaseKeepAliveService
{
    /// <summary>
    /// Sends a lightweight keep-alive ping to Supabase to prevent project auto-pause.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Result containing success flag, HTTP status code, latency, and status message.</returns>
    Task<KeepAliveResult> PingSupabaseAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Sends a self-ping to the backend URL to keep free-tier cloud hosts (e.g. Render) active.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Result containing success flag, HTTP status code, latency, and status message.</returns>
    Task<KeepAliveResult> PingBackendAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Performs an overall health and keepalive assessment of both backend and Supabase.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Combined health summary.</returns>
    Task<OverallHealthResult> CheckHealthAsync(CancellationToken cancellationToken = default);
}

/// <summary>
/// Status result of a keep-alive ping operation.
/// </summary>
/// <param name="Success">Whether the ping succeeded.</param>
/// <param name="StatusCode">HTTP status code returned.</param>
/// <param name="Message">Descriptive status message.</param>
/// <param name="Duration">Round-trip duration of the ping.</param>
/// <param name="Timestamp">UTC timestamp when the ping completed.</param>
public record KeepAliveResult(
    bool Success,
    int StatusCode,
    string Message,
    TimeSpan Duration,
    DateTime Timestamp);

/// <summary>
/// Consolidated health and keep-alive summary.
/// </summary>
/// <param name="BackendHealthy">Whether backend service is operating normally.</param>
/// <param name="Supabase">Detailed Supabase ping result.</param>
/// <param name="SelfPing">Detailed backend self-ping result if configured.</param>
/// <param name="Timestamp">UTC timestamp of the assessment.</param>
public record OverallHealthResult(
    bool BackendHealthy,
    KeepAliveResult Supabase,
    KeepAliveResult? SelfPing,
    DateTime Timestamp);
