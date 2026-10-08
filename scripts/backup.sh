#!/usr/bin/env bash
# backup.sh - Automated backup script for Chemgraph (Linux/VPS)
# =============================================================================
# Usage: ./backup.sh [--verify-only]
# Cron: 0 3 * * * /opt/chemgraph/scripts/backup.sh >> /var/log/chemgraph-backup.log 2>&1
# =============================================================================

set -euo pipefail

# Configuration
BACKUP_DIR="/var/backups/chemgraph"
PROJECT_DIR="/opt/chemgraph"
DATE=$(date -u +"%Y%m%d_%H%M%S")
BACKUP_NAME="chemgraph_${DATE}"
AGE_RECIPIENT_FILE="${HOME}/.age/chemgraph.pub"
AGE_IDENTITY_FILE="${HOME}/.age/chemgraph.key"
RETENTION_DAYS=30
RCLONE_REMOTE="r2:chemgraph-backups"
OFFSITE_HOST="backup@offsite-chemgraph"
OFFSITE_PATH="/var/backups/chemgraph"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "[$(date -u +'%Y-%m-%d %H:%M:%S')] $*"; }
success() { log "${GREEN}✓${NC} $*"; }
warning() { log "${YELLOW}⚠${NC} $*"; }
error() { log "${RED}✗${NC} $*"; }

# Check dependencies
check_deps() {
    for cmd in docker age rclone rsync; do
        if ! command -v "$cmd" &>/dev/null; then
            error "Required command not found: $cmd"
            exit 1
        fi
    done
    if [[ ! -f "$AGE_RECIPIENT_FILE" ]]; then
        error "Age recipient key not found: $AGE_RECIPIENT_FILE"
        exit 1
    fi
}

# Create backup
create_backup() {
    mkdir -p "$BACKUP_DIR"
    cd "$PROJECT_DIR"

    log "Starting backup: $BACKUP_NAME"

    # 1. MySQL dump
    log "Dumping MySQL..."
    docker exec chemgraph-mysql \
        mysqldump -u ghost -p"$(cat /run/secrets/mysql_password 2>/dev/null || echo "$MYSQL_PASSWORD")" \
        --single-transaction --routines --triggers --events ghost \
        | gzip > "$BACKUP_DIR/${BACKUP_NAME}_mysql.sql.gz"

    # 2. Ghost content
    log "Archiving Ghost content..."
    docker run --rm \
        -v chemgraph_ghost_content:/source:ro \
        -v "$BACKUP_DIR:/dest" \
        alpine tar czf "/dest/${BACKUP_NAME}_content.tar.gz" -C /source .

    # 3. Configs
    log "Archiving configs..."
    tar czf "$BACKUP_DIR/${BACKUP_NAME}_config.tar.gz" \
        -C "$PROJECT_DIR" \
        docker-compose.yml docker-compose.prod.yml \
        config/ .env.example 2>/dev/null || true

    # 4. Combine & Encrypt
    log "Encrypting backup..."
    tar czf - -C "$BACKUP_DIR" \
        "${BACKUP_NAME}_mysql.sql.gz" \
        "${BACKUP_NAME}_content.tar.gz" \
        "${BACKUP_NAME}_config.tar.gz" \
        | age -r "$(cat "$AGE_RECIPIENT_FILE")" -e > "$BACKUP_DIR/${BACKUP_NAME}.tar.gz.age"

    # 5. Checksum
    sha256sum "$BACKUP_DIR/${BACKUP_NAME}.tar.gz.age" > "$BACKUP_DIR/${BACKUP_NAME}.sha256"

    # 6. Cleanup temp files
    rm -f "$BACKUP_DIR/${BACKUP_NAME}_mysql.sql.gz" \
          "$BACKUP_DIR/${BACKUP_NAME}_content.tar.gz" \
          "$BACKUP_DIR/${BACKUP_NAME}_config.tar.gz"

    success "Backup created: $BACKUP_DIR/${BACKUP_NAME}.tar.gz.age"
}

# Verify backup
verify_backup() {
    local file="${1:-}"
    if [[ -z "$file" ]]; then
        file=$(ls -t "$BACKUP_DIR"/*.tar.gz.age 2>/dev/null | head -1)
    fi

    if [[ ! -f "$file" ]]; then
        error "Backup file not found: $file"
        return 1
    fi

    log "Verifying backup: $file"

    # Decrypt and verify checksum
    local tmpdir=$(mktemp -d)
    age -d -i "$AGE_IDENTITY_FILE" "$file" 2>/dev/null | tar xzf - -C "$tmpdir" || {
        error "Decryption failed"
        rm -rf "$tmpdir"
        return 1
    }

    cd "$tmpdir"
    sha256sum -c "${BACKUP_NAME}.sha256" || {
        error "Checksum verification failed"
        rm -rf "$tmpdir"
        return 1
    }

    success "Backup verification passed"
    rm -rf "$tmpdir"
    return 0
}

# Sync to remote storage
sync_remotes() {
    local file="${1:-}"
    if [[ -z "$file" ]]; then
        file=$(ls -t "$BACKUP_DIR"/*.tar.gz.age 2>/dev/null | head -1)
    fi

    local base=$(basename "$file" .age)
    local sha_file="$BACKUP_DIR/${base}.sha256"

    log "Syncing to Cloudflare R2..."
    rclone copy "$file" "$RCLONE_REMOTE/" --progress
    rclone copy "$sha_file" "$RCLONE_REMOTE/" --progress

    log "Syncing to offsite..."
    rsync -avz --progress "$BACKUP_DIR/" "$OFFSITE_HOST:$OFFSITE_PATH/"

    success "Remote sync completed"
}

# Cleanup old backups
cleanup_old() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -name "chemgraph_*.tar.gz.age" -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "chemgraph_*.sha256" -mtime +$RETENTION_DAYS -delete
    success "Cleanup completed"
}

# Main
main() {
    local verify_only=false

    for arg in "$@"; do
        case $arg in
            --verify-only) verify_only=true ;;
            --verify) verify_only=true ;;
            *) ;;
        esac
    done

    check_deps

    if [[ "$verify_only" == true ]]; then
        verify_backup "$2" || exit 1
    else
        create_backup
        local latest=$(ls -t "$BACKUP_DIR"/*.tar.gz.age 2>/dev/null | head -1)
        verify_backup "$latest" || exit 1
        sync_remotes "$latest"
        cleanup_old
    fi
}

main "$@"