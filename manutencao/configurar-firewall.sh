#!/bin/bash

# =========================================
# Script de Configuração do Firewall UFW
# =========================================
#
# Configura o firewall com regras otimizadas para:
# - Coolify (HTTP/HTTPS público)
# - SSH restrito (localhost + LAN + Docker networks)
# - Cloudflare Tunnel (via localhost)
#
# Uso: sudo ./configurar-firewall.sh

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

# Verifica se está rodando como root
if [[ $EUID -ne 0 ]]; then
   log_error "Este script precisa ser executado como root (sudo)"
   exit 1
fi

# Banner
echo "=========================================="
echo "  Configuração do Firewall UFW"
echo "=========================================="
echo ""

# =========================================
# DETECTAR IP DE ORIGEM DA CONEXÃO SSH
# =========================================
log_info "Detectando origem da sua conexão..."
echo ""

# Detectar o IP de onde o usuário está conectado via SSH
SSH_CLIENT_IP=""
if [ -n "$SSH_CONNECTION" ]; then
    SSH_CLIENT_IP=$(echo "$SSH_CONNECTION" | awk '{print $1}')
fi

# Tentar também via variável SSH_CLIENT
if [ -z "$SSH_CLIENT_IP" ] && [ -n "$SSH_CLIENT" ]; then
    SSH_CLIENT_IP=$(echo "$SSH_CLIENT" | awk '{print $1}')
fi

# Tentar detectar via who/w
if [ -z "$SSH_CLIENT_IP" ]; then
    SSH_CLIENT_IP=$(who am i | awk '{print $5}' | sed 's/[()]//g')
fi

SUGGESTED_NETWORK="192.168.1"
CONNECTION_TYPE=""

if [ -n "$SSH_CLIENT_IP" ] && [ "$SSH_CLIENT_IP" != "127.0.0.1" ]; then
    # Verificar se é um IP privado válido
    if [[ $SSH_CLIENT_IP =~ ^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.) ]]; then
        # IP privado - conexão direta LAN ou VPN
        SUGGESTED_NETWORK=$(echo "$SSH_CLIENT_IP" | cut -d. -f1-3)
        CONNECTION_TYPE="LAN"
        echo -e "${GREEN}✓ Conexão detectada: LAN (Rede Local)${NC}"
        echo -e "${BLUE}  Seu IP na rede:${NC} $SSH_CLIENT_IP"
        echo -e "${BLUE}  Rede sugerida:${NC} ${SUGGESTED_NETWORK}.0/24"
        echo ""
        echo -e "${GRAY}  → Você está conectando diretamente da rede local${NC}"
    else
        # IP público - CGNAT, VPN, Internet direta, ou Cloudflare Tunnel
        CONNECTION_TYPE="PUBLIC"
        echo -e "${YELLOW}⚠ Conexão detectada: Internet (IP Público)${NC}"
        echo -e "${BLUE}  IP de origem:${NC} $SSH_CLIENT_IP"
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}  ⚠️  IMPORTANTE - CGNAT/IP PÚBLICO DETECTADO ⚠️${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${GRAY}Possíveis cenários:${NC}"
        echo "  • Você está atrás de CGNAT (Carrier-Grade NAT)"
        echo "  • Conectando via Cloudflare Tunnel"
        echo "  • Usando VPN externa"
        echo "  • Acesso direto pela internet"
        echo ""
        echo -e "${RED}⚠ Não é possível detectar sua rede LAN automaticamente!${NC}"
        echo ""
        echo -e "${BLUE}💡 Como descobrir sua rede LAN:${NC}"
        echo "  1. No seu computador local, execute:"
        echo -e "     ${WHITE}ip addr${NC} (Linux) ou ${WHITE}ipconfig${NC} (Windows)"
        echo "  2. Procure seu IP local (ex: 192.168.1.100)"
        echo "  3. Use os 3 primeiros números (ex: 192.168.1)"
        echo ""
    fi
else
    # Não conseguiu detectar
    CONNECTION_TYPE="UNKNOWN"
    log_warning "Não foi possível detectar o IP de origem"
    echo -e "${GRAY}  → Você pode estar executando localmente na VPS${NC}"
    echo ""
fi

echo -e "${BLUE}  Rede sugerida padrão:${NC} ${SUGGESTED_NETWORK}.0/24"
echo -e "${GRAY}  (Você pode alterar a seguir)${NC}"

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}Configure MANUALMENTE o range de IPs para acesso SSH${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$CONNECTION_TYPE" = "PUBLIC" ]; then
    echo -e "${RED}⚠ ATENÇÃO: Você está atrás de CGNAT ou IP público!${NC}"
    echo ""
    echo -e "${WHITE}📋 PASSO A PASSO - Como descobrir sua rede LAN:${NC}"
    echo ""
    echo -e "${BLUE}1. No seu computador/celular LOCAL (não na VPS):${NC}"
    echo ""
    echo -e "   ${WHITE}Linux/Mac:${NC}"
    echo -e "   ${GRAY}\$ ip addr | grep inet${NC}"
    echo -e "   ${GRAY}ou${NC}"
    echo -e "   ${GRAY}\$ ifconfig | grep inet${NC}"
    echo ""
    echo -e "   ${WHITE}Windows (CMD ou PowerShell):${NC}"
    echo -e "   ${GRAY}> ipconfig${NC}"
    echo ""
    echo -e "   ${WHITE}Android:${NC}"
    echo -e "   ${GRAY}Configurações → Wi-Fi → [sua rede] → Detalhes${NC}"
    echo ""
    echo -e "   ${WHITE}iPhone:${NC}"
    echo -e "   ${GRAY}Ajustes → Wi-Fi → (i) ao lado da sua rede${NC}"
    echo ""
    echo -e "${BLUE}2. Procure seu IP local:${NC}"
    echo -e "   ${GRAY}Exemplo: 192.168.1.105 ou 10.0.0.50${NC}"
    echo ""
    echo -e "${BLUE}3. Use os 3 primeiros números:${NC}"
    echo -e "   ${GRAY}Se seu IP é 192.168.1.105 → digite: 192.168.1${NC}"
    echo -e "   ${GRAY}Se seu IP é 10.0.0.50     → digite: 10.0.0${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

echo -e "${WHITE}O SSH será restrito apenas aos IPs da sua LAN local.${NC}"
echo ""
echo -e "${BLUE}💡 Como funciona:${NC}"
echo "  • Digite os 3 primeiros octetos da sua rede local (ex: 192.168.31)"
echo "  • O script adiciona automaticamente .0/24 ao final"
echo "  • Isso permite todos os IPs de X.X.X.1 até X.X.X.254"
echo ""
echo -e "${GRAY}Exemplos comuns:${NC}"
echo "  • 192.168.0  → Permite 192.168.0.1 até 192.168.0.254"
echo "  • 192.168.1  → Permite 192.168.1.1 até 192.168.1.254"
echo "  • 10.0.0     → Permite 10.0.0.1 até 10.0.0.254"
echo ""
echo -e "${YELLOW}💡 DICA IMPORTANTE:${NC}"
echo "  • Se você acessa de múltiplas redes (casa, trabalho, etc),"
echo "    você pode adicionar várias redes neste script"
echo "  • Para acesso de QUALQUER LUGAR, use Cloudflare Tunnel"
echo "    (não configure SSH no firewall neste caso)"
echo ""

# Array para armazenar redes
declare -a LAN_NETWORKS

# Loop para adicionar redes
while true; do
    if [ ${#LAN_NETWORKS[@]} -eq 0 ]; then
        prompt_msg="Digite os 3 primeiros octetos [${SUGGESTED_NETWORK}]: "
    else
        prompt_msg="Digite outra rede (ou deixe vazio para continuar): "
    fi

    read -p "$prompt_msg" -r NETWORK_INPUT

    # Se vazio
    if [ -z "$NETWORK_INPUT" ]; then
        if [ ${#LAN_NETWORKS[@]} -eq 0 ]; then
            # Primeira vez e vazio, usa sugerido
            NETWORK_INPUT="$SUGGESTED_NETWORK"
        else
            # Já tem redes, usuário quer continuar
            break
        fi
    fi

    # Validar formato (3 octetos)
    if [[ $NETWORK_INPUT =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # Validar ranges de cada octeto
        IFS='.' read -r -a octets <<< "$NETWORK_INPUT"
        valid=true
        for octet in "${octets[@]}"; do
            if [ "$octet" -gt 255 ]; then
                valid=false
                break
            fi
        done

        if [ "$valid" = true ]; then
            NETWORK="${NETWORK_INPUT}.0/24"

            # Verificar se já foi adicionada
            if [[ " ${LAN_NETWORKS[@]} " =~ " ${NETWORK} " ]]; then
                log_warning "Esta rede já foi adicionada!"
            else
                LAN_NETWORKS+=("$NETWORK")
                echo -e "${GREEN}✓ Rede adicionada:${NC} $NETWORK"
            fi

            # Se só tem uma rede, perguntar se quer adicionar mais
            if [ ${#LAN_NETWORKS[@]} -eq 1 ]; then
                echo ""
                echo -e "${BLUE}Deseja adicionar outra rede LAN?${NC}"
                echo -e "${GRAY}(útil se você acessa de casa e trabalho)${NC}"
            fi
        else
            log_error "Octeto inválido (deve ser 0-255). Tente novamente."
        fi
    else
        log_error "Formato inválido. Use o formato: X.X.X (ex: 192.168.1)"
    fi
done

echo ""
echo -e "${GREEN}✓ Configuração completa!${NC}"
echo -e "${WHITE}Redes que terão acesso SSH:${NC}"
for network in "${LAN_NETWORKS[@]}"; do
    echo -e "  • $network"
done
echo ""

# Confirma a ação
log_warning "Este script irá RESETAR todas as regras do firewall!"
echo ""
echo "Configuração que será aplicada:"
echo "  • Política padrão: DENY incoming, ALLOW outgoing"
echo "  • Loopback: PERMITIDO (essencial para CF Tunnel)"
echo "  • HTTP (80): PÚBLICO"
echo "  • HTTPS (443): PÚBLICO"
echo "  • SSH (22): RESTRITO aos seguintes destinos:"
echo "      - Localhost (127.0.0.1)"
echo "      - Redes Docker (10.0.0.0/8) - para Coolify gerenciar"
echo "      - Suas redes LAN:"
for network in "${LAN_NETWORKS[@]}"; do
    echo "        → $network"
done
echo ""
read -p "Deseja continuar? (s/N): " -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_info "Operação cancelada pelo usuário"
    exit 0
fi

# =========================================
# RESET COMPLETO
# =========================================
log_info "Resetando configuração do UFW..."
ufw --force reset
log_success "Firewall resetado"

# =========================================
# POLÍTICA PADRÃO
# =========================================
log_info "Configurando política padrão..."
ufw default deny incoming
ufw default allow outgoing
log_success "Política padrão configurada"

# =========================================
# LOOPBACK (ESSENCIAL)
# =========================================
log_info "Permitindo tráfego loopback..."
ufw allow in on lo
ufw allow out on lo
log_success "Loopback configurado"

# =========================================
# HTTP/HTTPS (COOLIFY - PÚBLICO)
# =========================================
log_info "Permitindo HTTP/HTTPS público..."
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
log_success "HTTP/HTTPS configurado"

# =========================================
# SSH - LOCALHOST
# =========================================
log_info "Permitindo SSH via localhost..."
ufw allow from 127.0.0.1 to any port 22 comment 'SSH localhost'
log_success "SSH localhost configurado"

# =========================================
# SSH - REDES DOCKER
# =========================================
log_info "Permitindo SSH das redes Docker (Coolify)..."
ufw allow from 10.0.0.0/8 to any port 22 comment 'SSH Docker networks'
log_success "SSH Docker networks configurado"

# =========================================
# SSH - REDES LAN DO USUÁRIO
# =========================================
log_info "Configurando SSH restrito às LANs autorizadas..."
for network in "${LAN_NETWORKS[@]}"; do
    ufw allow from "$network" to any port 22 comment 'SSH LAN'
    echo -e "${BLUE}  → Permitido:${NC} $network"
done
log_success "SSH LAN configurado (${#LAN_NETWORKS[@]} rede(s) autorizada(s))"

# =========================================
# ATIVA O FIREWALL
# =========================================
log_info "Ativando o firewall..."
ufw --force enable
log_success "Firewall ativado"

# =========================================
# VERIFICA STATUS
# =========================================
echo ""
echo "=========================================="
echo "  ✅ UFW Configurado com Sucesso"
echo "=========================================="
echo ""
ufw status numbered

# =========================================
# TESTES DE CONECTIVIDADE
# =========================================
echo ""
log_info "🧪 Testando conectividade..."
echo ""

# Verificar se Docker está disponível
if command -v docker &> /dev/null; then
    echo -e "${BLUE}1️⃣ Docker → Internet:${NC}"
    if docker run --rm --network coolify alpine sh -c "wget -qO- https://api.github.com/zen" 2>/dev/null; then
        echo -e "${GREEN}✅ Internet OK${NC}"
    else
        echo -e "${RED}❌ Internet Falhou${NC}"
        log_warning "Verifique a rede 'coolify' do Docker"
    fi
    echo ""

    echo -e "${BLUE}2️⃣ SSH (Host via Docker):${NC}"
    if docker run --rm --network coolify --add-host=host.docker.internal:host-gateway alpine sh -c "apk add --no-cache netcat-openbsd >/dev/null 2>&1 && nc -z -w 5 host.docker.internal 22" 2>/dev/null; then
        echo -e "${GREEN}✅ SSH (Porta 22 Host) OK${NC}"
    else
        echo -e "${RED}❌ SSH (Porta 22 Host) Falhou${NC}"
        log_warning "Isso pode ser normal se o serviço SSH não estiver rodando"
    fi
else
    log_warning "Docker não encontrado, pulando testes de conectividade"
fi

# =========================================
# RESUMO E AVISOS
# =========================================
echo ""
echo "=========================================="
log_success "Configuração finalizada!"
echo "=========================================="
echo ""
log_warning "IMPORTANTE:"
echo "  • SSH só é acessível de:"
echo "      - Localhost (127.0.0.1)"
echo "      - Redes Docker (10.0.0.0/8)"
echo "      - Suas redes LAN:"
for network in "${LAN_NETWORKS[@]}"; do
    echo "        → $network"
done
echo ""
echo "  • Para acesso remoto seguro, use Cloudflare Tunnel"
echo "  • HTTP/HTTPS estão abertos publicamente"
echo "  • Loopback está permitido (necessário para CF Tunnel)"
echo ""
log_info "Para verificar o status: sudo ufw status verbose"
log_info "Para adicionar mais redes: rode este script novamente"
log_info "Para ver logs: sudo tail -f /var/log/ufw.log"
echo ""
