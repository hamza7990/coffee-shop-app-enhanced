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

        // ── Seed default admin user ────────────────────────────────────────────
        modelBuilder.Entity<User>().HasData(new User
        {
            Id       = 1,
            Name     = "Admin",
            Email    = "admin@brewhaus.com",
            Password = BCrypt.Net.BCrypt.HashPassword("password"),
            Role     = "Admin",
            IsActive = true
        });

        // ── Seed categories ────────────────────────────────────────────────────
        modelBuilder.Entity<Category>().HasData(
            new Category { Id = 1, Name = "Hot Drinks",   IsActive = true },
            new Category { Id = 2, Name = "Cold Drinks",  IsActive = true },
            new Category { Id = 3, Name = "Food & Snacks", IsActive = true }
        );
    }
}
