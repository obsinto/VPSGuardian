#!/bin/bash
################################################################################
# Validador de Script - migrar-coolify.sh
# Propósito: Verificar se as correções foram aplicadas corretamente
# Uso: ./validar-script.sh
################################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_section() { echo -e "\n${YELLOW}=== $1 ===${NC}\n"; }

SCRIPT_PATH="./migrar-coolify.sh"
ERRORS=0
WARNINGS=0

log_section "VALIDADOR DE CORREÇÕES - migrar-coolify.sh"

################################################################################
# CHECK 1: Arquivo Existe
################################################################################
echo "1. Verificando existência do script..."
if [ ! -f "$SCRIPT_PATH" ]; then
    log_error "Script não encontrado: $SCRIPT_PATH"
    exit 1
fi
log_success "Script encontrado"

################################################################################
# CHECK 2: Busca Inteligente de .env Implementada
################################################################################
echo "2. Verificando busca inteligente de .env..."
if grep -q 'find "$TEMP_EXTRACT_DIR" -name ".env"' "$SCRIPT_PATH"; then
    log_success "Busca inteligente com find implementada"
else
    log_error "Busca inteligente NÃO encontrada"
    ((ERRORS++))
fi

################################################################################
# CHECK 3: Extração Antes de Limpar
################################################################################
echo "3. Verificando ordem de extração de chaves..."

# Procurar linha de extração
EXTRACTION_LINE=$(grep -n "BACKUP_APP_KEY.*grep.*APP_KEY" "$SCRIPT_PATH" | head -1 | cut -d: -f1)

# Procurar linha de remoção
REMOVAL_LINE=$(grep -n 'rm -rf "$TEMP_EXTRACT_DIR"' "$SCRIPT_PATH" | head -1 | cut -d: -f1)

if [ -n "$EXTRACTION_LINE" ] && [ -n "$REMOVAL_LINE" ]; then
    if [ "$EXTRACTION_LINE" -lt "$REMOVAL_LINE" ]; then
        log_success "Extração acontece ANTES da remoção (linha $EXTRACTION_LINE < $REMOVAL_LINE)"
    else
        log_error "Extração acontece DEPOIS da remoção (BUG!)"
        ((ERRORS++))
    fi
else
    log_warning "Não foi possível determinar ordem das operações"
    ((WARNINGS++))
fi

################################################################################
# CHECK 4: Captura de APP_PREVIOUS_KEYS
################################################################################
echo "4. Verificando captura de APP_PREVIOUS_KEYS..."
if grep -q 'BACKUP_PREV_KEYS.*APP_PREVIOUS_KEYS' "$SCRIPT_PATH"; then
    log_success "Captura de APP_PREVIOUS_KEYS implementada"
else
    log_warning "APP_PREVIOUS_KEYS pode não estar sendo capturado"
    ((WARNINGS++))
fi

################################################################################
# CHECK 5: Fallback para Sistema Local
################################################################################
echo "5. Verificando fallback para sistema local..."
if grep -q 'APP_KEY_LOCAL' "$SCRIPT_PATH" && grep -q 'ENV_FILE.*APP_KEY' "$SCRIPT_PATH"; then
    log_success "Fallback para sistema local implementado"
else
    log_warning "Fallback pode não estar completo"
    ((WARNINGS++))
fi

################################################################################
# CHECK 6: Remoção de Código Duplicado
################################################################################
echo "6. Verificando código duplicado..."

# Contar quantas vezes tenta extrair BACKUP_APP_KEY
COUNT=$(grep -c 'BACKUP_APP_KEY=""' "$SCRIPT_PATH" || echo "0")

if [ "$COUNT" -le 1 ]; then
    log_success "Sem código duplicado detectado"
else
    log_warning "Possível código duplicado: $COUNT inicializações de BACKUP_APP_KEY"
    ((WARNINGS++))
fi

################################################################################
# CHECK 7: Mensagens de Debug
################################################################################
echo "7. Verificando mensagens de debug..."
if grep -q '📊 Estado das chaves' "$SCRIPT_PATH"; then
    log_success "Mensagens de debug implementadas"
else
    log_info "Mensagens de debug não encontradas (opcional)"
fi

################################################################################
# CHECK 8: Validação Final de APP_KEY
################################################################################
echo "8. Verificando validação de APP_KEY..."
if grep -q 'ERRO CRÍTICO.*APP_KEY' "$SCRIPT_PATH"; then
    log_success "Validação crítica de APP_KEY presente"
else
    log_warning "Validação crítica pode estar ausente"
    ((WARNINGS++))
fi

################################################################################
# CHECK 9: Backup do Script Original Existe
################################################################################
echo "9. Verificando backup do script original..."
BACKUP_COUNT=$(ls -1 migrar-coolify.sh.backup-* 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 0 ]; then
    log_success "Backup encontrado: $(ls -1t migrar-coolify.sh.backup-* 2>/dev/null | head -1 | xargs basename)"
else
    log_warning "Nenhum backup do script original encontrado"
    ((WARNINGS++))
fi

################################################################################
# CHECK 10: Script de Teste Existe
################################################################################
echo "10. Verificando script de teste..."
if [ -f "test-app-key-logic.sh" ]; then
    log_success "Script de teste encontrado"
    if [ -x "test-app-key-logic.sh" ]; then
        log_success "Script de teste é executável"
    else
        log_warning "Script de teste não é executável (execute: chmod +x test-app-key-logic.sh)"
        ((WARNINGS++))
    fi
else
    log_error "Script de teste NÃO encontrado"
    ((ERRORS++))
fi

################################################################################
# RESUMO
################################################################################
log_section "RESUMO DA VALIDAÇÃO"

echo "Erros Críticos: $ERRORS"
echo "Avisos: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    log_success "✅ TODAS AS VERIFICAÇÕES PASSARAM!"
    echo ""
    echo "✅ Script está correto e pronto para teste"
    echo ""
    echo "Próximos passos:"
    echo "  1. Teste a extração de APP_KEY:"
    echo "     ./test-app-key-logic.sh /path/to/backup.tar.gz"
    echo ""
    echo "  2. Execute migração em servidor de TESTE:"
    echo "     ./migrar-coolify.sh"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    log_warning "⚠️  VALIDAÇÃO COM AVISOS"
    echo ""
    echo "O script provavelmente está correto, mas há $WARNINGS aviso(s)."
    echo "Revise os avisos acima antes de prosseguir."
    echo ""
    exit 0
else
    log_error "❌ VALIDAÇÃO FALHOU"
    echo ""
    echo "Foram encontrados $ERRORS erro(s) crítico(s)."
    echo "Revise e corrija os erros antes de usar o script."
    echo ""
    exit 1
fi
