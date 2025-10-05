# API Referans Dokümantasyonu

**Kaynak:** diskhastanesi.com projesi - Microsoft Stack'e taşıma için hazırlanmıştır

Bu dosya, tüm API endpoint'lerini, request/response şemalarını ve kullanım örneklerini içerir.

---

## 1. Genel Bilgiler

### 1.1 Base URL

**Current (Vercel)**
```
Production: https://diskhastanesi.com/api
Staging: https://staging.diskhastanesi.com/api
Development: http://localhost:3000/api
```

**Target (Azure)**
```
Production: https://api.diskhastanesi.com
Staging: https://staging-api.diskhastanesi.com
Development: http://localhost:5000/api
```

### 1.2 Authentication

**Current**
- Public endpoints: No auth required
- Private endpoints: JWT token (planned)

**Target**
```http
Authorization: Bearer {jwt_token}
```

**Token Expiry**
- Access token: 15 minutes
- Refresh token: 7 days

### 1.3 Common Headers

**Request**
```http
Content-Type: application/json
Accept: application/json
Accept-Language: tr-TR, en-US
X-Request-ID: {uuid}
```

**Response**
```http
Content-Type: application/json
X-Response-Time: 123ms
X-Request-ID: {uuid}
```

### 1.4 Rate Limiting

**Limits**
- Global: 100 requests/minute per IP
- Lead submission: 5 requests/hour per IP
- API key: 1000 requests/minute

**Headers**
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

**Rate Limit Exceeded Response**
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "retryAfter": 60
  }
}
```

---

## 2. Endpoints

### 2.1 Lead Management

#### POST /api/leads

Yeni lead oluşturur.

**Request**
```http
POST /api/leads
Content-Type: application/json

{
  "name": "Ahmet Yılmaz",
  "email": "ahmet@example.com",
  "phone": "+905551234567",
  "company": "Example Corp",
  "service": "veri-kurtarma",
  "message": "Acil veri kurtarma ihtiyacımız var.",
  "captchaToken": "hcaptcha-token-here"
}
```

**Response (201 Created)**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Ahmet Yılmaz",
    "email": "ahmet@example.com",
    "phone": "+905551234567",
    "company": "Example Corp",
    "service": "veri-kurtarma",
    "message": "Acil veri kurtarma ihtiyacımız var.",
    "status": "new",
    "createdAt": "2025-10-04T12:00:00Z"
  }
}
```

**Error Response (400 Bad Request)**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "phone",
        "message": "Phone number must be in international format"
      }
    ]
  }
}
```

**Validation Rules**
- `name`: Required, 2-100 characters
- `email`: Required, valid email format
- `phone`: Required, international format (+905551234567)
- `company`: Optional, 2-100 characters
- `service`: Required, one of predefined services
- `message`: Required, 10-1000 characters
- `captchaToken`: Required, valid hCaptcha token

#### GET /api/leads/{id}

Lead detayını getirir (admin only).

**Request**
```http
GET /api/leads/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer {jwt_token}
```

**Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Ahmet Yılmaz",
    "email": "ahmet@example.com",
    "phone": "+905551234567",
    "company": "Example Corp",
    "service": "veri-kurtarma",
    "message": "Acil veri kurtarma ihtiyacımız var.",
    "status": "contacted",
    "assignedTo": "user-id-123",
    "createdAt": "2025-10-04T12:00:00Z",
    "updatedAt": "2025-10-04T14:30:00Z"
  }
}
```

#### GET /api/leads

Lead listesini getirir (admin only).

**Request**
```http
GET /api/leads?status=new&limit=20&offset=0&sortBy=createdAt&sortOrder=desc
Authorization: Bearer {jwt_token}
```

**Query Parameters**
- `status`: (optional) Filter by status: new, contacted, proposal_sent, won, lost
- `service`: (optional) Filter by service
- `search`: (optional) Search in name, email, company
- `limit`: (optional) Results per page (default: 20, max: 100)
- `offset`: (optional) Pagination offset (default: 0)
- `sortBy`: (optional) Sort field (createdAt, updatedAt, name)
- `sortOrder`: (optional) asc or desc (default: desc)

**Response (200 OK)**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Ahmet Yılmaz",
      "email": "ahmet@example.com",
      "company": "Example Corp",
      "service": "veri-kurtarma",
      "status": "new",
      "createdAt": "2025-10-04T12:00:00Z"
    }
  ],
  "pagination": {
    "total": 150,
    "limit": 20,
    "offset": 0,
    "hasMore": true
  }
}
```

#### PATCH /api/leads/{id}

Lead bilgilerini günceller (admin only).

**Request**
```http
PATCH /api/leads/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "status": "contacted",
  "assignedTo": "user-id-123",
  "notes": "İlk görüşme yapıldı. Teklif hazırlanacak."
}
```

**Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "contacted",
    "assignedTo": "user-id-123",
    "notes": "İlk görüşme yapıldı. Teklif hazırlanacak.",
    "updatedAt": "2025-10-04T14:30:00Z"
  }
}
```

---

### 2.2 Contact Form

#### POST /api/contact

İletişim formu gönderir.

**Request**
```http
POST /api/contact
Content-Type: application/json

{
  "name": "Mehmet Demir",
  "email": "mehmet@example.com",
  "subject": "Fiyat teklifi",
  "message": "Sunucu bakım hizmeti fiyatları hakkında bilgi almak istiyorum.",
  "captchaToken": "hcaptcha-token-here"
}
```

**Response (201 Created)**
```json
{
  "success": true,
  "message": "Mesajınız başarıyla gönderildi. En kısa sürede size dönüş yapacağız."
}
```

---

### 2.3 Consultation Request

#### POST /api/consultations

Uzman görüşme talebi oluşturur.

**Request**
```http
POST /api/consultations
Content-Type: application/json

{
  "name": "Ayşe Kaya",
  "email": "ayse@example.com",
  "phone": "+905559876543",
  "company": "Tech Solutions Ltd",
  "topic": "siber-guvenlik",
  "preferredDate": "2025-10-10",
  "preferredTime": "14:00",
  "message": "Şirketimizin güvenlik altyapısını değerlendirmek istiyoruz.",
  "captchaToken": "hcaptcha-token-here"
}
```

**Response (201 Created)**
```json
{
  "success": true,
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440000",
    "reference": "CONS-2025-001234",
    "status": "pending",
    "createdAt": "2025-10-04T12:00:00Z"
  },
  "message": "Görüşme talebiniz alındı. Referans numaranız: CONS-2025-001234"
}
```

---

### 2.4 Content API

#### GET /api/content/pages/{slug}

Sayfa içeriğini getirir.

**Request**
```http
GET /api/content/pages/veri-kurtarma?locale=tr
```

**Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "id": "page-123",
    "slug": "veri-kurtarma",
    "locale": "tr",
    "title": "Veri Kurtarma Hizmetleri",
    "description": "Profesyonel veri kurtarma hizmetleri...",
    "content": {
      "hero": {
        "title": "Veri Kurtarma Hizmetleri",
        "subtitle": "Kaybettiğiniz verileri geri kazanın",
        "image": "/images/data-recovery-hero.jpg"
      },
      "sections": [
        {
          "type": "text",
          "content": "<p>Veri kaybı...</p>"
        },
        {
          "type": "features",
          "items": [...]
        }
      ]
    },
    "seo": {
      "title": "Veri Kurtarma Hizmetleri | Disk Hastanesi",
      "description": "Profesyonel veri kurtarma...",
      "keywords": ["veri kurtarma", "disk onarım"],
      "ogImage": "/og/veri-kurtarma.jpg"
    },
    "publishedAt": "2025-09-01T10:00:00Z",
    "updatedAt": "2025-10-01T15:30:00Z"
  }
}
```

#### GET /api/content/case-studies

Vaka analizleri listesini getirir.

**Request**
```http
GET /api/content/case-studies?locale=tr&limit=10&offset=0&category=veri-kurtarma
```

**Response (200 OK)**
```json
{
  "success": true,
  "data": [
    {
      "id": "case-001",
      "slug": "kurumsal-sunucu-veri-kurtarma",
      "title": "Kurumsal Sunucu Veri Kurtarma Başarı Hikayesi",
      "excerpt": "500GB veri başarıyla kurtarıldı...",
      "category": "veri-kurtarma",
      "thumbnail": "/images/cases/case-001-thumb.jpg",
      "publishedAt": "2025-09-15T10:00:00Z"
    }
  ],
  "pagination": {
    "total": 45,
    "limit": 10,
    "offset": 0,
    "hasMore": true
  }
}
```

#### GET /api/content/case-studies/{slug}

Vaka analizi detayını getirir.

**Request**
```http
GET /api/content/case-studies/kurumsal-sunucu-veri-kurtarma?locale=tr
```

**Response (200 OK)**
```json
{
  "success": true,
  "data": {
    "id": "case-001",
    "slug": "kurumsal-sunucu-veri-kurtarma",
    "locale": "tr",
    "title": "Kurumsal Sunucu Veri Kurtarma Başarı Hikayesi",
    "excerpt": "500GB veri başarıyla kurtarıldı...",
    "category": "veri-kurtarma",
    "client": "Example Corp",
    "duration": "3 gün",
    "dataSize": "500 GB",
    "images": [
      "/images/cases/case-001-1.jpg",
      "/images/cases/case-001-2.jpg"
    ],
    "problem": "<p>Sunucu arızası...</p>",
    "solution": "<p>Özel ekipmanlarla...</p>",
    "result": "<p>Tüm veriler kurtarıldı...</p>",
    "relatedServices": ["veri-kurtarma", "sunucu-bakim"],
    "publishedAt": "2025-09-15T10:00:00Z",
    "updatedAt": "2025-09-20T14:00:00Z"
  }
}
```

---

### 2.5 Edge Functions

#### POST /api/edge/notify-lead

Lead bildirimi gönderir (internal use).

**Request**
```http
POST /api/edge/notify-lead
Content-Type: application/json
X-API-Key: {service_key}

{
  "leadId": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Ahmet Yılmaz",
  "email": "ahmet@example.com",
  "service": "veri-kurtarma"
}
```

**Response (200 OK)**
```json
{
  "success": true,
  "notifications": {
    "email": "sent",
    "slack": "sent"
  }
}
```

---

### 2.6 Health Check

#### GET /api/health

Servis sağlık kontrolü.

**Request**
```http
GET /api/health
```

**Response (200 OK)**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-04T12:00:00Z",
  "version": "1.0.0",
  "services": {
    "database": "healthy",
    "cache": "healthy",
    "storage": "healthy"
  },
  "uptime": 86400
}
```

**Unhealthy Response (503 Service Unavailable)**
```json
{
  "status": "unhealthy",
  "timestamp": "2025-10-04T12:00:00Z",
  "services": {
    "database": "unhealthy",
    "cache": "healthy",
    "storage": "healthy"
  },
  "errors": [
    "Database connection timeout"
  ]
}
```

---

## 3. Error Codes

### 3.1 HTTP Status Codes

- `200 OK`: Başarılı istek
- `201 Created`: Kaynak oluşturuldu
- `400 Bad Request`: Geçersiz istek
- `401 Unauthorized`: Kimlik doğrulama gerekli
- `403 Forbidden`: Yetki yok
- `404 Not Found`: Kaynak bulunamadı
- `409 Conflict`: Kaynak çakışması
- `422 Unprocessable Entity`: Validasyon hatası
- `429 Too Many Requests`: Rate limit aşıldı
- `500 Internal Server Error`: Sunucu hatası
- `503 Service Unavailable`: Servis kullanılamaz

### 3.2 Custom Error Codes

**Validation Errors**
- `VALIDATION_ERROR`: Genel validasyon hatası
- `INVALID_EMAIL`: Geçersiz email formatı
- `INVALID_PHONE`: Geçersiz telefon formatı
- `REQUIRED_FIELD`: Zorunlu alan eksik

**Authentication Errors**
- `AUTH_REQUIRED`: Kimlik doğrulama gerekli
- `INVALID_TOKEN`: Geçersiz token
- `TOKEN_EXPIRED`: Token süresi dolmuş
- `INVALID_CREDENTIALS`: Geçersiz kimlik bilgileri

**Authorization Errors**
- `INSUFFICIENT_PERMISSIONS`: Yetersiz yetki
- `FORBIDDEN`: Erişim yasak

**Rate Limiting**
- `RATE_LIMIT_EXCEEDED`: Rate limit aşıldı

**Resource Errors**
- `NOT_FOUND`: Kaynak bulunamadı
- `ALREADY_EXISTS`: Kaynak zaten mevcut
- `CONFLICT`: Çakışma

**Server Errors**
- `INTERNAL_ERROR`: Sunucu hatası
- `SERVICE_UNAVAILABLE`: Servis kullanılamaz
- `DATABASE_ERROR`: Veritabanı hatası

---

## 4. Webhooks

### 4.1 Lead Created

Lead oluşturulduğunda tetiklenir.

**Endpoint**: `{your_webhook_url}`

**Payload**
```json
{
  "event": "lead.created",
  "timestamp": "2025-10-04T12:00:00Z",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Ahmet Yılmaz",
    "email": "ahmet@example.com",
    "service": "veri-kurtarma",
    "status": "new"
  }
}
```

**Signature**
```http
X-Webhook-Signature: sha256=abc123...
```

### 4.2 Lead Status Changed

Lead durumu değiştiğinde tetiklenir.

**Payload**
```json
{
  "event": "lead.status_changed",
  "timestamp": "2025-10-04T14:30:00Z",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "oldStatus": "new",
    "newStatus": "contacted"
  }
}
```

---

## 5. SDKs & Examples

### 5.1 JavaScript/TypeScript

```typescript
// Lead submission
const createLead = async (data: LeadRequest) => {
  const response = await fetch('/api/leads', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }

  return response.json();
};

// Usage
try {
  const result = await createLead({
    name: 'Ahmet Yılmaz',
    email: 'ahmet@example.com',
    phone: '+905551234567',
    company: 'Example Corp',
    service: 'veri-kurtarma',
    message: 'Acil veri kurtarma ihtiyacımız var.',
    captchaToken: token,
  });
  
  console.log('Lead created:', result.data.id);
} catch (error) {
  console.error('Error:', error.message);
}
```

### 5.2 C# (.NET)

```csharp
// Lead submission
public class LeadService
{
    private readonly HttpClient _httpClient;
    
    public LeadService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }
    
    public async Task<LeadResponse> CreateLeadAsync(LeadRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/leads", request);
        response.EnsureSuccessStatusCode();
        
        return await response.Content.ReadFromJsonAsync<LeadResponse>();
    }
}

// Usage
var leadService = new LeadService(httpClient);

try
{
    var result = await leadService.CreateLeadAsync(new LeadRequest
    {
        Name = "Ahmet Yılmaz",
        Email = "ahmet@example.com",
        Phone = "+905551234567",
        Company = "Example Corp",
        Service = "veri-kurtarma",
        Message = "Acil veri kurtarma ihtiyacımız var.",
        CaptchaToken = token
    });
    
    Console.WriteLine($"Lead created: {result.Data.Id}");
}
catch (HttpRequestException ex)
{
    Console.WriteLine($"Error: {ex.Message}");
}
```

### 5.3 cURL

```bash
# Create lead
curl -X POST https://diskhastanesi.com/api/leads \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ahmet Yılmaz",
    "email": "ahmet@example.com",
    "phone": "+905551234567",
    "company": "Example Corp",
    "service": "veri-kurtarma",
    "message": "Acil veri kurtarma ihtiyacımız var.",
    "captchaToken": "hcaptcha-token-here"
  }'

# Get lead (with auth)
curl -X GET https://diskhastanesi.com/api/leads/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer {jwt_token}"

# List leads with filters
curl -X GET "https://diskhastanesi.com/api/leads?status=new&limit=20" \
  -H "Authorization: Bearer {jwt_token}"
```

---

## 6. Versioning

### 6.1 Current Version

API Version: `v1`

### 6.2 Future Versions

Yeni versiyonlar URL'de belirtilecek:
```
/api/v2/leads
```

### 6.3 Deprecation Policy

- Major version: 12 ay destek
- Deprecation notice: 6 ay önce
- Sunset date: Response header'da belirtilir

```http
Sunset: Sat, 01 Jan 2026 00:00:00 GMT
Link: <https://diskhastanesi.com/api/v2/leads>; rel="successor-version"
```

---

## 7. Testing

### 7.1 Test Endpoints

**Staging**
```
https://staging.diskhastanesi.com/api
```

### 7.2 Test Data

**Test Email**
```
test+success@diskhastanesi.com  (success)
test+fail@diskhastanesi.com     (fail)
```

**Test Phone**
```
+905550000001  (success)
+905550000002  (fail)
```

**Test Captcha**
```
# Development mode: any token accepted
captchaToken: "dev-mode-token"
```

### 7.3 Postman Collection

Postman collection indirme linki:
```
https://diskhastanesi.com/api/postman-collection.json
```

---

## 8. Support

### 8.1 Documentation

- API Docs: https://docs.diskhastanesi.com/api
- Changelog: https://docs.diskhastanesi.com/api/changelog

### 8.2 Contact

- Email: api-support@diskhastanesi.com
- Slack: #api-support

### 8.3 Status Page

API durumu: https://status.diskhastanesi.com

---

**Son Güncelleme:** 2025-10-04
