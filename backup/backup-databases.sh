#!/bin/bash
################################################################################
# Script de Backup Automático de Bancos de Dados
# Detecta e faz backup de todos os bancos PostgreSQL e MySQL
# Uso: ./backup-databases.sh
################################################################################

set -e

LOG_PREFIX="[ DB Backup ]"
BACKUP_DIR="/root/database-backups"
RETENTION_DAYS=30

# Configurações opcionais de notificação
EMAIL=""
WEBHOOK_URL=""

log() {
    echo "$LOG_PREFIX [ $1 ] $2"
}

log_error() {
    echo "$LOG_PREFIX [ ERRO ] $1"
}

log_success() {
    echo "$LOG_PREFIX [ OK ] $1"
}

notify() {
    local message="$1"

    # Email
    if [ -n "$EMAIL" ]; then
        echo "$message" | mail -s "Database Backup - $(hostname)" "$EMAIL" 2>/dev/null || true
    fi

    # Webhook (Discord/Slack)
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$message\"}" 2>/dev/null || true
    fi
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         BACKUP AUTOMÁTICO DE BANCOS DE DADOS               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Verificar se Docker está rodando
if ! docker ps >/dev/null 2>&1; then
    log_error "Docker não está rodando"
    notify "❌ Backup de bancos FALHOU: Docker não está rodando"
    exit 1
fi

# Criar diretório de backup
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_DIR="$BACKUP_DIR/backup-$TIMESTAMP"
mkdir -p "$SESSION_DIR"

log "INFO" "Diretório de backup: $SESSION_DIR"
echo ""

# Contadores
TOTAL_DBS=0
SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL_SIZE=0

# Arrays para armazenar informações
declare -a BACKUP_FILES
declare -a BACKUP_SIZES

# ========== DETECTAR E FAZER BACKUP DE POSTGRESQL ==========
log "INFO" "========== DETECTANDO POSTGRESQL =========="
echo ""

POSTGRES_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -E 'postgres|pg|db' | grep -v 'mysql\|mariadb' || true)

if [ -z "$POSTGRES_CONTAINERS" ]; then
    log "INFO" "Nenhum container PostgreSQL detectado"
else
    while IFS= read -r CONTAINER; do
        # Tentar detectar se é realmente PostgreSQL
        if docker exec "$CONTAINER" psql --version >/dev/null 2>&1; then
            log "INFO" "Detectado PostgreSQL: $CONTAINER"

            # Obter informações do container
            POSTGRES_USER=$(docker exec "$CONTAINER" printenv POSTGRES_USER 2>/dev/null || echo "postgres")
            POSTGRES_DB=$(docker exec "$CONTAINER" printenv POSTGRES_DB 2>/dev/null || echo "$POSTGRES_USER")

            # Verificar se consegue listar databases
            DBS=$(docker exec "$CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres');" 2>/dev/null || echo "$POSTGRES_DB")

            # Fazer backup de cada database
            for DB in $DBS; do
                DB=$(echo "$DB" | xargs) # Trim whitespace
                if [ -z "$DB" ]; then
                    continue
                fi

                ((TOTAL_DBS++))

                BACKUP_FILE="$SESSION_DIR/${CONTAINER}_${DB}_pg_${TIMESTAMP}.sql"

                log "INFO" "Fazendo backup: $CONTAINER/$DB"

                if docker exec "$CONTAINER" pg_dump -U "$POSTGRES_USER" -d "$DB" --clean --if-exists > "$BACKUP_FILE" 2>/dev/null; then
                    # Comprimir backup
                    gzip "$BACKUP_FILE"
                    BACKUP_FILE="${BACKUP_FILE}.gz"

                    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
                    SIZE_BYTES=$(du -b "$BACKUP_FILE" | cut -f1)
                    TOTAL_SIZE=$((TOTAL_SIZE + SIZE_BYTES))

                    log_success "$CONTAINER/$DB → $SIZE"

                    BACKUP_FILES+=("$BACKUP_FILE")
                    BACKUP_SIZES+=("$SIZE")
                    ((SUCCESS_COUNT++))
                else
                    log_error "Falha ao fazer backup de $CONTAINER/$DB"
                    rm -f "$BACKUP_FILE" "$BACKUP_FILE.gz"
                    ((FAIL_COUNT++))
                fi
            done
        fi
    done <<< "$POSTGRES_CONTAINERS"
fi

echo ""

# ========== DETECTAR E FAZER BACKUP DE MYSQL/MARIADB ==========
log "INFO" "========== DETECTANDO MYSQL/MARIADB =========="
echo ""

MYSQL_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -E 'mysql|mariadb' || true)

if [ -z "$MYSQL_CONTAINERS" ]; then
    log "INFO" "Nenhum container MySQL/MariaDB detectado"
else
    while IFS= read -r CONTAINER; do
        # Tentar detectar se é realmente MySQL/MariaDB
        if docker exec "$CONTAINER" mysql --version >/dev/null 2>&1; then
            log "INFO" "Detectado MySQL/MariaDB: $CONTAINER"

            # Obter informações do container
            MYSQL_ROOT_PASSWORD=$(docker exec "$CONTAINER" printenv MYSQL_ROOT_PASSWORD 2>/dev/null || echo "")
            MYSQL_USER=$(docker exec "$CONTAINER" printenv MYSQL_USER 2>/dev/null || echo "root")
            MYSQL_PASSWORD=$(docker exec "$CONTAINER" printenv MYSQL_PASSWORD 2>/dev/null || echo "$MYSQL_ROOT_PASSWORD")

            if [ -z "$MYSQL_PASSWORD" ]; then
                log_error "Não foi possível obter senha do MySQL para $CONTAINER"
                ((FAIL_COUNT++))
                continue
            fi

            # Listar databases
            DBS=$(docker exec "$CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "Database|information_schema|performance_schema|mysql|sys" || true)

            if [ -z "$DBS" ]; then
                # Tentar obter database padrão
                MYSQL_DATABASE=$(docker exec "$CONTAINER" printenv MYSQL_DATABASE 2>/dev/null || echo "")
                if [ -n "$MYSQL_DATABASE" ]; then
                    DBS="$MYSQL_DATABASE"
                fi
            fi

            # Fazer backup de cada database
            for DB in $DBS; do
                DB=$(echo "$DB" | xargs) # Trim whitespace
                if [ -z "$DB" ]; then
                    continue
                fi

                ((TOTAL_DBS++))

                BACKUP_FILE="$SESSION_DIR/${CONTAINER}_${DB}_mysql_${TIMESTAMP}.sql"

                log "INFO" "Fazendo backup: $CONTAINER/$DB"

                if docker exec "$CONTAINER" mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --single-transaction --quick --lock-tables=false "$DB" > "$BACKUP_FILE" 2>/dev/null; then
                    # Comprimir backup
                    gzip "$BACKUP_FILE"
                    BACKUP_FILE="${BACKUP_FILE}.gz"

                    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
                    SIZE_BYTES=$(du -b "$BACKUP_FILE" | cut -f1)
                    TOTAL_SIZE=$((TOTAL_SIZE + SIZE_BYTES))

                    log_success "$CONTAINER/$DB → $SIZE"

                    BACKUP_FILES+=("$BACKUP_FILE")
                    BACKUP_SIZES+=("$SIZE")
                    ((SUCCESS_COUNT++))
                else
                    log_error "Falha ao fazer backup de $CONTAINER/$DB"
                    rm -f "$BACKUP_FILE" "$BACKUP_FILE.gz"
                    ((FAIL_COUNT++))
                fi
            done
        fi
    done <<< "$MYSQL_CONTAINERS"
fi

echo ""

# ========== CRIAR ARQUIVO DE INFORMAÇÕES ==========
INFO_FILE="$SESSION_DIR/backup-info.txt"
cat > "$INFO_FILE" << EOF
╔════════════════════════════════════════════════════════════╗
║         INFORMAÇÕES DO BACKUP DE BANCOS DE DADOS           ║
╚════════════════════════════════════════════════════════════╝

Data/Hora: $(date '+%Y-%m-%d %H:%M:%S')
Servidor: $(hostname)
Diretório: $SESSION_DIR

========== RESUMO ==========
Total de bancos: $TOTAL_DBS
Backups com sucesso: $SUCCESS_COUNT
Backups com falha: $FAIL_COUNT
Tamanho total: $(numfmt --to=iec-i --suffix=B $TOTAL_SIZE 2>/dev/null || echo "${TOTAL_SIZE} bytes")

========== ARQUIVOS CRIADOS ==========
EOF

for i in "${!BACKUP_FILES[@]}"; do
    echo "$(basename "${BACKUP_FILES[$i]}") - ${BACKUP_SIZES[$i]}" >> "$INFO_FILE"
done

cat >> "$INFO_FILE" << EOF

========== COMO RESTAURAR ==========

### PostgreSQL:
gunzip backup_file.sql.gz
docker exec -i CONTAINER_NAME psql -U USERNAME -d DATABASE_NAME < backup_file.sql

### MySQL/MariaDB:
gunzip backup_file.sql.gz
docker exec -i CONTAINER_NAME mysql -uUSERNAME -pPASSWORD DATABASE_NAME < backup_file.sql

========== OBSERVAÇÕES ==========
- Backups comprimidos com gzip
- Retenção configurada para $RETENTION_DAYS dias
- Backups antigos são removidos automaticamente

Para restauração remota, transfira o arquivo .sql.gz para o servidor
de destino e execute os comandos acima.
EOF

# ========== CRIAR TARBALL CONSOLIDADO ==========
log "INFO" "Criando arquivo consolidado..."
TARBALL="$BACKUP_DIR/databases-backup-$TIMESTAMP.tar.gz"

cd "$BACKUP_DIR"
tar -czf "$TARBALL" "backup-$TIMESTAMP/" 2>/dev/null

TARBALL_SIZE=$(du -h "$TARBALL" | cut -f1)
log_success "Tarball criado: databases-backup-$TIMESTAMP.tar.gz ($TARBALL_SIZE)"

# Remover diretório de sessão (mantém apenas tarball)
rm -rf "$SESSION_DIR"

echo ""

# ========== LIMPEZA DE BACKUPS ANTIGOS ==========
log "INFO" "Removendo backups com mais de $RETENTION_DAYS dias..."

DELETED_COUNT=0
while IFS= read -r OLD_BACKUP; do
    rm -f "$OLD_BACKUP"
    ((DELETED_COUNT++))
done < <(find "$BACKUP_DIR" -name "databases-backup-*.tar.gz" -type f -mtime +$RETENTION_DAYS 2>/dev/null)

if [ $DELETED_COUNT -gt 0 ]; then
    log_success "$DELETED_COUNT backup(s) antigo(s) removido(s)"
else
    log "INFO" "Nenhum backup antigo para remover"
fi

echo ""

# ========== RESUMO FINAL ==========
log "SUCCESS" "========== BACKUP CONCLUÍDO =========="
echo ""
echo "  📊 Estatísticas:"
echo "     • Bancos processados: $TOTAL_DBS"
echo "     • Sucesso: $SUCCESS_COUNT"
echo "     • Falhas: $FAIL_COUNT"
echo "     • Tamanho total: $TARBALL_SIZE"
echo ""
echo "  📁 Arquivo criado:"
echo "     $TARBALL"
echo ""
echo "  📋 Informações detalhadas:"
echo "     Extraia o tarball para ver backup-info.txt"
echo ""
echo "  🗑️  Limpeza:"
echo "     Backups antigos removidos: $DELETED_COUNT"
echo ""

# ========== NOTIFICAÇÃO ==========
if [ $FAIL_COUNT -eq 0 ]; then
    MESSAGE="✅ Backup de bancos concluído com sucesso!
Servidor: $(hostname)
Bancos: $SUCCESS_COUNT/$TOTAL_DBS
Tamanho: $TARBALL_SIZE
Arquivo: databases-backup-$TIMESTAMP.tar.gz"
    notify "$MESSAGE"
else
    MESSAGE="⚠️ Backup de bancos concluído com falhas!
Servidor: $(hostname)
Sucesso: $SUCCESS_COUNT
Falhas: $FAIL_COUNT
Tamanho: $TARBALL_SIZE
Arquivo: databases-backup-$TIMESTAMP.tar.gz"
    notify "$MESSAGE"
fi

# ========== PRÓXIMOS PASSOS ==========
echo "  💡 Próximos passos:"
echo ""
echo "  1. Enviar para destino remoto:"
echo "     sudo /opt/manutencao/backup-destinos.sh $TARBALL"
echo ""
echo "  2. Ver informações do backup:"
echo "     tar -xzf $TARBALL"
echo "     cat backup-$TIMESTAMP/backup-info.txt"
echo ""
echo "  3. Restaurar um banco específico:"
echo "     tar -xzf $TARBALL"
echo "     gunzip backup-$TIMESTAMP/CONTAINER_DB_*.sql.gz"
echo "     docker exec -i CONTAINER psql -U USER -d DB < backup-$TIMESTAMP/CONTAINER_DB_*.sql"
echo ""

exit 0
