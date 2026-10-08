# Makefile for Chemgraph
# =============================================================================
# Common commands for development, testing, backup, and deployment
# Usage: make <target>
# =============================================================================

# Variables
COMPOSE_FILE := docker-compose.yml
COMPOSE := docker compose -f $(COMPOSE_FILE)
PROJECT_NAME := chemgraph

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# =============================================================================
# HELP
# =============================================================================
.PHONY: help
help: ## Show this help message
	@echo "$(GREEN)Chemgraph - Development Commands$(NC)"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =============================================================================
# DEVELOPMENT
# =============================================================================
.PHONY: dev
dev: ## Start development stack (build + up)
	@echo "$(GREEN)Starting development stack...$(NC)"
	@$(COMPOSE) up -d --build --remove-orphans
	@echo "$(GREEN)Stack started!$(NC)"
	@echo "  Ghost Admin: http://localhost:2368/ghost"
	@echo "  Ghost Site:  http://localhost:2368"
	@echo "  Nginx Proxy: http://localhost"
	@make ps

.PHONY: up
up: ## Start existing containers
	@$(COMPOSE) up -d

.PHONY: down
down: ## Stop and remove containers
	@$(COMPOSE) down

.PHONY: restart
restart: ## Restart all services
	@$(COMPOSE) restart

.PHONY: pull
pull: ## Pull latest images
	@$(COMPOSE) pull

.PHONY: build
build: ## Build or rebuild services
	@$(COMPOSE) build --no-cache

.PHONY: ps
ps: ## Show container status
	@$(COMPOSE) ps

# =============================================================================
# LOGS
# =============================================================================
.PHONY: logs
logs: ## Follow all logs
	@$(COMPOSE) logs -f --tail=100

.PHONY: logs-ghost
logs-ghost: ## Follow Ghost logs
	@$(COMPOSE) logs -f --tail=100 ghost

.PHONY: logs-nginx
logs-nginx: ## Follow Nginx logs
	@$(COMPOSE) logs -f --tail=100 nginx

.PHONY: logs-mysql
logs-mysql: ## Follow MySQL logs
	@$(COMPOSE) logs -f --tail=100 mysql

.PHONY: logs-redis
logs-redis: ## Follow Redis logs
	@$(COMPOSE) logs -f --tail=100 redis

# =============================================================================
# SHELL ACCESS
# =============================================================================
.PHONY: shell-ghost
shell-ghost: ## Open bash in Ghost container
	@$(COMPOSE) exec ghost sh

.PHONY: shell-ghost-root
shell-ghost-root: ## Open bash in Ghost container as root
	@$(COMPOSE) exec -u root ghost sh

.PHONY: shell-mysql
shell-mysql: ## Open MySQL CLI
	@$(COMPOSE) exec mysql mysql -u ghost -p ghost

.PHONY: shell-mysql-root
shell-mysql-root: ## Open MySQL CLI as root
	@$(COMPOSE) exec mysql mysql -u root -p

.PHONY: shell-redis
shell-redis: ## Open Redis CLI
	@$(COMPOSE) exec redis redis-cli -a "$$REDIS_PASSWORD"

.PHONY: shell-nginx
shell-nginx: ## Open bash in Nginx container
	@$(COMPOSE) exec nginx sh

# =============================================================================
# DATABASE OPERATIONS
# =============================================================================
.PHONY: db-shell
db-shell: shell-mysql ## Alias for shell-mysql

.PHONY: db-dump
db-dump: ## Dump database to file (usage: make db-dump FILE=backup.sql)
	@if [ -z "$(FILE)" ]; then \
		FILE="backups/ghost_$$(date +%Y%m%d_%H%M%S).sql"; \
	fi
	@mkdir -p backups
	@echo "$(GREEN)Dumping database to $(FILE)...$(NC)"
	@$(COMPOSE) exec -T mysql mysqldump -u ghost -p"${MYSQL_PASSWORD}" ghost > $(FILE)
	@echo "$(GREEN)Done!$(NC)"

.PHONY: db-restore
db-restore: ## Restore database from file (usage: make db-restore FILE=backup.sql)
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)Error: FILE parameter required$(NC)"; \
		echo "Usage: make db-restore FILE=backups/ghost_20240101_120000.sql"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restoring database from $(FILE)...$(NC)"
	@$(COMPOSE) exec -T mysql mysql -u ghost -p"${MYSQL_PASSWORD}" ghost < $(FILE)
	@echo "$(GREEN)Done!$(NC)"

.PHONY: db-reset
db-reset: ## Reset database (DANGEROUS - destroys all data)
	@echo "$(RED)WARNING: This will destroy all data!$(NC)"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(COMPOSE) exec -T mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE ghost; CREATE DATABASE ghost CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"; \
		echo "$(GREEN)Database reset!$(NC)"; \
	else \
		echo "Cancelled."; \
	fi

# =============================================================================
# BACKUP & RESTORE
# =============================================================================
BACKUP_DIR := backups
BACKUP_NAME := chemgraph_$(shell date -u +"%Y%m%d_%H%M%S")
AGE_KEY_FILE := $(HOME)/.age/chemgraph.pub

.PHONY: backup
backup: ## Create full encrypted backup (DB + content + config)
	@echo "$(GREEN)Creating backup $(BACKUP_NAME)...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@echo "  -> Dumping MySQL..."
	@$(COMPOSE) exec -T mysql mysqldump -u ghost -p"${MYSQL_PASSWORD}" --single-transaction --routines --triggers --events ghost | gzip > $(BACKUP_DIR)/$(BACKUP_NAME)_mysql.sql.gz
	@echo "  -> Archiving Ghost content..."
	@docker run --rm -v $(PROJECT_NAME)_ghost_content:/source:ro -v $(PWD)/$(BACKUP_DIR):/dest alpine tar czf /dest/$(BACKUP_NAME)_content.tar.gz -C /source .
	@echo "  -> Archiving configs..."
	@tar czf $(BACKUP_DIR)/$(BACKUP_NAME)_config.tar.gz -C $(PWD) docker-compose.yml config/ .env.example 2>/dev/null || true
	@echo "  -> Combining and encrypting..."
	@tar czf - -C $(BACKUP_DIR) $(BACKUP_NAME)_mysql.sql.gz $(BACKUP_NAME)_content.tar.gz $(BACKUP_NAME)_config.tar.gz | age -r $(shell cat $(AGE_KEY_FILE) 2>/dev/null || echo "age1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqy9l8x") -e > $(BACKUP_DIR)/$(BACKUP_NAME).tar.gz.age
	@echo "  -> Cleaning up temporary files..."
	@rm -f $(BACKUP_DIR)/$(BACKUP_NAME)_mysql.sql.gz $(BACKUP_DIR)/$(BACKUP_NAME)_content.tar.gz $(BACKUP_DIR)/$(BACKUP_NAME)_config.tar.gz
	@echo "$(GREEN)Backup created: $(BACKUP_DIR)/$(BACKUP_NAME).tar.gz.age$(NC)"

.PHONY: backup-plain
backup-plain: ## Create unencrypted backup (for testing)
	@echo "$(GREEN)Creating plain backup $(BACKUP_NAME)...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@$(COMPOSE) exec -T mysql mysqldump -u ghost -p"${MYSQL_PASSWORD}" --single-transaction --routines --triggers --events ghost | gzip > $(BACKUP_DIR)/$(BACKUP_NAME)_mysql.sql.gz
	@docker run --rm -v $(PROJECT_NAME)_ghost_content:/source:ro -v $(PWD)/$(BACKUP_DIR):/dest alpine tar czf /dest/$(BACKUP_NAME)_content.tar.gz -C /source .
	@tar czf $(BACKUP_DIR)/$(BACKUP_NAME)_config.tar.gz -C $(PWD) docker-compose.yml config/ .env.example 2>/dev/null || true
	@tar czf $(BACKUP_DIR)/$(BACKUP_NAME).tar.gz -C $(BACKUP_DIR) $(BACKUP_NAME)_mysql.sql.gz $(BACKUP_NAME)_content.tar.gz $(BACKUP_NAME)_config.tar.gz
	@rm -f $(BACKUP_DIR)/$(BACKUP_NAME)_mysql.sql.gz $(BACKUP_DIR)/$(BACKUP_NAME)_content.tar.gz $(BACKUP_DIR)/$(BACKUP_NAME)_config.tar.gz
	@echo "$(GREEN)Backup created: $(BACKUP_DIR)/$(BACKUP_NAME).tar.gz$(NC)"

.PHONY: restore
restore: ## Restore from latest backup (usage: make restore [FILE=backup.tar.gz.age])
	@if [ -z "$(FILE)" ]; then \
		FILE=$$(ls -t $(BACKUP_DIR)/*.tar.gz.age 2>/dev/null | head -1); \
		if [ -z "$$FILE" ]; then \
			echo "$(RED)No backup found!$(NC)"; \
			exit 1; \
		fi; \
	fi
	@echo "$(YELLOW)Restoring from $(FILE)...$(NC)"
	@echo "$(RED)This will overwrite current data! Press Ctrl+C to cancel (5s)$(NC)"
	@sleep 5
	@mkdir -p /tmp/restore_$$
	@echo "  -> Decrypting..."
	@age -d -i $(HOME)/.age/chemgraph.key "$(FILE)" 2>/dev/null | tar xzf - -C /tmp/restore_$$ || (echo "$(RED)Decryption failed! Check age key.$(NC)" && exit 1)
	@echo "  -> Stopping Ghost..."
	@$(COMPOSE) stop ghost nginx
	@echo "  -> Restoring MySQL..."
	@gunzip -c /tmp/restore_$$/$(notdir $(FILE:.tar.gz.age=))_mysql.sql.gz | $(COMPOSE) exec -T mysql mysql -u ghost -p"${MYSQL_PASSWORD}" ghost
	@echo "  -> Restoring Ghost content..."
	@docker run --rm -v $(PROJECT_NAME)_ghost_content:/dest -v /tmp/restore_$$:/source alpine tar xzf /source/$(notdir $(FILE:.tar.gz.age=))_content.tar.gz -C /dest
	@echo "  -> Starting services..."
	@$(COMPOSE) up -d ghost nginx
	@echo "  -> Cleaning up..."
	@rm -rf /tmp/restore_$$
	@echo "$(GREEN)Restore completed!$(NC)"

.PHONY: list-backups
list-backups: ## List available backups
	@ls -lh $(BACKUP_DIR)/*.tar.gz.age 2>/dev/null || echo "No backups found"

# =============================================================================
# GHOST SPECIFIC
# =============================================================================
.PHONY: ghost-doctor
ghost-doctor: ## Run Ghost doctor inside container
	@$(COMPOSE) exec ghost ghost doctor

.PHONY: ghost-migrate
ghost-migrate: ## Run Ghost database migrations
	@$(COMPOSE) exec ghost ghost migrate

.PHONY: ghost-cache-clear
ghost-cache-clear: ## Clear Ghost cache
	@$(COMPOSE) exec ghost ghost cache clear

.PHONY: ghost-config
ghost-config: ## Show Ghost config
	@$(COMPOSE) exec ghost ghost config get

# =============================================================================
# CLEANUP
# =============================================================================
.PHONY: clean
clean: ## Remove containers, networks, volumes (DANGEROUS)
	@echo "$(RED)WARNING: This will destroy ALL data including database!$(NC)"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(COMPOSE) down -v --remove-orphans; \
		docker volume rm $(PROJECT_NAME)_mysql_data $(PROJECT_NAME)_redis_data $(PROJECT_NAME)_ghost_content 2>/dev/null || true; \
		echo "$(GREEN)Cleaned up!$(NC)"; \
	else \
		echo "Cancelled."; \
	fi

.PHONY: prune
prune: ## Docker system prune (remove unused images, networks, volumes)
	@docker system prune -af --volumes

# =============================================================================
# LINTING & TESTING
# =============================================================================
.PHONY: lint
lint: ## Run all linters
	@echo "$(GREEN)Running linters...$(NC)"
	@echo "  -> Dockerfile..."
	@hadolint Dockerfile.ghost || true
	@echo "  -> docker-compose..."
	@$(COMPOSE) config > /dev/null && echo "    OK" || echo "    FAILED"
	@echo "  -> JSON configs..."
	@python3 -m json.tool config/ghost/config.production.json > /dev/null && echo "    OK" || echo "    FAILED"
	@echo "  -> YAML..."
	@python3 -c "import yaml; yaml.safe_load(open('docker-compose.yml'))" && echo "    OK" || echo "    FAILED"
	@echo "$(GREEN)Linting complete!$(NC)"

.PHONY: test
test: ## Run tests (placeholder for future test suite)
	@echo "$(YELLOW)No tests configured yet$(NC)"

# =============================================================================
# SSL / CERTIFICATES (for production)
# =============================================================================
.PHONY: ssl-gen
ssl-gen: ## Generate self-signed cert for local HTTPS testing
	@mkdir -p config/ssl
	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout config/ssl/localhost.key \
		-out config/ssl/localhost.crt \
		-subj "/C=RU/ST=Moscow/L=Moscow/O=Chemgraph/CN=localhost"
	@echo "$(GREEN)Self-signed cert generated in config/ssl/$(NC)"

# =============================================================================
# UTILITIES
# =============================================================================
.PHONY: env
env: ## Show current environment (filtered)
	@$(COMPOSE) config --environment | grep -v PASSWORD | grep -v SECRET | grep -v KEY | sort

.PHONY: config
config: ## Show resolved docker-compose config
	@$(COMPOSE) config

.PHONY: version
version: ## Show versions
	@echo "Docker: $$(docker --version)"
	@echo "Docker Compose: $$(docker-compose --version)"
	@echo "Ghost: $$(grep GHOST_VERSION .env 2>/dev/null | cut -d= -f2 || echo 'from .env.example')"

.PHONY: health
health: ## Check health of all services
	@echo "$(GREEN)Checking service health...$(NC)"
	@$(COMPOSE) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# =============================================================================
# DEPLOYMENT (Production)
# =============================================================================
.PHONY: deploy-staging
deploy-staging: ## Deploy to staging (requires staging VPS configured)
	@echo "$(YELLOW)Deploy to staging not configured yet$(NC)"

.PHONY: deploy-prod
deploy-prod: ## Deploy to production (requires production VPS configured)
	@echo "$(YELLOW)Deploy to production not configured yet$(NC)"

# =============================================================================
# WINDOWS-SPECIFIC (PowerShell wrappers)
# =============================================================================
.PHONY: ps-dev
ps-dev: ## Start dev stack (PowerShell wrapper)
	@powershell -Command "docker-compose -f docker-compose.yml up -d --build"

.PHONY: ps-logs
ps-logs: ## Follow logs (PowerShell wrapper)
	@powershell -Command "docker-compose -f docker-compose.yml logs -f --tail=100"

.PHONY: ps-shell-ghost
ps-shell-ghost: ## Shell into Ghost (PowerShell wrapper)
	@powershell -Command "docker-compose -f docker-compose.yml exec ghost sh"