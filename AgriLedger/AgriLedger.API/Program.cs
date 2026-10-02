using AgriLedger.API.Data;
using AgriLedger.API.DTOs;
using AgriLedger.API.Middleware;
using AgriLedger.API.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ── SERVICES ──────────────────────────────────────────────────────────

builder.Services.AddHttpClient<INotificationService, NotificationService>();
builder.Services.AddHttpClient("SupabaseKeepAlive", client =>
{
    client.Timeout = TimeSpan.FromSeconds(30);
});
builder.Services.AddSingleton<SupabaseKeepAliveService>();
builder.Services.AddSingleton<ISupabaseKeepAliveService>(sp => sp.GetRequiredService<SupabaseKeepAliveService>());
builder.Services.AddHostedService(sp => sp.GetRequiredService<SupabaseKeepAliveService>());

builder.Services.AddControllers()
    .AddJsonOptions(opts =>
    {
        // Use camelCase in JSON responses
        opts.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        // Include nulls so mobile app gets predictable shape
        opts.JsonSerializerOptions.DefaultIgnoreCondition =
            System.Text.Json.Serialization.JsonIgnoreCondition.Never;
    });

// Configure standardized validation error response format
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = context.ModelState
            .Where(x => x.Value?.Errors.Count > 0)
            .SelectMany(x => x.Value!.Errors.Select(e => string.IsNullOrWhiteSpace(e.ErrorMessage) ? $"{x.Key} is invalid" : e.ErrorMessage))
            .ToList();

        var response = ApiResponse<object>.Fail("Validation failed.", errors);
        return new BadRequestObjectResult(response);
    };
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new()
    {
        Title = "AgriLedger API",
        Version = "v1",
        Description = "Agricultural ledger API for tracking grain, cash, and jute bag transactions."
    });
    c.AddSecurityDefinition("PIN", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "X-PIN",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Description = "Enter your 4-digit PIN"
    });
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new() { Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme, Id = "PIN" }
            },
            Array.Empty<string>()
        }
    });
    // Include XML comments if generated
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath)) c.IncludeXmlComments(xmlPath);
});

// ── DATABASE ──────────────────────────────────────────────────────────
// Phase 1: SQLite (zero setup, works on any machine)
// Phase 2: Switch to PostgreSQL — just change this one block

var usePostgres = builder.Configuration.GetValue<bool>("Database:UsePostgres");

if (usePostgres)
{
    builder.Services.AddDbContext<AppDbContext>(opt =>
        opt.UseNpgsql(
            builder.Configuration.GetConnectionString("PostgreSQL"),
            npg => npg.MigrationsAssembly("AgriLedger.API")
        ));
}
else
{
    var dbPath = builder.Configuration["Database:SqlitePath"] ?? "agriledger.db";
    builder.Services.AddDbContext<AppDbContext>(opt =>
        opt.UseSqlite(
            $"Data Source={dbPath}",
            sql => sql.MigrationsAssembly("AgriLedger.API")
        ));
}

// ── CORS ──────────────────────────────────────────────────────────────
builder.Services.AddCors(opt =>
{
    opt.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader());
});

// ── BUILD ─────────────────────────────────────────────────────────────
var app = builder.Build();

// ── GLOBAL EXCEPTION HANDLING & SECURITY HEADERS ──────────────────────
app.UseMiddleware<ExceptionHandlingMiddleware>();

app.Use(async (context, next) =>
{
    context.Response.Headers.Append("X-Content-Type-Options", "nosniff");
    context.Response.Headers.Append("X-Frame-Options", "DENY");
    context.Response.Headers.Append("X-XSS-Protection", "1; mode=block");
    context.Response.Headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");
    await next();
});

// ── AUTO MIGRATE ON STARTUP ───────────────────────────────────────────
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    try
    {
        db.Database.Migrate();
        logger.LogInformation("✅ Database migration applied.");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "❌ Database migration failed.");
        throw;
    }
}

// ── MIDDLEWARE PIPELINE ───────────────────────────────────────────────
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "AgriLedger API v1");
    c.RoutePrefix = string.Empty; // Swagger at root: http://localhost:5000
});

app.UseCors();

// PIN auth on all API routes
app.UseMiddleware<PinAuthMiddleware>();

app.UseRouting();
app.MapControllers();

// Health check endpoint (no auth required)
app.MapGet("/health", async (ISupabaseKeepAliveService keepAliveService, [FromQuery] bool? pingSupabase, CancellationToken ct) =>
{
    if (pingSupabase == true)
    {
        var result = await keepAliveService.CheckHealthAsync(ct);
        return Results.Ok(new
        {
            status = result.Supabase.Success ? "ok" : "degraded",
            timestamp = DateTime.UtcNow,
            version = "1.0.0",
            supabase = result.Supabase
        });
    }

    return Results.Ok(new
    {
        status = "ok",
        timestamp = DateTime.UtcNow,
        version = "1.0.0"
    });
});

// Dedicated Keep-Alive endpoint (no auth required) to ping Supabase and backend
app.MapGet("/api/keepalive", async (ISupabaseKeepAliveService keepAliveService, CancellationToken ct) =>
{
    var result = await keepAliveService.CheckHealthAsync(ct);
    var response = ApiResponse<OverallHealthResult>.Ok(
        result,
        result.Supabase.Success
            ? "Keep-alive pulse completed successfully"
            : "Supabase keep-alive ping returned non-success");
    return Results.Ok(response);
});

app.Run();

// Required for WebApplicationFactory integration testing
public partial class Program { }
