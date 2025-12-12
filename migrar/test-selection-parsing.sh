#!/bin/bash
################################################################################
# Script: test-selection-parsing.sh
# Propósito: Testar a função normalize_selection
################################################################################

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função normalize_selection (copiada do migrar-volumes.sh)
normalize_selection() {
    local input="$1"
    local result=""

    # Substituir vírgulas por espaços
    input="${input//,/ }"

    # Processar cada token
    for token in $input; do
        # Verificar se é um intervalo (ex: 0-5)
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"

            # Adicionar todos os números do intervalo
            for ((i=start; i<=end; i++)); do
                result="$result $i"
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            # Número simples
            result="$result $token"
        fi
    done

    # Remover espaços duplicados e trim
    echo "$result" | xargs
}

test_case() {
    local input="$1"
    local expected="$2"
    local result=$(normalize_selection "$input")

    if [ "$result" = "$expected" ]; then
        echo -e "${GREEN}✓${NC} Input: '$input' → Output: '$result'"
        return 0
    else
        echo -e "${RED}✗${NC} Input: '$input'"
        echo -e "   Expected: '$expected'"
        echo -e "   Got:      '$result'"
        return 1
    fi
}

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TESTANDO PARSING DE SELEÇÃO${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

passed=0
failed=0

# Testes com espaços
if test_case "0 1 2 3" "0 1 2 3"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi
if test_case "0 2 4 6" "0 2 4 6"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi

# Testes com vírgulas
if test_case "0,1,2,3" "0 1 2 3"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi
if test_case "0,2,4,6" "0 2 4 6"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi

# Testes com intervalos
if test_case "0-3" "0 1 2 3"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi
if test_case "5-8" "5 6 7 8"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi
if test_case "0-2" "0 1 2"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi

# Testes mistos
if test_case "0-3,5,7-9" "0 1 2 3 5 7 8 9"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi
if test_case "0,2-4,6" "0 2 3 4 6"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi
if test_case "0-2 5 8-10" "0 1 2 5 8 9 10"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi

# Testes com espaços e vírgulas mistos
if test_case "0,1,2, 3, 4" "0 1 2 3 4"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi
if test_case "0-2, 5-7, 10" "0 1 2 5 6 7 10"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi

# Caso original do usuário
if test_case "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21" "0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21"; then passed=$((passed + 1)); else failed=$((failed + 1)); fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  RESUMO${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}✓ Passed:${NC} $passed"
if [ $failed -gt 0 ]; then
    echo -e "  ${RED}✗ Failed:${NC} $failed"
fi
echo ""

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}🎉 Todos os testes passaram!${NC}"
    exit 0
else
    echo -e "${RED}❌ Alguns testes falharam.${NC}"
    exit 1
fi
