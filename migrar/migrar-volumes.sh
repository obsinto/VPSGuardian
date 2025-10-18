#!/bin/bash
################################################################################
# Script: migrar-volumes.sh
# Propósito: Migrar volumes Docker para um novo servidor usando backups existentes
# Uso: ./migrar-volumes.sh
################################################################################

### ========== CONFIGURAÇÃO ==========

# Servidor de destino
NEW_SERVER_IP=""
NEW_SERVER_USER="root"
NEW_SERVER_PORT="22"

# Autenticação SSH
SSH_PRIVATE_KEY_PATH="/root/.ssh/id_rsa"

# Diretórios
LOCAL_BACKUP_DIR="/root/volume-backups"
REMOTE_BACKUP_DIR="/root/volume-backups-received"

### ========== NÃO EDITAR ABAIXO DESTA LINHA ==========

LOG_PREFIX="[ Volume Migration Agent ]"
CONTROL_SOCKET="/tmp/ssh_mux_volumes_$$"

# Criar diretório de logs
LOG_DIR="$(pwd)/volume-migration-logs"
mkdir -p "$LOG_DIR"
AGENT_LOG="$LOG_DIR/volume-migration-$(date +%Y%m%d_%H%M%S).log"

### ========== FUNÇÕES ==========

log() {
    echo "$LOG_PREFIX [ $1 ] $2" | tee -a "$AGENT_LOG"
}

check_success() {
    if [ $1 -eq 0 ]; then
        log "SUCCESS" "$2"
    else
        log "FAILED" "$2"
        cleanup_and_exit 1
    fi
}

cleanup_and_exit() {
    if [ $1 -eq 0 ]; then
        log "SUCCESS" "Volume migration completed successfully."
    else
        log "FAILED" "Volume migration failed."
    fi

    log "INFO" "Cleaning up SSH connection..."
    ssh -S "$CONTROL_SOCKET" -O exit "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>/dev/null || true
    rm -f "$CONTROL_SOCKET"
    exit $1
}

trap cleanup_and_exit SIGINT SIGTERM

### ========== PROMPTS INTERATIVOS ==========

log "INFO" "========== DOCKER VOLUME MIGRATION =========="

if [ -z "$NEW_SERVER_IP" ]; then
    read -p "$LOG_PREFIX [ INPUT ] Enter the NEW server IP address: " NEW_SERVER_IP
fi
log "INFO" "Target server: $NEW_SERVER_IP"

if [ -z "$NEW_SERVER_USER" ] || [ "$NEW_SERVER_USER" = "root" ]; then
    read -p "$LOG_PREFIX [ INPUT ] SSH user (default: root): " INPUT_USER
    NEW_SERVER_USER=${INPUT_USER:-root}
fi

if [ -z "$NEW_SERVER_PORT" ] || [ "$NEW_SERVER_PORT" = "22" ]; then
    read -p "$LOG_PREFIX [ INPUT ] SSH port (default: 22): " INPUT_PORT
    NEW_SERVER_PORT=${INPUT_PORT:-22}
fi

# Listar backups de volumes disponíveis
log "INFO" "Searching for volume backups in $LOCAL_BACKUP_DIR..."

if [ ! -d "$LOCAL_BACKUP_DIR" ] || [ -z "$(ls -A $LOCAL_BACKUP_DIR/*.tar.gz 2>/dev/null)" ]; then
    log "FAILED" "No volume backups found in $LOCAL_BACKUP_DIR"
    log "INFO" "Please create volume backups first using backup-volume or backup-volume-interativo"
    exit 1
fi

echo ""
log "INFO" "Available volume backups:"
echo ""

BACKUPS=($(ls -t "$LOCAL_BACKUP_DIR"/*.tar.gz))
VOLUMES_TO_MIGRATE=()

for i in "${!BACKUPS[@]}"; do
    BACKUP_FILE="${BACKUPS[$i]}"
    BACKUP_DATE=$(stat -c %y "$BACKUP_FILE" | cut -d'.' -f1)
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    VOLUME_NAME=$(basename "$BACKUP_FILE" | sed 's/-[0-9_]*\.tar\.gz$//')

    echo "  [$i] $(basename $BACKUP_FILE)"
    echo "      Volume: $VOLUME_NAME"
    echo "      Date: $BACKUP_DATE"
    echo "      Size: $BACKUP_SIZE"
    echo ""
done

# Permitir seleção múltipla
echo "$LOG_PREFIX [ INPUT ] Select volumes to migrate:"
echo "  - Enter numbers separated by spaces (e.g., 0 2 4)"
echo "  - Enter 'all' to migrate all volumes"
echo "  - Enter 'none' to cancel"
read -p "$LOG_PREFIX [ INPUT ] Selection: " SELECTION

if [ "$SELECTION" = "none" ]; then
    log "INFO" "Migration cancelled by user."
    exit 0
fi

if [ "$SELECTION" = "all" ]; then
    SELECTED_INDICES=$(seq 0 $((${#BACKUPS[@]}-1)))
else
    SELECTED_INDICES=$SELECTION
fi

# Processar seleção
SELECTED_BACKUPS=()
for idx in $SELECTED_INDICES; do
    if [ $idx -ge 0 ] && [ $idx -lt ${#BACKUPS[@]} ]; then
        SELECTED_BACKUPS+=("${BACKUPS[$idx]}")
        VOLUME_NAME=$(basename "${BACKUPS[$idx]}" | sed 's/-[0-9_]*\.tar\.gz$//')
        VOLUMES_TO_MIGRATE+=("$VOLUME_NAME")
    fi
done

if [ ${#SELECTED_BACKUPS[@]} -eq 0 ]; then
    log "FAILED" "No valid volumes selected."
    exit 1
fi

# Confirmar migração
echo ""
log "INFO" "========== MIGRATION SUMMARY =========="
echo "  Volumes to migrate: ${#SELECTED_BACKUPS[@]}"
for i in "${!SELECTED_BACKUPS[@]}"; do
    echo "    - ${VOLUMES_TO_MIGRATE[$i]} ($(basename ${SELECTED_BACKUPS[$i]}))"
done
echo "  Target server: $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_PORT"
echo "  Total size: $(du -ch "${SELECTED_BACKUPS[@]}" | tail -1 | cut -f1)"
echo "  Logs: $LOG_DIR"
echo "========================================"
echo ""
read -p "$LOG_PREFIX [ INPUT ] Proceed with migration? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log "INFO" "Migration cancelled by user."
    exit 0
fi

### ========== SSH SETUP ==========
log "INFO" "Setting up SSH connection..."

# Verificar chave SSH
if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
    log "WARNING" "SSH key not found at $SSH_PRIVATE_KEY_PATH"
    read -p "$LOG_PREFIX [ INPUT ] Enter path to SSH private key: " SSH_PRIVATE_KEY_PATH

    if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
        log "FAILED" "SSH key not found. Aborting."
        exit 1
    fi
fi

log "INFO" "Starting ssh-agent..."
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$SSH_PRIVATE_KEY_PATH" >/dev/null 2>&1
check_success $? "SSH key added to agent."

log "INFO" "Testing SSH connection..."
ssh -o BatchMode=yes -o ConnectTimeout=10 -p "$NEW_SERVER_PORT" \
    "$NEW_SERVER_USER@$NEW_SERVER_IP" "exit" >/dev/null 2>&1
check_success $? "SSH connection successful."

log "INFO" "Establishing persistent SSH connection..."
ssh -fN -M -S "$CONTROL_SOCKET" -p "$NEW_SERVER_PORT" \
    "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>/dev/null
check_success $? "Persistent SSH connection established."

### ========== VERIFICAR DOCKER NO SERVIDOR REMOTO ==========
log "INFO" "Checking if Docker is installed on remote server..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "command -v docker >/dev/null 2>&1"
check_success $? "Docker is installed on remote server."

### ========== PREPARAR SERVIDOR REMOTO ==========
log "INFO" "Preparing remote server..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "mkdir -p $REMOTE_BACKUP_DIR"
check_success $? "Remote directory created: $REMOTE_BACKUP_DIR"

### ========== MIGRAR VOLUMES ==========
MIGRATED_COUNT=0
FAILED_COUNT=0

for i in "${!SELECTED_BACKUPS[@]}"; do
    BACKUP_FILE="${SELECTED_BACKUPS[$i]}"
    VOLUME_NAME="${VOLUMES_TO_MIGRATE[$i]}"
    BACKUP_FILENAME=$(basename "$BACKUP_FILE")

    echo ""
    log "INFO" "========== Migrating volume $((i+1))/${#SELECTED_BACKUPS[@]}: $VOLUME_NAME =========="

    # 1. Transferir backup
    log "INFO" "Transferring backup: $BACKUP_FILENAME..."
    scp -o ControlPath="$CONTROL_SOCKET" -P "$NEW_SERVER_PORT" \
        "$BACKUP_FILE" "$NEW_SERVER_USER@$NEW_SERVER_IP:$REMOTE_BACKUP_DIR/" >/dev/null 2>&1

    if [ $? -ne 0 ]; then
        log "FAILED" "Failed to transfer backup for $VOLUME_NAME"
        ((FAILED_COUNT++))
        continue
    fi
    log "SUCCESS" "Backup transferred."

    # 2. Criar volume no servidor remoto (se não existir)
    log "INFO" "Creating volume '$VOLUME_NAME' on remote server..."
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "docker volume create $VOLUME_NAME" >/dev/null 2>&1
    log "SUCCESS" "Volume created or already exists."

    # 3. Restaurar volume
    log "INFO" "Restoring volume data..."
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "docker run --rm -v $VOLUME_NAME:/volume -v $REMOTE_BACKUP_DIR:/backup busybox sh -c 'cd /volume && tar xzf /backup/$BACKUP_FILENAME'" 2>/dev/null

    if [ $? -eq 0 ]; then
        log "SUCCESS" "Volume '$VOLUME_NAME' restored successfully."
        ((MIGRATED_COUNT++))

        # Verificar conteúdo
        FILES_COUNT=$(ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "docker run --rm -v $VOLUME_NAME:/volume busybox find /volume -type f" 2>/dev/null | wc -l)
        log "INFO" "Files restored: $FILES_COUNT"
    else
        log "FAILED" "Failed to restore volume '$VOLUME_NAME'"
        ((FAILED_COUNT++))
    fi
done

### ========== CLEANUP REMOTE BACKUPS ==========
echo ""
log "INFO" "Cleaning up temporary backups on remote server..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "rm -rf $REMOTE_BACKUP_DIR" 2>/dev/null
log "SUCCESS" "Cleanup complete."

### ========== FINAL SUMMARY ==========
echo ""
log "INFO" "========== MIGRATION SUMMARY =========="
echo ""
echo "  ✅ Successfully migrated: $MIGRATED_COUNT volumes"
if [ $FAILED_COUNT -gt 0 ]; then
    echo "  ❌ Failed: $FAILED_COUNT volumes"
fi
echo ""
echo "  📍 Remote server: $NEW_SERVER_IP"
echo "  📋 Migration log: $AGENT_LOG"
echo ""
echo "  Migrated volumes:"
for i in "${!SELECTED_BACKUPS[@]}"; do
    VOLUME_NAME="${VOLUMES_TO_MIGRATE[$i]}"
    echo "    - $VOLUME_NAME"
done
echo ""
echo "  ⚠️  NEXT STEPS:"
echo "  1. Verify volumes on remote server:"
echo "     ssh $NEW_SERVER_USER@$NEW_SERVER_IP 'docker volume ls'"
echo ""
echo "  2. Check volume contents:"
echo "     ssh $NEW_SERVER_USER@$NEW_SERVER_IP 'docker run --rm -v VOLUME_NAME:/volume busybox ls -la /volume'"
echo ""
echo "  3. Update your applications to use the migrated volumes"
echo ""
echo "========================================"
echo ""

cleanup_and_exit 0
