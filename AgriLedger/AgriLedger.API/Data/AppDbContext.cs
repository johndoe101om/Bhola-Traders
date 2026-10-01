using AgriLedger.API.Models;
using Microsoft.EntityFrameworkCore;

namespace AgriLedger.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Party> Parties => Set<Party>();
    public DbSet<Transaction> Transactions => Set<Transaction>();
    public DbSet<BagMovement> BagMovements => Set<BagMovement>();
    public DbSet<SyncQueueItem> SyncQueue => Set<SyncQueueItem>();
    public DbSet<Employee> Employees => Set<Employee>();
    public DbSet<Attendance> Attendances => Set<Attendance>();
    public DbSet<EmployeePayment> EmployeePayments => Set<EmployeePayment>();

    protected override void OnModelCreating(ModelBuilder mb)
    {
        // ── PARTY ──────────────────────────────────────────────────────
        mb.Entity<Party>(e =>
        {
            e.HasKey(p => p.Id);
            e.Property(p => p.Id).HasMaxLength(36);
            e.Property(p => p.Name).HasMaxLength(200).IsRequired();
            e.Property(p => p.PartyType).HasMaxLength(20).IsRequired();
            e.Property(p => p.Phone).HasMaxLength(15);
            e.Property(p => p.Village).HasMaxLength(100);
            e.Property(p => p.Notes).HasMaxLength(500);

            e.HasIndex(p => p.Name);
            e.HasIndex(p => p.Village);
            e.HasIndex(p => p.PartyType);
            e.HasIndex(p => p.IsActive);

            // Seed data: one demo party
            e.HasData(new Party
            {
                Id = "00000000-0000-0000-0000-000000000001",
                Name = "Demo Farmer",
                PartyType = "farmer",
                Village = "Demo Village",
                IsActive = true,
                CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                UpdatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            });
        });

        // ── TRANSACTION ────────────────────────────────────────────────
        mb.Entity<Transaction>(e =>
        {
            e.HasKey(t => t.Id);
            e.Property(t => t.Id).HasMaxLength(36);
            e.Property(t => t.PartyId).HasMaxLength(36).IsRequired();
            e.Property(t => t.TxnType).HasMaxLength(20).IsRequired();
            e.Property(t => t.Commodity).HasMaxLength(20);
            e.Property(t => t.QuantityKg).HasPrecision(10, 3);
            e.Property(t => t.RatePerKg).HasPrecision(10, 2);
            e.Property(t => t.Amount).HasPrecision(12, 2).IsRequired();
            e.Property(t => t.Direction).HasMaxLength(5).IsRequired();
            e.Property(t => t.PaymentMode).HasMaxLength(10).HasDefaultValue("cash");
            e.Property(t => t.Notes).HasMaxLength(500);
            e.Property(t => t.VoiceRaw).HasMaxLength(1000);

            e.HasIndex(t => t.PartyId);
            e.HasIndex(t => t.EntryDate);
            e.HasIndex(t => t.TxnType);
            e.HasIndex(t => t.IsDeleted);

            e.HasOne(t => t.Party)
             .WithMany(p => p.Transactions)
             .HasForeignKey(t => t.PartyId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── BAG MOVEMENT ───────────────────────────────────────────────
        mb.Entity<BagMovement>(e =>
        {
            e.HasKey(b => b.Id);
            e.Property(b => b.Id).HasMaxLength(36);
            e.Property(b => b.PartyId).HasMaxLength(36).IsRequired();
            e.Property(b => b.Movement).HasMaxLength(10).IsRequired();
            e.Property(b => b.LinkedTxnId).HasMaxLength(36);
            e.Property(b => b.Notes).HasMaxLength(500);

            e.HasIndex(b => b.PartyId);
            e.HasIndex(b => b.EntryDate);

            e.HasOne(b => b.Party)
             .WithMany(p => p.BagMovements)
             .HasForeignKey(b => b.PartyId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(b => b.LinkedTransaction)
             .WithMany()
             .HasForeignKey(b => b.LinkedTxnId)
             .OnDelete(DeleteBehavior.SetNull)
             .IsRequired(false);
        });

        // ── SYNC QUEUE ─────────────────────────────────────────────────
        mb.Entity<SyncQueueItem>(e =>
        {
            e.HasKey(s => s.Id);
            e.Property(s => s.EntityType).HasMaxLength(30).IsRequired();
            e.Property(s => s.EntityId).HasMaxLength(36).IsRequired();
            e.Property(s => s.Operation).HasMaxLength(10).IsRequired();
            e.Property(s => s.LastError).HasMaxLength(500);

            e.HasIndex(s => new { s.EntityType, s.CreatedAt });
            e.HasIndex(s => s.ProcessedAt);
        });

        // ── EMPLOYEE ───────────────────────────────────────────────────
        mb.Entity<Employee>(e =>
        {
            e.HasKey(emp => emp.Id);
            e.Property(emp => emp.Id).HasMaxLength(36);
            e.Property(emp => emp.Name).HasMaxLength(200).IsRequired();
            e.Property(emp => emp.Phone).HasMaxLength(15);
            e.Property(emp => emp.Email).HasMaxLength(100);
            e.Property(emp => emp.DailyWageRate).HasPrecision(10, 2);
            e.Property(emp => emp.AadhaarNumber).HasMaxLength(20);
            e.Property(emp => emp.Address).HasMaxLength(500);
            e.Property(emp => emp.EmployeeType).HasMaxLength(20).IsRequired();
            e.Property(emp => emp.TeamGroup).HasMaxLength(50);
            e.Property(emp => emp.EmergencyContact).HasMaxLength(100);
            e.Property(emp => emp.Notes).HasMaxLength(500);

            e.HasIndex(emp => emp.Name);
            e.HasIndex(emp => emp.EmployeeType);
            e.HasIndex(emp => emp.TeamGroup);
            e.HasIndex(emp => emp.IsActive);
        });

        // ── ATTENDANCE ─────────────────────────────────────────────────
        mb.Entity<Attendance>(e =>
        {
            e.HasKey(a => a.Id);
            e.Property(a => a.Id).HasMaxLength(36);
            e.Property(a => a.EmployeeId).HasMaxLength(36).IsRequired();
            e.Property(a => a.Status).HasMaxLength(20).IsRequired();
            e.Property(a => a.AbsenceReason).HasMaxLength(1000);
            e.Property(a => a.VoiceRaw).HasMaxLength(1000);
            e.Property(a => a.OvertimeHours).HasPrecision(5, 2);
            e.Property(a => a.Notes).HasMaxLength(500);

            e.HasIndex(a => new { a.EmployeeId, a.AttendanceDate }).IsUnique();
            e.HasIndex(a => a.AttendanceDate);
            e.HasIndex(a => a.Status);

            e.HasOne(a => a.Employee)
             .WithMany(emp => emp.Attendances)
             .HasForeignKey(a => a.EmployeeId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ── EMPLOYEE PAYMENT ───────────────────────────────────────────
        mb.Entity<EmployeePayment>(e =>
        {
            e.HasKey(ep => ep.Id);
            e.Property(ep => ep.Id).HasMaxLength(36);
            e.Property(ep => ep.EmployeeId).HasMaxLength(36).IsRequired();
            e.Property(ep => ep.Amount).HasPrecision(12, 2).IsRequired();
            e.Property(ep => ep.PaymentMode).HasMaxLength(20).IsRequired();
            e.Property(ep => ep.PaymentType).HasMaxLength(20).IsRequired();
            e.Property(ep => ep.ReferenceNumber).HasMaxLength(100);
            e.Property(ep => ep.Notes).HasMaxLength(500);
            e.Property(ep => ep.VoiceRaw).HasMaxLength(1000);

            e.HasIndex(ep => ep.EmployeeId);
            e.HasIndex(ep => ep.PaymentDate);
            e.HasIndex(ep => ep.PaymentType);

            e.HasOne(ep => ep.Employee)
             .WithMany(emp => emp.EmployeePayments)
             .HasForeignKey(ep => ep.EmployeeId)
             .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
