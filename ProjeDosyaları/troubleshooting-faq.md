# Sorun Giderme ve SSS (Troubleshooting & FAQ)

**Kaynak:** diskhastanesi.com projesi - Microsoft Stack'e taşıma için hazırlanmıştır

Bu dosya, yaygın sorunları, hata mesajlarını, performance tuning ipuçlarını ve deployment pitfalls'ları içerir.

---

## 1. Build & Deployment Sorunları

### 1.1 Build Hatası: NuGet Package Restore Başarısız

**Hata:**
```
error NU1102: Unable to find package 'PackageName' with version (>= X.X.X)
```

**Çözüm:**
```bash
# 1. NuGet cache'i temizle
dotnet nuget locals all --clear

# 2. Restore tekrar dene
dotnet restore --force

# 3. NuGet source'ları kontrol et
dotnet nuget list source

# 4. Gerekirse private feed ekle
dotnet nuget add source https://api.nuget.org/v3/index.json -n nuget.org
```

### 1.2 Azure Deploy Hatası: Insufficient Permissions

**Hata:**
```
ERROR: The client 'xxx' with object id 'yyy' does not have authorization to perform action
```

**Çözüm:**
```bash
# 1. Service principal'e Contributor rolü ekle
az role assignment create \
  --assignee <service-principal-id> \
  --role Contributor \
  --scope /subscriptions/<subscription-id>/resourceGroups/rg-diskhastanesi-prod

# 2. veya Azure Portal'dan:
# Settings > Access Control (IAM) > Add role assignment
```

### 1.3 Deployment Slot Swap Başarısız

**Hata:**
```
ERROR: The swap operation failed because the target slot is still warming up
```

**Çözüm:**
```bash
# 1. Warm-up süresini arttır
az webapp config appsettings set \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --slot blue \
  --settings WEBSITE_SWAP_WARMUP_PING_PATH=/health WEBSITE_SWAP_WARMUP_PING_STATUSES=200

# 2. Manuel warm-up
curl https://app-diskhastanesi-prod-blue.azurewebsites.net/health

# 3. 30 saniye bekle, tekrar swap dene
az webapp deployment slot swap \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --slot blue
```

### 1.4 Migration Hatası: Pending Model Changes

**Hata:**
```
The model backing the 'AppDbContext' context has changed since the database was created
```

**Çözüm:**
```bash
# 1. Yeni migration oluştur
dotnet ef migrations add FixPendingChanges

# 2. Migration'ı uygula
dotnet ef database update

# 3. Eğer production'da ise, SQL script oluştur
dotnet ef migrations script --idempotent -o migration.sql

# 4. DBA'ya gönder veya manuel uygula
```

---

## 2. Runtime Hataları

### 2.1 HTTP 500 Internal Server Error

**Belirti:**
- API endpoint'leri 500 dönüyor
- Application Insights'ta exception görünüyor

**Debug Adımları:**
```bash
# 1. Log stream'i aç
az webapp log tail \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod

# 2. Application Insights'ta exception'ları kontrol et
# Azure Portal > Application Insights > Failures

# 3. Detailed error pages'i aç (sadece dev/staging)
az webapp config appsettings set \
  --name app-diskhastanesi-staging \
  --resource-group rg-diskhastanesi-staging \
  --settings ASPNETCORE_ENVIRONMENT=Development
```

**Yaygın Sebepler:**

**a) Null Reference Exception**
```csharp
// Problem
var lead = await _context.Leads.FirstOrDefaultAsync(l => l.Id == id);
var email = lead.Email; // NullReferenceException if not found

// Çözüm
var lead = await _context.Leads.FirstOrDefaultAsync(l => l.Id == id);
if (lead == null)
    return NotFound();

var email = lead.Email;
```

**b) Database Connection Timeout**
```
System.Data.SqlClient.SqlException: Timeout expired
```

**Çözüm:**
```csharp
// Connection string'e timeout ekle
"Server=...;Database=...;Connection Timeout=60;Command Timeout=60;"

// veya DbContext'te ayarla
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    optionsBuilder.UseSqlServer(
        connectionString,
        sqlOptions => sqlOptions.CommandTimeout(60));
}
```

### 2.2 HTTP 503 Service Unavailable

**Belirti:**
- Site yüklenmiyor
- "Service Unavailable" mesajı

**Çözüm:**
```bash
# 1. App Service durumunu kontrol et
az webapp show \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --query state

# 2. Eğer "Stopped" ise, başlat
az webapp start \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod

# 3. Always On ayarını kontrol et (production'da açık olmalı)
az webapp config set \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --always-on true
```

### 2.3 Memory Leak / OutOfMemoryException

**Belirti:**
- Memory usage sürekli artıyor
- App Service yavaşlıyor veya crash oluyor

**Debug:**
```bash
# 1. Memory metrics'leri kontrol et
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-diskhastanesi-prod/providers/Microsoft.Web/sites/app-diskhastanesi-prod \
  --metric "MemoryWorkingSet" \
  --start-time 2025-10-01T00:00:00Z \
  --end-time 2025-10-04T00:00:00Z

# 2. Memory dump al
az webapp debug-diagnostic download \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --output-path ./dumps
```

**Yaygın Sebepler:**
```csharp
// Problem 1: Dispose edilmeyen DbContext
public class LeadsController
{
    private readonly AppDbContext _context = new AppDbContext(); // BAD!
    
    // Her request'te yeni context oluşturulur ama dispose edilmez
}

// Çözüm: Dependency Injection
public class LeadsController
{
    private readonly AppDbContext _context;
    
    public LeadsController(AppDbContext context)
    {
        _context = context; // DI container dispose eder
    }
}

// Problem 2: Large result set memory'de tutmak
var allLeads = await _context.Leads.ToListAsync(); // BAD if 1M+ records

// Çözüm: Pagination veya streaming
var leads = await _context.Leads
    .OrderBy(l => l.CreatedAt)
    .Skip(offset)
    .Take(limit)
    .ToListAsync();
```

---

## 3. Database Sorunları

### 3.1 Connection Pool Exhausted

**Hata:**
```
System.InvalidOperationException: Timeout expired. The timeout period elapsed prior to obtaining a connection from the pool.
```

**Çözüm:**
```csharp
// 1. Connection string'de pool size arttır
"Server=...;Max Pool Size=200;" // Default: 100

// 2. Connections'ların dispose edildiğinden emin ol
using (var connection = new SqlConnection(connectionString))
{
    // Use connection
} // Auto-disposed

// 3. DbContext lifetime'ı kontrol et (Scoped olmalı)
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString),
    ServiceLifetime.Scoped); // NOT Singleton!
```

### 3.2 Deadlock Detected

**Hata:**
```
Transaction (Process ID XX) was deadlocked on lock resources with another process and has been chosen as the deadlock victim.
```

**Debug:**
```sql
-- Deadlock history
SELECT * FROM sys.dm_exec_query_stats
CROSS APPLY sys.dm_exec_sql_text(sql_handle)
WHERE last_execution_time > DATEADD(hour, -1, GETUTCDATE())
ORDER BY last_execution_time DESC;

-- Enable deadlock trace
DBCC TRACEON (1222, -1);

-- Check trace log
SELECT * FROM sys.fn_trace_gettable('C:\Path\To\Log.trc', DEFAULT);
```

**Çözüm:**
```csharp
// 1. Retry logic ekle
services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(
        connectionString,
        sqlOptions => sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 3,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorNumbersToAdd: null)));

// 2. Transaction scope'ları küçült
using (var transaction = await _context.Database.BeginTransactionAsync())
{
    // Minimize işlemler
    await _context.SaveChangesAsync();
    await transaction.CommitAsync();
}

// 3. Lock order'ı standardize et (hep aynı sırada lock al)
// BAD: Thread 1 locks Table A then B, Thread 2 locks B then A
// GOOD: Her ikisi de A then B sırasında lock alsın
```

### 3.3 Slow Queries

**Belirti:**
- API response time yüksek
- Database CPU %80+

**Debug:**
```sql
-- En yavaş query'leri bul
SELECT TOP 10
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
    qs.execution_count,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS query_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY avg_elapsed_time DESC;

-- Missing index önerileri
SELECT
    migs.avg_user_impact,
    migs.avg_total_user_cost,
    migs.user_seeks + migs.user_scans AS total_uses,
    mid.*
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid ON mig.index_handle = mid.index_handle
ORDER BY migs.avg_user_impact DESC;
```

**Çözüm:**
```csharp
// 1. Index ekle
migrationBuilder.CreateIndex(
    name: "IX_Leads_Status_CreatedAt",
    table: "Leads",
    columns: new[] { "Status", "CreatedAt" });

// 2. N+1 problem'ini çöz
// BAD
var leads = await _context.Leads.ToListAsync();
foreach (var lead in leads)
{
    var user = await _context.Users.FindAsync(lead.AssignedTo); // N+1!
}

// GOOD
var leads = await _context.Leads
    .Include(l => l.AssignedUser) // Eager loading
    .ToListAsync();

// 3. Projection kullan (sadece gerekli kolonlar)
var leads = await _context.Leads
    .Select(l => new LeadSummary
    {
        Id = l.Id,
        Name = l.Name,
        Email = l.Email
    })
    .ToListAsync();
```

---

## 4. Performance Sorunları

### 4.1 Yavaş Sayfa Yükleme

**Belirti:**
- TTFB (Time to First Byte) > 500ms
- LCP (Largest Contentful Paint) > 2.5s

**Debug:**
```bash
# 1. Lighthouse audit
npx lighthouse https://diskhastanesi.com --view

# 2. WebPageTest
# https://www.webpagetest.org/

# 3. Chrome DevTools > Performance tab
```

**Çözümler:**

**a) Server-Side Rendering Yavaş**
```csharp
// Problem: Synchronous database calls
public async Task<IActionResult> Index()
{
    var leads = _context.Leads.ToList(); // Blocking!
    return View(leads);
}

// Çözüm: Async/await
public async Task<IActionResult> Index()
{
    var leads = await _context.Leads.ToListAsync();
    return View(leads);
}
```

**b) No Caching**
```csharp
// Response cache ekle
[ResponseCache(Duration = 300, VaryByQueryKeys = new[] { "locale" })]
public async Task<IActionResult> GetCaseStudies(string locale)
{
    // ...
}

// Memory cache ekle
private readonly IMemoryCache _cache;

public async Task<List<CaseStudy>> GetCaseStudiesAsync()
{
    if (_cache.TryGetValue("case_studies", out List<CaseStudy> cached))
        return cached;
    
    var caseStudies = await _context.CaseStudies.ToListAsync();
    _cache.Set("case_studies", caseStudies, TimeSpan.FromMinutes(15));
    
    return caseStudies;
}
```

**c) Large Images**
```bash
# Image optimization
npm install -g imagemin-cli

imagemin public/images/*.jpg --out-dir=public/images/optimized --plugin=mozjpeg

# Azure CDN + image compression
az cdn endpoint create \
  --name diskhastanesi-images \
  --profile-name cdn-diskhastanesi \
  --resource-group rg-diskhastanesi-prod \
  --origin diskhastanesi.blob.core.windows.net \
  --enable-compression true
```

### 4.2 Yüksek CPU Usage

**Belirti:**
- App Service CPU > 80%
- Slow response times

**Debug:**
```bash
# 1. CPU metrics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-diskhastanesi-prod/providers/Microsoft.Web/sites/app-diskhastanesi-prod \
  --metric "CpuPercentage"

# 2. Performance profiler (Application Insights)
# Portal > Application Insights > Performance > Profiler
```

**Çözümler:**

**a) Inefficient Algorithms**
```csharp
// Problem: O(n²) complexity
foreach (var lead in leads)
{
    foreach (var user in users)
    {
        if (lead.AssignedTo == user.Id)
        {
            lead.AssignedUser = user;
        }
    }
}

// Çözüm: Dictionary lookup O(1)
var userDict = users.ToDictionary(u => u.Id);
foreach (var lead in leads)
{
    if (userDict.TryGetValue(lead.AssignedTo, out var user))
    {
        lead.AssignedUser = user;
    }
}
```

**b) Regex Overuse**
```csharp
// Problem: Regex her request'te compile ediliyor
var regex = new Regex(@"^\+90[0-9]{10}$");
if (regex.IsMatch(phone)) { }

// Çözüm: Static compiled regex
private static readonly Regex PhoneRegex = new Regex(
    @"^\+90[0-9]{10}$",
    RegexOptions.Compiled);

if (PhoneRegex.IsMatch(phone)) { }
```

**c) Scale Up**
```bash
# Tier upgrade
az appservice plan update \
  --name asp-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --sku P2v3 # P1v3 → P2v3 (2 cores → 4 cores)
```

### 4.3 Memory Usage Yüksek

**Debug:**
```bash
# Memory metrics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/rg-diskhastanesi-prod/providers/Microsoft.Web/sites/app-diskhastanesi-prod \
  --metric "MemoryWorkingSet"

# Memory snapshot (Application Insights)
# Portal > Application Insights > Memory Profiler
```

**Çözümler:**
```csharp
// 1. IDisposable pattern
public class LeadService : IDisposable
{
    private readonly AppDbContext _context;
    
    public void Dispose()
    {
        _context?.Dispose();
    }
}

// 2. Streaming large files
public async Task<IActionResult> DownloadReport()
{
    var stream = await GenerateReportStreamAsync();
    return File(stream, "application/pdf", "report.pdf");
}

// 3. GC tuning
// launchSettings.json
"environmentVariables": {
    "COMPlus_gcServer": "1",
    "COMPlus_GCHeapCount": "4"
}
```

---

## 5. Security Issues

### 5.1 CORS Hatası

**Hata:**
```
Access to XMLHttpRequest at 'https://api.diskhastanesi.com' from origin 'https://diskhastanesi.com' has been blocked by CORS policy
```

**Çözüm:**
```csharp
// Program.cs
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("https://diskhastanesi.com")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

app.UseCors("AllowFrontend");
```

### 5.2 Authentication Failed

**Hata:**
```
401 Unauthorized
WWW-Authenticate: Bearer error="invalid_token"
```

**Debug:**
```csharp
// Token validation logging
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                _logger.LogError($"Token validation failed: {context.Exception.Message}");
                return Task.CompletedTask;
            }
        };
    });
```

**Çözümler:**

**a) Token Expired**
```csharp
// Refresh token logic
if (token.ValidTo < DateTime.UtcNow)
{
    var newToken = await RefreshTokenAsync(refreshToken);
    return newToken;
}
```

**b) Wrong Issuer/Audience**
```csharp
// Token validation parameters kontrol et
options.TokenValidationParameters = new TokenValidationParameters
{
    ValidateIssuer = true,
    ValidIssuer = "https://diskhastanesi.com",
    ValidateAudience = true,
    ValidAudience = "https://api.diskhastanesi.com",
    // ...
};
```

---

## 6. Monitoring & Alerting

### 6.1 Missing Metrics

**Problem:** Application Insights'ta metric görünmüyor

**Çözüm:**
```csharp
// 1. Application Insights SDK eklenmiş mi kontrol et
builder.Services.AddApplicationInsightsTelemetry();

// 2. Connection string doğru mu?
// appsettings.json
{
  "ApplicationInsights": {
    "ConnectionString": "InstrumentationKey=xxx;IngestionEndpoint=https://westeurope-5.in.applicationinsights.azure.com/"
  }
}

// 3. Custom metrics tracking
var telemetryClient = new TelemetryClient();
telemetryClient.TrackMetric("LeadCreated", 1);
telemetryClient.TrackEvent("LeadStatusChanged", new Dictionary<string, string>
{
    { "LeadId", leadId.ToString() },
    { "OldStatus", oldStatus },
    { "NewStatus", newStatus }
});
```

### 6.2 Alert Not Firing

**Problem:** Alert rule oluşturuldu ama notification gelmiyor

**Debug:**
```bash
# 1. Alert rule durumu
az monitor metrics alert show \
  --name "HTTP 5xx Errors" \
  --resource-group rg-diskhastanesi-prod

# 2. Alert history
az monitor activity-log list \
  --resource-group rg-diskhastanesi-prod \
  --offset 1d

# 3. Action group test
az monitor action-group test-notifications create \
  --action-group ag-oncall \
  --resource-group rg-diskhastanesi-prod \
  --notification-type Email
```

**Çözüm:**
```bash
# Action group email doğrula
az monitor action-group update \
  --name ag-oncall \
  --resource-group rg-diskhastanesi-prod \
  --add-action email oncall oncall@diskhastanesi.com
```

---

## 7. FAQ

### Q1: Deployment sonrası 502 Bad Gateway alıyorum?

**A:** App Service'in başlaması 30-60 saniye sürebilir.

```bash
# Warm-up
curl https://app-diskhastanesi-prod.azurewebsites.net/health

# Health check log
az webapp log tail \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod
```

### Q2: Migration production'da nasıl uygulanır?

**A:** Manuel SQL script çalıştırılır (otomatik değil).

```bash
# 1. Script oluştur
dotnet ef migrations script --idempotent -o migration.sql

# 2. DBA review
# 3. Backup al
# 4. Apply script
sqlcmd -S sql-diskhastanesi-prod.database.windows.net -i migration.sql
```

### Q3: Blue-green deployment sırasında database conflict?

**A:** Backward-compatible migrations kullan.

```csharp
// BAD: Column silme (blue slot hala kullanıyor)
migrationBuilder.DropColumn("OldColumn", "Leads");

// GOOD: İki aşamada
// Step 1: Nullable yap, deploy
migrationBuilder.AlterColumn<string>("OldColumn", "Leads", nullable: true);

// Step 2: Deploy tamamlandıktan sonra sil
// migrationBuilder.DropColumn("OldColumn", "Leads");
```

### Q4: Local development'ta Azure SQL'e bağlanamıyorum?

**A:** IP whitelist ekle.

```bash
# Firewall rule ekle
az sql server firewall-rule create \
  --resource-group rg-diskhastanesi-dev \
  --server sql-diskhastanesi-dev \
  --name MyLocalIP \
  --start-ip-address <your-ip> \
  --end-ip-address <your-ip>

# IP'ni öğren
curl ifconfig.me
```

### Q5: Rate limiting çalışmıyor?

**A:** Middleware order kontrol et.

```csharp
// Program.cs - ORDER MATTERS!
app.UseRouting();
app.UseIpRateLimiting(); // Rate limiting ÖNCE
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
```

### Q6: HTTPS redirect loop?

**A:** Load balancer arkasında `X-Forwarded-Proto` header kullan.

```csharp
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedProto
});

app.UseHttpsRedirection();
```

### Q7: Environment variables production'da geçersiz?

**A:** App Settings'te set edilmiş mi kontrol et.

```bash
# List
az webapp config appsettings list \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod

# Add
az webapp config appsettings set \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod \
  --settings KEY=VALUE
```

### Q8: Slot swap sonrasıeski version çalışıyor?

**A:** Browser cache veya CDN cache.

```bash
# CDN purge
az cdn endpoint purge \
  --profile-name cdn-diskhastanesi \
  --name diskhastanesi \
  --resource-group rg-diskhastanesi-prod \
  --content-paths "/*"

# Browser: Hard refresh (Ctrl+Shift+R)
```

### Q9: Connection string Key Vault'tan okumuyor?

**A:** Managed Identity permission eksik.

```bash
# Grant access
az keyvault set-policy \
  --name kv-diskhastanesi-prod \
  --object-id <app-service-managed-identity-id> \
  --secret-permissions get list
```

### Q10: Performance test sonrası production slow?

**A:** Connection pool tükenmiş olabilir. Restart gerekebilir.

```bash
# Restart app
az webapp restart \
  --name app-diskhastanesi-prod \
  --resource-group rg-diskhastanesi-prod

# Connection pool settings kontrol
# Max Pool Size=200 yeterli mi?
```

---

## 8. Emergency Procedures

### 8.1 Site Down (P0)

**Checklist:**
1. [ ] Health endpoint check: `curl https://diskhastanesi.com/health`
2. [ ] Azure status: https://status.azure.com/
3. [ ] Application Insights: Exception count spike?
4. [ ] Rollback: Swap slot back
5. [ ] Incident report: Log to operations/ai-decisions/

### 8.2 Data Breach (P0)

**Checklist:**
1. [ ] Isolate: Disable affected endpoints
2. [ ] Evidence: Snapshot database, copy logs
3. [ ] Notify: CTO, legal team
4. [ ] Patch: Deploy fix immediately
5. [ ] Communicate: Notify affected users
6. [ ] Report: File with data protection authority

### 8.3 Performance Degradation (P1)

**Checklist:**
1. [ ] Metrics: Check CPU, memory, response time
2. [ ] Scale: Increase instance count
3. [ ] Cache: Verify cache hit rate
4. [ ] Database: Check slow queries
5. [ ] CDN: Verify CDN serving static assets

---

**Son Güncelleme:** 2025-10-04
