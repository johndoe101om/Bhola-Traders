using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AgriLedger.API.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Parties",
                columns: table => new
                {
                    Id = table.Column<string>(type: "TEXT", maxLength: 36, nullable: false),
                    Name = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    PartyType = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    Phone = table.Column<string>(type: "TEXT", maxLength: 15, nullable: true),
                    Village = table.Column<string>(type: "TEXT", maxLength: 100, nullable: true),
                    Notes = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false, defaultValue: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    SyncedAt = table.Column<DateTime>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Parties", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SyncQueue",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    EntityType = table.Column<string>(type: "TEXT", maxLength: 30, nullable: false),
                    EntityId = table.Column<string>(type: "TEXT", maxLength: 36, nullable: false),
                    Operation = table.Column<string>(type: "TEXT", maxLength: 10, nullable: false),
                    Payload = table.Column<string>(type: "TEXT", nullable: false),
                    RetryCount = table.Column<int>(type: "INTEGER", nullable: false, defaultValue: 0),
                    LastError = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ProcessedAt = table.Column<DateTime>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SyncQueue", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Transactions",
                columns: table => new
                {
                    Id = table.Column<string>(type: "TEXT", maxLength: 36, nullable: false),
                    PartyId = table.Column<string>(type: "TEXT", maxLength: 36, nullable: false),
                    TxnType = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    Commodity = table.Column<string>(type: "TEXT", maxLength: 20, nullable: true),
                    QuantityKg = table.Column<decimal>(type: "TEXT", precision: 10, scale: 3, nullable: true),
                    RatePerKg = table.Column<decimal>(type: "TEXT", precision: 10, scale: 2, nullable: true),
                    Amount = table.Column<decimal>(type: "TEXT", precision: 12, scale: 2, nullable: false),
                    Direction = table.Column<string>(type: "TEXT", maxLength: 5, nullable: false),
                    PaymentMode = table.Column<string>(type: "TEXT", maxLength: 10, nullable: false, defaultValue: "cash"),
                    Notes = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    VoiceRaw = table.Column<string>(type: "TEXT", maxLength: 1000, nullable: true),
                    EntryDate = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    SyncedAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    IsDeleted = table.Column<bool>(type: "INTEGER", nullable: false, defaultValue: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Transactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Transactions_Parties_PartyId",
                        column: x => x.PartyId,
                        principalTable: "Parties",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "BagMovements",
                columns: table => new
                {
                    Id = table.Column<string>(type: "TEXT", maxLength: 36, nullable: false),
                    PartyId = table.Column<string>(type: "TEXT", maxLength: 36, nullable: false),
                    Movement = table.Column<string>(type: "TEXT", maxLength: 10, nullable: false),
                    Quantity = table.Column<int>(type: "INTEGER", nullable: false),
                    LinkedTxnId = table.Column<string>(type: "TEXT", maxLength: 36, nullable: true),
                    Notes = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    EntryDate = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    SyncedAt = table.Column<DateTime>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BagMovements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BagMovements_Parties_PartyId",
                        column: x => x.PartyId,
                        principalTable: "Parties",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_BagMovements_Transactions_LinkedTxnId",
                        column: x => x.LinkedTxnId,
                        principalTable: "Transactions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            // ── INDEXES ────────────────────────────────────────────────
            migrationBuilder.CreateIndex(name: "IX_Parties_Name",      table: "Parties",      column: "Name");
            migrationBuilder.CreateIndex(name: "IX_Parties_Village",   table: "Parties",      column: "Village");
            migrationBuilder.CreateIndex(name: "IX_Parties_PartyType", table: "Parties",      column: "PartyType");
            migrationBuilder.CreateIndex(name: "IX_Parties_IsActive",  table: "Parties",      column: "IsActive");

            migrationBuilder.CreateIndex(name: "IX_Transactions_PartyId",   table: "Transactions", column: "PartyId");
            migrationBuilder.CreateIndex(name: "IX_Transactions_EntryDate", table: "Transactions", column: "EntryDate");
            migrationBuilder.CreateIndex(name: "IX_Transactions_TxnType",   table: "Transactions", column: "TxnType");
            migrationBuilder.CreateIndex(name: "IX_Transactions_IsDeleted", table: "Transactions", column: "IsDeleted");

            migrationBuilder.CreateIndex(name: "IX_BagMovements_PartyId",   table: "BagMovements", column: "PartyId");
            migrationBuilder.CreateIndex(name: "IX_BagMovements_EntryDate", table: "BagMovements", column: "EntryDate");
            migrationBuilder.CreateIndex(name: "IX_BagMovements_LinkedTxnId", table: "BagMovements", column: "LinkedTxnId");

            migrationBuilder.CreateIndex(name: "IX_SyncQueue_EntityType_CreatedAt", table: "SyncQueue",
                columns: new[] { "EntityType", "CreatedAt" });
            migrationBuilder.CreateIndex(name: "IX_SyncQueue_ProcessedAt", table: "SyncQueue", column: "ProcessedAt");

            // ── SEED DATA ──────────────────────────────────────────────
            migrationBuilder.InsertData(
                table: "Parties",
                columns: new[] { "Id", "Name", "PartyType", "Village", "IsActive", "CreatedAt", "UpdatedAt" },
                values: new object[]
                {
                    "00000000-0000-0000-0000-000000000001",
                    "Demo Farmer",
                    "farmer",
                    "Demo Village",
                    true,
                    new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                    new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "BagMovements");
            migrationBuilder.DropTable(name: "Transactions");
            migrationBuilder.DropTable(name: "SyncQueue");
            migrationBuilder.DropTable(name: "Parties");
        }
    }
}
