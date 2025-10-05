# Test Stratejisi Dokümantasyonu

**Kaynak:** diskhastanesi.com projesi - Microsoft Stack'e taşıma için hazırlanmıştır

Bu dosya, test piramidini, test senaryolarını, automation coverage hedeflerini ve performans testlerini içerir.

---

## 1. Test Stratejisi Genel Bakış

### 1.1 Test Piramidi

```
                      /\
                     /  \
                    / E2E \
                   /  Tests \
                  /----------\
                 /   API &    \
                / Integration  \
               /     Tests      \
              /------------------\
             /                    \
            /    Unit Tests        \
           /________________________\
```

**Test Dağılımı**
- Unit Tests: %70 (hızlı, izole, çok sayıda)
- Integration Tests: %20 (orta hızlı, component etkileşimi)
- E2E Tests: %10 (yavaş, kritik user flow'lar)

### 1.2 Testing Philosophy

**Principles**
- Test First: TDD approach (unit tests için)
- Test Coverage: Minimum %85 overall, %95 critical paths
- Fast Feedback: Unit tests <5s, Integration <30s, E2E <5min
- Reliable: Flaky test oranı <%1
- Maintainable: Açık, okunabilir test code

**Current Stack**
- Unit: Vitest
- E2E: Playwright
- Accessibility: Playwright + axe-core
- Visual Regression: Playwright screenshots

**Target Stack**
- Unit: xUnit
- Integration: xUnit + WebApplicationFactory
- E2E: Playwright (continue)
- Load: Apache JMeter / Azure Load Testing
- API: Postman / Rest Client

---

## 2. Unit Testing

### 2.1 Current (Vitest + React Testing Library)

**Configuration**
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './test/setup.ts',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'test/',
        '**/*.config.*',
        '**/*.d.ts',
      ],
      thresholds: {
        lines: 85,
        functions: 85,
        branches: 80,
        statements: 85
      }
    }
  }
});
```

**Example Tests**
```typescript
// components/LeadForm.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { LeadForm } from './LeadForm';

describe('LeadForm', () => {
  it('renders form fields', () => {
    render(<LeadForm />);
    
    expect(screen.getByLabelText('Name')).toBeInTheDocument();
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
    expect(screen.getByLabelText('Phone')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Submit' })).toBeInTheDocument();
  });
  
  it('validates required fields', async () => {
    render(<LeadForm />);
    
    const submitButton = screen.getByRole('button', { name: 'Submit' });
    fireEvent.click(submitButton);
    
    await waitFor(() => {
      expect(screen.getByText('Name is required')).toBeInTheDocument();
      expect(screen.getByText('Email is required')).toBeInTheDocument();
    });
  });
  
  it('validates email format', async () => {
    render(<LeadForm />);
    
    const emailInput = screen.getByLabelText('Email');
    fireEvent.change(emailInput, { target: { value: 'invalid-email' } });
    fireEvent.blur(emailInput);
    
    await waitFor(() => {
      expect(screen.getByText('Invalid email format')).toBeInTheDocument();
    });
  });
  
  it('submits valid form data', async () => {
    const onSubmit = vi.fn();
    render(<LeadForm onSubmit={onSubmit} />);
    
    fireEvent.change(screen.getByLabelText('Name'), {
      target: { value: 'Ahmet Yılmaz' }
    });
    fireEvent.change(screen.getByLabelText('Email'), {
      target: { value: 'ahmet@example.com' }
    });
    fireEvent.change(screen.getByLabelText('Phone'), {
      target: { value: '+905551234567' }
    });
    
    fireEvent.click(screen.getByRole('button', { name: 'Submit' }));
    
    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        name: 'Ahmet Yılmaz',
        email: 'ahmet@example.com',
        phone: '+905551234567'
      });
    });
  });
});
```

### 2.2 Target (xUnit + Moq)

**Project Structure**
```
Web.Tests/
├── Unit/
│   ├── Controllers/
│   │   ├── LeadsControllerTests.cs
│   │   └── ContentControllerTests.cs
│   ├── Services/
│   │   ├── LeadServiceTests.cs
│   │   └── EmailServiceTests.cs
│   └── Validators/
│       └── LeadRequestValidatorTests.cs
├── Integration/
│   └── Api/
│       └── LeadsApiTests.cs
└── Web.Tests.csproj
```

**Configuration**
```xml
<!-- Web.Tests.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.9.0" />
    <PackageReference Include="xunit" Version="2.7.0" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.5.7" />
    <PackageReference Include="Moq" Version="4.20.70" />
    <PackageReference Include="FluentAssertions" Version="6.12.0" />
    <PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="8.0.3" />
    <PackageReference Include="coverlet.collector" Version="6.0.1" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\Web\Web.csproj" />
  </ItemGroup>
</Project>
```

**Example Tests**
```csharp
// LeadsControllerTests.cs
using Xunit;
using Moq;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Web.Controllers;
using Web.Services;
using Web.Models;

public class LeadsControllerTests
{
    private readonly Mock<ILeadService> _leadServiceMock;
    private readonly LeadsController _controller;
    
    public LeadsControllerTests()
    {
        _leadServiceMock = new Mock<ILeadService>();
        _controller = new LeadsController(_leadServiceMock.Object);
    }
    
    [Fact]
    public async Task CreateLead_ValidRequest_ReturnsCreated()
    {
        // Arrange
        var request = new LeadRequest
        {
            Name = "Ahmet Yılmaz",
            Email = "ahmet@example.com",
            Phone = "+905551234567",
            Service = "veri-kurtarma",
            Message = "Test message"
        };
        
        var expectedLead = new Lead
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Email = request.Email,
            Status = "new"
        };
        
        _leadServiceMock
            .Setup(s => s.CreateLeadAsync(It.IsAny<LeadRequest>()))
            .ReturnsAsync(expectedLead);
        
        // Act
        var result = await _controller.CreateLead(request);
        
        // Assert
        var createdResult = result.Should().BeOfType<CreatedAtActionResult>().Subject;
        createdResult.StatusCode.Should().Be(201);
        
        var lead = createdResult.Value.Should().BeOfType<LeadResponse>().Subject;
        lead.Id.Should().Be(expectedLead.Id);
        lead.Name.Should().Be(expectedLead.Name);
        
        _leadServiceMock.Verify(
            s => s.CreateLeadAsync(It.Is<LeadRequest>(r => r.Email == request.Email)),
            Times.Once);
    }
    
    [Fact]
    public async Task GetLead_ExistingId_ReturnsLead()
    {
        // Arrange
        var leadId = Guid.NewGuid();
        var expectedLead = new Lead
        {
            Id = leadId,
            Name = "Ahmet Yılmaz",
            Email = "ahmet@example.com",
            Status = "new"
        };
        
        _leadServiceMock
            .Setup(s => s.GetLeadByIdAsync(leadId))
            .ReturnsAsync(expectedLead);
        
        // Act
        var result = await _controller.GetLead(leadId);
        
        // Assert
        var okResult = result.Should().BeOfType<OkObjectResult>().Subject;
        var lead = okResult.Value.Should().BeOfType<LeadResponse>().Subject;
        lead.Id.Should().Be(leadId);
    }
    
    [Fact]
    public async Task GetLead_NonExistingId_ReturnsNotFound()
    {
        // Arrange
        var leadId = Guid.NewGuid();
        _leadServiceMock
            .Setup(s => s.GetLeadByIdAsync(leadId))
            .ReturnsAsync((Lead?)null);
        
        // Act
        var result = await _controller.GetLead(leadId);
        
        // Assert
        result.Should().BeOfType<NotFoundResult>();
    }
}
```

**Validator Tests**
```csharp
// LeadRequestValidatorTests.cs
using Xunit;
using FluentAssertions;
using FluentValidation.TestHelper;
using Web.Validators;
using Web.Models;

public class LeadRequestValidatorTests
{
    private readonly LeadRequestValidator _validator;
    
    public LeadRequestValidatorTests()
    {
        _validator = new LeadRequestValidator();
    }
    
    [Fact]
    public void Validate_ValidRequest_ShouldNotHaveErrors()
    {
        // Arrange
        var request = new LeadRequest
        {
            Name = "Ahmet Yılmaz",
            Email = "ahmet@example.com",
            Phone = "+905551234567",
            Service = "veri-kurtarma",
            Message = "Test message"
        };
        
        // Act
        var result = _validator.TestValidate(request);
        
        // Assert
        result.ShouldNotHaveAnyValidationErrors();
    }
    
    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void Validate_EmptyName_ShouldHaveError(string name)
    {
        // Arrange
        var request = new LeadRequest { Name = name };
        
        // Act
        var result = _validator.TestValidate(request);
        
        // Assert
        result.ShouldHaveValidationErrorFor(r => r.Name);
    }
    
    [Theory]
    [InlineData("invalid-email")]
    [InlineData("@example.com")]
    [InlineData("test@")]
    public void Validate_InvalidEmail_ShouldHaveError(string email)
    {
        // Arrange
        var request = new LeadRequest { Email = email };
        
        // Act
        var result = _validator.TestValidate(request);
        
        // Assert
        result.ShouldHaveValidationErrorFor(r => r.Email);
    }
    
    [Theory]
    [InlineData("123456")] // Too short
    [InlineData("+905551")] // Incomplete
    [InlineData("05551234567")] // Missing +90
    public void Validate_InvalidPhone_ShouldHaveError(string phone)
    {
        // Arrange
        var request = new LeadRequest { Phone = phone };
        
        // Act
        var result = _validator.TestValidate(request);
        
        // Assert
        result.ShouldHaveValidationErrorFor(r => r.Phone);
    }
}
```

### 2.3 Test Coverage Requirements

**Minimum Coverage**
- Overall: 85%
- Controllers: 90%
- Services: 95%
- Validators: 100%
- Utilities: 90%

**Excluded from Coverage**
- Program.cs / Startup.cs
- Data models (POCOs)
- Migrations
- Auto-generated code

**Coverage Report**
```bash
# Current (Vitest)
npm run test:coverage

# Target (Coverlet)
dotnet test /p:CollectCoverage=true /p:CoverageReportsDirectory=./coverage /p:CoverletOutputFormat=cobertura

# Generate HTML report
reportgenerator -reports:coverage/coverage.cobertura.xml -targetdir:coverage/html
```

---

## 3. Integration Testing

### 3.1 API Integration Tests

**Current (Vitest + MSW)**
```typescript
// api/leads.integration.test.ts
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';

const server = setupServer(
  http.post('/api/leads', async ({ request }) => {
    const body = await request.json();
    
    return HttpResponse.json({
      success: true,
      data: {
        id: 'test-id',
        ...body,
        status: 'new'
      }
    }, { status: 201 });
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('Leads API Integration', () => {
  it('creates lead successfully', async () => {
    const response = await fetch('/api/leads', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Ahmet Yılmaz',
        email: 'ahmet@example.com',
        phone: '+905551234567',
        service: 'veri-kurtarma',
        message: 'Test'
      })
    });
    
    expect(response.status).toBe(201);
    const data = await response.json();
    expect(data.success).toBe(true);
    expect(data.data.status).toBe('new');
  });
});
```

**Target (WebApplicationFactory)**
```csharp
// LeadsApiTests.cs
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using System.Net.Http.Json;
using Xunit;
using FluentAssertions;

public class LeadsApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;
    
    public LeadsApiTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Replace DbContext with in-memory database
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                
                if (descriptor != null)
                    services.Remove(descriptor);
                
                services.AddDbContext<AppDbContext>(options =>
                {
                    options.UseInMemoryDatabase("TestDb");
                });
            });
        });
        
        _client = _factory.CreateClient();
    }
    
    [Fact]
    public async Task POST_CreateLead_ValidRequest_ReturnsCreated()
    {
        // Arrange
        var request = new
        {
            name = "Ahmet Yılmaz",
            email = "ahmet@example.com",
            phone = "+905551234567",
            service = "veri-kurtarma",
            message = "Test message",
            captchaToken = "test-token"
        };
        
        // Act
        var response = await _client.PostAsJsonAsync("/api/leads", request);
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        
        var lead = await response.Content.ReadFromJsonAsync<LeadResponse>();
        lead.Should().NotBeNull();
        lead!.Name.Should().Be(request.name);
        lead.Email.Should().Be(request.email);
        lead.Status.Should().Be("new");
    }
    
    [Fact]
    public async Task POST_CreateLead_InvalidEmail_ReturnsBadRequest()
    {
        // Arrange
        var request = new
        {
            name = "Ahmet Yılmaz",
            email = "invalid-email",
            phone = "+905551234567",
            service = "veri-kurtarma",
            message = "Test"
        };
        
        // Act
        var response = await _client.PostAsJsonAsync("/api/leads", request);
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }
    
    [Fact]
    public async Task GET_GetLead_ExistingId_ReturnsOk()
    {
        // Arrange - Create a lead first
        var createRequest = new
        {
            name = "Test User",
            email = "test@example.com",
            phone = "+905551234567",
            service = "veri-kurtarma",
            message = "Test",
            captchaToken = "test-token"
        };
        
        var createResponse = await _client.PostAsJsonAsync("/api/leads", createRequest);
        var createdLead = await createResponse.Content.ReadFromJsonAsync<LeadResponse>();
        
        // Act
        var response = await _client.GetAsync($"/api/leads/{createdLead!.Id}");
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        
        var lead = await response.Content.ReadFromJsonAsync<LeadResponse>();
        lead.Should().NotBeNull();
        lead!.Id.Should().Be(createdLead.Id);
    }
}
```

### 3.2 Database Integration Tests

```csharp
// LeadServiceIntegrationTests.cs
public class LeadServiceIntegrationTests : IDisposable
{
    private readonly AppDbContext _context;
    private readonly LeadService _service;
    
    public LeadServiceIntegrationTests()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        
        _context = new AppDbContext(options);
        _service = new LeadService(_context);
    }
    
    [Fact]
    public async Task CreateLead_SavesToDatabase()
    {
        // Arrange
        var request = new LeadRequest
        {
            Name = "Ahmet Yılmaz",
            Email = "ahmet@example.com",
            Phone = "+905551234567",
            Service = "veri-kurtarma",
            Message = "Test"
        };
        
        // Act
        var lead = await _service.CreateLeadAsync(request);
        
        // Assert
        var savedLead = await _context.Leads.FindAsync(lead.Id);
        savedLead.Should().NotBeNull();
        savedLead!.Name.Should().Be(request.Name);
        savedLead.Status.Should().Be("new");
    }
    
    [Fact]
    public async Task UpdateLeadStatus_UpdatesDatabase()
    {
        // Arrange
        var lead = new Lead
        {
            Id = Guid.NewGuid(),
            Name = "Test User",
            Email = "test@example.com",
            Phone = "+905551234567",
            Service = "veri-kurtarma",
            Message = "Test",
            Status = "new"
        };
        
        _context.Leads.Add(lead);
        await _context.SaveChangesAsync();
        
        // Act
        await _service.UpdateLeadStatusAsync(lead.Id, "contacted");
        
        // Assert
        var updatedLead = await _context.Leads.FindAsync(lead.Id);
        updatedLead!.Status.Should().Be("contacted");
        updatedLead.UpdatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
    }
    
    public void Dispose()
    {
        _context.Dispose();
    }
}
```

---

## 4. End-to-End Testing

### 4.1 Playwright Configuration

**Current & Target (same)**
```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html'],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['json', { outputFile: 'test-results/results.json' }]
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

### 4.2 Critical User Flows

**Lead Submission Flow**
```typescript
// tests/e2e/lead-submission.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Lead Submission Flow', () => {
  test('submits lead form successfully', async ({ page }) => {
    // Navigate to homepage
    await page.goto('/');
    
    // Click "Teklif Al" button
    await page.getByRole('link', { name: 'Teklif Al' }).click();
    await expect(page).toHaveURL('/teklif-al');
    
    // Fill form
    await page.getByLabel('Ad Soyad').fill('Ahmet Yılmaz');
    await page.getByLabel('E-posta').fill('ahmet@example.com');
    await page.getByLabel('Telefon').fill('+905551234567');
    await page.getByLabel('Şirket').fill('Example Corp');
    
    // Select service
    await page.getByLabel('Hizmet').selectOption('veri-kurtarma');
    
    // Fill message
    await page.getByLabel('Mesaj').fill('Acil veri kurtarma ihtiyacımız var.');
    
    // Solve captcha (mock in test environment)
    await page.evaluate(() => {
      (window as any).hcaptcha = {
        execute: () => Promise.resolve('test-token')
      };
    });
    
    // Submit form
    await page.getByRole('button', { name: 'Gönder' }).click();
    
    // Verify success message
    await expect(page.getByText('Talebiniz başarıyla alındı')).toBeVisible();
    
    // Verify redirect to success page
    await expect(page).toHaveURL(/\/teklif-al\/basarili/);
  });
  
  test('shows validation errors for empty fields', async ({ page }) => {
    await page.goto('/teklif-al');
    
    // Try to submit without filling
    await page.getByRole('button', { name: 'Gönder' }).click();
    
    // Verify validation errors
    await expect(page.getByText('Ad Soyad gereklidir')).toBeVisible();
    await expect(page.getByText('E-posta gereklidir')).toBeVisible();
    await expect(page.getByText('Telefon gereklidir')).toBeVisible();
  });
  
  test('validates email format', async ({ page }) => {
    await page.goto('/teklif-al');
    
    await page.getByLabel('E-posta').fill('invalid-email');
    await page.getByLabel('E-posta').blur();
    
    await expect(page.getByText('Geçersiz e-posta formatı')).toBeVisible();
  });
});
```

**Navigation & Content Flow**
```typescript
// tests/e2e/navigation.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Site Navigation', () => {
  test('navigates through main pages', async ({ page }) => {
    // Homepage
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'Disk Hastanesi' })).toBeVisible();
    
    // Veri Kurtarma page
    await page.getByRole('link', { name: 'Veri Kurtarma' }).click();
    await expect(page).toHaveURL('/veri-kurtarma');
    await expect(page.getByRole('heading', { name: 'Veri Kurtarma Hizmetleri' })).toBeVisible();
    
    // Siber Güvenlik page
    await page.getByRole('link', { name: 'Siber Güvenlik' }).click();
    await expect(page).toHaveURL('/siber-guvenlik');
    
    // Vaka Analizleri
    await page.getByRole('link', { name: 'Vaka Analizleri' }).click();
    await expect(page).toHaveURL('/vaka-analizleri');
    
    // Click first case study
    await page.getByRole('article').first().click();
    await expect(page).toHaveURL(/\/vaka-analizleri\/.+/);
  });
  
  test('mobile menu works', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
    
    // Open mobile menu
    await page.getByRole('button', { name: 'Menu' }).click();
    await expect(page.getByRole('navigation')).toBeVisible();
    
    // Click menu item
    await page.getByRole('link', { name: 'Hizmetler' }).click();
    await expect(page).toHaveURL('/hizmetler');
  });
});
```

### 4.3 Test Data Management

**Test Fixtures**
```typescript
// tests/fixtures/leads.ts
export const testLeads = {
  valid: {
    name: 'Ahmet Yılmaz',
    email: 'ahmet.test@example.com',
    phone: '+905551234567',
    company: 'Test Corp',
    service: 'veri-kurtarma',
    message: 'Test message for automated testing'
  },
  
  invalidEmail: {
    name: 'Test User',
    email: 'invalid-email',
    phone: '+905551234567',
    service: 'veri-kurtarma',
    message: 'Test'
  }
};
```

**Database Seeding**
```csharp
// SeedData.cs
public static class SeedData
{
    public static async Task SeedTestData(AppDbContext context)
    {
        if (await context.Users.AnyAsync())
            return; // Already seeded
        
        var adminUser = new User
        {
            Id = Guid.NewGuid(),
            Email = "admin@test.local",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("TestPassword123!"),
            FullName = "Test Admin",
            Role = "admin",
            IsActive = true
        };
        
        context.Users.Add(adminUser);
        await context.SaveChangesAsync();
    }
}
```

---

## 5. Performance Testing

### 5.1 Load Testing Strategy

**Test Scenarios**
1. **Normal Load**: Expected daily traffic
   - Duration: 1 hour
   - Users: 100 concurrent
   - Requests: ~10,000/hour

2. **Peak Load**: Expected peak times
   - Duration: 30 minutes
   - Users: 500 concurrent
   - Requests: ~50,000/hour

3. **Stress Test**: System limits
   - Duration: 1 hour
   - Users: Start 100, ramp to 2000
   - Find breaking point

4. **Spike Test**: Sudden traffic surge
   - Users: 100 → 1000 → 100
   - Duration: 15 min surge
   - Test recovery

### 5.2 Performance Metrics

**Target SLIs (Service Level Indicators)**
- Response time p50: <200ms
- Response time p95: <500ms
- Response time p99: <1000ms
- Error rate: <0.1%
- Throughput: >100 RPS
- Concurrent users: >500

**Infrastructure Metrics**
- CPU usage: <70%
- Memory usage: <80%
- Database connections: <80% pool
- Cache hit rate: >90%

### 5.3 Load Testing Tools

**Apache JMeter**
```xml
<!-- LoadTest.jmx -->
<jmeterTestPlan>
  <hashTree>
    <TestPlan>
      <stringProp name="TestPlan.comments">Disk Hastanesi Load Test</stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
    </TestPlan>
    
    <ThreadGroup>
      <stringProp name="ThreadGroup.num_threads">100</stringProp>
      <stringProp name="ThreadGroup.ramp_time">60</stringProp>
      <stringProp name="ThreadGroup.duration">3600</stringProp>
    </ThreadGroup>
    
    <HTTPSamplerProxy>
      <stringProp name="HTTPSampler.domain">diskhastanesi.com</stringProp>
      <stringProp name="HTTPSampler.path">/</stringProp>
      <stringProp name="HTTPSampler.method">GET</stringProp>
    </HTTPSamplerProxy>
  </hashTree>
</jmeterTestPlan>
```

**Azure Load Testing**
```yaml
# load-test.yaml
version: v0.1
testName: DiskhastanesiLoadTest
testPlan: LoadTest.jmx
configurationFiles:
  - test-data.csv
engineInstances: 5
loadTestConfiguration:
  optedOutIntervalForMetricsCollection: false
  reportDuration: 60
secrets:
  - name: API_KEY
    value: $(API_KEY)
env:
  - name: BASE_URL
    value: https://diskhastanesi.com
```

**Run Load Test**
```bash
# Using JMeter CLI
jmeter -n -t LoadTest.jmx -l results.jtl -e -o report/

# Using Azure Load Testing
az load test create \
  --name diskhastanesi-load-test \
  --resource-group rg-diskhastanesi \
  --load-test-config-file load-test.yaml
```

---

## 6. Accessibility Testing

### 6.1 Automated Accessibility Tests

**Playwright + axe-core**
```typescript
// tests/e2e/accessibility.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Accessibility Tests', () => {
  test('homepage has no accessibility violations', async ({ page }) => {
    await page.goto('/');
    
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
      .analyze();
    
    expect(accessibilityScanResults.violations).toEqual([]);
  });
  
  test('lead form has no accessibility violations', async ({ page }) => {
    await page.goto('/teklif-al');
    
    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();
    
    expect(accessibilityScanResults.violations).toEqual([]);
  });
  
  test('keyboard navigation works', async ({ page }) => {
    await page.goto('/');
    
    // Tab through navigation
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: 'Ana Sayfa' })).toBeFocused();
    
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: 'Hizmetler' })).toBeFocused();
    
    // Enter to activate link
    await page.keyboard.press('Enter');
    await expect(page).toHaveURL('/hizmetler');
  });
});
```

### 6.2 Manual Accessibility Checklist

**WCAG 2.1 AA Compliance**
- [ ] All images have alt text
- [ ] Form fields have labels
- [ ] Color contrast ratio ≥4.5:1
- [ ] Focus indicators visible
- [ ] Keyboard navigation works
- [ ] Screen reader tested (NVDA, JAWS)
- [ ] Skip navigation link present
- [ ] Headings hierarchy correct (H1 → H2 → H3)
- [ ] ARIA attributes used correctly
- [ ] No keyboard traps

---

## 7. CI/CD Integration

### 7.1 GitHub Actions Workflow

**Current (Next.js)**
```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run unit tests
        run: npm run test:coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json
  
  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Install Playwright
        run: npx playwright install --with-deps
      
      - name: Run E2E tests
        run: npm run test:e2e
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/
```

**Target (ASP.NET Core)**
```yaml
# .github/workflows/test.yml (modified)
jobs:
  dotnet-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'
      
      - name: Restore dependencies
        run: dotnet restore
      
      - name: Build
        run: dotnet build --no-restore
      
      - name: Run unit tests
        run: dotnet test --no-build --verbosity normal /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.cobertura.xml
```

### 7.2 Test Reports

**Coverage Badge**
```markdown
[![codecov](https://codecov.io/gh/oguzhanpisgin/diskhastanesi.com/branch/main/graph/badge.svg)](https://codecov.io/gh/oguzhanpisgin/diskhastanesi.com)
```

**Test Results Dashboard**
- Azure DevOps Test Plans
- GitHub Actions summary
- Playwright HTML report

---

## 8. Test Maintenance

### 8.1 Flaky Test Management

**Identification**
```bash
# Run tests multiple times to identify flaky tests
for i in {1..10}; do npm run test:e2e; done
```

**Mitigation Strategies**
- Use explicit waits instead of timeouts
- Avoid hard-coded delays
- Use retry mechanisms (Playwright built-in)
- Isolate tests (no shared state)
- Mock external dependencies

### 8.2 Test Refactoring

**Page Object Model**
```typescript
// pages/LeadFormPage.ts
export class LeadFormPage {
  constructor(private page: Page) {}
  
  async goto() {
    await this.page.goto('/teklif-al');
  }
  
  async fillForm(data: LeadData) {
    await this.page.getByLabel('Ad Soyad').fill(data.name);
    await this.page.getByLabel('E-posta').fill(data.email);
    await this.page.getByLabel('Telefon').fill(data.phone);
    await this.page.getByLabel('Hizmet').selectOption(data.service);
    await this.page.getByLabel('Mesaj').fill(data.message);
  }
  
  async submit() {
    await this.page.getByRole('button', { name: 'Gönder' }).click();
  }
  
  async expectSuccessMessage() {
    await expect(this.page.getByText('Talebiniz başarıyla alındı')).toBeVisible();
  }
}

// Usage in test
test('submits lead form', async ({ page }) => {
  const leadFormPage = new LeadFormPage(page);
  
  await leadFormPage.goto();
  await leadFormPage.fillForm(testLeads.valid);
  await leadFormPage.submit();
  await leadFormPage.expectSuccessMessage();
});
```

---

**Son Güncelleme:** 2025-10-04
