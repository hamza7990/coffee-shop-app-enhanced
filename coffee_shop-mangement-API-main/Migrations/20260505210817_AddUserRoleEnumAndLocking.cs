using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CoffeeShopAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddUserRoleEnumAndLocking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "LockedUntil",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 5, 5, 21, 8, 13, 750, DateTimeKind.Utc).AddTicks(1820));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 5, 5, 21, 8, 13, 750, DateTimeKind.Utc).AddTicks(1824));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 5, 5, 21, 8, 13, 750, DateTimeKind.Utc).AddTicks(1825));

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "CreatedAt", "LockedUntil", "Name", "Password" },
                values: new object[] { new DateTime(2024, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, "System Admin", "$2a$11$vQL5XTpT1V1RXJ5G0rZUGO0v9q.JQtuZgWpW.KZoJhKq6pP.W/0LW" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LockedUntil",
                table: "Users");

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 1,
                column: "CreatedAt",
                value: new DateTime(2026, 5, 4, 17, 31, 18, 999, DateTimeKind.Utc).AddTicks(3122));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 2,
                column: "CreatedAt",
                value: new DateTime(2026, 5, 4, 17, 31, 18, 999, DateTimeKind.Utc).AddTicks(3131));

            migrationBuilder.UpdateData(
                table: "Categories",
                keyColumn: "Id",
                keyValue: 3,
                column: "CreatedAt",
                value: new DateTime(2026, 5, 4, 17, 31, 18, 999, DateTimeKind.Utc).AddTicks(3133));

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1,
                columns: new[] { "CreatedAt", "Name", "Password" },
                values: new object[] { new DateTime(2026, 5, 4, 17, 31, 18, 697, DateTimeKind.Utc).AddTicks(7940), "Admin", "$2a$11$2LnNbogFOt5hV6ZeljHbVOA9x3xoC6Pnhh5IPijgacTbnN6Of6zwe" });
        }
    }
}
