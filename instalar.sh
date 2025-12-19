#!/bin/bash

################################################################################
# Script de Instalação - VPS Guardian
# Propósito: Instalação escalável e configurável do sistema
# Uso: sudo ./instalar.sh
#
# Características:
# - Menu interativo para configuração
# - Detecta instalação anterior
# - Oferece atualizar/reinstalar/desinstalar
# - Symlinks em vez de cópias (melhor para atualizações)
# - Configuração completa integrada
# - Validações robustas
################################################################################

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# CORES E FORMATAÇÃO
# ═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════════════════════
# DETECÇÃO AUTOMÁTICA DE DIRETÓRIOS
# ═══════════════════════════════════════════════════════════════════════════════

# Detectar diretório de origem (onde está o repositório clonado)
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_NAME="$(basename "$SOURCE_DIR")"

# Padrões dinâmicos baseados no nome da pasta atual
DEFAULT_INSTALL_DIR="/opt/$SOURCE_NAME"
DEFAULT_BACKUP_DIR="/var/backups/$SOURCE_NAME"
DEFAULT_LOG_DIR="/var/log/$SOURCE_NAME"

# ═══════════════════════════════════════════════════════════════════════════════
# FUNÇÕES DE LOG
# ═══════════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC} $1"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# VERIFICAÇÕES INICIAIS
# ═══════════════════════════════════════════════════════════════════════════════

verify_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script precisa ser executado como root (use sudo)"
        exit 1
    fi
}

verify_directory() {
    if [ ! -f "menu-principal.sh" ] || [ ! -d "backup" ]; then
        log_error "Execute este script do diretório raiz do projeto"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# CARREGAMENTO DE CONFIGURAÇÕES ANTERIORES
# ═══════════════════════════════════════════════════════════════════════════════

INSTALL_ROOT=""
BACKUP_ROOT=""
LOG_ROOT=""
USE_SYMLINKS=""
INSTALLED=false
INSTALL_CONFIG=""

load_previous_config() {
    # Procurar arquivo de configuração em locais possíveis
    local possible_configs=(
        "/opt/vpsguardian/.install.conf"
        "/opt/vpsguardian-src/.install.conf"
        "$DEFAULT_INSTALL_DIR/.install.conf"
        "/etc/vpsguardian/install.conf"
    )

    for config in "${possible_configs[@]}"; do
        if [ -f "$config" ]; then
            INSTALL_CONFIG="$config"
            source "$INSTALL_CONFIG"
            INSTALLED=true
            return
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════════════════════

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║             🛡️  VPS GUARDIAN - INSTALADOR                  ║"
    echo "║                                                            ║"
    echo "║     Sistema completo de Backup, Manutenção e Migração     ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MENU DE MODO (Instalar/Atualizar/Desinstalar)
# ═══════════════════════════════════════════════════════════════════════════════

choose_installation_mode() {
    log_section "MODO DE INSTALAÇÃO"

    if [ "$INSTALLED" = true ]; then
        log_warning "Instalação anterior detectada em: $INSTALL_ROOT"
        echo ""
        echo "O que deseja fazer?"
        echo ""
        echo "  1. 🔄 Atualizar (preservar configurações)"
        echo "  2. 🔁 Reinstalar (reconfigurar tudo)"
        echo "  3. ❌ Desinstalar (remover do sistema)"
        echo "  4. 📋 Ver configuração atual"
        echo "  5. ⬅️  Cancelar"
        echo ""

        read -p "Escolha uma opção (1-5): " MODE
        case $MODE in
            1) MODE="update" ;;
            2) MODE="reinstall" ;;
            3) MODE="uninstall" ;;
            4) show_current_config; return 1 ;;
            5) log_info "Cancelado"; exit 0 ;;
            *) log_error "Opção inválida"; return 1 ;;
        esac
    else
        log_success "Primeira instalação detectada"
        MODE="install"
    fi

    echo ""
}

show_current_config() {
    log_section "CONFIGURAÇÃO ATUAL"

    log_info "Diretório de instalação: $INSTALL_ROOT"
    log_info "Diretório de backups:    $BACKUP_ROOT"
    log_info "Diretório de logs:       $LOG_ROOT"
    log_info "Tipo de links:           $([ "$USE_SYMLINKS" = "true" ] && echo "Symlinks" || echo "Cópias")"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# MENU INTERATIVO DE CONFIGURAÇÃO
# ═══════════════════════════════════════════════════════════════════════════════

interactive_configuration() {
    log_section "CONFIGURAÇÃO INTERATIVA"

    log_info "Nome da pasta de origem detectado: $SOURCE_NAME"
    echo ""

    # Diretório de Instalação
    log_info "Diretório de instalação (padrão: $DEFAULT_INSTALL_DIR)"
    read -p "Caminho: " -i "$DEFAULT_INSTALL_DIR" -e INSTALL_ROOT
    INSTALL_ROOT="${INSTALL_ROOT:-$DEFAULT_INSTALL_DIR}"

    # Diretório de Backups
    log_info ""
    log_info "Diretório de backups (padrão: $DEFAULT_BACKUP_DIR)"
    read -p "Caminho: " -i "$DEFAULT_BACKUP_DIR" -e BACKUP_ROOT
    BACKUP_ROOT="${BACKUP_ROOT:-$DEFAULT_BACKUP_DIR}"

    # Diretório de Logs
    log_info ""
    log_info "Diretório de logs (padrão: $DEFAULT_LOG_DIR)"
    read -p "Caminho: " -i "$DEFAULT_LOG_DIR" -e LOG_ROOT
    LOG_ROOT="${LOG_ROOT:-$DEFAULT_LOG_DIR}"

    # Tipo de links
    log_info ""
    log_info "Usar symlinks (melhor para atualizações) ou cópias?"
    echo "  1. 🔗 Symlinks (recomendado)"
    echo "  2. 📋 Cópias"
    echo ""
    read -p "Escolha (1-2): " LINK_TYPE
    USE_SYMLINKS=$([ "$LINK_TYPE" = "1" ] && echo "true" || echo "false")

    echo ""
}

validate_paths() {
    log_section "VALIDAÇÃO DE CAMINHOS"

    # Definir INSTALL_CONFIG baseado no INSTALL_ROOT escolhido
    INSTALL_CONFIG="$INSTALL_ROOT/.install.conf"

    # Validar que os caminhos são diferentes
    if [ "$INSTALL_ROOT" = "$BACKUP_ROOT" ] || [ "$INSTALL_ROOT" = "$LOG_ROOT" ]; then
        log_error "Os caminhos devem ser diferentes!"
        return 1
    fi

    # Criar diretórios pai se necessário
    for path in "$INSTALL_ROOT" "$BACKUP_ROOT" "$LOG_ROOT"; do
        parent_dir=$(dirname "$path")
        if [ ! -d "$parent_dir" ]; then
            log_error "Diretório pai não existe: $parent_dir"
            return 1
        fi
    done

    log_success "Validação de caminhos OK"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# INSTALAÇÃO/ATUALIZAÇÃO
# ═══════════════════════════════════════════════════════════════════════════════

prepare_installation() {
    log_section "PREPARAÇÃO PARA INSTALAÇÃO"

    # Criar diretórios
    log_info "Criando diretórios..."
    mkdir -p "$INSTALL_ROOT"/{backup,manutencao,migrar,scripts-auxiliares,docs,lib}
    mkdir -p "$BACKUP_ROOT"/{coolify,volumes,databases}
    mkdir -p "$LOG_ROOT"
    log_success "Diretórios criados"

    echo ""
}

install_scripts() {
    log_section "INSTALANDO SCRIPTS"

    local link_cmd="cp -v"
    if [ "$USE_SYMLINKS" = "true" ]; then
        link_cmd="ln -sf"
    fi

    # Instalar backup scripts
    log_info "Instalando scripts de backup..."
    for script in backup/*.sh; do
        if [ -f "$script" ]; then
            $link_cmd "$(pwd)/$script" "$INSTALL_ROOT/backup/$(basename $script)"
        fi
    done
    log_success "Scripts de backup instalados"

    # Instalar maintenance scripts
    log_info "Instalando scripts de manutenção..."
    for script in manutencao/*.sh; do
        if [ -f "$script" ]; then
            $link_cmd "$(pwd)/$script" "$INSTALL_ROOT/manutencao/$(basename $script)"
        fi
    done
    log_success "Scripts de manutenção instalados"

    # Instalar migration scripts
    log_info "Instalando scripts de migração..."
    for script in migrar/*.sh; do
        if [ -f "$script" ]; then
            $link_cmd "$(pwd)/$script" "$INSTALL_ROOT/migrar/$(basename $script)"
        fi
    done
    log_success "Scripts de migração instalados"

    # Instalar auxiliary scripts
    log_info "Instalando scripts auxiliares..."
    for script in scripts-auxiliares/*.sh; do
        if [ -f "$script" ]; then
            $link_cmd "$(pwd)/$script" "$INSTALL_ROOT/scripts-auxiliares/$(basename $script)"
        fi
    done
    log_success "Scripts auxiliares instalados"

    # Instalar bibliotecas compartilhadas
    log_info "Instalando bibliotecas compartilhadas..."
    for lib in lib/*.sh; do
        if [ -f "$lib" ]; then
            $link_cmd "$(pwd)/$lib" "$INSTALL_ROOT/lib/$(basename $lib)"
        fi
    done
    log_success "Bibliotecas instaladas"

    # Instalar menu principal
    log_info "Instalando menu principal..."
    $link_cmd "$(pwd)/menu-principal.sh" "$INSTALL_ROOT/menu-principal.sh"
    log_success "Menu principal instalado"

    # Instalar documentação
    if [ -d "docs" ]; then
        log_info "Instalando documentação..."
        cp -r docs/* "$INSTALL_ROOT/docs/" 2>/dev/null || true
        log_success "Documentação instalada"
    fi

    echo ""
}

set_permissions() {
    log_section "CONFIGURANDO PERMISSÕES"

    log_info "Configurando permissões de execução..."
    find "$INSTALL_ROOT" -name "*.sh" -type f -exec chmod +x {} \;
    log_success "Permissões configuradas"

    log_info "Configurando permissões de diretórios..."
    chmod 755 "$INSTALL_ROOT"/{backup,manutencao,migrar,scripts-auxiliares,docs,lib}
    chmod 755 "$BACKUP_ROOT"/{coolify,volumes,databases}
    chmod 755 "$LOG_ROOT"
    log_success "Permissões de diretórios OK"

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# SALVAR CONFIGURAÇÃO
# ═══════════════════════════════════════════════════════════════════════════════

save_configuration() {
    log_section "SALVANDO CONFIGURAÇÃO"

    # Criar arquivo de configuração
    mkdir -p "$(dirname "$INSTALL_CONFIG")"

    cat > "$INSTALL_CONFIG" << EOF
# Configuração de Instalação - $(date)
INSTALL_ROOT="$INSTALL_ROOT"
BACKUP_ROOT="$BACKUP_ROOT"
LOG_ROOT="$LOG_ROOT"
USE_SYMLINKS="$USE_SYMLINKS"
INSTALLED="true"
EOF

    log_success "Configuração salva em: $INSTALL_CONFIG"

    # Também copiar para o diretório de instalação
    cp "$INSTALL_CONFIG" "$INSTALL_ROOT/.install.conf"
    log_success "Backup de configuração em: $INSTALL_ROOT/.install.conf"

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIAR COMANDOS GLOBAIS
# ═══════════════════════════════════════════════════════════════════════════════

create_global_commands() {
    log_section "CRIANDO COMANDOS GLOBAIS"

    # Wrapper principal inteligente: vps-guardian
    cat > /usr/local/bin/vps-guardian << 'WRAPPER_EOF'
#!/bin/bash

# Procurar arquivo de configuração em locais possíveis
INSTALL_CONFIG=""
for config in "/opt/vpsguardian/.install.conf" "/opt/vpsguardian-src/.install.conf" "/opt/"*"/.install.conf" "/etc/vpsguardian/install.conf"; do
    if [ -f "$config" ]; then
        INSTALL_CONFIG="$config"
        break
    fi
done

if [ -z "$INSTALL_CONFIG" ]; then
    echo "❌ Erro: VPS Guardian não está instalado"
    echo "Execute: sudo ./instalar.sh"
    exit 1
fi

source "$INSTALL_CONFIG"

# Cores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

show_help() {
    echo -e "${GREEN}🛡️  VPS Guardian${NC} - Sistema de Manutenção e Backup VPS"
    echo ""
    echo "Uso: vps-guardian [comando] [opções]"
    echo ""
    echo "Comandos Principais:"
    echo "  menu              📋 Abre o menu principal interativo"
    echo "  backup            📦 Faz backup completo do Coolify (local)"
    echo "  backup-s3         ☁️  Faz backup completo + envia para S3"
    echo "  migrate           🚀 Migra Coolify para novo servidor"
    echo "  restore           ♻️  Restaura backup do Coolify"
    echo ""
    echo "Manutenção:"
    echo "  status            📊 Mostra status completo do sistema"
    echo "  firewall          🔥 Gerenciador interativo de firewall"
    echo "  maintenance       🔧 Executa manutenção completa"
    echo "  updates           🔄 Configura updates automáticos"
    echo ""
    echo "Configuração:"
    echo "  cron              ⏰ Configura cron jobs para backups"
    echo "  --help, -h        ❓ Mostra esta ajuda"
    echo "  --version, -v     ℹ️  Mostra versão"
    echo ""
    echo "Exemplos:"
    echo "  vps-guardian              # Abre menu principal"
    echo "  vps-guardian backup       # Backup local do Coolify"
    echo "  vps-guardian backup-s3    # Backup + upload para S3"
    echo "  vps-guardian firewall     # Gerenciar firewall (interativo)"
    echo "  vps-guardian migrate      # Migrar para novo servidor"
    echo "  vps-guardian status       # Ver status do sistema"
    echo ""
    echo "Aliases Disponíveis:"
    echo "  firewall-vps      = vps-guardian firewall"
    echo "  backup-vps        = vps-guardian backup"
    echo "  backup-s3-vps     = vps-guardian backup-s3"
    echo "  status-vps        = vps-guardian status"
    echo ""
}

show_version() {
    echo -e "${GREEN}VPS Guardian${NC} v1.0.0"
    echo "Sistema de Manutenção e Backup VPS"
    echo "Instalado em: $INSTALL_ROOT"
    echo ""
}

# Se sem argumentos, abre menu
if [ $# -eq 0 ]; then
    exec sudo bash "$INSTALL_ROOT/menu-principal.sh"
fi

# Processar comando
case "$1" in
    menu)
        exec sudo bash "$INSTALL_ROOT/menu-principal.sh"
        ;;
    backup)
        exec sudo bash "$INSTALL_ROOT/backup/backup-coolify.sh" "${@:2}"
        ;;
    backup-s3)
        if [ -f "$INSTALL_ROOT/backup/backup-coolify-s3.sh" ]; then
            exec sudo bash "$INSTALL_ROOT/backup/backup-coolify-s3.sh" "${@:2}"
        else
            echo "❌ Script de backup S3 não encontrado"
            exit 1
        fi
        ;;
    status)
        if [ -f "$INSTALL_ROOT/scripts-auxiliares/verificar-saude-completa.sh" ]; then
            exec bash "$INSTALL_ROOT/scripts-auxiliares/verificar-saude-completa.sh" "${@:2}"
        else
            echo "❌ Script de status não encontrado"
            exit 1
        fi
        ;;
    firewall)
        # Prioriza o firewall interativo se existir
        if [ -f "$INSTALL_ROOT/manutencao/firewall-interativo.sh" ]; then
            exec sudo bash "$INSTALL_ROOT/manutencao/firewall-interativo.sh" "${@:2}"
        elif [ -f "$INSTALL_ROOT/manutencao/firewall-perfil-padrao.sh" ]; then
            exec sudo bash "$INSTALL_ROOT/manutencao/firewall-perfil-padrao.sh" "${@:2}"
        else
            echo "❌ Script de firewall não encontrado"
            exit 1
        fi
        ;;
    migrate)
        if [ -f "$INSTALL_ROOT/migrar/migrar-coolify.sh" ]; then
            exec sudo bash "$INSTALL_ROOT/migrar/migrar-coolify.sh" "${@:2}"
        else
            echo "❌ Script de migração não encontrado"
            exit 1
        fi
        ;;
    restore)
        if [ -f "$INSTALL_ROOT/backup/restaurar-coolify-remoto.sh" ]; then
            exec sudo bash "$INSTALL_ROOT/backup/restaurar-coolify-remoto.sh" "${@:2}"
        else
            echo "❌ Script de restauração não encontrado"
            exit 1
        fi
        ;;
    maintenance)
        if [ -f "$INSTALL_ROOT/manutencao/manutencao-completa.sh" ]; then
            exec sudo bash "$INSTALL_ROOT/manutencao/manutencao-completa.sh" "${@:2}"
        else
            echo "❌ Script de manutenção não encontrado"
            exit 1
        fi
        ;;
    updates)
        if [ -f "$INSTALL_ROOT/manutencao/configurar-updates-automaticos.sh" ]; then
            exec sudo bash "$INSTALL_ROOT/manutencao/configurar-updates-automaticos.sh" "${@:2}"
        else
            echo "❌ Script de updates não encontrado"
            exit 1
        fi
        ;;
    cron)
        if [ -f "$INSTALL_ROOT/scripts-auxiliares/configurar-cron.sh" ]; then
            exec sudo bash "$INSTALL_ROOT/scripts-auxiliares/configurar-cron.sh" "${@:2}"
        else
            echo "❌ Script de cron não encontrado"
            exit 1
        fi
        ;;
    --help|-h)
        show_help
        ;;
    --version|-v)
        show_version
        ;;
    *)
        echo "❌ Comando desconhecido: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
WRAPPER_EOF

    chmod +x /usr/local/bin/vps-guardian
    log_success "Comando global criado: vps-guardian"

    # Criar aliases úteis
    log_info "Criando aliases úteis..."

    # firewall-vps
    ln -sf /usr/local/bin/vps-guardian /usr/local/bin/firewall-vps
    cat > /usr/local/bin/.firewall-vps-wrapper << 'EOF'
#!/bin/bash
exec vps-guardian firewall "$@"
EOF
    chmod +x /usr/local/bin/.firewall-vps-wrapper
    ln -sf /usr/local/bin/.firewall-vps-wrapper /usr/local/bin/firewall-vps

    # backup-vps
    cat > /usr/local/bin/backup-vps << 'EOF'
#!/bin/bash
exec vps-guardian backup "$@"
EOF
    chmod +x /usr/local/bin/backup-vps

    # status-vps
    cat > /usr/local/bin/status-vps << 'EOF'
#!/bin/bash
exec vps-guardian status "$@"
EOF
    chmod +x /usr/local/bin/status-vps

    # backup-s3-vps
    cat > /usr/local/bin/backup-s3-vps << 'EOF'
#!/bin/bash
exec vps-guardian backup-s3 "$@"
EOF
    chmod +x /usr/local/bin/backup-s3-vps

    log_success "Aliases criados: firewall-vps, backup-vps, backup-s3-vps, status-vps"
    echo ""
    log_info "Teste os comandos:"
    echo "  • vps-guardian --help"
    echo "  • firewall-vps (abre firewall interativo)"
    echo "  • backup-vps (faz backup)"
    echo "  • status-vps (mostra status)"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# VERIFICAÇÃO PÓS-INSTALAÇÃO
# ═══════════════════════════════════════════════════════════════════════════════

verify_installation() {
    log_section "VERIFICAÇÃO PÓS-INSTALAÇÃO"

    local errors=0

    # Verificar diretórios
    for dir in "$INSTALL_ROOT" "$BACKUP_ROOT" "$LOG_ROOT"; do
        if [ -d "$dir" ]; then
            log_success "Diretório OK: $dir"
        else
            log_error "Diretório não encontrado: $dir"
            ((errors++))
        fi
    done

    # Verificar scripts principais
    for script in menu-principal.sh backup/backup-coolify.sh manutencao/configurar-updates-automaticos.sh; do
        script_path="$INSTALL_ROOT/$script"
        if [ -f "$script_path" ] && [ -x "$script_path" ]; then
            log_success "Script OK: $script"
        else
            log_error "Script não encontrado ou não executável: $script"
            ((errors++))
        fi
    done

    # Verificar comandos globais
    if command -v vps-guardian &> /dev/null; then
        log_success "Comando global OK: vps-guardian"
    fi

    echo ""
    if [ $errors -eq 0 ]; then
        log_success "✅ Instalação verificada com sucesso!"
        return 0
    else
        log_error "❌ Instalação com $errors erro(s)"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURAÇÃO OPCIONAL
# ═══════════════════════════════════════════════════════════════════════════════

offer_additional_config() {
    log_section "CONFIGURAÇÃO ADICIONAL"

    log_info "Deseja configurar agora?"
    echo ""
    echo "  1. 🔧 Configurar firewall"
    echo "  2. 🔄 Configurar updates automáticos"
    echo "  3. ⏰ Configurar cron jobs"
    echo "  4. 📧 Configurar notificações por email"
    echo "  5. 🚀 Nenhuma (continuar depois)"
    echo ""

    read -p "Escolha uma opção (1-5): " CONFIG_CHOICE

    case $CONFIG_CHOICE in
        1)
            log_info "Iniciando configuração de firewall..."
            sudo bash "$INSTALL_ROOT/manutencao/firewall-perfil-padrao.sh"
            ;;
        2)
            log_info "Iniciando configuração de updates automáticos..."
            sudo bash "$INSTALL_ROOT/manutencao/configurar-updates-automaticos.sh"
            ;;
        3)
            log_info "Iniciando configuração de cron jobs..."
            sudo bash "$INSTALL_ROOT/scripts-auxiliares/configurar-cron.sh"
            ;;
        4)
            log_warning "Email será configurado nos scripts individuais"
            ;;
        *)
            log_info "Configurações adicionais podem ser feitas depois"
            ;;
    esac

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# DESINSTALAÇÃO
# ═══════════════════════════════════════════════════════════════════════════════

uninstall() {
    log_section "DESINSTALAÇÃO"

    log_warning "Você está prestes a desinstalar o sistema"
    log_warning "Backups e logs serão PRESERVADOS"
    echo ""

    read -p "Digite 'SIM' para confirmar desinstalação: " CONFIRM
    if [ "$CONFIRM" != "SIM" ]; then
        log_info "Desinstalação cancelada"
        return
    fi

    echo ""
    log_info "Removendo scripts..."
    rm -rf "$INSTALL_ROOT"
    log_success "Scripts removidos"

    log_info "Removendo comandos globais..."
    rm -f /usr/local/bin/vps-guardian
    log_success "Comandos globais removidos"

    log_info "Limpando configuração..."
    rm -f "$INSTALL_CONFIG"
    log_success "Configuração removida"

    log_warning "Backups e logs foram PRESERVADOS em:"
    log_warning "  - $BACKUP_ROOT"
    log_warning "  - $LOG_ROOT"
    echo ""

    log_success "✅ Desinstalação concluída"
}

# ═══════════════════════════════════════════════════════════════════════════════
# RESUMO FINAL
# ═══════════════════════════════════════════════════════════════════════════════

show_summary() {
    log_section "RESUMO DA INSTALAÇÃO"

    echo -e "${GREEN}✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO${NC}"
    echo ""

    echo "📍 Localização:"
    echo "   • Scripts: $INSTALL_ROOT"
    echo "   • Backups: $BACKUP_ROOT"
    echo "   • Logs:    $LOG_ROOT"
    echo ""

    echo "🔗 Tipo de links:"
    echo "   • $([ "$USE_SYMLINKS" = "true" ] && echo "Symlinks (atualizações fáceis com git pull)" || echo "Cópias")"
    echo ""

    echo "🛡️  Comando disponível:"
    echo "   • vps-guardian [comando]"
    echo ""
    echo "   Subcomandos:"
    echo "     - vps-guardian            (abre menu principal)"
    echo "     - vps-guardian backup     (faz backup)"
    echo "     - vps-guardian status     (mostra status)"
    echo "     - vps-guardian firewall   (configura firewall)"
    echo "     - vps-guardian updates    (configura updates)"
    echo "     - vps-guardian cron       (configura cron)"
    echo "     - vps-guardian --help     (mostra ajuda)"
    echo ""

    echo "📚 Próximos passos:"
    echo "   1. Execute o menu: ${CYAN}vps-guardian${NC}"
    echo "   2. Configure firewall: ${CYAN}vps-guardian firewall${NC} (ou Menu → 5 → 1)"
    echo "   3. Configure updates: ${CYAN}vps-guardian updates${NC} (ou Menu → 3 → 3)"
    echo "   4. Configure cron: ${CYAN}vps-guardian cron${NC} (ou Menu → 5 → 2)"
    echo "   5. Faça primeiro backup: ${CYAN}vps-guardian backup${NC}"
    echo ""

    echo "📖 Documentação:"
    echo "   • Manual completo: $INSTALL_ROOT/docs/MANUAL-COMPLETO-DO-SISTEMA.md"
    echo "   • README: Veja $(pwd)/README.md"
    echo ""

    echo "📞 Suporte:"
    echo "   • Acesso remoto seguro via Cloudflare Tunnel"
    echo "   • Zero Trust com WARP + Email Auth"
    echo "   • SSH restrito a LAN local"
    echo ""

    echo -e "${GREEN}Sistema pronto para produção! 🎉${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# FLUXO PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    show_banner
    verify_root
    verify_directory
    load_previous_config

    # Escolher modo
    choose_installation_mode || main

    case $MODE in
        uninstall)
            uninstall
            return
            ;;
        install|reinstall)
            interactive_configuration || main
            validate_paths || main
            prepare_installation
            install_scripts
            set_permissions
            create_global_commands
            save_configuration
            verify_installation || exit 1
            offer_additional_config
            show_summary
            ;;
        update)
            log_section "ATUALIZANDO"
            log_warning "Atualizando scripts mantendo configuração anterior..."
            prepare_installation
            install_scripts
            set_permissions
            verify_installation || exit 1
            log_success "✅ Sistema atualizado com sucesso!"
            echo ""
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# EXECUTAR
# ═══════════════════════════════════════════════════════════════════════════════

main "$@"
