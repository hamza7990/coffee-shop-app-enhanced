using CoffeeShopAPI.DTOs;
using CoffeeShopAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CoffeeShopAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;
    private readonly IWebHostEnvironment _env;

    public AuthController(IAuthService authService, ILogger<AuthController> logger, IWebHostEnvironment env)
    {
        _authService = authService;
        _logger      = logger;
        _env         = env;
    }

    /// <summary>POST /api/auth/login — Returns JWT token</summary>
    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<AuthResponse>>> Login([FromBody] LoginRequest request)
    {
        try
        {
            var result = await _authService.LoginAsync(request);
            if (result == null)
                return Unauthorized(ApiResponse<AuthResponse>.Fail("Invalid email or password."));

            return Ok(ApiResponse<AuthResponse>.Ok(result, "Login successful."));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[LOGIN] Unhandled exception during login for {Email}", request.Email);

            var msg = _env.IsDevelopment()
                ? $"Login failed: {ex.Message}"
                : "Login service unavailable. Please try again later.";

            return StatusCode(500, ApiResponse<AuthResponse>.Fail(msg));
        }
    }

    /// <summary>POST /api/auth/register — Public registration</summary>
    [HttpPost("register")]
    public async Task<ActionResult<ApiResponse<AuthResponse>>> Register([FromBody] RegisterRequest request)
    {
        var result = await _authService.RegisterAsync(request);
        if (result == null)
            return BadRequest(ApiResponse<UserDto>.Fail("Email already in use."));

        // Auto-login after registration
        var loginResult = await _authService.LoginAsync(new LoginRequest
        {
            Email = request.Email,
            Password = request.Password
        });

        return Ok(ApiResponse<AuthResponse>.Ok(loginResult!, "Registration successful. Welcome to Brewhaus!"));
    }

    /// <summary>POST /api/auth/forgot-password — Request password reset</summary>
    [HttpPost("forgot-password")]
    public async Task<ActionResult<ApiResponse<object>>> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        await _authService.ForgotPasswordAsync(request);
        // Always return success to prevent email enumeration
        return Ok(ApiResponse<object>.Ok(new { }, "If this email exists, a reset link has been sent."));
    }

    /// <summary>POST /api/auth/reset-password — Reset password with token</summary>
    [HttpPost("reset-password")]
    public async Task<ActionResult<ApiResponse<object>>> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        var success = await _authService.ResetPasswordAsync(request);
        if (!success)
            return BadRequest(ApiResponse<object>.Fail("Invalid or expired token."));

        return Ok(ApiResponse<object>.Ok(new { }, "Password reset successful. Please log in with your new password."));
    }

    /// <summary>GET /api/auth/me — Returns current user profile</summary>
    [HttpGet("me")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<UserDto>>> Me()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var user   = await _authService.GetUserByIdAsync(userId);
        if (user == null) return NotFound(ApiResponse<UserDto>.Fail("User not found."));

        return Ok(ApiResponse<UserDto>.Ok(user));
    }
}
