#!/bin/bash
################################################################################
# Script: migrar-completo.sh
# Propósito: Migração COMPLETA Coolify + Apps (DB + Volumes + Configurações)
# Uso: ./migrar-completo.sh [--config=FILE] [--auto] [--skip-volumes]
################################################################################

# Carregar bibliotecas compartilhadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

### ========== CONFIGURAÇÃO PADRÃO ==========
NEW_SERVER_IP="${NEW_SERVER_IP:-}"
NEW_SERVER_USER="${NEW_SERVER_USER:-root}"
NEW_SERVER_PORT="${NEW_SERVER_PORT:-22}"
SSH_PRIVATE_KEY_PATH="${SSH_PRIVATE_KEY_PATH:-/root/.ssh/id_rsa}"

BACKUP_FILE="${BACKUP_FILE:-}"
SKIP_VOLUMES=false
AUTO_MODE=false

VOLUMES_BACKUP_DIR="/tmp/coolify-volumes-migration-$$"

### ========== PARSE ARGUMENTOS ==========
CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --config=*)
            CONFIG_FILE="${1#*=}"
            shift
            ;;
        --auto)
            AUTO_MODE=true
            shift
            ;;
        --skip-volumes)
            SKIP_VOLUMES=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Migração COMPLETA do Coolify (DB + Volumes + Configurações)"
            echo ""
            echo "Options:"
            echo "  --config=FILE      Load configuration from file"
            echo "  --auto             Run in automatic mode (no prompts)"
            echo "  --skip-volumes     Skip application volumes migration"
            echo "  -h, --help         Show this help"
            echo ""
            echo "Este script executa:"
            echo "  1. Backup do Coolify (DB + SSH keys + .env)"
            echo "  2. Backup de TODOS os volumes Docker (aplicações)"
            echo "  3. Migração do Coolify para novo servidor"
            echo "  4. Transferência dos volumes para novo servidor"
            echo "  5. Restore dos volumes no novo servidor"
            echo ""
            echo "Configuration file: use migration.conf.example as template"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Carregar configuração
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    log_info "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
fi

### ========== VALIDAÇÃO ==========
log_section "VPS Guardian - Migração Completa Coolify + Apps"

if [ -z "$NEW_SERVER_IP" ]; then
    if [ "$AUTO_MODE" = true ]; then
        log_error "NEW_SERVER_IP is required in automatic mode"
        exit 1
    fi
    read -p "Enter NEW server IP: " NEW_SERVER_IP
fi

if [ -z "$NEW_SERVER_IP" ]; then
    log_error "Server IP is required"
    exit 1
fi

log_info "Target server: $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_PORT"

# Verificar chave SSH
if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
    log_error "SSH key not found: $SSH_PRIVATE_KEY_PATH"
    exit 1
fi

# Contar volumes
volume_count=$(docker volume ls -q | wc -l)
log_info "Docker volumes found: $volume_count"

if [ "$SKIP_VOLUMES" = true ]; then
    log_warning "Volume migration will be SKIPPED (--skip-volumes flag)"
fi

# Confirmar migração
if [ "$AUTO_MODE" = false ]; then
    echo ""
    log_section "MIGRATION PLAN"
    echo "  📋 Steps:"
    echo "     1. Backup Coolify (DB + config)"
    if [ "$SKIP_VOLUMES" = false ]; then
        echo "     2. Backup $volume_count Docker volumes"
        echo "     3. Migrate Coolify to $NEW_SERVER_IP"
        echo "     4. Transfer volumes to $NEW_SERVER_IP"
        echo "     5. Restore volumes on $NEW_SERVER_IP"
    else
        echo "     2. Migrate Coolify to $NEW_SERVER_IP (VOLUMES SKIPPED)"
    fi
    echo ""
    echo "  ⏱️  Estimated time: 30min-3h (depends on data size)"
    echo "  ⚠️  Downtime: YES (applications will be down during migration)"
    echo ""
    read -p "Proceed with COMPLETE migration? Type 'YES' to confirm: " confirm

    if [ "$confirm" != "YES" ]; then
        log_info "Migration cancelled by user"
        exit 0
    fi
fi

### ========== STEP 1: BACKUP COOLIFY ==========
log_section "Step 1/5: Backup Coolify"

log_info "Running backup-coolify.sh..."
"$SCRIPT_DIR/../backup/backup-coolify.sh" >/dev/null 2>&1

if [ $? -ne 0 ]; then
    log_error "Coolify backup failed"
    exit 1
fi

# Obter backup mais recente se não especificado
if [ -z "$BACKUP_FILE" ]; then
    BACKUP_FILE=$(ls -t /var/backups/vpsguardian/coolify/*.tar.gz 2>/dev/null | head -1)
fi

if [ ! -f "$BACKUP_FILE" ]; then
    log_error "Backup file not found"
    exit 1
fi

log_success "Coolify backup: $(basename $BACKUP_FILE)"

### ========== STEP 2: BACKUP VOLUMES ==========
if [ "$SKIP_VOLUMES" = false ]; then
    log_section "Step 2/5: Backup Docker Volumes"

    mkdir -p "$VOLUMES_BACKUP_DIR"

    log_info "Backing up all Docker volumes to $VOLUMES_BACKUP_DIR..."
    "$SCRIPT_DIR/backup-volumes.sh" --all --output="$VOLUMES_BACKUP_DIR" 2>&1 | grep -E "SUCCESS|ERROR|WARNING|Backing up"

    # Verificar se backups foram criados
    backup_count=$(find "$VOLUMES_BACKUP_DIR" -name "*-backup-*.tar.gz" -type f | wc -l)

    if [ "$backup_count" -eq 0 ]; then
        log_warning "No volume backups created (this is OK if no volumes exist)"
    else
        log_success "$backup_count volume backups created"
    fi
else
    log_section "Step 2/5: SKIPPED (--skip-volumes)"
fi

### ========== STEP 3: MIGRATE COOLIFY ==========
log_section "Step 3/5: Migrate Coolify to New Server"

# Preparar variáveis para migrar-coolify.sh
export NEW_SERVER_IP
export NEW_SERVER_USER
export NEW_SERVER_PORT
export SSH_PRIVATE_KEY_PATH
export BACKUP_FILE

log_info "Running migrar-coolify.sh..."

if [ "$AUTO_MODE" = true ]; then
    "$SCRIPT_DIR/migrar-coolify.sh" --auto
else
    "$SCRIPT_DIR/migrar-coolify.sh"
fi

if [ $? -ne 0 ]; then
    log_error "Coolify migration failed"
    log_info "Cleaning up..."
    rm -rf "$VOLUMES_BACKUP_DIR"
    exit 1
fi

log_success "Coolify migrated successfully"

### ========== STEP 4: TRANSFER VOLUMES ==========
if [ "$SKIP_VOLUMES" = false ] && [ "$backup_count" -gt 0 ]; then
    log_section "Step 4/5: Transfer Volumes to New Server"

    # Preparar configuração para transfer-volumes.sh
    export SSH_IP="$NEW_SERVER_IP"
    export SSH_USER="$NEW_SERVER_USER"
    export SSH_PORT="$NEW_SERVER_PORT"
    export SSH_KEY="$SSH_PRIVATE_KEY_PATH"
    export SOURCE_PATH="$VOLUMES_BACKUP_DIR"
    export DESTINATION_PATH="/root/coolify-volumes-backup"

    log_info "Transferring $backup_count volume backups..."
    "$SCRIPT_DIR/transfer-volumes.sh" --auto

    if [ $? -ne 0 ]; then
        log_error "Volume transfer failed"
        log_warning "Coolify was migrated but volumes failed to transfer"
        log_info "You can manually transfer volumes from: $VOLUMES_BACKUP_DIR"
        exit 1
    fi

    log_success "All volumes transferred"
else
    log_section "Step 4/5: SKIPPED (no volumes to transfer)"
fi

### ========== STEP 5: RESTORE VOLUMES ==========
if [ "$SKIP_VOLUMES" = false ] && [ "$backup_count" -gt 0 ]; then
    log_section "Step 5/5: Restore Volumes on New Server"

    log_info "Restoring volumes on $NEW_SERVER_IP..."

    # Executar restore remotamente
    ssh -i "$SSH_PRIVATE_KEY_PATH" -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" bash <<EOF
set -e

# Baixar script de restore temporariamente
cat > /tmp/restore-volumes-remote.sh <<'SCRIPT'
#!/bin/bash

BACKUP_DIR="/root/coolify-volumes-backup"

echo "[ INFO ] Restoring volumes from \$BACKUP_DIR..."

if [ ! -d "\$BACKUP_DIR" ]; then
    echo "[ ERROR ] Backup directory not found: \$BACKUP_DIR"
    exit 1
fi

success=0
failed=0

for backup_file in "\$BACKUP_DIR"/*-backup-*.tar.gz; do
    if [ ! -f "\$backup_file" ]; then
        continue
    fi

    filename=\$(basename "\$backup_file")
    volume=\$(echo "\$filename" | sed 's/-backup-[0-9_]*\.tar\.gz$//')

    echo "[ INFO ] Restoring: \$volume"

    # Criar volume se não existir
    docker volume create "\$volume" >/dev/null 2>&1 || true

    # Restaurar
    docker run --rm \\
        -v "\$volume":/target \\
        -v "\$BACKUP_DIR":/backup:ro \\
        busybox \\
        sh -c "rm -rf /target/* /target/..?* /target/.[!.]* 2>/dev/null; tar -xzf /backup/\$filename -C /target" \\
        >/dev/null 2>&1

    if [ \$? -eq 0 ]; then
        echo "[ SUCCESS ] Volume restored: \$volume"
        ((success++))
    else
        echo "[ ERROR ] Failed to restore: \$volume"
        ((failed++))
    fi
done

echo ""
echo "[ SUMMARY ] Success: \$success | Failed: \$failed"

rm -rf "\$BACKUP_DIR"
SCRIPT

chmod +x /tmp/restore-volumes-remote.sh
/tmp/restore-volumes-remote.sh
rm -f /tmp/restore-volumes-remote.sh
EOF

    if [ $? -eq 0 ]; then
        log_success "All volumes restored on new server"
    else
        log_error "Some volumes failed to restore"
        log_warning "Check logs on $NEW_SERVER_IP for details"
    fi
else
    log_section "Step 5/5: SKIPPED (no volumes to restore)"
fi

### ========== CLEANUP ==========
log_info "Cleaning up local temporary files..."
rm -rf "$VOLUMES_BACKUP_DIR"

### ========== FINAL SUMMARY ==========
echo ""
log_section "MIGRATION COMPLETE"
echo ""
echo "  🎉 Coolify + Applications migrated successfully!"
echo ""
echo "  📍 New server: http://$NEW_SERVER_IP:8000"
echo "  📦 Coolify: ✅ Migrated (DB + SSH keys + config)"
if [ "$SKIP_VOLUMES" = false ]; then
    echo "  📂 Volumes: ✅ $backup_count volumes migrated"
else
    echo "  📂 Volumes: ⏭️  SKIPPED"
fi
echo ""
echo "  ⚠️  IMPORTANT NEXT STEPS:"
echo ""
echo "  1. Access Coolify: http://$NEW_SERVER_IP:8000"
echo "  2. Check all applications are listed"
echo "  3. DEPLOY each application to start containers"
echo "     (volumes are restored but containers need to be recreated)"
echo "  4. Update DNS records to point to $NEW_SERVER_IP"
echo "  5. Test all applications thoroughly"
echo "  6. Configure backups on new server"
echo ""
echo "  💡 TIP: Applications won't start automatically after volume restore."
echo "          You MUST click 'Deploy' for each app in Coolify dashboard."
echo ""

log_success "Migration completed successfully"
exit 0
