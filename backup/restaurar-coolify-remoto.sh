#!/bin/bash
################################################################################
# Script de Restauração Remota do Coolify
# Permite restaurar backup do Coolify em um novo servidor remotamente
# Uso: ./restaurar-coolify-remoto.sh
# Versão: 2.0 - Refatorado com bibliotecas compartilhadas
################################################################################

set -e

# Carregar bibliotecas compartilhadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

init_script

echo "╔════════════════════════════════════════════════════════════╗"
echo "║      RESTAURAÇÃO REMOTA DO COOLIFY - TOTALMENTE AUTOMATIZADA ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log_info "Este script restaurará um backup do Coolify em um servidor remoto"
log_info "A partir da máquina antiga, de forma totalmente remota"
echo ""

################################################################################
# CONFIGURAÇÃO DO SERVIDOR REMOTO
################################################################################

log_info "========== CONFIGURAÇÃO DO SERVIDOR REMOTO =========="
echo ""

read -p "IP do novo servidor: " NEW_SERVER_IP
read -p "Usuário SSH (padrão: root): " NEW_SERVER_USER
NEW_SERVER_USER=${NEW_SERVER_USER:-root}
read -p "Porta SSH (padrão: 22): " NEW_SERVER_PORT
NEW_SERVER_PORT=${NEW_SERVER_PORT:-22}

# Testar conexão SSH
log_info "Testando conexão SSH..."
if ! ssh -p "$NEW_SERVER_PORT" -o ConnectTimeout=10 "$NEW_SERVER_USER@$NEW_SERVER_IP" "exit" 2>/dev/null; then
    log_error "Falha na conexão SSH com $NEW_SERVER_IP"
    log_info "Verifique:"
    log_info "  - O IP está correto"
    log_info "  - A porta SSH está aberta"
    log_info "  - Você tem acesso SSH ao servidor"
    exit 1
fi
log_success "Conexão SSH estabelecida!"
echo ""

################################################################################
# SELEÇÃO DO BACKUP
################################################################################

log_section "Seleção do Backup"

BACKUP_DIR="${COOLIFY_BACKUP_DIR:-/var/backups/vpsguardian/coolify}"

# Verificar se diretório de backups existe
if [ ! -d "$BACKUP_DIR" ]; then
    log_error "Diretório de backups não encontrado: $BACKUP_DIR"
    exit 1
fi

# Listar backups disponíveis
BACKUPS=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    log_error "Nenhum backup encontrado em $BACKUP_DIR"
    exit 1
fi

log_info "Backups disponíveis:"
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

read -p "Selecione o número do backup: " BACKUP_INDEX

if [ -z "$BACKUP_INDEX" ] || [ "$BACKUP_INDEX" -ge "${#BACKUPS[@]}" ]; then
    log_error "Seleção de backup inválida"
    exit 1
fi

SELECTED_BACKUP="${BACKUPS[$BACKUP_INDEX]}"
BACKUP_FILENAME=$(basename "$SELECTED_BACKUP")

log_info "Backup selecionado: $BACKUP_FILENAME"
echo ""

################################################################################
# CONFIRMAÇÃO
################################################################################

log_info "========== CONFIRMAÇÃO =========="
echo ""
echo "  Servidor destino: $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_PORT"
echo "  Backup: $BACKUP_FILENAME"
echo ""
log_warning "Esta operação irá:"
log_warning "  1. Instalar o Coolify no novo servidor (se não estiver instalado)"
log_warning "  2. Transferir o backup para o novo servidor"
log_warning "  3. Restaurar banco de dados, SSH keys e configurações"
log_warning "  4. Reiniciar o Coolify"
echo ""

read -p "Continuar? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    log_info "Operação cancelada pelo usuário"
    exit 0
fi

echo ""

################################################################################
# VERIFICAR SE COOLIFY ESTÁ INSTALADO NO SERVIDOR REMOTO
################################################################################

log_info "========== VERIFICANDO COOLIFY NO SERVIDOR REMOTO =========="
echo ""

log_info "Verificando se Coolify está instalado..."
if ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" "docker ps --filter name=coolify -q" 2>/dev/null | grep -q .; then
    log_success "Coolify encontrado no servidor remoto"

    log_warning "O Coolify já está instalado e rodando"
    read -p "Deseja continuar e sobrescrever? (yes/no): " OVERWRITE
    if [ "$OVERWRITE" != "yes" ]; then
        log_info "Operação cancelada pelo usuário"
        exit 0
    fi
else
    log_info "Coolify não encontrado. Instalando..."

    # Instalar Coolify no servidor remoto
    log_info "Executando instalação do Coolify..."
    ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash" || {
        log_error "Falha na instalação do Coolify"
        exit 1
    }

    log_success "Coolify instalado com sucesso"

    # Aguardar Coolify iniciar
    log_info "Aguardando Coolify iniciar (30 segundos)..."
    sleep 30
fi

echo ""

################################################################################
# TRANSFERIR BACKUP PARA SERVIDOR REMOTO
################################################################################

log_info "========== TRANSFERINDO BACKUP =========="
echo ""

REMOTE_BACKUP_DIR="/root/coolify-restore-$(date +%s)"

log_info "Criando diretório temporário no servidor remoto..."
ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" "mkdir -p $REMOTE_BACKUP_DIR"

log_info "Transferindo backup (isso pode levar alguns minutos)..."
if scp -P "$NEW_SERVER_PORT" "$SELECTED_BACKUP" "$NEW_SERVER_USER@$NEW_SERVER_IP:$REMOTE_BACKUP_DIR/"; then
    log_success "Backup transferido com sucesso"
else
    log_error "Falha na transferência do backup"
    exit 1
fi

echo ""

################################################################################
# EXTRAIR BACKUP NO SERVIDOR REMOTO
################################################################################

log_info "========== EXTRAINDO BACKUP =========="
echo ""

log_info "Extraindo backup no servidor remoto..."
ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "cd $REMOTE_BACKUP_DIR && tar -xzf $BACKUP_FILENAME" || {
    log_error "Falha ao extrair backup"
    exit 1
}

log_success "Backup extraído com sucesso"
echo ""

################################################################################
# PARAR COOLIFY TEMPORARIAMENTE
################################################################################

log_info "========== PARANDO COOLIFY TEMPORARIAMENTE =========="
echo ""

log_info "Parando containers do Coolify..."
ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "docker stop \$(docker ps --filter name=coolify -q)" 2>/dev/null || true

log_success "Coolify parado"
echo ""

################################################################################
# RESTAURAR BANCO DE DADOS
################################################################################

log_info "========== RESTAURANDO BANCO DE DADOS =========="
echo ""

log_info "Restaurando banco de dados PostgreSQL..."

# Encontrar arquivo de dump
DB_DUMP=$(ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "find $REMOTE_BACKUP_DIR -name 'coolify-db-*.dmp' | head -1")

if [ -z "$DB_DUMP" ]; then
    log_error "Arquivo de dump do banco de dados não encontrado"
    exit 1
fi

log_info "Arquivo de dump encontrado: $(basename $DB_DUMP)"

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

log_success "Banco de dados restaurado"
echo ""

################################################################################
# RESTAURAR SSH KEYS
################################################################################

log_info "========== RESTAURANDO SSH KEYS =========="
echo ""

log_info "Restaurando chaves SSH..."

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

log_success "SSH keys restauradas"
echo ""

################################################################################
# RESTAURAR .ENV
################################################################################

log_info "========== RESTAURANDO CONFIGURAÇÕES =========="
echo ""

log_info "Restaurando arquivo .env..."

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

log_success "Configurações restauradas"
echo ""

################################################################################
# RESTAURAR AUTHORIZED_KEYS (OPCIONAL)
################################################################################

log_info "========== RESTAURANDO AUTHORIZED_KEYS =========="
echo ""

read -p "Restaurar authorized_keys do backup? (y/N): " RESTORE_AUTH_KEYS
if [ "$RESTORE_AUTH_KEYS" = "y" ]; then
    log_info "Restaurando authorized_keys..."

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

    log_success "authorized_keys restaurado"
else
    log_info "authorized_keys não restaurado (mantendo o existente)"
fi

echo ""

################################################################################
# REINICIAR COOLIFY
################################################################################

log_info "========== REINICIANDO COOLIFY =========="
echo ""

log_info "Iniciando todos os containers do Coolify..."
ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "cd /data/coolify/source && docker compose up -d" || {
    log_error "Falha ao reiniciar Coolify"
    exit 1
}

log_success "Coolify reiniciado"

# Aguardar Coolify iniciar completamente
log_info "Aguardando Coolify iniciar (30 segundos)..."
sleep 30

echo ""

################################################################################
# VERIFICAÇÃO FINAL
################################################################################

log_info "========== VERIFICAÇÃO FINAL =========="
echo ""

log_info "Verificando status dos containers..."
CONTAINERS_RUNNING=$(ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "docker ps --filter name=coolify --format '{{.Names}}'" | wc -l)

log_success "Containers rodando: $CONTAINERS_RUNNING"

if [ "$CONTAINERS_RUNNING" -ge 3 ]; then
    log_success "Coolify está rodando corretamente!"
else
    log_warning "Menos containers que o esperado. Verifique os logs."
fi

echo ""

################################################################################
# LIMPEZA
################################################################################

log_info "========== LIMPEZA =========="
echo ""

read -p "Remover arquivos temporários do servidor remoto? (Y/n): " CLEANUP
if [ "$CLEANUP" != "n" ]; then
    log_info "Removendo arquivos temporários..."
    ssh -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" "rm -rf $REMOTE_BACKUP_DIR"
    log_success "Arquivos temporários removidos"
else
    log_info "Arquivos temporários mantidos em: $REMOTE_BACKUP_DIR"
fi

echo ""

################################################################################
# RESUMO FINAL
################################################################################

log_success "========== RESTAURAÇÃO CONCLUÍDA COM SUCESSO! =========="
echo ""
echo "  🎉 Coolify restaurado no servidor: $NEW_SERVER_IP"
echo "  🌐 Acesse: http://$NEW_SERVER_IP:8000"
echo ""
log_info "Próximos passos:"
log_info "  1. Acesse o Coolify e faça login"
log_info "  2. Verifique se todas as aplicações estão listadas"
log_info "  3. Atualize DNS para apontar para o novo IP: $NEW_SERVER_IP"
log_info "  4. Teste todas as aplicações"
log_info "  5. Mantenha o servidor antigo online por 24-48h"
echo ""
log_success "Restauração remota finalizada! 🚀"
