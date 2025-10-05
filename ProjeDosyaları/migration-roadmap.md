# Migration Roadmap (Taşıma Yol Haritası)

**Kaynak:** diskhastanesi.com projesi - Microsoft Stack'e taşıma için hazırlanmıştır

Bu dosya, Next.js/Supabase'den ASP.NET Core/Azure'a geçiş için detaylı migration planını, fazları, milestone'ları, riskleri ve success criteria'yı içerir.

---

## 1. Executive Summary

### 1.1 Migration Overview

**Current State:**
- Frontend: Next.js 15.5.4 (App Router)
- Backend: Supabase Edge Functions + Next.js API routes
- Database: Supabase PostgreSQL
- Hosting: Vercel
- Cost: ~$45-100/month

**Target State:**
- Frontend: ASP.NET Core 8.0 (Razor Pages / Blazor)
- Backend: Azure Functions + ASP.NET Core Web API
- Database: Azure SQL Database
- Hosting: Azure App Service + Front Door
- Cost: ~$100-200/month

**Timeline:** 12 weeks (3 months)
**Team:** 2-3 developers + 1 DevOps engineer
**Budget:** $15,000-20,000 (labor + Azure resources)

### 1.2 Migration Goals

**Primary Objectives:**
1. ✅ Migrate to Microsoft technology stack
2. ✅ Maintain 100% feature parity
3. ✅ Zero data loss
4. ✅ Minimal downtime (<1 hour)
5. ✅ Improve performance (target: 20% faster)

**Success Criteria:**
- All features migrated and tested
- Database migrated with integrity validation
- Performance metrics meet or exceed current
- Security compliance maintained (KVKK, GDPR)
- Cost within budget
- Team trained on new stack

---

## 2. Migration Phases

### Phase 1: Preparation & Planning (Weeks 1-2)

**Objectives:**
- Complete discovery and documentation
- Set up Azure infrastructure
- Define migration strategy
- Establish rollback procedures

**Tasks:**

**Week 1: Discovery**
- [x] Audit current application (features, dependencies, APIs)
- [x] Document database schema
- [x] Identify third-party integrations (SendGrid, hCaptcha, Slack)
- [x] Create comprehensive documentation set (AI-transition/)
- [x] Stakeholder alignment meeting

**Week 2: Infrastructure Setup**
- [ ] Provision Azure resources (Dev + Staging)
  - Resource Group
  - App Service Plan (B1 for staging)
  - Azure SQL Database (Basic for staging)
  - Storage Account
  - Key Vault
  - Application Insights
- [ ] Configure Azure DevOps / GitHub Actions
- [ ] Set up monitoring and alerting
- [ ] Create Bicep IaC templates

**Deliverables:**
- ✅ Complete documentation (API Reference, Database Schema, Security, Testing Strategy, Deployment Guide, Troubleshooting, Migration Roadmap)
- ✅ Architecture diagrams (current vs target)
- [ ] Azure Dev/Staging environments ready
- [ ] CI/CD pipeline template

**Risks:**
- Azure subscription limits (mitigate: Request quota increase)
- Team unfamiliar with Azure (mitigate: Training sessions)

---

### Phase 2: Backend Migration (Weeks 3-6)

**Objectives:**
- Migrate database schema to Azure SQL
- Rewrite API endpoints in ASP.NET Core
- Set up authentication with Azure AD B2C
- Implement business logic

**Week 3: Database Migration**
- [ ] Create Entity Framework Core models
- [ ] Generate EF Core migrations from schema
- [ ] Set up Azure SQL Database (staging)
- [ ] Export Supabase PostgreSQL data
- [ ] Transform data (PostgreSQL → SQL Server)
- [ ] Import to Azure SQL
- [ ] Validate data integrity (row counts, checksums)
- [ ] Test backup/restore procedures

**Week 4: Core API Development**
- [ ] Create ASP.NET Core Web API project
- [ ] Implement Leads API (`POST /api/leads`, `GET /api/leads`, `PATCH /api/leads/{id}`)
- [ ] Implement Contact API (`POST /api/contact`)
- [ ] Implement Consultations API (`POST /api/consultations`)
- [ ] Set up FluentValidation
- [ ] Add input sanitization (HtmlSanitizer)
- [ ] Implement rate limiting

**Week 5: Content API & Edge Functions**
- [ ] Implement Content API (`GET /api/content/pages/{slug}`)
- [ ] Implement Case Studies API (`GET /api/content/case-studies`)
- [ ] Migrate Edge Functions to Azure Functions
  - `notify-lead` → Azure Function (HTTP trigger)
  - SendGrid email integration
  - Slack webhook integration
- [ ] Set up health check endpoint (`/health`)

**Week 6: Authentication & Authorization**
- [ ] Configure Azure AD B2C tenant
- [ ] Implement OAuth 2.0 + OpenID Connect
- [ ] Set up roles (admin, sales, support, viewer)
- [ ] Implement policy-based authorization
- [ ] Add JWT token validation
- [ ] Test login/logout flows
- [ ] Implement MFA for admin roles

**Deliverables:**
- [ ] Database migrated to Azure SQL
- [ ] All API endpoints functional (feature parity)
- [ ] Authentication working (Azure AD B2C)
- [ ] Unit tests passing (>85% coverage)
- [ ] Integration tests passing
- [ ] API documentation (Swagger)

**Risks:**
- Data migration complexity (mitigate: Incremental testing)
- PostgreSQL → SQL Server incompatibilities (mitigate: Data transformation scripts)
- Azure AD B2C learning curve (mitigate: Microsoft documentation, pilot users)

---

### Phase 3: Frontend Migration (Weeks 7-9)

**Objectives:**
- Rewrite UI in ASP.NET Core Razor Pages / Blazor
- Implement responsive design (same UX)
- Integrate with migrated backend APIs
- i18n support (TR/EN)

**Week 7: Core Pages**
- [ ] Set up ASP.NET Core MVC project
- [ ] Implement Layout (Header, Footer)
- [ ] Implement Homepage (`/`)
- [ ] Implement Service Pages (`/veri-kurtarma`, `/siber-guvenlik`)
- [ ] Implement Case Studies List (`/vaka-analizleri`)
- [ ] Implement Case Study Detail (`/vaka-analizleri/{slug}`)
- [ ] Set up Tailwind CSS / Bootstrap integration
- [ ] Implement responsive breakpoints (mobile, tablet, desktop)

**Week 8: Forms & Interactions**
- [ ] Implement Lead Form (`/teklif-al`)
- [ ] Client-side validation (jQuery Validation / Blazor validation)
- [ ] Server-side validation (FluentValidation)
- [ ] hCaptcha integration
- [ ] Success/Error messaging
- [ ] Implement Consultation Form (`/uzmanlarimizla-gorusun`)
- [ ] Implement Contact Form

**Week 9: i18n & CMS Integration**
- [ ] Set up Resource files (.resx) for TR/EN
- [ ] Implement locale switcher
- [ ] Integrate with Content API (dynamic content)
- [ ] Implement CMS admin panel (optional, simplified)
- [ ] SEO: Meta tags, structured data (JSON-LD)
- [ ] Accessibility: WCAG 2.1 AA compliance
- [ ] Implement 404 page, error pages

**Deliverables:**
- [ ] All pages migrated (feature parity with Next.js)
- [ ] Responsive design tested (Chrome, Firefox, Safari, Edge)
- [ ] i18n working (TR/EN)
- [ ] Forms functional (validation, submission, success flows)
- [ ] E2E tests passing (Playwright)
- [ ] Accessibility tests passing (axe-core)

**Risks:**
- UI/UX differences from Next.js (mitigate: Pixel-perfect design review)
- Razor Pages learning curve (mitigate: Templates, examples)
- SEO impact (mitigate: Verify meta tags, structured data, sitemap)

---

### Phase 4: Testing & Quality Assurance (Week 10)

**Objectives:**
- Comprehensive testing across all layers
- Performance benchmarking
- Security audit
- Bug fixing

**Testing Checklist:**

**Unit Tests**
- [ ] Controllers: 90%+ coverage
- [ ] Services: 95%+ coverage
- [ ] Validators: 100% coverage
- [ ] All tests passing

**Integration Tests**
- [ ] API endpoints (happy path + error cases)
- [ ] Database operations (CRUD)
- [ ] Authentication flows
- [ ] Third-party integrations (SendGrid, hCaptcha)

**E2E Tests (Playwright)**
- [ ] Lead submission flow
- [ ] Consultation request flow
- [ ] Contact form submission
- [ ] Navigation (all pages)
- [ ] i18n switching
- [ ] Mobile navigation
- [ ] Form validations

**Performance Tests**
- [ ] Load test: 100 concurrent users (1 hour)
- [ ] Stress test: Ramp to 2000 users
- [ ] Spike test: 100 → 1000 → 100 users
- [ ] Target metrics:
  - Response time p50 < 200ms ✅
  - Response time p95 < 500ms ✅
  - Response time p99 < 1000ms ✅
  - Error rate < 0.1% ✅
  - Throughput > 100 RPS ✅

**Security Audit**
- [ ] OWASP ZAP scan
- [ ] SQL injection testing
- [ ] XSS testing
- [ ] CSRF protection validation
- [ ] Authentication/authorization bypass attempts
- [ ] Secrets management review (no hardcoded credentials)
- [ ] HTTPS enforcement
- [ ] Security headers (CSP, HSTS, X-Frame-Options)

**Accessibility Audit**
- [ ] WCAG 2.1 AA compliance (axe-core)
- [ ] Screen reader testing (NVDA)
- [ ] Keyboard navigation testing
- [ ] Color contrast validation

**Deliverables:**
- [ ] All tests passing
- [ ] Performance benchmarks documented
- [ ] Security audit report
- [ ] Bug list (all P0/P1 bugs fixed)
- [ ] Test summary report

**Risks:**
- Performance regressions (mitigate: Early benchmarking)
- Security vulnerabilities (mitigate: Continuous scanning)
- Browser compatibility issues (mitigate: Cross-browser testing)

---

### Phase 5: Staging Deployment & User Acceptance Testing (Week 11)

**Objectives:**
- Deploy to Azure Staging environment
- Conduct User Acceptance Testing (UAT)
- Train internal team
- Prepare production deployment

**Tasks:**

**Staging Deployment**
- [ ] Deploy application to Azure App Service (Staging)
- [ ] Configure custom domain (`staging.diskhastanesi.com`)
- [ ] Set up Azure Front Door (CDN)
- [ ] Configure SSL certificate
- [ ] Run database migrations
- [ ] Seed production-like data
- [ ] Smoke tests (health endpoint, critical paths)

**User Acceptance Testing (UAT)**
- [ ] Invite stakeholders to test staging
- [ ] Prepare UAT test cases
- [ ] Collect feedback
- [ ] Fix critical bugs
- [ ] Re-test

**Training**
- [ ] Train sales team on CRM features
- [ ] Train support team on lead management
- [ ] Train devs on Azure deployment procedures
- [ ] Document admin workflows

**Production Readiness**
- [ ] Create production Bicep templates
- [ ] Provision production Azure resources
  - App Service Plan (P1v3, 2 instances)
  - Azure SQL Database (S1, zone-redundant)
  - Front Door + WAF
  - Production Key Vault
  - Application Insights (90 days retention)
- [ ] Configure production secrets (Key Vault)
- [ ] Set up monitoring alerts (CPU, memory, 5xx errors, response time)
- [ ] Prepare rollback plan
- [ ] Schedule deployment window (low traffic time)

**Deliverables:**
- [ ] Staging environment fully functional
- [ ] UAT sign-off from stakeholders
- [ ] Production infrastructure ready
- [ ] Team trained
- [ ] Go-live checklist prepared

**Risks:**
- UAT reveals major issues (mitigate: Early stakeholder demos)
- Production resource provisioning delays (mitigate: Early setup)

---

### Phase 6: Production Deployment & Cutover (Week 12)

**Objectives:**
- Deploy to production
- Database cutover with minimal downtime
- Parallel run (old + new systems)
- Gradual traffic migration (10% → 50% → 100%)
- Decommission old system

**Day 1-2: Pre-Deployment**
- [ ] Final code freeze
- [ ] Run full test suite (all passing)
- [ ] Database backup (Supabase)
- [ ] Stakeholder notification (deployment window)
- [ ] On-call team ready

**Day 3: Initial Deployment (Friday evening, low traffic)**
- [ ] Deploy application to Azure App Service (Production)
- [ ] Deploy to Blue slot first (blue-green deployment)
- [ ] Run database migration (PostgreSQL → Azure SQL)
  - Freeze writes on Supabase (maintenance mode)
  - Export data
  - Import to Azure SQL
  - Validate data integrity
  - Estimated downtime: 30-60 minutes
- [ ] Warm up Blue slot
- [ ] Run smoke tests on Blue slot
- [ ] If tests pass, swap Blue → Production
- [ ] Re-enable writes (Azure SQL)

**Day 4: Parallel Run (10% traffic to new system)**
- [ ] Configure Azure Front Door to split traffic
  - 90% → old system (Vercel)
  - 10% → new system (Azure)
- [ ] Monitor metrics:
  - Error rate
  - Response time
  - Throughput
  - User feedback
- [ ] Log and fix any issues

**Day 5-6: Gradual Traffic Increase**
- [ ] Increase to 50% Azure / 50% Vercel
- [ ] Monitor for 24 hours
- [ ] If stable, increase to 100% Azure
- [ ] Keep Vercel as fallback (instant rollback if needed)

**Day 7: Full Cutover**
- [ ] 100% traffic to Azure
- [ ] Monitor for 48 hours
- [ ] Decommission Vercel deployment (keep backup)
- [ ] Decommission Supabase (after 30-day retention)

**Rollback Plan:**
```bash
# If critical issues detected:

# 1. Immediate: Revert Front Door to 100% Vercel
az network front-door routing-rule update \
  --front-door-name fd-diskhastanesi \
  --name DefaultRoutingRule \
  --resource-group rg-diskhastanesi-prod \
  --accepted-protocols Https \
  --backend-pool OldBackendPool

# 2. Database rollback (if needed)
# Restore Supabase from backup
# Re-enable Supabase write access

# 3. Post-mortem analysis
# Fix issues, retry deployment next window
```

**Deliverables:**
- [ ] Production deployment successful
- [ ] 100% traffic on Azure
- [ ] All metrics within targets
- [ ] Zero data loss verified
- [ ] Old system decommissioned
- [ ] Go-live announcement

**Risks:**
- Database migration issues (mitigate: Extensive testing, backup/restore plan)
- Production performance issues (mitigate: Load testing, gradual rollout)
- User confusion (mitigate: Communication plan, training)

---

## 3. Timeline & Milestones

### Gantt Chart

```
Week  1  2  3  4  5  6  7  8  9  10 11 12
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 1: Prep          ██
Phase 2: Backend          ████████
Phase 3: Frontend                    ██████
Phase 4: Testing                           ██
Phase 5: UAT                                ██
Phase 6: Production                           ██
```

### Key Milestones

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| M1: Documentation complete | Week 2 | ✅ |
| M2: Azure infrastructure ready | Week 2 | ⏳ |
| M3: Database migrated | Week 3 | ⏳ |
| M4: All APIs migrated | Week 6 | ⏳ |
| M5: Frontend migrated | Week 9 | ⏳ |
| M6: Testing complete | Week 10 | ⏳ |
| M7: UAT sign-off | Week 11 | ⏳ |
| M8: Production go-live | Week 12 | ⏳ |

---

## 4. Resource Allocation

### Team Structure

**Development Team:**
- Lead Developer (ASP.NET Core): 12 weeks @ 40h/week = 480 hours
- Full-Stack Developer: 12 weeks @ 40h/week = 480 hours
- Frontend Developer (part-time): 4 weeks @ 20h/week = 80 hours

**DevOps/Infrastructure:**
- DevOps Engineer: 6 weeks @ 20h/week = 120 hours

**QA/Testing:**
- QA Engineer: 3 weeks @ 40h/week = 120 hours (Week 10-12)

**Total Effort:** ~1280 hours

### Budget Breakdown

**Labor Costs:**
- Development: 1040 hours × $50/hour = $52,000
- DevOps: 120 hours × $60/hour = $7,200
- QA: 120 hours × $40/hour = $4,800
- **Total Labor:** $64,000

**Infrastructure Costs (3 months):**
- Azure Dev/Staging: $50/month × 3 = $150
- Azure Production: $150/month × 1 = $150
- Vercel (parallel run): $20/month × 1 = $20
- Supabase (parallel run): $25/month × 1 = $25
- **Total Infrastructure:** $345

**Contingency:** 15% of labor = $9,600

**Total Estimated Cost:** $73,945

**Note:** For internal team, labor costs are sunk. External costs: ~$400 (infrastructure only).

---

## 5. Risk Management

### Risk Matrix

| Risk | Probability | Impact | Mitigation | Owner |
|------|-------------|--------|------------|-------|
| Data migration data loss | Low | Critical | Extensive testing, backups, validation scripts | Lead Dev |
| Performance degradation | Medium | High | Load testing, gradual rollout, monitoring | DevOps |
| Security vulnerability | Medium | Critical | Security audit, penetration testing, code review | Lead Dev |
| Timeline overrun | High | Medium | Buffer time, agile sprints, daily standups | PM |
| Azure outage during cutover | Low | High | Scheduled maintenance window, rollback plan | DevOps |
| Team knowledge gaps | Medium | Medium | Training, pair programming, documentation | Lead Dev |
| Budget overrun | Low | Medium | Fixed scope, prioritization, contingency | PM |
| SEO ranking drop | Medium | High | Meta tags validation, structured data, redirects | Frontend Dev |
| User resistance | Low | Medium | Training, communication, gradual rollout | PM |
| Third-party integration failure | Medium | Medium | Mock APIs, fallback mechanisms, health checks | Lead Dev |

### Mitigation Strategies

**1. Data Loss Prevention**
- Multiple backups before migration
- Data integrity validation scripts (row counts, checksums)
- Parallel run with old database as fallback
- Point-in-time restore capability

**2. Performance Assurance**
- Baseline performance metrics from current system
- Load testing matching production traffic patterns
- Auto-scaling configured
- CDN for static assets

**3. Security Hardening**
- OWASP ZAP automated scanning in CI/CD
- Manual penetration testing before go-live
- Security headers validation
- Secrets in Key Vault (no hardcoded credentials)

**4. Schedule Management**
- Two-week buffer built into timeline
- Weekly progress reviews
- Blocker escalation process
- MVP feature set (defer nice-to-haves if needed)

---

## 6. Communication Plan

### Stakeholder Updates

**Weekly Status Reports (Fridays):**
- Progress summary (completed tasks, blockers)
- Metrics (code coverage, test pass rate, velocity)
- Risks and mitigation actions
- Next week plan

**Recipients:**
- CTO
- Product Manager
- Sales Director
- Support Manager

**Deployment Notifications:**

**7 days before go-live:**
- Deployment window announcement
- Expected downtime (30-60 minutes)
- User impact (read-only mode during migration)

**Day before go-live:**
- Reminder notification
- Support team on-call schedule

**During deployment:**
- Status updates every 30 minutes
- Immediate notification if issues

**Post-deployment:**
- Go-live announcement
- Known issues (if any)
- Support contact information

---

## 7. Success Metrics

### Technical Metrics

**Performance:**
- [ ] Response time p95 < 500ms (baseline: 600ms) → 17% improvement
- [ ] TTFB < 200ms (baseline: 250ms) → 20% improvement
- [ ] LCP < 2.5s (baseline: 2.8s) → 11% improvement
- [ ] Lighthouse score > 90 (baseline: 85)

**Reliability:**
- [ ] Uptime > 99.9% (first month)
- [ ] Error rate < 0.1%
- [ ] Zero data loss incidents

**Security:**
- [ ] Zero critical vulnerabilities
- [ ] KVKK/GDPR compliance maintained
- [ ] No security incidents (first 3 months)

**Cost:**
- [ ] Monthly cost $100-200 (baseline: $45-100) → Expected increase acceptable
- [ ] ROI positive within 6 months (scalability benefits)

### Business Metrics

**User Experience:**
- [ ] User satisfaction survey > 4/5
- [ ] Support ticket volume < baseline
- [ ] Form submission success rate > 95%

**Operational:**
- [ ] Team trained on new stack (100% completion)
- [ ] Documentation complete and up-to-date
- [ ] Deployment process documented and repeatable

---

## 8. Post-Migration Activities

### Week 13-14: Stabilization

**Tasks:**
- [ ] Monitor production metrics daily
- [ ] Address post-launch issues (P0/P1)
- [ ] Optimize performance (cache tuning, query optimization)
- [ ] Collect user feedback
- [ ] Conduct retrospective meeting

### Week 15-16: Decommissioning

**Tasks:**
- [ ] Export final backup from Supabase
- [ ] Cancel Supabase subscription
- [ ] Cancel Vercel subscription
- [ ] Archive old codebase (GitHub archive)
- [ ] Update documentation (remove legacy references)

### Ongoing: Continuous Improvement

**Tasks:**
- [ ] Implement feature flags for gradual rollout
- [ ] Optimize Azure costs (right-sizing, reserved instances)
- [ ] Enhance monitoring dashboards
- [ ] Expand test coverage (target: 95%)
- [ ] Implement advanced features:
  - AI chatbot integration
  - Advanced CRM workflows
  - Predictive analytics

---

## 9. Lessons Learned Template

**Post-Migration Retrospective (Week 13)**

**What Went Well:**
- (To be filled after migration)

**What Could Be Improved:**
- (To be filled after migration)

**Action Items:**
- (To be filled after migration)

**Key Takeaways:**
- (To be filled after migration)

---

## 10. Appendix

### A. Technology Stack Comparison

| Component | Current | Target | Reason for Change |
|-----------|---------|--------|-------------------|
| Frontend Framework | Next.js 15 | ASP.NET Core 8.0 | Microsoft stack standardization |
| Backend Runtime | Node.js | .NET 8 | Better tooling, performance, enterprise support |
| Database | PostgreSQL (Supabase) | Azure SQL | Managed service, integration with Azure ecosystem |
| Auth | Supabase Auth (planned) | Azure AD B2C | Enterprise SSO, MFA, compliance |
| Hosting | Vercel | Azure App Service | Unified Azure platform, better control |
| CDN | Vercel Edge Network | Azure Front Door | WAF, advanced routing, DDoS protection |
| Monitoring | Sentry | Application Insights | Native Azure integration, cost-effective |
| CI/CD | GitHub Actions | Azure DevOps / GitHub Actions | Enterprise DevOps features |

### B. Migration Checklist (Master)

**Pre-Migration:**
- [x] Documentation complete (AI-transition/)
- [ ] Azure infrastructure provisioned
- [ ] CI/CD pipeline ready
- [ ] Team trained on Azure/ASP.NET Core
- [ ] Rollback procedures tested

**Migration:**
- [ ] Database migrated and validated
- [ ] All API endpoints migrated
- [ ] Frontend pages migrated
- [ ] Authentication configured
- [ ] Third-party integrations working
- [ ] All tests passing

**Post-Migration:**
- [ ] Production deployed
- [ ] Traffic cutover complete
- [ ] Monitoring operational
- [ ] Old system decommissioned
- [ ] Post-mortem completed

### C. Escalation Path

**Issue Severity:**

**P0 (Critical):** Production down, data loss
- **Response Time:** 15 minutes
- **Escalation:** CTO immediately

**P1 (High):** Major feature broken, security issue
- **Response Time:** 1 hour
- **Escalation:** Lead Developer → CTO

**P2 (Medium):** Minor feature broken, performance degraded
- **Response Time:** 4 hours
- **Escalation:** Lead Developer

**P3 (Low):** UI issue, minor bug
- **Response Time:** 1 business day
- **Escalation:** Ticket queue

**Contact Information:**
- Lead Developer: [name]@diskhastanesi.com
- DevOps Engineer: [name]@diskhastanesi.com
- CTO: [name]@diskhastanesi.com
- On-Call Rotation: Slack #oncall

---

**Doküman Sahibi:** Oğuzhan Pişgin  
**Son Güncelleme:** 2025-10-04  
**Sonraki Review:** Her hafta Cuma (migration süresince)  

**Onay:**
- [ ] CTO
- [ ] Product Manager
- [ ] Lead Developer
- [ ] DevOps Lead

---

**Son Güncelleme:** 2025-10-04
