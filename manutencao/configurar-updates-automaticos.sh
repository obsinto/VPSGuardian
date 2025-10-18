#!/bin/bash
################################################################################
# Script de Configuração de Updates Automáticos
# Propósito: Configurar unattended-upgrades para VPS com Docker/Coolify
# Uso: sudo ./configurar-updates-automaticos.sh
################################################################################

set -e

LOG_PREFIX="[ Updates Automáticos ]"

log() {
    echo "$LOG_PREFIX [ $1 ] $2"
}

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    log "ERROR" "Este script deve ser executado como root (use sudo)"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║      CONFIGURAÇÃO DE UPDATES AUTOMÁTICOS DE SEGURANÇA      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log "INFO" "Este script irá configurar updates automáticos de segurança"
log "INFO" "Otimizado para VPS com Docker e Coolify"
echo ""

# Instalar pacotes necessários
log "INFO" "========== INSTALANDO PACOTES =========="
echo ""

log "INFO" "Instalando unattended-upgrades e apt-listchanges..."
apt update -qq
apt install -y unattended-upgrades apt-listchanges

log "SUCCESS" "Pacotes instalados"
echo ""

# Ativar unattended-upgrades
log "INFO" "========== ATIVANDO UNATTENDED-UPGRADES =========="
echo ""

log "INFO" "Ativando serviço..."
dpkg-reconfigure -plow unattended-upgrades

log "SUCCESS" "Serviço ativado"
echo ""

# Backup da configuração original
log "INFO" "========== BACKUP DA CONFIGURAÇÃO ORIGINAL =========="
echo ""

CONFIG_FILE="/etc/apt/apt.conf.d/50unattended-upgrades"
BACKUP_FILE="/etc/apt/apt.conf.d/50unattended-upgrades.bak"

if [ ! -f "$BACKUP_FILE" ]; then
    log "INFO" "Criando backup da configuração original..."
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    log "SUCCESS" "Backup criado: $BACKUP_FILE"
else
    log "INFO" "Backup já existe: $BACKUP_FILE"
fi

echo ""

# Perguntar configurações ao usuário
log "INFO" "========== CONFIGURAÇÃO PERSONALIZADA =========="
echo ""

read -p "$LOG_PREFIX [ INPUT ] Incluir updates regulares além de segurança? (y/N): " INCLUDE_UPDATES
INCLUDE_UPDATES=${INCLUDE_UPDATES:-n}

read -p "$LOG_PREFIX [ INPUT ] Reiniciar automaticamente se necessário? (y/N): " AUTO_REBOOT
AUTO_REBOOT=${AUTO_REBOOT:-n}

read -p "$LOG_PREFIX [ INPUT ] Horário para reinício automático (padrão: 03:00): " REBOOT_TIME
REBOOT_TIME=${REBOOT_TIME:-03:00}

read -p "$LOG_PREFIX [ INPUT ] Email para notificações (deixe vazio para não enviar): " EMAIL_ADDRESS

echo ""
log "INFO" "Configurações escolhidas:"
log "INFO" "  - Updates regulares: $([ "$INCLUDE_UPDATES" = "y" ] && echo "SIM" || echo "NÃO")"
log "INFO" "  - Reinício automático: $([ "$AUTO_REBOOT" = "y" ] && echo "SIM às $REBOOT_TIME" || echo "NÃO")"
log "INFO" "  - Email notificações: ${EMAIL_ADDRESS:-Nenhum}"
echo ""

read -p "$LOG_PREFIX [ INPUT ] Continuar com estas configurações? (Y/n): " CONFIRM
if [ "$CONFIRM" = "n" ]; then
    log "INFO" "Configuração cancelada"
    exit 0
fi

echo ""

# Criar configuração otimizada
log "INFO" "========== CRIANDO CONFIGURAÇÃO OTIMIZADA =========="
echo ""

log "INFO" "Escrevendo configuração em $CONFIG_FILE..."

cat > "$CONFIG_FILE" << 'EOF'
// Configuração otimizada de Updates Automáticos
// Gerado automaticamente para VPS com Docker/Coolify
// Data: $(date +%Y-%m-%d)

Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
EOF

# Adicionar updates regulares se solicitado
if [ "$INCLUDE_UPDATES" = "y" ]; then
    cat >> "$CONFIG_FILE" << 'EOF'
    "${distro_id}:${distro_codename}-updates";
EOF
fi

cat >> "$CONFIG_FILE" << 'EOF'
};

// Pacotes que NUNCA devem ser atualizados automaticamente
Unattended-Upgrade::Package-Blacklist {
    // Exemplos (descomente se necessário):
    // "docker-ce";        // Docker Engine
    // "docker-ce-cli";    // Docker CLI
    // "containerd.io";    // Containerd
    // "linux-image-*";    // Kernel do Linux
    // "postgresql-*";     // PostgreSQL
};

// Remover dependências não usadas automaticamente
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Auto-remover kernels antigos (mantém apenas 2 últimos)
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";

EOF

# Configurar reinício automático
if [ "$AUTO_REBOOT" = "y" ]; then
    cat >> "$CONFIG_FILE" << EOF
// Reiniciar automaticamente se necessário
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
Unattended-Upgrade::Automatic-Reboot-Time "$REBOOT_TIME";
EOF
else
    cat >> "$CONFIG_FILE" << 'EOF'
// Reiniciar automaticamente se necessário
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF
fi

# Configurar email se fornecido
if [ -n "$EMAIL_ADDRESS" ]; then
    cat >> "$CONFIG_FILE" << EOF

// Notificações por email
Unattended-Upgrade::Mail "$EMAIL_ADDRESS";
Unattended-Upgrade::MailReport "on-change";
EOF
else
    cat >> "$CONFIG_FILE" << 'EOF'

// Notificações por email (desabilitado)
// Unattended-Upgrade::Mail "seu-email@exemplo.com";
Unattended-Upgrade::MailReport "on-change";
EOF
fi

# Adicionar configurações finais
cat >> "$CONFIG_FILE" << 'EOF'

// Aplicar updates em passos mínimos (mais estável)
Unattended-Upgrade::MinimalSteps "true";

// Instalar atualizações de segurança automaticamente
Unattended-Upgrade::InstallOnShutdown "false";

// Logar detalhadamente
Unattended-Upgrade::Verbose "true";

// Modo de debug (desabilitado por padrão)
// Unattended-Upgrade::Debug "true";

// Baixar e instalar automaticamente
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

log "SUCCESS" "Configuração criada com sucesso"
echo ""

# Criar configuração adicional
log "INFO" "========== CONFIGURAÇÃO ADICIONAL =========="
echo ""

AUTO_UPGRADES_FILE="/etc/apt/apt.conf.d/20auto-upgrades"

log "INFO" "Criando $AUTO_UPGRADES_FILE..."

cat > "$AUTO_UPGRADES_FILE" << 'EOF'
// Habilitar updates automáticos
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

log "SUCCESS" "Configuração adicional criada"
echo ""

# Habilitar e iniciar serviços
log "INFO" "========== HABILITANDO SERVIÇOS =========="
echo ""

log "INFO" "Habilitando timer do unattended-upgrades..."
systemctl enable unattended-upgrades
systemctl restart unattended-upgrades

log "SUCCESS" "Serviços habilitados e iniciados"
echo ""

# Testar configuração
log "INFO" "========== TESTANDO CONFIGURAÇÃO =========="
echo ""

log "INFO" "Executando dry-run (simulação)..."
unattended-upgrade --dry-run --debug

echo ""
log "SUCCESS" "Teste de configuração concluído"
echo ""

# Resumo
log "SUCCESS" "========== CONFIGURAÇÃO CONCLUÍDA =========="
echo ""
echo "  ✅ Unattended-upgrades instalado e configurado"
echo "  ✅ Updates de segurança: HABILITADOS"
echo "  ✅ Updates regulares: $([ "$INCLUDE_UPDATES" = "y" ] && echo "HABILITADOS" || echo "DESABILITADOS")"
echo "  ✅ Reinício automático: $([ "$AUTO_REBOOT" = "y" ] && echo "HABILITADO às $REBOOT_TIME" || echo "DESABILITADO")"
echo "  ✅ Limpeza automática: HABILITADA (a cada 7 dias)"
echo "  ✅ Remoção de kernels antigos: HABILITADA"
echo ""

if [ -n "$EMAIL_ADDRESS" ]; then
    echo "  📧 Notificações enviadas para: $EMAIL_ADDRESS"
    echo ""
fi

echo "  📁 Arquivos de configuração:"
echo "     • $CONFIG_FILE"
echo "     • $AUTO_UPGRADES_FILE"
echo "     • Backup: $BACKUP_FILE"
echo ""

log "INFO" "========== COMANDOS ÚTEIS =========="
echo ""
echo "  # Ver status do serviço"
echo "  sudo systemctl status unattended-upgrades"
echo ""
echo "  # Ver log de updates"
echo "  sudo cat /var/log/unattended-upgrades/unattended-upgrades.log"
echo ""
echo "  # Executar update manualmente (dry-run)"
echo "  sudo unattended-upgrade --dry-run --debug"
echo ""
echo "  # Executar update manualmente"
echo "  sudo unattended-upgrade --debug"
echo ""
echo "  # Editar configuração"
echo "  sudo nano $CONFIG_FILE"
echo ""
echo "  # Restaurar backup"
echo "  sudo cp $BACKUP_FILE $CONFIG_FILE"
echo ""

log "INFO" "========== PRÓXIMOS PASSOS =========="
echo ""
echo "  1. Verifique os logs regularmente:"
echo "     tail -f /var/log/unattended-upgrades/unattended-upgrades.log"
echo ""
echo "  2. Teste manualmente após alguns dias:"
echo "     sudo unattended-upgrade --dry-run"
echo ""
echo "  3. Configure email (se ainda não fez):"
echo "     sudo apt install mailutils -y"
echo ""

log "SUCCESS" "Sistema de updates automáticos configurado e ativo! 🚀"
