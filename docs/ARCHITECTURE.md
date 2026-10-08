# Архитектура Chemgraph

> **Статус:** Документ живой — обновляется при каждом архитектурном решении (ADR).
> **Формат:** Context → Decision → Consequences (ADR-style).

---

## 1. Контекст (Context)

Chemgraph — контентная платформа с требованиями:
- **Высокая доступность контента** — статьи должны открываться быстро, без зависимостей от внешних API
- **Безопасность** — защита от DDoS, инъекций, утечки данных подписчиков
- **Масштабируемость** — от локального alpha-теста до продакшн нагрузки (10k+ MAU)
- **Observability** — понимание здоровья системы без ручного логирования
- **Cost-efficiency** — старт на бесплатных/дешёвых ресурсах, плавное масштабирование

---

## 2. Общая диаграмма компонентов (Component Diagram)

```mermaid
graph TB
    subgraph "Client Layer"
        U[👤 Пользователь<br/>Browser]
        SE[🤖 Search Engines<br/>Crawlers]
        API_CLIENT[🔌 API Consumers<br/>Partners, ML pipelines]
    end

    subgraph "Edge / CDN / Security"
        CF[☁️ Cloudflare<br/>DNS, WAF, DDoS, SSL, Cache]
        CT[🚇 Cloudflare Tunnel<br/>cloudflared]
    end

    subgraph "Application Layer (Docker Compose / VPS)"
        NGINX[🌐 Nginx<br/>Reverse Proxy, Rate Limit, SSL Term]
        
        subgraph "Ghost CMS Cluster"
            GHOST1[👻 Ghost #1<br/>Node.js 18+]
            GHOST2[👻 Ghost #2<br/>Node.js 18+]
        end
        
        subgraph "Python Services (Phase 3+)"
            NEWS[📰 Newsletter Bridge<br/>FastAPI + Celery]
            SEO[🔍 SEO Enrichment<br/>FastAPI]
            ANALYTICS[📊 Analytics<br/>FastAPI + ClickHouse]
        end
    end

    subgraph "Data Layer"
        MYSQL[(🗄️ MySQL 8 / MariaDB<br/>Ghost Content + Members)]
        REDIS[(⚡ Redis 7<br/>Cache, Celery Broker, Sessions)]
        R2[(☁️ Cloudflare R2 / S3<br/>Media Assets)]
        MEILI[(🔎 MeiliSearch<br/>Full-text Search Phase 4)]
    end

    subgraph "Observability"
        SENTRY[🐛 Sentry<br/>Error Tracking]
        UPTIME[💚 Uptime Kuma<br/>Uptime Monitoring]
        GRAFANA[📈 Grafana + Prometheus<br/>Metrics Phase 4]
    end

    subgraph "CI/CD"
        GH_ACTIONS[⚙️ GitHub Actions<br/>Lint, Test, Build, Deploy]
        GHCR[📦 GHCR<br/>Docker Images]
    end

    %% Connections
    U --> CF
    SE --> CF
    API_CLIENT --> CF
    
    CF --> CT
    CT --> NGINX
    
    NGINX --> GHOST1
    NGINX --> GHOST2
    NGINX --> NEWS
    NGINX --> SEO
    NGINX --> ANALYTICS
    
    GHOST1 --> MYSQL
    GHOST2 --> MYSQL
    GHOST1 --> REDIS
    GHOST2 --> REDIS
    GHOST1 --> R2
    GHOST2 --> R2
    
    NEWS --> MYSQL
    NEWS --> REDIS
    SEO --> MYSQL
    ANALYTICS --> MYSQL
    ANALYTICS --> REDIS
    
    GHOST1 --> MEILI
    GHOST2 --> MEILI
    
    GHOST1 --> SENTRY
    GHOST2 --> SENTRY
    NEWS --> SENTRY
    SEO --> SENTRY
    ANALYTICS --> SENTRY
    
    NGINX --> UPTIME
    GHOST1 --> UPTIME
    
    GH_ACTIONS --> GHCR
    GH_ACTIONS --> CF
    GH_ACTIONS --> NGINX
```

---

## 3. Data Flow (Sequence Diagram: Публикация статьи)

```mermaid
sequenceDiagram
    participant Author as Автор/Редактор
    participant GhostAdmin as Ghost Admin UI
    participant GhostAPI as Ghost Content API
    participant MySQL as MySQL
    participant Redis as Redis Cache
    participant R2 as Cloudflare R2
    participant Cloudflare as Cloudflare CDN
    participant Reader as Читатель
    participant SearchEng as Search Engines

    Author->>GhostAdmin: Создаёт/редактирует пост
    GhostAdmin->>GhostAPI: POST /ghost/api/admin/posts/
    GhostAPI->>MySQL: INSERT INTO posts + tags + authors
    GhostAPI->>R2: Upload feature image (если есть)
    GhostAPI->>Redis: Invalidate cache для /, /tag/*, /author/*
    GhostAPI-->>GhostAdmin: 201 Created
    
    Note over GhostAdmin,Reader: Публикация (status: published)
    
    Reader->>Cloudflare: GET https://chemgraph.ru/post-slug/
    Cloudflare->>Cloudflare: Check cache (HTML cached 5min)
    alt Cache HIT
        Cloudflare-->>Reader: 200 OK (cached HTML)
    else Cache MISS
        Cloudflare->>GhostAPI: GET /ghost/api/content/posts/slug/post-slug/
        GhostAPI->>MySQL: SELECT post + relations
        GhostAPI->>Redis: Cache response (TTL 5min)
        GhostAPI-->>Cloudflare: 200 OK JSON
        Cloudflare->>Cloudflare: Render via Ghost theme (SSR)
        Cloudflare-->>Reader: 200 OK HTML
    end
    
    SearchEng->>Cloudflare: GET /sitemap.xml
    Cloudflare->>GhostAPI: GET /ghost/api/content/posts/?limit=1000
    GhostAPI->>MySQL: SELECT published posts
    GhostAPI-->>Cloudflare: 200 OK
    Cloudflare-->>SearchEng: 200 OK XML
```

---

## 4. Data Flow (Sequence Diagram: Newsletter Bridge — Парсинг arXiv)

```mermaid
sequenceDiagram
    participant Scheduler as Celery Beat<br/>(cron: 0 6 * * *)
    participant Newsletter as Newsletter Bridge<br/>FastAPI Service
    participant ArXiv as arXiv API
    participant PubMed as PubMed API
    participant LLM as LLM API<br/>(Claude/OpenRouter)
    participant Ghost as Ghost Admin API
    participant MySQL as MySQL
    participant Email as SMTP<br/>(Yandex/Mailgun)

    Scheduler->>Newsletter: Trigger task "daily-digest"
    Newsletter->>ArXiv: Search query: "chemistry AI drug discovery"
    Newsletter->>PubMed: Search query: "molecular graph neural network"
    ArXiv-->>Newsletter: 50 papers (XML)
    PubMed-->>Newsletter: 50 papers (XML)
    
    Newsletter->>Newsletter: Dedupe by DOI/arXiv ID
    Newsletter->>Newsletter: Filter by relevance score > 0.7
    Newsletter->>LLM: Batch summarize top 10 papers
    LLM-->>Newsletter: Structured summaries (JSON)
    
    Newsletter->>Ghost: Create draft post "Ежедневный дайджест YYYY-MM-DD"
    Ghost->>MySQL: INSERT draft post
    Ghost-->>Newsletter: Post ID
    
    Newsletter->>Email: Send newsletter to members (Mailgun API)
    Email-->>Newsletter: 202 Accepted
    
    Note over Newsletter,Ghost: Через 30 мин — автопубликация<br/>(Ghost scheduled publishing)
```

---

## 5. Deployment Architecture (Alpha vs Production)

### Alpha (Локально на Windows 11 + Cloudflare Tunnel)

```mermaid
graph LR
    subgraph "Windows 11 Host"
        WSL[WSL2 Ubuntu]
        DOCKER[Docker Desktop<br/>WSL2 Backend]
        
        subgraph "Docker Compose Stack"
            GHOST_A[Ghost:2368]
            MYSQL_A[MySQL:3306]
            REDIS_A[Redis:6379]
            NGINX_A[Nginx:80]
        end
        
        CF_TUNNEL[cloudflared<br/>Windows Service]
    end
    
    INTERNET[🌐 Internet] --> CF[☁️ Cloudflare Edge]
    CF --> CF_TUNNEL
    CF_TUNNEL --> NGINX_A
    NGINX_A --> GHOST_A
    GHOST_A --> MYSQL_A
    GHOST_A --> REDIS_A
```

**Характеристики Alpha:**
- Single-instance Ghost (нет HA)
- SQLite не поддерживается Ghost — обязателен MySQL даже в dev
- Cloudflare Tunnel даёт бесплатный HTTPS, DDoS защиту, скрывает домашний IP
- Бэкапы ручные (`make backup`) на локальный диск / сетевую папку

### Production (VPS + GitHub Actions Deploy)

```mermaid
graph TB
    subgraph "GitHub"
        REPO[📦 Private Repo<br/>chemgraph]
        ACTIONS[⚙️ GitHub Actions<br/>CI/CD Pipeline]
        GHCR[📦 GHCR<br/>ghcr.io/org/chemgraph/*]
    end
    
    subgraph "Cloudflare"
        CF_DNS[🌐 DNS: chemgraph.ru]
        CF_WAF[🛡️ WAF Rules]
        CF_R2[☁️ R2 Bucket<br/>media.chemgraph.ru]
    end
    
    subgraph "VPS (Selectel/Timeweb/Yandex Cloud)"
        subgraph "Docker Swarm / Compose"
            NGINX_P[Nginx:80/443<br/>SSL: Let's Encrypt/CF Origin Cert]
            
            subgraph "Ghost Cluster (2+ replicas)"
                GHOST_P1[Ghost #1]
                GHOST_P2[Ghost #2]
            end
            
            MYSQL_P[(MySQL 8<br/>Primary + Replica)]
            REDIS_P[(Redis Cluster<br/>Sentinel)]
            MEILI_P[MeiliSearch]
        end
        
        BACKUP_SRV[🗄️ Backup Server<br/>rsync + BorgBackup]
        MONITOR[📊 Uptime Kuma + Grafana]
    end
    
    REPO --> ACTIONS
    ACTIONS -->|Build & Push| GHCR
    ACTIONS -->|Deploy (SSH)| VPS
    ACTIONS -->|Purge Cache| CF
    
    USER[👤 Пользователь] --> CF_DNS
    CF_DNS --> CF_WAF
    CF_WAF --> NGINX_P
    NGINX_P --> GHOST_P1
    NGINX_P --> GHOST_P2
    GHOST_P1 --> MYSQL_P
    GHOST_P2 --> MYSQL_P
    GHOST_P1 --> REDIS_P
    GHOST_P2 --> REDIS_P
    GHOST_P1 --> CF_R2
    GHOST_P2 --> CF_R2
    GHOST_P1 --> MEILI_P
    GHOST_P2 --> MEILI_P
    
    MYSQL_P --> BACKUP_SRV
    CF_R2 --> BACKUP_SRV
    NGINX_P --> MONITOR
    GHOST_P1 --> MONITOR
```

---

## 6. Security Architecture (Threat Model)

```mermaid
graph TD
    subgraph "Threats"
        T1[DDoS Volumetric]
        T2[DDoS Application Layer]
        T3[SQL Injection]
        T4[XSS / CSRF]
        T5[Credential Stuffing]
        T6[Data Exfiltration]
        T7[Supply Chain Attack]
        T8[Secret Leakage]
    end
    
    subgraph "Mitigations"
        M1[Cloudflare WAF + Rate Limiting<br/>"Under Attack" mode]
        M2[Cloudflare Bot Fight Mode<br/>Turnstile on forms]
        M3[Parameterized Queries (Ghost ORM)<br/>No raw SQL in services]
        M4[CSP Headers (Nginx + Ghost)<br/>Subresource Integrity]
        M5[bcrypt + Rate Limit Login<br/>2FA for Admin/Members]
        M6[Encryption at Rest (MySQL TDE)<br/>Encryption in Transit (TLS 1.3)]
        M7[Dependabot + SCA (GitHub Actions)<br/>Signed images (cosign)]
        M8[.env + Docker Secrets<br/>No secrets in git/images]
    end
    
    T1 --> M1
    T2 --> M1
    T2 --> M2
    T3 --> M3
    T4 --> M4
    T5 --> M5
    T6 --> M6
    T7 --> M7
    T8 --> M8
```

---

## 7. Key Architectural Decisions (ADR Log)

### ADR-001: Ghost CMS как ядро платформы
- **Context:** Нужен профессиональный CMS с встроенными: memberships, newsletters, SEO, themes, API.
- **Decision:** Ghost (self-hosted) вместо WordPress/Strapi/Contentful.
- **Consequences:** 
  - ✅ Встроенные memberships, email newsletters, Stripe интеграция
  - ✅ Content API + Admin API для headless режима
  - ✅ Активное сообщество, регулярные релизы
  - ❌ Требует MySQL (не SQLite в продакшене)
  - ❌ Node.js стек — нужен отдельный Python для ML

### ADR-002: Cloudflare Tunnel для Alpha вместо VPS
- **Context:** Нужен публичный HTTPS для тестов без покупки VPS и настройки SSL.
- **Decision:** Cloudflare Tunnel (cloudflared) на Windows 11 хосте.
- **Consequences:**
  - ✅ Бесплатный HTTPS, DDoS защита, скрыт реальный IP
  - ✅ Работает за NAT/CGNAT, не нужен публичный IP
  - ❌ Зависимость от Cloudflare (vendor lock-in на уровне edge)
  - ❌ Cold start ~1-2 сек после простоя туннеля

### ADR-003: Docker Compose для локальной разработки
- **Context:** Нужен воспроизводимый стек: Ghost + MySQL + Redis + Nginx.
- **Decision:** docker-compose.yml с именованными volumes, healthchecks.
- **Consequences:**
  - ✅ `make dev` поднимает всё за 1 команду
  - ✅ Изоляция от хостовой ОС (WSL2)
  - ✅ Легкая миграция на VPS (тот же compose)
  - ❌ Windows filesystem performance для bind mounts (используем volumes)

### ADR-004: Python микросервисы отдельно от Ghost
- **Context:** ML/парсинг/аналитика не вписываются в Node.js архитектуру Ghost.
- **Decision:** Отдельные FastAPI сервисы, общающиеся с Ghost через Admin/Content API + прямая запись в MySQL (read-only replicas).
- **Consequences:**
  - ✅ Независимый деплой, скейлинг, стек
  - ✅ Python экосистема для ML (PyTorch, transformers, RDKit)
  - ❌ Сложнее транзакционность (eventual consistency)
  - ❌ Дублирование некоторых моделей (DRY через shared lib)

### ADR-005: Cloudflare R2 для медиа в продакшене
- **Context:** Ghost хранит изображения локально — не масштабируется, нет CDN.
- **Decision:** Ghost storage adapter → Cloudflare R2 (S3-compatible, 10GB free).
- **Consequences:**
  - ✅ Бесплатный egress, глобальный CDN через Cloudflare
  - ✅ S3 API — стандарт, легко мигрировать на S3/MinIO
  - ❌ Ghost не имеет нативного R2 адаптера — нужен кастомный или прокси

---

## 8. Network Ports & Connectivity

| Service | Internal Port | External (Alpha) | External (Prod) | Notes |
|---------|---------------|------------------|-----------------|-------|
| Nginx (HTTP) | 80 | localhost:80 | 80 (redirect→443) | Rate limiting, SSL termination |
| Nginx (HTTPS) | 443 | — | 443 | TLS 1.3, HSTS |
| Ghost | 2368 | localhost:2368 | Internal only | Binding 127.0.0.1 в prod |
| MySQL | 3306 | localhost:3306 | Internal only | Binding 127.0.0.1, SSL required |
| Redis | 6379 | localhost:6379 | Internal only | Binding 127.0.0.1, AUTH required |
| cloudflared | — | Windows Service | — | Outbound only, no inbound ports |
| MeiliSearch | 7700 | — | Internal only | Phase 4, master key required |
| Uptime Kuma | 3001 | — | VPN/SSH tunnel | Internal monitoring |
| Grafana | 3000 | — | VPN/SSH tunnel | Phase 4 |

---

## 9. Data Models (High-Level ERD)

```mermaid
erDiagram
    GHOST_POSTS ||--o{ GHOST_POSTS_TAGS : has
    GHOST_POSTS ||--o{ GHOST_POSTS_AUTHORS : written_by
    GHOST_TAGS ||--o{ GHOST_POSTS_TAGS : tagged_in
    GHOST_USERS ||--o{ GHOST_POSTS_AUTHORS : authored
    GHOST_MEMBERS ||--o{ GHOST_MEMBERS_STRIPE_CUSTOMERS : billing
    GHOST_NEWSLETTERS ||--o{ GHOST_EMAIL_RECIPIENTS : sent_to
    
    GHOST_POSTS {
        uuid id PK
        string title
        string slug UK
        text markdown
        text html
        string feature_image
        enum status "draft,published,scheduled"
        datetime published_at
        datetime created_at
        datetime updated_at
        json meta_title
        json meta_description
        json og_image
        json twitter_image
        string canonical_url
        uuid author_id FK
    }
    
    GHOST_TAGS {
        uuid id PK
        string name
        string slug UK
        string description
        string feature_image
        json meta_title
        json meta_description
        boolean visibility "public,internal"
    }
    
    GHOST_USERS {
        uuid id PK
        string name
        string email UK
        string password_hash
        enum role "owner,admin,editor,author"
        datetime last_login
        boolean two_factor_enabled
    }
    
    GHOST_MEMBERS {
        uuid id PK
        string email UK
        string name
        enum status "free,paid,complimentary"
        uuid stripe_customer_id
        datetime subscribed_at
        json labels
        json note
    }
```

---

## 10. Backup & Recovery Strategy

```mermaid
graph LR
    subgraph "Backup Sources"
        MYSQL[(MySQL Data)]
        REDIS[(Redis Dump)]
        GHOST_CONTENT[Ghost content/images]
        CONFIG[Config files<br/>.env, docker-compose, nginx]
    end
    
    subgraph "Backup Process (Daily 03:00 UTC)"
        SCRIPT[backup.sh<br/>mysqldump + rsync + tar]
        ENCRYPT[age/gpg<br/>Encryption]
    end
    
    subgraph "Storage Targets (3-2-1 Rule)"
        LOCAL[Local Disk<br/>D:\Backups\chemgraph]
        REMOTE[Cloudflare R2<br/>s3://chemgraph-backups]
        OFFSITE[Offsite<br/>Another region/VPS]
    end
    
    MYSQL --> SCRIPT
    REDIS --> SCRIPT
    GHOST_CONTENT --> SCRIPT
    CONFIG --> SCRIPT
    SCRIPT --> ENCRYPT
    ENCRYPT --> LOCAL
    ENCRYPT --> REMOTE
    ENCRYPT --> OFFSITE
    
    subgraph "Recovery"
        RESTORE[restore.sh<br/>Decrypt → mysqldump restore → rsync]
        VERIFY[Test restore<br/>Monthly drill]
    end
    
    LOCAL --> RESTORE
    REMOTE --> RESTORE
    OFFSITE --> RESTORE
    RESTORE --> VERIFY
```

**RPO:** 24 часа (дневной бэкап)  
**RTO:** < 2 часа (автоматизированный restore скрипт)  
**Retention:** Daily × 7, Weekly × 4, Monthly × 12

---

## 11. Scaling Triggers (When to Scale)

| Metric | Threshold | Action |
|--------|-----------|--------|
| Ghost CPU > 70% 5min | Horizontal: add Ghost replica |
| MySQL connections > 80% max | Vertical: larger instance / read replica |
| Redis memory > 80% | Vertical: more RAM / Redis Cluster |
| Nginx 5xx > 1%/5min | Alert → investigate → scale Ghost |
| Disk usage > 80% | Cleanup / expand volume / move media to R2 |
| Tunnel latency p99 > 2s | Check cloudflared health / upgrade plan |

---

## 12. Appendices

### A. Useful Commands

```bash
# Проверить здоровье стека
docker-compose ps
docker-compose exec ghost ghost doctor

# Логи Ghost
docker-compose logs -f ghost | jq -R 'fromjson? | select(.level=="error")'

# MySQL инспекция
docker-compose exec mysql mysql -u ghost -p ghost -e "SHOW TABLE STATUS;"

# Redis инспекция
docker-compose exec redis redis-cli INFO memory

# Бэкап вручную
make backup

# Обновление Ghost версии
# 1. Обновить GHOST_VERSION в .env
# 2. make dev (rebuild)
# 3. ghost doctor в контейнере
```

### B. Links

- [Ghost Architecture](https://ghost.org/docs/architecture/)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Docker Compose Spec](https://docs.docker.com/compose/compose-file/)
- [MySQL 8 Reference](https://dev.mysql.com/doc/refman/8.0/en/)