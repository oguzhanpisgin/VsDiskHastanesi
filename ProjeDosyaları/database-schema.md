# Veritabanı Şeması Dokümantasyonu

**Kaynak:** diskhastanesi.com projesi - Microsoft Stack'e taşıma için hazırlanmıştır

Bu dosya, tam veritabanı şemasını, ilişkileri, indexleri ve migration stratejisini içerir.

---

## 1. Genel Bakış

### 1.1 Current Stack (Supabase PostgreSQL)

**Database:** PostgreSQL 15.x
**Extensions:** uuid-ossp, pgcrypto, pg_stat_statements
**Row Level Security (RLS):** Enabled
**Backups:** Automated daily backups

### 1.2 Target Stack (Azure SQL)

**Database:** Azure SQL Database (Gen 5, 2 vCores)
**Tier:** General Purpose
**Backups:** Point-in-time restore (7 days)
**Geo-replication:** Optional (production)

### 1.3 Migration Strategy

**Approach:** Dual-write → Cutover → Decommission
**Tools:** 
- Current: Supabase CLI, SQL migrations
- Target: Entity Framework Core, Azure Data Migration Service

---

## 2. Entity Relationship Diagram

```
┌──────────────────┐         ┌──────────────────┐
│      leads       │         │      users       │
├──────────────────┤         ├──────────────────┤
│ id (PK)          │         │ id (PK)          │
│ name             │         │ email            │
│ email            │         │ password_hash    │
│ phone            │    ┌───▶│ role             │
│ company          │    │    │ created_at       │
│ service          │    │    │ updated_at       │
│ message          │    │    └──────────────────┘
│ status           │    │
│ assigned_to (FK) │────┘
│ created_at       │
│ updated_at       │
└──────────────────┘

┌──────────────────┐         ┌──────────────────┐
│ form_submissions │         │ consultations    │
├──────────────────┤         ├──────────────────┤
│ id (PK)          │         │ id (PK)          │
│ form_type        │         │ reference        │
│ data (JSONB)     │         │ name             │
│ ip_address       │         │ email            │
│ user_agent       │         │ phone            │
│ created_at       │         │ company          │
└──────────────────┘         │ topic            │
                              │ preferred_date   │
┌──────────────────┐         │ preferred_time   │
│   case_studies   │         │ message          │
├──────────────────┤         │ status           │
│ id (PK)          │         │ created_at       │
│ slug             │         │ updated_at       │
│ locale           │         └──────────────────┘
│ title            │
│ excerpt          │         ┌──────────────────┐
│ category         │         │  notifications   │
│ client           │         ├──────────────────┤
│ duration         │         │ id (PK)          │
│ data_size        │         │ type             │
│ problem          │         │ recipient        │
│ solution         │         │ channel          │
│ result           │         │ payload (JSONB)  │
│ images (JSONB)   │         │ status           │
│ related_services │         │ sent_at          │
│ published_at     │         │ created_at       │
│ updated_at       │         └──────────────────┘
└──────────────────┘

┌──────────────────┐         ┌──────────────────┐
│  content_pages   │         │   audit_logs     │
├──────────────────┤         ├──────────────────┤
│ id (PK)          │         │ id (PK)          │
│ slug             │         │ user_id (FK)     │
│ locale           │         │ action           │
│ title            │         │ entity_type      │
│ description      │         │ entity_id        │
│ content (JSONB)  │         │ changes (JSONB)  │
│ seo (JSONB)      │         │ ip_address       │
│ published_at     │         │ user_agent       │
│ updated_at       │         │ created_at       │
└──────────────────┘         └──────────────────┘
```

---

## 3. Table Definitions

### 3.1 leads

Lead (potansiyel müşteri) kayıtlarını tutar.

**Schema**
```sql
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    company VARCHAR(100),
    service VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'new',
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_assigned_to ON leads(assigned_to);
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX idx_leads_email ON leads(email);
CREATE INDEX idx_leads_service ON leads(service);

-- Full-text search (PostgreSQL)
CREATE INDEX idx_leads_search ON leads USING gin(
    to_tsvector('turkish', name || ' ' || email || ' ' || COALESCE(company, ''))
);
```

**C# Entity (Target)**
```csharp
public class Lead
{
    [Key]
    public Guid Id { get; set; }
    
    [Required, MaxLength(100)]
    public string Name { get; set; }
    
    [Required, EmailAddress, MaxLength(255)]
    public string Email { get; set; }
    
    [Required, Phone, MaxLength(20)]
    public string Phone { get; set; }
    
    [MaxLength(100)]
    public string? Company { get; set; }
    
    [Required, MaxLength(50)]
    public string Service { get; set; }
    
    [Required]
    public string Message { get; set; }
    
    [Required, MaxLength(20)]
    public string Status { get; set; } = "new";
    
    public Guid? AssignedTo { get; set; }
    
    [ForeignKey(nameof(AssignedTo))]
    public User? AssignedUser { get; set; }
    
    public string? Metadata { get; set; } // JSON string
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
```

**Status Values**
- `new`: Yeni lead
- `contacted`: İlk temas yapıldı
- `evaluating`: Değerlendiriliyor
- `proposal_sent`: Teklif gönderildi
- `won`: Kazanıldı
- `lost`: Kaybedildi

**Service Values**
- `veri-kurtarma`: Veri kurtarma
- `siber-guvenlik`: Siber güvenlik
- `sunucu-bakim`: Sunucu bakım
- `network-cozumleri`: Network çözümleri
- `disaster-recovery`: Disaster recovery

### 3.2 users

Sistem kullanıcıları (admin, sales, support).

**Schema**
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active);
```

**C# Entity (Target)**
```csharp
public class User
{
    [Key]
    public Guid Id { get; set; }
    
    [Required, EmailAddress, MaxLength(255)]
    public string Email { get; set; }
    
    [Required, MaxLength(255)]
    public string PasswordHash { get; set; }
    
    [Required, MaxLength(100)]
    public string FullName { get; set; }
    
    [Required, MaxLength(20)]
    public string Role { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public DateTime? LastLoginAt { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public ICollection<Lead> AssignedLeads { get; set; }
}
```

**Role Values**
- `admin`: Tam yetki
- `sales`: Satış ekibi
- `support`: Destek ekibi
- `viewer`: Sadece görüntüleme

### 3.3 form_submissions

Tüm form gönderimlerini log'lar (rate limiting, analytics).

**Schema**
```sql
CREATE TABLE form_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_type VARCHAR(50) NOT NULL,
    data JSONB NOT NULL,
    ip_address INET NOT NULL,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_form_submissions_form_type ON form_submissions(form_type);
CREATE INDEX idx_form_submissions_ip_address ON form_submissions(ip_address);
CREATE INDEX idx_form_submissions_created_at ON form_submissions(created_at DESC);
```

**C# Entity (Target)**
```csharp
public class FormSubmission
{
    [Key]
    public Guid Id { get; set; }
    
    [Required, MaxLength(50)]
    public string FormType { get; set; }
    
    [Required]
    public string Data { get; set; } // JSON string
    
    [Required]
    public string IpAddress { get; set; }
    
    public string? UserAgent { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

**Form Types**
- `lead`: Lead formu
- `contact`: İletişim formu
- `consultation`: Uzman görüşme talebi
- `quote`: Teklif formu

### 3.4 consultations

Uzman görüşme talepleri.

**Schema**
```sql
CREATE TABLE consultations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    company VARCHAR(100),
    topic VARCHAR(50) NOT NULL,
    preferred_date DATE NOT NULL,
    preferred_time TIME NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    meeting_url TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE UNIQUE INDEX idx_consultations_reference ON consultations(reference);
CREATE INDEX idx_consultations_status ON consultations(status);
CREATE INDEX idx_consultations_assigned_to ON consultations(assigned_to);
CREATE INDEX idx_consultations_preferred_date ON consultations(preferred_date);
CREATE INDEX idx_consultations_created_at ON consultations(created_at DESC);
```

**C# Entity (Target)**
```csharp
public class Consultation
{
    [Key]
    public Guid Id { get; set; }
    
    [Required, MaxLength(20)]
    public string Reference { get; set; }
    
    [Required, MaxLength(100)]
    public string Name { get; set; }
    
    [Required, EmailAddress, MaxLength(255)]
    public string Email { get; set; }
    
    [Required, Phone, MaxLength(20)]
    public string Phone { get; set; }
    
    [MaxLength(100)]
    public string? Company { get; set; }
    
    [Required, MaxLength(50)]
    public string Topic { get; set; }
    
    [Required]
    public DateOnly PreferredDate { get; set; }
    
    [Required]
    public TimeOnly PreferredTime { get; set; }
    
    [Required]
    public string Message { get; set; }
    
    [Required, MaxLength(20)]
    public string Status { get; set; } = "pending";
    
    public Guid? AssignedTo { get; set; }
    
    [ForeignKey(nameof(AssignedTo))]
    public User? AssignedUser { get; set; }
    
    public string? MeetingUrl { get; set; }
    
    public string? Notes { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
```

**Status Values**
- `pending`: Bekliyor
- `scheduled`: Planlandı
- `completed`: Tamamlandı
- `cancelled`: İptal edildi

### 3.5 case_studies

Vaka analizleri (başarı hikayeleri).

**Schema**
```sql
CREATE TABLE case_studies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(100) NOT NULL,
    locale VARCHAR(5) NOT NULL DEFAULT 'tr',
    title VARCHAR(200) NOT NULL,
    excerpt TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    client VARCHAR(100),
    duration VARCHAR(50),
    data_size VARCHAR(50),
    problem TEXT NOT NULL,
    solution TEXT NOT NULL,
    result TEXT NOT NULL,
    images JSONB DEFAULT '[]',
    related_services JSONB DEFAULT '[]',
    published_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(slug, locale)
);

-- Indexes
CREATE INDEX idx_case_studies_slug ON case_studies(slug);
CREATE INDEX idx_case_studies_locale ON case_studies(locale);
CREATE INDEX idx_case_studies_category ON case_studies(category);
CREATE INDEX idx_case_studies_published_at ON case_studies(published_at DESC);

-- Full-text search (PostgreSQL)
CREATE INDEX idx_case_studies_search ON case_studies USING gin(
    to_tsvector('turkish', title || ' ' || excerpt || ' ' || problem)
);
```

**C# Entity (Target)**
```csharp
public class CaseStudy
{
    [Key]
    public Guid Id { get; set; }
    
    [Required, MaxLength(100)]
    public string Slug { get; set; }
    
    [Required, MaxLength(5)]
    public string Locale { get; set; } = "tr";
    
    [Required, MaxLength(200)]
    public string Title { get; set; }
    
    [Required]
    public string Excerpt { get; set; }
    
    [Required, MaxLength(50)]
    public string Category { get; set; }
    
    [MaxLength(100)]
    public string? Client { get; set; }
    
    [MaxLength(50)]
    public string? Duration { get; set; }
    
    [MaxLength(50)]
    public string? DataSize { get; set; }
    
    [Required]
    public string Problem { get; set; }
    
    [Required]
    public string Solution { get; set; }
    
    [Required]
    public string Result { get; set; }
    
    public string? Images { get; set; } // JSON array
    
    public string? RelatedServices { get; set; } // JSON array
    
    public DateTime? PublishedAt { get; set; }
    
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
```

### 3.6 content_pages

CMS sayfa içerikleri.

**Schema**
```sql
CREATE TABLE content_pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(100) NOT NULL,
    locale VARCHAR(5) NOT NULL DEFAULT 'tr',
    title VARCHAR(200) NOT NULL,
    description TEXT,
    content JSONB NOT NULL,
    seo JSONB DEFAULT '{}',
    published_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(slug, locale)
);

-- Indexes
CREATE INDEX idx_content_pages_slug ON content_pages(slug);
CREATE INDEX idx_content_pages_locale ON content_pages(locale);
CREATE INDEX idx_content_pages_published_at ON content_pages(published_at DESC);
```

**C# Entity (Target)**
```csharp
public class ContentPage
{
    [Key]
    public Guid Id { get; set; }
    
    [Required, MaxLength(100)]
    public string Slug { get; set; }
    
    [Required, MaxLength(5)]
    public string Locale { get; set; } = "tr";
    
    [Required, MaxLength(200)]
    public string Title { get; set; }
    
    public string? Description { get; set; }
    
    [Required]
    public string Content { get; set; } // JSON string
    
    public string? Seo { get; set; } // JSON string
    
    public DateTime? PublishedAt { get; set; }
    
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
```

### 3.7 notifications

Bildirim logları (email, SMS, Slack).

**Schema**
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_channel ON notifications(channel);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
```

**C# Entity (Target)**
```csharp
public class Notification
{
    [Key]
    public Guid Id { get; set; }
    
    [Required, MaxLength(50)]
    public string Type { get; set; }
    
    [Required, MaxLength(255)]
    public string Recipient { get; set; }
    
    [Required, MaxLength(20)]
    public string Channel { get; set; }
    
    [Required]
    public string Payload { get; set; } // JSON string
    
    [Required, MaxLength(20)]
    public string Status { get; set; } = "pending";
    
    public string? ErrorMessage { get; set; }
    
    public DateTime? SentAt { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

**Type Values**
- `lead_created`: Yeni lead bildirimi
- `consultation_requested`: Görüşme talebi
- `lead_status_changed`: Lead durumu değişti

**Channel Values**
- `email`: Email
- `sms`: SMS
- `slack`: Slack
- `webhook`: Webhook

**Status Values**
- `pending`: Bekliyor
- `sent`: Gönderildi
- `failed`: Başarısız
- `retrying`: Tekrar deneniyor

### 3.8 audit_logs

Sistem audit logları (compliance, security).

**Schema**
```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    changes JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX idx_audit_logs_entity_id ON audit_logs(entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
```

**C# Entity (Target)**
```csharp
public class AuditLog
{
    [Key]
    public Guid Id { get; set; }
    
    public Guid? UserId { get; set; }
    
    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }
    
    [Required, MaxLength(50)]
    public string Action { get; set; }
    
    [Required, MaxLength(50)]
    public string EntityType { get; set; }
    
    [Required]
    public Guid EntityId { get; set; }
    
    public string? Changes { get; set; } // JSON string
    
    public string? IpAddress { get; set; }
    
    public string? UserAgent { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

**Action Values**
- `create`: Kayıt oluşturuldu
- `update`: Kayıt güncellendi
- `delete`: Kayıt silindi
- `login`: Kullanıcı giriş yaptı
- `logout`: Kullanıcı çıkış yaptı

---

## 4. Relationships

### 4.1 Foreign Keys

```sql
-- leads -> users
ALTER TABLE leads 
ADD CONSTRAINT fk_leads_assigned_to 
FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL;

-- consultations -> users
ALTER TABLE consultations 
ADD CONSTRAINT fk_consultations_assigned_to 
FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL;

-- audit_logs -> users
ALTER TABLE audit_logs 
ADD CONSTRAINT fk_audit_logs_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
```

### 4.2 Entity Framework (Target)

```csharp
public class AppDbContext : DbContext
{
    public DbSet<Lead> Leads { get; set; }
    public DbSet<User> Users { get; set; }
    public DbSet<FormSubmission> FormSubmissions { get; set; }
    public DbSet<Consultation> Consultations { get; set; }
    public DbSet<CaseStudy> CaseStudies { get; set; }
    public DbSet<ContentPage> ContentPages { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<AuditLog> AuditLogs { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Relationships
        modelBuilder.Entity<Lead>()
            .HasOne(l => l.AssignedUser)
            .WithMany(u => u.AssignedLeads)
            .HasForeignKey(l => l.AssignedTo)
            .OnDelete(DeleteBehavior.SetNull);
        
        modelBuilder.Entity<Consultation>()
            .HasOne(c => c.AssignedUser)
            .WithMany()
            .HasForeignKey(c => c.AssignedTo)
            .OnDelete(DeleteBehavior.SetNull);
        
        modelBuilder.Entity<AuditLog>()
            .HasOne(a => a.User)
            .WithMany()
            .HasForeignKey(a => a.UserId)
            .OnDelete(DeleteBehavior.SetNull);
        
        // Indexes
        modelBuilder.Entity<Lead>()
            .HasIndex(l => l.Status);
        
        modelBuilder.Entity<Lead>()
            .HasIndex(l => l.CreatedAt)
            .IsDescending();
        
        // Unique constraints
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();
        
        modelBuilder.Entity<CaseStudy>()
            .HasIndex(cs => new { cs.Slug, cs.Locale })
            .IsUnique();
    }
}
```

---

## 5. Indexes Strategy

### 5.1 Primary Keys

Tüm tablolar UUID primary key kullanır:
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

**Rationale:**
- Distributed systems için uygun
- Merge conflicts yok
- Security (sequential ID leak yok)

### 5.2 Query Optimization Indexes

**Frequent Filters**
```sql
-- Status filtering
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_consultations_status ON consultations(status);

-- Date range queries
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- Foreign key lookups
CREATE INDEX idx_leads_assigned_to ON leads(assigned_to);
CREATE INDEX idx_consultations_assigned_to ON consultations(assigned_to);
```

**Search Indexes**
```sql
-- Full-text search (PostgreSQL)
CREATE INDEX idx_leads_search ON leads USING gin(
    to_tsvector('turkish', name || ' ' || email || ' ' || COALESCE(company, ''))
);

-- Email lookups
CREATE INDEX idx_leads_email ON leads(email);
CREATE UNIQUE INDEX idx_users_email ON users(email);
```

**Composite Indexes**
```sql
-- Locale + slug lookups
CREATE UNIQUE INDEX idx_case_studies_slug_locale ON case_studies(slug, locale);
CREATE UNIQUE INDEX idx_content_pages_slug_locale ON content_pages(slug, locale);
```

### 5.3 Azure SQL Indexes (Target)

```sql
-- Columnstore index for analytics (optional)
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_leads_analytics 
ON leads (status, service, created_at);

-- Covering indexes
CREATE NONCLUSTERED INDEX idx_leads_status_covering 
ON leads (status) 
INCLUDE (name, email, created_at);
```

---

## 6. Migrations

### 6.1 Current (Supabase)

**Migration Structure**
```
web/supabase/migrations/
├── 20250901000000_initial_schema.sql
├── 20250915000000_add_consultations.sql
├── 20250920000000_add_audit_logs.sql
└── 20251001000000_add_notifications.sql
```

**Apply Migration**
```bash
# Local
supabase db push

# Remote
supabase db push --linked
```

### 6.2 Target (Entity Framework Core)

**Migration Structure**
```
web/Migrations/
├── 20250901000000_InitialCreate.cs
├── 20250915000000_AddConsultations.cs
├── 20250920000000_AddAuditLogs.cs
└── 20251001000000_AddNotifications.cs
```

**Create Migration**
```bash
dotnet ef migrations add MigrationName --project Web.csproj
```

**Apply Migration**
```bash
# Local
dotnet ef database update --project Web.csproj

# Production
# Via Azure DevOps pipeline or manual SQL script
```

**Example Migration**
```csharp
public partial class InitialCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "Users",
            columns: table => new
            {
                Id = table.Column<Guid>(nullable: false),
                Email = table.Column<string>(maxLength: 255, nullable: false),
                PasswordHash = table.Column<string>(maxLength: 255, nullable: false),
                FullName = table.Column<string>(maxLength: 100, nullable: false),
                Role = table.Column<string>(maxLength: 20, nullable: false),
                IsActive = table.Column<bool>(nullable: false, defaultValue: true),
                CreatedAt = table.Column<DateTime>(nullable: false, defaultValueSql: "GETUTCDATE()"),
                UpdatedAt = table.Column<DateTime>(nullable: false, defaultValueSql: "GETUTCDATE()")
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Users", x => x.Id);
            });
        
        migrationBuilder.CreateIndex(
            name: "IX_Users_Email",
            table: "Users",
            column: "Email",
            unique: true);
    }
    
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "Users");
    }
}
```

---

## 7. Data Migration

### 7.1 Migration Steps

**Phase 1: Schema Setup**
```bash
# 1. Create Azure SQL database
az sql db create \
  --resource-group rg-diskhastanesi \
  --server sql-diskhastanesi \
  --name db-diskhastanesi \
  --service-objective GP_Gen5_2

# 2. Apply schema migrations
dotnet ef database update
```

**Phase 2: Data Export/Import**
```bash
# 1. Export from Supabase
pg_dump -h db.supabase.co -U postgres -d diskhastanesi > backup.sql

# 2. Transform data (Python script)
python scripts/transform_data.py backup.sql transformed.sql

# 3. Import to Azure SQL
sqlcmd -S sql-diskhastanesi.database.windows.net \
  -d db-diskhastanesi \
  -U sqladmin \
  -i transformed.sql
```

**Phase 3: Validation**
```sql
-- Row count validation
SELECT 'leads' AS table_name, COUNT(*) AS row_count FROM leads
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'consultations', COUNT(*) FROM consultations;

-- Data integrity checks
SELECT COUNT(*) FROM leads WHERE assigned_to IS NOT NULL 
  AND NOT EXISTS (SELECT 1 FROM users WHERE id = leads.assigned_to);
```

### 7.2 Azure Data Migration Service

**Alternative:** Use Azure DMS for automated migration

```bash
# Create migration project
az dms project create \
  --resource-group rg-diskhastanesi \
  --service-name dms-diskhastanesi \
  --name migrate-diskhastanesi \
  --source-platform PostgreSQL \
  --target-platform AzureSqlDatabase

# Start migration task
az dms project task create \
  --resource-group rg-diskhastanesi \
  --service-name dms-diskhastanesi \
  --project-name migrate-diskhastanesi \
  --task-name migrate-task \
  --source-connection-json source.json \
  --target-connection-json target.json \
  --database-options-json options.json
```

---

## 8. Data Retention

### 8.1 Retention Policies

**Production Data**
- `leads`: 7 years (legal requirement)
- `consultations`: 7 years
- `audit_logs`: 7 years
- `form_submissions`: 1 year
- `notifications`: 90 days

**Archival Strategy**
```sql
-- Archive old notifications (monthly job)
INSERT INTO notifications_archive 
SELECT * FROM notifications 
WHERE created_at < NOW() - INTERVAL '90 days';

DELETE FROM notifications 
WHERE created_at < NOW() - INTERVAL '90 days';
```

### 8.2 Soft Deletes

**Implementation**
```sql
ALTER TABLE leads ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;

CREATE INDEX idx_leads_deleted_at ON leads(deleted_at) 
WHERE deleted_at IS NULL;
```

```csharp
public class Lead
{
    // ... other properties
    
    public DateTime? DeletedAt { get; set; }
    
    public bool IsDeleted => DeletedAt.HasValue;
}

// Global query filter (EF Core)
modelBuilder.Entity<Lead>()
    .HasQueryFilter(l => l.DeletedAt == null);
```

---

## 9. Backup & Recovery

### 9.1 Current (Supabase)

**Automated Backups**
- Daily automated backups (retained for 7 days)
- Point-in-time recovery available

**Manual Backup**
```bash
# Export database
supabase db dump --file backup-$(date +%Y%m%d).sql

# Restore database
supabase db reset --file backup-20251004.sql
```

### 9.2 Target (Azure SQL)

**Automated Backups**
- Full backups: Weekly
- Differential backups: Every 12 hours
- Transaction log backups: Every 5-10 minutes
- Retention: 7-35 days

**Point-in-Time Restore**
```bash
az sql db restore \
  --resource-group rg-diskhastanesi \
  --server sql-diskhastanesi \
  --name db-diskhastanesi-restored \
  --source-database db-diskhastanesi \
  --time "2025-10-04T12:00:00Z"
```

**Long-Term Retention (LTR)**
```bash
az sql db ltr-policy set \
  --resource-group rg-diskhastanesi \
  --server sql-diskhastanesi \
  --database db-diskhastanesi \
  --weekly-retention P4W \
  --monthly-retention P12M \
  --yearly-retention P7Y \
  --week-of-year 1
```

---

## 10. Performance Tuning

### 10.1 Query Optimization

**Current Slow Query**
```sql
-- Slow: Sequential scan
SELECT * FROM leads 
WHERE status = 'new' 
  AND created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC
LIMIT 20;
```

**Optimized with Covering Index**
```sql
-- Fast: Index-only scan
CREATE INDEX idx_leads_status_created_covering 
ON leads (status, created_at DESC) 
INCLUDE (id, name, email, company, service);
```

### 10.2 Connection Pooling

**Current (Supabase)**
```typescript
// Max connections: 100 (Supabase limit)
// Pooling handled by Supabase
```

**Target (.NET)**
```csharp
// Connection string with pooling
"Server=sql-diskhastanesi.database.windows.net;
 Database=db-diskhastanesi;
 User Id=sqladmin;
 Password=***;
 Min Pool Size=5;
 Max Pool Size=100;
 Connection Timeout=30;
 Command Timeout=30;"
```

### 10.3 Caching Strategy

**Application-Level Cache**
```csharp
// Memory cache for frequently accessed data
services.AddMemoryCache();

public class ContentService
{
    private readonly IMemoryCache _cache;
    
    public async Task<ContentPage> GetPageAsync(string slug, string locale)
    {
        var cacheKey = $"page:{slug}:{locale}";
        
        if (_cache.TryGetValue(cacheKey, out ContentPage page))
            return page;
        
        page = await _db.ContentPages
            .FirstOrDefaultAsync(p => p.Slug == slug && p.Locale == locale);
        
        _cache.Set(cacheKey, page, TimeSpan.FromMinutes(15));
        
        return page;
    }
}
```

---

## 11. Security

### 11.1 Row Level Security (Current)

**PostgreSQL RLS Policies**
```sql
-- Enable RLS
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see assigned leads
CREATE POLICY leads_select_policy ON leads
FOR SELECT
USING (
  assigned_to = auth.uid() 
  OR 
  EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Policy: Only admins can insert
CREATE POLICY leads_insert_policy ON leads
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() AND role IN ('admin', 'sales')
  )
);
```

### 11.2 Authorization (Target)

**ASP.NET Core Authorization**
```csharp
// Policy-based authorization
services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => 
        policy.RequireRole("admin"));
    
    options.AddPolicy("SalesOrAdmin", policy => 
        policy.RequireRole("admin", "sales"));
    
    options.AddPolicy("ViewOwnLeads", policy =>
        policy.RequireAssertion(context =>
        {
            var user = context.User;
            var leadId = context.Resource as Guid?;
            
            // Check if user is admin or assigned to lead
            return user.IsInRole("admin") || 
                   IsUserAssignedToLead(user.GetUserId(), leadId.Value);
        }));
});

// Usage in controller
[Authorize(Policy = "AdminOnly")]
public class AdminController : Controller
{
    [Authorize(Policy = "ViewOwnLeads")]
    public async Task<IActionResult> GetLead(Guid id)
    {
        // ...
    }
}
```

### 11.3 Data Encryption

**At Rest (Azure SQL)**
- Transparent Data Encryption (TDE) enabled by default
- Customer-managed keys (optional)

**In Transit**
- TLS 1.2+ enforced
- Certificate validation required

**Application-Level**
```csharp
// Encrypt sensitive fields
public class Lead
{
    // ... other properties
    
    [EncryptedColumn]
    public string Phone { get; set; }
    
    [EncryptedColumn]
    public string Email { get; set; }
}
```

---

**Son Güncelleme:** 2025-10-04
