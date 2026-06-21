namespace UISampleSpark.Core.Models.Data;

public class EmployeeContext : DbContext
{
    public EmployeeContext() : base()
    {
    }

    public EmployeeContext(DbContextOptions<Data.EmployeeContext> options) : base(options)
    {
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        ArgumentNullException.ThrowIfNull(optionsBuilder);

        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseInMemoryDatabase("Employee");
        }

        optionsBuilder.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        ArgumentNullException.ThrowIfNull(modelBuilder);

        modelBuilder.Entity<Data.Employee>(entity =>
        {
            entity.HasKey(e => e.Id);
            
            entity.HasOne(e => e.Department)
                .WithMany(d => d.Employees)
                .HasForeignKey(e => e.DepartmentId)
                .IsRequired()
                .OnDelete(DeleteBehavior.Restrict);

            entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(e => e.State)
                .HasMaxLength(2);

            entity.Property(e => e.Country)
                .HasMaxLength(100);

            entity.HasIndex(e => e.Name);
        });

        modelBuilder.Entity<Data.Department>(entity =>
        {
            entity.HasKey(d => d.Id);

            entity.Property(d => d.Name)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(d => d.Description)
                .HasMaxLength(500);

            entity.HasIndex(d => d.Name)
                .IsUnique();
        });
    }

    public DbSet<Data.Employee> Employees => Set<Data.Employee>();
    public DbSet<Data.Department> Departments => Set<Data.Department>();
}
