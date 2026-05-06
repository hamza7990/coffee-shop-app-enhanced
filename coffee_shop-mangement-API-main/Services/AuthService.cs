using CoffeeShopAPI.Data;
using CoffeeShopAPI.DTOs;
using CoffeeShopAPI.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace CoffeeShopAPI.Services;

// ── Token Service ─────────────────────────────────────────────────────────────
public class TokenService : ITokenService
{
    private readonly IConfiguration _config;

    public TokenService(IConfiguration config) => _config = config;

    public string GenerateToken(User user)
    {
        var key     = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
        var creds   = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expiry  = int.Parse(_config["Jwt:ExpiryInMinutes"] ?? "1440");

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub,   user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(ClaimTypes.Name,               user.Name),
            new Claim(ClaimTypes.Role,               user.Role.ToString()),
            new Claim("isActive",                    user.IsActive.ToString().ToLowerInvariant()),
            new Claim(JwtRegisteredClaimNames.Jti,   Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer:             _config["Jwt:Issuer"],
            audience:           _config["Jwt:Audience"],
            claims:             claims,
            expires:            DateTime.UtcNow.AddMinutes(expiry),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

// ── Auth Service ──────────────────────────────────────────────────────────────
public class AuthService : IAuthService
{
    private readonly AppDbContext  _db;
    private readonly ITokenService _tokenService;
    private readonly IConfiguration _config;
    private readonly IEmailService _emailService;
    private readonly ILogger<AuthService> _logger;

    public AuthService(AppDbContext db, ITokenService tokenService, IConfiguration config, IEmailService emailService, ILogger<AuthService> logger)
    {
        _db           = db;
        _tokenService = tokenService;
        _config       = config;
        _emailService = emailService;
        _logger       = logger;
    }

    public async Task<AuthResponse?> LoginAsync(LoginRequest request)
    {
        var email = request.Email.Trim();
        _logger.LogInformation("[LOGIN] Attempt for email: {Email}", email);

        var user = await _db.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Email == email);

        if (user == null)
        {
            _logger.LogWarning("[LOGIN] FAIL — user not found: {Email}", email);
            return null;
        }

        _logger.LogInformation(
            "[LOGIN] User found — Id:{UserId} Active:{IsActive} LockedUntil:{LockedUntil} Role:{Role} HashLength:{HashLen}",
            user.Id, user.IsActive, user.LockedUntil, user.Role, user.Password?.Length ?? 0);

        // ── Defensive: null/empty hash ───────────────────────────────────────
        var storedHash = user.Password?.Trim();
        if (string.IsNullOrWhiteSpace(storedHash))
        {
            _logger.LogError("[LOGIN] FAIL — stored password hash is null/empty for UserId:{UserId}", user.Id);
            return null;
        }

        // ── Account status checks (before password to avoid timing leaks) ──────
        if (!user.IsActive)
        {
            _logger.LogWarning("[LOGIN] FAIL — account deactivated for UserId:{UserId}", user.Id);
            return null;
        }

        if (user.LockedUntil.HasValue && user.LockedUntil.Value > DateTime.UtcNow)
        {
            _logger.LogWarning("[LOGIN] FAIL — account locked until {LockedUntil} for UserId:{UserId}",
                user.LockedUntil.Value, user.Id);
            return null;
        }

        // ── BCrypt verification with bullet-proof exception handling ───────────
        bool passwordValid;
        try
        {
            passwordValid = BCrypt.Net.BCrypt.Verify(request.Password, storedHash);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "[LOGIN] FAIL — BCrypt exception for UserId:{UserId}. " +
                "Type:{ExType} HashPrefix:{Prefix} HashLength:{Len}",
                user.Id, ex.GetType().Name,
                storedHash.Length >= 7 ? storedHash[..7] : storedHash,
                storedHash.Length);
            return null;
        }

        if (!passwordValid)
        {
            _logger.LogWarning("[LOGIN] FAIL — incorrect password for UserId:{UserId}", user.Id);
            return null;
        }

        _logger.LogInformation("[LOGIN] SUCCESS — UserId:{UserId} Email:{Email}", user.Id, email);

        var token  = _tokenService.GenerateToken(user);
        var expiry = int.Parse(_config["Jwt:ExpiryInMinutes"] ?? "1440");

        return new AuthResponse
        {
            Token     = token,
            TokenType = "Bearer",
            ExpiresIn = expiry * 60,
            User      = MapToDto(user)
        };
    }

    public async Task<UserDto?> RegisterAsync(RegisterRequest request)
    {
        var exists = await _db.Users.AnyAsync(u => u.Email == request.Email);
        if (exists) return null;

        var user = new User
        {
            Name     = request.Name,
            Email    = request.Email,
            Password = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role     = UserRole.User // Never allow role selection during public registration
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();
        return MapToDto(user);
    }

    public async Task<UserDto?> GetUserByIdAsync(int id)
    {
        var user = await _db.Users.FindAsync(id);
        return user == null ? null : MapToDto(user);
    }

    public async Task<bool> ForgotPasswordAsync(ForgotPasswordRequest request)
    {
        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Email == request.Email && u.IsActive);

        if (user == null) return true; // Don't reveal if email exists

        // Generate secure random token
        var token = Convert.ToHexString(System.Security.Cryptography.RandomNumberGenerator.GetBytes(32));

        // Save token with expiration (1 hour)
        var resetToken = new PasswordResetToken
        {
            Token = token,
            Email = request.Email,
            UserId = user.Id,
            ExpiresAt = DateTime.UtcNow.AddHours(1)
        };

        _db.PasswordResetTokens.Add(resetToken);
        await _db.SaveChangesAsync();

        // Send email
        await _emailService.SendPasswordResetEmailAsync(request.Email, token, user.Name);
        return true;
    }

    public async Task<bool> ResetPasswordAsync(ResetPasswordRequest request)
    {
        var resetToken = await _db.PasswordResetTokens
            .FirstOrDefaultAsync(t => t.Token == request.Token && !t.IsUsed && t.ExpiresAt > DateTime.UtcNow);

        if (resetToken == null) return false;

        var user = await _db.Users.FindAsync(resetToken.UserId);
        if (user == null) return false;

        // Update password
        user.Password = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);

        // Mark token as used
        resetToken.IsUsed = true;

        await _db.SaveChangesAsync();
        return true;
    }

    private static UserDto MapToDto(User u) =>
        new()
        {
            Id = u.Id,
            Name = u.Name,
            Email = u.Email,
            Role = u.Role,
            IsActive = u.IsActive,
            LockedUntil = u.LockedUntil,
            CreatedAt = u.CreatedAt
        };
}
