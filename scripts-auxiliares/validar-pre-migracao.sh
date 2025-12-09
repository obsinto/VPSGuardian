#!/bin/bash
################################################################################
# Script: validar-pre-migracao.sh
# Propósito: Validar ambiente ANTES da migração
# Uso: ./validar-pre-migracao.sh
################################################################################

set -e

LOG_PREFIX="[ Pre-Migration Validator ]"
VALIDATION_LOG="/tmp/pre-migration-validation-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "$LOG_PREFIX [ $1 ] $2" | tee -a "$VALIDATION_LOG"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        log "✓" "$1 is installed"
        return 0
    else
        log "✗" "$1 is NOT installed"
        return 1
    fi
}

check_file() {
    if [ -f "$1" ]; then
        log "✓" "File exists: $1"
        return 0
    else
        log "✗" "File NOT found: $1"
        return 1
    fi
}

check_directory() {
    if [ -d "$1" ]; then
        log "✓" "Directory exists: $1"
        return 0
    else
        log "✗" "Directory NOT found: $1"
        return 1
    fi
}

check_docker_container() {
    if docker ps --filter "name=$1" --format '{{.Names}}' | grep -q "^$1$"; then
        log "✓" "Container running: $1"
        return 0
    else
        log "✗" "Container NOT running: $1"
        return 1
    fi
}

check_port() {
    if nc -z localhost "$1" 2>/dev/null; then
        log "✓" "Port $1 is open"
        return 0
    else
        log "✗" "Port $1 is NOT open"
        return 1
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║           PRE-MIGRATION VALIDATION CHECKLIST               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0
WARNINGS=0

################################################################################
# 1. SISTEMA BASE
################################################################################

log "INFO" "========== SYSTEM CHECKS =========="
echo ""

# Verificar usuário
if [ "$EUID" -eq 0 ]; then
    log "✓" "Running as root"
else
    log "⚠" "NOT running as root (some checks may fail)"
    ((WARNINGS++))
fi

# Verificar espaço em disco
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    log "✓" "Disk usage: ${DISK_USAGE}% (healthy)"
else
    log "⚠" "Disk usage: ${DISK_USAGE}% (consider cleaning up)"
    ((WARNINGS++))
fi

# Verificar memória
TOTAL_MEM=$(free -m | awk 'NR==2 {print $2}')
AVAILABLE_MEM=$(free -m | awk 'NR==2 {print $7}')
if [ "$AVAILABLE_MEM" -gt 500 ]; then
    log "✓" "Available memory: ${AVAILABLE_MEM}MB"
else
    log "⚠" "Low memory: ${AVAILABLE_MEM}MB available"
    ((WARNINGS++))
fi

echo ""

################################################################################
# 2. DEPENDÊNCIAS NECESSÁRIAS
################################################################################

log "INFO" "========== REQUIRED DEPENDENCIES =========="
echo ""

check_command "docker" || ((ERRORS++))
check_command "tar" || ((ERRORS++))
check_command "gzip" || ((ERRORS++))
check_command "ssh" || ((ERRORS++))
check_command "scp" || ((ERRORS++))
check_command "nc" || ((WARNINGS++))

echo ""

################################################################################
# 3. VERIFICAR COOLIFY
################################################################################

log "INFO" "========== COOLIFY CHECKS =========="
echo ""

check_directory "/data/coolify" || ((ERRORS++))
check_directory "/data/coolify/source" || ((ERRORS++))
check_file "/data/coolify/source/.env" || ((ERRORS++))
check_directory "/data/coolify/ssh/keys" || ((WARNINGS++))

# Verificar containers do Coolify
check_docker_container "coolify" || ((ERRORS++))
check_docker_container "coolify-db" || ((ERRORS++))
check_docker_container "coolify-proxy" || ((WARNINGS++))

# Verificar porta do Coolify
check_port 8000 || ((WARNINGS++))

# Verificar APP_KEY
if [ -f "/data/coolify/source/.env" ]; then
    APP_KEY=$(grep "^APP_KEY=" /data/coolify/source/.env | cut -d'=' -f2-)
    if [ -n "$APP_KEY" ]; then
        log "✓" "APP_KEY found in .env"
    else
        log "✗" "APP_KEY NOT found in .env"
        ((ERRORS++))
    fi
fi

# Verificar versão do Coolify
COOLIFY_VERSION=$(docker ps --filter "name=coolify" --format '{{.Image}}' | grep coollabsio/coolify | head -n1)
if [ -n "$COOLIFY_VERSION" ]; then
    log "✓" "Coolify version: $COOLIFY_VERSION"
else
    log "⚠" "Could not detect Coolify version"
    ((WARNINGS++))
fi

echo ""

################################################################################
# 4. VERIFICAR BANCO DE DADOS
################################################################################

log "INFO" "========== DATABASE CHECKS =========="
echo ""

# Testar conexão com banco
if docker exec coolify-db pg_isready -U coolify >/dev/null 2>&1; then
    log "✓" "PostgreSQL is ready"
else
    log "✗" "PostgreSQL is NOT ready"
    ((ERRORS++))
fi

# Verificar tamanho do banco
DB_SIZE=$(docker exec coolify-db psql -U coolify -d coolify -t -c "SELECT pg_size_pretty(pg_database_size('coolify'));" 2>/dev/null | xargs)
if [ -n "$DB_SIZE" ]; then
    log "✓" "Database size: $DB_SIZE"
else
    log "⚠" "Could not determine database size"
    ((WARNINGS++))
fi

# Contar tabelas
TABLE_COUNT=$(docker exec coolify-db psql -U coolify -d coolify -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs)
if [ -n "$TABLE_COUNT" ] && [ "$TABLE_COUNT" -gt 0 ]; then
    log "✓" "Database has $TABLE_COUNT tables"
else
    log "⚠" "Could not count database tables"
    ((WARNINGS++))
fi

echo ""

################################################################################
# 5. VERIFICAR SSH
################################################################################

log "INFO" "========== SSH CHECKS =========="
echo ""

SSH_KEY_PATH="/root/.ssh/id_rsa"
if [ -f "$SSH_KEY_PATH" ]; then
    log "✓" "SSH private key exists: $SSH_KEY_PATH"

    # Verificar permissões
    KEY_PERMS=$(stat -c %a "$SSH_KEY_PATH" 2>/dev/null || stat -f %Lp "$SSH_KEY_PATH" 2>/dev/null)
    if [ "$KEY_PERMS" = "600" ] || [ "$KEY_PERMS" = "400" ]; then
        log "✓" "SSH key permissions are correct: $KEY_PERMS"
    else
        log "⚠" "SSH key permissions should be 600 or 400, current: $KEY_PERMS"
        ((WARNINGS++))
    fi
else
    log "⚠" "SSH private key not found at $SSH_KEY_PATH"
    log "INFO" "You will need to configure SSH key before migration"
    ((WARNINGS++))
fi

# Verificar authorized_keys
if [ -f "/root/.ssh/authorized_keys" ]; then
    KEY_COUNT=$(grep -c "^ssh-" /root/.ssh/authorized_keys 2>/dev/null || echo 0)
    log "✓" "authorized_keys has $KEY_COUNT keys"
else
    log "⚠" "No authorized_keys file found"
    ((WARNINGS++))
fi

echo ""

################################################################################
# 6. VERIFICAR BACKUPS EXISTENTES
################################################################################

log "INFO" "========== BACKUP CHECKS =========="
echo ""

BACKUP_DIR="/root/coolify-backups"
if [ -d "$BACKUP_DIR" ]; then
    log "✓" "Backup directory exists: $BACKUP_DIR"

    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt 0 ]; then
        log "✓" "Found $BACKUP_COUNT backup file(s)"

        # Mostrar backup mais recente
        LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            BACKUP_SIZE=$(du -h "$LATEST_BACKUP" | cut -f1)
            BACKUP_DATE=$(stat -c %y "$LATEST_BACKUP" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
            log "✓" "Latest backup: $(basename $LATEST_BACKUP)"
            log "INFO" "  - Size: $BACKUP_SIZE"
            log "INFO" "  - Date: $BACKUP_DATE"

            # Verificar conteúdo do backup
            log "INFO" "Validating backup contents..."
            if tar -tzf "$LATEST_BACKUP" 2>/dev/null | grep -q "\.dmp$"; then
                log "✓" "Backup contains database dump"
            else
                log "✗" "Backup does NOT contain database dump"
                ((ERRORS++))
            fi

            if tar -tzf "$LATEST_BACKUP" 2>/dev/null | grep -q "\.env$"; then
                log "✓" "Backup contains .env file"
            else
                log "⚠" "Backup does NOT contain .env file"
                ((WARNINGS++))
            fi
        fi
    else
        log "⚠" "No backup files found in $BACKUP_DIR"
        log "INFO" "Run 'vps-guardian backup' to create a backup first"
        ((WARNINGS++))
    fi
else
    log "⚠" "Backup directory does not exist: $BACKUP_DIR"
    log "INFO" "Run 'vps-guardian backup' to create initial backup"
    ((WARNINGS++))
fi

echo ""

################################################################################
# 7. VERIFICAR VOLUMES DOCKER
################################################################################

log "INFO" "========== DOCKER VOLUMES =========="
echo ""

VOLUME_COUNT=$(docker volume ls -q | wc -l)
log "✓" "Total Docker volumes: $VOLUME_COUNT"

# Listar volumes do Coolify
COOLIFY_VOLUMES=$(docker volume ls --filter name=coolify -q)
if [ -n "$COOLIFY_VOLUMES" ]; then
    COOLIFY_VOLUME_COUNT=$(echo "$COOLIFY_VOLUMES" | wc -l)
    log "✓" "Coolify volumes: $COOLIFY_VOLUME_COUNT"
    echo "$COOLIFY_VOLUMES" | while read volume; do
        log "INFO" "  - $volume"
    done
else
    log "⚠" "No Coolify volumes found"
    ((WARNINGS++))
fi

echo ""

################################################################################
# 8. VERIFICAR REDE
################################################################################

log "INFO" "========== NETWORK CHECKS =========="
echo ""

# Verificar conectividade externa
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    log "✓" "External network connectivity OK"
else
    log "✗" "No external network connectivity"
    ((ERRORS++))
fi

# Verificar resolução DNS
if nslookup google.com >/dev/null 2>&1 || host google.com >/dev/null 2>&1; then
    log "✓" "DNS resolution working"
else
    log "✗" "DNS resolution NOT working"
    ((ERRORS++))
fi

echo ""

################################################################################
# RESUMO FINAL
################################################################################

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                   VALIDATION SUMMARY                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    log "SUCCESS" "All checks passed! System is ready for migration."
    echo ""
    log "INFO" "Next steps:"
    echo "  1. Ensure you have SSH access to the destination server"
    echo "  2. Run: ./migrar/migrar-coolify.sh"
    echo "  3. Follow the migration wizard"
    EXIT_CODE=0
elif [ $ERRORS -eq 0 ]; then
    log "WARNING" "System passed with $WARNINGS warning(s)"
    echo ""
    log "INFO" "Review warnings above before proceeding with migration"
    log "INFO" "Migration can proceed but some features may be affected"
    EXIT_CODE=0
else
    log "ERROR" "System validation FAILED with $ERRORS error(s) and $WARNINGS warning(s)"
    echo ""
    log "INFO" "Fix errors above before attempting migration"
    log "INFO" "Run this script again after fixing issues"
    EXIT_CODE=1
fi

echo ""
log "INFO" "Full validation log saved to: $VALIDATION_LOG"
echo ""

exit $EXIT_CODE
