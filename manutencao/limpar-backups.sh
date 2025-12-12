#!/bin/bash
################################################################################
# Script: limpar-backups.sh
# Propósito: Limpar backups antigos de volumes e databases
# Uso: ./limpar-backups.sh
################################################################################

# Carregar bibliotecas compartilhadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

### ========== CONFIGURAÇÃO ==========

# Diretórios padrão de backup
VOLUME_BACKUP_DIR="/root/volume-backups"
DB_BACKUP_DIR="/var/backups/vpsguardian"
COOLIFY_BACKUP_DIR="/data/coolify/backups"

### ========== FUNÇÕES ==========

get_dir_size() {
    local dir="$1"
    if [ -d "$dir" ]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

get_dir_files_count() {
    local dir="$1"
    if [ -d "$dir" ]; then
        find "$dir" -type f 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

clean_directory() {
    local dir="$1"
    local description="$2"

    if [ ! -d "$dir" ]; then
        log_info "$description: Diretório não encontrado (não há nada para limpar)"
        return 0
    fi

    local size=$(get_dir_size "$dir")
    local count=$(get_dir_files_count "$dir")

    if [ "$count" -eq 0 ]; then
        log_info "$description: Nenhum arquivo encontrado"
        return 0
    fi

    echo ""
    echo "  📁 $description"
    echo "     Localização: $dir"
    echo "     Arquivos: $count"
    echo "     Tamanho: $size"
    echo ""

    read -p "  Deletar estes arquivos? (yes/no): " confirm

    if [ "$confirm" = "yes" ]; then
        log_info "Deletando arquivos de $dir..."
        rm -rf "$dir"/*

        if [ $? -eq 0 ]; then
            log_success "✓ Arquivos deletados com sucesso!"
            log_info "Espaço liberado: $size"
        else
            log_error "✗ Erro ao deletar arquivos"
            return 1
        fi
    else
        log_info "Arquivos preservados"
    fi

    return 0
}

show_backup_summary() {
    local total_size=0
    local total_files=0

    echo ""
    log_section "RESUMO DE BACKUPS"
    echo ""

    # Volume backups
    if [ -d "$VOLUME_BACKUP_DIR" ]; then
        local size=$(get_dir_size "$VOLUME_BACKUP_DIR")
        local count=$(get_dir_files_count "$VOLUME_BACKUP_DIR")
        echo "  📦 Backups de Volumes"
        echo "     Localização: $VOLUME_BACKUP_DIR"
        echo "     Arquivos: $count"
        echo "     Tamanho: $size"
        echo ""
    fi

    # Database backups
    if [ -d "$DB_BACKUP_DIR" ]; then
        local size=$(get_dir_size "$DB_BACKUP_DIR")
        local count=$(get_dir_files_count "$DB_BACKUP_DIR")
        echo "  🗄️  Backups de Databases"
        echo "     Localização: $DB_BACKUP_DIR"
        echo "     Arquivos: $count"
        echo "     Tamanho: $size"
        echo ""
    fi

    # Coolify backups
    if [ -d "$COOLIFY_BACKUP_DIR" ]; then
        local size=$(get_dir_size "$COOLIFY_BACKUP_DIR")
        local count=$(get_dir_files_count "$COOLIFY_BACKUP_DIR")
        echo "  ☁️  Backups do Coolify"
        echo "     Localização: $COOLIFY_BACKUP_DIR"
        echo "     Arquivos: $count"
        echo "     Tamanho: $size"
        echo ""
    fi
}

clean_old_backups() {
    local dir="$1"
    local days="$2"
    local description="$3"

    if [ ! -d "$dir" ]; then
        log_info "$description: Diretório não encontrado"
        return 0
    fi

    log_info "Procurando backups com mais de $days dias em $dir..."

    local old_files=$(find "$dir" -type f -mtime +$days 2>/dev/null)
    local old_count=$(echo "$old_files" | grep -v "^$" | wc -l)

    if [ "$old_count" -eq 0 ]; then
        log_info "Nenhum backup antigo encontrado"
        return 0
    fi

    echo ""
    echo "  📁 $description"
    echo "     Backups com mais de $days dias: $old_count arquivos"
    echo ""

    # Mostrar lista de arquivos
    echo "  Arquivos que serão deletados:"
    echo "$old_files" | while read -r file; do
        if [ -n "$file" ]; then
            local file_date=$(stat -c %y "$file" | cut -d' ' -f1)
            local file_size=$(du -h "$file" | cut -f1)
            echo "    - $(basename "$file") ($file_date, $file_size)"
        fi
    done
    echo ""

    read -p "  Deletar estes arquivos antigos? (yes/no): " confirm

    if [ "$confirm" = "yes" ]; then
        echo "$old_files" | while read -r file; do
            if [ -n "$file" ]; then
                rm -f "$file"
            fi
        done
        log_success "✓ $old_count arquivos antigos deletados!"
    else
        log_info "Arquivos preservados"
    fi
}

### ========== MAIN ==========

log_section "VPS Guardian - Limpeza de Backups"

show_backup_summary

echo ""
log_info "Opções de limpeza:"
echo ""
echo "  [1] Limpar TODOS os backups de volumes"
echo "  [2] Limpar TODOS os backups de databases"
echo "  [3] Limpar TODOS os backups do Coolify"
echo "  [4] Limpar backups antigos (mais de X dias)"
echo "  [5] Limpar TUDO (volumes + databases + coolify)"
echo "  [0] Cancelar"
echo ""

read -p "Escolha uma opção (0-5): " option

case $option in
    1)
        log_section "LIMPEZA DE BACKUPS DE VOLUMES"
        clean_directory "$VOLUME_BACKUP_DIR" "Backups de Volumes"
        ;;
    2)
        log_section "LIMPEZA DE BACKUPS DE DATABASES"
        clean_directory "$DB_BACKUP_DIR" "Backups de Databases"
        ;;
    3)
        log_section "LIMPEZA DE BACKUPS DO COOLIFY"
        clean_directory "$COOLIFY_BACKUP_DIR" "Backups do Coolify"
        ;;
    4)
        log_section "LIMPEZA DE BACKUPS ANTIGOS"
        echo ""
        read -p "Deletar backups com mais de quantos dias? (ex: 7, 30, 90): " days

        if ! [[ "$days" =~ ^[0-9]+$ ]]; then
            log_error "Número inválido"
            exit 1
        fi

        echo ""
        log_info "Procurando backups com mais de $days dias..."
        echo ""

        clean_old_backups "$VOLUME_BACKUP_DIR" "$days" "Backups de Volumes"
        echo ""
        clean_old_backups "$DB_BACKUP_DIR" "$days" "Backups de Databases"
        echo ""
        clean_old_backups "$COOLIFY_BACKUP_DIR" "$days" "Backups do Coolify"
        ;;
    5)
        log_section "LIMPEZA COMPLETA DE BACKUPS"
        echo ""
        log_warning "⚠️  ATENÇÃO: Esta operação vai deletar TODOS os backups!"
        echo ""
        read -p "Tem certeza? Digite 'DELETE ALL' para confirmar: " confirm

        if [ "$confirm" = "DELETE ALL" ]; then
            clean_directory "$VOLUME_BACKUP_DIR" "Backups de Volumes"
            echo ""
            clean_directory "$DB_BACKUP_DIR" "Backups de Databases"
            echo ""
            clean_directory "$COOLIFY_BACKUP_DIR" "Backups do Coolify"
        else
            log_info "Operação cancelada"
        fi
        ;;
    0)
        log_info "Operação cancelada"
        exit 0
        ;;
    *)
        log_error "Opção inválida"
        exit 1
        ;;
esac

echo ""
log_section "RESUMO FINAL"

show_backup_summary

log_success "Limpeza concluída!"
