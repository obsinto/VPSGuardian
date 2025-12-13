#!/bin/bash
################################################################################
# Script de Teste: Lógica de APP_KEY
# Propósito: Validar extração de APP_KEY de backups antes de aplicar no script principal
# Uso: ./test-app-key-logic.sh /path/to/backup.tar.gz
################################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERRO]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_section() { echo -e "\n${YELLOW}=== $1 ===${NC}\n"; }

################################################################################
# CONFIGURAÇÃO
################################################################################

BACKUP_FILE="${1:-}"
COOLIFY_DATA_DIR="/data/coolify"
ENV_FILE="$COOLIFY_DATA_DIR/source/.env"

if [ -z "$BACKUP_FILE" ]; then
    log_error "Uso: $0 /path/to/backup.tar.gz"
    echo ""
    echo "Este script testa a extração de APP_KEY de um backup do Coolify"
    echo "sem executar a migração completa."
    echo ""
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    log_error "Arquivo não encontrado: $BACKUP_FILE"
    exit 1
fi

log_section "TESTE DE EXTRAÇÃO DE APP_KEY"
log_info "Backup: $(basename $BACKUP_FILE)"
log_info "Tamanho: $(du -h "$BACKUP_FILE" | cut -f1)"
echo ""

################################################################################
# TESTE 1: Extração Temporária
################################################################################

log_section "TESTE 1: Extração do Backup"

TEMP_EXTRACT_DIR="/tmp/test-coolify-migration-$$"
mkdir -p "$TEMP_EXTRACT_DIR"

log_info "Extraindo backup para: $TEMP_EXTRACT_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEMP_EXTRACT_DIR" 2>/dev/null

if [ $? -eq 0 ]; then
    log_success "Backup extraído com sucesso"

    # Mostrar estrutura
    log_info "Estrutura do backup (primeiros 20 diretórios):"
    find "$TEMP_EXTRACT_DIR" -maxdepth 3 -type d 2>/dev/null | head -20 | while read dir; do
        echo "  📁 ${dir#$TEMP_EXTRACT_DIR/}"
    done
    echo ""
else
    log_error "Falha ao extrair backup"
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 1
fi

################################################################################
# TESTE 2: Método Atual (Script em Produção)
################################################################################

log_section "TESTE 2: Método Atual (Produção)"

APP_KEY_METHOD_CURRENT=""

# Simula o que o script atual faz (linha 1050)
if [ -f "$TEMP_EXTRACT_DIR/.env" ]; then
    APP_KEY_METHOD_CURRENT=$(grep "^APP_KEY=" "$TEMP_EXTRACT_DIR/.env" | cut -d '=' -f2-)
    log_success "Encontrado em: $TEMP_EXTRACT_DIR/.env"
else
    log_warning "NÃO encontrado em: $TEMP_EXTRACT_DIR/.env"

    # Fallback do script atual
    log_info "Tentando fallback: leitura direta do tar.gz..."
    APP_KEY_METHOD_CURRENT=$(tar -xzf "$BACKUP_FILE" -O ".env" 2>/dev/null | grep "^APP_KEY=" | cut -d '=' -f2-)

    if [ -n "$APP_KEY_METHOD_CURRENT" ]; then
        log_success "Fallback funcionou!"
    else
        log_error "Fallback FALHOU"
    fi
fi

if [ -n "$APP_KEY_METHOD_CURRENT" ]; then
    log_success "✅ Método Atual: APP_KEY encontrado"
    echo "   Primeiros 20 chars: ${APP_KEY_METHOD_CURRENT:0:20}..."
else
    log_error "❌ Método Atual: APP_KEY NÃO encontrado"
fi
echo ""

################################################################################
# TESTE 3: Método Proposto (Busca Inteligente)
################################################################################

log_section "TESTE 3: Método Proposto (Busca Inteligente)"

APP_KEY_METHOD_NEW=""
PREV_KEYS_METHOD_NEW=""

# Busca inteligente
log_info "Procurando .env com find..."
FOUND_ENV_FILE=$(find "$TEMP_EXTRACT_DIR" -name ".env" -type f | head -n 1)

if [ -n "$FOUND_ENV_FILE" ]; then
    log_success "Arquivo .env encontrado!"
    log_info "Localização: ${FOUND_ENV_FILE#$TEMP_EXTRACT_DIR/}"
    log_info "Tamanho: $(stat -c%s "$FOUND_ENV_FILE") bytes"
    echo ""

    # Extrair APP_KEY e APP_PREVIOUS_KEYS
    APP_KEY_METHOD_NEW=$(grep "^APP_KEY=" "$FOUND_ENV_FILE" | cut -d '=' -f2-)
    PREV_KEYS_METHOD_NEW=$(grep "^APP_PREVIOUS_KEYS=" "$FOUND_ENV_FILE" | cut -d '=' -f2-)

    if [ -n "$APP_KEY_METHOD_NEW" ]; then
        log_success "✅ APP_KEY encontrado!"
        echo "   Primeiros 20 chars: ${APP_KEY_METHOD_NEW:0:20}..."
    fi

    if [ -n "$PREV_KEYS_METHOD_NEW" ]; then
        log_success "✅ APP_PREVIOUS_KEYS encontrado!"
        # Contar quantas chaves
        KEY_COUNT=$(echo "$PREV_KEYS_METHOD_NEW" | tr ',' '\n' | wc -l)
        echo "   Número de chaves anteriores: $KEY_COUNT"
    else
        log_info "ℹ️  Nenhuma APP_PREVIOUS_KEYS (normal para primeira migração)"
    fi
else
    log_error "❌ Nenhum arquivo .env encontrado no backup"
fi
echo ""

################################################################################
# TESTE 4: Fallback para Sistema Local
################################################################################

log_section "TESTE 4: Fallback para Sistema Local"

APP_KEY_LOCAL=""
PREV_KEYS_LOCAL=""

if [ -f "$ENV_FILE" ]; then
    log_info "Verificando .env local: $ENV_FILE"
    APP_KEY_LOCAL=$(grep "^APP_KEY=" "$ENV_FILE" | cut -d '=' -f2-)
    PREV_KEYS_LOCAL=$(grep "^APP_PREVIOUS_KEYS=" "$ENV_FILE" | cut -d '=' -f2-)

    if [ -n "$APP_KEY_LOCAL" ]; then
        log_success "✅ APP_KEY local encontrado (fallback disponível)"
        echo "   Primeiros 20 chars: ${APP_KEY_LOCAL:0:20}..."
    fi

    if [ -n "$PREV_KEYS_LOCAL" ]; then
        log_info "APP_PREVIOUS_KEYS local também disponível"
    fi
else
    log_warning "⚠️  Arquivo .env local não encontrado: $ENV_FILE"
    log_info "Fallback não disponível"
fi
echo ""

################################################################################
# TESTE 5: Lógica de Rotação Completa
################################################################################

log_section "TESTE 5: Simulação da Rotação de Chaves"

# Decidir qual APP_KEY usar
FINAL_APP_KEY=""
FINAL_PREV_KEYS=""

if [ -n "$APP_KEY_METHOD_NEW" ]; then
    FINAL_APP_KEY="$APP_KEY_METHOD_NEW"
    FINAL_PREV_KEYS="$PREV_KEYS_METHOD_NEW"
    log_success "Usando APP_KEY do backup (método inteligente)"
elif [ -n "$APP_KEY_METHOD_CURRENT" ]; then
    FINAL_APP_KEY="$APP_KEY_METHOD_CURRENT"
    log_success "Usando APP_KEY do backup (método atual)"
elif [ -n "$APP_KEY_LOCAL" ]; then
    FINAL_APP_KEY="$APP_KEY_LOCAL"
    FINAL_PREV_KEYS="$PREV_KEYS_LOCAL"
    log_warning "⚠️  Usando APP_KEY local (fallback)"
else
    log_error "❌ CRÍTICO: Nenhuma APP_KEY disponível!"
    echo ""
    log_error "Sem APP_KEY, a migração FALHARÁ e dados serão perdidos!"
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 1
fi

# Construir string de rotação
KEYS_TO_MIGRATE="$FINAL_APP_KEY"

if [ -n "$FINAL_PREV_KEYS" ]; then
    KEYS_TO_MIGRATE="${KEYS_TO_MIGRATE},${FINAL_PREV_KEYS}"
    log_info "Histórico de chaves anteriores detectado"
fi

# Remover espaços
KEYS_TO_MIGRATE=$(echo "$KEYS_TO_MIGRATE" | tr -d ' ')

# Contar total de chaves
TOTAL_KEYS=$(echo "$KEYS_TO_MIGRATE" | tr ',' '\n' | wc -l)

log_success "✅ String de rotação preparada!"
echo ""
log_info "📊 Estatísticas:"
echo "   Total de chaves: $TOTAL_KEYS"
echo "   Tamanho da string: ${#KEYS_TO_MIGRATE} caracteres"
echo "   Preview: ${KEYS_TO_MIGRATE:0:50}..."
echo ""

################################################################################
# TESTE 6: Validação Final
################################################################################

log_section "TESTE 6: Validação Final"

# Simular o que seria escrito no .env remoto
SIMULATED_ENV="/tmp/simulated-env-$$"
cat > "$SIMULATED_ENV" << EOF
# Simulação do .env remoto após migração
APP_ID=coolify
APP_NAME=Coolify
APP_ENV=production
APP_DEBUG=false
APP_URL=http://localhost

# Chaves de criptografia (rotação)
APP_PREVIOUS_KEYS=$KEYS_TO_MIGRATE

# Outras configurações...
DB_HOST=coolify-db
DB_PORT=5432
EOF

log_info "Conteúdo que seria escrito no servidor remoto:"
echo ""
cat "$SIMULATED_ENV" | grep -A 2 "APP_PREVIOUS_KEYS"
echo ""

# Validar sintaxe
if grep -q "^APP_PREVIOUS_KEYS=" "$SIMULATED_ENV"; then
    log_success "✅ Sintaxe válida do .env"
else
    log_error "❌ Sintaxe inválida!"
fi

rm -f "$SIMULATED_ENV"

################################################################################
# LIMPEZA E RESUMO
################################################################################

log_section "RESUMO DOS TESTES"

echo "📋 Resultados:"
echo ""
echo "   [Método Atual - Produção]"
if [ -n "$APP_KEY_METHOD_CURRENT" ]; then
    echo "   ✅ APP_KEY: Encontrado"
else
    echo "   ❌ APP_KEY: NÃO encontrado"
fi
echo ""

echo "   [Método Proposto - Busca Inteligente]"
if [ -n "$APP_KEY_METHOD_NEW" ]; then
    echo "   ✅ APP_KEY: Encontrado"
    echo "   ✅ APP_PREVIOUS_KEYS: $([ -n "$PREV_KEYS_METHOD_NEW" ] && echo 'Encontrado' || echo 'Não encontrado')"
else
    echo "   ❌ APP_KEY: NÃO encontrado"
fi
echo ""

echo "   [Fallback Local]"
if [ -n "$APP_KEY_LOCAL" ]; then
    echo "   ✅ Disponível"
else
    echo "   ⚠️  Não disponível"
fi
echo ""

echo "   [Rotação de Chaves]"
echo "   ✅ Total de chaves preparadas: $TOTAL_KEYS"
echo ""

# Recomendação
if [ -n "$APP_KEY_METHOD_NEW" ]; then
    log_success "✅ RECOMENDAÇÃO: Usar Método Proposto (Busca Inteligente)"
    log_success "   É mais resiliente e funciona com diferentes estruturas de backup"
elif [ -n "$APP_KEY_METHOD_CURRENT" ]; then
    log_warning "⚠️  Método Atual funciona para ESTE backup"
    log_warning "   Mas pode falhar com outras estruturas"
else
    log_error "❌ AMBOS os métodos falharam!"
    log_error "   Apenas fallback local disponível"
fi

# Limpar
rm -rf "$TEMP_EXTRACT_DIR"
log_info "Diretório temporário removido"
echo ""

log_success "Teste concluído!"
echo ""
