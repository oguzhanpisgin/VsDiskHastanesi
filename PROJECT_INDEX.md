# 🚑 DiskHastanesi.com CMS Projesi - Ana İndeks
## Versiyon: 3.0 | Son Güncelleme: Ocak 2025

---

## 🔄 WORKSPACE CONTEXT DURUMU (Auto-Refresh)
| Alan | Değer |
|------|-------|
| RulesVersion | 1.1 |
| RuleHash | (bkz: .copilot/rulehash.txt) |
| ContextRefreshedAt | {{REFRESH_UTC}} |
| CanonicalRules | docs/VS_WORKFLOW_RULES.md |
| CopilotInstructions | .github/copilot-instructions.md |

> Bu blok otomatik güncellemeye uygundur; manuel düzenlemeyin. `22_CONTEXT_REFRESH.sql` metadata anahtarlarını senkronlar.

---

## 🧠 PROJE HAKKINDA

**DiskHastanesi.com CMS Admin Panel**  
AI destekli, multi-tenant SaaS CMS platformu

**Hedef:** Pazarlama/kurumsal ekibin web sitesi içeriklerini (sayfalar, hizmetler, blog, medya, SEO) **7 AI Agent** ile hızlı ve güvenli yönetmesi.

**Modüller:** CMS, CRM, Website Builder, AI Chatbot

---

## ✅ APPROVED TECH STACK (AI Council Decision)

### **Backend:**
- **Framework:** ASP.NET Core 8.0
- **Architecture:** Vertical Slice Architecture
- **ORM:** Entity Framework Core 8
- **API Pattern:** RESTful + Minimal APIs

### **Frontend:**
- **Framework:** Vue.js 3 + Composition API + TypeScript
- **Build Tool:** Vite
- **UI Design:** Microsoft Fluent 2 Design System
- **CSS Framework:** Tailwind CSS + Fluent UI Web Components

### **Cloud Infrastructure (Azure):**
- **Hosting:** Azure Container Apps (KEDA auto-scaling)
- **Database:** Azure SQL Database (Standard S3 / Elastic Pool planlanıyor)
- **Authentication:** Azure AD B2C + ASP.NET Core Identity
- **Storage:** Azure Blob Storage (Hot/Cool tiers)
- **CDN:** Azure CDN + Azure Front Door
- **CI/CD:** GitHub Actions (OIDC)

### **Development Tools:**
- **IDE:** Visual Studio 2022 / VS Code
- **Source Control:** Git + GitHub
- **Package Manager:** NuGet (.NET), npm (Node.js)

**Decision Source:** AI Council Report (ai_council/TECH_STACK_DECISION.txt)  
**Consensus Score:** 78%  
**Decision Date:** January 2025

---

## 🗄️ SQL DATABASE

### **Bağlantı Bilgileri:**
```
Server: (localdb)\MSSQLLocalDB
Database: DiskHastanesiDocs
Integrated Security: true
```

### **Database Yapısı (Updated):**
```
database/
├─ 00_MASTER_SCHEMA.sql    • Tüm tablolar (10 tablo)
├─ 01_INDEXES.sql          • Performance indexes
├─ 02_VIEWS.sql            • Helper views (vw_SystemHealth)
├─ 03_SEED_DATA.sql        • 18 AI rule + 5 AI model + 3 knowledge
├─ 04_SYNC_SYSTEM.sql      • Senkronizasyon sistemi + 2 kural
├─ 05_CHATBOT_SYSTEM.sql   • Chatbot tables
├─ 06_CMS_ROUTES.sql       • CMS routing system
├─ 07_SUBDOMAINS.sql       • Subdomain management
├─ 08_CRM_SYSTEM.sql       • CRM system
├─ 09_WEBSITE_STRUCTURE.sql • Website structure
├─ 10_AI_COUNCIL.sql       • AI Council system
├─ 11_CMS_CONTENT.sql      • NEW: Blog, Media, SEO (27 new tables)
└─ README.md               • Kurulum kılavuzu
```

### **Database Status:**
- **Current:** 16 tables
- **After MVP:** 43 tables (+27 new)
- **6 months:** 55 tables
- **1 year:** 70 tables

### **New Tables (CMS Features - MVP):**
(İçerik listesi önceki sürümle aynı – kısaltıldı)

---

## 🔍 SENKRONİZASYON KONTROLÜ
```sql
SELECT * FROM vw_SystemHealth; -- Sağlık / sayım senkron durumu
```
Metadata güncelleme örneği:
```sql
UPDATE SystemMetadata 
SET MetadataValue = 'YeniDeger', LastUpdatedAt = GETDATE() 
WHERE MetadataKey = 'MetadataKeyAdi';
```

---

## 🚀 HIZLI BAŞLANGIÇ
(Önceki içerik korunmuştur – gereksiz tekrar kaldırıldı)

---

## 📌 NOTLAR
1. TODO, AI dokümanları ve proje yapısı SQL’de tutulur.
2. Bu dosya (PROJECT_INDEX.md) konseptsel özet sağlar; sayısal doğruluk SystemMetadata tablosundadır.
3. RuleHash uyuşmazsa `sync-rules.ps1` çalıştır.
4. Context yenileme görevi tamamlandı.

---
**Context Refreshed:** {{REFRESH_UTC}}  
**Rules Version:** 1.1  
**Status:** Synchronized ✅
