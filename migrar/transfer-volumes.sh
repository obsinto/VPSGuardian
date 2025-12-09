#!/bin/bash
################################################################################
# Script: transfer-volumes.sh
# Propósito: Transferir backups de volumes para servidor remoto
# Uso: ./transfer-volumes.sh [--config=FILE] [--auto]
################################################################################

# Carregar bibliotecas compartilhadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

### ========== CONFIGURAÇÃO PADRÃO ==========
SSH_IP="${SSH_IP:-}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-/root/.ssh/id_rsa}"
SOURCE_PATH="${SOURCE_PATH:-./volume-backup}"
DESTINATION_PATH="${DESTINATION_PATH:-/root/backups/volume-backup}"
MAX_RETRIES=3
AUTO_MODE=false

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
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --config=FILE    Load configuration from file"
            echo "  --auto           Run in automatic mode"
            echo "  -h, --help       Show this help"
            echo ""
            echo "Configuration file format:"
            echo "  SSH_IP=\"192.168.1.100\""
            echo "  SSH_USER=\"root\""
            echo "  SSH_PORT=\"22\""
            echo "  SSH_KEY=\"/root/.ssh/id_rsa\""
            echo "  SOURCE_PATH=\"./volume-backup\""
            echo "  DESTINATION_PATH=\"/root/backups/volume-backup\""
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Carregar arquivo de configuração
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    log_info "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
fi

### ========== MAIN ==========
log_section "VPS Guardian - Transferência de Volumes"

# Validar configurações
if [ -z "$SSH_IP" ]; then
    if [ "$AUTO_MODE" = true ]; then
        log_error "SSH_IP is required in automatic mode"
        exit 1
    fi
    read -p "Enter destination server IP: " SSH_IP
fi

if [ -z "$SSH_IP" ]; then
    log_error "Server IP is required"
    exit 1
fi

log_info "Destination: $SSH_USER@$SSH_IP:$SSH_PORT"

# Verificar diretório de origem
if [ ! -d "$SOURCE_PATH" ]; then
    log_error "Source directory not found: $SOURCE_PATH"
    exit 1
fi

# Contar arquivos de backup
backup_count=$(find "$SOURCE_PATH" -name "*-backup-*.tar.gz" -type f | wc -l)

if [ "$backup_count" -eq 0 ]; then
    log_error "No backup files found in $SOURCE_PATH"
    log_info "Run backup-volumes.sh first"
    exit 1
fi

log_success "Found $backup_count backup files"

# Calcular tamanho total
total_size=$(du -sh "$SOURCE_PATH" | cut -f1)
log_info "Total size: $total_size"

# Confirmar transferência
if [ "$AUTO_MODE" = false ]; then
    echo ""
    read -p "Transfer all backups to $SSH_IP? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "Transfer cancelled"
        exit 0
    fi
fi

# Verificar chave SSH
if [ ! -f "$SSH_KEY" ]; then
    log_error "SSH key not found: $SSH_KEY"
    exit 1
fi

# Testar conexão SSH
log_info "Testing SSH connection..."
ssh -i "$SSH_KEY" -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=10 \
    "$SSH_USER@$SSH_IP" "exit" >/dev/null 2>&1

if [ $? -ne 0 ]; then
    log_error "SSH connection failed"
    log_info "Check SSH_KEY, SSH_IP, SSH_USER, SSH_PORT"
    exit 1
fi

log_success "SSH connection successful"

# Criar diretório de destino
log_info "Creating destination directory..."
ssh -i "$SSH_KEY" -p "$SSH_PORT" "$SSH_USER@$SSH_IP" \
    "mkdir -p $DESTINATION_PATH" 2>/dev/null

# Transferir arquivos com retry
log_section "Transfer"

transferred=0
failed=0

for backup_file in "$SOURCE_PATH"/*-backup-*.tar.gz; do
    if [ ! -f "$backup_file" ]; then
        continue
    fi

    filename=$(basename "$backup_file")
    filesize=$(du -h "$backup_file" | cut -f1)

    log_info "Transferring: $filename ($filesize)"

    retry=0
    success=false

    while [ $retry -lt $MAX_RETRIES ]; do
        scp -i "$SSH_KEY" -P "$SSH_PORT" -q \
            "$backup_file" "$SSH_USER@$SSH_IP:$DESTINATION_PATH/" 2>/dev/null

        if [ $? -eq 0 ]; then
            log_success "  ✓ Transferred successfully"
            ((transferred++))
            success=true
            break
        else
            ((retry++))
            if [ $retry -lt $MAX_RETRIES ]; then
                log_warning "  Retry $retry/$MAX_RETRIES..."
                sleep 2
            fi
        fi
    done

    if [ "$success" = false ]; then
        log_error "  ✗ Transfer failed after $MAX_RETRIES attempts"
        ((failed++))
    fi
done

# Resumo
echo ""
log_section "TRANSFER SUMMARY"
echo "  ✅ Transferred: $transferred files"
if [ $failed -gt 0 ]; then
    echo "  ❌ Failed: $failed files"
fi
echo "  📁 Destination: $SSH_USER@$SSH_IP:$DESTINATION_PATH"
echo ""

if [ $failed -eq 0 ]; then
    log_success "All backups transferred successfully"
    exit 0
else
    log_error "Some transfers failed"
    exit 1
fi
