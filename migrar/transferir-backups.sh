#!/bin/bash
################################################################################
# Script: transferir-backups.sh
# Propósito: Transferir backups para servidor remoto (com ou sem chave SSH)
# Uso: ./transferir-backups.sh
################################################################################

### ========== CONFIGURAÇÃO ==========

SSH_PORT=""
SSH_USER=""
SSH_IP=""
SSH_KEY="$HOME/.ssh/id_rsa"
SOURCE_PATH="/root/coolify-backups"
DESTINATION_PATH="/root/backups-received"
MAX_RETRIES=3

### ========== NÃO EDITAR ABAIXO DESTA LINHA ==========

LOG_PREFIX="[ Transfer Agent ]"

log() {
    echo "$LOG_PREFIX [ $1 ] $2"
}

### ========== PROMPTS ==========

if [ -z "$SSH_IP" ]; then
    read -p "$LOG_PREFIX [ INPUT ] Enter remote server IP: " SSH_IP
fi

if [ -z "$SSH_USER" ]; then
    read -p "$LOG_PREFIX [ INPUT ] Enter SSH user (default: root): " SSH_USER
    SSH_USER=${SSH_USER:-root}
fi

if [ -z "$SSH_PORT" ]; then
    read -p "$LOG_PREFIX [ INPUT ] Enter SSH port (default: 22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}
fi

log_info "Transfer configuration:"
echo "  From: $SOURCE_PATH"
echo "  To: $SSH_USER@$SSH_IP:$DESTINATION_PATH"
echo "  Port: $SSH_PORT"
echo ""

# Verificar se origem existe
if [ ! -d "$SOURCE_PATH" ]; then
    log_error "Source directory not found: $SOURCE_PATH"
    exit 1
fi

# Contar arquivos
FILE_COUNT=$(find "$SOURCE_PATH" -type f -name "*.tar.gz" | wc -l)
if [ $FILE_COUNT -eq 0 ]; then
    log_error "No backup files found in $SOURCE_PATH"
    exit 1
fi

TOTAL_SIZE=$(du -sh "$SOURCE_PATH" | cut -f1)
log_info "Found $FILE_COUNT backup file(s), total size: $TOTAL_SIZE"
echo ""

read -p "$LOG_PREFIX [ INPUT ] Proceed with transfer? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    log_info "Transfer cancelled."
    exit 0
fi

### ========== AUTHENTICATION ==========

USING_KEY=false

# Tentar autenticação com chave SSH
if [ -f "$SSH_KEY" ]; then
    log_info "Trying SSH key authentication: $SSH_KEY"
    ssh -i "$SSH_KEY" -o BatchMode=yes -o ConnectTimeout=10 -p "$SSH_PORT" \
        "$SSH_USER@$SSH_IP" exit >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_success "SSH key authentication successful!"
        USING_KEY=true
    else
        log_warning "SSH key authentication failed."
    fi
fi

# Fallback para senha se chave falhar
if [ "$USING_KEY" = false ]; then
    log_info "Falling back to password authentication."

    # Verificar se expect está instalado
    if ! command -v expect >/dev/null 2>&1; then
        log_error "Package 'expect' is required for password authentication."
        log_info "Install it with: sudo apt install expect"
        exit 1
    fi

    # Solicitar senha
    retries=0
    while [ $retries -lt $MAX_RETRIES ]; do
        read -s -p "$LOG_PREFIX [ INPUT ] Enter SSH password for $SSH_USER@$SSH_IP: " SSHPASS
        echo ""

        # Testar senha
        expect -c "
            log_user 0
            set timeout 15
            spawn ssh -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_IP exit
            expect {
                \"*?assword:\" {
                    send -- \"$SSHPASS\r\"
                    expect {
                        \"Permission denied\" { exit 1 }
                        eof { exit [lindex [wait] 3] }
                    }
                }
                eof { exit [lindex [wait] 3] }
            }
        " >/dev/null 2>&1

        if [ $? -eq 0 ]; then
            log_success "Password authentication successful!"
            break
        else
            log_error "Invalid password. Please try again."
            retries=$((retries + 1))
        fi
    done

    if [ $retries -eq $MAX_RETRIES ]; then
        log_error "Maximum password attempts reached. Aborting."
        exit 1
    fi
fi

### ========== PREPARE REMOTE DIRECTORY ==========

log_info "Preparing remote directory: $DESTINATION_PATH"

if [ "$USING_KEY" = true ]; then
    ssh -i "$SSH_KEY" -p "$SSH_PORT" "$SSH_USER@$SSH_IP" \
        "mkdir -p $DESTINATION_PATH" >/dev/null 2>&1
    PREP_RC=$?
else
    expect -c "
        log_user 0
        set timeout 10
        spawn ssh -o StrictHostKeyChecking=no -p $SSH_PORT $SSH_USER@$SSH_IP mkdir -p $DESTINATION_PATH
        expect {
            \"*?assword:\" { send -- \"$SSHPASS\r\"; exp_continue }
            eof { exit [lindex [wait] 3] }
        }
    " >/dev/null 2>&1
    PREP_RC=$?
fi

if [ $PREP_RC -ne 0 ]; then
    log_error "Failed to create remote directory."
    exit 1
fi

log_success "Remote directory ready."

### ========== TRANSFER FILES ==========

log_info "Starting file transfer..."
echo ""

SCP_LOG="/tmp/scp-transfer-$$.log"

if [ "$USING_KEY" = true ]; then
    # Transferência com chave SSH (com progresso)
    scp -i "$SSH_KEY" -P "$SSH_PORT" -r "$SOURCE_PATH"/. \
        "$SSH_USER@$SSH_IP:$DESTINATION_PATH" 2> "$SCP_LOG"
    SCP_RC=$?
else
    # Transferência com senha (usando expect)
    expect -c "
        log_user 1
        set timeout -1
        spawn scp -o StrictHostKeyChecking=no -P $SSH_PORT -r $SOURCE_PATH/. $SSH_USER@$SSH_IP:$DESTINATION_PATH
        expect {
            \"*?assword:\" { send -- \"$SSHPASS\r\"; exp_continue }
            eof { exit [lindex [wait] 3] }
        }
    " 2> "$SCP_LOG"
    SCP_RC=$?
fi

echo ""

if [ $SCP_RC -eq 0 ]; then
    log_success "Transfer completed successfully!"
    echo ""
    log_info "Transferred: $FILE_COUNT file(s) ($TOTAL_SIZE)"
    log_info "Destination: $SSH_USER@$SSH_IP:$DESTINATION_PATH"
    rm -f "$SCP_LOG"
    exit 0
else
    log_error "Transfer failed!"
    echo ""
    log_info "Error details:"
    while IFS= read -r line; do
        echo "  $line"
    done < "$SCP_LOG"
    rm -f "$SCP_LOG"
    exit 1
fi
