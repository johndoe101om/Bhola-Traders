using Microsoft.AspNetCore.Mvc;
using AgriLedger.API.DTOs;

namespace AgriLedger.API.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[Produces("application/json")]
public class AuthController : ControllerBase
{
    private readonly IConfiguration _config;

    public AuthController(IConfiguration config) => _config = config;

    // ── POST /api/v1/auth/verify ──────────────────────────────────────
    /// <summary>Verify PIN before using the app. Returns ok/fail.</summary>
    [HttpPost("verify")]
    public ActionResult<ApiResponse<object>> VerifyPin([FromBody] PinVerifyRequest req)
    {
        var expected = _config["Auth:Pin"] ?? "1234";
        if (req.Pin == expected)
            return Ok(ApiResponse<object>.Ok(new { verified = true }, "PIN correct."));

        return Unauthorized(ApiResponse<object>.Fail("Incorrect PIN."));
    }
}

public class PinVerifyRequest
{
    public string Pin { get; set; } = "";
}
