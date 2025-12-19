#!/bin/bash
################################################################################
# BACKUP OBSIDIAN COM GITHUB
# Propósito: Fazer backup automático do Obsidian vault para GitHub
# Autor: Sistema de Manutenção e Backup VPS
# Versão: 1.0
################################################################################

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configurações
VAULT_DIR="/root/obsidian-vault"
LOG_FILE="/var/log/manutencao/obsidian-backup.log"

# Criar diretório de logs se não existir
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# FUNÇÕES AUXILIARES
################################################################################

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}📓 BACKUP OBSIDIAN COM GITHUB${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# VERIFICAÇÕES INICIAIS
################################################################################

check_prerequisites() {
    echo -e "${BLUE}→ Verificando pré-requisitos...${NC}"
    echo ""

    # Verificar se git está instalado
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ Git não está instalado!${NC}"
        echo -e "${YELLOW}Instale com: sudo apt install git${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ Git instalado${NC}"

    # Verificar se o diretório vault existe
    if [ ! -d "$VAULT_DIR" ]; then
        echo -e "${YELLOW}⚠ Diretório do vault não existe: $VAULT_DIR${NC}"
        echo -e "${BLUE}Criando diretório...${NC}"
        mkdir -p "$VAULT_DIR"
    fi
    echo -e "${GREEN}✓ Diretório do vault: $VAULT_DIR${NC}"

    # Verificar se já é um repositório git
    if [ ! -d "$VAULT_DIR/.git" ]; then
        echo -e "${YELLOW}⚠ Vault não está inicializado como repositório Git${NC}"
        return 2
    fi
    echo -e "${GREEN}✓ Repositório Git configurado${NC}"

    echo ""
    return 0
}

################################################################################
# CONFIGURAÇÃO INICIAL DO REPOSITÓRIO
################################################################################

setup_repository() {
    print_header
    echo -e "${YELLOW}🔧 CONFIGURAÇÃO INICIAL DO REPOSITÓRIO${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Vamos configurar o repositório Git para seu vault do Obsidian."
    echo ""

    # Navegar para o diretório
    cd "$VAULT_DIR" || exit 1

    # Inicializar repositório
    echo -e "${BLUE}→ Inicializando repositório Git...${NC}"
    git init
    echo ""

    # Configurar usuário (se não estiver configurado globalmente)
    if [ -z "$(git config user.name)" ]; then
        echo -e "${YELLOW}Configure seu nome de usuário Git:${NC}"
        read -p "Nome: " git_name
        git config user.name "$git_name"
    fi

    if [ -z "$(git config user.email)" ]; then
        echo -e "${YELLOW}Configure seu email Git:${NC}"
        read -p "Email: " git_email
        git config user.email "$git_email"
    fi
    echo ""

    # Criar .gitignore
    echo -e "${BLUE}→ Criando .gitignore...${NC}"
    cat > .gitignore << 'EOF'
# Obsidian workspace
.obsidian/workspace
.obsidian/workspace.json

# Trash
.trash/

# macOS
.DS_Store

# Windows
Thumbs.db

# Temporary files
*.tmp
*~
EOF
    echo -e "${GREEN}✓ .gitignore criado${NC}"
    echo ""

    # Adicionar remote
    echo -e "${YELLOW}Configure o repositório remoto do GitHub:${NC}"
    echo -e "${GRAY}Exemplo: https://github.com/usuario/obsidian-vault.git${NC}"
    read -p "URL do repositório: " repo_url

    if [ -n "$repo_url" ]; then
        git remote add origin "$repo_url" 2>/dev/null || git remote set-url origin "$repo_url"
        echo -e "${GREEN}✓ Remote configurado${NC}"
    fi
    echo ""

    # Primeiro commit
    echo -e "${BLUE}→ Criando commit inicial...${NC}"
    git add .
    git commit -m "Initial commit - Obsidian vault setup $(date '+%Y-%m-%d')" || true
    echo ""

    # Configurar branch principal
    git branch -M main
    echo -e "${GREEN}✓ Branch 'main' configurada${NC}"
    echo ""

    # Push inicial
    echo -e "${YELLOW}Deseja fazer o push inicial agora? [s/N]${NC}"
    read -r response
    if [[ "$response" =~ ^[sS]$ ]]; then
        echo -e "${BLUE}→ Fazendo push para GitHub...${NC}"
        git push -u origin main
        echo -e "${GREEN}✓ Push inicial concluído!${NC}"
    else
        echo -e "${YELLOW}⚠ Lembre-se de fazer o push manualmente:${NC}"
        echo -e "${GRAY}  cd $VAULT_DIR && git push -u origin main${NC}"
    fi

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Repositório configurado com sucesso!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# EXECUTAR BACKUP
################################################################################

run_backup() {
    print_header
    log_message "INÍCIO: Backup Obsidian para GitHub"

    echo -e "${BLUE}→ Navegando para o vault...${NC}"
    cd "$VAULT_DIR" || {
        echo -e "${RED}✗ Erro ao acessar $VAULT_DIR${NC}"
        log_message "ERRO: Não foi possível acessar $VAULT_DIR"
        return 1
    }
    echo ""

    echo -e "${BLUE}→ Verificando mudanças...${NC}"
    if git status --porcelain | grep -q '^'; then
        echo -e "${YELLOW}Arquivos modificados encontrados:${NC}"
        git status --short
    else
        echo -e "${GREEN}Nenhuma mudança detectada${NC}"
        log_message "INFO: Nenhuma mudança para commitar"
        return 0
    fi
    echo ""

    echo -e "${BLUE}→ Adicionando mudanças ao staging...${NC}"
    git add .
    echo -e "${GREEN}✓ Mudanças adicionadas${NC}"
    echo ""

    echo -e "${BLUE}→ Criando commit...${NC}"
    COMMIT_MSG="Auto backup $(date '+%Y-%m-%d %H:%M:%S')"
    if git commit -m "$COMMIT_MSG"; then
        echo -e "${GREEN}✓ Commit criado: $COMMIT_MSG${NC}"
        log_message "SUCESSO: Commit criado - $COMMIT_MSG"
    else
        echo -e "${YELLOW}⚠ Nenhuma mudança para commitar${NC}"
        log_message "INFO: Nenhuma mudança para commitar"
        return 0
    fi
    echo ""

    echo -e "${BLUE}→ Enviando para GitHub...${NC}"
    if git push origin main; then
        echo -e "${GREEN}✓ Push concluído com sucesso!${NC}"
        log_message "SUCESSO: Backup enviado para GitHub"
    else
        echo -e "${RED}✗ Erro ao fazer push${NC}"
        echo -e "${YELLOW}Possíveis causas:${NC}"
        echo -e "  • Sem conexão com a internet"
        echo -e "  • Credenciais incorretas"
        echo -e "  • Remote não configurado"
        log_message "ERRO: Falha ao fazer push para GitHub"
        return 1
    fi
    echo ""

    # Mostrar últimos commits
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}📊 ÚLTIMOS 5 COMMITS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    git log --oneline --decorate -5
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${GREEN}✓ Backup concluído com sucesso!${NC}"
    log_message "SUCESSO: Backup Obsidian finalizado"
}

################################################################################
# MENU PRINCIPAL
################################################################################

main() {
    print_header

    # Verificar pré-requisitos
    check_prerequisites
    result=$?

    if [ $result -eq 1 ]; then
        echo -e "${RED}Instalação incompleta. Execute novamente após instalar os requisitos.${NC}"
        exit 1
    elif [ $result -eq 2 ]; then
        echo ""
        echo -e "${YELLOW}O repositório Git ainda não está configurado.${NC}"
        echo -e "${YELLOW}Deseja configurar agora? [s/N]${NC}"
        read -r response
        if [[ "$response" =~ ^[sS]$ ]]; then
            setup_repository
        else
            echo -e "${YELLOW}Configure manualmente ou execute este script novamente.${NC}"
            exit 0
        fi
    fi

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Executar backup agora? [S/n]${NC}"
    read -r response

    if [[ -z "$response" || "$response" =~ ^[sS]$ ]]; then
        run_backup
    else
        echo -e "${YELLOW}Backup cancelado.${NC}"
    fi
}

# Executar script
main
