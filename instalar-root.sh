#!/bin/bash
################################################################################
# Script de Instalação Alternativa - Tudo no /root/
# Propósito: Instalar tudo em /root/manutencao (estrutura simples)
# Uso: sudo ./instalar-root.sh
################################################################################

set -e

LOG_PREFIX="[ Instalador Root ]"

log() {
    echo "$LOG_PREFIX [ $1 ] $2"
}

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    echo "$LOG_PREFIX [ ERRO ] Execute como root: sudo ./instalar-root.sh"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║    INSTALAÇÃO SIMPLIFICADA - TUDO EM /root/manutencao     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log "INFO" "Esta instalação coloca TUDO em /root/manutencao/"
echo "  • Mais simples de gerenciar"
echo "  • Tudo em um só lugar"
echo "  • Ideal para ambientes de teste/desenvolvimento"
echo ""

read -p "$LOG_PREFIX [ INPUT ] Continuar? (sim/nao): " CONFIRM
if [ "$CONFIRM" != "sim" ]; then
    log "INFO" "Cancelado."
    exit 0
fi

BASE_DIR="/root/manutencao"

log "INFO" "Criando estrutura em $BASE_DIR..."

# Criar estrutura
mkdir -p "$BASE_DIR/scripts/backup"
mkdir -p "$BASE_DIR/scripts/manutencao"
mkdir -p "$BASE_DIR/scripts/migrar"
mkdir -p "$BASE_DIR/scripts/auxiliares"
mkdir -p "$BASE_DIR/backups/coolify"
mkdir -p "$BASE_DIR/backups/volumes"
mkdir -p "$BASE_DIR/logs"
mkdir -p "$BASE_DIR/config"

# Copiar scripts
log "INFO" "Copiando scripts..."
cp backup/*.sh "$BASE_DIR/scripts/backup/"
cp manutencao/*.sh "$BASE_DIR/scripts/manutencao/"
cp migrar/*.sh "$BASE_DIR/scripts/migrar/"
cp scripts-auxiliares/*.sh "$BASE_DIR/scripts/auxiliares/"
cp config/* "$BASE_DIR/config/" 2>/dev/null || true

# Permissões
log "INFO" "Configurando permissões..."
chmod +x "$BASE_DIR/scripts"/**/*.sh

# Criar links simbólicos para fácil acesso
log "INFO" "Criando atalhos..."
ln -sf "$BASE_DIR/scripts/auxiliares/status-completo.sh" /usr/local/bin/status-completo
ln -sf "$BASE_DIR/scripts/backup/backup-volume.sh" /usr/local/bin/backup-volume
ln -sf "$BASE_DIR/scripts/backup/backup-volume-interativo.sh" /usr/local/bin/backup-volume-interativo

# Atualizar paths nos scripts
log "INFO" "Ajustando caminhos nos scripts..."
find "$BASE_DIR/scripts" -name "*.sh" -type f -exec sed -i \
    -e "s|/var/log/manutencao|$BASE_DIR/logs|g" \
    -e "s|/root/coolify-backups|$BASE_DIR/backups/coolify|g" \
    -e "s|/root/volume-backups|$BASE_DIR/backups/volumes|g" \
    -e "s|/opt/manutencao|$BASE_DIR/scripts|g" \
    {} \;

echo ""
log "SUCCESS" "========== INSTALAÇÃO CONCLUÍDA! =========="
echo ""
echo "  📂 Estrutura criada:"
echo ""
echo "  $BASE_DIR/"
echo "  ├── scripts/"
echo "  │   ├── backup/           (scripts de backup)"
echo "  │   ├── manutencao/       (scripts de manutenção)"
echo "  │   ├── migrar/           (scripts de migração)"
echo "  │   └── auxiliares/       (scripts auxiliares)"
echo "  ├── backups/"
echo "  │   ├── coolify/          (backups do Coolify)"
echo "  │   └── volumes/          (backups de volumes)"
echo "  ├── logs/                 (logs do sistema)"
echo "  └── config/               (configurações)"
echo ""
echo "  🛠️  Comandos disponíveis:"
echo "     status-completo"
echo "     backup-volume"
echo "     backup-volume-interativo"
echo ""
echo "  📝 Uso dos scripts:"
echo "     cd $BASE_DIR/scripts/backup && ./backup-coolify.sh"
echo "     cd $BASE_DIR/scripts/manutencao && ./manutencao-completa.sh"
echo "     cd $BASE_DIR/scripts/migrar && ./migrar-coolify.sh"
echo ""
echo "  ⚠️  IMPORTANTE:"
echo "     Os scripts foram ajustados para usar os caminhos:"
echo "     - Logs: $BASE_DIR/logs/"
echo "     - Backups: $BASE_DIR/backups/"
echo ""

log "INFO" "Configure o cron usando os caminhos ajustados!"
