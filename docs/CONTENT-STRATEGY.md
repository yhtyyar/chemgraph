# Content Strategy: Chemgraph

> **Версия:** 1.0  
> **Статус:** 🟡 Черновик — требует ревью и утверждения  
> **Обновлено:** 2026-10-06

---

## 1. Миссия и позиционирование

**Chemgraph** — авторитетный источник знаний на стыке химии, фармацевтики и AI/ML для русскоязычного профессионального сообщества.

### Ценностное предложение (Value Proposition)

| Для кого | Проблема | Решение Chemgraph |
|----------|----------|-------------------|
| **Химики / фармацевты** | AI хайп, непонятно как применить на практике | Разборы статей с экспертной оценкой, код, датасеты, reproducibility |
| **ML-инженеры** | Доменные знания химии сложны, нет качественных датасетов | Туториалы по GNN/молекулярным графам, бенчмарки, best practices |
| **Исследователи / студенты** | Информационный шум, сложно отследить SOTA | Курируемые дайджесты (arXiv, PubMed, ChemRxiv), тренды, career advice |
| **Индустрия (R&D, регуляторика)** | Медленная адаптация AI, риски compliance | Кейсы внедрения, разбор FDA/EMA гайдлайнов по AI, риск-менеджмент |

### Тон голоса (Tone of Voice)

- **Экспертный, но доступный** — не упрощаем до поп-науки, объясняем термины
- **Эвidence-based** — ссылки на первоисточники, DOI, код, данные
- **Критический** — не копируем пресс-релизы, указываем ограничения методов
- **Практичный** — "как воспроизвести", "где взять данные", "какие ловушки"
- **На русском** — термины на английском в скобках при первом упоминании

---

## 2. Таксономия тегов (Tag Taxonomy)

### 2.1 Primary Tags (Обязательные — каждый пост должен иметь 1-2)

| Тег | Описание | Примеры контента | Цвет (Ghost) |
|-----|----------|------------------|--------------|
| `#ai-ml` | Общие ML методы, не специфичные для химии | Transformers, MLOps, evaluation | `#6366f1` (indigo) |
| `#cheminformatics` | Хемоинформатика, дескрипторы, фингерпринты | RDKit, Morgan FP, similarity search | `#059669` (emerald) |
| `#gnn` | Graph Neural Networks для молекул | MPNN, GAT, Graphormer, DGL/PyG | `#dc2626` (red) |
| `#drug-discovery` | Drug discovery pipeline | Virtual screening, hit-to-lead, ADMET | `#ea580c` (orange) |
| `#generative-chemistry` | Генеративные модели молекул | VAE, GAN, Diffusion, REINVENT, MolGPT | `#9333ea` (purple) |
| `#pharma-regulatory` | Регуляторика, фармакопея, CMC | FDA AI/ML guidance, EMA reflection paper, ICH | `#0891b2` (cyan) |
| `#llm-science` | LLM в научной работе | Literature review automation, lab automation, agents | `#7c2d12` (amber) |
| `#industry-case` | Индустриальные кейсы, interviews | Pharma R&D adoption, startup stories | `#166534` (green) |

### 2.2 Secondary Tags (Дополнительные — 2-5 на пост)

| Категория | Теги |
|-----------|------|
| **Методология** | `#benchmark`, `#reproducibility`, `#interpretability`, `#uncertainty-quantification`, `#active-learning`, `#transfer-learning` |
| **Данные** | `#datasets`, `#pubchem`, `#chembl`, `#zinc`, `#pdb`, `#bindingdb`, `#tdc` |
| **Приложения** | `#admet`, `#toxicity`, `#solubility`, `#protein-ligand`, `#retrosynthesis`, `#reaction-prediction`, `#materials-science` |
| **Инструменты** | `#rdkit`, `#pytorch-geometric`, `#dgl`, `#deepchem`, `#openfold`, `#alphafold`, `#molstar` |
| **Регуляторика** | `#fda`, `#ema`, `#ich`, `#gmp`, `#validation`, `#explainability`, `#bias` |
| **Формат** | `#review`, `#tutorial`, `#digest`, `#interview`, `#opinion`, `#paper-breakdown`, `#code-along` |
| **Язык** | `#ru`, `#en` (для билингва) |
| **Уровень** | `#beginner`, `#intermediate`, `#advanced` |

### 2.3 Tag Hierarchy (Ghost Internal Tags)

```
#type/review          → Формат: обзор статьи
#type/tutorial        → Формат: пошаговое руководство
#type/digest          → Формат: дайджест новостей
#type/interview       → Формат: интервью
#type/paper-breakdown → Формат: разбор одной статьи
#type/code-along      → Формат: код с комментариями

#series/ai-in-chem    → Серия: AI в химии (hub)
#series/drug-disc     → Серия: Drug Discovery
#series/pharma-ai     → Серия: Pharma + AI
#series/ml-fundamentals → Серия: ML основы для химиков

#status/evergreen     → Evergreen контент (обновляется)
#status/news          → Новостной контент (устаревает)
#status/draft         → Черновик (не для публикации)

#audience/chemists    → Для химиков
#audience/ml-engineers → Для ML инженеров
#audience/students    → Для студентов
#audience/managers    → Для руководителей R&D
```

### 2.4 Hub Pages (Custom Routes)

| Hub URL | Primary Tag | Описание |
|---------|-------------|----------|
| `/ai-in-chemistry` | `#ai-ml` + `#cheminformatics` | Введение в ML для химиков, фндментальные статьи |
| `/drug-discovery-ai` | `#drug-discovery` + `#gnn` | Pipeline от hit finding до clinical candidate |
| `/generative-chemistry` | `#generative-chemistry` | Генеративные модели, molecular design |
| `/pharma-ai-regulatory` | `#pharma-regulatory` | FDA/EMA guidance, compliance, validation |
| `/llm-for-science` | `#llm-science` | LLM в литературе, лабах, автоматизация |
| `/industry-insights` | `#industry-case` | Кейсы, интервью, тренды рынка |
| `/methods-benchmarks` | `#benchmark` + `#reproducibility` | Методология, бенчмарки, best practices |
| `/learning-path` | `#beginner` | Курированный путь обучения (курс) |

---

## 3. Типы контента (Content Types)

### 3.1 Paper Breakdown (Разбор статьи) — **Core Format**

**Частота:** 2-3 в неделю  
**Длина:** 2500-4000 слов  
**Структура:**
```
1. TL;DR (3 bullets: проблема, метод, ключевой результат)
2. Контекст: почему это важно (1-2 абзаца)
3. Методология: архитектура, данные, обучение (с схемами/диаграммами)
4. Результаты: таблицы, графики, сравнение с baseline
5. Критический разбор: ограничения, bias, reproducibility concerns
6. Практические выводы: как применить / что взять в работу
7. Ссылки: DOI, GitHub, данные, демо
8. Теги: primary + secondary + format/paper-breakdown
```

**Примеры:** "EquiBind: SE(3)-equivariant binding pose prediction", "Graphormer: Transformer for Molecular Graphs"

### 3.2 Tutorial / Code-Along (Практическое руководство)

**Частота:** 1 в неделю  
**Длина:** 3000-5000 слов + код  
**Структура:**
```
1. Цель: что построим к концу
2. Prerequisites: окружение, данные, знания
3. Пошаговая реализация (кодовые блоки с комментариями)
4. Типичные ошибки и как их избежать
5. Расширения: идеи для экспериментов
6. Репозиторий: GitHub/Colab link
7. Теги: primary + format/tutorial или format/code-along
```

**Примеры:** "Fine-tuning ChemBERTa на своих данных", "Building GNN for solubility prediction с PyG"

### 3.3 Weekly Digest (Еженедельный дайджест) — **Автоматизированный**

**Частота:** Еженедельно (понедельник 09:00 МСК)  
**Источники:** arXiv (cs.LG, physics.chem-ph, q-bio.QM), PubMed, ChemRxiv, FDA/EMA news, ключевые блоги  
**Структура:**
```
1. Топ-5 статей недели (с 1-стр суммаризацией LLM)
2. Важные новости инфраструктуры (релизы библиотек, датасеты)
3. Регуляторные апдейты (FDA/EMA guidance, публичные консультации)
4. Индустрия: финансирование, M&A, партнерства
5. Подборка инструментов / репозиториев недели
6. One-liner: "Цитата недели" от эксперта
```

**Техническая реализация:** Python service (Фаза 3.3) → Ghost draft → scheduled publish

### 3.4 Deep Dive / Review (Глубокий обзор темы)

**Частота:** 1 в 2 недели  
**Длина:** 5000-8000 слов  
**Структура:**
```
1. Executive Summary (для занятых)
2. Исторический контекст / эволюция подходов
3. Таксономия методов (с таблицей сравнения)
4. Ключевые работы (annotated bibliography)
5. Open problems & future directions
6. Practical checklist для практиков
7. Теги: primary + format/review + status/evergreen
```

**Примеры:** "Molecular Property Prediction: 2024 Landscape", "FDA AI/ML Guidance: What Pharma Needs to Know"

### 3.5 Interview / Expert Take (Интервью / Экспертное мнение)

**Частота:** 1 в месяц  
**Формат:** Текст + аудио (опционально)  
**Структура:**
```
1. Бэкграунд гостя
2. 5-7 ключевых вопросов (подготовлены заранее)
3. Практические советы аудитории
4. Контакты гостя
5. Теги: primary + format/interview + audience/*
```

### 3.6 Opinion / Editorial (Мнение / Эдиториал)

**Частота:** По мере необходимости  
**Длина:** 1500-2500 слов  
**Тема:** Контрверсы, хайп-циклы, этика, funding landscape  
**Политика:** Чётко помечается как `#opinion`, разделено от factual контента

---

## 4. Editorial Policy (Редакционная политика)

### 4.1 Standards of Evidence

| Утверждение | Требуемое доказательство |
|-------------|-------------------------|
| "Модель SOTA на задаче X" | Ссылка на бенчмарк (TDC, MoleculeNet, OGB) + версия метрики |
| "Метод работает лучше человека" | Статистическая значимость, confidence intervals, внешняя валидация |
| "Компания Y использует подход Z" | Публичный источник (блог, патен, конференция, интервью) |
| "Регулятор требует..." | Номер гайдлайна, раздел, дата публикации |

**Запрещено:** Неподтверждённые заявки из пресс-релизов, маркетинговые обещания без технических деталей.

### 4.2 Reproducibility Requirements

Для всех технических статей (tutorial, paper-breakdown с кодом):
- ✅ Ссылка на GitHub/Colab с working кодом
- ✅ Указаны версии зависимостей (requirements.txt / environment.yml)
- ✅ Данные: открытые (с DOI) или синтетические с генератором
- ✅ Hardware requirements (GPU, RAM, время обучения)
- ⚠️ Если код закрыт — явное замечание "Code not available"

### 4.3 Conflict of Interest & Disclosure

- Авторы обязаны раскрывать: affiliation, funding sources, equity в упомянутых компаниях
- Спонсируемый контент: **категорически нет** (только editorial independence)
- Affiliate links: только к открытым инструментам/курсам, с дисклеймером

### 4.4 Correction & Update Policy

| Тип контента | Частота обновления | Процесс |
|--------------|-------------------|---------|
| Evergreen (reviews, tutorials) | Раз в 6 месяцев | PR в репо → review → republishing с changelog |
| Paper breakdowns | При выходе camera-ready / rebuttal | Addendum в начале статьи |
| Digests | Не обновляются | Архивные версии доступны |
| Regulatory guides | При выходе новых версий гайдлайнов | Новая версия с версионированием v1.0, v1.1 |

**Changelog формат:** В конце статьи: `Updated YYYY-MM-DD: added section on X; fixed typo in Table 2`

### 4.5 Language & Localization

- **Основной язык:** Русский (ru)
- **Английский (en):** Перевод ключевых evergreen статей (после 10k views)
- **Терминология:** Английский термин в скобках при первом упоминании: "графовые нейронные сети (Graph Neural Networks, GNN)"
- **Глоссарий:** Поддерживаемый в `/glossary/` (Ghost page), связываемый через tooltip

---

## 5. Content Calendar (Примерный план на Q4 2026)

| Неделя | Paper Breakdown | Tutorial | Deep Dive | Digest | Special |
|--------|-----------------|----------|-----------|--------|---------|
| 42 (Oct 14) | Graphormer (Ying et al.) | RDKit basics для ML | — | #1 | Launch announcement |
| 43 | EquiBind / DiffDock | PyG: molecular GNN | — | #2 | — |
| 44 | MolCLR / 3D Infomax | Fine-tuning ChemBERTa | Molecular SSL Landscape | #3 | — |
| 45 | Retrosynthesis (Retro*) | Reaction prediction | — | #4 | Interview: Pharma AI lead |
| 46 | FDA AI/ML Guidance 2024 | — | FDA Guidance Deep Dive | #5 | — |
| 47 | AlphaFold 3 / Boltz-1 | Protein-ligand docking | — | #6 | — |
| 48 | Generative: MolDiff / DiffSBDD | Diffusion для молекул | Generative Chem 2024 | #7 | — |
| 49 | ADMET benchmarks (TDC) | ADMET modeling tutorial | — | #8 | Year in Review |
| 50 | Best of 2024: Top 10 papers | — | Annual Review | #9 | — |

---

## 6. Distribution & Growth

### 6.1 Owned Channels

| Channel | Частота | Контент | KPI |
|---------|---------|---------|-----|
| **Ghost Site (SEO)** | Continuous | Все статьи | Organic traffic, dwell time |
| **Email Newsletter** | Weekly (Digest) + Per post | Digest + new post alerts | Open rate > 25%, CTR > 3% |
| **RSS / JSON Feed** | Auto | Все публикации | Subscribers count |
| **Telegram Channel** | Daily (auto-crosspost) | Digest items + announcements | Subscribers, views/post |

### 6.2 Earned / Shared

| Channel | Стратегия |
|---------|-----------|
| **Habr / VC.ru** | Репост лучших статей с canonical link (партнёрство) |
| **LinkedIn** | Expert takes, industry insights — персональный бранд автора |
| **Twitter/X** | Thread-разборы статей, визуальные abstracts |
| **Reddit** | r/MachineLearning, r/Chemistry, r/DrugDiscovery — value-first |
| **Academic** | Представление на семинарах, лекциях, летних школах |

### 6.3 SEO Strategy

- **Target keywords:** "GNN химия", "drug discovery AI", "молекулярные графы обучение", "FDA AI guidance русском"
- **Content clusters:** Hub pages + spoke articles (topic clusters)
- **Technical SEO:** JSON-LD Article/BlogPosting, BreadcrumbList, Organization, FAQPage
- **Core Web Vitals:** LCP < 2.5s, CLS < 0.1, INP < 200ms
- **Internationalization:** hreflang ru/en для переведённых статей

---

## 7. Content Operations (Workflow)

### 7.1 Production Workflow

```mermaid
flowchart LR
    IDEA[Идея / Тема] --> PITCH[Pitch в Notion/GH Issues]
    PITCH --> ASSIGN[Assign автору / самоисполнение]
    ASSIGN --> RESEARCH[Research: papers, code, data]
    RESEARCH --> DRAFT[Draft в Ghost Editor]
    DRAFT --> REVIEW[Expert Review / Self-edit]
    REVIEW --> SEO[SEO enrichment: meta, schema, links]
    SEO --> PUBLISH[Publish / Schedule]
    PUBLISH --> DISTRIBUTE[Cross-post: Email, TG, Social]
    DISTRIBUTE --> ANALYZE[Analytics review (7d, 30d)]
    ANALYZE --> UPDATE[Update evergreen если нужно]
```

### 7.2 Roles & Responsibilities

| Role | Responsibilities | Time Commitment |
|------|------------------|-----------------|
| **Editor-in-Chief** (Owner) | Strategy, calendar, final edit, partnerships | 10h/week |
| **Technical Writer** | Tutorials, paper breakdowns, code verification | 15h/week |
| **Domain Expert** (Chem/Pharma) | Review accuracy, suggest topics, interviews | 5h/week |
| **ML Engineer** | Code reviews, benchmark reproduction, tools | 5h/week |
| **Automation** (Newsletter Bridge) | Daily digest generation, scheduling | 0h (automated) |

### 7.3 Quality Checklist (Pre-Publish)

- [ ] Fact-check: все утверждения имеют источник (DOI, URL, doc number)
- [ ] Code: запускается, воспроизводит результаты (если применимо)
- [ ] SEO: meta title < 60 chars, meta description < 160 chars, JSON-LD валиден
- [ ] Images: alt text, WebP, оптимизированы, feature image 1200×630
- [ ] Tags: 1-2 primary, 2-5 secondary, format, audience, series
- [ ] Links: внутренние (хотя бы 2), внешние (DOI, GitHub, датасеты)
- [ ] Disclosure: COI statement если применимо
- [ ] Accessibility: headings hierarchy, contrast, link text descriptive
- [ ] Legal: no copyrighted images/text без лицензии, attribution где нужно

---

## 8. Metrics & Success Criteria

### 8.1 Content Metrics (Per Article)

| Metric | Target (3 months) | Target (12 months) |
|--------|-------------------|-------------------|
| Organic sessions (30d) | > 500 | > 3000 |
| Avg. time on page | > 4 min | > 6 min |
| Scroll depth | > 60% | > 75% |
| Newsletter CTR | > 3% | > 5% |
| Social shares | > 20 | > 100 |
| Backlinks (referring domains) | > 5 | > 30 |

### 8.2 Channel Metrics

| Channel | 3-month Target | 12-month Target |
|---------|----------------|-----------------|
| Email subscribers | 500 | 3000 |
| Telegram subscribers | 300 | 2000 |
| RSS subscribers | 100 | 500 |
| Organic keywords (top 100) | 50 | 300 |

### 8.3 Business Metrics (Phase 3+)

| Metric | Target |
|--------|--------|
| Free → Paid conversion | > 2% |
| Monthly Recurring Revenue | > $500 (Year 1) |
| Churn rate (paid) | < 5% monthly |
| Lifetime Value (LTV) | > $100 |

---

## 9. Tools & Stack

| Purpose | Tool | Cost |
|---------|------|------|
| CMS & Publishing | Ghost CMS | Self-hosted ($0) |
| Editorial Calendar | Notion / GitHub Projects | Free |
| Writing & Editing | Ghost Editor + Obsidian (local) | Free |
| Code Verification | Google Colab / Local GPU | Free / Cloud credits |
| LLM Summarization | OpenRouter (Claude 3.5 Sonnet) | ~$10-20/mo |
| Email | Mailgun / Brevo | Free tier → $15/mo |
| Analytics | Umami (self-hosted) + Plausible | $0 / $9/mo |
| SEO | Ahrefs / Semrush (тrial) + GSC | $0-100/mo |
| Social Scheduling | Buffer / Typefully (free tier) | $0 |
| Design | Figma (free) / Excalidraw | Free |

---

## 10. Legal & Compliance

- **Copyright:** Все оригинальный контент — CC BY-NC 4.0 (атрибуция, некоммерческое использование)
- **Third-party content:** Fair use для цитат (< 10% статьи), скриншотов фигур (с attribuцией)
- **Data:** Используем только открытые датасеты (CC0, CC BY, MIT) или собственные
- **Privacy:** Соответствие 152-ФЗ (РФ) + GDPR (если EU трафик) — см. `docs/SECURITY.md`
- **Disclaimer:** Медицинский/фармацевтический дисклеймер в футере каждой статьи про лекарства

---

## 11. Appendices

### A. Tag Creation Checklist (для админа Ghost)

```bash
# Primary tags (с цветом, описанием, feature image)
# Secondary tags (без цвета, только описание)
# Internal tags (префикс #type/, #series/, #status/, #audience/)
```

### B. Ghost Routes.yaml Template

```yaml
routes:
  collections:
    /:
      permalink: /{slug}/
      template: index
      filter: 'tag:-#status/draft'
  
  taxonomies:
    tag: /tag/{slug}/
    author: /author/{slug}/
  
  # Hub pages
  /ai-in-chemistry/:
    template: hub-ai-chemistry
    data: tag.ai-ml
    controller: hub-controller
  
  /drug-discovery-ai/:
    template: hub-drug-discovery
    data: tag.drug-discovery
    controller: hub-controller
  
  # ... остальные hubs
```

### C. JSON-LD Templates (для темы)

```json
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "{{title}}",
  "description": "{{excerpt}}",
  "image": "{{feature_image}}",
  "datePublished": "{{published_at}}",
  "dateModified": "{{updated_at}}",
  "author": {
    "@type": "Person",
    "name": "{{author.name}}",
    "url": "{{author.url}}"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Chemgraph",
    "logo": { "@type": "ImageObject", "url": "https://chemgraph.ru/logo.png" }
  },
  "mainEntityOfPage": "{{url}}"
}
```

---

*Документ живой — обновляется по мере эволюции контент-стратегии. Следующая ревизия: после первых 20 публикаций (Beta fase).*