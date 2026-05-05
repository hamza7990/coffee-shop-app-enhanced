using CoffeeShopAPI.DTOs;
using CoffeeShopAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CoffeeShopAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class UsersController : ControllerBase
{
    private readonly IAdminService _adminService;

    public UsersController(IAdminService adminService) => _adminService = adminService;

    /// <summary>GET /api/users — List all users</summary>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<UserDto>>>> GetUsers()
    {
        var users = await _adminService.GetAllUsersAsync();
        return Ok(ApiResponse<List<UserDto>>.Ok(users));
    }

    /// <summary>GET /api/users/{id} — Get single user</summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<UserDto>>> GetUser(int id)
    {
        var user = await _adminService.GetUserByIdAsync(id);
        if (user == null) return NotFound(ApiResponse<UserDto>.Fail("User not found."));
        return Ok(ApiResponse<UserDto>.Ok(user));
    }

    /// <summary>PATCH /api/users/{id}/role — Update user role</summary>
    [HttpPatch("{id}/role")]
    public async Task<ActionResult<ApiResponse<UserDto>>> UpdateRole(int id, [FromBody] UpdateUserRoleRequest request)
    {
        try
        {
            var user = await _adminService.UpdateUserRoleAsync(id, request);
            if (user == null) return NotFound(ApiResponse<UserDto>.Fail("User not found."));
            return Ok(ApiResponse<UserDto>.Ok(user, "Role updated successfully."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<UserDto>.Fail(ex.Message));
        }
    }

    /// <summary>PATCH /api/users/{id}/lock — Lock or unlock user</summary>
    [HttpPatch("{id}/lock")]
    public async Task<ActionResult<ApiResponse<object>>> LockUser(int id, [FromBody] LockUserRequest request)
    {
        try
        {
            var success = await _adminService.LockUserAsync(id, request);
            if (!success) return NotFound(ApiResponse<object>.Fail("User not found."));
            var msg = request.Lock ? "User locked successfully." : "User unlocked successfully.";
            return Ok(ApiResponse<object>.Ok(new { }, msg));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>DELETE /api/users/{id} — Deactivate user</summary>
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteUser(int id)
    {
        try
        {
            var success = await _adminService.DeleteUserAsync(id);
            if (!success) return NotFound(ApiResponse<object>.Fail("User not found."));
            return Ok(ApiResponse<object>.Ok(new { }, "User deactivated successfully."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }
}
