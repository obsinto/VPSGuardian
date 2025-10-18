#!/bin/bash
################################################################################
# Script: migrar-coolify.sh
# Propósito: Migrar Coolify completo para um novo servidor usando backups existentes
# Uso: ./migrar-coolify.sh
################################################################################

### ========== CONFIGURAÇÃO ==========
# Estas variáveis podem ser editadas diretamente ou passadas via prompts

# Servidor de destino
NEW_SERVER_IP=""
NEW_SERVER_USER="root"
NEW_SERVER_PORT="22"
NEW_SERVER_AUTH_KEYS_FILE="/root/.ssh/authorized_keys"

# Autenticação SSH
SSH_PRIVATE_KEY_PATH="/root/.ssh/id_rsa"
LOCAL_AUTH_KEYS_FILE="/root/.ssh/authorized_keys"

# Backup a ser usado (deixe vazio para listar e escolher)
BACKUP_FILE=""

# Diretórios
COOLIFY_DATA_DIR="/data/coolify"
ENV_FILE="$COOLIFY_DATA_DIR/source/.env"
SSH_KEYS_DIR="$COOLIFY_DATA_DIR/ssh/keys"
BACKUP_DIR="/root/coolify-backups"

### ========== NÃO EDITAR ABAIXO DESTA LINHA ==========

REMOTE_BACKUP_DIR="/root/coolify-backup"
LOG_PREFIX="[ Migration Agent ]"
CONTROL_SOCKET="/tmp/ssh_mux_socket_$$"

# Criar diretório de logs
LOG_DIR="$(pwd)/migration-logs"
mkdir -p "$LOG_DIR"
AGENT_LOG="$LOG_DIR/migration-agent-$(date +%Y%m%d_%H%M%S).log"
DB_RESTORE_LOG="$LOG_DIR/db-restore.log"
INSTALL_LOG="$LOG_DIR/coolify-install.log"
FINAL_INSTALL_LOG="$LOG_DIR/coolify-final-install.log"

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
        log "SUCCESS" "Migration completed successfully."
    else
        log "FAILED" "Migration failed."
    fi

    log "INFO" "Cleaning up SSH connection and background processes..."
    kill $HEALTH_CHECK_PID 2>/dev/null || true
    ssh -S "$CONTROL_SOCKET" -O exit "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>/dev/null || true
    rm -f "$CONTROL_SOCKET"
    log "INFO" "Cleanup complete."
    exit $1
}

trap cleanup_and_exit SIGINT SIGTERM

### ========== PROMPTS INTERATIVOS ==========

if [ -z "$NEW_SERVER_IP" ]; then
    read -p "$LOG_PREFIX [ INPUT ] Enter the NEW server IP address: " NEW_SERVER_IP
fi
log "INFO" "Target server: $NEW_SERVER_IP"

if [ -z "$NEW_SERVER_USER" ] || [ "$NEW_SERVER_USER" = "root" ]; then
    read -p "$LOG_PREFIX [ INPUT ] SSH user (default: root): " INPUT_USER
    NEW_SERVER_USER=${INPUT_USER:-root}
fi
log "INFO" "SSH user: $NEW_SERVER_USER"

if [ -z "$NEW_SERVER_PORT" ] || [ "$NEW_SERVER_PORT" = "22" ]; then
    read -p "$LOG_PREFIX [ INPUT ] SSH port (default: 22): " INPUT_PORT
    NEW_SERVER_PORT=${INPUT_PORT:-22}
fi
log "INFO" "SSH port: $NEW_SERVER_PORT"

# Selecionar backup
if [ -z "$BACKUP_FILE" ]; then
    log "INFO" "Available backups:"
    echo ""

    if ls "$BACKUP_DIR"/*.tar.gz 1> /dev/null 2>&1; then
        BACKUPS=($(ls -t "$BACKUP_DIR"/*.tar.gz))
        for i in "${!BACKUPS[@]}"; do
            BACKUP_DATE=$(stat -c %y "${BACKUPS[$i]}" | cut -d'.' -f1)
            BACKUP_SIZE=$(du -h "${BACKUPS[$i]}" | cut -f1)
            echo "  [$i] $(basename ${BACKUPS[$i]}) - $BACKUP_DATE ($BACKUP_SIZE)"
        done
        echo ""
        read -p "$LOG_PREFIX [ INPUT ] Select backup number (0-$((${#BACKUPS[@]}-1))): " BACKUP_INDEX
        BACKUP_FILE="${BACKUPS[$BACKUP_INDEX]}"
    else
        log "FAILED" "No backups found in $BACKUP_DIR"
        log "INFO" "Please run backup-coolify.sh first to create a backup"
        exit 1
    fi
fi

if [ ! -f "$BACKUP_FILE" ]; then
    log "FAILED" "Backup file not found: $BACKUP_FILE"
    exit 1
fi
log "SUCCESS" "Selected backup: $(basename $BACKUP_FILE)"

# Extrair backup temporariamente para obter informações
TEMP_EXTRACT_DIR="/tmp/coolify-migration-$$"
mkdir -p "$TEMP_EXTRACT_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEMP_EXTRACT_DIR" --strip-components=1 2>/dev/null

# Obter APP_KEY do backup
if [ -f "$TEMP_EXTRACT_DIR/.env" ]; then
    APP_KEY=$(grep "^APP_KEY=" "$TEMP_EXTRACT_DIR/.env" | cut -d '=' -f2-)
else
    # Fallback para env atual
    APP_KEY=$(grep "^APP_KEY=" "$ENV_FILE" | cut -d '=' -f2-)
fi

if [ -z "$APP_KEY" ]; then
    log "FAILED" "APP_KEY not found in backup or current installation"
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 1
fi
log "SUCCESS" "APP_KEY retrieved from backup."

# Detectar versão do Coolify
COOLIFY_IMAGE=$(docker ps --filter "name=coolify" --format '{{.Image}}' | grep coollabsio/coolify | head -n1)
COOLIFY_VERSION="${COOLIFY_IMAGE##*:}"
log "SUCCESS" "Detected Coolify version: $COOLIFY_VERSION"

# Confirmar migração
echo ""
log "INFO" "========== MIGRATION SUMMARY =========="
echo "  Source backup: $(basename $BACKUP_FILE)"
echo "  Target server: $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_PORT"
echo "  Coolify version: $COOLIFY_VERSION"
echo "  Logs directory: $LOG_DIR"
echo "========================================"
echo ""
read -p "$LOG_PREFIX [ INPUT ] Proceed with migration? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log "INFO" "Migration cancelled by user."
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 0
fi

### ========== SSH SETUP ==========
log "INFO" "Setting up SSH connection..."

# Verificar se chave SSH existe
if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
    log "WARNING" "SSH key not found at $SSH_PRIVATE_KEY_PATH"
    read -p "$LOG_PREFIX [ INPUT ] Enter path to SSH private key: " SSH_PRIVATE_KEY_PATH

    if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
        log "FAILED" "SSH key still not found. Aborting."
        rm -rf "$TEMP_EXTRACT_DIR"
        exit 1
    fi
fi

log "INFO" "Starting ssh-agent..."
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$SSH_PRIVATE_KEY_PATH" >/dev/null 2>&1
check_success $? "SSH key added to agent."

log "INFO" "Testing SSH connection..."
ssh -o BatchMode=yes -o ConnectTimeout=10 -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" "exit" >/dev/null 2>&1
check_success $? "SSH connection successful."

log "INFO" "Establishing persistent SSH connection..."
ssh -fN -M -S "$CONTROL_SOCKET" -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>/dev/null
check_success $? "Persistent SSH connection established."

# Health check em background
(while true; do
    if ssh -S "$CONTROL_SOCKET" -O check "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>&1 | grep -q "Master running"; then
        sleep 20
    else
        log "HEALTH CHECK" "SSH connection lost."
        cleanup_and_exit 1
    fi
done) &
HEALTH_CHECK_PID=$!

### ========== INSTALL COOLIFY ON NEW SERVER ==========
log "INFO" "Installing Coolify on new server (version: $COOLIFY_VERSION)..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash -s $COOLIFY_VERSION" \
    >"$INSTALL_LOG" 2>&1

if grep -q "Your instance is ready to use" "$INSTALL_LOG"; then
    log "SUCCESS" "Coolify installed successfully on new server."
else
    log "WARNING" "Install script output unexpected. Checking if Coolify is running..."
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" "docker ps --filter name=coolify"
fi

### ========== EXTRACT AND PREPARE BACKUP ==========
log "INFO" "Preparing backup files for transfer..."

# Localizar dump do PostgreSQL no backup extraído
DB_DUMP=$(find "$TEMP_EXTRACT_DIR" -name "coolify-db-*.dmp" -type f | head -1)
if [ -z "$DB_DUMP" ]; then
    log "FAILED" "PostgreSQL dump not found in backup"
    rm -rf "$TEMP_EXTRACT_DIR"
    cleanup_and_exit 1
fi
log "SUCCESS" "Found database dump: $(basename $DB_DUMP)"

### ========== TRANSFER FILES ==========
log "INFO" "Transferring files to new server..."

# Criar diretório remoto
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "mkdir -p $REMOTE_BACKUP_DIR && rm -rf /data/coolify/ssh/keys/*"
check_success $? "Remote directories prepared."

# Transferir dump do banco
log "INFO" "Transferring database dump..."
scp -o ControlPath="$CONTROL_SOCKET" -P "$NEW_SERVER_PORT" \
    "$DB_DUMP" "$NEW_SERVER_USER@$NEW_SERVER_IP:$REMOTE_BACKUP_DIR/db-dump.dmp" >/dev/null 2>&1
check_success $? "Database dump transferred."

# Transferir SSH keys
if [ -d "$TEMP_EXTRACT_DIR/ssh-keys" ]; then
    log "INFO" "Transferring SSH keys..."
    scp -o ControlPath="$CONTROL_SOCKET" -P "$NEW_SERVER_PORT" -r \
        "$TEMP_EXTRACT_DIR/ssh-keys"/* "$NEW_SERVER_USER@$NEW_SERVER_IP:/data/coolify/ssh/keys/" >/dev/null 2>&1
    check_success $? "SSH keys transferred."
fi

# Transferir authorized_keys
if [ -f "$TEMP_EXTRACT_DIR/authorized_keys" ]; then
    log "INFO" "Appending authorized_keys to remote server..."
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "mkdir -p $(dirname $NEW_SERVER_AUTH_KEYS_FILE) && touch $NEW_SERVER_AUTH_KEYS_FILE" 2>/dev/null
    cat "$TEMP_EXTRACT_DIR/authorized_keys" | \
        ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "cat >> $NEW_SERVER_AUTH_KEYS_FILE"
    check_success $? "Authorized keys appended."
fi

# Limpar diretório temporário
rm -rf "$TEMP_EXTRACT_DIR"

### ========== STOP CONTAINERS ==========
log "INFO" "Stopping all Coolify containers except database..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "docker ps --filter name=coolify --format '{{.Names}}' | grep -v 'coolify-db' | xargs -r docker stop" >/dev/null 2>&1
check_success $? "Containers stopped."

### ========== RESTORE DATABASE ==========
log "INFO" "Restoring Coolify database (this may take a few minutes)..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "cat $REMOTE_BACKUP_DIR/db-dump.dmp | docker exec -i coolify-db pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify" \
    >"$DB_RESTORE_LOG" 2>&1

if [ $? -eq 0 ] || grep -q "processing data for table" "$DB_RESTORE_LOG"; then
    log "SUCCESS" "Database restore completed."
else
    log "WARNING" "Database restore may have encountered issues. Check $DB_RESTORE_LOG"
fi

### ========== UPDATE ENV FILE ==========
log "INFO" "Updating .env with APP_KEY from backup..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "cd /data/coolify/source && sed -i '/^APP_PREVIOUS_KEYS=/d' .env && echo 'APP_PREVIOUS_KEYS=$APP_KEY' >> .env"
check_success $? ".env file updated with APP_KEY."

### ========== FINAL INSTALL ==========
log "INFO" "Running final Coolify install to apply all changes..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash -s $COOLIFY_VERSION" \
    >"$FINAL_INSTALL_LOG" 2>&1 &

INSTALL_PID=$!

log "INFO" "Waiting for installation to complete (max 5 minutes)..."
for i in {1..30}; do
    sleep 10
    if grep -q "Your instance is ready to use" "$FINAL_INSTALL_LOG"; then
        log "SUCCESS" "Coolify installation completed successfully."
        break
    fi
    if [ $i -eq 30 ]; then
        log "WARNING" "Install script timeout. Checking container status..."
    fi
done

# Verificar status dos containers
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "docker ps --filter name=coolify --format '{{.Names}} {{.Status}}'" \
    > "$LOG_DIR/docker-status.txt"

if grep -q "coolify" "$LOG_DIR/docker-status.txt"; then
    log "SUCCESS" "Coolify containers are running."
    cat "$LOG_DIR/docker-status.txt" | while read line; do
        log "INFO" "Container: $line"
    done
else
    log "FAILED" "Coolify containers are not running properly."
    log "INFO" "Check logs in $LOG_DIR for details."
    cleanup_and_exit 1
fi

### ========== CLEANUP REMOTE BACKUP ==========
log "INFO" "Cleaning up temporary files on remote server..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "rm -rf $REMOTE_BACKUP_DIR" 2>/dev/null

### ========== FINAL SUMMARY ==========
echo ""
log "SUCCESS" "========== MIGRATION COMPLETE =========="
echo ""
echo "  🎉 Coolify has been migrated successfully!"
echo ""
echo "  📍 New server: http://$NEW_SERVER_IP:8000"
echo "  📊 Container status: See $LOG_DIR/docker-status.txt"
echo "  📋 All logs: $LOG_DIR/"
echo ""
echo "  ⚠️  NEXT STEPS:"
echo "  1. Update DNS records to point to $NEW_SERVER_IP"
echo "  2. Test Coolify access: http://$NEW_SERVER_IP:8000"
echo "  3. Verify all applications are running"
echo "  4. Configure backup scripts on new server"
echo ""
echo "========================================"
echo ""

cleanup_and_exit 0
