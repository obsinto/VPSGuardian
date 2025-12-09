#!/bin/bash
################################################################################
# VPS Guardian - Biblioteca de Cores
# Define cores ANSI para uso em terminais que suportam
################################################################################

# Detecta se o terminal suporta cores
# Só define cores se:
# 1. Estiver em terminal interativo (não redirecionado)
# 2. Terminal suportar cores (TERM != dumb)
if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
    # Cores básicas
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'
    GRAY='\033[0;90m'

    # Cores em negrito
    BOLD_RED='\033[1;31m'
    BOLD_GREEN='\033[1;32m'
    BOLD_YELLOW='\033[1;33m'
    BOLD_BLUE='\033[1;34m'
    BOLD_MAGENTA='\033[1;35m'
    BOLD_CYAN='\033[1;36m'
    BOLD_WHITE='\033[1;37m'

    # Cores de fundo
    BG_RED='\033[41m'
    BG_GREEN='\033[42m'
    BG_YELLOW='\033[43m'
    BG_BLUE='\033[44m'
    BG_MAGENTA='\033[45m'
    BG_CYAN='\033[46m'

    # Estilos
    BOLD='\033[1m'
    DIM='\033[2m'
    UNDERLINE='\033[4m'
    BLINK='\033[5m'
    REVERSE='\033[7m'
    HIDDEN='\033[8m'

    # Reset
    NC='\033[0m' # No Color / Reset

else
    # Não é terminal interativo ou não suporta cores
    # Define todas as variáveis como vazias
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    WHITE=''
    GRAY=''

    BOLD_RED=''
    BOLD_GREEN=''
    BOLD_YELLOW=''
    BOLD_BLUE=''
    BOLD_MAGENTA=''
    BOLD_CYAN=''
    BOLD_WHITE=''

    BG_RED=''
    BG_GREEN=''
    BG_YELLOW=''
    BG_BLUE=''
    BG_MAGENTA=''
    BG_CYAN=''

    BOLD=''
    DIM=''
    UNDERLINE=''
    BLINK=''
    REVERSE=''
    HIDDEN=''

    NC=''
fi

################################################################################
# Funções Auxiliares de Colorização
################################################################################

# Coloriza uma string com a cor especificada
colorize() {
    local color="$1"
    shift
    local text="$*"

    if [ -n "$color" ]; then
        echo -e "${color}${text}${NC}"
    else
        echo "$text"
    fi
}

# Funções de atalho para cores comuns
red()     { colorize "$RED" "$*"; }
green()   { colorize "$GREEN" "$*"; }
yellow()  { colorize "$YELLOW" "$*"; }
blue()    { colorize "$BLUE" "$*"; }
magenta() { colorize "$MAGENTA" "$*"; }
cyan()    { colorize "$CYAN" "$*"; }
gray()    { colorize "$GRAY" "$*"; }

# Estilos
bold()      { colorize "$BOLD" "$*"; }
underline() { colorize "$UNDERLINE" "$*"; }

################################################################################
# Funções de Símbolos Coloridos (para melhor UX)
################################################################################

# Símbolo de sucesso (✓ ou OK)
print_success() {
    if [ -t 1 ]; then
        echo -e "${GREEN}✓${NC} $*"
    else
        echo "[OK] $*"
    fi
}

# Símbolo de erro (✗ ou ERROR)
print_error() {
    if [ -t 1 ]; then
        echo -e "${RED}✗${NC} $*"
    else
        echo "[ERROR] $*"
    fi
}

# Símbolo de aviso (⚠ ou WARNING)
print_warning() {
    if [ -t 1 ]; then
        echo -e "${YELLOW}⚠${NC} $*"
    else
        echo "[WARNING] $*"
    fi
}

# Símbolo de informação (ℹ ou INFO)
print_info() {
    if [ -t 1 ]; then
        echo -e "${BLUE}ℹ${NC} $*"
    else
        echo "[INFO] $*"
    fi
}

################################################################################
# Funções de Teste de Cores
################################################################################

# Exibe todas as cores disponíveis (para teste)
show_colors() {
    echo "=== VPS Guardian - Paleta de Cores ==="
    echo ""
    echo "Cores Básicas:"
    echo -e "  ${RED}RED${NC}       - Erros, falhas"
    echo -e "  ${GREEN}GREEN${NC}     - Sucesso, OK"
    echo -e "  ${YELLOW}YELLOW${NC}    - Avisos, atenção"
    echo -e "  ${BLUE}BLUE${NC}      - Informações"
    echo -e "  ${MAGENTA}MAGENTA${NC}   - Debug"
    echo -e "  ${CYAN}CYAN${NC}      - Títulos, seções"
    echo -e "  ${GRAY}GRAY${NC}      - Comentários"
    echo ""
    echo "Estilos:"
    echo -e "  ${BOLD}BOLD${NC}      - Destaque"
    echo -e "  ${UNDERLINE}UNDERLINE${NC} - Sublinhado"
    echo -e "  ${DIM}DIM${NC}       - Texto esmaecido"
    echo ""
    echo "Símbolos:"
    print_success "Operação bem-sucedida"
    print_error "Erro na operação"
    print_warning "Aviso importante"
    print_info "Informação adicional"
    echo ""
}

################################################################################
# Export de funções para uso em subshells
################################################################################

export -f colorize red green yellow blue magenta cyan gray bold underline
export -f print_success print_error print_warning print_info
export -f show_colors
