#!/bin/bash
################################################################################
# VPS Guardian - Limpeza Inteligente de Backups Antigos
#
# Suporta múltiplas estratégias de retenção:
#   1. Simple - Deleta backups mais antigos que X dias
#   2. Count - Mantém últimos X backups (independente da idade)
#   3. GFS (Grandfather-Father-Son) - 7 diários, 4 semanais, 12 mensais
#
# Uso:
#   ./limpar-backups-antigos.sh [opções]
#   --strategy=simple|count|gfs    Estratégia de retenção
#   --days=X                       Dias para estratégia simple (padrão: 30)
#   --count=X                      Quantidade para estratégia count (padrão: 10)
#   --dir=/path                    Diretório de backups (padrão: coolify)
#   --dry-run                      Simula sem deletar
#   --auto                         Modo não-interativo
#
# Versão: 1.0
################################################################################

set -e

# Carregar bibliotecas compartilhadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Inicializar script
init_script

################################################################################
# CONFIGURAÇÕES
################################################################################

# Estratégia (sobrescreve config/default.conf se passado via argumento)
STRATEGY="${BACKUP_RETENTION_STRATEGY:-simple}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
RETENTION_COUNT="${BACKUP_RETENTION_COUNT:-10}"
BACKUP_DIR="${COOLIFY_BACKUP_DIR}"

# Flags
DRY_RUN=false
AUTO_MODE=false

################################################################################
# FUNÇÕES AUXILIARES
################################################################################

show_help() {
    cat << EOF
$(log_info "VPS Guardian - Limpeza Inteligente de Backups")

$(log_info "USO:")
  $0 [opções]

$(log_info "OPÇÕES:")
  --strategy=TIPO     Estratégia de retenção
                      • simple = Deleta backups >X dias
                      • count = Mantém últimos X backups
                      • gfs = Grandfather-Father-Son
  --days=X            Dias para estratégia simple (padrão: 30)
  --count=X           Quantidade para estratégia count (padrão: 10)
  --dir=/path         Diretório de backups (padrão: $BACKUP_DIR)
  --dry-run           Simula sem deletar (mostra o que seria feito)
  --auto              Modo não-interativo
  --help              Mostra esta ajuda

$(log_info "ESTRATÉGIAS:")

  $(log_info "1. SIMPLE (Simples)")
     Deleta backups mais antigos que X dias
     Exemplo: --strategy=simple --days=30

  $(log_info "2. COUNT (Quantidade)")
     Mantém últimos X backups (deleta o resto)
     Exemplo: --strategy=count --count=10

  $(log_info "3. GFS (Grandfather-Father-Son)")
     Retenção inteligente multi-nível:
     • Diários: últimos 7 dias (todos)
     • Semanais: últimas 4 semanas (1 por semana)
     • Mensais: últimos 12 meses (1 por mês)
     Exemplo: --strategy=gfs

$(log_info "EXEMPLOS:")

  # Deletar backups >30 dias
  $0 --strategy=simple --days=30

  # Manter apenas últimos 10 backups
  $0 --strategy=count --count=10

  # Estratégia GFS
  $0 --strategy=gfs

  # Simular (dry-run)
  $0 --strategy=simple --days=30 --dry-run

  # Limpar backups de volumes (outro diretório)
  $0 --dir=/var/backups/vpsguardian/volumes --days=15

EOF
    exit 0
}

parse_arguments() {
    for arg in "$@"; do
        case $arg in
            --strategy=*)
                STRATEGY="${arg#*=}"
                ;;
            --days=*)
                RETENTION_DAYS="${arg#*=}"
                ;;
            --count=*)
                RETENTION_COUNT="${arg#*=}"
                ;;
            --dir=*)
                BACKUP_DIR="${arg#*=}"
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --auto)
                AUTO_MODE=true
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Argumento desconhecido: $arg"
                show_help
                ;;
        esac
    done
}

validate_config() {
    # Validar estratégia
    case "$STRATEGY" in
        simple|count|gfs)
            ;;
        *)
            log_error "Estratégia inválida: $STRATEGY"
            log_info "Use: simple, count ou gfs"
            exit 1
            ;;
    esac

    # Validar diretório
    if [ ! -d "$BACKUP_DIR" ]; then
        log_error "Diretório não existe: $BACKUP_DIR"
        exit 1
    fi

    # Validar números
    if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
        log_error "Dias deve ser um número: $RETENTION_DAYS"
        exit 1
    fi

    if ! [[ "$RETENTION_COUNT" =~ ^[0-9]+$ ]]; then
        log_error "Count deve ser um número: $RETENTION_COUNT"
        exit 1
    fi
}

show_summary() {
    log_section "Configuração de Limpeza"

    echo "Diretório: $BACKUP_DIR"
    echo "Estratégia: $STRATEGY"

    case "$STRATEGY" in
        simple)
            echo "Retenção: $RETENTION_DAYS dias"
            ;;
        count)
            echo "Retenção: últimos $RETENTION_COUNT backups"
            ;;
        gfs)
            echo "Retenção: GFS (7 diários + 4 semanais + 12 mensais)"
            ;;
    esac

    if [ "$DRY_RUN" = true ]; then
        log_warning "MODO DRY-RUN: Nenhum arquivo será deletado"
    fi

    echo ""
}

################################################################################
# ESTRATÉGIA 1: SIMPLE (por idade)
################################################################################

cleanup_simple() {
    log_section "Estratégia SIMPLE: Deletar backups >$RETENTION_DAYS dias"

    local backups_to_delete=()

    # Encontrar backups antigos
    while IFS= read -r backup; do
        backups_to_delete+=("$backup")
    done < <(find "$BACKUP_DIR" -name "*.tar.gz*" -type f -mtime +$RETENTION_DAYS)

    local total=${#backups_to_delete[@]}

    if [ $total -eq 0 ]; then
        log_success "Nenhum backup antigo para deletar (todos <$RETENTION_DAYS dias)"
        return 0
    fi

    log_info "Encontrados $total backups para deletar:"
    echo ""

    for backup in "${backups_to_delete[@]}"; do
        local filename=$(basename "$backup")
        local age=$(find "$backup" -mtime +$RETENTION_DAYS -printf '%A@\n' | xargs -I{} date -d @{} '+%Y-%m-%d %H:%M')
        local size=$(du -h "$backup" | cut -f1)

        echo "  🗑️  $filename ($size, criado em $age)"
    done

    echo ""

    # Confirmar (se não for auto mode)
    if [ "$AUTO_MODE" = false ] && [ "$DRY_RUN" = false ]; then
        read -p "Deletar estes $total backups? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            log_info "Operação cancelada"
            return 0
        fi
    fi

    # Deletar
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY-RUN: Arquivos NÃO foram deletados"
    else
        local deleted=0
        for backup in "${backups_to_delete[@]}"; do
            if rm -f "$backup"; then
                ((deleted++))
            fi
        done

        log_success "$deleted backups deletados"

        # Calcular espaço liberado
        local space_freed=$(du -ch "${backups_to_delete[@]}" 2>/dev/null | tail -1 | cut -f1)
        log_success "Espaço liberado: $space_freed"
    fi
}

################################################################################
# ESTRATÉGIA 2: COUNT (por quantidade)
################################################################################

cleanup_count() {
    log_section "Estratégia COUNT: Manter últimos $RETENTION_COUNT backups"

    # Listar backups ordenados por data (mais recente primeiro)
    local all_backups=()
    while IFS= read -r backup; do
        all_backups+=("$backup")
    done < <(find "$BACKUP_DIR" -name "*.tar.gz*" -type f -printf '%T@ %p\n' | sort -rn | cut -d' ' -f2-)

    local total=${#all_backups[@]}

    log_info "Total de backups encontrados: $total"

    if [ $total -le $RETENTION_COUNT ]; then
        log_success "Nenhum backup para deletar (total: $total, retenção: $RETENTION_COUNT)"
        return 0
    fi

    # Backups a deletar (todos após os últimos RETENTION_COUNT)
    local backups_to_delete=("${all_backups[@]:$RETENTION_COUNT}")
    local to_delete_count=${#backups_to_delete[@]}

    log_info "Backups a deletar: $to_delete_count (mantendo últimos $RETENTION_COUNT)"
    echo ""

    echo "✅ MANTENDO (últimos $RETENTION_COUNT):"
    for i in $(seq 0 $((RETENTION_COUNT - 1))); do
        if [ $i -lt $total ]; then
            local filename=$(basename "${all_backups[$i]}")
            local size=$(du -h "${all_backups[$i]}" | cut -f1)
            echo "  ✓ $filename ($size)"
        fi
    done

    echo ""
    echo "🗑️  DELETANDO (restante):"
    for backup in "${backups_to_delete[@]}"; do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        echo "  ✗ $filename ($size)"
    done

    echo ""

    # Confirmar
    if [ "$AUTO_MODE" = false ] && [ "$DRY_RUN" = false ]; then
        read -p "Deletar $to_delete_count backups? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            log_info "Operação cancelada"
            return 0
        fi
    fi

    # Deletar
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY-RUN: Arquivos NÃO foram deletados"
    else
        local deleted=0
        for backup in "${backups_to_delete[@]}"; do
            if rm -f "$backup"; then
                ((deleted++))
            fi
        done

        log_success "$deleted backups deletados (mantidos $RETENTION_COUNT)"
    fi
}

################################################################################
# ESTRATÉGIA 3: GFS (Grandfather-Father-Son)
################################################################################

cleanup_gfs() {
    log_section "Estratégia GFS: Retenção Multi-Nível"

    log_info "Retenção configurada:"
    echo "  • Diários: últimos 7 dias (todos)"
    echo "  • Semanais: últimas 4 semanas (1 por semana - domingo)"
    echo "  • Mensais: últimos 12 meses (1 por mês - dia 1)"
    echo ""

    # Datas de referência
    local now=$(date +%s)
    local day_seconds=86400

    # Arrays para classificação
    declare -A keep_backups
    local all_backups=()

    # Listar todos os backups
    while IFS= read -r backup; do
        all_backups+=("$backup")
    done < <(find "$BACKUP_DIR" -name "*.tar.gz*" -type f)

    log_info "Total de backups encontrados: ${#all_backups[@]}"
    echo ""

    # Classificar backups
    for backup in "${all_backups[@]}"; do
        local backup_time=$(stat -c %Y "$backup")
        local backup_date=$(date -d @$backup_time +%Y-%m-%d)
        local backup_day=$(date -d @$backup_time +%u)  # 1-7 (1=Monday, 7=Sunday)
        local backup_dom=$(date -d @$backup_time +%d)  # day of month
        local age_days=$(( (now - backup_time) / day_seconds ))

        local reason=""

        # 1. DIÁRIOS: últimos 7 dias (todos)
        if [ $age_days -le 7 ]; then
            reason="diário (${age_days}d)"
            keep_backups["$backup"]="$reason"

        # 2. SEMANAIS: últimas 4 semanas (domingos)
        elif [ $age_days -le 28 ] && [ $backup_day -eq 7 ]; then
            local week=$(( age_days / 7 ))
            reason="semanal (semana $week)"
            keep_backups["$backup"]="$reason"

        # 3. MENSAIS: últimos 12 meses (dia 1)
        elif [ $age_days -le 365 ] && [ $backup_dom -eq 01 ]; then
            local month=$(date -d @$backup_time +%B)
            reason="mensal ($month)"
            keep_backups["$backup"]="$reason"
        fi
    done

    # Backups a manter
    log_info "✅ MANTENDO (${#keep_backups[@]} backups):"
    for backup in "${!keep_backups[@]}"; do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local reason="${keep_backups[$backup]}"
        echo "  ✓ $filename ($size) - $reason"
    done

    echo ""

    # Backups a deletar
    local backups_to_delete=()
    for backup in "${all_backups[@]}"; do
        if [ -z "${keep_backups[$backup]}" ]; then
            backups_to_delete+=("$backup")
        fi
    done

    if [ ${#backups_to_delete[@]} -eq 0 ]; then
        log_success "Nenhum backup para deletar (todos dentro da política GFS)"
        return 0
    fi

    log_info "🗑️  DELETANDO (${#backups_to_delete[@]} backups fora da política):"
    for backup in "${backups_to_delete[@]}"; do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local backup_time=$(stat -c %Y "$backup")
        local backup_date=$(date -d @$backup_time +%Y-%m-%d)
        echo "  ✗ $filename ($size, $backup_date)"
    done

    echo ""

    # Confirmar
    if [ "$AUTO_MODE" = false ] && [ "$DRY_RUN" = false ]; then
        read -p "Deletar ${#backups_to_delete[@]} backups? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            log_info "Operação cancelada"
            return 0
        fi
    fi

    # Deletar
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY-RUN: Arquivos NÃO foram deletados"
    else
        local deleted=0
        for backup in "${backups_to_delete[@]}"; do
            if rm -f "$backup"; then
                ((deleted++))
            fi
        done

        log_success "$deleted backups deletados (mantidos ${#keep_backups[@]})"
    fi
}

################################################################################
# MAIN
################################################################################

main() {
    log_section "VPS Guardian - Limpeza de Backups Antigos"

    # Parse argumentos
    parse_arguments "$@"

    # Validar configuração
    validate_config

    # Mostrar resumo
    show_summary

    # Executar estratégia escolhida
    case "$STRATEGY" in
        simple)
            cleanup_simple
            ;;
        count)
            cleanup_count
            ;;
        gfs)
            cleanup_gfs
            ;;
    esac

    log_section "Limpeza Concluída"
    log_success "Operação finalizada com sucesso"
}

# Executar
main "$@"
