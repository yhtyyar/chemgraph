#!/usr/bin/env bash
# migrate.sh - Migrate data between environments (local -> staging -> prod)
# =============================================================================
# Usage: ./migrate.sh SOURCE_ENV TARGET_ENV
# Environments: local, staging, prod
# =============================================================================

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "[$(date -u +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "${GREEN}✓${NC} $*"; }
warning() { log "${YELLOW}⚠${NC} $*"; }
error() { log "${RED}✗${NC} $*"; }

if [[ $# -lt 2 ]]; then
    error "Usage: $0 <source_env> <target_env>"
    error "Environments: local, staging, prod"
    exit 1
fi

SOURCE_ENV="$1"
TARGET_ENV="$2"

# Validate environments
for env in "$SOURCE_ENV" "$TARGET_ENV"; do
    case $env in
        local|staging|prod) ;;
        *) error "Invalid environment: $env (must be local, staging, or prod)"; exit 1 ;;
    esac
done

warning "Migration: $SOURCE_ENV -> $TARGET_ENV"
read -p "Continue? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log "Cancelled."
    exit 0
fi

# Define compose files per environment
case $SOURCE_ENV in
    local)
        SOURCE_COMPOSE="docker-compose.yml"
        SOURCE_URL="http://localhost"
        ;;
    staging)
        SOURCE_COMPOSE="docker-compose.yml -f docker-compose.staging.yml"
        SOURCE_URL="https://staging.chemgraph.ru"
        ;;
    prod)
        SOURCE_COMPOSE="docker-compose.yml -f docker-compose.prod.yml"
        SOURCE_URL="https://chemgraph.ru"
        ;;
esac

case $TARGET_ENV in
    local)
        TARGET_COMPOSE="docker-compose.yml"
        TARGET_URL="http://localhost"
        ;;
    staging)
        TARGET_COMPOSE="docker-compose.yml -f docker-compose.staging.yml"
        TARGET_URL="https://staging.chemgraph.ru"
        ;;
    prod)
        TARGET_COMPOSE="docker-compose.yml -f docker-compose.prod.yml"
        TARGET_URL="https://chemgraph.ru"
        ;;
esac

# Step 1: Create backup from source
log "Creating backup from $SOURCE_ENV..."
BACKUP_FILE="backups/migrate_${SOURCE_ENV}_to_${TARGET_ENV}_$(date -u +%Y%m%d_%H%M%S).tar.gz"

mkdir -p backups

log "Dumping database from $SOURCE_ENV..."
docker-compose -f $SOURCE_COMPOSE exec -T mysql \
    mysqldump -u ghost -p"$MYSQL_PASSWORD" --single-transaction --routines --triggers --events ghost \
    | gzip > "backups/${BACKUP_FILE%.tar.gz}_mysql.sql.gz"

log "Archiving Ghost content from $SOURCE_ENV..."
docker run --rm \
    -v chemgraph_ghost_content:/source:ro \
    -v "$(pwd)/backups:/dest" \
    alpine tar czf "/dest/${BACKUP_FILE%.tar.gz}_content.tar.gz" -C /source .

log "Creating migration package..."
tar czf "$BACKUP_FILE" -C backups \
    "${BACKUP_FILE%.tar.gz}_mysql.sql.gz" \
    "${BACKUP_FILE%.tar.gz}_content.tar.gz"

rm -f "backups/${BACKUP_FILE%.tar.gz}_mysql.sql.gz" \
      "backups/${BACKUP_FILE%.tar.gz}_content.tar.gz"

success "Migration package created: $BACKUP_FILE"

# Step 2: Transfer to target (if remote)
if [[ "$TARGET_ENV" != "local" ]]; then
    log "Transferring to $TARGET_ENV..."
    # This would use scp/rsync to target server
    warning "Manual transfer required for remote environments"
    warning "Run on target: scp user@source:$(pwd)/$BACKUP_FILE ./backups/"
fi

# Step 3: Restore on target
log "Restoring to $TARGET_ENV..."

# Update URLs in database dump
log "Updating URLs: $SOURCE_URL -> $TARGET_URL"
gunzip -c "backups/${BACKUP_FILE%.tar.gz}_mysql.sql.gz" | \
    sed "s|$SOURCE_URL|$TARGET_URL|g" | \
    gzip > "backups/${BACKUP_FILE%.tar.gz}_mysql_updated.sql.gz"

# Restore database
log "Restoring database..."
gunzip -c "backups/${BACKUP_FILE%.tar.gz}_mysql_updated.sql.gz" | \
    docker-compose -f $TARGET_COMPOSE exec -T mysql \
    mysql -u ghost -p"$MYSQL_PASSWORD" ghost

# Restore content
log "Restoring Ghost content..."
docker run --rm \
    -v chemgraph_ghost_content:/dest \
    -v "$(pwd)/backups:/source" \
    alpine tar xzf "/source/${BACKUP_FILE%.tar.gz}_content.tar.gz" -C /dest

# Cleanup
rm -f "backups/${BACKUP_FILE%.tar.gz}_mysql.sql.gz" \
      "backups/${BACKUP_FILE%.tar.gz}_mysql_updated.sql.gz" \
      "backups/${BACKUP_FILE%.tar.gz}_content.tar.gz" \
      "$BACKUP_FILE"

# Restart target services
log "Restarting $TARGET_ENV services..."
docker-compose -f $TARGET_COMPOSE restart ghost nginx

success "Migration $SOURCE_ENV -> $TARGET_ENV completed!"
log "Verify at: $TARGET_URL"