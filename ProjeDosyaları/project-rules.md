# Proje Kuralları (PROJECT_RULES.md)

**Kaynak:** `PROJECT_RULES.md` v2.4 (2025-10-01)

Bu dosya, diskhastanesi.com projesinin tüm geliştirme, test, deployment ve governance kurallarını içerir.

---

## 📌 Ana Direktif

**Kalite hızdan önce gelir.** Teslimat; test, okunabilirlik, sürdürülebilirlik veya güvenlik pahasına hızlandırılmaz.

---

## 1. Temel Prensipler

### 1.1 Modülerlik ve Atomik Görevler

- **Atomik Görev**: Tek iş amacı; bağımsız merge edilebilir; diff ≤ 400 satır; kendi testleri dahil.
- **Kalite Bariyeri**: Linter temiz, formatter uygulanmış, testler yeşil, coverage ≥ %85.

### 1.2 5 Şapka Analizi Modeli

Kritik kararlar için tüm perspektifler değerlendirilir:

- **Mimar**: Genel yapıya ve gelecek bakıma etkisi
- **Geliştirici**: Teknik temizlik ve verimlilik
- **Güvenlik**: Potansiyel riskler ve zafiyetler
- **Performans**: Sayfa hızı ve çalışma performansı
- **UX**: Kullanıcı deneyimi ve basitlik

### 1.3 Cerrahi Hata Ayıklama

1. Reproduce → Root Cause → Minimal Fix → Test → Doğrulama
2. Rastgele denemeler yasak
3. Teknik borç işaretleme: `TECHDEBT:` + issue referansı

---

## 2. Branch ve PR Süreci

### 2.1 Branch Formatı

- `feature/*`, `fix/*`, `refactor/*`, `chore/*`, `hotfix/*`
- `main` korumalı (doğrudan push yasak)

### 2.2 PR Gereklilikleri

- Conventional Commit başlık
- Özet + Risk + Test Kapsamı (+ 5 Şapka özeti gerekiyorsa)
- CI PASS
- En az 1 onay (kritik modül 2)
- Squash merge tercih edilir

### 2.3 Commit Formatı (Conventional Commits)

`feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, `chore:`, `security:`

---

## 3. Test Standartları

- Yeni fonksiyon: 1 mutlu yol + 1 edge case
- Hata düzeltme: Önce failing test ekle
- Coverage eşiği: Global ≥ %85 (çekirdek modüller ≥ %90)

---

## 4. Güvenlik

- Otomatik dependency scanning (Dependabot)
- Gizli bilgiler env var olarak (`.env.example` şablon)
- Üretim kodunda `console.log` yasak
- SQL injection, XSS, CSRF temel korumaları

---

## 5. Ortam Yapılandırması

### 5.1 Local Development

- **Database**: Local Supabase CLI (`supabase start`)
- **Web**: Next.js dev server (`npm run dev`)
- **Port**: Frontend <http://localhost:3000>, Supabase <http://localhost:54321>
- **Env**: `.env.local` dosyası

### 5.2 Production

- **Hosting**: Vercel
- **Database**: Supabase Cloud
- **Env**: Vercel dashboard

---

## 6. Hata Takip ve Observability

### 6.1 Development Phase

- ESLint + Prettier (real-time)
- Pre-commit Hooks (Husky + lint-staged)
- TypeScript Strict Mode

### 6.2 Production Phase

- **Sentry Integration**: Error tracking, performance monitoring
- **AI Error Resolution Workflow**: Sentry Alert → Analysis → Fix → Deploy
- **Monitoring Metrics**: Core Web Vitals, API response times, error rates

---

## 7. Performans

- p95 endpoint latency < 500ms (≥ 800ms aksiyon tetikler)
- N+1 sorgu kontrolü
- Büyük veri: stream/chunk işleme

---

## 8. Dokümantasyon

- Public module: Amaç + Girdi/Çıktı + Örnek
- Mimari karar: `docs/adr/NN-title.md`
- README güncel tutulur
- Divio modeline göre `docs/index.md` hub'ı
- Şablon kullanımı: `docs/templates/`

---

## 9. CI/CD Pipeline

### 9.1 Pipeline Sırası

Install → Lint → Test → Coverage Gate → Security Scan → Build/Package

### 9.2 Pre-commit

Format + Lint (bloklayıcı)

---

## 10. Refactoring Politikası

- \> 400 satır değişiklik: Ayrı issue + plan
- Mikro refactor: Aynı PR içinde kabul

---

## 11. MCP (Model Context Protocol) Kuralları

### 11.1 Bilgi Güncelliği Protokolü

1. Tarih senkronizasyonu doğrulanır
2. `lastSyncedAt` kontrolü (24 saat eşiği)
3. Güvenilir kaynaklardan güncelleme
4. `docs/updates/mcp-sync-log.md` kaydı
5. Güncelleme tamamlanmadan görev başlamaz

### 11.2 Heartbeat Otomasyon

- `/.mcp/heartbeat.json` gerekli
- Anahtarlar: `lastSyncedAt`, `dataSources`, `contentHash`
- CI pipeline doğrulaması (`npm run mcp:preflight`)
- Başarısız: `docs/runbooks/mcp-heartbeat-recovery.md`

### 11.3 AI Karar Arşivleme

- Tüm AI destekli üretim düzeltmeleri arşivlenir
- Konum: `docs/operations/ai-decisions/YYYY-MM-DD--<slug>.md`
- Bölümler: Görev, Kaynaklar, AI Çıktısı, İnsan Doğrulama, Sonuç
- Haftalık gözden geçirme

### 11.4 Güvenilir Kaynak Whitelist

- Liste: `docs/updates/trusted-sources.md`
- Yeni kaynak: Güvenlik + Mimari onayı
- Çeyreklik gözden geçirme

### 11.5 Rollback Planı

- Her MCP tabanlı prod düzeltme için plan zorunlu
- Şablon: `docs/runbooks/mcp-rollback.md`
- Test ortamında dry-run
- Plan olmadan deploy yasak

### 11.6 Drift Alarm Sistemi

- Haftalık cron (`.github/workflows/mcp-drift-check.yml`)
- %2 fark veya kritik dosya değişikliği → alarm
- Drift kapanmadan MCP verisi prod'da kullanılamaz

### 11.7 VS Code MCP Konfigürasyonu

- VS Code 1.104+
- `AGENTS.md` otomatik dahil
- `.vscode/settings.json` gerekli ayarlar:
  - `"chat.mcp.discovery.enabled": true`
  - `"chat.mcp.access": "all"`
- MCP client config: `.mcp/settings.json`

### 11.8 AI + MCP İşbirliği Zorunluluğu

1. Görev öncesi `repo-docs-mcp-server` erişimi aktif
2. İlk bağlam MCP üzerinden toplanır
3. MCP erişimi olmayan ajan göreve başlayamaz
4. MCP yetersiz/erişilemez → `docs/runbooks/mcp-heartbeat-recovery.md`
5. Kritik otomasyonlar arşivlenir (§11.3)
6. Uyumsuzluk → PR bloklanır

---

## 12. Kullanıcıya Açıklama Dili

- Açıklamalar ve yönergeler: **Türkçe**
- Teknik terimler, kod, komutlar: **İngilizce**
- AI/Agent yanıtları: Türkçe (kod blokları İngilizce)

---

## 13. Versiyonlama

- **SemVer**: MAJOR.MINOR.PATCH
- **Changelog**: Keep a Changelog formatı (`CHANGELOG.md`)
- Her PR ilgili bölümü günceller

---

## 14. Manifesto Güncelleme

Öneri → Issue → İnceleme → Onay → Versiyon artışı

- **patch**: Netleştirme
- **minor**: Yeni kural
- **major**: Davranışsal kırılım

---

## 15. Gelecek Genişletme Alanları (Backlog)

- Observability genişletmesi (`docs/architecture/observability-expansion.md`)
- Detaylı test planı (`docs/qa/test-plan.md`)
- Edge function deploy pipeline (`docs/delivery/edge-function-deploy-pipeline.md`)
- CRM yol haritası (`docs/architecture/crm-roadmap.md`)
- i18n stratejisi
- Erişilebilirlik checklist (`docs/qa/accessibility-checklist.md`)
- Kaos/dayanıklılık testleri (`docs/qa/chaos-resilience-test-plan.md`)
- Taslak kaydetme & dosya yükleme (`docs/architecture/draft-upload-strategy.md`)

---

## 16. Microsoft'a Taşıma Notları

### 16.1 Framework Değişiklikleri

- Next.js → ASP.NET Core / Blazor
- Supabase → Azure SQL / Cosmos DB
- Vercel → Azure App Service / Static Web Apps
- Sentry → Application Insights

### 16.2 DevOps Değişiklikleri

- GitHub Actions → Azure DevOps Pipelines
- npm scripts → dotnet CLI / MSBuild
- Husky hooks → Azure DevOps policy checks
- Pre-commit → Azure DevOps build validation

### 16.3 Güvenlik Değişiklikleri

- `.env` → Azure Key Vault
- Supabase Auth → Azure AD B2C / Entra ID
- Environment variables → App Configuration

### 16.4 Test Değişiklikleri

- Vitest → xUnit / MSTest
- Playwright → Playwright .NET
- Jest → .NET test frameworks

### 16.5 Dokümantasyon

- Tüm path referansları güncellenmeli
- Azure service endpoint'leri eklenmeli
- .NET dependency management dokümante edilmeli

---

## 17. Sorumluluk

Bu dokümana uyumsuzluk tespitinde PR bloklanır. Teknik borç erteleme gerekçesi PR'da belgelenmelidir.

---

## Değişiklik Geçmişi

### v2.4 (2025-10-01)

- Konsolidasyon güncellemesi
- §1.27 "Kullanıcıya Açıklama Dili Kuralı" eklendi
- Master dosya uyarısı eklendi
- `GLOBAL_AGENT_RULES.md` ve `PROJECT_CONSOLIDATED_RULES.md` birleştirildi

### v2.3 (2025-09-29)

- MCP protokolleri ve governance kuralları eklendi
- Observability ve Sentry entegrasyonu detaylandırıldı

---

**Son Güncelleme:** 2025-10-01
