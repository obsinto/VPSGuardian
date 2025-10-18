#!/bin/bash
################################################################################
# Script de Restauração Remota do Coolify
# Permite restaurar backup do Coolify em um novo servidor remotamente
# Uso: ./restaurar-coolify-remoto.sh
################################################################################

set -e

LOG_PREFIX="[ Coolify Remote Restore ]"

log() {
    echo "$LOG_PREFIX [ $1 ] $2"
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║      RESTAURAÇÃO REMOTA DO COOLIFY - TOTALMENTE AUTOMATIZADA ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log "INFO" "Este script restaurará um backup do Coolify em um servidor remoto"
log "INFO" "A partir da máquina antiga, de forma totalmente remota"
echo ""

################################################################################
# CONFIGURAÇÃO DO SERVIDOR REMOTO
################################################################################

log "INFO" "========== CONFIGURAÇÃO DO SERVIDOR REMOTO =========="
echo ""

read -p "$LOG_PREFIX [ INPUT ] IP do novo servidor: " NEW_SERVER_IP
read -p "$LOG_PREFIX [ INPUT ] Usuário SSH (padrão: root): " NEW_SERVER_USER
NEW_SERVER_USER=${NEW_SERVER_USER:-root}
read -p "$LOG_PREFIX [ INPUT ] Porta SSH (padrão: 22): " NEW_SERVER_PORT
NEW_SERVER_PORT=${NEW_SERVER_PORT:-22}

# Testar conexão SSH
log "INFO" "Testando conexão SSH..."
if ! ssh -p "$NEW_SERVER_PORT" -o ConnectTimeout=10 "$NEW_SERVER_USER@$NEW_SERVER_IP" "exit" 2>/dev/null; then
    log "ERROR" "Falha na conexão SSH com $NEW_SERVER_IP"
    log "INFO" "Verifique:"
    log "INFO" "  - O IP está correto"
    log "INFO" "  - A porta SSH está aberta"
    log "INFO" "  - Você tem acesso SSH ao servidor"
    exit 1
fi
log "SUCCESS" "Conexão SSH estabelecida!"
echo ""

################################################################################
# SELEÇÃO DO BACKUP
################################################################################

log "INFO" "========== SELEÇÃO DO BACKUP =========="
echo ""

BACKUP_DIR="/root/coolify-backups"

# Verificar se diretório de backups existe
if [ ! -d "$BACKUP_DIR" ]; then
    log "ERROR" "Diretório de backups não encontrado: $BACKUP_DIR"
    exit 1
fi

# Listar backups disponíveis
BACKUPS=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    log "ERROR" "Nenhum backup encontrado em $BACKUP_DIR"
    exit 1
fi

log "INFO" "Backups disponíveis:"
echo ""

for i in "${!BACKUPS[@]}"; do
    BACKUP_NAME=$(basename "${BACKUPS[$i]}")
    BACKUP_SIZE=$(du -h "${BACKUPS[$i]}" | cut -f1)
    BACKUP_DATE=$(stat -c %y "${BACKUPS[$i]}" | cut -d' ' -f1,2 | cut -d'.' -f1)
    echo "  [$i] $BACKUP_NAME"
    echo "      Data: $BACKUP_DATE"
    echo "      Tamanho: $BACKUP_SIZE"
    echo ""
done

read -p "$LOG_PREFIX [ INPUT ] Selecione o número do backup: " BACKUP_INDEX

if [ -z "$BACKUP_INDEX" ] || [ "$BACKUP_INDEX" -ge "${#BACKUPS[@]}" ]; then
    log "ERROR" "Seleção de backup inválida"
    exit 1
fi

SELECTED_BACKUP="${BACKUPS[$BACKUP_INDEX]}"
BACKUP_FILENAME=$(basename "$SELECTED_BACKUP")

log "INFO" "Backup selecionado: $BACKUP_FILENAME"
echo ""

################################################################################
# CONFIRMAÇÃO
################################################################################

log "INFO" "========== CONFIRMAÇÃO =========="
echo ""
echo "  Servidor destino: $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_PORT"
echo "  Backup: $BACKUP_FILENAME"
echo ""
log "WARNING" "Esta operação irá:"
log "WARNING" "  1. Instalar o Coolify no novo servidor (se não estiver instalado)"
log "WARNING" "  2. Transferir o backup para o novo servidor"
log "WARNING" "  3. Restaurar banco de dados, SSH keys e configurações"
log "WARNING" "  4. Reiniciar o Coolify"
echo ""

read -p "$LOG_PREFIX [ INPUT ] Continuar? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    log "INFO" "Operação cancelada pelo usuário"
    exit 0
fi

echo ""

################################################################################
# VERIFICAR SE COOLIFY ESTÁ INSTALADO NO SERVIDOR REMOTO
################################################################################

log "INFO" "========== VERIFICANDO COOLIFY NO SERVIDOR REMOTO =========="
echo ""

log "INFO" "Verificando se Coolify está instalado..."
if ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" "docker ps --filter name=coolify -q" 2>/dev/null | grep -q .; then
    log "SUCCESS" "Coolify encontrado no servidor remoto"

    log "WARNING" "O Coolify já está instalado e rodando"
    read -p "$LOG_PREFIX [ INPUT ] Deseja continuar e sobrescrever? (yes/no): " OVERWRITE
    if [ "$OVERWRITE" != "yes" ]; then
        log "INFO" "Operação cancelada pelo usuário"
        exit 0
    fi
else
    log "INFO" "Coolify não encontrado. Instalando..."

    # Instalar Coolify no servidor remoto
    log "INFO" "Executando instalação do Coolify..."
    ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash" || {
        log "ERROR" "Falha na instalação do Coolify"
        exit 1
    }

    log "SUCCESS" "Coolify instalado com sucesso"

    # Aguardar Coolify iniciar
    log "INFO" "Aguardando Coolify iniciar (30 segundos)..."
    sleep 30
fi

echo ""

################################################################################
# TRANSFERIR BACKUP PARA SERVIDOR REMOTO
################################################################################

log "INFO" "========== TRANSFERINDO BACKUP =========="
echo ""

REMOTE_BACKUP_DIR="/root/coolify-restore-$(date +%s)"

log "INFO" "Criando diretório temporário no servidor remoto..."
ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" "mkdir -p $REMOTE_BACKUP_DIR"

log "INFO" "Transferindo backup (isso pode levar alguns minutos)..."
if scp -P "$NEW_SERVER_PORT" "$SELECTED_BACKUP" "$NEW_SERVER_USER@$NEW_SERVER_IP:$REMOTE_BACKUP_DIR/"; then
    log "SUCCESS" "Backup transferido com sucesso"
else
    log "ERROR" "Falha na transferência do backup"
    exit 1
fi

echo ""

################################################################################
# EXTRAIR BACKUP NO SERVIDOR REMOTO
################################################################################

log "INFO" "========== EXTRAINDO BACKUP =========="
echo ""

log "INFO" "Extraindo backup no servidor remoto..."
ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "cd $REMOTE_BACKUP_DIR && tar -xzf $BACKUP_FILENAME" || {
    log "ERROR" "Falha ao extrair backup"
    exit 1
}

log "SUCCESS" "Backup extraído com sucesso"
echo ""

################################################################################
# PARAR COOLIFY TEMPORARIAMENTE
################################################################################

log "INFO" "========== PARANDO COOLIFY TEMPORARIAMENTE =========="
echo ""

log "INFO" "Parando containers do Coolify..."
ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "docker stop \$(docker ps --filter name=coolify -q)" 2>/dev/null || true

log "SUCCESS" "Coolify parado"
echo ""

################################################################################
# RESTAURAR BANCO DE DADOS
################################################################################

log "INFO" "========== RESTAURANDO BANCO DE DADOS =========="
echo ""

log "INFO" "Restaurando banco de dados PostgreSQL..."

# Encontrar arquivo de dump
DB_DUMP=$(ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "find $REMOTE_BACKUP_DIR -name 'coolify-db-*.dmp' | head -1")

if [ -z "$DB_DUMP" ]; then
    log "ERROR" "Arquivo de dump do banco de dados não encontrado"
    exit 1
fi

log "INFO" "Arquivo de dump encontrado: $(basename $DB_DUMP)"

# Restaurar banco de dados
ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" <<EOF
    # Iniciar apenas o banco de dados
    docker start coolify-db 2>/dev/null || true
    sleep 10

    # Limpar banco de dados existente
    docker exec coolify-db psql -U coolify -d postgres -c "DROP DATABASE IF EXISTS coolify;"
    docker exec coolify-db psql -U coolify -d postgres -c "CREATE DATABASE coolify;"

    # Restaurar dump
    cat "$DB_DUMP" | docker exec -i coolify-db pg_restore \
        --verbose --clean --no-acl --no-owner -U coolify -d coolify 2>&1 | grep -v "already exists\|does not exist" || true
EOF

log "SUCCESS" "Banco de dados restaurado"
echo ""

################################################################################
# RESTAURAR SSH KEYS
################################################################################

log "INFO" "========== RESTAURANDO SSH KEYS =========="
echo ""

log "INFO" "Restaurando chaves SSH..."

ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" <<EOF
    # Backup das keys existentes (se houver)
    if [ -d /data/coolify/ssh/keys ]; then
        mv /data/coolify/ssh/keys /data/coolify/ssh/keys.backup-\$(date +%s)
    fi

    # Restaurar keys do backup
    SSH_KEYS_DIR=\$(find $REMOTE_BACKUP_DIR -type d -name "ssh-keys" | head -1)
    if [ -n "\$SSH_KEYS_DIR" ]; then
        mkdir -p /data/coolify/ssh
        cp -r "\$SSH_KEYS_DIR" /data/coolify/ssh/keys
        chmod 700 /data/coolify/ssh/keys
        chmod 600 /data/coolify/ssh/keys/* 2>/dev/null || true
    fi
EOF

log "SUCCESS" "SSH keys restauradas"
echo ""

################################################################################
# RESTAURAR .ENV
################################################################################

log "INFO" "========== RESTAURANDO CONFIGURAÇÕES =========="
echo ""

log "INFO" "Restaurando arquivo .env..."

ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" <<EOF
    # Backup do .env existente
    if [ -f /data/coolify/source/.env ]; then
        cp /data/coolify/source/.env /data/coolify/source/.env.backup-\$(date +%s)
    fi

    # Restaurar .env do backup
    ENV_FILE=\$(find $REMOTE_BACKUP_DIR -name ".env" | grep -v node_modules | head -1)
    if [ -n "\$ENV_FILE" ]; then
        cp "\$ENV_FILE" /data/coolify/source/.env
    fi

    # Atualizar APP_URL com novo IP
    sed -i "s|APP_URL=.*|APP_URL=http://$NEW_SERVER_IP:8000|g" /data/coolify/source/.env
EOF

log "SUCCESS" "Configurações restauradas"
echo ""

################################################################################
# RESTAURAR AUTHORIZED_KEYS (OPCIONAL)
################################################################################

log "INFO" "========== RESTAURANDO AUTHORIZED_KEYS =========="
echo ""

read -p "$LOG_PREFIX [ INPUT ] Restaurar authorized_keys do backup? (y/N): " RESTORE_AUTH_KEYS
if [ "$RESTORE_AUTH_KEYS" = "y" ]; then
    log "INFO" "Restaurando authorized_keys..."

    ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" <<EOF
        # Backup do authorized_keys existente
        if [ -f ~/.ssh/authorized_keys ]; then
            cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup-\$(date +%s)
        fi

        # Restaurar authorized_keys do backup
        AUTH_KEYS=\$(find $REMOTE_BACKUP_DIR -name "authorized_keys" | head -1)
        if [ -n "\$AUTH_KEYS" ]; then
            mkdir -p ~/.ssh
            cp "\$AUTH_KEYS" ~/.ssh/authorized_keys
            chmod 600 ~/.ssh/authorized_keys
        fi
EOF

    log "SUCCESS" "authorized_keys restaurado"
else
    log "INFO" "authorized_keys não restaurado (mantendo o existente)"
fi

echo ""

################################################################################
# REINICIAR COOLIFY
################################################################################

log "INFO" "========== REINICIANDO COOLIFY =========="
echo ""

log "INFO" "Iniciando todos os containers do Coolify..."
ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "cd /data/coolify/source && docker compose up -d" || {
    log "ERROR" "Falha ao reiniciar Coolify"
    exit 1
}

log "SUCCESS" "Coolify reiniciado"

# Aguardar Coolify iniciar completamente
log "INFO" "Aguardando Coolify iniciar (30 segundos)..."
sleep 30

echo ""

################################################################################
# VERIFICAÇÃO FINAL
################################################################################

log "INFO" "========== VERIFICAÇÃO FINAL =========="
echo ""

log "INFO" "Verificando status dos containers..."
CONTAINERS_RUNNING=$(ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "docker ps --filter name=coolify --format '{{.Names}}'" | wc -l)

log "SUCCESS" "Containers rodando: $CONTAINERS_RUNNING"

if [ "$CONTAINERS_RUNNING" -ge 3 ]; then
    log "SUCCESS" "Coolify está rodando corretamente!"
else
    log "WARNING" "Menos containers que o esperado. Verifique os logs."
fi

echo ""

################################################################################
# LIMPEZA
################################################################################

log "INFO" "========== LIMPEZA =========="
echo ""

read -p "$LOG_PREFIX [ INPUT ] Remover arquivos temporários do servidor remoto? (Y/n): " CLEANUP
if [ "$CLEANUP" != "n" ]; then
    log "INFO" "Removendo arquivos temporários..."
    ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" "rm -rf $REMOTE_BACKUP_DIR"
    log "SUCCESS" "Arquivos temporários removidos"
else
    log "INFO" "Arquivos temporários mantidos em: $REMOTE_BACKUP_DIR"
fi

echo ""

################################################################################
# RESUMO FINAL
################################################################################

log "SUCCESS" "========== RESTAURAÇÃO CONCLUÍDA COM SUCESSO! =========="
echo ""
echo "  🎉 Coolify restaurado no servidor: $NEW_SERVER_IP"
echo "  🌐 Acesse: http://$NEW_SERVER_IP:8000"
echo ""
log "INFO" "Próximos passos:"
log "INFO" "  1. Acesse o Coolify e faça login"
log "INFO" "  2. Verifique se todas as aplicações estão listadas"
log "INFO" "  3. Atualize DNS para apontar para o novo IP: $NEW_SERVER_IP"
log "INFO" "  4. Teste todas as aplicações"
log "INFO" "  5. Mantenha o servidor antigo online por 24-48h"
echo ""
log "SUCCESS" "Restauração remota finalizada! 🚀"
