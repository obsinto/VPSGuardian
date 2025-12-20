#!/bin/bash

################################################################################
# Script: firewall-perfil-padrao.sh
# Propósito: Aplicar configuração UFW padrão otimizada para Coolify + Cloudflared
# Uso: sudo ./firewall-perfil-padrao.sh
#
# Esta configuração foi testada e aprovada para:
# - Coolify rodando normalmente
# - Cloudflare Tunnel funcionando
# - SSH seguro e acessível apenas da LAN
################################################################################

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
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      Firewall UFW - Perfil Padrão (Coolify + Cloudflared)    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# =========================================
# CONFIGURAR REDE LAN DO USUÁRIO
# =========================================
log_info "Configurando rede LAN para acesso SSH..."
echo ""
echo -e "${BLUE}💡 Sua rede LAN local (ex: 192.168.31, 192.168.1, 10.0.0):${NC}"
echo ""
echo -e "${GRAY}Como descobrir sua rede LAN:${NC}"
echo "  • Linux/Mac:  ${YELLOW}ip addr | grep inet${NC}"
echo "  • Windows:    ${YELLOW}ipconfig${NC}"
echo "  • Resultado:  ${GRAY}192.168.31.105 → use 192.168.31${NC}"
echo ""

# Validar entrada
NETWORK_INPUT=""
while [ -z "$NETWORK_INPUT" ] || ! [[ $NETWORK_INPUT =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; do
    read -p "Digite os 3 primeiros octetos da sua rede (ex: 192.168.31): " -r NETWORK_INPUT

    # Validar formato
    if ! [[ $NETWORK_INPUT =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        log_error "Formato inválido. Use: X.X.X (ex: 192.168.31)"
        NETWORK_INPUT=""
        continue
    fi

    # Validar range de cada octeto
    IFS='.' read -r -a octets <<< "$NETWORK_INPUT"
    valid=true
    for octet in "${octets[@]}"; do
        if [ "$octet" -gt 255 ] 2>/dev/null; then
            valid=false
            break
        fi
    done

    if [ "$valid" != "true" ]; then
        log_error "Octeto inválido (deve ser 0-255). Tente novamente."
        NETWORK_INPUT=""
        continue
    fi
done

LAN_NETWORK="${NETWORK_INPUT}.0/24"
echo ""
log_success "Rede LAN configurada: $LAN_NETWORK"
echo ""

# Mostrar configuração que será aplicada
echo -e "${BLUE}📋 Configuração que será aplicada:${NC}"
echo ""
echo "  Política Padrão:"
echo "    • Incoming: DENY (bloqueia tudo por padrão)"
echo "    • Outgoing: ALLOW (permite conexões saintes)"
echo "    • Routed: ALLOW"
echo ""
echo "  Portas:"
echo "    • HTTP (80/tcp):    PÚBLICO"
echo "    • HTTPS (443/tcp):  PÚBLICO"
echo "    • SSH (22):         RESTRITO"
echo ""
echo "  SSH Permitido De:"
echo "    • 127.0.0.1 (Localhost)"
echo "    • ${LAN_NETWORK} (Sua LAN)"
echo "    • 10.0.0.0/8 (Redes Docker/Coolify)"
echo ""
echo "  Loopback:"
echo "    • Permitido (necessário para Cloudflare Tunnel)"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Confirmação
log_warning "Este script irá RESETAR todas as regras do firewall!"
echo ""
read -p "Deseja continuar? (s/N): " -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log_info "Operação cancelada pelo usuário"
    exit 0
fi

echo ""
log_info "Iniciando configuração do firewall..."
echo ""

# =========================================
# RESET COMPLETO
# =========================================
log_info "Resetando configuração do UFW..."
ufw --force reset > /dev/null 2>&1
log_success "Firewall resetado"
echo ""

# =========================================
# POLÍTICA PADRÃO
# =========================================
log_info "Configurando política padrão..."
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw default allow routed > /dev/null 2>&1
log_success "Política padrão configurada"
echo ""

# =========================================
# LOOPBACK (ESSENCIAL PARA CLOUDFLARE TUNNEL)
# =========================================
log_info "Permitindo tráfego loopback..."
ufw allow in on lo > /dev/null 2>&1
ufw allow out on lo > /dev/null 2>&1
log_success "Loopback configurado"
echo ""

# =========================================
# HTTP/HTTPS (COOLIFY - PÚBLICO)
# =========================================
log_info "Permitindo HTTP/HTTPS público..."
ufw allow 80/tcp comment 'HTTP' > /dev/null 2>&1
ufw allow 443/tcp comment 'HTTPS' > /dev/null 2>&1
log_success "HTTP/HTTPS configurado"
echo ""

# =========================================
# SSH - LOCALHOST
# =========================================
log_info "Permitindo SSH via localhost..."
ufw allow from 127.0.0.1 to any port 22 comment 'SSH localhost' > /dev/null 2>&1
log_success "SSH localhost configurado"
echo ""

# =========================================
# SSH - REDE LAN (Configurada pelo usuário)
# =========================================
log_info "Permitindo SSH da rede LAN (${LAN_NETWORK})..."
ufw allow from "$LAN_NETWORK" to any port 22 comment 'SSH LAN' > /dev/null 2>&1
log_success "SSH LAN configurado"
echo ""

# =========================================
# SSH - REDES DOCKER (Coolify)
# =========================================
log_info "Permitindo SSH das redes Docker (10.0.0.0/8)..."
ufw allow from 10.0.0.0/8 to any port 22 comment 'SSH Docker networks' > /dev/null 2>&1
log_success "SSH Docker networks configurado"
echo ""

# =========================================
# ATIVA O FIREWALL
# =========================================
log_info "Ativando o firewall..."
ufw --force enable > /dev/null 2>&1
log_success "Firewall ativado"
echo ""

# =========================================
# VERIFICA STATUS
# =========================================
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              ✅ Firewall Configurado com Sucesso              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${BLUE}Status do Firewall:${NC}"
echo ""
ufw status numbered
echo ""

# =========================================
# TESTES DE CONECTIVIDADE
# =========================================
echo -e "${BLUE}🧪 Testando conectividade...${NC}"
echo ""

# Verificar se Docker está disponível
if command -v docker &> /dev/null; then
    echo -e "${BLUE}1️⃣ Docker → Internet:${NC}"
    if docker run --rm --network coolify alpine sh -c "wget -qO- https://api.github.com/zen" 2>/dev/null; then
        echo -e "${GREEN}✅ Internet OK${NC}"
    else
        echo -e "${YELLOW}⚠️  Internet Falhou${NC}"
        log_warning "Verifique a rede 'coolify' do Docker"
    fi
    echo ""

    echo -e "${BLUE}2️⃣ SSH (Host via Docker):${NC}"
    if docker run --rm --network coolify --add-host=host.docker.internal:host-gateway alpine sh -c "apk add --no-cache netcat-openbsd >/dev/null 2>&1 && nc -z -w 5 host.docker.internal 22" 2>/dev/null; then
        echo -e "${GREEN}✅ SSH (Porta 22 Host) OK${NC}"
    else
        echo -e "${YELLOW}⚠️  SSH (Porta 22 Host) Pode estar desativado${NC}"
        log_warning "Isso é normal se o serviço SSH não estiver rodando"
    fi
else
    log_warning "Docker não encontrado, pulando testes de conectividade"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
log_success "Configuração finalizada!"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

log_warning "⚠️  IMPORTANTE:"
echo "  • SSH está restrito a:"
echo "      - Localhost (127.0.0.1)"
echo "      - Rede LAN (${LAN_NETWORK})"
echo "      - Redes Docker (10.0.0.0/8)"
echo ""
echo "  • Para alterar a rede LAN novamente, rode este script"
echo "  • Para acesso remoto seguro, use Cloudflare Tunnel"
echo "  • HTTP/HTTPS estão abertos publicamente"
echo ""

log_info "Comandos úteis:"
echo "  • Ver status: sudo ufw status verbose"
echo "  • Ver logs: sudo tail -f /var/log/ufw.log"
echo "  • Modificar rede LAN: edite 192.168.31.0/24 neste script"
echo ""

# =========================================
# CONFIGURAR TAILSCALE (OPCIONAL)
# =========================================

# Verificar se Tailscale está disponível
if command -v tailscale &> /dev/null && ip link show tailscale0 &> /dev/null 2>&1; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                  Tailscale VPN Detectado                      ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "Tailscale está instalado e rodando"
    echo ""
    read -p "Deseja adicionar regras do Tailscale ao firewall? (s/N): " -r
    echo ""

    if [[ $REPLY =~ ^[Ss]$ ]]; then
        log_info "Adicionando regras do Tailscale ao UFW..."
        echo ""

        # Permitir todo tráfego de entrada na interface tailscale0
        ufw allow in on tailscale0 comment 'Tailscale all' > /dev/null 2>&1
        log_success "  ✓ Permitido todo tráfego de entrada em tailscale0"

        # Permitir SSH na interface tailscale0
        ufw allow in on tailscale0 to any port 22 comment 'Tailscale SSH' > /dev/null 2>&1
        log_success "  ✓ Permitido SSH em tailscale0"

        # Permitir todo tráfego de saída na interface tailscale0
        ufw allow out on tailscale0 comment 'Tailscale out' > /dev/null 2>&1
        log_success "  ✓ Permitido tráfego de saída em tailscale0"

        echo ""
        log_success "Regras do Tailscale configuradas com sucesso!"
        echo ""
        log_info "Você agora pode acessar este servidor via Tailscale VPN"
        echo ""

        # Mostrar status atualizado
        echo "╔═══════════════════════════════════════════════════════════════╗"
        echo "║              Status do Firewall (com Tailscale)              ║"
        echo "╚═══════════════════════════════════════════════════════════════╝"
        echo ""
        ufw status numbered
        echo ""
    fi
fi
