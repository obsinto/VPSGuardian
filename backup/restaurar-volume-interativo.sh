#!/bin/bash
################################################################################
# Script: restaurar-volume-interativo.sh
# Propósito: Restaurar volume Docker local ou remotamente (versão unificada)
# Uso: ./restaurar-volume-interativo.sh [--remote IP] [volume] [backup]
################################################################################

LOG_PREFIX="[ Restore Agent ]"

log() {
    echo "$LOG_PREFIX [ $1 ] $2"
}

################################################################################
# PARSE ARGUMENTOS
################################################################################

REMOTE_MODE=false
REMOTE_IP=""
REMOTE_USER=""
REMOTE_PORT=""
VOLUME_NAME=""
BACKUP_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --remote)
            REMOTE_MODE=true
            REMOTE_IP="$2"
            shift 2
            ;;
        *)
            if [ -z "$VOLUME_NAME" ]; then
                VOLUME_NAME="$1"
            elif [ -z "$BACKUP_FILE" ]; then
                BACKUP_FILE="$1"
            fi
            shift
            ;;
    esac
done

################################################################################
# MODO REMOTO: CONFIGURAÇÃO SSH
################################################################################

if [ "$REMOTE_MODE" = true ]; then
    log "INFO" "========== RESTAURAÇÃO REMOTA =========="
    echo ""

    if [ -z "$REMOTE_IP" ]; then
        read -p "$LOG_PREFIX [ INPUT ] Enter remote server IP: " REMOTE_IP
    fi

    read -p "$LOG_PREFIX [ INPUT ] SSH user (default: root): " REMOTE_USER
    REMOTE_USER=${REMOTE_USER:-root}

    read -p "$LOG_PREFIX [ INPUT ] SSH port (default: 22): " REMOTE_PORT
    REMOTE_PORT=${REMOTE_PORT:-22}

    log "INFO" "Testing SSH connection to $REMOTE_USER@$REMOTE_IP..."
    if ! ssh -p "$REMOTE_PORT" -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_IP" "exit" 2>/dev/null; then
        log "ERROR" "SSH connection failed to $REMOTE_IP"
        log "ERROR" "Restore Failed!"
        exit 1
    fi
    log "SUCCESS" "SSH connection established"
    echo ""
fi

################################################################################
# VOLUME NAME INPUT
################################################################################

if [ -z "$VOLUME_NAME" ]; then
    read -p "$LOG_PREFIX [ INPUT ] Enter the target Docker volume name to restore into: " VOLUME_NAME
fi

################################################################################
# VOLUME CHECK (Local ou Remoto)
################################################################################

if [ "$REMOTE_MODE" = true ]; then
    log "INFO" "Checking volume on remote server..."
    if ! ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_IP" "docker volume ls --quiet | grep -q '^$VOLUME_NAME$'" 2>/dev/null; then
        log "ERROR" "Volume '$VOLUME_NAME' doesn't exist on remote server."

        read -p "$LOG_PREFIX [ INPUT ] Do you want to create a new volume with the name '$VOLUME_NAME'? (y/N): " create_volume
        if [[ "$create_volume" == "y" ]]; then
            log "INFO" "Creating volume '$VOLUME_NAME' on remote server..."
            ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_IP" "docker volume create $VOLUME_NAME" || {
                log "ERROR" "Failed to create volume '$VOLUME_NAME' on remote server"
                log "ERROR" "Restore Failed!"
                exit 1
            }
            log "INFO" "Volume '$VOLUME_NAME' created successfully on remote server."
        else
            log "INFO" "Volume '$VOLUME_NAME' doesn't exist and user opted not to create it. Aborting restore."
            log "ERROR" "Restore Failed!"
            exit 1
        fi
    else
        log "INFO" "Volume '$VOLUME_NAME' exists on remote server, continuing..."
    fi
else
    # Verificar volume localmente
    if ! docker volume ls --quiet | grep -q "^$VOLUME_NAME$"; then
        log "ERROR" "Volume '$VOLUME_NAME' doesn't exist."

        read -p "$LOG_PREFIX [ INPUT ] Do you want to create a new volume with the name '$VOLUME_NAME'? (y/N): " create_volume
        if [[ "$create_volume" == "y" ]]; then
            log "INFO" "Creating volume '$VOLUME_NAME'..."
            docker volume create "$VOLUME_NAME" || {
                log "ERROR" "Failed to create volume '$VOLUME_NAME', aborting restore."
                log "ERROR" "Restore Failed!"
                exit 1
            }
            log "INFO" "Volume '$VOLUME_NAME' created successfully."
        else
            log "INFO" "Volume '$VOLUME_NAME' doesn't exist and user opted not to create it. Aborting restore."
            log "ERROR" "Restore Failed!"
            exit 1
        fi
    else
        log "INFO" "Volume '$VOLUME_NAME' exists, continuing..."
    fi
fi

################################################################################
# BACKUP SELECTION
################################################################################

if [ -z "$BACKUP_FILE" ]; then
    BACKUP_DIR="/root/volume-backups"

    log "INFO" "Available backups in $BACKUP_DIR:"
    echo ""

    if [ ! -d "$BACKUP_DIR" ]; then
        log "ERROR" "Backup directory not found: $BACKUP_DIR"
        log "ERROR" "Restore Failed!"
        exit 1
    fi

    BACKUPS=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))

    if [ ${#BACKUPS[@]} -eq 0 ]; then
        log "ERROR" "No backup files found in $BACKUP_DIR"
        log "ERROR" "Restore Failed!"
        exit 1
    fi

    for i in "${!BACKUPS[@]}"; do
        BACKUP_NAME=$(basename "${BACKUPS[$i]}")
        BACKUP_SIZE=$(du -h "${BACKUPS[$i]}" | cut -f1)
        BACKUP_DATE=$(stat -c %y "${BACKUPS[$i]}" 2>/dev/null || stat -f %Sm "${BACKUPS[$i]}" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo "  [$i] $BACKUP_NAME"
        echo "      Date: $BACKUP_DATE"
        echo "      Size: $BACKUP_SIZE"
        echo ""
    done

    read -p "$LOG_PREFIX [ INPUT ] Select backup number: " BACKUP_INDEX

    if [ -z "$BACKUP_INDEX" ] || [ "$BACKUP_INDEX" -ge "${#BACKUPS[@]}" ]; then
        log "ERROR" "Invalid backup selection"
        log "ERROR" "Restore Failed!"
        exit 1
    fi

    BACKUP_FILE="${BACKUPS[$BACKUP_INDEX]}"
fi

# Verificar se backup existe
if [ ! -f "$BACKUP_FILE" ]; then
    log "ERROR" "Backup file not found: $BACKUP_FILE"
    log "ERROR" "Restore Failed!"
    exit 1
fi

BACKUP_FILENAME=$(basename "$BACKUP_FILE")
log "INFO" "Backup file '$BACKUP_FILENAME' found, continuing..."
echo ""

################################################################################
# SAFETY CONFIRMATION
################################################################################

log "INFO" "Make sure containers using '$VOLUME_NAME' are stopped!"
if [ "$REMOTE_MODE" = true ]; then
    log "INFO" "Restoration will be performed on remote server: $REMOTE_IP"
fi
echo ""
log "INFO" "Volume: $VOLUME_NAME"
log "INFO" "Backup: $BACKUP_FILENAME"
echo ""

read -p "$LOG_PREFIX [ INPUT ] Proceed with restore? (y/N): " confirm
if [[ "$confirm" != "y" ]]; then
    log "ERROR" "Restore Failed: cancelled by user."
    exit 1
fi

################################################################################
# RESTORE START
################################################################################

log "INFO" "Restoring $BACKUP_FILENAME into volume: $VOLUME_NAME"
echo ""

if [ "$REMOTE_MODE" = true ]; then
    ################################################################################
    # RESTAURAÇÃO REMOTA
    ################################################################################

    log "INFO" "Transferring backup to remote server..."

    REMOTE_BACKUP_DIR="/tmp/restore-$(date +%s)"
    ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_IP" "mkdir -p $REMOTE_BACKUP_DIR"

    if scp -P "$REMOTE_PORT" "$BACKUP_FILE" "$REMOTE_USER@$REMOTE_IP:$REMOTE_BACKUP_DIR/"; then
        log "SUCCESS" "Backup transferred successfully"
    else
        log "ERROR" "Failed to transfer backup to remote server"
        log "ERROR" "Restore Failed!"
        exit 1
    fi

    log "INFO" "Executing restore on remote server..."

    if ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_IP" \
        "docker run --rm \
            -v '$VOLUME_NAME':/volume \
            -v '$REMOTE_BACKUP_DIR':/backup \
            busybox \
            sh -c 'cd /volume && tar xzf /backup/$BACKUP_FILENAME'"; then

        log "SUCCESS" "Restore completed on remote server!"

        # Verificar restauração
        log "INFO" "Verifying restored data..."
        FILE_COUNT=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_IP" \
            "docker run --rm -v '$VOLUME_NAME':/volume busybox find /volume -type f | wc -l")
        TOTAL_SIZE=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_IP" \
            "docker run --rm -v '$VOLUME_NAME':/volume busybox du -sh /volume | cut -f1")

        log "SUCCESS" "Files restored: $FILE_COUNT"
        log "SUCCESS" "Total size: $TOTAL_SIZE"

        # Limpar arquivo temporário
        log "INFO" "Cleaning up temporary files on remote server..."
        ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_IP" "rm -rf $REMOTE_BACKUP_DIR"

    else
        log "ERROR" "Docker restore process failed on remote server"
        ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_IP" "rm -rf $REMOTE_BACKUP_DIR"
        log "ERROR" "Restore Failed!"
        exit 1
    fi

else
    ################################################################################
    # RESTAURAÇÃO LOCAL
    ################################################################################

    BACKUP_DIR_ABS=$(cd "$(dirname "$BACKUP_FILE")" && pwd)

    docker run --rm \
        -v "$VOLUME_NAME":/volume \
        -v "$BACKUP_DIR_ABS":/backup \
        busybox \
        sh -c "cd /volume && tar xzf /backup/$BACKUP_FILENAME" || {
        log "ERROR" "Docker restore process failed, aborting."
        log "ERROR" "Restore Failed!"
        exit 1
    }

    log "SUCCESS" "Restore completed!"

    # Verificar restauração
    log "INFO" "Verifying restored data..."
    FILE_COUNT=$(docker run --rm -v "$VOLUME_NAME":/volume busybox find /volume -type f | wc -l)
    TOTAL_SIZE=$(docker run --rm -v "$VOLUME_NAME":/volume busybox du -sh /volume | cut -f1)

    log "SUCCESS" "Files restored: $FILE_COUNT"
    log "SUCCESS" "Total size: $TOTAL_SIZE"

    # Perguntar se deseja listar arquivos
    echo ""
    read -p "$LOG_PREFIX [ INPUT ] Do you want to list the restored files? (y/N): " SHOW_FILES

    if [ "$SHOW_FILES" = "y" ]; then
        echo ""
        log "INFO" "Contents of volume '$VOLUME_NAME':"
        docker run --rm -v "$VOLUME_NAME":/volume busybox ls -lah /volume
    fi
fi

echo ""
log "SUCCESS" "========== RESTORE COMPLETED SUCCESSFULLY =========="
