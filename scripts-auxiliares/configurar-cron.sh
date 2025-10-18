#!/bin/bash
################################################################################
# Script de Configuração Automática de Cron
# Propósito: Configurar automaticamente todas as tarefas agendadas
# Uso: sudo ./configurar-cron.sh
################################################################################

set -e

LOG_PREFIX="[ Cron Config ]"

log() {
    echo "$LOG_PREFIX [ $1 ] $2"
}

log_error() {
    echo "$LOG_PREFIX [ ERRO ] $1"
}

log_success() {
    echo "$LOG_PREFIX [ OK ] $1"
}

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    log_error "Este script deve ser executado como root (use sudo)"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         CONFIGURAÇÃO AUTOMÁTICA DE TAREFAS AGENDADAS       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log "INFO" "Este script irá configurar cron jobs para:"
echo "  • Backup semanal do Coolify"
echo "  • Manutenção preventiva semanal"
echo "  • Alerta de espaço em disco diário"
echo "  • Rotação de logs mensal"
echo ""

# Verificar se scripts existem
log "INFO" "Verificando scripts necessários..."
ERRORS=0

if [ ! -x "/opt/manutencao/backup-coolify.sh" ]; then
    log_error "Script de backup não encontrado: /opt/manutencao/backup-coolify.sh"
    ((ERRORS++))
fi

if [ ! -x "/opt/manutencao/manutencao-completa.sh" ]; then
    log_error "Script de manutenção não encontrado: /opt/manutencao/manutencao-completa.sh"
    ((ERRORS++))
fi

if [ ! -x "/opt/manutencao/alerta-disco.sh" ]; then
    log_error "Script de alerta não encontrado: /opt/manutencao/alerta-disco.sh"
    ((ERRORS++))
fi

if [ $ERRORS -gt 0 ]; then
    log_error "Execute primeiro: sudo ./instalar.sh"
    exit 1
fi

log_success "Todos os scripts encontrados"
echo ""

# Perguntar configurações
log "INFO" "========== CONFIGURAÇÃO PERSONALIZADA =========="
echo ""

# Backup de Bancos de Dados
echo "1️⃣  BACKUP DE BANCOS DE DADOS (PostgreSQL + MySQL)"
echo ""
read -p "$LOG_PREFIX [ INPUT ] Habilitar backup automático de bancos? (Y/n): " ENABLE_DB_BACKUP
ENABLE_DB_BACKUP=${ENABLE_DB_BACKUP:-y}

if [ "$ENABLE_DB_BACKUP" = "y" ]; then
    read -p "$LOG_PREFIX [ INPUT ] Frequência (daily/weekly, padrão: daily): " DB_BACKUP_FREQ
    DB_BACKUP_FREQ=${DB_BACKUP_FREQ:-daily}

    if [ "$DB_BACKUP_FREQ" = "weekly" ]; then
        read -p "$LOG_PREFIX [ INPUT ] Dia da semana (0-6, 0=Domingo, padrão: 0): " DB_BACKUP_DAY
        DB_BACKUP_DAY=${DB_BACKUP_DAY:-0}
    fi

    read -p "$LOG_PREFIX [ INPUT ] Horário (HH:MM formato 24h, padrão: 01:00): " DB_BACKUP_TIME
    DB_BACKUP_TIME=${DB_BACKUP_TIME:-01:00}

    DB_BACKUP_HOUR=$(echo $DB_BACKUP_TIME | cut -d':' -f1)
    DB_BACKUP_MIN=$(echo $DB_BACKUP_TIME | cut -d':' -f2)
fi

echo ""

# Backup do Coolify
echo "2️⃣  BACKUP DO COOLIFY"
echo ""
read -p "$LOG_PREFIX [ INPUT ] Dia da semana para backup (0-6, 0=Domingo): " BACKUP_DAY
BACKUP_DAY=${BACKUP_DAY:-0}

read -p "$LOG_PREFIX [ INPUT ] Horário do backup (HH:MM formato 24h, padrão: 02:00): " BACKUP_TIME
BACKUP_TIME=${BACKUP_TIME:-02:00}

# Extrair hora e minuto
BACKUP_HOUR=$(echo $BACKUP_TIME | cut -d':' -f1)
BACKUP_MIN=$(echo $BACKUP_TIME | cut -d':' -f2)

echo ""

# Manutenção preventiva
echo "3️⃣  MANUTENÇÃO PREVENTIVA"
echo ""
read -p "$LOG_PREFIX [ INPUT ] Dia da semana para manutenção (0-6, 1=Segunda): " MANUTENCAO_DAY
MANUTENCAO_DAY=${MANUTENCAO_DAY:-1}

read -p "$LOG_PREFIX [ INPUT ] Horário da manutenção (HH:MM formato 24h, padrão: 03:00): " MANUTENCAO_TIME
MANUTENCAO_TIME=${MANUTENCAO_TIME:-03:00}

MANUTENCAO_HOUR=$(echo $MANUTENCAO_TIME | cut -d':' -f1)
MANUTENCAO_MIN=$(echo $MANUTENCAO_TIME | cut -d':' -f2)

echo ""

# Alerta de disco
echo "4️⃣  ALERTA DE ESPAÇO EM DISCO"
echo ""
read -p "$LOG_PREFIX [ INPUT ] Horário do alerta diário (HH:MM formato 24h, padrão: 09:00): " ALERTA_TIME
ALERTA_TIME=${ALERTA_TIME:-09:00}

ALERTA_HOUR=$(echo $ALERTA_TIME | cut -d':' -f1)
ALERTA_MIN=$(echo $ALERTA_TIME | cut -d':' -f2)

echo ""

# Upload automático de backups
echo "5️⃣  UPLOAD AUTOMÁTICO DE BACKUPS (OPCIONAL)"
echo ""
read -p "$LOG_PREFIX [ INPUT ] Enviar backups para destino remoto automaticamente? (y/N): " AUTO_UPLOAD
AUTO_UPLOAD=${AUTO_UPLOAD:-n}

UPLOAD_DEST=""
if [ "$AUTO_UPLOAD" = "y" ]; then
    echo ""
    echo "Destinos disponíveis:"
    echo "  [1] Self-hosted (SSH)"
    echo "  [2] Google Drive (rclone)"
    echo "  [3] AWS S3"
    echo "  [4] Todos os destinos"
    echo ""
    read -p "$LOG_PREFIX [ INPUT ] Escolha o destino (1-4): " UPLOAD_CHOICE

    case $UPLOAD_CHOICE in
        1) UPLOAD_DEST="self-hosted" ;;
        2) UPLOAD_DEST="google-drive" ;;
        3) UPLOAD_DEST="aws-s3" ;;
        4) UPLOAD_DEST="all" ;;
        *)
            log "WARN" "Opção inválida. Upload automático desabilitado."
            AUTO_UPLOAD="n"
            ;;
    esac

    if [ "$AUTO_UPLOAD" = "y" ]; then
        echo ""
        read -p "$LOG_PREFIX [ INPUT ] Quantas horas após o backup fazer upload? (padrão: 1): " UPLOAD_DELAY
        UPLOAD_DELAY=${UPLOAD_DELAY:-1}
    fi
fi

echo ""

# Resumo das configurações
log "INFO" "========== RESUMO DAS CONFIGURAÇÕES =========="
echo ""

if [ "$ENABLE_DB_BACKUP" = "y" ]; then
    echo "🗄️  Backup de Bancos de Dados:"
    if [ "$DB_BACKUP_FREQ" = "daily" ]; then
        echo "   • Frequência: Diário"
    else
        echo "   • Frequência: Semanal ($(case $DB_BACKUP_DAY in 0) echo 'Domingo';; 1) echo 'Segunda';; 2) echo 'Terça';; 3) echo 'Quarta';; 4) echo 'Quinta';; 5) echo 'Sexta';; 6) echo 'Sábado';; esac))"
    fi
    echo "   • Horário: $DB_BACKUP_TIME"
    echo ""
fi

echo "📅 Backup do Coolify:"
echo "   • Dia: $(case $BACKUP_DAY in 0) echo 'Domingo';; 1) echo 'Segunda';; 2) echo 'Terça';; 3) echo 'Quarta';; 4) echo 'Quinta';; 5) echo 'Sexta';; 6) echo 'Sábado';; esac)"
echo "   • Horário: $BACKUP_TIME"
echo ""
echo "🔧 Manutenção Preventiva:"
echo "   • Dia: $(case $MANUTENCAO_DAY in 0) echo 'Domingo';; 1) echo 'Segunda';; 2) echo 'Terça';; 3) echo 'Quarta';; 4) echo 'Quinta';; 5) echo 'Sexta';; 6) echo 'Sábado';; esac)"
echo "   • Horário: $MANUTENCAO_TIME"
echo ""
echo "💾 Alerta de Disco:"
echo "   • Frequência: Diário"
echo "   • Horário: $ALERTA_TIME"
echo ""
echo "📦 Rotação de Logs:"
echo "   • Frequência: Mensalmente (dia 1 às 04:00)"
echo ""

if [ "$AUTO_UPLOAD" = "y" ]; then
    echo "☁️  Upload Automático:"
    echo "   • Destino: $UPLOAD_DEST"
    echo "   • Delay: $UPLOAD_DELAY hora(s) após o backup"
    echo ""
fi

read -p "$LOG_PREFIX [ INPUT ] Confirmar configuração? (Y/n): " CONFIRM
CONFIRM=${CONFIRM:-y}

if [ "$CONFIRM" != "y" ]; then
    log "INFO" "Configuração cancelada"
    exit 0
fi

echo ""

# Backup do crontab atual
log "INFO" "========== BACKUP DO CRONTAB ATUAL =========="
echo ""

CRONTAB_BACKUP="/root/crontab.backup.$(date +%Y%m%d_%H%M%S)"
crontab -l > "$CRONTAB_BACKUP" 2>/dev/null || touch "$CRONTAB_BACKUP"

log_success "Backup criado: $CRONTAB_BACKUP"
echo ""

# Criar arquivo temporário com novos cron jobs
log "INFO" "========== CONFIGURANDO CRON JOBS =========="
echo ""

TEMP_CRON=$(mktemp)

# Adicionar crontab existente (removendo entradas antigas do sistema)
crontab -l 2>/dev/null | grep -v "/opt/manutencao/backup-coolify.sh" | \
    grep -v "/opt/manutencao/backup-databases.sh" | \
    grep -v "/opt/manutencao/manutencao-completa.sh" | \
    grep -v "/opt/manutencao/alerta-disco.sh" | \
    grep -v "/opt/manutencao/backup-destinos.sh" | \
    grep -v "logrotate" > "$TEMP_CRON" || true

# Adicionar cabeçalho
cat >> "$TEMP_CRON" << 'EOF'

################################################################################
# Sistema de Manutenção e Backup VPS - Configurado automaticamente
# Gerado em: $(date +"%Y-%m-%d %H:%M:%S")
################################################################################

# Configurações de ambiente
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=""

EOF

# Adicionar backup de bancos de dados se habilitado
if [ "$ENABLE_DB_BACKUP" = "y" ]; then
    if [ "$DB_BACKUP_FREQ" = "daily" ]; then
        cat >> "$TEMP_CRON" << EOF
# Backup automático de bancos de dados (diário às $DB_BACKUP_TIME)
$DB_BACKUP_MIN $DB_BACKUP_HOUR * * * /opt/manutencao/backup-databases.sh >> /var/log/manutencao/cron-db-backup.log 2>&1

EOF
    else
        cat >> "$TEMP_CRON" << EOF
# Backup automático de bancos de dados (semanal ${DB_BACKUP_DAY}=Dia da semana, $DB_BACKUP_TIME)
$DB_BACKUP_MIN $DB_BACKUP_HOUR * * $DB_BACKUP_DAY /opt/manutencao/backup-databases.sh >> /var/log/manutencao/cron-db-backup.log 2>&1

EOF
    fi
fi

# Adicionar backup do Coolify
cat >> "$TEMP_CRON" << EOF
# Backup completo do Coolify (${BACKUP_DAY}=Dia da semana, $BACKUP_TIME)
$BACKUP_MIN $BACKUP_HOUR * * $BACKUP_DAY /opt/manutencao/backup-coolify.sh >> /var/log/manutencao/cron-backup.log 2>&1

EOF

# Adicionar upload automático se configurado
if [ "$AUTO_UPLOAD" = "y" ]; then
    # Calcular horário do upload (backup_time + delay)
    UPLOAD_HOUR=$((BACKUP_HOUR + UPLOAD_DELAY))

    # Ajustar se passar de 24h
    if [ $UPLOAD_HOUR -ge 24 ]; then
        UPLOAD_HOUR=$((UPLOAD_HOUR - 24))
        UPLOAD_DAY=$((BACKUP_DAY + 1))
        if [ $UPLOAD_DAY -gt 6 ]; then
            UPLOAD_DAY=0
        fi
    else
        UPLOAD_DAY=$BACKUP_DAY
    fi

    cat >> "$TEMP_CRON" << EOF
# Upload automático de backups para $UPLOAD_DEST ($UPLOAD_DELAY hora(s) após o backup)
$BACKUP_MIN $UPLOAD_HOUR * * $UPLOAD_DAY find /root/coolify-backups -name "coolify-backup-*.tar.gz" -mmin -120 -exec /opt/manutencao/backup-destinos.sh {} --dest=$UPLOAD_DEST \; >> /var/log/manutencao/cron-upload.log 2>&1

EOF
fi

# Adicionar manutenção preventiva
cat >> "$TEMP_CRON" << EOF
# Manutenção preventiva semanal (${MANUTENCAO_DAY}=Dia da semana, $MANUTENCAO_TIME)
$MANUTENCAO_MIN $MANUTENCAO_HOUR * * $MANUTENCAO_DAY /opt/manutencao/manutencao-completa.sh >> /var/log/manutencao/cron-manutencao.log 2>&1

EOF

# Adicionar alerta de disco
cat >> "$TEMP_CRON" << EOF
# Alerta de espaço em disco (diário às $ALERTA_TIME)
$ALERTA_MIN $ALERTA_HOUR * * * /opt/manutencao/alerta-disco.sh >> /var/log/manutencao/cron-alerta.log 2>&1

EOF

# Adicionar rotação de logs
cat >> "$TEMP_CRON" << 'EOF'
# Rotação de logs (mensalmente, dia 1 às 04:00)
0 4 1 * * /usr/sbin/logrotate /etc/logrotate.conf >> /var/log/manutencao/cron-logrotate.log 2>&1

EOF

# Instalar novo crontab
crontab "$TEMP_CRON"
rm "$TEMP_CRON"

log_success "Cron jobs configurados com sucesso"
echo ""

# Criar diretórios de logs se não existirem
mkdir -p /var/log/manutencao

# Verificar instalação
log "INFO" "========== VERIFICANDO CONFIGURAÇÃO =========="
echo ""

log "INFO" "Cron jobs instalados:"
crontab -l | grep -E "(backup-coolify|manutencao-completa|alerta-disco|backup-destinos|logrotate)" | while read line; do
    echo "  ✓ $line"
done

echo ""

# Mostrar próximas execuções
log "INFO" "========== PRÓXIMAS EXECUÇÕES =========="
echo ""

# Função para calcular próxima execução
get_next_execution() {
    local min=$1
    local hour=$2
    local day=$3
    local current_day=$(date +%u)

    # Converter domingo de 0 para 7
    if [ "$day" -eq 0 ]; then
        day=7
    fi

    # Calcular dias até próxima execução
    local days_until=$((day - current_day))
    if [ $days_until -lt 0 ]; then
        days_until=$((days_until + 7))
    elif [ $days_until -eq 0 ]; then
        # Se é hoje, verificar se já passou o horário
        local current_time=$(date +%H%M)
        local exec_time=$(printf "%02d%02d" $hour $min)
        if [ $current_time -gt $exec_time ]; then
            days_until=7
        fi
    fi

    if [ $days_until -eq 0 ]; then
        echo "Hoje às $(printf "%02d:%02d" $hour $min)"
    else
        date -d "+$days_until days" "+%d/%m/%Y às $(printf "%02d:%02d" $hour $min)"
    fi
}

echo "📅 Backup do Coolify:"
echo "   $(get_next_execution $BACKUP_MIN $BACKUP_HOUR $BACKUP_DAY)"
echo ""

echo "🔧 Manutenção Preventiva:"
echo "   $(get_next_execution $MANUTENCAO_MIN $MANUTENCAO_HOUR $MANUTENCAO_DAY)"
echo ""

echo "💾 Alerta de Disco:"
TOMORROW=$(date -d "tomorrow" +%d/%m/%Y)
if [ $(date +%H) -lt $ALERTA_HOUR ]; then
    echo "   Hoje às $(printf "%02d:%02d" $ALERTA_HOUR $ALERTA_MIN)"
else
    echo "   $TOMORROW às $(printf "%02d:%02d" $ALERTA_HOUR $ALERTA_MIN)"
fi
echo ""

echo "📦 Rotação de Logs:"
NEXT_MONTH=$(date -d "$(date +%Y-%m-01) +1 month" +%d/%m/%Y)
echo "   $NEXT_MONTH às 04:00"
echo ""

if [ "$AUTO_UPLOAD" = "y" ]; then
    echo "☁️  Upload Automático:"
    echo "   $(get_next_execution $BACKUP_MIN $UPLOAD_HOUR $UPLOAD_DAY)"
    echo ""
fi

# Informações adicionais
log "INFO" "========== COMANDOS ÚTEIS =========="
echo ""
echo "  # Ver cron jobs configurados"
echo "  sudo crontab -l"
echo ""
echo "  # Editar manualmente"
echo "  sudo crontab -e"
echo ""
echo "  # Ver logs de execução"
echo "  tail -f /var/log/manutencao/cron-backup.log"
echo "  tail -f /var/log/manutencao/cron-manutencao.log"
echo "  tail -f /var/log/manutencao/cron-alerta.log"
echo ""
echo "  # Verificar próximas execuções (aproximado)"
echo "  grep CRON /var/log/syslog | tail -20"
echo ""
echo "  # Restaurar backup do crontab"
echo "  sudo crontab $CRONTAB_BACKUP"
echo ""

log "SUCCESS" "========== CONFIGURAÇÃO CONCLUÍDA =========="
echo ""
log_success "Tarefas agendadas configuradas automaticamente!"
log "INFO" "Backup do crontab anterior: $CRONTAB_BACKUP"
echo ""

# Testar se cron está rodando
if systemctl is-active --quiet cron || systemctl is-active --quiet crond; then
    log_success "Serviço cron está ativo"
else
    log "WARN" "Serviço cron pode não estar ativo. Execute: sudo systemctl start cron"
fi

echo ""
log "INFO" "Monitore os logs em /var/log/manutencao/ para garantir que tudo funciona"
