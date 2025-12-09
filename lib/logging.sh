#!/bin/bash
################################################################################
# VPS Guardian - Biblioteca de Logging
# Fornece funções padronizadas de log para todos os scripts
################################################################################

# Carregar cores se disponível
if [ -f "$(dirname "${BASH_SOURCE[0]}")/colors.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
fi

# Nome do script atual (para incluir nos logs)
SCRIPT_NAME="${SCRIPT_NAME:-$(basename "$0")}"

# Arquivo de log (pode ser sobrescrito pelo script que chama)
LOG_FILE="${LOG_FILE:-}"

# Formato de timestamp
LOG_TIMESTAMP_FORMAT="${LOG_TIMESTAMP_FORMAT:-%Y-%m-%d %H:%M:%S}"

################################################################################
# Funções Internas
################################################################################

_log_write() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+${LOG_TIMESTAMP_FORMAT}")
    local log_line="[$timestamp] [$level] [$SCRIPT_NAME] $message"

    # Sempre exibe no terminal
    echo "$log_line"

    # Salva em arquivo se LOG_FILE estiver definido
    if [ -n "$LOG_FILE" ]; then
        echo "$log_line" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

_log_write_colored() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp=$(date "+${LOG_TIMESTAMP_FORMAT}")

    # Com cor no terminal (se suportado)
    if [ -t 1 ]; then
        echo -e "${color}[$timestamp] [$level] [$SCRIPT_NAME]${NC} $message"
    else
        echo "[$timestamp] [$level] [$SCRIPT_NAME] $message"
    fi

    # Salva em arquivo SEM cores
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [$level] [$SCRIPT_NAME] $message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

################################################################################
# Funções Públicas de Log
################################################################################

# Log de informação
log_info() {
    _log_write_colored "INFO" "${BLUE}" "$*"
}

# Log de sucesso
log_success() {
    _log_write_colored "SUCCESS" "${GREEN}" "$*"
}

# Log de aviso
log_warning() {
    _log_write_colored "WARNING" "${YELLOW}" "$*"
}

# Log de erro (vai para stderr)
log_error() {
    _log_write_colored "ERROR" "${RED}" "$*" >&2
}

# Log de debug (apenas se DEBUG=1)
log_debug() {
    if [ "${DEBUG:-0}" -eq 1 ]; then
        _log_write_colored "DEBUG" "${MAGENTA}" "$*"
    fi
}

# Log simples sem formato (compatibilidade com scripts antigos)
log() {
    local level="${1:-INFO}"
    shift
    local message="$*"

    case "$level" in
        SUCCESS|OK|✓)
            log_success "$message"
            ;;
        ERROR|FAIL|FAILED|✗)
            log_error "$message"
            ;;
        WARNING|WARN|⚠)
            log_warning "$message"
            ;;
        DEBUG)
            log_debug "$message"
            ;;
        *)
            # Se primeiro argumento não for um level, trata tudo como mensagem
            log_info "$level $message"
            ;;
    esac
}

################################################################################
# Funções de Seção (para organizar visualmente os logs)
################################################################################

log_section() {
    local title="$*"
    local line="════════════════════════════════════════════════════════════"

    if [ -t 1 ]; then
        echo ""
        echo -e "${CYAN}$line${NC}"
        echo -e "${CYAN}  $title${NC}"
        echo -e "${CYAN}$line${NC}"
        echo ""
    else
        echo ""
        echo "$line"
        echo "  $title"
        echo "$line"
        echo ""
    fi
}

log_separator() {
    if [ -t 1 ]; then
        echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"
    else
        echo "────────────────────────────────────────────────────────────"
    fi
}

################################################################################
# Funções de Configuração
################################################################################

# Configura arquivo de log
set_log_file() {
    LOG_FILE="$1"

    # Cria diretório se não existir
    local log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir" 2>/dev/null || true

    # Cria arquivo com permissões corretas
    touch "$LOG_FILE" 2>/dev/null || true
    chmod 640 "$LOG_FILE" 2>/dev/null || true
}

# Configura nome do script (para logs mais claros)
set_script_name() {
    SCRIPT_NAME="$1"
}

################################################################################
# Funções de Rotação de Logs
################################################################################

rotate_log() {
    local log_file="${1:-$LOG_FILE}"
    local max_size_mb="${2:-10}"
    local max_size_bytes=$((max_size_mb * 1024 * 1024))

    if [ ! -f "$log_file" ]; then
        return 0
    fi

    local size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null)

    if [ "$size" -gt "$max_size_bytes" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        mv "$log_file" "${log_file}.${timestamp}"
        gzip "${log_file}.${timestamp}" 2>/dev/null || true
        touch "$log_file"
        chmod 640 "$log_file" 2>/dev/null || true
        log_info "Log rotacionado: ${log_file}.${timestamp}.gz"
    fi
}

clean_old_logs() {
    local log_dir="${1:-$(dirname "$LOG_FILE")}"
    local days="${2:-${LOG_RETENTION_DAYS:-90}}"

    if [ -d "$log_dir" ]; then
        find "$log_dir" -name "*.log.*" -type f -mtime "+${days}" -delete 2>/dev/null || true
        log_info "Logs antigos (>${days} dias) removidos de $log_dir"
    fi
}

################################################################################
# Export de funções para uso em subshells
################################################################################

export -f log_info log_success log_warning log_error log_debug log
export -f log_section log_separator
export -f set_log_file set_script_name
export -f rotate_log clean_old_logs
