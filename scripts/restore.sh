#!/usr/bin/env bash
# restore.sh - Restore Chemgraph from encrypted backup
# =============================================================================
# Usage: ./restore.sh BACKUP_FILE.tar.gz.age
# =============================================================================

set -euo pipefail

# Configuration
PROJECT_DIR="/opt/chemgraph"
AGE_IDENTITY_FILE="${HOME}/.age/chemgraph.key"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "[$(date -u +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "${GREEN}✓${NC} $*"; }
warning() { log "${YELLOW}⚠${NC} $*"; }
error() { log "${RED}✗${NC} $*"; }

# Check arguments
if [[ $# -lt 1 ]]; then
    error "Usage: $0 <backup-file.tar.gz.age>"
    echo "Available backups:"
    ls -lh /var/backups/chemgraph/*.tar.gz.age 2>/dev/null || echo "  No backups found"
    exit 1
fi

BACKUP_FILE="$1"

if [[ ! -f "$BACKUP_FILE" ]]; then
    error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

if [[ ! -f "$AGE_IDENTITY_FILE" ]]; then
    error "Age identity key not found: $AGE_IDENTITY_FILE"
    exit 1
fi

# Confirmation
warning "This will OVERWRITE current database and content!"
warning "Backup file: $BACKUP_FILE"
read -p "Type 'RESTORE' to confirm: " confirm
if [[ "$confirm" != "RESTORE" ]]; then
    log "Cancelled."
    exit 1
fi

# Create temp directory
TMPDIR=$(mktemp -d -t chemgraph-restore-XXXXXX)
trap "rm -rf $TMPDIR" EXIT

log "Decrypting and extracting backup..."
age -d -i "$AGE_IDENTITY_FILE" "$BACKUP_FILE" | tar xzf - -C "$TMPDIR" || {
    error "Decryption/extraction failed"
    exit 1
}

# Verify checksum
cd "$TMPDIR"
BACKUP_BASE=$(basename "$BACKUP_FILE" .age)
sha256sum -c "${BACKUP_BASE}.sha256" || {
    error "Checksum verification failed"
    exit 1
}
success "Backup verified"

# Stop Ghost and Nginx (keep DB running for restore)
log "Stopping Ghost and Nginx..."
cd "$PROJECT_DIR"
docker-compose -f docker-compose.prod.yml stop ghost nginx

# Restore MySQL
log "Restoring MySQL database..."
gunzip -c "$TMPDIR/${BACKUP_BASE}_mysql.sql.gz" | docker exec -i chemgraph-mysql \
    mysql -u ghost -p"$(cat /run/secrets/mysql_password 2>/dev/null || echo "$MYSQL_PASSWORD")" ghost || {
    error "MySQL restore failed"
    exit 1
}
success "MySQL restored"

# Restore Ghost content
log "Restoring Ghost content..."
docker run --rm \
    -v chemgraph_ghost_content:/dest \
    -v "$TMPDIR:/source" \
    alpine tar xzf "/source/${BACKUP_BASE}_content.tar.gz" -C /dest || {
    error "Ghost content restore failed"
    exit 1
}
success "Ghost content restored"

# Show config files for manual review
log "Config files extracted to: $TMPDIR"
warning "Review config files manually before applying:"
ls -la "$TMPDIR/${BACKUP_BASE}_config.tar.gz" 2>/dev/null && {
    mkdir -p "$TMPDIR/configs"
    tar xzf "$TMPDIR/${BACKUP_BASE}_config.tar.gz" -C "$TMPDIR/configs"
    log "Config contents:"
    find "$TMPDIR/configs" -type f
}

# Start services
log "Starting services..."
docker-compose -f docker-compose.prod.yml up -d ghost nginx

# Wait for health
log "Waiting for services to be healthy..."
for i in {1..30}; do
    if curl -f -s https://chemgraph.ru/health > /dev/null 2>&1; then
        success "Health check passed"
        break
    fi
    if [[ $i -eq 30 ]]; then
        error "Health check failed after 5 minutes"
        docker-compose -f docker-compose.prod.yml logs ghost --tail=50
        exit 1
    fi
    sleep 10
done

# Final verification
log "Running final verification..."
curl -f -s https://chemgraph.ru/health
curl -f -s https://chemgraph.ru/ghost/ -o /dev/null -w "%{http_code}" | grep -q "200\|302"

success "=== RESTORE COMPLETED SUCCESSFULLY ==="
log "Site should be accessible at https://chemgraph.ru"