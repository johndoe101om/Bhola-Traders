namespace AgriLedger.API.Middleware;

/// <summary>
/// Simple PIN-based auth middleware.
/// Pass X-PIN header with each request.
/// Phase 2: Replace with JWT Bearer tokens.
/// </summary>
public class PinAuthMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IConfiguration _config;

    // Paths that don't need auth
    private static readonly string[] PublicPaths =
    [
        "/swagger",
        "/health",
        "/api/v1/auth"
    ];

    public PinAuthMiddleware(RequestDelegate next, IConfiguration config)
    {
        _next = next;
        _config = config;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var path = context.Request.Path.Value ?? "";

        // Allow swagger and health without PIN
        if (PublicPaths.Any(p => path.StartsWith(p, StringComparison.OrdinalIgnoreCase)))
        {
            await _next(context);
            return;
        }

        var expectedPin = _config["Auth:Pin"] ?? "1234";

        if (!context.Request.Headers.TryGetValue("X-PIN", out var pin) || pin != expectedPin)
        {
            context.Response.StatusCode = 401;
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsync("""{"success":false,"message":"Invalid or missing PIN. Send X-PIN header."}""");
            return;
        }

        await _next(context);
    }
}
