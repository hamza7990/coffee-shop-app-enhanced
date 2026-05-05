using CoffeeShopAPI.Data;
using CoffeeShopAPI.DTOs;
using CoffeeShopAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace CoffeeShopAPI.Services;

public class AdminService : IAdminService
{
    private readonly AppDbContext _db;

    public AdminService(AppDbContext db) => _db = db;

    public async Task<List<UserDto>> GetAllUsersAsync()
    {
        var users = await _db.Users
            .AsNoTracking()
            .OrderByDescending(u => u.CreatedAt)
            .ToListAsync();

        return users.Select(MapToDto).ToList();
    }

    public async Task<UserDto?> GetUserByIdAsync(int id)
    {
        var user = await _db.Users.FindAsync(id);
        return user == null ? null : MapToDto(user);
    }

    public async Task<UserDto?> UpdateUserRoleAsync(int id, UpdateUserRoleRequest request)
    {
        var user = await _db.Users.FindAsync(id);
        if (user == null) return null;

        // Prevent removing the last admin
        if (user.Role == UserRole.Admin && request.Role != UserRole.Admin)
        {
            var adminCount = await _db.Users.CountAsync(u => u.Role == UserRole.Admin && u.IsActive);
            if (adminCount <= 1)
                throw new InvalidOperationException("Cannot demote the last active admin.");
        }

        user.Role = request.Role;
        await _db.SaveChangesAsync();
        return MapToDto(user);
    }

    public async Task<bool> DeleteUserAsync(int id)
    {
        var user = await _db.Users.FindAsync(id);
        if (user == null) return false;

        // Prevent deleting the last admin
        if (user.Role == UserRole.Admin)
        {
            var adminCount = await _db.Users.CountAsync(u => u.Role == UserRole.Admin && u.IsActive);
            if (adminCount <= 1)
                throw new InvalidOperationException("Cannot delete the last active admin.");
        }

        // Soft delete: deactivate account
        user.IsActive = false;
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> LockUserAsync(int id, LockUserRequest request)
    {
        var user = await _db.Users.FindAsync(id);
        if (user == null) return false;

        if (user.Role == UserRole.Admin)
            throw new InvalidOperationException("Cannot lock an admin account.");

        if (request.Lock)
        {
            user.LockedUntil = request.Minutes.HasValue
                ? DateTime.UtcNow.AddMinutes(request.Minutes.Value)
                : DateTime.UtcNow.AddHours(24);
        }
        else
        {
            user.LockedUntil = null;
        }

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
