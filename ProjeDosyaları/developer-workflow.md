# Geliştirici Workflow Rehberi

**Kaynak:** diskhastanesi.com projesi - Microsoft Stack'e taşıma için hazırlanmıştır

Bu dosya, projeyi geliştirirken izlenecek adımları, kullanılacak araçları ve best practice'leri içerir.

---

## 1. Geliştirme Ortamı Kurulumu

### 1.1 Gerekli Yazılımlar

**Mevcut Stack (Next.js + Supabase)**
- Node.js 18+ ve npm
- Git
- VS Code (önerilen IDE)
- Supabase CLI
- Docker (Supabase local için)

**Microsoft Stack**
- .NET SDK 8.0+
- Visual Studio 2022 / VS Code
- Azure CLI
- SQL Server Management Studio (SSMS)
- Azurite (Azure Storage Emulator)

### 1.2 Repo Klonlama ve Bağımlılık Kurulumu

**Next.js Projesi**
```bash
git clone https://github.com/oguzhanpisgin/diskhastanesi.com.git
cd diskhastanesi.com/web
npm install
```

**Microsoft Projesi**
```bash
git clone [azure-repo-url]
cd diskhastanesi-dotnet
dotnet restore
```

### 1.3 Supabase CLI Kurulumu ve Yerel Başlatma

```bash
# Supabase CLI kurulumu
npm install -g supabase

# Yerel Supabase başlatma
cd web
supabase start

# Migration'ları uygulama
supabase db reset
```

**Azure SQL Alternatifi**
```bash
# Azure SQL local emulator
# veya Docker SQL Server container
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong@Passw0rd" \
  -p 1433:1433 --name sql1 -d mcr.microsoft.com/mssql/server:2022-latest
```

### 1.4 Environment Variable Yapılandırması

**Next.js `.env.local`**
```env
NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=[local-anon-key]
SUPABASE_SERVICE_ROLE_KEY=[local-service-role-key]
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

**ASP.NET Core `appsettings.Development.json`**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=diskhastanesi;User Id=sa;Password=YourStrong@Passw0rd;"
  },
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "[tenant-id]",
    "ClientId": "[client-id]"
  }
}
```

### 1.5 VS Code Extension'ları ve Ayarları

**Önerilen Extension'lar**
- ESLint
- Prettier
- Edge DevTools
- GitLens
- Thunder Client (API test)
- Error Lens
- Tailwind CSS IntelliSense (Next.js için)

**Microsoft Stack için**
- C# Dev Kit
- Azure Tools
- SQL Server (mssql)
- REST Client

---

## 2. Proje Yapısı

### 2.1 Monorepo Organizasyonu

```
diskhastanesi.com/
├── web/                    # Next.js frontend
├── docs/                   # Divio dokümantasyon
├── mcp/                    # MCP server
├── scripts/                # Otomasyon scriptleri
├── prompts/                # AI prompt şablonları
├── AI-transition/          # Microsoft taşıma dokümanları
├── .vscode/                # VS Code ayarları
├── .github/                # GitHub Actions
└── PROJECT_RULES.md        # Proje kuralları
```

### 2.2 `web/` Dizini (Next.js App)

```
web/
├── src/
│   ├── app/                # Next.js App Router
│   │   ├── [locale]/       # Çok dilli routing
│   │   ├── api/            # API routes
│   │   └── globals.css
│   ├── components/         # React componentleri
│   ├── lib/                # Utility fonksiyonlar
│   └── messages/           # i18n dosyaları
├── public/                 # Static assets
├── supabase/               # Supabase config
│   ├── functions/          # Edge functions
│   └── migrations/         # SQL migrations
├── tests/                  # Test dosyaları
├── package.json
└── tsconfig.json
```

### 2.3 `docs/` Dizini (Divio Dokümantasyon)

```
docs/
├── index.md                # Ana hub
├── explanation/            # Kavramsal açıklamalar
├── how-to/                 # Görev rehberleri
├── reference/              # Teknik referans
├── tutorials/              # Öğreticiler
├── templates/              # Doküman şablonları
├── architecture/           # Mimari kararlar
├── qa/                     # Test ve QA
├── operations/             # Operasyon kılavuzları
└── updates/                # Değişiklik logları
```

### 2.4 `mcp/` Dizini (MCP Server)

```
mcp/
├── repo-docs-server/
│   ├── src/
│   ├── dist/
│   ├── package.json
│   └── tsconfig.json
└── repo-docs-server.config.json
```

### 2.5 `scripts/` Dizini (Otomasyon)

```
scripts/
├── chaos/                  # Kaos testi scriptleri
├── smoke/                  # Smoke test
├── seed/                   # Seed data
├── mcp-preflight.sh
├── mcp-smoke.sh
└── setup-edge-devtools.sh
```

### 2.6 `prompts/` Dizini (AI Prompt Şablonları)

```
prompts/
├── mcp-preflight.md
├── mcp-drift-review.md
├── mcp-onboarding.md
└── mcp-release-check.md
```

---

## 3. Geliştirme Workflow'u

### 3.1 Branch Oluşturma ve İsimlendirme

```bash
# Feature branch
git checkout -b feature/add-contact-form

# Bug fix branch
git checkout -b fix/lead-form-validation

# Refactor branch
git checkout -b refactor/optimize-database-queries

# Hotfix branch
git checkout -b hotfix/security-patch
```

### 3.2 Local Development Server Başlatma

**Next.js**
```bash
cd web
npm run dev
# http://localhost:3000
```

**ASP.NET Core**
```bash
cd Diskhastanesi.Web
dotnet watch run
# https://localhost:7001
```

### 3.3 Hot Reload ve Canlı Önizleme

- Next.js: Otomatik hot reload
- ASP.NET Core: `dotnet watch` ile hot reload
- Tarayıcıda değişiklikler anında yansır

### 3.4 Kod Yazma ve Linting

**Linting (Next.js)**
```bash
npm run lint
npm run lint --fix  # Otomatik düzeltme
```

**Linting (ASP.NET)**
```bash
dotnet format
```

### 3.5 Pre-commit Hooks

**Husky (Next.js)**
- Otomatik lint ve format
- Commit mesajı validasyonu
- Test çalıştırma (opsiyonel)

**Git Hooks (Microsoft)**
```bash
# .git/hooks/pre-commit
#!/bin/sh
dotnet format --verify-no-changes
dotnet test
```

### 3.6 Commit Mesajı Formatı

**Conventional Commits**
```
feat: add contact form validation
fix: resolve lead submission error
docs: update API documentation
style: format code with prettier
refactor: optimize database queries
perf: improve page load time
test: add unit tests for lead service
chore: update dependencies
security: patch XSS vulnerability
```

---

## 4. Test Süreci

### 4.1 Unit Test Yazma (Vitest)

**Next.js**
```typescript
// src/lib/__tests__/validation.test.ts
import { describe, it, expect } from 'vitest';
import { validateEmail } from '../validation';

describe('validateEmail', () => {
  it('should return true for valid email', () => {
    expect(validateEmail('test@example.com')).toBe(true);
  });

  it('should return false for invalid email', () => {
    expect(validateEmail('invalid-email')).toBe(false);
  });
});
```

**ASP.NET (xUnit)**
```csharp
// Tests/Services/LeadServiceTests.cs
public class LeadServiceTests
{
    [Fact]
    public void ValidateEmail_ValidEmail_ReturnsTrue()
    {
        // Arrange
        var email = "test@example.com";
        
        // Act
        var result = LeadService.ValidateEmail(email);
        
        // Assert
        Assert.True(result);
    }
}
```

### 4.2 Integration Test (Playwright)

**Next.js**
```bash
npm run test:e2e
```

**Playwright .NET**
```bash
dotnet test --filter FullyQualifiedName~E2ETests
```

### 4.3 E2E Test Senaryoları

```typescript
// tests/e2e/contact-form.spec.ts
import { test, expect } from '@playwright/test';

test('should submit contact form successfully', async ({ page }) => {
  await page.goto('/tr/iletisim');
  await page.fill('[name="name"]', 'Test User');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="message"]', 'Test message');
  await page.click('button[type="submit"]');
  await expect(page.locator('.success-message')).toBeVisible();
});
```

### 4.4 Test Coverage Kontrolü

```bash
npm run test -- --coverage

# Minimum %85 coverage gerekli
```

### 4.5 Edge Function Testleri

```bash
cd web
npm run test:notify-lead
```

### 4.6 Accessibility Testleri

```bash
npm run test:a11y
```

---

## 5. Build ve Deployment

### 5.1 Production Build Oluşturma

**Next.js**
```bash
npm run build
npm run start  # Production server
```

**ASP.NET Core**
```bash
dotnet publish -c Release -o ./publish
```

### 5.2 Vercel Deployment Süreci

1. Git push to `main` branch
2. Vercel otomatik build başlatır
3. Build başarılı → Production deploy
4. Preview URL oluşturulur

### 5.3 Supabase Migration'ları

```bash
# Yeni migration oluşturma
supabase migration new add_lead_status_column

# Migration'ları uygulama
supabase db push

# Remote'a push
supabase db push --linked
```

### 5.4 Environment Variable Yönetimi

**Vercel Dashboard**
- Environment Variables bölümünden ekle
- Production, Preview, Development ortamları ayrı

**Azure App Configuration**
```bash
az appconfig kv set --name diskhastanesi-config \
  --key "ConnectionStrings:DefaultConnection" \
  --value "Server=..."
```

### 5.5 Edge Function Deploy

```bash
# Supabase Edge Functions
supabase functions deploy notify-lead

# Azure Functions
func azure functionapp publish diskhastanesi-functions
```

### 5.6 Rollback Prosedürü

**Vercel**
- Dashboard → Deployments → Previous deployment → "Rollback"

**Azure**
```bash
az webapp deployment slot swap \
  --name diskhastanesi \
  --resource-group diskhastanesi-rg \
  --slot staging
```

---

## 6. Debugging

### 6.1 VS Code Debugger Yapılandırması

**launch.json (Next.js)**
```json
{
  "type": "msedge",
  "request": "launch",
  "name": "Launch Edge",
  "url": "http://localhost:3000",
  "webRoot": "${workspaceFolder}/web"
}
```

**launch.json (ASP.NET)**
```json
{
  "type": "coreclr",
  "request": "launch",
  "name": ".NET Core Launch (web)",
  "program": "${workspaceFolder}/bin/Debug/net8.0/Diskhastanesi.Web.dll",
  "cwd": "${workspaceFolder}"
}
```

### 6.2 Edge DevTools Kullanımı

1. VS Code'da F5 (Launch Edge)
2. Edge DevTools otomatik açılır
3. Network, Console, Performance tabs kullan

### 6.3 Sentry Error Tracking

- Hata oluştuğunda Sentry'de görünür
- Stack trace analizi
- Breadcrumbs takibi
- User session replay

### 6.4 Log Analizi

**Console logs (development)**
```typescript
console.log('Debug info:', data);
console.error('Error occurred:', error);
```

**Sentry (production)**
```typescript
Sentry.captureException(error, {
  tags: { section: 'lead-form' },
  extra: { formData }
});
```

### 6.5 Performance Profiling

**Chrome DevTools**
- Performance tab
- Lighthouse audit
- Network waterfall

**Application Insights**
- Performance dashboard
- Slow request tracking
- Dependency analysis

---

## 7. Modül Geliştirme Rehberi

### 7.1 Component Oluşturma

```typescript
// src/components/ContactForm.tsx
'use client';

import { useState } from 'react';

export function ContactForm() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    message: ''
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    // Form submission logic
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
    </form>
  );
}
```

### 7.2 API Route Geliştirme

**Next.js API Route**
```typescript
// src/app/api/leads/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const body = await request.json();
  
  // Validation
  if (!body.email) {
    return NextResponse.json(
      { error: 'Email is required' },
      { status: 400 }
    );
  }

  // Save to database
  // ...

  return NextResponse.json({ success: true });
}
```

**ASP.NET Minimal API**
```csharp
app.MapPost("/api/leads", async (LeadRequest request, LeadService service) =>
{
    if (string.IsNullOrEmpty(request.Email))
    {
        return Results.BadRequest(new { error = "Email is required" });
    }

    await service.CreateLeadAsync(request);
    return Results.Ok(new { success = true });
});
```

### 7.3 Database Query Yazma

**Supabase (TypeScript)**
```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(url, key);

// Insert
const { data, error } = await supabase
  .from('leads')
  .insert({ name, email, phone });

// Select
const { data } = await supabase
  .from('leads')
  .select('*')
  .eq('status', 'new');
```

**Entity Framework Core**
```csharp
// Insert
var lead = new Lead { Name = name, Email = email };
await _context.Leads.AddAsync(lead);
await _context.SaveChangesAsync();

// Select
var leads = await _context.Leads
  .Where(l => l.Status == LeadStatus.New)
  .ToListAsync();
```

### 7.4 i18n İçerik Ekleme

**Next.js (next-intl)**
```typescript
// messages/tr/common.json
{
  "nav": {
    "home": "Ana Sayfa",
    "about": "Hakkımızda",
    "contact": "İletişim"
  }
}

// Component'te kullanım
import { useTranslations } from 'next-intl';

const t = useTranslations('common');
<a href="/">{t('nav.home')}</a>
```

**ASP.NET Core (Resource files)**
```xml
<!-- Resources/Common.tr.resx -->
<data name="Nav.Home">
  <value>Ana Sayfa</value>
</data>

<!-- Razor'da kullanım -->
@Localizer["Nav.Home"]
```

### 7.5 Form Validasyon

**Zod (Next.js)**
```typescript
import { z } from 'zod';

const leadSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  phone: z.string().regex(/^\+?[1-9]\d{1,14}$/)
});

const result = leadSchema.safeParse(formData);
if (!result.success) {
  console.error(result.error);
}
```

**FluentValidation (ASP.NET)**
```csharp
public class LeadValidator : AbstractValidator<LeadRequest>
{
    public LeadValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MinimumLength(2);
        RuleFor(x => x.Email).EmailAddress();
        RuleFor(x => x.Phone).Matches(@"^\+?[1-9]\d{1,14}$");
    }
}
```

---

## 8. Kod Kalite Araçları

### 8.1 ESLint Kuralları

```json
// .eslintrc.json
{
  "extends": ["next/core-web-vitals", "prettier"],
  "rules": {
    "no-console": "warn",
    "prefer-const": "error",
    "@typescript-eslint/no-unused-vars": "error"
  }
}
```

### 8.2 Prettier Formatı

```json
// .prettierrc
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2
}
```

### 8.3 TypeScript Strict Mode

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true
  }
}
```

### 8.4 Husky Hooks

```json
// package.json
{
  "scripts": {
    "prepare": "husky install"
  }
}
```

```bash
# .husky/pre-commit
#!/bin/sh
npm run lint
npm run format:check
```

### 8.5 lint-staged Konfigürasyonu

```json
// package.json
{
  "lint-staged": {
    "**/*.{ts,tsx,js,jsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "**/*.{json,md,css}": "prettier --write"
  }
}
```

---

## 9. Dokümantasyon Yazma

### 9.1 Divio Framework Kullanımı

- **Tutorials**: Adım adım öğretici
- **How-to Guides**: Belirli görev çözümleri
- **Reference**: Teknik API/config referansı
- **Explanation**: Kavramsal açıklamalar

### 9.2 Şablon Seçimi (`docs/templates/`)

```bash
# Yeni doküman oluştur
cp docs/templates/how-to-template.md docs/how-to/setup-local-env.md
```

### 9.3 Markdown Standartları

- Başlıklar: `#`, `##`, `###`
- Kod blokları: ` ```typescript ` 
- Linkler: `[text](url)`
- Listeler: `-` veya `1.`

### 9.4 ADR (Architecture Decision Record) Yazma

```markdown
# ADR-001: Next.js yerine ASP.NET Core kullanımı

## Durum
Kabul Edildi

## Bağlam
Microsoft stack'e geçiş için frontend framework kararı

## Karar
ASP.NET Core Razor Pages kullanacağız

## Sonuçlar
- .NET ekosistemi entegrasyonu
- Azure servisleri ile uyum
- Ekip .NET uzmanlığı
```

### 9.5 README Güncelleme

Her modül için README.md:
- Amaç
- Kurulum
- Kullanım
- API
- Örnekler

---

## 10. Observability ve Monitoring

### 10.1 Sentry Entegrasyonu

```typescript
// sentry.client.config.ts
Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.2,
  replaysSessionSampleRate: 0.1
});
```

### 10.2 Application Insights

```csharp
// Program.cs
builder.Services.AddApplicationInsightsTelemetry(
    builder.Configuration["ApplicationInsights:ConnectionString"]
);
```

### 10.3 Log Toplama

**Pino (Next.js)**
```typescript
import pino from 'pino';

const logger = pino();
logger.info({ userId: 123 }, 'User logged in');
```

**Serilog (ASP.NET)**
```csharp
Log.Information("User {UserId} logged in", userId);
```

### 10.4 Performance Metrikleri

- Core Web Vitals tracking
- API response time
- Database query duration
- Memory usage

### 10.5 Alert Yapılandırması

**Sentry**
- Error rate > 10/min
- Response time > 2s
- Memory usage > 80%

**Azure Monitor**
- CPU > 80%
- Failed requests > 5%
- 5xx errors

---

## 11. Güvenlik Best Practices

### 11.1 Secret Yönetimi

**Never commit**
- `.env` files
- API keys
- Database passwords

**Use**
- `.env.example` şablonları
- Azure Key Vault
- GitHub Secrets (CI/CD)

### 11.2 Dependency Güncellemeleri

```bash
# Güvenlik açıklarını kontrol et
npm audit

# Otomatik güncelleme
npm audit fix

# Dependabot (GitHub)
# Otomatik PR oluşturur
```

### 11.3 Security Scan

```bash
# Snyk
npx snyk test

# OWASP Dependency Check
dotnet list package --vulnerable
```

### 11.4 CORS Yapılandırması

**Next.js (next.config.ts)**
```typescript
module.exports = {
  async headers() {
    return [
      {
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: 'https://diskhastanesi.com' }
        ]
      }
    ];
  }
};
```

**ASP.NET Core**
```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowedOrigins", policy =>
    {
        policy.WithOrigins("https://diskhastanesi.com")
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});
```

### 11.5 Input Validation

- Client-side: Zod, FluentValidation
- Server-side: Always validate
- Sanitize HTML inputs
- Parameterized queries

---

## 12. CI/CD Pipeline

### 12.1 GitHub Actions Workflow'ları

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm test -- --coverage
```

### 12.2 Build Steps

1. Checkout code
2. Install dependencies
3. Lint
4. Test
5. Build
6. Deploy

### 12.3 Test Automation

```yaml
test:
  steps:
    - run: npm test
    - run: npm run test:e2e
    - run: npm run test:a11y
```

### 12.4 Deployment Triggers

- `main` branch → Production
- `develop` branch → Staging
- Pull request → Preview

### 12.5 Pipeline Debugging

- GitHub Actions logs
- Failed step analizi
- Re-run with debug logging

---

## 13. Troubleshooting

### 13.1 Sık Karşılaşılan Hatalar

**Build Failure**
- Node/npm sürüm uyumsuzluğu
- Missing dependencies
- TypeScript type errors

**Database Connection**
- Wrong connection string
- Firewall rules
- Authentication errors

### 13.2 Build Failure Çözümleri

```bash
# Clear cache
rm -rf node_modules .next
npm install

# Rebuild
npm run build
```

### 13.3 Database Connection Sorunları

```bash
# Test connection
npx supabase status

# Restart local DB
supabase stop
supabase start
```

### 13.4 Port Çakışması

```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or use different port
npm run dev -- -p 3001
```

### 13.5 Cache Temizleme

```bash
# Next.js
rm -rf .next

# npm
npm cache clean --force

# Browser
# Hard refresh (Ctrl+Shift+R)
```

---

## 14. Microsoft Stack'e Taşıma

### 14.1 .NET SDK Kurulumu

```bash
# Ubuntu/Debian
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --version 8.0

# Windows
# Download from https://dotnet.microsoft.com/download
```

### 14.2 Visual Studio Setup

1. Visual Studio 2022 indir
2. Workload seç: ASP.NET and web development
3. Azure development workload
4. .NET 8.0 SDK

### 14.3 Azure CLI Kurulumu

```bash
# Ubuntu
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login
```

### 14.4 Azure Resource Oluşturma

```bash
# Resource group
az group create --name diskhastanesi-rg --location westeurope

# App Service plan
az appservice plan create --name diskhastanesi-plan \
  --resource-group diskhastanesi-rg --sku B1

# Web app
az webapp create --name diskhastanesi \
  --resource-group diskhastanesi-rg \
  --plan diskhastanesi-plan
```

### 14.5 Migration Checklist

- [ ] .NET proje oluştur
- [ ] Azure SQL database setup
- [ ] Connection string yapılandır
- [ ] Entity Framework migrations
- [ ] Azure AD B2C setup
- [ ] Application Insights entegre et
- [ ] Azure Key Vault secret'ları taşı
- [ ] Azure Blob Storage setup
- [ ] Azure Functions oluştur
- [ ] CI/CD pipeline (Azure DevOps)
- [ ] Domain DNS ayarları
- [ ] SSL certificate
- [ ] Performance test
- [ ] Production deploy

---

**Son Güncelleme:** 2025-10-04
