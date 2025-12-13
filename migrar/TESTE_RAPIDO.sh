#!/bin/bash
################################################################################
# TESTE RÁPIDO - Validar Correções
# Execute este script para validar rapidamente se tudo está OK
################################################################################

echo "======================================================================"
echo "  TESTE RÁPIDO - Validação de Correções do migrar-coolify.sh"
echo "======================================================================"
echo ""

cd "$(dirname "$0")"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

# Test 1: Verificar ordem de operações
echo -e "${YELLOW}[1/3]${NC} Verificando ordem de operações..."
FIND_LINE=$(grep -n 'find.*TEMP_EXTRACT.*\.env' migrar-coolify.sh | head -1 | cut -d: -f1)
EXTRACT_LINE=$(grep -n 'BACKUP_APP_KEY.*grep' migrar-coolify.sh | head -1 | cut -d: -f1)
REMOVE_LINE=$(grep -n 'rm -rf.*TEMP_EXTRACT_DIR' migrar-coolify.sh | head -1 | cut -d: -f1)

if [ "$EXTRACT_LINE" -lt "$REMOVE_LINE" ]; then
    echo -e "   ${GREEN}✓${NC} Extração (linha $EXTRACT_LINE) acontece ANTES da remoção (linha $REMOVE_LINE)"
    ((PASSED++))
else
    echo -e "   ${RED}✗${NC} ERRO: Extração acontece DEPOIS da remoção!"
    ((FAILED++))
fi

# Test 2: Verificar busca inteligente
echo -e "${YELLOW}[2/3]${NC} Verificando busca inteligente..."
if grep -q 'find.*TEMP_EXTRACT_DIR.*\.env' migrar-coolify.sh; then
    echo -e "   ${GREEN}✓${NC} Busca inteligente com find implementada"
    ((PASSED++))
else
    echo -e "   ${RED}✗${NC} Busca inteligente NÃO encontrada"
    ((FAILED++))
fi

# Test 3: Verificar se tem backup
echo -e "${YELLOW}[3/3]${NC} Verificando backup do script original..."
if ls migrar-coolify.sh.backup-* >/dev/null 2>&1; then
    BACKUP=$(ls -1t migrar-coolify.sh.backup-* | head -1)
    echo -e "   ${GREEN}✓${NC} Backup encontrado: $(basename $BACKUP)"
    ((PASSED++))
else
    echo -e "   ${YELLOW}!${NC} Backup não encontrado (não crítico)"
fi

echo ""
echo "======================================================================"
echo "  RESULTADO"
echo "======================================================================"
echo ""
echo "Testes Passados: $PASSED"
echo "Testes Falhos: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ SUCESSO!${NC} Script está corrigido e pronto para uso"
    echo ""
    echo "Próximo passo:"
    echo "  Testar extração de APP_KEY com um backup real:"
    echo ""
    echo "  BACKUP=\$(ls -t /var/backups/vpsguardian/coolify/*.tar.gz | head -1)"
    echo "  ./test-app-key-logic.sh \"\$BACKUP\""
    echo ""
    exit 0
else
    echo -e "${RED}❌ FALHOU!${NC} Há $FAILED problema(s) crítico(s)"
    echo ""
    echo "Revise os erros acima antes de usar o script."
    echo ""
    exit 1
fi
