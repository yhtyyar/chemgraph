# Chemgraph

Научно-популярный портал и аналитическая платформа на стыке химии, фармацевтики и AI/ML.

## 🎯 Описание проекта

**Chemgraph** — профессиональный контент о том, как искусственный интеллект меняет химию и фармацевтику:
- **Хемоинформатика и молекулярные графы** (GNN, molecular property prediction)
- **Drug Discovery** (виртуальный скрининг, генерация молекул, ADMET)
- **Фармацевтическая регуляторика** (FDA, EMA, фармакопея, CMC)
- **LLM в науке** (автоматизация обзоров, извлечение знаний, lab automation)

**Целевая аудитория:** химики, фармацевты, ML-инженеры, студенты, исследователи (преимущественно русскоязычные).

## 🏗 Технологический стек

| Компонент | Технология | Примечание |
|-----------|------------|------------|
| CMS | Ghost CMS (self-hosted) | Latest stable, Node.js 18+ |
| Frontend (позже) | Astro + React | Headless режим через Content API |
| Backend Services | Python 3.11+ (FastAPI, Celery) | Микросервисы для ML/парсинга |
| Database | SQLite (dev) → MySQL 8/MariaDB (prod) | Ghost требует MySQL в продакшене |
| Cache/Queue | Redis | Celery broker, кэширование |
| Reverse Proxy | Nginx | SSL termination, rate limiting |
| Tunnel (Alpha) | Cloudflare Tunnel (cloudflared) | Бесплатный HTTPS, DDoS защита |
| Email | SMTP (Yandex/Mailgun/Brevo) | Transactional + newsletter |
| Media Storage | Local FS (dev) → Cloudflare R2 (prod) | 10 GB free tier |
| CI/CD | GitHub Actions | Lint, test, build, deploy |
| Observability | Sentry + Uptime Kuma | Errors + uptime monitoring |

## 📁 Структура репозитория

```
chemgraph/
├── README.md                 # Этот файл
├── PROJECT-PLAN.md           # WBS и временные оценки
├── Makefile                  # Типовые команды (dev, logs, backup, deploy)
├── docker-compose.yml        # Локальный стек (Ghost + MySQL + Redis + Nginx)
├── Dockerfile.ghost          # Multi-stage build для Ghost
├── .dockerignore
├── .env.example              # Шаблон переменных окружения
├── .gitignore
├── docs/
│   ├── ARCHITECTURE.md       # Диаграмма компонентов (Mermaid), data flow
│   ├── ROADMAP.md            # Фазы Alpha→Beta→Production с milestones
│   ├── CONTENT-STRATEGY.md   # Таксономия, типы контента, editorial policy
│   ├── DEPLOYMENT.md         # Пошаговая инструкция развёртывания
│   └── SECURITY.md           # Threat model, secrets, backup strategy
├── config/
│   ├── nginx.conf            # Nginx конфигурация
│   ├── cloudflared.yml       # Cloudflare Tunnel конфигурация
│   └── ghost/
│       └── config.production.json  # Ghost production config
├── scripts/
│   ├── setup-tunnel.ps1      # PowerShell: установка cloudflared (Windows 11)
│   ├── backup.sh             # Бэкап БД и медиа
│   ├── restore.sh            # Восстановление из бэкапа
│   └── migrate.sh            # Миграция данных между средами
├── services/                 # Python микросервисы (Фаза 3+)
│   ├── newsletter-bridge/
│   ├── seo-enrichment/
│   └── analytics/
└── themes/
    └── chemgraph-theme/      # Кастомная Ghost тема (Фаза 3)
```

## 🚀 Quick Start (Alpha — локально на Windows 11)

### Предварительные требования

- **Windows 11 Pro/Enterprise** (для WSL2)
- **WSL2** с Ubuntu 22.04+ (`wsl --install -d Ubuntu`)
- **Docker Desktop** (WSL2 backend) — [скачать](https://www.docker.com/products/docker-desktop/)
- **PowerShell 7+** (`winget install Microsoft.PowerShell`)
- **Git** (`winget install Git.Git`)
- **Cloudflare аккаунт** (для туннеля) — [регистрация](https://dash.cloudflare.com/sign-up)
- Домен `chemgraph.ru` (или поддомен для тестов)

### 1. Клонирование и настройка окружения

```powershell
# В PowerShell 7+
cd D:\Projects
git clone https://github.com/<your-org>/chemgraph.git
cd chemgraph

# Копируем пример env и редактируем
Copy-Item .env.example .env
notepad .env  # Заполните обязательные переменные
```

### 2. Запуск локального стека

```powershell
# Сборка и запуск всех сервисов
make dev

# Или вручную:
docker-compose up -d --build
```

Сервисы поднимутся на:
- **Ghost Admin:** http://localhost:2368/ghost
- **Ghost Public:** http://localhost:2368
- **MySQL:** localhost:3306
- **Redis:** localhost:6379
- **Nginx:** http://localhost:80

### 3. Настройка Cloudflare Tunnel (для публичного доступа)

```powershell
# Запуск скрипта настройки туннеля (требует админа)
.\scripts\setup-tunnel.ps1 -Domain "chemgraph.ru" -Email "your@email.com"
```

Скрипт:
1. Установит `cloudflared` через winget
2. Авторизует в Cloudflare
3. Создаст туннель и маршрут к `chemgraph.ru`
4. Установит как Windows Service (автозапуск)

После настройки сайт будет доступен по **https://chemgraph.ru** с автоматическим SSL от Cloudflare.

### 4. Первичная настройка Ghost

1. Откройте http://localhost:2368/ghost
2. Создайте админ-аккаунт (Owner)
3. Настройте: **Settings → General → Publication URL** = `https://chemgraph.ru`
4. Настройте Email (Settings → Email) — SMTP credentials из `.env`

## 🛠 Типовые команды (Makefile)

```bash
make dev          # Поднять dev-стек (build + up)
make down         # Остановить все контейнеры
make logs         # Показать логи (follow)
make shell-ghost  # Зайти в контейнер Ghost
make shell-db     # Зайти в MySQL CLI
make backup       # Бэкап БД + content/images
make restore      # Восстановить из последнего бэкапа
make clean        # Полная очистка (контейнеры + volumes + build cache)
make lint         # Линтинг (ruff, eslint, hadolint)
```

## 📋 Переменные окружения (.env)

Обязательные для запуска (см. `.env.example`):

```bash
# Ghost
GHOST_VERSION=5.100
NODE_ENV=development
GHOST_URL=https://chemgraph.ru
GHOST_ADMIN_URL=https://chemgraph.ru/ghost

# Database (MySQL для продакшена, SQLite для dev)
MYSQL_ROOT_PASSWORD=changeme
MYSQL_DATABASE=ghost
MYSQL_USER=ghost
MYSQL_PASSWORD=changeme

# Redis
REDIS_PASSWORD=changeme

# Email (SMTP)
SMTP_HOST=smtp.yandex.ru
SMTP_PORT=465
SMTP_USER=your@yandex.ru
SMTP_PASS=app-password
SMTP_FROM="Chemgraph <noreply@chemgraph.ru>"

# Cloudflare Tunnel
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoi...  # Получите после setup-tunnel.ps1

# Security
JWT_SECRET=generate-with-openssl-rand-base64-32
```

## 📚 Документация

| Документ | Описание |
|----------|----------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Архитектура системы, диаграммы компонентов, data flow |
| [ROADMAP.md](docs/ROADMAP.md) | План развития: Alpha → Beta → Production |
| [CONTENT-STRATEGY.md](docs/CONTENT-STRATEGY.md) | Таксономия тегов, типы контента, editorial policy |
| [DEPLOYMENT.md](docs/DEPLOYMENT.md) | Инструкции по развёртыванию локально и в продакшене |
| [SECURITY.md](docs/SECURITY.md) | Threat model, управление секретами, стратегия бэкапов |
| [PROJECT-PLAN.md](PROJECT-PLAN.md) | WBS с оценкой времени на ближайшие 4 недели |

## 🔒 Безопасность

- **Никогда не коммитьте `.env`** — в `.gitignore`
- Используйте `docker secrets` для продакшена
- Регулярно ротируйте JWT_SECRET и пароли БД
- Включите 2FA в Cloudflare и GitHub
- Настройте бэкапы (make backup) — храните в другом регионе/облаке

## 📄 Лицензия

MIT License — см. [LICENSE](LICENSE) (если open-source core).

---

**Статус:** 🟡 Фаза 1 — Документирование и планирование  
**Следующий шаг:** Создание `docs/ARCHITECTURE.md` с Mermaid-диаграммами