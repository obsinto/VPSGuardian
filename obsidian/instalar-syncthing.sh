#!/bin/bash
################################################################################
# INSTALAÇÃO E CONFIGURAÇÃO DO SYNCTHING PARA OBSIDIAN
# Propósito: Instalar Syncthing e configurar com Cloudflare Zero Trust
# Autor: Sistema de Manutenção e Backup VPS
# Versão: 1.0
################################################################################

# Diretório base do script (resolve links simbólicos)
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [ -L "$SCRIPT_PATH" ]; then
    SCRIPT_PATH="$(readlink -f "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Carregar configurações
CONFIG_FILE="$SCRIPT_DIR/../config/config.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# Configurações (usa variável do config.env ou padrão)
VAULT_DIR="${OBSIDIAN_VAULT_PATH:-/root/obsidian-vault}"
CONFIG_DIR="/root/.local/state/syncthing"
LOG_FILE="/var/log/manutencao/syncthing-install.log"

# Criar diretório de logs
mkdir -p "$(dirname "$LOG_FILE")"

################################################################################
# FUNÇÕES AUXILIARES
################################################################################

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                  ║${NC}"
    echo -e "${CYAN}║        🔄 INSTALAÇÃO E CONFIGURAÇÃO DO SYNCTHING 🔄             ║${NC}"
    echo -e "${CYAN}║                                                                  ║${NC}"
    echo -e "${CYAN}║              Sincronização do Obsidian com VPS                   ║${NC}"
    echo -e "${CYAN}║                                                                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GRAY}Vault: $VAULT_DIR${NC}"
    echo -e "${GRAY}Para alterar, edite: $CONFIG_FILE${NC}"
    echo ""
}

pause() {
    echo ""
    echo -e "${GRAY}Pressione ENTER para continuar...${NC}"
    read -r
}

################################################################################
# PASSO 1: INSTALAÇÃO DO SYNCTHING
################################################################################

install_syncthing() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}PASSO 1: INSTALAÇÃO DO SYNCTHING${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Verificar se já está instalado
    if command -v syncthing &> /dev/null; then
        echo -e "${GREEN}✓ Syncthing já está instalado${NC}"
        syncthing --version
        echo ""
        return 0
    fi

    echo -e "${BLUE}→ Atualizando lista de pacotes...${NC}"
    apt update || {
        echo -e "${RED}✗ Erro ao atualizar pacotes${NC}"
        return 1
    }
    echo ""

    echo -e "${BLUE}→ Instalando dependências...${NC}"
    apt install -y curl apt-transport-https || {
        echo -e "${RED}✗ Erro ao instalar dependências${NC}"
        return 1
    }
    echo ""

    echo -e "${BLUE}→ Adicionando repositório oficial do Syncthing...${NC}"
    # Adicionar chave GPG
    curl -s https://syncthing.net/release-key.txt | gpg --dearmor -o /usr/share/keyrings/syncthing-archive-keyring.gpg || {
        echo -e "${RED}✗ Erro ao adicionar chave GPG${NC}"
        return 1
    }

    # Adicionar repositório
    echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list
    echo ""

    echo -e "${BLUE}→ Atualizando lista de pacotes...${NC}"
    apt update || {
        echo -e "${RED}✗ Erro ao atualizar pacotes${NC}"
        return 1
    }
    echo ""

    echo -e "${BLUE}→ Instalando Syncthing...${NC}"
    apt install -y syncthing || {
        echo -e "${RED}✗ Erro ao instalar Syncthing${NC}"
        return 1
    }
    echo ""

    echo -e "${GREEN}✓ Syncthing instalado com sucesso!${NC}"
    syncthing --version
    echo ""
    log_message "SUCESSO: Syncthing instalado"
}

################################################################################
# PASSO 2: CONFIGURAÇÃO DO SERVIÇO
################################################################################

configure_service() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}PASSO 2: CONFIGURAÇÃO DO SERVIÇO SYSTEMD${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${BLUE}→ Criando diretório do vault...${NC}"
    mkdir -p "$VAULT_DIR"
    echo -e "${GREEN}✓ Diretório criado: $VAULT_DIR${NC}"
    echo ""

    echo -e "${BLUE}→ Iniciando Syncthing pela primeira vez (para gerar configurações)...${NC}"
    # Iniciar e parar para gerar configs
    timeout 10 syncthing -no-browser -home="$CONFIG_DIR" &>/dev/null || true
    sleep 5
    pkill -f syncthing || true
    sleep 2
    echo -e "${GREEN}✓ Configurações iniciais geradas${NC}"
    echo ""

    echo -e "${BLUE}→ Habilitando serviço systemd...${NC}"
    systemctl enable syncthing@root || {
        echo -e "${RED}✗ Erro ao habilitar serviço${NC}"
        return 1
    }
    echo ""

    echo -e "${BLUE}→ Iniciando serviço...${NC}"
    systemctl start syncthing@root || {
        echo -e "${RED}✗ Erro ao iniciar serviço${NC}"
        return 1
    }
    echo ""

    # Aguardar serviço iniciar
    sleep 5

    echo -e "${GREEN}✓ Serviço configurado e iniciado!${NC}"
    echo ""
    systemctl status syncthing@root --no-pager | head -10
    echo ""
    log_message "SUCESSO: Serviço Syncthing configurado"
}

################################################################################
# PASSO 3: CONFIGURAR INSECURE SKIP HOSTCHECK
################################################################################

configure_insecure_skip() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}PASSO 3: HABILITAR ACESSO VIA CLOUDFLARE TUNNEL${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${YELLOW}Para acessar o Syncthing via Cloudflare Tunnel, precisamos${NC}"
    echo -e "${YELLOW}habilitar a opção 'insecureSkipHostcheck'.${NC}"
    echo ""

    echo -e "${BLUE}→ Parando serviço...${NC}"
    systemctl stop syncthing@root
    sleep 2
    echo ""

    CONFIG_FILE="$CONFIG_DIR/config.xml"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}✗ Arquivo de configuração não encontrado: $CONFIG_FILE${NC}"
        return 1
    fi

    echo -e "${BLUE}→ Criando backup da configuração...${NC}"
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${GREEN}✓ Backup criado${NC}"
    echo ""

    echo -e "${BLUE}→ Modificando configuração...${NC}"
    # Verificar se já existe a tag
    if grep -q "insecureSkipHostcheck" "$CONFIG_FILE"; then
        echo -e "${YELLOW}⚠ insecureSkipHostcheck já está configurado${NC}"
    else
        # Adicionar insecureSkipHostcheck na seção <gui>
        sed -i 's|<gui |<gui enabled="true" tls="false" debugging="false">\n    <insecureSkipHostcheck>true</insecureSkipHostcheck>\n    |' "$CONFIG_FILE" 2>/dev/null || {
            # Tentar outra abordagem se a primeira falhar
            sed -i '/<gui/a\    <insecureSkipHostcheck>true</insecureSkipHostcheck>' "$CONFIG_FILE"
        }
        echo -e "${GREEN}✓ Configuração modificada${NC}"
    fi
    echo ""

    echo -e "${BLUE}→ Reiniciando serviço...${NC}"
    systemctl start syncthing@root
    sleep 5
    echo -e "${GREEN}✓ Serviço reiniciado${NC}"
    echo ""

    log_message "SUCESSO: insecureSkipHostcheck habilitado"
}

################################################################################
# PASSO 4: CONFIGURAR SENHA
################################################################################

configure_password() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}PASSO 4: CONFIGURAR SENHA DE ACESSO (OBRIGATÓRIO)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${YELLOW}⚠ IMPORTANTE: Configure uma senha forte para proteger o acesso!${NC}"
    echo ""
    echo -e "${WHITE}Acesse a interface web do Syncthing para configurar a senha:${NC}"
    echo ""
    echo -e "${GREEN}Se você JÁ configurou Cloudflare Tunnel:${NC}"
    echo -e "  ${BLUE}https://syncthing.seu-dominio.com${NC}"
    echo ""
    echo -e "${GREEN}Se ainda NÃO tem Cloudflare Tunnel:${NC}"
    echo -e "  ${BLUE}1.${NC} Acesse temporariamente via SSH tunnel:"
    echo -e "     ${GRAY}ssh -L 8384:localhost:8384 root@seu-servidor${NC}"
    echo -e "  ${BLUE}2.${NC} Abra no navegador: ${BLUE}http://localhost:8384${NC}"
    echo ""
    echo -e "${YELLOW}Após acessar:${NC}"
    echo -e "  ${BLUE}1.${NC} Clique em 'Actions' (canto superior direito)"
    echo -e "  ${BLUE}2.${NC} Selecione 'Settings'"
    echo -e "  ${BLUE}3.${NC} Vá em 'GUI'"
    echo -e "  ${BLUE}4.${NC} Em 'Authentication', configure:"
    echo -e "     • User name: ${GREEN}seu-usuario${NC}"
    echo -e "     • Password: ${GREEN}senha-forte${NC}"
    echo -e "  ${BLUE}5.${NC} Clique em 'Save'"
    echo ""
}

################################################################################
# PASSO 5: CONFIGURAR CLOUDFLARE TUNNEL
################################################################################

configure_cloudflare_tunnel() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}PASSO 5: CONFIGURAR CLOUDFLARE ZERO TRUST TUNNEL${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${YELLOW}Configure um tunnel no Cloudflare Zero Trust Dashboard:${NC}"
    echo ""
    echo -e "${BLUE}1.${NC} Acesse: ${BLUE}https://one.dash.cloudflare.com${NC}"
    echo -e "${BLUE}2.${NC} Vá em: ${WHITE}Access → Tunnels${NC}"
    echo -e "${BLUE}3.${NC} Crie um novo tunnel (ou edite existente)"
    echo -e "${BLUE}4.${NC} Adicione uma Public Hostname:"
    echo ""
    echo -e "   ${GREEN}Subdomain:${NC} syncthing"
    echo -e "   ${GREEN}Domain:${NC} seu-dominio.com"
    echo -e "   ${GREEN}Service Type:${NC} HTTP"
    echo -e "   ${GREEN}URL:${NC} localhost:8384"
    echo ""
    echo -e "${BLUE}5.${NC} Salve e aguarde alguns segundos"
    echo -e "${BLUE}6.${NC} Acesse: ${GREEN}https://syncthing.seu-dominio.com${NC}"
    echo ""
    echo -e "${WHITE}Pronto! Agora você pode acessar o Syncthing de qualquer lugar.${NC}"
    echo ""
}

################################################################################
# PASSO 6: ADICIONAR PASTA DO OBSIDIAN
################################################################################

configure_obsidian_folder() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}PASSO 6: ADICIONAR PASTA DO OBSIDIAN NO SYNCTHING${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${YELLOW}Na interface web do Syncthing:${NC}"
    echo ""
    echo -e "${BLUE}1.${NC} Clique em ${WHITE}'Add Folder'${NC}"
    echo ""
    echo -e "${BLUE}2.${NC} Preencha:"
    echo -e "   ${GREEN}Folder Label:${NC} Obsidian Vault"
    echo -e "   ${GREEN}Folder Path:${NC} $VAULT_DIR"
    echo ""
    echo -e "${BLUE}3.${NC} Vá na aba ${WHITE}'Sharing'${NC}"
    echo -e "   • Não compartilhe ainda (faremos depois de configurar outros dispositivos)"
    echo ""
    echo -e "${BLUE}4.${NC} Vá na aba ${WHITE}'File Versioning'${NC} (RECOMENDADO)"
    echo -e "   ${GREEN}File Versioning:${NC} Simple File Versioning"
    echo -e "   ${GREEN}Keep Versions:${NC} 10"
    echo -e "   ${GRAY}(Mantém as últimas 10 versões de cada arquivo)${NC}"
    echo ""
    echo -e "${BLUE}5.${NC} Clique em ${WHITE}'Save'${NC}"
    echo ""
}

################################################################################
# PASSO 7: CONECTAR DISPOSITIVOS
################################################################################

show_device_connection_guide() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}PASSO 7: CONECTAR SEUS DISPOSITIVOS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${YELLOW}No seu PC/Celular:${NC}"
    echo ""
    echo -e "${BLUE}1.${NC} Instale o Syncthing:"
    echo -e "   ${GREEN}Windows/Mac/Linux:${NC} https://syncthing.net/downloads/"
    echo -e "   ${GREEN}Android:${NC} Play Store - 'Syncthing'"
    echo -e "   ${GREEN}iOS:${NC} App Store - 'Möbius Sync'"
    echo ""
    echo -e "${BLUE}2.${NC} Abra o Syncthing no dispositivo"
    echo ""
    echo -e "${BLUE}3.${NC} Clique em ${WHITE}'Actions → Show ID'${NC}"
    echo -e "   • Copie ou tire print do QR Code"
    echo ""
    echo -e "${BLUE}4.${NC} No Syncthing do VPS (interface web):"
    echo -e "   • Clique em ${WHITE}'Add Remote Device'${NC}"
    echo -e "   • Cole o Device ID ou escaneie o QR Code"
    echo -e "   • Em 'Sharing', marque a pasta ${GREEN}'Obsidian Vault'${NC}"
    echo -e "   • Clique em 'Save'"
    echo ""
    echo -e "${BLUE}5.${NC} No dispositivo, aceite a solicitação de conexão"
    echo ""
    echo -e "${BLUE}6.${NC} No dispositivo, quando aparecer solicitação da pasta:"
    echo -e "   • Escolha o caminho do seu vault do Obsidian"
    echo -e "   • Aceite o compartilhamento"
    echo ""
    echo -e "${GREEN}✓ Pronto! Seus dispositivos começarão a sincronizar!${NC}"
    echo ""
}

################################################################################
# RESUMO FINAL
################################################################################

show_summary() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     ✓ INSTALAÇÃO CONCLUÍDA                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}📊 RESUMO DA INSTALAÇÃO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}✓${NC} Syncthing instalado e rodando"
    echo -e "${GREEN}✓${NC} Serviço systemd habilitado"
    echo -e "${GREEN}✓${NC} insecureSkipHostcheck configurado"
    echo -e "${GREEN}✓${NC} Pasta do vault: $VAULT_DIR"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}📝 PRÓXIMOS PASSOS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} Configure senha na interface web"
    echo -e "${YELLOW}2.${NC} Configure Cloudflare Tunnel"
    echo -e "${YELLOW}3.${NC} Adicione a pasta do Obsidian"
    echo -e "${YELLOW}4.${NC} Conecte seus dispositivos"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🔗 LINKS ÚTEIS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}Interface local:${NC} http://localhost:8384"
    echo -e "${BLUE}Via Cloudflare:${NC} https://syncthing.seu-dominio.com"
    echo -e "${BLUE}Documentação:${NC} https://docs.syncthing.net/"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🛠️  COMANDOS ÚTEIS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GRAY}# Ver status do serviço${NC}"
    echo -e "systemctl status syncthing@root"
    echo ""
    echo -e "${GRAY}# Ver logs${NC}"
    echo -e "journalctl -u syncthing@root -f"
    echo ""
    echo -e "${GRAY}# Reiniciar serviço${NC}"
    echo -e "systemctl restart syncthing@root"
    echo ""
    echo -e "${GRAY}# Parar serviço${NC}"
    echo -e "systemctl stop syncthing@root"
    echo ""
}

################################################################################
# MENU PRINCIPAL
################################################################################

main() {
    # Verificar se é root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Este script precisa ser executado como root!${NC}"
        echo -e "${YELLOW}Execute: sudo $0${NC}"
        exit 1
    fi

    print_header
    log_message "INÍCIO: Instalação do Syncthing"

    # Passo 1: Instalar
    install_syncthing || {
        echo -e "${RED}Erro na instalação. Verifique os logs.${NC}"
        exit 1
    }
    pause

    # Passo 2: Configurar serviço
    print_header
    configure_service || {
        echo -e "${RED}Erro na configuração do serviço.${NC}"
        exit 1
    }
    pause

    # Passo 3: Habilitar insecureSkipHostcheck
    print_header
    configure_insecure_skip || {
        echo -e "${YELLOW}⚠ Aviso: Erro ao configurar insecureSkipHostcheck${NC}"
        echo -e "${YELLOW}Configure manualmente no arquivo:${NC}"
        echo -e "${GRAY}$CONFIG_DIR/config.xml${NC}"
    }
    pause

    # Passo 4: Instruções de senha
    print_header
    configure_password
    pause

    # Passo 5: Instruções Cloudflare
    print_header
    configure_cloudflare_tunnel
    pause

    # Passo 6: Instruções pasta Obsidian
    print_header
    configure_obsidian_folder
    pause

    # Passo 7: Instruções dispositivos
    print_header
    show_device_connection_guide
    pause

    # Resumo final
    print_header
    show_summary

    log_message "SUCESSO: Instalação do Syncthing concluída"
}

# Executar
main
