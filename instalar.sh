#!/bin/bash
################################################################################
# Script de Instalação - Sistema de Manutenção, Backup e Migração
# Propósito: Instalar todos os scripts na estrutura recomendada
# Uso: sudo ./instalar.sh
################################################################################

set -e  # Sair se houver erro

LOG_PREFIX="[ Instalador ]"

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
echo "║    INSTALADOR - SISTEMA DE MANUTENÇÃO E BACKUP VPS        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log "INFO" "Este script irá instalar:"
echo "  • Scripts de backup em /opt/manutencao/"
echo "  • Scripts de manutenção em /opt/manutencao/"
echo "  • Scripts de migração em /opt/manutencao/"
echo "  • Comandos auxiliares em /usr/local/bin/"
echo "  • Diretórios de logs em /var/log/manutencao/"
echo "  • Diretórios de backups em /root/coolify-backups/"
echo ""

read -p "$LOG_PREFIX [ INPUT ] Continuar com a instalação? (sim/nao): " CONFIRM
if [ "$CONFIRM" != "sim" ]; then
    log "INFO" "Instalação cancelada."
    exit 0
fi

echo ""
log "INFO" "========== INICIANDO INSTALAÇÃO =========="

# 1. Criar diretórios
log "INFO" "Criando diretórios..."
mkdir -p /opt/manutencao
mkdir -p /var/log/manutencao
mkdir -p /root/coolify-backups
mkdir -p /root/volume-backups
mkdir -p /root/database-backups
log_success "Diretórios criados"

# 2. Copiar scripts de backup
log "INFO" "Instalando scripts de backup..."
cp backup/backup-coolify.sh /opt/manutencao/
cp backup/backup-databases.sh /opt/manutencao/
cp backup/backup-destinos.sh /opt/manutencao/
cp backup/backup-volume.sh /usr/local/bin/backup-volume
cp backup/backup-volume-interativo.sh /usr/local/bin/backup-volume-interativo
cp backup/restaurar-volume-interativo.sh /usr/local/bin/restaurar-volume-interativo
cp backup/restaurar-coolify-remoto.sh /opt/manutencao/
log_success "Scripts de backup instalados"

# 3. Copiar scripts de manutenção
log "INFO" "Instalando scripts de manutenção..."
cp manutencao/manutencao-completa.sh /opt/manutencao/
cp manutencao/alerta-disco.sh /opt/manutencao/
cp manutencao/configurar-updates-automaticos.sh /opt/manutencao/
log_success "Scripts de manutenção instalados"

# 4. Copiar scripts de migração
log "INFO" "Instalando scripts de migração..."
cp migrar/migrar-coolify.sh /opt/manutencao/
cp migrar/migrar-volumes.sh /opt/manutencao/
cp migrar/transferir-backups.sh /opt/manutencao/
log_success "Scripts de migração instalados"

# 5. Copiar scripts auxiliares
log "INFO" "Instalando scripts auxiliares..."
cp scripts-auxiliares/status-completo.sh /usr/local/bin/status-completo
cp scripts-auxiliares/test-sistema.sh /opt/manutencao/
cp scripts-auxiliares/configurar-cron.sh /opt/manutencao/
log_success "Scripts auxiliares instalados"

# 6. Copiar configuração (opcional)
if [ -f config/config.env ]; then
    log "INFO" "Copiando arquivo de configuração..."
    cp config/config.env /opt/manutencao/config.env.exemplo
    log_success "Arquivo de configuração copiado como exemplo"
fi

# 7. Dar permissões de execução
log "INFO" "Configurando permissões..."
chmod +x /opt/manutencao/*.sh
chmod +x /usr/local/bin/backup-volume*
chmod +x /usr/local/bin/restaurar-volume*
chmod +x /usr/local/bin/status-completo
log_success "Permissões configuradas"

# 8. Verificar instalação
log "INFO" "Verificando instalação..."
ERRORS=0

# Verificar scripts em /opt/manutencao
for script in backup-coolify.sh backup-databases.sh manutencao-completa.sh alerta-disco.sh migrar-coolify.sh migrar-volumes.sh transferir-backups.sh test-sistema.sh configurar-cron.sh; do
    if [ -x "/opt/manutencao/$script" ]; then
        log_success "$script OK"
    else
        log_error "$script FALHOU"
        ((ERRORS++))
    fi
done

# Verificar comandos em /usr/local/bin
for cmd in backup-volume backup-volume-interativo restaurar-volume-interativo status-completo; do
    if [ -x "/usr/local/bin/$cmd" ]; then
        log_success "$cmd OK"
    else
        log_error "$cmd FALHOU"
        ((ERRORS++))
    fi
done

# Verificar diretórios
for dir in /opt/manutencao /var/log/manutencao /root/coolify-backups /root/volume-backups /root/database-backups; do
    if [ -d "$dir" ]; then
        log_success "$dir OK"
    else
        log_error "$dir FALHOU"
        ((ERRORS++))
    fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
    log "SUCCESS" "========== INSTALAÇÃO CONCLUÍDA COM SUCESSO! =========="
else
    log_error "========== INSTALAÇÃO COM $ERRORS ERRO(S) =========="
    exit 1
fi

echo ""
log "INFO" "Estrutura instalada:"
echo ""
echo "  📂 Scripts:"
echo "     /opt/manutencao/backup-coolify.sh"
echo "     /opt/manutencao/backup-databases.sh         ⭐ NOVO"
echo "     /opt/manutencao/manutencao-completa.sh"
echo "     /opt/manutencao/alerta-disco.sh"
echo "     /opt/manutencao/migrar-coolify.sh"
echo "     /opt/manutencao/migrar-volumes.sh"
echo "     /opt/manutencao/transferir-backups.sh"
echo "     /opt/manutencao/test-sistema.sh"
echo "     /opt/manutencao/configurar-cron.sh"
echo ""
echo "  🛠️  Comandos globais:"
echo "     backup-volume"
echo "     backup-volume-interativo"
echo "     restaurar-volume-interativo"
echo "     status-completo"
echo ""
echo "  📁 Diretórios:"
echo "     /var/log/manutencao/      (logs)"
echo "     /root/coolify-backups/    (backups do Coolify)"
echo "     /root/database-backups/   (backups de bancos de dados)  ⭐ NOVO"
echo "     /root/volume-backups/     (backups de volumes)"
echo ""

log "INFO" "========== CONFIGURAÇÃO DE UPDATES AUTOMÁTICOS =========="
echo ""
read -p "$LOG_PREFIX [ INPUT ] Deseja configurar updates automáticos agora? (Y/n): " CONFIG_UPDATES
CONFIG_UPDATES=${CONFIG_UPDATES:-y}

if [ "$CONFIG_UPDATES" = "y" ]; then
    echo ""
    log "INFO" "Executando configuração de updates automáticos..."
    /opt/manutencao/configurar-updates-automaticos.sh
else
    echo ""
    log "INFO" "Updates automáticos NÃO configurados"
    log "INFO" "Execute mais tarde: sudo /opt/manutencao/configurar-updates-automaticos.sh"
fi

echo ""
log "INFO" "========== CONFIGURAÇÃO DE TAREFAS AGENDADAS (CRON) =========="
echo ""
read -p "$LOG_PREFIX [ INPUT ] Deseja configurar cron jobs automaticamente agora? (Y/n): " CONFIG_CRON
CONFIG_CRON=${CONFIG_CRON:-y}

if [ "$CONFIG_CRON" = "y" ]; then
    echo ""
    log "INFO" "Executando configuração automática de cron jobs..."
    /opt/manutencao/configurar-cron.sh
else
    echo ""
    log "INFO" "Cron jobs NÃO configurados"
    log "INFO" "Execute mais tarde: sudo /opt/manutencao/configurar-cron.sh"
fi

echo ""
log "INFO" "========== PRÓXIMOS PASSOS =========="
echo ""
echo "  1. Configure notificações (opcional):"
echo "     sudo nano /opt/manutencao/backup-coolify.sh"
echo "     # Edite EMAIL e WEBHOOK_URL"
echo ""

if [ "$CONFIG_CRON" != "y" ]; then
    echo "  2. Configure tarefas agendadas (cron):"
    echo "     sudo /opt/manutencao/configurar-cron.sh"
    echo "     # OU manualmente: sudo crontab -e"
    echo ""
fi

if [ "$CONFIG_UPDATES" != "y" ]; then
    echo "  3. Configure updates automáticos:"
    echo "     sudo /opt/manutencao/configurar-updates-automaticos.sh"
    echo ""
fi

echo "  4. Teste a instalação:"
echo "     sudo /opt/manutencao/test-sistema.sh"
echo ""
echo "  5. Execute primeiro backup:"
echo "     sudo /opt/manutencao/backup-coolify.sh"
echo ""
echo "  6. Veja o status:"
echo "     status-completo"
echo ""

log "SUCCESS" "Instalação concluída! Sistema pronto para uso."
