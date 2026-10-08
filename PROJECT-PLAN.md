# Project Plan: Chemgraph — WBS (Work Breakdown Structure)

> **Версия:** 1.0  
> **Статус:** 🟡 Активный — обновляется еженедельно  
> **Период:** 2026-10-06 → 2026-11-02 (4 недели = Фаза 1 + начало Фазы 2)  
> **Методология:** Documentation-first → Infrastructure-as-Code → Incremental Delivery

---

## 1. Executive Summary

| Параметр | Значение |
|----------|----------|
| **Проект** | Chemgraph — научно-популярный портал Chemistry + Pharma + AI |
| **Фаза** | 1: Documentation & Planning (Week 1) → 2: Infrastructure Alpha (Weeks 2-3) |
| **Команда** | 1 Senior Full-Stack DevOps (вы) + AI-ассистент |
| **Бюджет** | $0-50/мес (free tiers, локальная инфраструктура) |
| **Ключевой риск** | Зависимость от внешних сервисов (Cloudflare, домен, SMTP) |

---

## 2. WBS — Work Breakdown Structure

### Неделя 1 (2026-10-06 → 2026-10-10): Фаза 1 — Документация

| ID | Work Package | Задача | Оценка | Статус | Owner |
|----|--------------|--------|--------|--------|-------|
| 1.1 | **README.md** | Overview, quick start, структура репо, env примеры | 2ч | ✅ Done | You |
| 1.2 | **ARCHITECTURE.md** | Mermaid диаграммы: компоненты, data flow, deployment, ADR log | 4ч | ✅ Done | You |
| 1.3 | **ROADMAP.md** | 4 фазы, milestones, Gantt, бюджет, риски, KPI | 3ч | ✅ Done | You |
| 1.4 | **CONTENT-STRATEGY.md** | Таксономия тегов, типы контента, editorial policy, календарь | 4ч | ✅ Done | You |
| 1.5 | **DEPLOYMENT.md** | Local Alpha, Staging, Production, миграция, troubleshooting | 4ч | ✅ Done | You |
| 1.6 | **SECURITY.md** | Threat model, secrets, backup/DR, incident response, compliance | 4ч | ✅ Done | You |
| 1.7 | **PROJECT-PLAN.md** | Этот документ — WBS детализация, tracking, definitions of done | 2ч | 🔄 In Progress | You |
| 1.8 | **Review Gate** | Ревью всех 7 docs, approval → переход к Фазе 2 | 1ч | ⏳ Pending | You |

**Неделя 1 Итого:** ~24 часа | **Done:** 6/8

---

### Неделя 2 (2026-10-13 → 2026-10-17): Фаза 2.1 — Docker Stack

| ID | Work Package | Задача | Оценка | Зависимости | Статус |
|----|--------------|--------|--------|-------------|--------|
| 2.1.1 | **docker-compose.yml** | Ghost, MySQL 8, Redis 7, Nginx — volumes, healthchecks, networks | 4ч | 1.8 | ⏳ |
| 2.1.2 | **Dockerfile.ghost** | Multi-stage, non-root, dumb-init, healthcheck, GHOST_VERSION arg | 3ч | 2.1.1 | ⏳ |
| 2.1.3 | **.dockerignore + .env.example** | Исключения, шаблон с комментариями | 1ч | 2.1.1 | ⏳ |
| 2.1.4 | **config/nginx.conf** | Reverse proxy, rate limits, CSP, HSTS, SSL params, upstream | 3ч | 2.1.1 | ⏳ |
| 2.1.5 | **config/ghost/config.production.json** | MySQL SSL, mail, security headers, privacy, CSP | 2ч | 2.1.1 | ⏳ |
| 2.1.6 | **Makefile** | dev, down, logs, shell-*, backup, restore, clean, lint, db-* | 4ч | 2.1.1 | ⏳ |
| 2.1.7 | **Test Run: `make dev`** | Полный цикл: build → up → healthchecks → Ghost на :2368 | 2ч | 2.1.1-2.1.6 | ⏳ |
| 2.1.8 | **Fix & Iterate** | Исправление ошибок сборки, healthchecks, permissions | 2ч | 2.1.7 | ⏳ |

**Неделя 2 Итого:** ~21 час | **Milestone M2.1:** `make dev` работает без ошибок

---

### Неделя 3 (2026-10-20 → 2026-10-24): Фаза 2.2-2.4 — Tunnel, Ghost Setup, CI/CD

#### 2.2 Cloudflare Tunnel (Windows 11) — 3 дня

| ID | Задача | Оценка | Зависимости | Статус |
|----|--------|--------|-------------|--------|
| 2.2.1 | `scripts/setup-tunnel.ps1` — winget install, login, create, route dns | 3ч | 2.1.8 | ⏳ |
| 2.2.2 | `config/cloudflared.yml` — ingress rules, localhost:80 | 2ч | 2.2.1 | ⏳ |
| 2.2.3 | Windows Service install + auto-start | 2ч | 2.2.2 | ⏳ |
| 2.2.4 | Test: `https://chemgraph.ru` — 200 OK, SSL A+, HSTS | 2ч | 2.2.3 | ⏳ |
| 2.2.5 | Document tunnel credentials in 1Password/Vault | 1ч | 2.2.4 | ⏳ |

#### 2.3 Ghost Initial Setup — 2 дня

| ID | Задача | Оценка | Зависимости | Статус |
|----|--------|--------|-------------|--------|
| 2.3.1 | Owner account setup via `/ghost` | 0.5ч | 2.2.4 | ⏳ |
| 2.3.2 | Settings: Publication URL, Title, Description, Language | 0.5ч | 2.3.1 | ⏳ |
| 2.3.3 | Email: SMTP config (Yandex/Mailgun), test send | 2ч | 2.3.2 | ⏳ |
| 2.3.4 | Members: Portals, Tiers (Free), Newsletter signup | 2ч | 2.3.3 | ⏳ |
| 2.3.5 | Design: Upload base theme (Source fork), basic customization | 2ч | 2.3.4 | ⏳ |
| 2.3.6 | Verify: sitemap.xml, robots.txt, RSS, JSON-LD, /health | 1ч | 2.3.5 | ⏳ |

#### 2.4 GitHub Repo & CI/CD — 2 дня

| ID | Задача | Оценка | Зависимости | Статус |
|----|--------|--------|-------------|--------|
| 2.4.1 | Create private repo `chemgraph`, push main | 0.5ч | 1.8 | ⏳ |
| 2.4.2 | `.gitignore` (Ghost, Node, Python, .env, secrets, IDE) | 1ч | 2.4.1 | ⏳ |
| 2.4.3 | Branch protection: main (require PR, CI pass), develop | 0.5ч | 2.4.1 | ⏳ |
| 2.4.4 | `.github/workflows/ci.yml` — lint, test, build, trivy, codeql | 3ч | 2.4.1 | ⏳ |
| 2.4.5 | `.github/workflows/deploy.yml` — build & push to GHCR | 2ч | 2.4.4 | ⏳ |
| 2.4.6 | GitHub Environments: production (manual approval) | 1ч | 2.4.5 | ⏳ |
| 2.4.7 | Dependabot + CodeQL + Secret scanning enabled | 1ч | 2.4.1 | ⏳ |

**Неделя 3 Итого:** ~24 часа | **Milestones:** M2.2 (Tunnel works), M2.3 (Ghost configured), M2.4 (CI/CD green)

---

### Неделя 4 (2026-10-27 → 2026-10-31): Фаза 2.5 — Hardening & Beta Prep

| ID | Work Package | Задача | Оценка | Зависимости | Статус |
|----|--------------|--------|--------|-------------|--------|
| 2.5.1 | **Backup/Restore Drill** | `make backup` → `make restore` на чистом стеке | 2ч | 2.1.8 | ⏳ |
| 2.5.2 | **Security Hardening** | CSP tuning, rate limits, fail2ban (SSH), UFW, auditd | 3ч | 2.3.6 | ⏳ |
| 2.5.3 | **Monitoring Baseline** | Uptime Kuma (local Docker), checks: HTTP, SSL, DNS, TCP | 2ч | 2.2.4 | ⏳ |
| 2.5.4 | **Documentation Sync** | Обновить DEPLOYMENT.md, ARCHITECTURE.md под реальную инфраструктуру | 2ч | 2.1-2.4 | ⏳ |
| 2.5.5 | **Content Prep** | Создать 3-5 draft статей в Ghost для тестирования темы | 4ч | 2.3.6 | ⏳ |
| 2.5.6 | **Phase 2 Retrospective** | Lessons learned, blockers, plan adjustments для Фазы 3 | 1ч | All | ⏳ |
| 2.5.7 | **Phase 3 Kickoff Planning** | Детальный спринт-план для Недели 5-8 (Theme, Content, Newsletter Bridge) | 2ч | 2.5.6 | ⏳ |

**Неделя 4 Итого:** ~16 часов | **Exit Criteria Фазы 2:** Все чек-листы зелёные

---

## 3. Detailed Task Cards (для трекинга)

### Template (копируйте для каждой задачи)

```markdown
## TASK-XXX: [Название]

**WP:** [Work Package ID] | **Estimate:** [Xч] | **Actual:** [Xч]
**Status:** ⏳ Todo / 🔄 In Progress / 👀 Review / ✅ Done / ❌ Blocked
**Assignee:** [You]
**Dependencies:** [TASK-YYY]
**Blockers:** [None / Description]

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Notes
- Key decisions:
- Issues encountered:
- Follow-up needed:
```

### Example: TASK-2.1.1

```markdown
## TASK-2.1.1: docker-compose.yml — Core Stack

**WP:** 2.1 | **Estimate:** 4ч | **Actual:** 0ч
**Status:** ⏳ Todo
**Assignee:** You
**Dependencies:** 1.8 (Phase 1 Review Gate)
**Blockers:** None

### Acceptance Criteria
- [ ] Services: ghost, mysql, redis, nginx
- [ ] Named volumes: mysql_data, redis_data, ghost_content
- [ ] Healthchecks для всех сервисов (mysqladmin, redis-cli, wget ghost, wget nginx)
- [ ] Networks: chemgraph-network (bridge)
- [ ] Environment variables из .env (no hardcoded secrets)
- [ ] Ghost depends_on mysql/redis с condition: service_healthy
- [ ] Nginx depends_on ghost
- [ ] Ports: nginx 80:80, ghost 127.0.0.1:2368, mysql 127.0.0.1:3306, redis 127.0.0.1:6379
- [ ] MySQL: utf8mb4, native_password, GTID ready
- [ ] Redis: appendonly, requirepass

### Notes
- Use mysql:8.0, redis:7-alpine, nginx:alpine, ghost:${GHOST_VERSION}
- Ghost build из Dockerfile.ghost (context: .)
- Test: `docker-compose config` — valid, `docker-compose up -d` — all healthy
```

---

## 4. Time Tracking Log

| Date | Task ID | Planned | Actual | Delta | Notes |
|------|---------|---------|--------|-------|-------|
| 2026-10-06 | 1.1-1.6 | 21ч | ~20ч | -1ч | Docs Phase 1 mostly done |
| 2026-10-06 | 1.7 | 2ч | — | — | This document |
| 2026-10-07 | 1.8 | 1ч | — | — | Review gate |
| 2026-10-13 | 2.1.1-2.1.3 | 8ч | — | — | Docker config start |
| 2026-10-14 | 2.1.4-2.1.6 | 9ч | — | — | Nginx, Ghost config, Makefile |
| 2026-10-15 | 2.1.7-2.1.8 | 4ч | — | — | Test run + fixes |
| 2026-10-16 | 2.2.1-2.2.3 | 7ч | — | — | Tunnel setup |
| 2026-10-17 | 2.2.4-2.2.5 | 3ч | — | — | Tunnel test + docs |
| 2026-10-20 | 2.3.1-2.3.6 | 8ч | — | — | Ghost setup |
| 2026-10-21 | 2.4.1-2.4.4 | 5ч | — | — | Repo + CI |
| 2026-10-22 | 2.4.5-2.4.7 | 4ч | — | — | CD + Security scanning |
| 2026-10-23 | 2.5.1-2.5.3 | 7ч | — | — | Backup, hardening, monitoring |
| 2026-10-24 | 2.5.4-2.5.7 | 9ч | — | — | Sync, content, retro, planning |

**Total Planned (4 weeks):** ~85 часов  
**Buffer (20%):** ~17 часов  
**Total with Buffer:** ~102 часа

---

## 5. Definitions of Done (DoD)

### Phase 1: Documentation
- [ ] Все 7 документов созданы в `/docs` и корне
- [ ] Mermaid диаграммы рендерятся на GitHub
- [ ] Нет неразрешённых TODO/TBD в документах
- [ ] Пользователь подтвердил: "Начинай Фазу 2"

### Phase 2: Infrastructure Alpha
- [ ] `make dev` поднимает стек < 3 мин, все healthy
- [ ] `https://chemgraph.ru` — 200 OK, SSL Labs A+, HSTS preload
- [ ] Ghost Admin доступен, Owner создан, тестовый пост публикуется
- [ ] Email отправляется (тестовый newsletter приходит)
- [ ] CI pipeline: lint + test + build + trivy + codeql = PASS на main
- [ ] Docker образ в GHCR, теги: `latest`, `sha-<commit>`
- [ ] `make backup` → `make restore` работает (данные сохраняются)
- [ ] Uptime Kuma мониторит: HTTP, SSL expiry, DNS, Tunnel health
- [ ] Secrets в Docker Secrets / 1Password, НИКОГДА не в git
- [ ] DR runbook пройден (tabletop), RTO < 2ч подтверждён

### Phase 3: Beta (планируемо)
- [ ] Custom theme deployed, Lighthouse > 90
- [ ] 10+ pillar статей опубликовано
- [ ] Daily digest автоматизирован (Newsletter Bridge)
- [ ] Email pipeline: welcome, digest, new post, unsubscribe
- [ ] Analytics: Umami/Plausible + Core Web Vitals
- [ ] Free → Paid membership flow работает (Stripe test mode)

---

## 6. Risk Register & Mitigations

| ID | Risk | Probability | Impact | Score | Mitigation | Owner | Status |
|----|------|-------------|--------|-------|------------|-------|--------|
| R1 | Домен `chemgraph.ru` не зарегистрирован / занят | Medium | High | 6 | Зарегистрировать ЗАРАНЕЕ (до 13.10) | You | ⏳ |
| R2 | Cloudflare Tunnel нестабилен на Windows (disconnects) | High | High | 9 | Systemd/Service авторестарт, monitoring alert, fallback plan | You | 🔄 |
| R3 | Ghost MySQL migration issues (version mismatch) | Low | High | 4 | Pin MySQL 8.0, test restore weekly, read replica | You | ⏳ |
| R4 | SMTP доставляемость (spam folder) | Medium | Medium | 4 | SPF/DKIM/DMARC, warm-up, Mailgun dedicated IP | You | ⏳ |
| R5 | LLM API costs превышают бюджет | Medium | Medium | 4 | Hard limits в коде, кэширование, локальные модели (Ollama) | You | ⏳ |
| R6 | Время на контент > ожиданий (burnout) | High | Medium | 6 | Реалистичный календарь, батчинг, AI-ассистент для drafts | You | 🔄 |
| R7 | Взлом / утечка секретов | Low | Critical | 5 | Secrets scanning, rotation, least privilege, 2FA везде | You | 🔄 |
| R8 | Cloudflare блокировка в РФ | Low | Critical | 5 | Зарезервировать домен у ру регистратора, план Б: Yandex Cloud | You | ⏳ |

**Risk Score = Probability (1-3) × Impact (1-3); High > 6**

---

## 7. Communication & Cadence

| Ceremony | Frequency | Duration | Participants | Artifacts |
|----------|-----------|----------|--------------|-----------|
| **Daily Standup** (async) | Daily | 5 min | You | Update in this doc (Status column) |
| **Weekly Review** | Friday 17:00 | 30 min | You | Updated WBS, blockers, next week plan |
| **Phase Gate** | End of Phase | 60 min | You | Demo, retrospective, go/no-go decision |
| **Monthly Retro** | Last Friday | 90 min | You | Metrics review, process improvements |

---

## 8. Budget Tracking (Monthly)

| Category | Month 1 (Oct) | Month 2 (Nov) | Month 3 (Dec) | Notes |
|----------|---------------|---------------|---------------|-------|
| Domain `chemgraph.ru` | ~$10 | — | — | Yearly |
| Cloudflare (Free) | $0 | $0 | $0 | Pro $20 if needed |
| VPS (Phase 4) | — | — | ~$20 | Selectel/Timeweb |
| Email (Mailgun/Brevo) | $0 (free) | $0-15 | $15-35 | Scale with subscribers |
| LLM API (OpenRouter) | $0 | $10-20 | $20-50 | Based on digest volume |
| Sentry (Free) | $0 | $0 | $0 | Team $26 if needed |
| **Total/Month** | **~$10** | **~$10-35** | **~$35-105** | |

---

## 9. Next Actions (Immediate)

| Priority | Action | Owner | Due |
|----------|--------|-------|-----|
| 🔴 **P0** | Зарегистрировать `chemgraph.ru` (если ещё нет) | You | ASAP |
| 🔴 **P0** | Создать Cloudflare аккаунт, добавить домен | You | ASAP |
| 🔴 **P0** | Выбрать SMTP провайдер (Yandex/Mailgun/Brevo), получить credentials | You | До 13.10 |
| 🟡 **P1** | Завершить `PROJECT-PLAN.md` (этот документ) | You | 06.10 |
| 🟡 **P1** | Review Gate: прочитать все 7 docs, подтвердить Фазу 2 | You | 10.10 |
| 🟢 **P2** | Подготовить SSH ключ для GitHub Actions deploy | You | До 20.10 |
| 🟢 **P2** | Создать 1Password/Vault vault для секретов | You | До 16.10 |

---

## 10. Sign-off

> **Phase 1 Complete Criteria Met:**
> - [ ] README.md ✅
> - [ ] ARCHITECTURE.md ✅
> - [ ] ROADMAP.md ✅
> - [ ] CONTENT-STRATEGY.md ✅
> - [ ] DEPLOYMENT.md ✅
> - [ ] SECURITY.md ✅
> - [ ] PROJECT-PLAN.md 🔄 (this doc)
> - [ ] User Approval: "Начинай Фазу 2" ⏳

---

*Обновляйте этот документ еженедельно (пятница). Коммитьте изменения в git для истории планирования.*