using CoffeeShopAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace CoffeeShopAPI.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User>        Users        { get; set; }
    public DbSet<Category>    Categories   { get; set; }
    public DbSet<MenuItem>    MenuItems    { get; set; }
    public DbSet<Table>       Tables       { get; set; } = null!;
    public DbSet<Reservation> Reservations { get; set; } = null!;
    public DbSet<Order>       Orders       { get; set; } = null!;
    public DbSet<OrderItem>   OrderItems   { get; set; } = null!;
    public DbSet<PasswordResetToken> PasswordResetTokens { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ── Enum conversions ───────────────────────────────────────────────────
        modelBuilder.Entity<User>()
            .Property(u => u.Role)
            .HasConversion<string>();

        // ── Unique constraints ─────────────────────────────────────────────────
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email).IsUnique();

        modelBuilder.Entity<Table>()
            .HasIndex(t => t.TableNumber).IsUnique();

        // ── Order → Table (optional FK) ────────────────────────────────────────
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Table)
            .WithMany(t => t.Orders)
            .HasForeignKey(o => o.TableId)
            .OnDelete(DeleteBehavior.SetNull);

        // ── Order → Cashier ────────────────────────────────────────────────────
        modelBuilder.Entity<Order>()
            .HasOne(o => o.Cashier)
            .WithMany()
            .HasForeignKey(o => o.CashierId)
            .OnDelete(DeleteBehavior.Restrict);

        // ── Seed default admin user (deterministic BCrypt hash) ──────────────────
        // Pre-computed hash for "Ch@ngeMe#2024!" – change via env/config in production
        var adminPasswordHash = "$2a$11$vQL5XTpT1V1RXJ5G0rZUGO0v9q.JQtuZgWpW.KZoJhKq6pP.W/0LW";
        modelBuilder.Entity<User>().HasData(new User
        {
            Id       = 1,
            Name     = "System Admin",
            Email    = "admin@brewhaus.com",
            Password = adminPasswordHash,
            Role     = UserRole.Admin,
            IsActive = true,
            CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        });

        // ── Seed categories ────────────────────────────────────────────────────
        modelBuilder.Entity<Category>().HasData(
            new Category { Id = 1, Name = "Hot Drinks",   IsActive = true },
            new Category { Id = 2, Name = "Cold Drinks",  IsActive = true },
            new Category { Id = 3, Name = "Food & Snacks", IsActive = true }
        );
    }
}
