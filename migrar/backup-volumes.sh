#!/bin/bash
################################################################################
# Script: backup-volumes.sh
# Propósito: Fazer backup de volumes Docker (aplicações Coolify)
# Uso: ./backup-volumes.sh [--volume=NOME] [--all] [--output=DIR]
################################################################################

# Carregar bibliotecas compartilhadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

### ========== CONFIGURAÇÃO ==========
BACKUP_OUTPUT_DIR="${BACKUP_OUTPUT_DIR:-./volume-backup}"
VOLUME_NAME="${VOLUME_NAME:-}"
BACKUP_ALL=false

# Criar Batch ID único para esta execução de backup
BATCH_ID=$(date +%Y%m%d_%H%M%S)

### ========== PARSE ARGUMENTOS ==========
while [[ $# -gt 0 ]]; do
    case $1 in
        --volume=*)
            VOLUME_NAME="${1#*=}"
            shift
            ;;
        --all)
            BACKUP_ALL=true
            shift
            ;;
        --output=*)
            BACKUP_OUTPUT_DIR="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --volume=NAME    Backup specific volume"
            echo "  --all            Backup all volumes"
            echo "  --output=DIR     Output directory (default: ./volume-backup)"
            echo "  -h, --help       Show this help"
            echo ""
            echo "Interactive mode if no options provided."
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

### ========== FUNÇÕES ==========

list_volumes() {
    docker volume ls --format "{{.Name}}" 2>/dev/null
}

create_batch_metadata() {
    local output_dir="$1"
    local batch_id="$2"
    local volume_count="$3"
    local success_count="$4"

    local metadata_file="$output_dir/.batch-${batch_id}.meta"

    cat > "$metadata_file" <<EOF
BATCH_ID=$batch_id
CREATED="$(date '+%Y-%m-%d %H:%M:%S')"
TOTAL_VOLUMES=$volume_count
SUCCESSFUL_BACKUPS=$success_count
HOSTNAME=$(hostname)
DOCKER_VERSION="$(docker --version 2>/dev/null || echo "N/A")"
EOF

    log_info "Batch metadata criado: .batch-${batch_id}.meta"
}

backup_volume() {
    local volume_name="$1"
    local output_dir="$2"
    local batch_id="${3:-$BATCH_ID}"  # Usar BATCH_ID global se não fornecido

    # Verificar se volume existe
    if ! docker volume inspect "$volume_name" >/dev/null 2>&1; then
        log_error "Volume não encontrado: $volume_name"
        return 1
    fi

    # Criar diretório de output
    ensure_directory "$output_dir" 755

    log_info "Backing up volume: $volume_name"

    # Criar backup usando container temporário com BATCH_ID no nome
    local backup_filename="${volume_name}-backup-${batch_id}.tar.gz"

    docker run --rm \
        -v "$volume_name":/source:ro \
        -v "$output_dir":/backup \
        busybox \
        tar -czf "/backup/${backup_filename}" -C /source . \
        >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        local size=$(du -h "$output_dir/${backup_filename}" | cut -f1)
        log_success "Backup criado: ${backup_filename} ($size)"

        # Criar symlink para o mais recente
        ln -sf "${backup_filename}" "$output_dir/${volume_name}-backup-latest.tar.gz"

        return 0
    else
        log_error "Falha ao criar backup de $volume_name"
        return 1
    fi
}

### ========== MAIN ==========
log_section "VPS Guardian - Backup de Volumes Docker"

# Modo: Backup todos os volumes
if [ "$BACKUP_ALL" = true ]; then
    log_info "Modo: Backup de TODOS os volumes"
    log_info "Batch ID: $BATCH_ID"

    volumes=($(list_volumes))

    if [ ${#volumes[@]} -eq 0 ]; then
        log_warning "Nenhum volume Docker encontrado"
        exit 0
    fi

    log_info "Encontrados ${#volumes[@]} volumes"
    echo ""

    success_count=0
    fail_count=0

    for volume in "${volumes[@]}"; do
        if backup_volume "$volume" "$BACKUP_OUTPUT_DIR" "$BATCH_ID"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done

    # Criar metadata do batch
    create_batch_metadata "$BACKUP_OUTPUT_DIR" "$BATCH_ID" "${#volumes[@]}" "$success_count"

    echo ""
    log_section "RESUMO"
    echo "  🆔 Batch ID: $BATCH_ID"
    echo "  ✅ Sucesso: $success_count volumes"
    if [ $fail_count -gt 0 ]; then
        echo "  ❌ Falha: $fail_count volumes"
    fi
    echo "  📁 Diretório: $BACKUP_OUTPUT_DIR"
    echo ""

    exit 0
fi

# Modo: Backup de volume específico
if [ -n "$VOLUME_NAME" ]; then
    backup_volume "$VOLUME_NAME" "$BACKUP_OUTPUT_DIR"
    exit $?
fi

# Modo: Interativo
echo ""
log_info "Volumes Docker disponíveis:"
echo ""

volumes=($(list_volumes))

if [ ${#volumes[@]} -eq 0 ]; then
    log_warning "Nenhum volume Docker encontrado"
    exit 0
fi

# Listar volumes com informações
for i in "${!volumes[@]}"; do
    volume_name="${volumes[$i]}"

    # Obter informações do volume
    volume_info=$(docker volume inspect "$volume_name" 2>/dev/null | grep -E '"Mountpoint"|"Driver"')
    mountpoint=$(echo "$volume_info" | grep Mountpoint | cut -d'"' -f4)

    # Tentar estimar tamanho (pode falhar se sem permissão)
    size="N/A"
    if [ -d "$mountpoint" ]; then
        size=$(du -sh "$mountpoint" 2>/dev/null | cut -f1 || echo "N/A")
    fi

    echo "  [$i] $volume_name"
    echo "      Tamanho: $size"
    echo ""
done

echo ""
read -p "Selecione o número do volume (ou 'all' para todos): " selection

if [ "$selection" = "all" ]; then
    echo ""
    read -p "Fazer backup de TODOS os ${#volumes[@]} volumes? (yes/no): " confirm

    if [ "$confirm" = "yes" ]; then
        log_info "Batch ID: $BATCH_ID"
        success_count=0
        fail_count=0

        for volume in "${volumes[@]}"; do
            if backup_volume "$volume" "$BACKUP_OUTPUT_DIR" "$BATCH_ID"; then
                ((success_count++))
            else
                ((fail_count++))
            fi
        done

        # Criar metadata do batch
        create_batch_metadata "$BACKUP_OUTPUT_DIR" "$BATCH_ID" "${#volumes[@]}" "$success_count"

        echo ""
        log_section "RESUMO"
        echo "  🆔 Batch ID: $BATCH_ID"
        echo "  ✅ Sucesso: $success_count volumes"
        if [ $fail_count -gt 0 ]; then
            echo "  ❌ Falha: $fail_count volumes"
        fi
        echo "  📁 Diretório: $BACKUP_OUTPUT_DIR"
        echo ""
    else
        log_info "Operação cancelada"
    fi
elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -lt "${#volumes[@]}" ]; then
    VOLUME_NAME="${volumes[$selection]}"
    backup_volume "$VOLUME_NAME" "$BACKUP_OUTPUT_DIR"
else
    log_error "Seleção inválida"
    exit 1
fi
