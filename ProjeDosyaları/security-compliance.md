# Güvenlik ve Uyumluluk Dokümantasyonu

**Kaynak:** diskhastanesi.com projesi - Microsoft Stack'e taşıma için hazırlanmıştır

Bu dosya, güvenlik politikalarını, uyumluluk gereksinimlerini ve güvenlik testlerini içerir.

---

## 1. Güvenlik Genel Bakış

### 1.1 Güvenlik Prensipleri

**Defense in Depth (Katmanlı Savunma)**
- Network katmanı: WAF, DDoS protection
- Application katmanı: Authentication, authorization, input validation
- Data katmanı: Encryption at rest/transit, RLS
- Identity katmanı: MFA, password policies

**Zero Trust Model**
- Her istek doğrulanır
- Minimum privilege principle
- Continuous monitoring

**Secure by Design**
- Security requirements baştan tasarımda
- Threat modeling her feature için
- Security testing CI/CD pipeline'da

### 1.2 Threat Model

**STRIDE Analysis**

| Threat | Mitigasyon |
|--------|------------|
| **Spoofing** | JWT authentication, Azure AD B2C, MFA |
| **Tampering** | HTTPS, CSP, input validation, SQL parameterization |
| **Repudiation** | Audit logs, transaction logs |
| **Information Disclosure** | Encryption, access controls, data masking |
| **Denial of Service** | Rate limiting, CDN, auto-scaling |
| **Elevation of Privilege** | RBAC, least privilege, policy enforcement |

---

## 2. Authentication & Authorization

### 2.1 Current Stack (Next.js + Supabase)

**Authentication**
- Provider: Supabase Auth (planned)
- Method: Email/password (currently public endpoints)
- Session: JWT tokens
- Storage: httpOnly cookies

**Authorization**
- Method: Row Level Security (RLS) policies
- Roles: admin, sales, support, viewer

**Implementation**
```typescript
// Middleware (planned)
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs';

export async function middleware(req: NextRequest) {
  const res = NextResponse.next();
  const supabase = createMiddlewareClient({ req, res });
  
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session && req.nextUrl.pathname.startsWith('/admin')) {
    return NextResponse.redirect(new URL('/login', req.url));
  }
  
  return res;
}
```

### 2.2 Target Stack (ASP.NET Core + Azure AD B2C)

**Authentication**
- Provider: Azure AD B2C / Entra ID
- Method: OAuth 2.0 + OpenID Connect
- MFA: Required for admin roles
- Session: Encrypted cookies + JWT
- Password policy: 
  - Minimum 12 characters
  - Complexity requirements (uppercase, lowercase, numbers, symbols)
  - Password history (last 5 passwords)
  - Expiry: 90 days

**Authorization**
- Method: Policy-based authorization
- Claims-based access control
- Roles: admin, sales, support, viewer

**Implementation**
```csharp
// Startup.cs
services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApp(Configuration.GetSection("AzureAdB2C"));

services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => 
        policy.RequireRole("admin"));
    
    options.AddPolicy("RequireMFA", policy =>
        policy.RequireClaim("amr", "mfa"));
    
    options.AddPolicy("ViewLeads", policy =>
        policy.RequireAssertion(context =>
            context.User.IsInRole("admin") ||
            context.User.IsInRole("sales") ||
            IsAssignedToLead(context)));
});

// Controller
[Authorize(Policy = "AdminOnly")]
[Authorize(Policy = "RequireMFA")]
public class AdminController : Controller
{
    // ...
}
```

**Azure AD B2C Configuration**
```json
{
  "AzureAdB2C": {
    "Instance": "https://diskhastanesi.b2clogin.com",
    "ClientId": "your-client-id",
    "Domain": "diskhastanesi.onmicrosoft.com",
    "SignUpSignInPolicyId": "B2C_1_signupsignin",
    "ResetPasswordPolicyId": "B2C_1_passwordreset",
    "EditProfilePolicyId": "B2C_1_profileedit"
  }
}
```

---

## 3. Input Validation & Sanitization

### 3.1 Server-Side Validation

**Current (Zod + Next.js)**
```typescript
import { z } from 'zod';

const leadSchema = z.object({
  name: z.string()
    .min(2, 'Name must be at least 2 characters')
    .max(100, 'Name must be less than 100 characters')
    .regex(/^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$/, 'Invalid name format'),
  
  email: z.string()
    .email('Invalid email format')
    .max(255),
  
  phone: z.string()
    .regex(/^\+90[0-9]{10}$/, 'Invalid phone format'),
  
  company: z.string()
    .min(2)
    .max(100)
    .optional(),
  
  service: z.enum([
    'veri-kurtarma',
    'siber-guvenlik',
    'sunucu-bakim',
    'network-cozumleri',
    'disaster-recovery'
  ]),
  
  message: z.string()
    .min(10, 'Message must be at least 10 characters')
    .max(1000, 'Message must be less than 1000 characters'),
  
  captchaToken: z.string().min(1, 'Captcha required')
});

// Usage
export async function POST(request: Request) {
  const body = await request.json();
  
  const result = leadSchema.safeParse(body);
  
  if (!result.success) {
    return NextResponse.json(
      { error: { code: 'VALIDATION_ERROR', details: result.error.errors } },
      { status: 400 }
    );
  }
  
  // Process validated data
  const lead = result.data;
  // ...
}
```

**Target (FluentValidation + ASP.NET Core)**
```csharp
using FluentValidation;

public class LeadRequestValidator : AbstractValidator<LeadRequest>
{
    public LeadRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .Length(2, 100)
            .Matches(@"^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$");
        
        RuleFor(x => x.Email)
            .NotEmpty()
            .EmailAddress()
            .MaximumLength(255);
        
        RuleFor(x => x.Phone)
            .NotEmpty()
            .Matches(@"^\+90[0-9]{10}$");
        
        RuleFor(x => x.Company)
            .Length(2, 100)
            .When(x => !string.IsNullOrEmpty(x.Company));
        
        RuleFor(x => x.Service)
            .NotEmpty()
            .Must(BeValidService)
            .WithMessage("Invalid service type");
        
        RuleFor(x => x.Message)
            .NotEmpty()
            .Length(10, 1000);
        
        RuleFor(x => x.CaptchaToken)
            .NotEmpty()
            .WithMessage("Captcha verification required");
    }
    
    private bool BeValidService(string service)
    {
        var validServices = new[] {
            "veri-kurtarma",
            "siber-guvenlik",
            "sunucu-bakim",
            "network-cozumleri",
            "disaster-recovery"
        };
        
        return validServices.Contains(service);
    }
}

// Startup.cs
services.AddValidatorsFromAssemblyContaining<LeadRequestValidator>();
services.AddFluentValidationAutoValidation();

// Controller
[ApiController]
[Route("api/[controller]")]
public class LeadsController : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> CreateLead([FromBody] LeadRequest request)
    {
        // Validation automatically applied
        // If invalid, 400 Bad Request with validation errors returned
        
        // Process validated request
        // ...
    }
}
```

### 3.2 XSS Prevention

**Content Security Policy (CSP)**
```typescript
// next.config.ts
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: `
      default-src 'self';
      script-src 'self' 'unsafe-eval' 'unsafe-inline' https://hcaptcha.com https://*.hcaptcha.com;
      style-src 'self' 'unsafe-inline' https://hcaptcha.com;
      img-src 'self' data: https:;
      font-src 'self' data:;
      connect-src 'self' https://*.supabase.co https://hcaptcha.com;
      frame-src https://hcaptcha.com;
      object-src 'none';
      base-uri 'self';
      form-action 'self';
      frame-ancestors 'none';
      upgrade-insecure-requests;
    `.replace(/\s{2,}/g, ' ').trim()
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff'
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY'
  },
  {
    key: 'X-XSS-Protection',
    value: '1; mode=block'
  },
  {
    key: 'Referrer-Policy',
    value: 'strict-origin-when-cross-origin'
  },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=()'
  }
];

export default {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: securityHeaders,
      },
    ];
  },
};
```

**HTML Sanitization**
```typescript
// Current (DOMPurify)
import DOMPurify from 'isomorphic-dompurify';

const sanitizeHtml = (dirty: string): string => {
  return DOMPurify.sanitize(dirty, {
    ALLOWED_TAGS: ['p', 'br', 'strong', 'em', 'ul', 'ol', 'li'],
    ALLOWED_ATTR: []
  });
};
```

```csharp
// Target (HtmlSanitizer)
using Ganss.Xss;

public class HtmlSanitizerService
{
    private readonly HtmlSanitizer _sanitizer;
    
    public HtmlSanitizerService()
    {
        _sanitizer = new HtmlSanitizer();
        _sanitizer.AllowedTags.Clear();
        _sanitizer.AllowedTags.Add("p");
        _sanitizer.AllowedTags.Add("br");
        _sanitizer.AllowedTags.Add("strong");
        _sanitizer.AllowedTags.Add("em");
    }
    
    public string Sanitize(string html)
    {
        return _sanitizer.Sanitize(html);
    }
}
```

### 3.3 SQL Injection Prevention

**Parameterized Queries**
```typescript
// Current (Supabase client - safe by default)
const { data, error } = await supabase
  .from('leads')
  .select('*')
  .eq('status', userInput); // Safe: automatically parameterized
```

```csharp
// Target (Entity Framework Core - safe by default)
var leads = await _context.Leads
    .Where(l => l.Status == userInput) // Safe: parameterized
    .ToListAsync();

// Raw SQL (when necessary)
var leads = await _context.Leads
    .FromSqlRaw("SELECT * FROM leads WHERE status = {0}", userInput) // Safe: parameterized
    .ToListAsync();
```

---

## 4. Rate Limiting

### 4.1 Current (Vercel Edge)

**Implementation**
```typescript
// middleware.ts
import { Redis } from '@upstash/redis';

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

export async function middleware(request: NextRequest) {
  const ip = request.ip ?? '127.0.0.1';
  const key = `rate_limit:${ip}`;
  
  const requests = await redis.incr(key);
  
  if (requests === 1) {
    await redis.expire(key, 60); // 1 minute window
  }
  
  if (requests > 100) {
    return new NextResponse('Rate limit exceeded', {
      status: 429,
      headers: {
        'Retry-After': '60',
        'X-RateLimit-Limit': '100',
        'X-RateLimit-Remaining': '0',
        'X-RateLimit-Reset': new Date(Date.now() + 60000).toISOString()
      }
    });
  }
  
  return NextResponse.next({
    headers: {
      'X-RateLimit-Limit': '100',
      'X-RateLimit-Remaining': String(100 - requests),
    }
  });
}
```

### 4.2 Target (ASP.NET Core + Azure)

**Implementation**
```csharp
// Using AspNetCoreRateLimit
// Startup.cs
services.AddMemoryCache();

services.Configure<IpRateLimitOptions>(options =>
{
    options.EnableEndpointRateLimiting = true;
    options.StackBlockedRequests = false;
    options.HttpStatusCode = 429;
    
    options.GeneralRules = new List<RateLimitRule>
    {
        new RateLimitRule
        {
            Endpoint = "*",
            Period = "1m",
            Limit = 100
        },
        new RateLimitRule
        {
            Endpoint = "POST:/api/leads",
            Period = "1h",
            Limit = 5
        }
    };
});

services.AddInMemoryRateLimiting();
services.AddSingleton<IRateLimitConfiguration, RateLimitConfiguration>();

// Program.cs
app.UseIpRateLimiting();
```

**API Management (Azure APIM)**
```xml
<policies>
    <inbound>
        <rate-limit calls="100" renewal-period="60" />
        <rate-limit-by-key calls="5" renewal-period="3600" 
            counter-key="@(context.Request.IpAddress)" />
    </inbound>
</policies>
```

---

## 5. Data Protection

### 5.1 Encryption at Rest

**Current (Supabase)**
- Database: AES-256 encryption (managed by Supabase)
- Storage: Encrypted by default

**Target (Azure SQL + Azure Storage)**
- Database: Transparent Data Encryption (TDE) enabled
- Storage: Azure Storage Service Encryption (SSE)
- Key management: Azure Key Vault

**Azure Key Vault Configuration**
```bash
# Create Key Vault
az keyvault create \
  --name kv-diskhastanesi \
  --resource-group rg-diskhastanesi \
  --location westeurope

# Create encryption key
az keyvault key create \
  --vault-name kv-diskhastanesi \
  --name sql-encryption-key \
  --protection software

# Grant SQL Server access
az sql server key create \
  --resource-group rg-diskhastanesi \
  --server sql-diskhastanesi \
  --kid https://kv-diskhastanesi.vault.azure.net/keys/sql-encryption-key/...

# Enable TDE with customer-managed key
az sql db tde set \
  --resource-group rg-diskhastanesi \
  --server sql-diskhastanesi \
  --database db-diskhastanesi \
  --status Enabled \
  --encryption-protector-type ServiceManaged
```

### 5.2 Encryption in Transit

**HTTPS/TLS**
- Minimum TLS version: 1.2
- Certificate: Let's Encrypt (current) → Azure App Service Managed Certificate (target)
- HSTS enabled

**Next.js Configuration**
```typescript
// next.config.ts
const securityHeaders = [
  {
    key: 'Strict-Transport-Security',
    value: 'max-age=63072000; includeSubDomains; preload'
  }
];
```

**ASP.NET Core Configuration**
```csharp
// Program.cs
app.UseHsts();
app.UseHttpsRedirection();

// Enforce HTTPS
services.AddHttpsRedirection(options =>
{
    options.RedirectStatusCode = StatusCodes.Status308PermanentRedirect;
    options.HttpsPort = 443;
});

// HSTS
services.AddHsts(options =>
{
    options.Preload = true;
    options.IncludeSubDomains = true;
    options.MaxAge = TimeSpan.FromDays(730);
});
```

### 5.3 Sensitive Data Masking

**Database Column Encryption**
```csharp
using Microsoft.EntityFrameworkCore.DataEncryption;

public class Lead
{
    [Encrypted]
    public string Phone { get; set; }
    
    [Encrypted]
    public string Email { get; set; }
}

// DbContext configuration
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    var encryptionProvider = new AesEncryptionProvider(
        key: Configuration["Encryption:Key"],
        iv: Configuration["Encryption:IV"]);
    
    modelBuilder.UseEncryption(encryptionProvider);
}
```

**Log Masking**
```csharp
public class SensitiveDataMasker
{
    public static string MaskEmail(string email)
    {
        if (string.IsNullOrEmpty(email)) return email;
        
        var parts = email.Split('@');
        if (parts.Length != 2) return email;
        
        var username = parts[0];
        var masked = username.Length > 2
            ? $"{username[0]}***{username[^1]}@{parts[1]}"
            : $"***@{parts[1]}";
        
        return masked;
    }
    
    public static string MaskPhone(string phone)
    {
        if (string.IsNullOrEmpty(phone) || phone.Length < 10) return phone;
        
        return $"+90***{phone[^4..]}";
    }
}

// Usage in logging
_logger.LogInformation("Lead created: {Email}", 
    SensitiveDataMasker.MaskEmail(lead.Email));
```

---

## 6. Secrets Management

### 6.1 Current (Vercel Environment Variables)

**Environment Variables**
```bash
# .env.local (development)
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
HCAPTCHA_SECRET=0x...
SENDGRID_API_KEY=SG...
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
```

**Vercel Secrets**
```bash
# Production secrets stored in Vercel dashboard
vercel env add SUPABASE_SERVICE_ROLE_KEY production
vercel env add HCAPTCHA_SECRET production
```

### 6.2 Target (Azure Key Vault)

**Key Vault Setup**
```bash
# Store secrets
az keyvault secret set \
  --vault-name kv-diskhastanesi \
  --name "ConnectionStrings--DefaultConnection" \
  --value "Server=..."

az keyvault secret set \
  --vault-name kv-diskhastanesi \
  --name "SendGrid--ApiKey" \
  --value "SG..."

# Grant App Service access
az webapp identity assign \
  --name app-diskhastanesi \
  --resource-group rg-diskhastanesi

az keyvault set-policy \
  --name kv-diskhastanesi \
  --object-id <managed-identity-id> \
  --secret-permissions get list
```

**ASP.NET Core Configuration**
```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsProduction())
{
    var keyVaultName = builder.Configuration["KeyVault:Name"];
    var keyVaultUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
    
    builder.Configuration.AddAzureKeyVault(
        keyVaultUri,
        new DefaultAzureCredential());
}

// Usage
var connectionString = builder.Configuration["ConnectionStrings:DefaultConnection"];
var sendGridApiKey = builder.Configuration["SendGrid:ApiKey"];
```

---

## 7. KVKK & GDPR Compliance

### 7.1 Data Privacy

**Personal Data Inventory**
- Name
- Email
- Phone number
- Company name
- IP address
- User agent

**Legal Basis**
- Consent: Explicit consent for marketing communications
- Contract: Processing for lead management
- Legitimate interest: Security monitoring, fraud prevention

**Data Subject Rights**
- Right to access: API endpoint for data export
- Right to rectification: Update endpoints
- Right to erasure: Soft delete implementation
- Right to portability: JSON export format
- Right to object: Opt-out mechanisms

### 7.2 Privacy Implementation

**Consent Management**
```typescript
// Cookie consent banner
import { CookieConsent } from '@/components/CookieConsent';

export default function RootLayout() {
  return (
    <html>
      <body>
        {children}
        <CookieConsent />
      </body>
    </html>
  );
}
```

**Data Export (GDPR Article 20)**
```csharp
[HttpGet("me/export")]
[Authorize]
public async Task<IActionResult> ExportMyData()
{
    var userId = User.GetUserId();
    
    var userData = new
    {
        User = await _context.Users.FindAsync(userId),
        Leads = await _context.Leads
            .Where(l => l.Email == User.GetEmail())
            .ToListAsync(),
        Consultations = await _context.Consultations
            .Where(c => c.Email == User.GetEmail())
            .ToListAsync(),
        AuditLogs = await _context.AuditLogs
            .Where(a => a.UserId == userId)
            .ToListAsync()
    };
    
    var json = JsonSerializer.Serialize(userData, new JsonSerializerOptions
    {
        WriteIndented = true
    });
    
    return File(
        Encoding.UTF8.GetBytes(json),
        "application/json",
        $"my-data-{DateTime.UtcNow:yyyyMMdd}.json");
}
```

**Data Deletion (GDPR Article 17)**
```csharp
[HttpDelete("me")]
[Authorize]
public async Task<IActionResult> DeleteMyAccount()
{
    var userId = User.GetUserId();
    var user = await _context.Users.FindAsync(userId);
    
    if (user == null)
        return NotFound();
    
    // Soft delete
    user.DeletedAt = DateTime.UtcNow;
    user.Email = $"deleted-{userId}@deleted.local";
    user.IsActive = false;
    
    // Anonymize related data
    var leads = await _context.Leads
        .Where(l => l.Email == User.GetEmail())
        .ToListAsync();
    
    foreach (var lead in leads)
    {
        lead.Name = "Deleted User";
        lead.Email = $"deleted-{lead.Id}@deleted.local";
        lead.Phone = "+900000000000";
        lead.Company = null;
    }
    
    await _context.SaveChangesAsync();
    
    // Log deletion
    _logger.LogWarning("User account deleted: {UserId}", userId);
    
    return NoContent();
}
```

### 7.3 Data Retention

**Retention Policy**
```csharp
public class DataRetentionService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await AnonymizeOldData();
            await DeleteExpiredData();
            
            await Task.Delay(TimeSpan.FromDays(1), stoppingToken);
        }
    }
    
    private async Task AnonymizeOldData()
    {
        // Anonymize leads older than 7 years
        var cutoffDate = DateTime.UtcNow.AddYears(-7);
        
        var oldLeads = await _context.Leads
            .Where(l => l.CreatedAt < cutoffDate && l.DeletedAt == null)
            .ToListAsync();
        
        foreach (var lead in oldLeads)
        {
            lead.Name = "Anonymized";
            lead.Email = $"anon-{lead.Id}@anonymized.local";
            lead.Phone = "+900000000000";
            lead.Company = null;
            lead.Message = "[Anonymized]";
        }
        
        await _context.SaveChangesAsync();
    }
    
    private async Task DeleteExpiredData()
    {
        // Delete old notifications (90 days)
        var notificationCutoff = DateTime.UtcNow.AddDays(-90);
        
        await _context.Notifications
            .Where(n => n.CreatedAt < notificationCutoff)
            .ExecuteDeleteAsync();
        
        // Delete old form submissions (1 year)
        var formCutoff = DateTime.UtcNow.AddYears(-1);
        
        await _context.FormSubmissions
            .Where(f => f.CreatedAt < formCutoff)
            .ExecuteDeleteAsync();
    }
}
```

---

## 8. Security Testing

### 8.1 Static Application Security Testing (SAST)

**Current (ESLint Security Plugin)**
```bash
npm install --save-dev eslint-plugin-security

# .eslintrc.json
{
  "plugins": ["security"],
  "extends": ["plugin:security/recommended"]
}

# Run
npm run lint
```

**Target (Security Code Scan for .NET)**
```bash
dotnet add package SecurityCodeScan.VS2019

# Build (warnings treated as errors in CI)
dotnet build /p:TreatWarningsAsErrors=true
```

### 8.2 Dynamic Application Security Testing (DAST)

**OWASP ZAP**
```bash
# Run ZAP scan
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://staging.diskhastanesi.com \
  -r zap-report.html

# CI/CD integration
# .github/workflows/security.yml
- name: ZAP Scan
  uses: zaproxy/action-baseline@v0.7.0
  with:
    target: 'https://staging.diskhastanesi.com'
    rules_file_name: '.zap/rules.tsv'
    cmd_options: '-a'
```

### 8.3 Dependency Vulnerability Scanning

**npm audit (Current)**
```bash
# Check vulnerabilities
npm audit

# Fix automatically
npm audit fix

# CI/CD check
npm audit --production --audit-level=high
```

**Dependabot (GitHub)**
```.github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/web"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    
  - package-ecosystem: "nuget"
    directory: "/web"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
```

**Snyk (Recommended)**
```bash
# Install Snyk CLI
npm install -g snyk

# Authenticate
snyk auth

# Test
snyk test

# Monitor
snyk monitor

# CI/CD integration
snyk test --severity-threshold=high
```

### 8.4 Penetration Testing

**Scope**
- Authentication bypass
- Authorization issues
- SQL injection
- XSS
- CSRF
- Business logic flaws
- API abuse

**Schedule**
- Pre-launch: Full penetration test
- Quarterly: Automated scans
- Annually: Manual penetration test

**Vendors**
- Internal: Security team
- External: Certified penetration testing firm (OSCP, CEH)

---

## 9. Incident Response

### 9.1 Security Incident Classification

**Severity Levels**

| Level | Description | Response Time | Examples |
|-------|-------------|---------------|----------|
| **P0 - Critical** | Active breach, data exposure | 15 minutes | Database breach, credential leak |
| **P1 - High** | Potential breach, high impact | 1 hour | XSS vulnerability, auth bypass |
| **P2 - Medium** | Security weakness, medium impact | 4 hours | Outdated dependency, weak config |
| **P3 - Low** | Minor issue, low impact | 1 business day | Information disclosure, minor bug |

### 9.2 Incident Response Plan

**Phase 1: Detection & Analysis**
1. Alert received (Sentry, Azure Monitor, manual report)
2. Triage: Classify severity
3. Assemble response team
4. Initial investigation

**Phase 2: Containment**
1. Isolate affected systems
2. Block malicious actors (IP ban, disable accounts)
3. Preserve evidence (logs, database snapshots)
4. Implement temporary fixes

**Phase 3: Eradication**
1. Identify root cause
2. Remove malicious code/access
3. Patch vulnerabilities
4. Update security controls

**Phase 4: Recovery**
1. Restore systems from clean backups
2. Monitor for recurrence
3. Gradually restore normal operations
4. Validate security posture

**Phase 5: Post-Incident**
1. Root cause analysis
2. Document lessons learned
3. Update runbooks
4. Improve detection/prevention
5. Notify affected parties (if required by law)

### 9.3 Incident Response Runbook

**Suspected Data Breach**
```markdown
# Data Breach Response Runbook

## Immediate Actions (0-15 minutes)
1. Confirm breach (check logs, database)
2. Page on-call engineer
3. Isolate affected database/systems
4. Enable enhanced logging
5. Take database snapshot for forensics

## Short-term (15-60 minutes)
1. Identify scope: What data? How many users?
2. Contain: Disable compromised accounts, rotate credentials
3. Notify: CTO, legal team
4. Preserve evidence: Copy logs to secure location

## Medium-term (1-4 hours)
1. Root cause analysis
2. Patch vulnerability
3. Validate no ongoing access
4. Prepare user communication
5. Contact authorities if required (KVKK, data protection authority)

## Long-term (4-24 hours)
1. Notify affected users
2. Offer credit monitoring (if applicable)
3. File incident report with authorities
4. Update security controls
5. Post-mortem meeting

## Follow-up (1-7 days)
1. Implement additional security measures
2. Conduct security audit
3. Update documentation
4. Train team on lessons learned
5. Public disclosure (if required)
```

---

## 10. Compliance Checklist

### 10.1 KVKK Compliance

- [x] Privacy policy published
- [x] Cookie consent banner
- [x] Data processing agreement (DPA)
- [x] Data inventory maintained
- [x] Legal basis documented
- [x] Data subject rights procedures
- [x] Data retention policy
- [x] Breach notification procedure
- [x] DPO (Data Protection Officer) appointed
- [ ] KVKK registration completed (if required)

### 10.2 GDPR Compliance

- [x] Privacy policy compliant
- [x] Consent management
- [x] Data portability (export API)
- [x] Right to erasure (delete account)
- [x] Data Processing Agreement (DPA) with vendors
- [x] Vendor compliance verified
- [ ] EU representative appointed (if applicable)
- [ ] Transfer Impact Assessment for non-EU transfers

### 10.3 Security Best Practices

- [x] HTTPS enforced
- [x] Security headers configured
- [x] Input validation implemented
- [x] Output encoding/sanitization
- [x] Parameterized queries
- [x] Rate limiting
- [x] Authentication implemented
- [x] Authorization policies
- [x] Audit logging
- [x] Encryption at rest
- [x] Encryption in transit
- [x] Secrets management
- [x] Dependency scanning
- [x] Vulnerability scanning
- [ ] Penetration testing scheduled
- [ ] Security training for team

### 10.4 Operational Security

- [x] Automated backups
- [x] Disaster recovery plan
- [x] Incident response plan
- [x] Access control (least privilege)
- [x] MFA for admin accounts
- [x] Password policy
- [x] Session management
- [x] Monitoring & alerting
- [ ] SOC 2 audit (future)
- [ ] ISO 27001 certification (future)

---

**Son Güncelleme:** 2025-10-04
