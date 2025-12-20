#!/bin/bash
################################################################################
# Script: firewall-interativo.sh
# Propósito: Gerenciador interativo de firewall UFW com múltiplos perfis
# Uso: sudo ./firewall-interativo.sh
#
# Modos disponíveis:
# 1. Seguro (Cloudflare Tunnel) - Porta 22 fechada publicamente
# 2. Híbrido - Cloudflare + Whitelist IPs
# 3. Básico - Apenas Whitelist IPs (simples)
################################################################################

# Carregar bibliotecas compartilhadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

init_script

# Arquivo de configuração de IPs
WHITELIST_FILE="/etc/vpsguardian/firewall-whitelist.conf"

################################################################################
# FUNÇÕES AUXILIARES
################################################################################

# Criar arquivo de whitelist se não existir
ensure_whitelist_file() {
    ensure_directory "$(dirname "$WHITELIST_FILE")" 755
    if [ ! -f "$WHITELIST_FILE" ]; then
        cat > "$WHITELIST_FILE" <<EOF
# VPS Guardian - Whitelist de IPs para SSH
# Formato: IP DESCRIÇÃO
# Exemplo: 203.0.113.50 Casa
# Exemplo: 198.51.100.25 Escritório

EOF
        chmod 600 "$WHITELIST_FILE"
        log_success "Arquivo de whitelist criado: $WHITELIST_FILE"
    fi
}

# Validar formato de IP
validate_ip() {
    local ip="$1"
    local ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    if ! [[ "$ip" =~ $ip_regex ]]; then
        return 1
    fi

    # Validar cada octeto
    IFS='.' read -r -a octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [ "$octet" -gt 255 ]; then
            return 1
        fi
    done

    return 0
}

# Listar IPs na whitelist
list_whitelist() {
    ensure_whitelist_file

    if ! grep -v '^#' "$WHITELIST_FILE" | grep -v '^[[:space:]]*$' > /dev/null; then
        log_warning "Nenhum IP configurado na whitelist"
        return 1
    fi

    echo ""
    log_section "IPs na Whitelist"
    echo ""

    local count=1
    while IFS=' ' read -r ip desc || [ -n "$ip" ]; do
        # Pular comentários e linhas vazias
        [[ "$ip" =~ ^#.*$ ]] && continue
        [[ -z "$ip" ]] && continue

        printf "  [%d] %-15s → %s\n" "$count" "$ip" "$desc"
        ((count++))
    done < "$WHITELIST_FILE"

    echo ""
    return 0
}

# Adicionar IP à whitelist
add_ip_whitelist() {
    ensure_whitelist_file

    log_section "Adicionar IP à Whitelist"
    echo ""

    local ip desc

    # Solicitar IP
    while true; do
        read -p "Digite o IP (formato: X.X.X.X): " ip

        if validate_ip "$ip"; then
            # Verificar se já existe
            if grep -q "^$ip " "$WHITELIST_FILE" 2>/dev/null; then
                log_error "IP $ip já está na whitelist"
                return 1
            fi
            break
        else
            log_error "IP inválido. Use formato: X.X.X.X (ex: 203.0.113.50)"
        fi
    done

    # Solicitar descrição
    read -p "Digite descrição (ex: Casa, Escritório): " desc
    desc="${desc:-Sem descrição}"

    # Adicionar ao arquivo
    echo "$ip $desc" >> "$WHITELIST_FILE"
    log_success "IP $ip adicionado à whitelist"

    return 0
}

# Remover IP da whitelist
remove_ip_whitelist() {
    if ! list_whitelist; then
        return 1
    fi

    read -p "Digite o número do IP para remover (ou 0 para cancelar): " choice

    if [ "$choice" -eq 0 ]; then
        log_info "Operação cancelada"
        return 0
    fi

    # Extrair linha específica
    local line=$(grep -v '^#' "$WHITELIST_FILE" | grep -v '^[[:space:]]*$' | sed -n "${choice}p")

    if [ -z "$line" ]; then
        log_error "Opção inválida"
        return 1
    fi

    local ip=$(echo "$line" | awk '{print $1}')

    # Remover do arquivo
    sed -i "/^$ip /d" "$WHITELIST_FILE"
    log_success "IP $ip removido da whitelist"

    return 0
}

# Detectar IP público atual
detect_current_ip() {
    local ip

    log_info "Detectando seu IP público..."

    # Tentar múltiplos serviços
    ip=$(curl -s https://api.ipify.org 2>/dev/null) || \
    ip=$(curl -s https://ifconfig.me 2>/dev/null) || \
    ip=$(curl -s https://icanhazip.com 2>/dev/null)

    if [ -n "$ip" ] && validate_ip "$ip"; then
        echo "$ip"
        return 0
    else
        log_error "Não foi possível detectar IP público"
        return 1
    fi
}

# Adicionar IP atual à whitelist
add_current_ip() {
    local current_ip desc

    current_ip=$(detect_current_ip)

    if [ $? -ne 0 ]; then
        return 1
    fi

    log_success "Seu IP público: $current_ip"
    echo ""

    read -p "Adicionar este IP à whitelist? (s/N): " response

    if [[ "$response" =~ ^[Ss]$ ]]; then
        read -p "Descrição (ex: Meu IP Atual): " desc
        desc="${desc:-IP Atual}"

        echo "$current_ip $desc" >> "$WHITELIST_FILE"
        log_success "IP $current_ip adicionado à whitelist"
    fi
}

# Configurar rede LAN
configure_lan() {
    log_section "Configurar Rede LAN"
    echo ""

    log_info "Digite os 3 primeiros octetos da sua rede LAN"
    echo "Exemplos: 192.168.1  ou  192.168.31  ou  10.0.0"
    echo ""
    echo "Como descobrir:"
    echo "  • Linux/Mac:  ip addr | grep inet"
    echo "  • Windows:    ipconfig"
    echo ""

    local network_input
    while true; do
        read -p "Rede LAN (ex: 192.168.31): " network_input

        if [[ "$network_input" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            # Validar octetos
            IFS='.' read -r -a octets <<< "$network_input"
            local valid=true

            for octet in "${octets[@]}"; do
                if [ "$octet" -gt 255 ]; then
                    valid=false
                    break
                fi
            done

            if [ "$valid" = "true" ]; then
                echo "${network_input}.0/24"
                return 0
            fi
        fi

        log_error "Formato inválido. Use: X.X.X (ex: 192.168.31)"
    done
}

# Verificar se Tailscale está instalado e interface existe
check_tailscale() {
    if ! command -v tailscale &> /dev/null; then
        return 1
    fi

    if ! ip link show tailscale0 &> /dev/null; then
        return 2
    fi

    return 0
}

# Verificar se regras Tailscale já existem
check_tailscale_rules() {
    if ufw status | grep -q "Anywhere on tailscale0"; then
        return 0
    fi
    return 1
}

# Adicionar regras Tailscale ao firewall
apply_tailscale_rules() {
    log_section "Configurando Tailscale no Firewall"
    echo ""

    # Verificar se Tailscale está instalado
    check_tailscale
    local status=$?

    if [ $status -eq 1 ]; then
        log_error "Tailscale não está instalado"
        echo ""
        log_info "Para instalar o Tailscale, visite: https://tailscale.com/download"
        return 1
    elif [ $status -eq 2 ]; then
        log_error "Interface tailscale0 não encontrada"
        echo ""
        log_info "Certifique-se de que o Tailscale está rodando: sudo tailscale up"
        return 1
    fi

    # Verificar se regras já existem
    if check_tailscale_rules; then
        log_warning "Regras do Tailscale já estão configuradas"
        echo ""
        read -p "Deseja reconfigurar? (s/N): " response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
            return 0
        fi

        log_info "Removendo regras antigas do Tailscale..."
        remove_tailscale_rules
    fi

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

    return 0
}

# Remover regras Tailscale do firewall
remove_tailscale_rules() {
    log_info "Removendo regras do Tailscale..."

    # Obter números das regras relacionadas ao Tailscale
    local rule_numbers=$(ufw status numbered | grep "tailscale0" | awk -F'[][]' '{print $2}' | sort -rn)

    if [ -z "$rule_numbers" ]; then
        log_warning "Nenhuma regra do Tailscale encontrada"
        return 0
    fi

    # Remover regras (de trás para frente para não alterar os números)
    while read -r num; do
        ufw --force delete "$num" > /dev/null 2>&1
    done <<< "$rule_numbers"

    log_success "Regras do Tailscale removidas"
    return 0
}

# Menu para gerenciar Tailscale
manage_tailscale() {
    while true; do
        clear
        log_section "Gerenciar Tailscale no Firewall"
        echo ""

        # Verificar status
        check_tailscale
        local status=$?

        if [ $status -eq 1 ]; then
            log_error "❌ Tailscale não instalado"
            echo ""
            log_info "Para instalar: https://tailscale.com/download"
            echo ""
            read -p "Pressione ENTER para voltar..."
            return 1
        elif [ $status -eq 2 ]; then
            log_warning "⚠️  Tailscale instalado mas interface não encontrada"
            echo ""
            log_info "Execute: sudo tailscale up"
        else
            log_success "✓ Tailscale instalado e rodando"
        fi

        echo ""

        # Verificar regras
        if check_tailscale_rules; then
            log_success "✓ Regras do Tailscale configuradas no UFW"
            echo ""
            echo "  [1] 🔄 Reconfigurar regras"
            echo "  [2] ❌ Remover regras"
        else
            log_warning "⚠️  Regras do Tailscale não configuradas"
            echo ""
            echo "  [1] ➕ Adicionar regras do Tailscale"
        fi

        echo "  [3] 📊 Ver regras atuais"
        echo "  [0] 🔙 Voltar"
        echo ""

        read -p "Selecione uma opção: " choice
        echo ""

        case $choice in
            1)
                apply_tailscale_rules
                pause
                ;;
            2)
                if check_tailscale_rules; then
                    remove_tailscale_rules
                    pause
                else
                    log_error "Opção inválida"
                    sleep 2
                fi
                ;;
            3)
                ufw status numbered | grep -E "(tailscale0|Status:)"
                echo ""
                pause
                ;;
            0)
                return 0
                ;;
            *)
                log_error "Opção inválida"
                sleep 2
                ;;
        esac
    done
}

################################################################################
# APLICAR CONFIGURAÇÕES DE FIREWALL
################################################################################

apply_firewall_secure() {
    log_section "Aplicando Modo SEGURO (Cloudflare Tunnel)"

    log_info "Resetando firewall..."
    ufw --force reset > /dev/null 2>&1

    log_info "Configurando política padrão..."
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1
    ufw default allow routed > /dev/null 2>&1

    log_info "Configurando loopback (Cloudflare Tunnel)..."
    ufw allow in on lo > /dev/null 2>&1
    ufw allow out on lo > /dev/null 2>&1

    log_info "Permitindo HTTP/HTTPS público..."
    ufw allow 80/tcp comment 'HTTP' > /dev/null 2>&1
    ufw allow 443/tcp comment 'HTTPS' > /dev/null 2>&1

    log_info "Permitindo SSH apenas localhost..."
    ufw allow from 127.0.0.1 to any port 22 comment 'SSH localhost' > /dev/null 2>&1

    # LAN
    local lan_network=$(configure_lan)
    log_info "Permitindo SSH da LAN ($lan_network)..."
    ufw allow from "$lan_network" to any port 22 comment 'SSH LAN' > /dev/null 2>&1

    log_info "Permitindo SSH das redes Docker..."
    ufw allow from 10.0.0.0/8 to any port 22 comment 'SSH Docker' > /dev/null 2>&1

    log_info "Ativando firewall..."
    ufw --force enable > /dev/null 2>&1

    echo ""
    log_success "Modo SEGURO aplicado!"
    echo ""

    # Verificar se Tailscale está disponível e perguntar se quer adicionar regras
    check_tailscale
    local ts_status=$?
    if [ $ts_status -eq 0 ]; then
        echo ""
        read -p "Deseja adicionar regras do Tailscale ao firewall? (s/N): " response
        if [[ "$response" =~ ^[Ss]$ ]]; then
            echo ""
            apply_tailscale_rules
        fi
    fi

    echo ""
    log_warning "⚠️  IMPORTANTE:"
    echo "  • Porta 22 NÃO está exposta publicamente"
    echo "  • Configure Cloudflare Tunnel para acesso remoto"
    echo "  • SSH disponível apenas: localhost + LAN + Docker"
    echo ""
}

apply_firewall_hybrid() {
    log_section "Aplicando Modo HÍBRIDO (Cloudflare + Whitelist)"

    if ! list_whitelist; then
        log_error "Configure IPs na whitelist primeiro (opção 5)"
        pause
        return 1
    fi

    log_info "Resetando firewall..."
    ufw --force reset > /dev/null 2>&1

    log_info "Configurando política padrão..."
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1
    ufw default allow routed > /dev/null 2>&1

    log_info "Configurando loopback..."
    ufw allow in on lo > /dev/null 2>&1
    ufw allow out on lo > /dev/null 2>&1

    log_info "Permitindo HTTP/HTTPS público..."
    ufw allow 80/tcp comment 'HTTP' > /dev/null 2>&1
    ufw allow 443/tcp comment 'HTTPS' > /dev/null 2>&1

    log_info "Permitindo SSH localhost..."
    ufw allow from 127.0.0.1 to any port 22 comment 'SSH localhost' > /dev/null 2>&1

    # LAN
    local lan_network=$(configure_lan)
    log_info "Permitindo SSH da LAN ($lan_network)..."
    ufw allow from "$lan_network" to any port 22 comment 'SSH LAN' > /dev/null 2>&1

    log_info "Permitindo SSH das redes Docker..."
    ufw allow from 10.0.0.0/8 to any port 22 comment 'SSH Docker' > /dev/null 2>&1

    log_info "Aplicando whitelist de IPs..."
    while IFS=' ' read -r ip desc || [ -n "$ip" ]; do
        [[ "$ip" =~ ^#.*$ ]] && continue
        [[ -z "$ip" ]] && continue

        ufw allow from "$ip" to any port 22 comment "SSH - $desc" > /dev/null 2>&1
        log_success "  ✓ $ip ($desc)"
    done < "$WHITELIST_FILE"

    log_info "Ativando firewall..."
    ufw --force enable > /dev/null 2>&1

    echo ""
    log_success "Modo HÍBRIDO aplicado!"
    echo ""

    # Verificar se Tailscale está disponível e perguntar se quer adicionar regras
    check_tailscale
    local ts_status=$?
    if [ $ts_status -eq 0 ]; then
        echo ""
        read -p "Deseja adicionar regras do Tailscale ao firewall? (s/N): " response
        if [[ "$response" =~ ^[Ss]$ ]]; then
            echo ""
            apply_tailscale_rules
        fi
    fi

    echo ""
    log_warning "⚠️  IMPORTANTE:"
    echo "  • SSH disponível de: localhost + LAN + Docker + Whitelist IPs"
    echo "  • Use Cloudflare Tunnel como método principal"
    echo "  • Whitelist IPs como fallback de emergência"
    echo ""
}

apply_firewall_basic() {
    log_section "Aplicando Modo BÁSICO (Apenas Whitelist)"

    if ! list_whitelist; then
        log_error "Configure IPs na whitelist primeiro (opção 5)"
        pause
        return 1
    fi

    log_warning "⚠️  ATENÇÃO: Modo menos seguro!"
    echo "  • Porta 22 ficará exposta publicamente"
    echo "  • Sujeito a port scanning e brute force"
    echo "  • Use apenas se não puder usar Cloudflare Tunnel"
    echo ""

    if ! confirm "Continuar com modo básico?"; then
        return 1
    fi

    log_info "Resetando firewall..."
    ufw --force reset > /dev/null 2>&1

    log_info "Configurando política padrão..."
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1
    ufw default allow routed > /dev/null 2>&1

    log_info "Configurando loopback..."
    ufw allow in on lo > /dev/null 2>&1
    ufw allow out on lo > /dev/null 2>&1

    log_info "Permitindo HTTP/HTTPS público..."
    ufw allow 80/tcp comment 'HTTP' > /dev/null 2>&1
    ufw allow 443/tcp comment 'HTTPS' > /dev/null 2>&1

    log_info "Permitindo SSH localhost..."
    ufw allow from 127.0.0.1 to any port 22 comment 'SSH localhost' > /dev/null 2>&1

    # LAN
    local lan_network=$(configure_lan)
    log_info "Permitindo SSH da LAN ($lan_network)..."
    ufw allow from "$lan_network" to any port 22 comment 'SSH LAN' > /dev/null 2>&1

    log_info "Permitindo SSH das redes Docker..."
    ufw allow from 10.0.0.0/8 to any port 22 comment 'SSH Docker' > /dev/null 2>&1

    log_info "Aplicando whitelist de IPs..."
    while IFS=' ' read -r ip desc || [ -n "$ip" ]; do
        [[ "$ip" =~ ^#.*$ ]] && continue
        [[ -z "$ip" ]] && continue

        ufw allow from "$ip" to any port 22 comment "SSH - $desc" > /dev/null 2>&1
        log_success "  ✓ $ip ($desc)"
    done < "$WHITELIST_FILE"

    log_info "Ativando firewall..."
    ufw --force enable > /dev/null 2>&1

    echo ""
    log_success "Modo BÁSICO aplicado!"
    echo ""

    # Verificar se Tailscale está disponível e perguntar se quer adicionar regras
    check_tailscale
    local ts_status=$?
    if [ $ts_status -eq 0 ]; then
        echo ""
        read -p "Deseja adicionar regras do Tailscale ao firewall? (s/N): " response
        if [[ "$response" =~ ^[Ss]$ ]]; then
            echo ""
            apply_tailscale_rules
        fi
    fi

    echo ""
    log_warning "⚠️  RECOMENDAÇÕES:"
    echo "  • Configure fail2ban para proteção contra brute force"
    echo "  • Use chaves SSH (desabilite senha)"
    echo "  • Monitore logs regularmente: tail -f /var/log/auth.log"
    echo "  • Considere migrar para Cloudflare Tunnel"
    echo ""
}

################################################################################
# MENU PRINCIPAL
################################################################################

show_menu() {
    clear
    cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║          VPS Guardian - Firewall Interativo                    ║
║                  Gerenciador UFW com Múltiplos Perfis          ║
╚════════════════════════════════════════════════════════════════╝

EOF

    log_section "Perfis de Firewall"
    echo ""
    echo "  [1] 🔒 SEGURO (Recomendado)"
    echo "      └─ Cloudflare Tunnel only (porta 22 fechada)"
    echo ""
    echo "  [2] 🔐 HÍBRIDO"
    echo "      └─ Cloudflare Tunnel + Whitelist IPs (fallback)"
    echo ""
    echo "  [3] 🔓 BÁSICO"
    echo "      └─ Apenas Whitelist IPs (menos seguro)"
    echo ""

    log_separator
    log_section "Gerenciar Whitelist de IPs"
    echo ""
    echo "  [4] 📋 Ver IPs na whitelist"
    echo "  [5] ➕ Adicionar IP manualmente"
    echo "  [6] ➕ Adicionar meu IP atual"
    echo "  [7] ➖ Remover IP da whitelist"
    echo ""

    log_separator
    log_section "Tailscale VPN"
    echo ""
    echo "  [8] 🔐 Gerenciar Tailscale no Firewall"
    echo ""

    log_separator
    log_section "Ferramentas"
    echo ""
    echo "  [9] 📊 Ver status do firewall"
    echo "  [10] 📜 Ver logs do firewall"
    echo "  [0] 🚪 Sair"
    echo ""

    log_separator
}

show_firewall_status() {
    log_section "Status do Firewall UFW"
    echo ""
    ufw status numbered
    echo ""
    pause
}

show_firewall_logs() {
    log_section "Logs do Firewall (últimas 30 linhas)"
    echo ""

    if [ -f /var/log/ufw.log ]; then
        tail -30 /var/log/ufw.log
    else
        log_warning "Arquivo de log não encontrado"
    fi

    echo ""
    pause
}

################################################################################
# MAIN LOOP
################################################################################

main() {
    # Verificar root
    check_root || exit 1

    # Criar arquivo de whitelist
    ensure_whitelist_file

    while true; do
        show_menu

        read -p "Selecione uma opção: " choice
        echo ""

        case $choice in
            1)
                apply_firewall_secure
                pause
                ;;
            2)
                apply_firewall_hybrid
                pause
                ;;
            3)
                apply_firewall_basic
                pause
                ;;
            4)
                list_whitelist
                pause
                ;;
            5)
                add_ip_whitelist
                pause
                ;;
            6)
                add_current_ip
                pause
                ;;
            7)
                remove_ip_whitelist
                pause
                ;;
            8)
                manage_tailscale
                ;;
            9)
                show_firewall_status
                ;;
            10)
                show_firewall_logs
                ;;
            0)
                log_info "Saindo..."
                exit 0
                ;;
            *)
                log_error "Opção inválida!"
                sleep 2
                ;;
        esac
    done
}

# Executar
main
