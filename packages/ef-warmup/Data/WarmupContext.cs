using Microsoft.EntityFrameworkCore;

public class WarmupContext : DbContext
{
    public WarmupContext(DbContextOptions<WarmupContext> options) : base(options) { }
    public DbSet<WarmupModel> Models { get; set; }
} 