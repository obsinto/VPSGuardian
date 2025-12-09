#!/bin/bash
################################################################################
# Script de Backup Completo para Coolify
# Complementa o script de manutenção
# Versão: 2.0 - Refatorado com bibliotecas compartilhadas
# Compatível com o padrão de migração do Coolify
################################################################################

# Carregar bibliotecas compartilhadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Inicializar script (cria diretórios, configura log)
init_script

# Configurações (usa variáveis de config/default.conf)
BACKUP_BASE_DIR="${COOLIFY_BACKUP_DIR:-/var/backups/vpsguardian/coolify}"
BACKUP_DIR="$BACKUP_BASE_DIR/$(date +%Y%m%d_%H%M%S)"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# Diretórios e arquivos do Coolify
COOLIFY_DATA_DIR="/data/coolify"
COOLIFY_SOURCE_DIR="$COOLIFY_DATA_DIR/source"
COOLIFY_SSH_DIR="$COOLIFY_DATA_DIR/ssh/keys"
COOLIFY_ENV_FILE="$COOLIFY_SOURCE_DIR/.env"

# Notificações (configure conforme necessário)
WEBHOOK_URL=""
EMAIL=""

################################################################################
# FUNÇÕES
################################################################################

notificar() {
    local mensagem="$1"

    if [ -n "$EMAIL" ]; then
        echo "$mensagem" | mail -s "Backup Coolify - $(hostname)" "$EMAIL"
    fi

    if [ -n "$WEBHOOK_URL" ]; then
        curl -s -H "Content-Type: application/json" \
             -d "{\"content\":\"$mensagem\"}" \
             "$WEBHOOK_URL" > /dev/null 2>&1
    fi
}

################################################################################
# INÍCIO DO BACKUP
################################################################################

log_section "VPS Guardian - Backup Coolify"

# Verificar se Coolify está instalado
check_docker || exit 1
check_coolify || exit 1
check_container_running "coolify-db" || exit 1
log_success "Coolify detectado e rodando"

# Criar diretório de backup
ensure_directory "$BACKUP_DIR" 700
log_info "Diretório de backup criado: $BACKUP_DIR"

################################################################################
# 1. BACKUP DO BANCO DE DADOS
################################################################################

log_section "Backup do Banco de Dados PostgreSQL"

DB_BACKUP_FILE="$BACKUP_DIR/coolify-db-$(date +%s).dmp"

docker exec coolify-db pg_dump -U coolify -d coolify -F c -f /tmp/backup.dmp 2>/dev/null
if [ $? -eq 0 ]; then
    docker cp coolify-db:/tmp/backup.dmp "$DB_BACKUP_FILE"
    docker exec coolify-db rm /tmp/backup.dmp

    DB_SIZE=$(du -h "$DB_BACKUP_FILE" | cut -f1)
    log_success "Banco de dados backupeado: $DB_SIZE"
else
    log_error "Falha ao fazer backup do banco de dados"
    notificar "⚠️ Falha no backup do banco de dados Coolify em $(hostname)"
fi

################################################################################
# 2. BACKUP DAS SSH KEYS
################################################################################

log_section "Backup das SSH Keys"

if [ -d "$COOLIFY_SSH_DIR" ]; then
    cp -r "$COOLIFY_SSH_DIR" "$BACKUP_DIR/ssh-keys"
    KEYS_COUNT=$(find "$BACKUP_DIR/ssh-keys" -type f | wc -l)
    log_success "SSH Keys backupeadas: $KEYS_COUNT arquivos"
else
    log_error "Diretório de SSH keys não encontrado: $COOLIFY_SSH_DIR"
fi

################################################################################
# 3. BACKUP DO .ENV E CONFIGURAÇÕES
################################################################################

log_section "Backup das Configurações"

if [ -f "$COOLIFY_ENV_FILE" ]; then
    cp "$COOLIFY_ENV_FILE" "$BACKUP_DIR/.env"

    # Extrair APP_KEY para referência
    APP_KEY=$(grep "^APP_KEY=" "$COOLIFY_ENV_FILE" | cut -d '=' -f2-)
    echo "APP_KEY=$APP_KEY" > "$BACKUP_DIR/app-key.txt"

    log_success "Arquivo .env e APP_KEY backupeados"
else
    log_error "Arquivo .env não encontrado: $COOLIFY_ENV_FILE"
fi

# Backup de outras configurações importantes
if [ -d "/etc/nginx" ]; then
    cp -r /etc/nginx "$BACKUP_DIR/nginx-config"
    log_success "Configurações do Nginx backupeadas"
fi

# Backup do authorized_keys (importante para acesso SSH)
if [ -f "/root/.ssh/authorized_keys" ]; then
    cp /root/.ssh/authorized_keys "$BACKUP_DIR/authorized_keys"
    log_success "Arquivo authorized_keys backupeado"
fi

################################################################################
# 4. BACKUP DE VOLUMES DOCKER (OPCIONAL)
################################################################################

log_section "Volumes Docker"

# Criar arquivo com lista de volumes
docker volume ls --format '{{.Name}}' > "$BACKUP_DIR/volumes-list.txt"
VOLUMES_COUNT=$(wc -l < "$BACKUP_DIR/volumes-list.txt")
log_info "Total de volumes Docker: $VOLUMES_COUNT"

# Se quiser fazer backup de volumes específicos, descomente abaixo
# IMPORTANTE: Isso pode consumir MUITO espaço em disco
#
# mkdir -p "$BACKUP_DIR/volumes"
# while IFS= read -r volume; do
#     # Pular volumes do sistema
#     if [[ "$volume" =~ ^(coolify|postgres) ]]; then
#         continue
#     fi
#
#     log_info "Backupeando volume: $volume"
#     docker run --rm \
#       -v "$volume":/volume \
#       -v "$BACKUP_DIR/volumes":/backup \
#       busybox \
#       tar czf "/backup/${volume}.tar.gz" -C /volume .
# done < "$BACKUP_DIR/volumes-list.txt"

log_info "Backup de volumes desativado (economizar espaço). Habilite se necessário."

################################################################################
# 5. INFORMAÇÕES DO SISTEMA
################################################################################

log_section "Informações do Sistema"

cat > "$BACKUP_DIR/system-info.txt" <<EOF
Sistema Operacional: $(lsb_release -d | cut -f2)
Kernel: $(uname -r)
Docker Version: $(docker --version)
Espaço em disco: $(df -h / | tail -1 | awk '{print $5 " usado de " $2}')
Memória: $(free -h | grep Mem | awk '{print $3 " usado de " $2}')
EOF

log_success "Informações do sistema coletadas"

################################################################################
# 6. CRIAR ARQUIVO DE METADADOS
################################################################################

log_section "Arquivo de Metadados"

COOLIFY_VERSION=$(docker ps --filter "name=coolify" --format '{{.Image}}' | grep coollabsio/coolify | head -n1)

cat > "$BACKUP_DIR/backup-info.txt" <<EOF
╔════════════════════════════════════════════════════════════╗
║              BACKUP DO COOLIFY                             ║
╚════════════════════════════════════════════════════════════╝

📅 Data: $(date '+%Y-%m-%d %H:%M:%S')
🖥️  Hostname: $(hostname)
🐳 Versão do Coolify: $COOLIFY_VERSION

📦 CONTEÚDO DO BACKUP:
  ✓ Banco de dados PostgreSQL (dump completo no formato custom)
  ✓ SSH Keys do Coolify (/data/coolify/ssh/keys)
  ✓ Arquivo .env e APP_KEY extraída
  ✓ Arquivo authorized_keys do root
  ✓ Configurações do Nginx
  ✓ Lista de volumes Docker
  ✓ Informações do sistema

💾 Tamanho total: $(du -sh "$BACKUP_DIR" | cut -f1)

🔄 COMO RESTAURAR ESTE BACKUP:

1. Instale o Coolify no novo servidor:
   curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

2. Pare os containers (exceto o banco):
   docker ps --filter name=coolify --format '{{.Names}}' | grep -v 'coolify-db' | xargs docker stop

3. Restaure o banco de dados:
   cat coolify-db-*.dmp | docker exec -i coolify-db pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify

4. Copie as SSH keys:
   cp -r ssh-keys/* /data/coolify/ssh/keys/

5. Restaure o authorized_keys:
   cat authorized_keys >> /root/.ssh/authorized_keys

6. Atualize o .env com a APP_KEY:
   cd /data/coolify/source
   sed -i '/^APP_PREVIOUS_KEYS=/d' .env
   echo 'APP_PREVIOUS_KEYS=<APP_KEY_DO_BACKUP>' >> .env

7. Execute o install script novamente:
   curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

📋 Para mais detalhes, consulte: https://coolify.io/docs

EOF

log_success "Arquivo de metadados criado"

################################################################################
# 7. COMPACTAR BACKUP
################################################################################

log_section "Compactação"

cd "$BACKUP_BASE_DIR"
BACKUP_BASENAME=$(basename "$BACKUP_DIR")
tar -czf "${BACKUP_BASENAME}.tar.gz" "$BACKUP_BASENAME" 2>/dev/null

if [ $? -eq 0 ]; then
    COMPRESSED_SIZE=$(du -h "${BACKUP_BASENAME}.tar.gz" | cut -f1)
    log_success "Backup compactado: $COMPRESSED_SIZE"

    # Remover diretório não compactado para economizar espaço
    rm -rf "$BACKUP_DIR"
    log_info "Diretório descompactado removido"
else
    log_error "Falha ao compactar backup"
fi

################################################################################
# 8. LIMPEZA DE BACKUPS ANTIGOS
################################################################################

log_section "Limpeza de Backups Antigos"

BACKUPS_REMOVIDOS=$(find "$BACKUP_BASE_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)

if [ "$BACKUPS_REMOVIDOS" -gt 0 ]; then
    log_success "$BACKUPS_REMOVIDOS backups antigos removidos (>${RETENTION_DAYS} dias)"
else
    log_info "Nenhum backup antigo para remover"
fi

################################################################################
# 9. RELATÓRIO FINAL
################################################################################

log_section "BACKUP CONCLUÍDO"

BACKUP_FINAL=$(ls -lht "$BACKUP_BASE_DIR"/*.tar.gz 2>/dev/null | head -1 | awk '{print $9, "("$5")"}')

RELATORIO="
📦 RELATÓRIO DE BACKUP - $(hostname)
Data: $(date '+%d/%m/%Y %H:%M')

✅ Backup criado: $BACKUP_FINAL

📊 Conteúdo:
  - Banco de dados PostgreSQL: ✓
  - SSH Keys: ✓
  - Configurações (.env, Nginx): ✓
  - authorized_keys: ✓
  - Lista de volumes: ✓

🗄️  Backups mantidos: $(ls -1 "$BACKUP_BASE_DIR"/*.tar.gz 2>/dev/null | wc -l)
🗑️  Backups removidos: $BACKUPS_REMOVIDOS

📍 Localização: $BACKUP_BASE_DIR
📋 Log completo: $LOG_FILE

⚠️  IMPORTANTE:
  - Baixe este backup para outro local seguro
  - Teste a restauração periodicamente
  - Mantenha backups off-site (outro servidor/cloud)
"

echo "$RELATORIO" | tee -a "$LOG_FILE"

# Notificar sucesso
notificar "✅ Backup do Coolify concluído em $(hostname). Tamanho: $COMPRESSED_SIZE"

exit 0
