using AgriLedger.API.Data;
using AgriLedger.API.Middleware;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ── SERVICES ──────────────────────────────────────────────────────────

builder.Services.AddControllers()
    .AddJsonOptions(opts =>
    {
        // Use camelCase in JSON responses
        opts.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        // Include nulls so mobile app gets predictable shape
        opts.JsonSerializerOptions.DefaultIgnoreCondition =
            System.Text.Json.Serialization.JsonIgnoreCondition.Never;
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
    // Phase 2: Uncomment when moving to PostgreSQL
    builder.Services.AddDbContext<AppDbContext>(opt =>
        opt.UseNpgsql(
            builder.Configuration.GetConnectionString("PostgreSQL"),
            npg => npg.MigrationsAssembly("AgriLedger.API")
        ));
}
else
{
    // Phase 1: SQLite
    var dbPath = builder.Configuration["Database:SqlitePath"] ?? "agriledger.db";
    builder.Services.AddDbContext<AppDbContext>(opt =>
        opt.UseSqlite(
            $"Data Source={dbPath}",
            sql => sql.MigrationsAssembly("AgriLedger.API")
        ));
}

// ── CORS (for testing from browser/Postman) ───────────────────────────
builder.Services.AddCors(opt =>
{
    opt.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader());
});

// ── BUILD ─────────────────────────────────────────────────────────────
var app = builder.Build();

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
app.MapGet("/health", () => new
{
    status = "ok",
    timestamp = DateTime.UtcNow,
    version = "1.0.0"
});

app.Run();
