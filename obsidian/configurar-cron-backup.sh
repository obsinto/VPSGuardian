#!/bin/bash
################################################################################
# CONFIGURAR CRON PARA BACKUP AUTOMÁTICO DO OBSIDIAN
# Propósito: Configurar agendamento automático do backup do Obsidian com GitHub
# Autor: Sistema de Manutenção e Backup VPS
# Versão: 1.0
################################################################################

# Diretório base do script (detecta automaticamente)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# Caminho do script de backup
BACKUP_SCRIPT="$SCRIPT_DIR/backup-github.sh"

################################################################################
# FUNÇÕES
################################################################################

print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                  ║${NC}"
    echo -e "${CYAN}║        ⏰ CONFIGURAR BACKUP AUTOMÁTICO DO OBSIDIAN ⏰           ║${NC}"
    echo -e "${CYAN}║                                                                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

pause() {
    echo ""
    echo -e "${GRAY}Pressione ENTER para continuar...${NC}"
    read -r
}

################################################################################
# VERIFICAR CRON EXISTENTE
################################################################################

check_existing_cron() {
    echo -e "${BLUE}→ Verificando cron existente...${NC}"
    echo ""

    if crontab -l 2>/dev/null | grep -q "obsidian.*backup-github.sh"; then
        echo -e "${YELLOW}⚠ Já existe um cron configurado para backup do Obsidian:${NC}"
        echo ""
        crontab -l 2>/dev/null | grep "obsidian\|backup-github.sh"
        echo ""
        echo -e "${YELLOW}Deseja remover e reconfigurar? [s/N]${NC}"
        read -r response
        if [[ "$response" =~ ^[sS]$ ]]; then
            remove_existing_cron
            return 0
        else
            echo -e "${YELLOW}Mantendo configuração existente.${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ Nenhum cron existente encontrado${NC}"
        return 0
    fi
}

remove_existing_cron() {
    echo -e "${BLUE}→ Removendo cron existente...${NC}"
    crontab -l 2>/dev/null | grep -v "obsidian" | grep -v "backup-github.sh" | crontab -
    echo -e "${GREEN}✓ Cron removido${NC}"
}

################################################################################
# CONFIGURAR NOVO CRON
################################################################################

configure_cron() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}CONFIGURAÇÃO DO AGENDAMENTO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Escolha a frequência do backup automático:${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC} → A cada 1 hora"
    echo -e "  ${GREEN}2${NC} → A cada 2 horas"
    echo -e "  ${GREEN}3${NC} → A cada 4 horas"
    echo -e "  ${GREEN}4${NC} → A cada 6 horas"
    echo -e "  ${GREEN}5${NC} → A cada 12 horas"
    echo -e "  ${GREEN}6${NC} → Uma vez por dia (meia-noite)"
    echo -e "  ${GREEN}7${NC} → Personalizado (você define)"
    echo ""
    echo -ne "${WHITE}Escolha [1-7]: ${NC}"
    read -r option

    case $option in
        1)
            CRON_SCHEDULE="0 * * * *"
            CRON_DESC="A cada 1 hora"
            ;;
        2)
            CRON_SCHEDULE="0 */2 * * *"
            CRON_DESC="A cada 2 horas"
            ;;
        3)
            CRON_SCHEDULE="0 */4 * * *"
            CRON_DESC="A cada 4 horas"
            ;;
        4)
            CRON_SCHEDULE="0 */6 * * *"
            CRON_DESC="A cada 6 horas"
            ;;
        5)
            CRON_SCHEDULE="0 */12 * * *"
            CRON_DESC="A cada 12 horas"
            ;;
        6)
            CRON_SCHEDULE="0 0 * * *"
            CRON_DESC="Uma vez por dia (meia-noite)"
            ;;
        7)
            echo ""
            echo -e "${YELLOW}Formato cron: MIN HOUR DAY MONTH WEEKDAY${NC}"
            echo -e "${GRAY}Exemplos:${NC}"
            echo -e "${GRAY}  0 2 * * *     → Diariamente às 2h${NC}"
            echo -e "${GRAY}  0 */3 * * *   → A cada 3 horas${NC}"
            echo -e "${GRAY}  0 9,18 * * *  → Às 9h e 18h${NC}"
            echo ""
            echo -ne "${WHITE}Digite o schedule cron: ${NC}"
            read -r CRON_SCHEDULE
            CRON_DESC="Personalizado: $CRON_SCHEDULE"
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            return 1
            ;;
    esac

    echo ""
    echo -e "${GREEN}✓ Configuração selecionada: $CRON_DESC${NC}"
    echo -e "${GRAY}  Schedule: $CRON_SCHEDULE${NC}"
    echo ""
}

################################################################################
# INSTALAR CRON
################################################################################

install_cron() {
    echo -e "${BLUE}→ Instalando cron job...${NC}"
    echo ""

    # Criar log directory
    mkdir -p /var/log/manutencao

    # Adicionar novo cron
    (crontab -l 2>/dev/null; echo "# Backup automático do Obsidian para GitHub - $CRON_DESC") | crontab -
    (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $BACKUP_SCRIPT >> /var/log/manutencao/obsidian-backup-cron.log 2>&1") | crontab -

    echo -e "${GREEN}✓ Cron job instalado com sucesso!${NC}"
    echo ""
}

################################################################################
# TESTAR CONFIGURAÇÃO
################################################################################

test_configuration() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}TESTE DA CONFIGURAÇÃO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${BLUE}→ Verificando script de backup...${NC}"
    if [ -x "$BACKUP_SCRIPT" ]; then
        echo -e "${GREEN}✓ Script encontrado e executável${NC}"
        echo -e "${GRAY}  Localização: $BACKUP_SCRIPT${NC}"
    else
        echo -e "${RED}✗ Script não encontrado ou sem permissão de execução${NC}"
        echo -e "${YELLOW}  Execute: chmod +x $BACKUP_SCRIPT${NC}"
        return 1
    fi
    echo ""

    echo -e "${BLUE}→ Verificando cron instalado...${NC}"
    if crontab -l 2>/dev/null | grep -q "$BACKUP_SCRIPT"; then
        echo -e "${GREEN}✓ Cron job está ativo${NC}"
        echo ""
        echo -e "${WHITE}Cron configurado:${NC}"
        crontab -l 2>/dev/null | grep -A 1 "Backup automático do Obsidian"
    else
        echo -e "${RED}✗ Cron job não encontrado${NC}"
        return 1
    fi
    echo ""

    echo -e "${YELLOW}Deseja executar um teste do backup agora? [s/N]${NC}"
    read -r response
    if [[ "$response" =~ ^[sS]$ ]]; then
        echo ""
        echo -e "${BLUE}→ Executando backup de teste...${NC}"
        echo ""
        bash "$BACKUP_SCRIPT"
    fi
}

################################################################################
# RESUMO FINAL
################################################################################

show_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               ✓ CONFIGURAÇÃO CONCLUÍDA COM SUCESSO              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}📊 RESUMO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✓${NC} Frequência: ${WHITE}$CRON_DESC${NC}"
    echo -e "${GREEN}✓${NC} Schedule: ${GRAY}$CRON_SCHEDULE${NC}"
    echo -e "${GREEN}✓${NC} Script: ${GRAY}$BACKUP_SCRIPT${NC}"
    echo -e "${GREEN}✓${NC} Log: ${GRAY}/var/log/manutencao/obsidian-backup-cron.log${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}📝 COMANDOS ÚTEIS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GRAY}# Ver cron jobs ativos${NC}"
    echo -e "crontab -l"
    echo ""
    echo -e "${GRAY}# Ver log do backup automático${NC}"
    echo -e "tail -f /var/log/manutencao/obsidian-backup-cron.log"
    echo ""
    echo -e "${GRAY}# Executar backup manualmente${NC}"
    echo -e "$BACKUP_SCRIPT"
    echo ""
    echo -e "${GRAY}# Remover cron do backup${NC}"
    echo -e "crontab -e  # e remova a linha do backup-github.sh"
    echo ""
}

################################################################################
# MAIN
################################################################################

main() {
    # Verificar se é root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}⚠ Este script requer privilégios de root para configurar cron${NC}"
        echo -e "${YELLOW}Execute: sudo $0${NC}"
        exit 1
    fi

    print_header

    echo -e "${WHITE}Este assistente irá configurar o backup automático do Obsidian${NC}"
    echo -e "${WHITE}para GitHub usando cron.${NC}"
    echo ""

    pause

    # Verificar script de backup
    if [ ! -f "$BACKUP_SCRIPT" ]; then
        echo -e "${RED}✗ Script de backup não encontrado:${NC}"
        echo -e "${RED}  $BACKUP_SCRIPT${NC}"
        echo ""
        echo -e "${YELLOW}Certifique-se de que o script existe neste local.${NC}"
        exit 1
    fi

    # Verificar cron existente
    print_header
    check_existing_cron || exit 0

    pause

    # Configurar novo cron
    print_header
    configure_cron || exit 1

    pause

    # Instalar cron
    print_header
    install_cron

    pause

    # Testar configuração
    print_header
    test_configuration

    pause

    # Resumo
    print_header
    show_summary
}

# Executar
main
