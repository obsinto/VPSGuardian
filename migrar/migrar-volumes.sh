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

# Cores para melhor visualização
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo "$LOG_PREFIX [ $1 ] $2" | tee -a "$AGENT_LOG"
}

log_info() {
    echo -e "${BLUE}$LOG_PREFIX${NC} [ INFO ] $1" | tee -a "$AGENT_LOG"
}

log_success() {
    echo -e "${GREEN}$LOG_PREFIX${NC} [ ✓ ] $1" | tee -a "$AGENT_LOG"
}

log_error() {
    echo -e "${RED}$LOG_PREFIX${NC} [ ✗ ] $1" | tee -a "$AGENT_LOG"
}

log_warning() {
    echo -e "${YELLOW}$LOG_PREFIX${NC} [ ⚠ ] $1" | tee -a "$AGENT_LOG"
}

log_section() {
    echo "" | tee -a "$AGENT_LOG"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}" | tee -a "$AGENT_LOG"
    echo -e "${CYAN}  $1${NC}" | tee -a "$AGENT_LOG"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}" | tee -a "$AGENT_LOG"
    echo "" | tee -a "$AGENT_LOG"
}

check_success() {
    if [ $1 -eq 0 ]; then
        log_success "$2"
    else
        log_error "$2"
        cleanup_and_exit 1
    fi
}

cleanup_and_exit() {
    if [ $1 -eq 0 ]; then
        log_success "Volume migration completed successfully."
    else
        log_error "Volume migration failed."
    fi

    # Só fechar conexão SSH se foi criada por este script (não herdada)
    if [ "$SSH_REUSED" != "true" ]; then
        log_info "Cleaning up SSH connection..."
        ssh -S "$CONTROL_SOCKET" -O exit "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>/dev/null || true
        rm -f "$CONTROL_SOCKET"
    else
        log_info "Keeping SSH connection for parent script."
    fi

    exit $1
}

trap cleanup_and_exit SIGINT SIGTERM

### ========== APRESENTAÇÃO ==========

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}          ${GREEN}🚀 DOCKER VOLUME MIGRATION AGENT 🚀${NC}              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

### ========== PROMPTS INTERATIVOS ==========

log_section "SERVER CONFIGURATION"

if [ -z "$NEW_SERVER_IP" ]; then
    echo -e "${BLUE}Enter destination server details:${NC}"
    echo ""
    read -p "  New server IP address: " NEW_SERVER_IP
fi
log_success "Target server: $NEW_SERVER_IP"

if [ -z "$NEW_SERVER_USER" ] || [ "$NEW_SERVER_USER" = "root" ]; then
    read -p "  SSH user (default: root): " INPUT_USER
    NEW_SERVER_USER=${INPUT_USER:-root}
fi
log_info "SSH user: $NEW_SERVER_USER"

if [ -z "$NEW_SERVER_PORT" ] || [ "$NEW_SERVER_PORT" = "22" ]; then
    read -p "  SSH port (default: 22): " INPUT_PORT
    NEW_SERVER_PORT=${INPUT_PORT:-22}
fi
log_info "SSH port: $NEW_SERVER_PORT"

# SEMPRE criar backups fresh na execução
log_section "CREATING FRESH VOLUME BACKUPS"
log_info "Creating fresh backups of all Docker volumes..."

# Contar volumes reais no Docker
DOCKER_VOLUMES_COUNT=$(docker volume ls --quiet | wc -l)
log_info "Docker volumes found: $DOCKER_VOLUMES_COUNT"

if [ $DOCKER_VOLUMES_COUNT -eq 0 ]; then
    log_error "No Docker volumes found to backup."
    exit 1
fi

# Criar diretório de backup
mkdir -p "$LOCAL_BACKUP_DIR"

# Verificar se script de backup existe
BACKUP_SCRIPT="$(dirname "$0")/backup-volumes.sh"

if [ ! -f "$BACKUP_SCRIPT" ]; then
    log_error "Backup script not found: $BACKUP_SCRIPT"
    echo ""
    echo "  Expected location: $BACKUP_SCRIPT"
    echo ""
    exit 1
fi

if [ ! -x "$BACKUP_SCRIPT" ]; then
    chmod +x "$BACKUP_SCRIPT"
fi

log_info "Launching backup script..."
echo ""

# Executar backup-volumes.sh em modo all
"$BACKUP_SCRIPT" --all --output="$LOCAL_BACKUP_DIR"

BACKUP_EXIT_CODE=$?

if [ $BACKUP_EXIT_CODE -ne 0 ]; then
    log_error "Backup creation failed with code: $BACKUP_EXIT_CODE"
    echo ""
    echo "  Please fix the errors and try again."
    exit 1
fi

echo ""
log_success "Fresh backups created successfully!"
echo ""

# Validar contagem de backups criados (ignorar symlinks -latest)
BACKUP_FILES_COUNT=$(ls -1 "$LOCAL_BACKUP_DIR"/*-backup-*.tar.gz 2>/dev/null | grep -v "\-latest\.tar\.gz$" | wc -l)

log_section "BACKUP VALIDATION"
echo "  Docker volumes in origin: $DOCKER_VOLUMES_COUNT"
echo "  Backup files created: $BACKUP_FILES_COUNT"
echo ""

if [ $BACKUP_FILES_COUNT -ne $DOCKER_VOLUMES_COUNT ]; then
    log_error "Mismatch detected!"
    log_error "Expected $DOCKER_VOLUMES_COUNT backups, but found $BACKUP_FILES_COUNT"
    echo ""
    echo "  This could mean:"
    echo "    - Some volumes failed to backup"
    echo "    - Permission issues accessing volumes"
    echo ""
    read -p "  Continue anyway? (yes/no): " CONTINUE_ANYWAY
    if [ "$CONTINUE_ANYWAY" != "yes" ]; then
        log_info "Migration aborted by user."
        exit 1
    fi
else
    log_success "Validation passed! All volumes backed up successfully."
fi

echo ""
log_info "Available volume backups:"
echo ""

# Listar apenas backups reais (sem symlinks -latest)
BACKUPS=($(ls -t "$LOCAL_BACKUP_DIR"/*-backup-*.tar.gz 2>/dev/null | grep -v "\-latest\.tar\.gz$"))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    log_error "No backup files found after check"
    exit 1
fi

VOLUMES_TO_MIGRATE=()

for i in "${!BACKUPS[@]}"; do
    BACKUP_FILE="${BACKUPS[$i]}"
    BACKUP_DATE=$(stat -c %y "$BACKUP_FILE" | cut -d'.' -f1)
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    # Extrair nome do volume removendo -backup-TIMESTAMP.tar.gz
    VOLUME_NAME=$(basename "$BACKUP_FILE" | sed 's/-backup-[0-9_]*\.tar\.gz$//')

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
    log_info "Migration cancelled by user."
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
        # Extrair nome do volume removendo -backup-TIMESTAMP.tar.gz
        VOLUME_NAME=$(basename "${BACKUPS[$idx]}" | sed 's/-backup-[0-9_]*\.tar\.gz$//')
        VOLUMES_TO_MIGRATE+=("$VOLUME_NAME")
    fi
done

if [ ${#SELECTED_BACKUPS[@]} -eq 0 ]; then
    log_error "No valid volumes selected."
    exit 1
fi

# Confirmar migração
echo ""
log_info "========== MIGRATION SUMMARY =========="
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
    log_info "Migration cancelled by user."
    exit 0
fi

### ========== SSH SETUP ==========
log_info "Setting up SSH connection..."

# Verificar se já existe uma conexão SSH ativa (herdada de migrar-coolify.sh)
SSH_REUSED=false
if [ -n "$CONTROL_SOCKET" ] && [ -S "$CONTROL_SOCKET" ]; then
    log_info "Checking existing SSH connection..."
    if ssh -S "$CONTROL_SOCKET" -O check "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>/dev/null; then
        log_success "Reusing existing SSH connection from Coolify migration."
        SSH_REUSED=true
    else
        log_warning "Existing SSH connection is not active, creating new one..."
        CONTROL_SOCKET="/tmp/ssh_mux_volumes_$$"
    fi
else
    # Se não existe, criar novo CONTROL_SOCKET
    CONTROL_SOCKET="/tmp/ssh_mux_volumes_$$"
fi

# Se não está reutilizando conexão, configurar nova
if [ "$SSH_REUSED" = false ]; then
    # Verificar chave SSH
    if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
        log_warning "SSH key not found at $SSH_PRIVATE_KEY_PATH"
        read -p "$LOG_PREFIX [ INPUT ] Enter path to SSH private key: " SSH_PRIVATE_KEY_PATH

        if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
            log_error "SSH key not found. Aborting."
            exit 1
        fi
    fi

    log_info "Starting ssh-agent..."
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$SSH_PRIVATE_KEY_PATH" >/dev/null 2>&1
    check_success $? "SSH key added to agent."

    log_info "Testing SSH connection..."
    ssh -o BatchMode=yes -o ConnectTimeout=10 -p "$NEW_SERVER_PORT" \
        "$NEW_SERVER_USER@$NEW_SERVER_IP" "exit" >/dev/null 2>&1
    check_success $? "SSH connection successful."

    log_info "Establishing persistent SSH connection..."
    ssh -fN -M -S "$CONTROL_SOCKET" -p "$NEW_SERVER_PORT" \
        "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>/dev/null
    check_success $? "Persistent SSH connection established."
fi

### ========== VERIFICAR DOCKER NO SERVIDOR REMOTO ==========
log_info "Checking if Docker is installed on remote server..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "command -v docker >/dev/null 2>&1"
check_success $? "Docker is installed on remote server."

### ========== PREPARAR SERVIDOR REMOTO ==========
log_info "Preparing remote server..."
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
    log_info "========== Migrating volume $((i+1))/${#SELECTED_BACKUPS[@]}: $VOLUME_NAME =========="

    # 1. Transferir backup
    log_info "Transferring backup: $BACKUP_FILENAME..."
    scp -o ControlPath="$CONTROL_SOCKET" -P "$NEW_SERVER_PORT" \
        "$BACKUP_FILE" "$NEW_SERVER_USER@$NEW_SERVER_IP:$REMOTE_BACKUP_DIR/" >/dev/null 2>&1

    if [ $? -ne 0 ]; then
        log_error "Failed to transfer backup for $VOLUME_NAME"
        ((FAILED_COUNT++))
        continue
    fi
    log_success "Backup transferred."

    # 2. Criar volume no servidor remoto (se não existir)
    log_info "Creating volume '$VOLUME_NAME' on remote server..."
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "docker volume create $VOLUME_NAME" >/dev/null 2>&1
    log_success "Volume created or already exists."

    # 3. Restaurar volume
    log_info "Restoring volume data..."
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "docker run --rm -v $VOLUME_NAME:/volume -v $REMOTE_BACKUP_DIR:/backup busybox sh -c 'cd /volume && tar xzf /backup/$BACKUP_FILENAME'" 2>/dev/null

    if [ $? -eq 0 ]; then
        log_success "Volume '$VOLUME_NAME' restored successfully."
        ((MIGRATED_COUNT++))

        # Verificar conteúdo
        FILES_COUNT=$(ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "docker run --rm -v $VOLUME_NAME:/volume busybox find /volume -type f" 2>/dev/null | wc -l)
        log_info "Files restored: $FILES_COUNT"
    else
        log_error "Failed to restore volume '$VOLUME_NAME'"
        ((FAILED_COUNT++))
    fi
done

### ========== CLEANUP REMOTE BACKUPS ==========
echo ""
log_info "Cleaning up temporary backups on remote server..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "rm -rf $REMOTE_BACKUP_DIR" 2>/dev/null
log_success "Remote cleanup complete."

### ========== CLEANUP LOCAL BACKUPS ==========
echo ""
log_warning "Cleaning up local backups..."
echo ""
echo "  Local backup directory: $LOCAL_BACKUP_DIR"
echo "  Space used: $(du -sh "$LOCAL_BACKUP_DIR" | cut -f1)"
echo ""
read -p "  Delete local backups to free space? (yes/no): " DELETE_LOCAL

if [ "$DELETE_LOCAL" = "yes" ]; then
    log_info "Deleting local backups..."
    rm -rf "$LOCAL_BACKUP_DIR"
    log_success "Local backups deleted successfully."
else
    log_info "Local backups preserved at: $LOCAL_BACKUP_DIR"
    echo ""
    echo "  To clean up later, run:"
    echo "    rm -rf $LOCAL_BACKUP_DIR"
    echo ""
    echo "  Or use the maintenance menu:"
    echo "    vps-guardian"
    echo "    → Manutenção → Limpar backups antigos"
    echo ""
fi

### ========== FINAL SUMMARY ==========
echo ""
log_info "========== MIGRATION SUMMARY =========="
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
