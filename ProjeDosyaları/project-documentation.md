# Proje Dokümantasyonu

**Kaynak:** diskhastanesi.com projesi - Microsoft Stack'e taşıma için hazırlanmıştır

Bu dosya, projenin iş gereksinimleri, sayfa yapısı, CMS/CRM/AI sistemleri ve kullanıcı deneyimi detaylarını içerir.

---

## 1. Proje Genel Bakış

### 1.1 Proje Amacı ve Vizyonu
- Kurumsal veri kurtarma ve IT altyapı hizmetleri sunumu
- Güvenilir, profesyonel ve kullanıcı odaklı dijital vitrin
- Lead üretme ve müşteri kazanımı
- Bilgilendirici içerik ve vaka analizi paylaşımı

### 1.2 Hedef Kitle
- Kurumsal müşteriler (KOBİ ve büyük işletmeler)
- IT sorumluları ve karar vericiler
- Acil veri kurtarma ihtiyacı olan firmalar
- Siber güvenlik ve altyapı danışmanlığı arayanlar

### 1.3 Ana Özellikler
- Çok dilli destek (TR/EN)
- Dinamik içerik yönetimi (CMS)
- Lead toplama formları
- AI destekli müşteri hizmetleri
- Vaka analizi arşivi
- Responsive ve erişilebilir tasarım

### 1.4 İş Modeli
- B2B hizmet satışı
- Teklif talepleri üzerinden lead dönüşümü
- Uzman danışmanlık hizmetleri
- Acil müdahale hizmetleri

---

## 2. Web Sitesi Yapısı

### 2.1 Sayfa Hiyerarşisi ve Slug Yapısı

**Türkçe Sayfalar (`/tr/`)**
- `/tr/` - Ana sayfa
- `/tr/hakkimizda` - Kurumsal bilgi
- `/tr/iletisim` - İletişim formu ve bilgiler
- `/tr/veri-kurtarma` - Veri kurtarma hizmetleri
- `/tr/siber-guvenlik` - Siber güvenlik hizmetleri
- `/tr/vaka-analizleri` - Vaka listesi
- `/tr/vaka-analizleri/[slug]` - Tekil vaka detayı
- `/tr/teklif-al` - Teklif formu
- `/tr/uzmanlarimizla-gorusun` - Uzman görüşme formu

**İngilizce Sayfalar (`/en/`)**
- Türkçe sayfaların İngilizce karşılıkları
- URL yapısı aynı mantıkla kurgulanmış

### 2.2 Navigasyon Mimarisi
- Header: Logo, ana menü, dil seçici
- Ana menü: Hizmetler, Hakkımızda, Vaka Analizleri, İletişim
- Footer: Hızlı linkler, sosyal medya, iletişim bilgileri, yasal linkler
- Breadcrumb: Sayfa hiyerarşisi göstergesi

### 2.3 Çok Dilli Yapı
- Next.js `[locale]` dynamic routing
- `next-intl` paketi ile lokalizasyon
- Namespaced message dosyaları (`@/messages/tr/`, `@/messages/en/`)
- Otomatik dil yönlendirmesi
- SEO için `hreflang` tagları

### 2.4 URL Routing Kuralları
- Clean URL'ler (`.html` uzantısı yok)
- Slug'lar küçük harf, tire ile ayrılmış
- Locale prefix zorunlu (`/tr/`, `/en/`)
- Trailing slash yok

### 2.5 SEO ve Meta Tag Stratejisi
- Unique title ve description her sayfa için
- Open Graph tags (Facebook, LinkedIn)
- Twitter Card tags
- Structured data (Schema.org)
- Canonical URL'ler
- XML sitemap
- robots.txt

---

## 3. Sayfa Detayları

### 3.1 Ana Sayfa (`/`)
- Hero section: Başlık, alt başlık, CTA butonları
- Hizmet kartları: Veri kurtarma, siber güvenlik, IT altyapı
- Sosyal kanıt: Müşteri logoları, istatistikler
- Vaka örnekleri: Son 3 vaka analizi
- İletişim CTA: Teklif al veya görüşün

### 3.2 Hizmet Sayfaları
- `/veri-kurtarma`, `/siber-guvenlik`, vb.
- Hizmet açıklaması
- Alt hizmetler listesi
- Süreç adımları
- SSS (Frequently Asked Questions)
- İlgili vakalar
- CTA: Teklif al

### 3.3 Kurumsal Sayfalar
- **Hakkımızda**: Şirket hikayesi, değerler, ekip
- **İletişim**: İletişim formu, adres, telefon, e-posta, harita

### 3.4 Vaka Analizleri
- **Liste sayfası** (`/vaka-analizleri`): Grid layout, filtreleme, arama
- **Detay sayfası** (`/vaka-analizleri/[slug]`):
  - Başlık, özet, görseller
  - Sorun, çözüm, sonuç bölümleri
  - İlgili hizmetler
  - Benzer vakalar

### 3.5 Lead Formları
- **Teklif Al** (`/teklif-al`):
  - Kişi bilgileri (ad, email, telefon, firma)
  - Hizmet seçimi
  - Mesaj alanı
  - KVKK onayı
  - hCaptcha doğrulama
  
- **Uzmanlarımızla Görüşün** (`/uzmanlarimizla-gorusun`):
  - Randevu tercihi
  - Konu seçimi
  - İletişim bilgileri
  - Mesaj

### 3.6 Error ve Fallback Sayfaları
- `not-found.tsx`: 404 sayfası
- `global-error.tsx`: Uygulama düzeyinde hata
- Kullanıcı dostu mesajlar ve yönlendirme linkleri

---

## 4. CMS (İçerik Yönetim Sistemi)

### 4.1 CMS Platformu
- **Mevcut**: Sanity CMS planlanmış
- **Microsoft Stack**: Azure Contentful / Headless CMS / SharePoint

### 4.2 İçerik Modelleri ve Şemalar
- **Sayfa**: Başlık, slug, içerik blokları, SEO meta
- **Vaka Analizi**: Başlık, slug, özet, görseller, sorun, çözüm, sonuç, ilgili hizmetler
- **Hizmet**: Başlık, slug, açıklama, alt hizmetler, SSS
- **Blog/Makale**: Başlık, yazar, tarih, içerik, kategoriler, etiketler

### 4.3 Editör Rolleri ve Yetkileri
- **Admin**: Tüm içerik ve ayarlara erişim
- **Editor**: İçerik oluşturma, düzenleme, taslak kaydetme
- **Reviewer**: İçerik onaylama yetkisi
- **Viewer**: Sadece okuma

### 4.4 İçerik Onay Akışı
1. Editor taslak oluşturur
2. Review durumuna alır
3. Reviewer onaylar/reddeder
4. Onaylanan içerik yayına alınır
5. Versiyon kontrolü

### 4.5 Lokalizasyon Yönetimi
- Her içerik çoklu dil versiyonu
- Translation workflow
- Çeviri durumu takibi
- Dil bazlı yayın tarihi

### 4.6 AI Destekli İçerik Önerileri
- SEO başlık/description önerisi
- Benzer içerik önerisi
- Etiket önerisi
- Ton ve stil kontrolü
- Readability skoru

### 4.7 Taslak Kaydetme Sistemi
- Otomatik kaydetme (her 30 saniye)
- Manuel kaydetme
- Versiyon geçmişi
- Geri alma (undo/redo)

### 4.8 Medya Yönetimi
- Görsel yükleme ve optimize etme
- CDN entegrasyonu
- Alt text ve metadata
- Klasör organizasyonu
- Arama ve filtreleme

---

## 5. CRM (Müşteri İlişkileri Yönetimi)

### 5.1 Lead Toplama Mekanizması
- Form submission → Supabase/Azure SQL tablosuna yazma
- Otomatik notification (Slack, email)
- Lead ID ve timestamp

### 5.2 Lead Pipeline Aşamaları
1. **Yeni**: Form gönderimi
2. **Değerlendiriliyor**: İlk inceleme
3. **İletişimde**: Müşteri ile görüşme
4. **Teklif Hazırlandı**: Fiyat teklifi gönderildi
5. **Kazanıldı**: Müşteri oldu
6. **Kaybedildi**: Dönüşüm olmadı

### 5.3 Form Validasyonları
- Email format kontrolü
- Telefon format kontrolü (libphonenumber-js)
- Zorunlu alan kontrolü
- Spam/bot koruması (hCaptcha)
- Rate limiting

### 5.4 Supabase/Azure SQL Entegrasyonu
- Lead tablosu: id, name, email, phone, company, service, message, status, created_at
- Form submission log tablosu
- Notification queue tablosu

### 5.5 Notification Sistemi
- **Slack**: Yeni lead bildirimi
- **Email**: Otoresponder (müşteriye), bildirim (ekibe)
- **SMS/WhatsApp**: Kritik leadler için (opsiyonel)

### 5.6 Lead Puanlama ve Segmentasyon
- Firma büyüklüğü skoru
- Hizmet türü skoru
- Aciliyet skoru
- Coğrafi konum
- Segment: Kurumsal, KOBİ, Bireysel

### 5.7 Takip ve Raporlama
- Lead sayısı (günlük, haftalık, aylık)
- Dönüşüm oranları
- Kaynak analizi (organik, reklam, referral)
- Response time ortalama
- Pipeline dashboard

---

## 6. AI Müşteri Hizmetleri

### 6.1 Chatbot Senaryoları
- Karşılama mesajı
- Hizmet tanıtımı
- Fiyat bilgisi talepleri
- Randevu oluşturma
- Sık sorulan sorular (SSS)

### 6.2 FAQ Otomasyonu
- Veri kurtarma süreleri
- Fiyatlandırma bilgisi
- Çalışma saatleri
- Hizmet kapsamı
- Ödeme koşulları

### 6.3 Form Yönlendirme
- İhtiyaç analizi soruları
- Doğru form önerisi
- Alan doldurma yardımı
- Hata mesajları açıklama

### 6.4 Durum Takibi
- Lead durumu sorgulama
- Teklif durumu
- Hizmet ilerleme raporu

### 6.5 Dil Desteği
- Türkçe ve İngilizce
- Otomatik dil tespiti
- Cevap kalitesi kontrolü

### 6.6 Fallback Süreçleri
- Anlaşılamayan sorular için cevap şablonu
- İnsan ajana yönlendirme butonu
- Callback talep formu

### 6.7 İnsan Ajan Eskalasyonu
- Karmaşık teknik sorular
- Şikayet ve memnuniyetsizlik
- Özel fiyat talepleri
- Çalışma saatleri dışı acil durumlar

### 6.8 Veri Kaynakları ve Training
- İç dokümantasyon (SSS, hizmet detayları)
- Vaka analizleri
- Geçmiş chat logları
- Müşteri geri bildirimleri

---

## 7. Kullanıcı Akışları (User Flows)

### 7.1 Ana Sayfa → Hizmet Keşfi
1. Kullanıcı ana sayfaya gelir
2. Hizmet kartlarını inceler
3. İlgili hizmete tıklar
4. Hizmet detay sayfasını okur
5. "Teklif Al" butonuna tıklar

### 7.2 Teklif Al Formu Akışı
1. Form sayfası açılır
2. Kullanıcı bilgilerini doldurur
3. hCaptcha doğrulaması
4. Form gönderilir
5. Başarı mesajı gösterilir
6. Otoresponder email gönderilir

### 7.3 Uzmanlarımızla Görüşün Akışı
1. Form sayfası açılır
2. Randevu tercihi seçilir
3. İletişim bilgileri girilir
4. Form gönderilir
5. Notification tetiklenir
6. Geri dönüş bekleme sayfası

### 7.4 Vaka Analizi Okuma
1. Vaka listesi sayfası
2. Kategoriye göre filtreleme
3. Vaka seçimi
4. Detay sayfası okuma
5. İlgili hizmet keşfi
6. CTA: Teklif al

### 7.5 İletişim Formu
1. İletişim sayfası açılır
2. Form doldurulur
3. Gönderilir
4. Başarı mesajı
5. Email bildirimi

### 7.6 Çok Dilli Gezinme
1. Dil seçici tıklanır
2. Locale değişir
3. Sayfa aynı slug'da yeniden yüklenir
4. İçerik seçili dilde gösterilir

---

## 8. Component Kütüphanesi

### 8.1 Header/Footer
- Responsive header (mobile menü)
- Logo ve branding
- Ana navigasyon
- Dil değiştirici
- Footer link grupları
- Sosyal medya ikonları

### 8.2 Navigation Menü
- Desktop: Horizontal menü
- Mobile: Hamburger menü
- Active state gösterimi
- Dropdown submenu (hizmetler)

### 8.3 Form Componentleri
- TextInput
- TextArea
- Select/Dropdown
- Checkbox
- RadioButton
- PhoneInput (ülke kodu ile)
- EmailInput (validasyon)
- SubmitButton (loading state)
- ErrorMessage
- SuccessMessage

### 8.4 Card/Grid Sistemleri
- ServiceCard
- CaseStudyCard
- BlogCard
- Grid layout (responsive)

### 8.5 Modal/Dialog
- Form modal
- Confirmation dialog
- Alert dialog
- Image lightbox

### 8.6 Button Varyantları
- Primary
- Secondary
- Outline
- Ghost
- Loading state
- Disabled state

### 8.7 Loading States
- Skeleton loader
- Spinner
- Progress bar
- Page loader

### 8.8 Error Boundaries
- Component-level error boundary
- Page-level error boundary
- Fallback UI

---

## 9. API ve Entegrasyonlar

### 9.1 Lead Submission API
- Endpoint: `/api/edge/notify-lead`
- Method: POST
- Body: Lead form data
- Response: Success/Error

### 9.2 Email Notification Service
- Supabase Edge Function
- SMTP entegrasyonu (SendGrid, AWS SES)
- Template engine
- Retry mekanizması

### 9.3 SMS/WhatsApp Entegrasyonu
- Twilio / Vonage API
- Acil lead bildirimi
- OTP doğrulama (opsiyonel)

### 9.4 Analytics Tracking
- Google Analytics 4
- Custom event tracking
- Conversion tracking
- User behavior analysis

### 9.5 Sentry Error Tracking
- Otomatik error capture
- Performance monitoring
- User session replay
- Alert kuralları

### 9.6 Third-party Servisler
- hCaptcha (bot koruması)
- CDN (Cloudflare, Azure CDN)
- Email provider
- SMS provider

---

## 10. Veritabanı Şeması

### 10.1 Lead Tablosu
```sql
id: UUID
name: TEXT
email: TEXT
phone: TEXT
company: TEXT
service: TEXT
message: TEXT
status: ENUM (new, contacted, proposal_sent, won, lost)
created_at: TIMESTAMP
updated_at: TIMESTAMP
```

### 10.2 Form Submission Tablosu
```sql
id: UUID
form_type: TEXT (teklif_al, uzmanlarimizla_gorusun, iletisim)
data: JSONB
ip_address: TEXT
user_agent: TEXT
created_at: TIMESTAMP
```

### 10.3 Content Tables (CMS)
- Pages
- CaseStudies
- Services
- BlogPosts
- Media

### 10.4 User/Session Tablosu
```sql
id: UUID
email: TEXT
role: ENUM (admin, editor, reviewer, viewer)
last_login: TIMESTAMP
created_at: TIMESTAMP
```

### 10.5 Log Tablosu
```sql
id: UUID
level: ENUM (info, warning, error)
message: TEXT
context: JSONB
created_at: TIMESTAMP
```

### 10.6 Migration Stratejisi
- EF Core migrations (Azure SQL)
- Supabase migrations (SQL files)
- Seed data
- Rollback planı

---

## 11. Güvenlik ve Gizlilik

### 11.1 Form CSRF Koruması
- CSRF token generation
- Token validation
- Session-based protection

### 11.2 Rate Limiting
- IP bazlı rate limiting
- Form submission throttling
- API endpoint koruması

### 11.3 Input Sanitization
- XSS koruması
- SQL injection önleme
- HTML encoding
- URL validation

### 11.4 KVKK/GDPR Uyumluluğu
- Açık rıza metni
- Veri işleme aydınlatma metni
- Veri silme talebi prosedürü
- Cookie consent banner

### 11.5 Veri Saklama Politikaları
- Lead verisi: 2 yıl
- Log verisi: 6 ay
- Oturum verisi: 30 gün
- Otomatik silme job'ları

### 11.6 Cookie Consent
- Essential cookies
- Analytics cookies
- Marketing cookies
- Kullanıcı tercihi kaydı

### 11.7 Veri Maskeleme
- Log'larda sensitive data maskeleme
- Email/telefon kısmi gösterim
- PII koruması

---

## 12. Performans ve Optimizasyon

### 12.1 Core Web Vitals Hedefleri
- LCP (Largest Contentful Paint): < 2.5s
- FID (First Input Delay): < 100ms
- CLS (Cumulative Layout Shift): < 0.1
- TTFB (Time to First Byte): < 600ms

### 12.2 Image Optimization
- Next.js Image component
- WebP format
- Lazy loading
- Responsive images
- CDN delivery

### 12.3 Code Splitting
- Route-based splitting
- Component lazy loading
- Dynamic imports
- Vendor bundle optimization

### 12.4 Caching Stratejisi
- Browser cache headers
- CDN cache
- API response cache
- Static page cache (ISR)

### 12.5 CDN Kullanımı
- Static asset delivery
- Edge caching
- Geo-distribution
- Automatic failover

### 12.6 Lazy Loading
- Images below fold
- Components on scroll
- Third-party scripts
- Heavy libraries

---

## 13. Erişilebilirlik (Accessibility)

### 13.1 WCAG 2.1 AA Uyumluluğu
- Perceivable
- Operable
- Understandable
- Robust

### 13.2 Keyboard Navigation
- Tab order mantıklı
- Skip to content link
- Focus visible
- Keyboard shortcuts

### 13.3 Screen Reader Desteği
- Semantic HTML
- ARIA labels
- Alt text tüm görsellerde
- Heading hierarchy

### 13.4 Color Contrast
- Minimum 4.5:1 (normal text)
- Minimum 3:1 (large text)
- Renk körü dostu palet

### 13.5 Focus Management
- Visible focus indicator
- Modal focus trap
- Skip navigation
- Focus restoration

### 13.6 ARIA Attributes
- aria-label
- aria-labelledby
- aria-describedby
- aria-live regions

---

## 14. Brand ve Tasarım

### 14.1 Logo ve Renk Paleti
- Primary color: [Hex kod]
- Secondary color: [Hex kod]
- Accent colors
- Neutral colors
- Error/Success/Warning colors

### 14.2 Tipografi
- Heading font: [Font ailesi]
- Body font: [Font ailesi]
- Font sizes: 12px-64px scale
- Line heights
- Font weights

### 14.3 Spacing/Grid Sistem
- 8px base unit
- 12-column grid
- Container max-width
- Gutters ve margins

### 14.4 Responsive Breakpoints
- Mobile: 0-767px
- Tablet: 768-1023px
- Desktop: 1024-1439px
- Large desktop: 1440px+

### 14.5 Dark/Light Mode
- Renk değişkenleri
- Auto-detect sistem tercihi
- Manuel toggle
- LocalStorage kayıt

### 14.6 Icon Set
- Icon library (Heroicons, Lucide)
- Tutarlı boyutlar
- Semantik kullanım
- Accessibility labels

---

## Microsoft Stack'e Taşıma Notları

### Değiştirilecek Teknolojiler
- **Frontend**: Next.js → ASP.NET Core Razor Pages / Blazor
- **CMS**: Sanity → Azure Contentful / SharePoint
- **Database**: Supabase → Azure SQL / Cosmos DB
- **Auth**: Supabase Auth → Azure AD B2C / Entra ID
- **Storage**: Supabase Storage → Azure Blob Storage
- **Functions**: Supabase Edge Functions → Azure Functions
- **Hosting**: Vercel → Azure App Service / Static Web Apps
- **CDN**: Vercel Edge Network → Azure Front Door / CDN
- **Monitoring**: Sentry → Application Insights
- **Analytics**: Custom → Azure Monitor

### Korunacak Prensipler
- Sayfa yapısı ve URL routing
- Form validasyonları
- Güvenlik kuralları
- Erişilebilirlik standartları
- Brand ve tasarım sistemi
- İş kuralları ve workflow'lar
