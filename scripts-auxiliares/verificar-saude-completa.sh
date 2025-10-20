#!/bin/bash
################################################################################
# Script de Verificação de Saúde Completa do Servidor
# Propósito: Verificar status de todos os componentes da infraestrutura
#            - Sistema operacional e recursos
#            - Docker e containers
#            - Cloudflare Tunnels e WARP
#            - Firewall (UFW)
#            - Serviços (Coolify, PostgreSQL, etc)
#            - Backups e manutenção
#            - Configurações de segurança
################################################################################

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Símbolos
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"
INFO="${BLUE}ℹ${NC}"

################################################################################
# FUNÇÕES AUXILIARES
################################################################################

print_header() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_section() {
    echo -e "\n${MAGENTA}▶ $1${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "  $CHECK $2 instalado"
        return 0
    else
        echo -e "  $CROSS $2 NÃO instalado"
        return 1
    fi
}

check_service() {
    if systemctl is-active --quiet "$1"; then
        echo -e "  $CHECK $2: ${GREEN}Ativo${NC}"
        return 0
    else
        if systemctl is-enabled --quiet "$1" 2>/dev/null; then
            echo -e "  $WARN $2: ${YELLOW}Parado (mas habilitado)${NC}"
            return 1
        else
            echo -e "  $CROSS $2: ${RED}Inativo${NC}"
            return 2
        fi
    fi
}

get_percentage_color() {
    local value=$1
    if [ "$value" -lt 70 ]; then
        echo -e "${GREEN}${value}%${NC}"
    elif [ "$value" -lt 85 ]; then
        echo -e "${YELLOW}${value}%${NC}"
    else
        echo -e "${RED}${value}%${NC}"
    fi
}

################################################################################
# CABEÇALHO
################################################################################

clear
echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     🏥 VERIFICAÇÃO DE SAÚDE COMPLETA DO SERVIDOR 🏥             ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${WHITE}📅 Data/Hora:${NC} $(date '+%d/%m/%Y %H:%M:%S')"
echo -e "${WHITE}🖥️  Hostname:${NC}  $(hostname)"
echo -e "${WHITE}👤 Usuário:${NC}   $(whoami)"
echo -e "${WHITE}📍 IP Local:${NC}  $(hostname -I | awk '{print $1}')"

################################################################################
# 1. INFORMAÇÕES DO SISTEMA
################################################################################

print_header "1️⃣  SISTEMA OPERACIONAL"

print_section "Informações Básicas"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "  ${WHITE}SO:${NC} $PRETTY_NAME"
    echo -e "  ${WHITE}Versão:${NC} $VERSION"
else
    echo -e "  $WARN Não foi possível detectar o SO"
fi

echo -e "  ${WHITE}Kernel:${NC} $(uname -r)"
echo -e "  ${WHITE}Arquitetura:${NC} $(uname -m)"
echo -e "  ${WHITE}Uptime:${NC} $(uptime -p | sed 's/up //')"

print_section "Última Reinicialização"
echo -e "  ${WHITE}Data:${NC} $(who -b | awk '{print $3, $4}')"

################################################################################
# 2. RECURSOS DO SISTEMA
################################################################################

print_header "2️⃣  RECURSOS DO SISTEMA"

print_section "CPU"
CPU_CORES=$(nproc)
CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\100/" | awk '{print 100 - $1}' | cut -d'.' -f1)
echo -e "  ${WHITE}Modelo:${NC} $CPU_MODEL"
echo -e "  ${WHITE}Cores:${NC} $CPU_CORES"
echo -e "  ${WHITE}Uso:${NC} $(get_percentage_color $CPU_USAGE)"

print_section "Memória RAM"
MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
MEM_USED=$(free -h | grep Mem | awk '{print $3}')
MEM_PERCENT=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100)}')
echo -e "  ${WHITE}Total:${NC} $MEM_TOTAL"
echo -e "  ${WHITE}Usado:${NC} $MEM_USED ($(get_percentage_color $MEM_PERCENT))"

print_section "Disco /"
DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
DISK_USED=$(df -h / | tail -1 | awk '{print $3}')
DISK_PERCENT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo -e "  ${WHITE}Total:${NC} $DISK_TOTAL"
echo -e "  ${WHITE}Usado:${NC} $DISK_USED ($(get_percentage_color $DISK_PERCENT))"

# Verificar outros pontos de montagem importantes
if mountpoint -q /var/lib/docker; then
    print_section "Disco Docker (/var/lib/docker)"
    DOCKER_DISK_TOTAL=$(df -h /var/lib/docker | tail -1 | awk '{print $2}')
    DOCKER_DISK_USED=$(df -h /var/lib/docker | tail -1 | awk '{print $3}')
    DOCKER_DISK_PERCENT=$(df /var/lib/docker | tail -1 | awk '{print $5}' | sed 's/%//')
    echo -e "  ${WHITE}Total:${NC} $DOCKER_DISK_TOTAL"
    echo -e "  ${WHITE}Usado:${NC} $DOCKER_DISK_USED ($(get_percentage_color $DOCKER_DISK_PERCENT))"
fi

print_section "Load Average"
LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)
echo -e "  ${WHITE}1min, 5min, 15min:${NC} $LOAD"

################################################################################
# 3. FERRAMENTAS INSTALADAS
################################################################################

print_header "3️⃣  FERRAMENTAS ESSENCIAIS"

print_section "Verificando Instalação"
check_command docker "Docker"
check_command docker-compose "Docker Compose"
check_command cloudflared "Cloudflared"
check_command warp-cli "WARP CLI"
check_command ufw "UFW (Firewall)"
check_command fail2ban-client "Fail2Ban"
check_command psql "PostgreSQL Client"
check_command git "Git"
check_command curl "cURL"
check_command wget "wget"
check_command jq "jq (JSON processor)"

################################################################################
# 4. SERVIÇOS DO SISTEMA
################################################################################

print_header "4️⃣  SERVIÇOS DO SISTEMA"

print_section "Serviços Críticos"
check_service ssh "SSH"
check_service docker "Docker"
check_service ufw "Firewall (UFW)"

print_section "Cloudflare"
if check_service cloudflared "Cloudflared Tunnel"; then
    # Verificar conectividade do túnel
    if journalctl -u cloudflared -n 20 --no-pager 2>/dev/null | grep -q "Registered tunnel connection"; then
        echo -e "  $CHECK Túnel conectado à Cloudflare"
    else
        echo -e "  $WARN Túnel pode não estar conectado (verificar logs)"
    fi
fi

print_section "WARP"
if command -v warp-cli &> /dev/null; then
    WARP_STATUS=$(warp-cli status 2>/dev/null | head -1 || echo "Unknown")
    if echo "$WARP_STATUS" | grep -q "Connected"; then
        echo -e "  $CHECK WARP: ${GREEN}Conectado${NC}"
    elif echo "$WARP_STATUS" | grep -q "Disconnected"; then
        echo -e "  $INFO WARP: ${YELLOW}Desconectado${NC}"
    else
        echo -e "  $WARN WARP: Status desconhecido"
    fi
fi

print_section "Outros Serviços"
check_service fail2ban "Fail2Ban" 2>/dev/null || echo -e "  $INFO Fail2Ban não instalado"
check_service unattended-upgrades "Unattended Upgrades" 2>/dev/null || echo -e "  $INFO Unattended Upgrades não configurado"
check_service cron "Cron"

################################################################################
# 5. DOCKER
################################################################################

print_header "5️⃣  DOCKER"

if command -v docker &> /dev/null; then
    print_section "Informações Docker"
    DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "N/A")
    echo -e "  ${WHITE}Versão:${NC} $DOCKER_VERSION"

    print_section "Containers"
    CONTAINERS_RUNNING=$(docker ps -q | wc -l)
    CONTAINERS_TOTAL=$(docker ps -aq | wc -l)
    echo -e "  ${WHITE}Rodando:${NC} ${GREEN}$CONTAINERS_RUNNING${NC} de $CONTAINERS_TOTAL"

    if [ $CONTAINERS_RUNNING -gt 0 ]; then
        echo ""
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | while IFS= read -r line; do
            echo -e "  ${BLUE}$line${NC}"
        done
    fi

    print_section "Uso de Recursos Docker"
    docker system df 2>/dev/null | tail -n +2 | while IFS= read -r line; do
        echo -e "  $line"
    done

    print_section "Redes Docker"
    DOCKER_NETWORKS=$(docker network ls --format '{{.Name}}' | wc -l)
    echo -e "  ${WHITE}Total de redes:${NC} $DOCKER_NETWORKS"

    print_section "Volumes Docker"
    DOCKER_VOLUMES=$(docker volume ls -q | wc -l)
    echo -e "  ${WHITE}Total de volumes:${NC} $DOCKER_VOLUMES"
else
    echo -e "  $CROSS Docker não está instalado"
fi

################################################################################
# 6. COOLIFY
################################################################################

print_header "6️⃣  COOLIFY"

if docker ps --format '{{.Names}}' | grep -q "coolify"; then
    print_section "Status"
    echo -e "  $CHECK Coolify está ${GREEN}rodando${NC}"

    COOLIFY_IMAGE=$(docker ps --filter "name=coolify" --format '{{.Image}}' | grep coollabsio/coolify | head -n1)
    if [ -n "$COOLIFY_IMAGE" ]; then
        echo -e "  ${WHITE}Imagem:${NC} $COOLIFY_IMAGE"
    fi

    # Listar containers Coolify
    print_section "Containers Coolify"
    docker ps --filter "name=coolify" --format "  • {{.Names}} - {{.Status}}"

    # Verificar acesso à porta 8000
    if netstat -tlnp 2>/dev/null | grep -q ":8000"; then
        echo -e "\n  $CHECK Porta 8000 (UI) está escutando"
    else
        echo -e "\n  $WARN Porta 8000 (UI) não detectada"
    fi
else
    echo -e "  $CROSS Coolify ${RED}NÃO${NC} está rodando"

    # Verificar se já foi instalado
    if docker ps -a --format '{{.Names}}' | grep -q "coolify"; then
        echo -e "  $INFO Coolify está instalado mas parado"
        echo -e "  ${YELLOW}Execute:${NC} docker start \$(docker ps -a --filter 'name=coolify' --format '{{.Names}}')"
    else
        echo -e "  $INFO Coolify não parece estar instalado"
    fi
fi

################################################################################
# 7. FIREWALL (UFW)
################################################################################

print_header "7️⃣  FIREWALL (UFW)"

if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null | head -1)

    if echo "$UFW_STATUS" | grep -q "Status: active"; then
        echo -e "  $CHECK UFW está ${GREEN}ATIVO${NC}"

        print_section "Política Padrão"
        sudo ufw status verbose 2>/dev/null | grep -i "default:" | sed 's/^/  /'

        print_section "Regras Principais"
        sudo ufw status numbered 2>/dev/null | grep -E "(80|443|22|100\.64)" | head -10 | sed 's/^/  /'

        # Verificar regras Docker
        print_section "Proteção Docker (DOCKER-USER)"
        if sudo iptables -L DOCKER-USER -n 2>/dev/null | grep -q "100.64.0.0/10"; then
            echo -e "  $CHECK Regras DOCKER-USER configuradas (permite WARP)"
        else
            echo -e "  $WARN Regras DOCKER-USER podem não estar configuradas"
            echo -e "  ${YELLOW}Verifique:${NC} /etc/ufw/before.rules"
        fi

    elif echo "$UFW_STATUS" | grep -q "Status: inactive"; then
        echo -e "  $CROSS UFW está ${RED}INATIVO${NC}"
        echo -e "  ${YELLOW}Ative com:${NC} sudo ufw enable"
    fi
else
    echo -e "  $CROSS UFW não está instalado"
fi

################################################################################
# 8. PORTAS ABERTAS
################################################################################

print_header "8️⃣  PORTAS EM ESCUTA"

print_section "Portas TCP"
sudo netstat -tlnp 2>/dev/null | grep LISTEN | awk '{print $4, $7}' | sort -u | while read -r line; do
    PORT=$(echo "$line" | awk '{print $1}' | rev | cut -d: -f1 | rev)
    PROCESS=$(echo "$line" | awk '{print $2}')

    # Colorir portas conhecidas
    case $PORT in
        22)   echo -e "  ${GREEN}SSH (22)${NC}        - $PROCESS" ;;
        80)   echo -e "  ${GREEN}HTTP (80)${NC}       - $PROCESS" ;;
        443)  echo -e "  ${GREEN}HTTPS (443)${NC}     - $PROCESS" ;;
        5432) echo -e "  ${YELLOW}PostgreSQL (5432)${NC} - $PROCESS" ;;
        8000) echo -e "  ${YELLOW}Coolify (8000)${NC}  - $PROCESS" ;;
        19999) echo -e "  ${YELLOW}Netdata (19999)${NC} - $PROCESS" ;;
        *)    echo -e "  ${WHITE}Porta $PORT${NC} - $PROCESS" ;;
    esac
done | head -15

################################################################################
# 9. CLOUDFLARE TUNNELS
################################################################################

print_header "9️⃣  CLOUDFLARE TUNNELS"

if systemctl is-active --quiet cloudflared; then
    print_section "Status do Serviço"
    echo -e "  $CHECK Cloudflared está rodando"

    # Verificar arquivo de configuração
    if [ -f /etc/cloudflared/config.yml ]; then
        echo -e "  $CHECK Arquivo de configuração encontrado"

        print_section "Configuração"
        grep -E "^tunnel:|^credentials-file:" /etc/cloudflared/config.yml 2>/dev/null | sed 's/^/  /'

        # Verificar ingress rules
        INGRESS_COUNT=$(grep -c "hostname:" /etc/cloudflared/config.yml 2>/dev/null || echo "0")
        echo -e "  ${WHITE}Hostnames públicos:${NC} $INGRESS_COUNT"
    fi

    # Verificar logs recentes
    print_section "Status da Conexão (últimos logs)"
    if journalctl -u cloudflared -n 5 --no-pager 2>/dev/null | grep -q "error"; then
        echo -e "  $WARN Erros detectados nos logs recentes"
        journalctl -u cloudflared -n 3 --no-pager 2>/dev/null | grep "error" | sed 's/^/  /' | head -3
    else
        echo -e "  $CHECK Sem erros recentes"
        journalctl -u cloudflared -n 2 --no-pager 2>/dev/null | tail -2 | sed 's/^/  /'
    fi
else
    echo -e "  $CROSS Cloudflared não está rodando"
fi

################################################################################
# 10. BANCOS DE DADOS
################################################################################

print_header "🔟 BANCOS DE DADOS"

print_section "PostgreSQL"
POSTGRES_CONTAINERS=$(docker ps --filter "ancestor=postgres" --format '{{.Names}}' | wc -l)
if [ "$POSTGRES_CONTAINERS" -gt 0 ]; then
    echo -e "  $CHECK $POSTGRES_CONTAINERS container(s) PostgreSQL rodando"
    docker ps --filter "ancestor=postgres" --format "  • {{.Names}} - Porta: {{.Ports}}" | sed 's/0.0.0.0://'
else
    # Verificar se tem PostgreSQL nativo
    if command -v psql &> /dev/null && systemctl is-active --quiet postgresql 2>/dev/null; then
        echo -e "  $CHECK PostgreSQL nativo está rodando"
    else
        echo -e "  $INFO Nenhum PostgreSQL detectado"
    fi
fi

print_section "MySQL/MariaDB"
MYSQL_CONTAINERS=$(docker ps --filter "ancestor=mysql" --format '{{.Names}}' | wc -l)
MARIADB_CONTAINERS=$(docker ps --filter "ancestor=mariadb" --format '{{.Names}}' | wc -l)
TOTAL_MYSQL=$((MYSQL_CONTAINERS + MARIADB_CONTAINERS))
if [ "$TOTAL_MYSQL" -gt 0 ]; then
    echo -e "  $CHECK $TOTAL_MYSQL container(s) MySQL/MariaDB rodando"
else
    echo -e "  $INFO Nenhum MySQL/MariaDB detectado"
fi

print_section "MongoDB"
MONGO_CONTAINERS=$(docker ps --filter "ancestor=mongo" --format '{{.Names}}' | wc -l)
if [ "$MONGO_CONTAINERS" -gt 0 ]; then
    echo -e "  $CHECK $MONGO_CONTAINERS container(s) MongoDB rodando"
else
    echo -e "  $INFO Nenhum MongoDB detectado"
fi

print_section "Redis"
REDIS_CONTAINERS=$(docker ps --filter "ancestor=redis" --format '{{.Names}}' | wc -l)
if [ "$REDIS_CONTAINERS" -gt 0 ]; then
    echo -e "  $CHECK $REDIS_CONTAINERS container(s) Redis rodando"
else
    echo -e "  $INFO Nenhum Redis detectado"
fi

################################################################################
# 11. BACKUPS
################################################################################

print_header "1️⃣1️⃣ BACKUPS"

print_section "Diretório de Backups"
if [ -d /root/coolify-backups ]; then
    BACKUP_COUNT=$(ls -1 /root/coolify-backups/*.tar.gz 2>/dev/null | wc -l)
    echo -e "  $CHECK Diretório existe"
    echo -e "  ${WHITE}Total de backups:${NC} $BACKUP_COUNT"

    if [ "$BACKUP_COUNT" -gt 0 ]; then
        ULTIMO_BACKUP=$(ls -t /root/coolify-backups/*.tar.gz 2>/dev/null | head -1)
        BACKUP_SIZE=$(du -h "$ULTIMO_BACKUP" | cut -f1)
        BACKUP_DATE=$(stat -c %y "$ULTIMO_BACKUP" 2>/dev/null | cut -d'.' -f1)

        echo -e "  ${WHITE}Último backup:${NC}"
        echo -e "    • Arquivo: $(basename "$ULTIMO_BACKUP")"
        echo -e "    • Tamanho: $BACKUP_SIZE"
        echo -e "    • Data: $BACKUP_DATE"

        # Calcular idade do último backup
        BACKUP_AGE=$(($(date +%s) - $(stat -c %Y "$ULTIMO_BACKUP")))
        BACKUP_AGE_DAYS=$((BACKUP_AGE / 86400))

        if [ "$BACKUP_AGE_DAYS" -eq 0 ]; then
            echo -e "    • Idade: ${GREEN}Hoje${NC}"
        elif [ "$BACKUP_AGE_DAYS" -eq 1 ]; then
            echo -e "    • Idade: ${GREEN}1 dia${NC}"
        elif [ "$BACKUP_AGE_DAYS" -le 7 ]; then
            echo -e "    • Idade: ${YELLOW}$BACKUP_AGE_DAYS dias${NC}"
        else
            echo -e "    • Idade: ${RED}$BACKUP_AGE_DAYS dias${NC} (backup antigo!)"
        fi
    else
        echo -e "  $WARN Nenhum backup encontrado"
    fi
else
    echo -e "  $CROSS Diretório de backups não existe"
fi

print_section "Scripts de Backup"
if [ -f /root/manutencao_backup_vps/backup/backup-coolify.sh ]; then
    echo -e "  $CHECK Script backup-coolify.sh encontrado"
else
    echo -e "  $WARN Script backup-coolify.sh não encontrado"
fi

if [ -f /root/manutencao_backup_vps/backup/backup-databases.sh ]; then
    echo -e "  $CHECK Script backup-databases.sh encontrado"
else
    echo -e "  $INFO Script backup-databases.sh não encontrado"
fi

################################################################################
# 12. CRON JOBS
################################################################################

print_header "1️⃣2️⃣ CRON JOBS (Tarefas Agendadas)"

print_section "Cron do Root"
CRON_COUNT=$(crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | wc -l)
if [ "$CRON_COUNT" -gt 0 ]; then
    echo -e "  $CHECK $CRON_COUNT tarefa(s) agendada(s)"
    echo ""
    crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | while IFS= read -r line; do
        echo -e "  ${BLUE}$line${NC}"
    done
else
    echo -e "  $INFO Nenhuma tarefa agendada"
fi

################################################################################
# 13. SEGURANÇA
################################################################################

print_header "1️⃣3️⃣ SEGURANÇA"

print_section "SSH"
if [ -f /etc/ssh/sshd_config ]; then
    # Verificar PermitRootLogin
    ROOT_LOGIN=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')
    if [ "$ROOT_LOGIN" = "no" ] || [ "$ROOT_LOGIN" = "prohibit-password" ]; then
        echo -e "  $CHECK Root login: ${GREEN}$ROOT_LOGIN${NC}"
    else
        echo -e "  $WARN Root login: ${YELLOW}$ROOT_LOGIN${NC} (considere 'prohibit-password')"
    fi

    # Verificar PasswordAuthentication
    PASS_AUTH=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')
    if [ "$PASS_AUTH" = "no" ]; then
        echo -e "  $CHECK Autenticação por senha: ${GREEN}Desabilitada${NC}"
    else
        echo -e "  $WARN Autenticação por senha: ${YELLOW}Habilitada${NC}"
    fi
fi

print_section "Fail2Ban"
if systemctl is-active --quiet fail2ban 2>/dev/null; then
    echo -e "  $CHECK Fail2Ban está ativo"
    BANNED_IPS=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $4}')
    echo -e "  ${WHITE}IPs banidos (SSH):${NC} ${BANNED_IPS:-0}"
else
    echo -e "  $WARN Fail2Ban não está ativo"
fi

print_section "Updates de Segurança"
SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
if [ "$SECURITY_UPDATES" -eq 0 ]; then
    echo -e "  $CHECK Sem updates de segurança pendentes"
else
    echo -e "  $WARN ${YELLOW}$SECURITY_UPDATES${NC} update(s) de segurança disponível(is)"
fi

print_section "Login Recentes"
echo -e "  ${WHITE}Últimos logins:${NC}"
last -n 5 -w | head -5 | sed 's/^/    /'

################################################################################
# 14. REDE
################################################################################

print_header "1️⃣4️⃣ REDE"

print_section "Interfaces de Rede"
ip -br addr show | while IFS= read -r line; do
    echo -e "  $line"
done

print_section "Conectividade"
if ping -c 1 1.1.1.1 &> /dev/null; then
    echo -e "  $CHECK Internet (IPv4): ${GREEN}OK${NC}"
else
    echo -e "  $CROSS Internet (IPv4): ${RED}FALHA${NC}"
fi

if ping -c 1 2606:4700:4700::1111 &> /dev/null; then
    echo -e "  $CHECK Internet (IPv6): ${GREEN}OK${NC}"
else
    echo -e "  $INFO Internet (IPv6): Não disponível"
fi

print_section "DNS"
if host cloudflare.com &> /dev/null; then
    echo -e "  $CHECK Resolução DNS: ${GREEN}OK${NC}"
else
    echo -e "  $CROSS Resolução DNS: ${RED}FALHA${NC}"
fi

################################################################################
# 15. ATUALIZAÇÕES
################################################################################

print_header "1️⃣5️⃣ ATUALIZAÇÕES DO SISTEMA"

print_section "Pacotes Atualizáveis"
TOTAL_UPDATES=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")
if [ "$TOTAL_UPDATES" -eq 0 ]; then
    echo -e "  $CHECK Sistema atualizado"
else
    echo -e "  $INFO $TOTAL_UPDATES pacote(s) disponível(is) para atualização"
fi

print_section "Último apt update"
if [ -f /var/lib/apt/periodic/update-success-stamp ]; then
    LAST_UPDATE=$(stat -c %y /var/lib/apt/periodic/update-success-stamp 2>/dev/null | cut -d'.' -f1)
    echo -e "  ${WHITE}Data:${NC} $LAST_UPDATE"
else
    echo -e "  $INFO Data desconhecida"
fi

################################################################################
# 16. LOGS RECENTES
################################################################################

print_header "1️⃣6️⃣ LOGS IMPORTANTES"

print_section "Erros Críticos no Sistema (últimas 24h)"
ERROR_COUNT=$(journalctl --since "24 hours ago" -p err --no-pager 2>/dev/null | wc -l)
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "  $CHECK Nenhum erro crítico"
else
    echo -e "  $WARN $ERROR_COUNT erro(s) encontrado(s)"
    echo -e "  ${YELLOW}Visualize com:${NC} journalctl --since '24 hours ago' -p err"
fi

print_section "Logs de Autenticação SSH (últimas 10 tentativas)"
if [ -f /var/log/auth.log ]; then
    grep "sshd" /var/log/auth.log 2>/dev/null | tail -5 | sed 's/^/  /' || echo -e "  $INFO Nenhum log recente"
else
    echo -e "  $INFO Arquivo de log não encontrado"
fi

################################################################################
# 17. RESUMO FINAL
################################################################################

print_header "📊 RESUMO GERAL"

# Calcular score de saúde
HEALTH_SCORE=100
ISSUES_FOUND=0

# Docker não rodando (-20)
if ! systemctl is-active --quiet docker; then
    HEALTH_SCORE=$((HEALTH_SCORE - 20))
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# UFW inativo (-15)
if ! sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    HEALTH_SCORE=$((HEALTH_SCORE - 15))
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Disco >85% (-10)
if [ "$DISK_PERCENT" -gt 85 ]; then
    HEALTH_SCORE=$((HEALTH_SCORE - 10))
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Memória >90% (-10)
if [ "$MEM_PERCENT" -gt 90 ]; then
    HEALTH_SCORE=$((HEALTH_SCORE - 10))
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Cloudflared não rodando (-15)
if ! systemctl is-active --quiet cloudflared; then
    HEALTH_SCORE=$((HEALTH_SCORE - 15))
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Backup muito antigo (-10)
if [ -n "$BACKUP_AGE_DAYS" ] && [ "$BACKUP_AGE_DAYS" -gt 7 ]; then
    HEALTH_SCORE=$((HEALTH_SCORE - 10))
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Security updates pendentes (-5)
if [ "$SECURITY_UPDATES" -gt 0 ]; then
    HEALTH_SCORE=$((HEALTH_SCORE - 5))
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

echo ""
if [ "$HEALTH_SCORE" -ge 90 ]; then
    echo -e "  ${GREEN}🏆 SAÚDE DO SERVIDOR: EXCELENTE${NC}"
    echo -e "  ${GREEN}Score: $HEALTH_SCORE/100${NC}"
elif [ "$HEALTH_SCORE" -ge 70 ]; then
    echo -e "  ${YELLOW}⚠️  SAÚDE DO SERVIDOR: BOA${NC}"
    echo -e "  ${YELLOW}Score: $HEALTH_SCORE/100${NC}"
elif [ "$HEALTH_SCORE" -ge 50 ]; then
    echo -e "  ${RED}⚠️  SAÚDE DO SERVIDOR: REGULAR${NC}"
    echo -e "  ${RED}Score: $HEALTH_SCORE/100${NC}"
else
    echo -e "  ${RED}🔥 SAÚDE DO SERVIDOR: CRÍTICA${NC}"
    echo -e "  ${RED}Score: $HEALTH_SCORE/100${NC}"
fi

echo -e "  ${WHITE}Problemas encontrados:${NC} $ISSUES_FOUND"

if [ "$ISSUES_FOUND" -gt 0 ]; then
    echo ""
    echo -e "  ${YELLOW}Recomendações:${NC}"

    if ! systemctl is-active --quiet docker; then
        echo -e "    • Iniciar Docker: ${CYAN}sudo systemctl start docker${NC}"
    fi

    if ! sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        echo -e "    • Ativar firewall: ${CYAN}sudo ufw enable${NC}"
    fi

    if [ "$DISK_PERCENT" -gt 85 ]; then
        echo -e "    • Limpar disco: ${CYAN}docker system prune -a${NC}"
    fi

    if [ "$MEM_PERCENT" -gt 90 ]; then
        echo -e "    • Reiniciar containers pesados ou aumentar RAM"
    fi

    if ! systemctl is-active --quiet cloudflared; then
        echo -e "    • Iniciar Cloudflared: ${CYAN}sudo systemctl start cloudflared${NC}"
    fi

    if [ -n "$BACKUP_AGE_DAYS" ] && [ "$BACKUP_AGE_DAYS" -gt 7 ]; then
        echo -e "    • Executar backup: ${CYAN}~/manutencao_backup_vps/backup/backup-coolify.sh${NC}"
    fi

    if [ "$SECURITY_UPDATES" -gt 0 ]; then
        echo -e "    • Atualizar sistema: ${CYAN}sudo apt update && sudo apt upgrade${NC}"
    fi
fi

################################################################################
# RODAPÉ
################################################################################

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}Verificação concluída em: $(date '+%H:%M:%S')${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
