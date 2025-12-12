#!/bin/bash
################################################################################
# Script: test-migration-scripts.sh
# Propósito: Testar scripts de migração de volumes sem executar migrações reais
# Uso: ./test-migration-scripts.sh
################################################################################

echo "======================================"
echo "  TESTE DE SCRIPTS DE MIGRAÇÃO"
echo "======================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

all_tests_passed=true

### ========== TESTE 1: Verificar Arquivos ==========
echo "[ TESTE 1 ] Verificando existência dos scripts..."
echo ""

required_scripts=(
    "backup-volumes.sh"
    "transfer-volumes.sh"
    "restore-volumes.sh"
    "migrar-volumes.sh"
)

for script in "${required_scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "  ✓ $script (executável)"
        else
            echo "  ⚠ $script (não executável, corrigindo...)"
            chmod +x "$script"
        fi
    else
        echo "  ✗ $script (NÃO ENCONTRADO)"
        all_tests_passed=false
    fi
done

echo ""

### ========== TESTE 2: Validar Sintaxe ==========
echo "[ TESTE 2 ] Validando sintaxe dos scripts..."
echo ""

for script in "${required_scripts[@]}"; do
    if [ -f "$script" ]; then
        if bash -n "$script" 2>/dev/null; then
            echo "  ✓ $script"
        else
            echo "  ✗ $script (erro de sintaxe)"
            bash -n "$script"
            all_tests_passed=false
        fi
    fi
done

echo ""

### ========== TESTE 3: Verificar Bibliotecas ==========
echo "[ TESTE 3 ] Verificando bibliotecas compartilhadas..."
echo ""

required_libs=(
    "../lib/common.sh"
    "../lib/colors.sh"
    "../lib/logging.sh"
    "../lib/validation.sh"
)

for lib in "${required_libs[@]}"; do
    if [ -f "$lib" ]; then
        if bash -n "$lib" 2>/dev/null; then
            echo "  ✓ $lib"
        else
            echo "  ✗ $lib (erro de sintaxe)"
            all_tests_passed=false
        fi
    else
        echo "  ✗ $lib (NÃO ENCONTRADO)"
        all_tests_passed=false
    fi
done

echo ""

### ========== TESTE 4: Verificar Help ==========
echo "[ TESTE 4 ] Testando opção --help..."
echo ""

help_scripts=(
    "backup-volumes.sh"
    "transfer-volumes.sh"
    "restore-volumes.sh"
)

for script in "${help_scripts[@]}"; do
    if [ -f "$script" ]; then
        if ./"$script" --help >/dev/null 2>&1; then
            echo "  ✓ $script --help"
        else
            echo "  ⚠ $script --help (sem suporte ou erro)"
        fi
    fi
done

echo ""

### ========== TESTE 5: Verificar Dependências do Sistema ==========
echo "[ TESTE 5 ] Verificando dependências do sistema..."
echo ""

required_commands=(
    "docker"
    "tar"
    "ssh"
    "scp"
)

for cmd in "${required_commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        version=$($cmd --version 2>&1 | head -1 || echo "")
        echo "  ✓ $cmd"
    else
        echo "  ✗ $cmd (NÃO INSTALADO)"
        all_tests_passed=false
    fi
done

echo ""

### ========== TESTE 6: Verificar Funções dos Scripts ==========
echo "[ TESTE 6 ] Verificando funções definidas..."
echo ""

# Verificar se backup-volumes.sh tem as funções necessárias
if grep -q "backup_volume()" backup-volumes.sh; then
    echo "  ✓ backup-volumes.sh: função backup_volume() definida"
else
    echo "  ✗ backup-volumes.sh: função backup_volume() NÃO encontrada"
    all_tests_passed=false
fi

if grep -q "list_volumes()" backup-volumes.sh; then
    echo "  ✓ backup-volumes.sh: função list_volumes() definida"
else
    echo "  ✗ backup-volumes.sh: função list_volumes() NÃO encontrada"
    all_tests_passed=false
fi

# Verificar se restore-volumes.sh tem as funções necessárias
if grep -q "restore_volume()" restore-volumes.sh; then
    echo "  ✓ restore-volumes.sh: função restore_volume() definida"
else
    echo "  ✗ restore-volumes.sh: função restore_volume() NÃO encontrada"
    all_tests_passed=false
fi

# Verificar se migrar-volumes.sh tem as funções de log
if grep -q "log_info()" migrar-volumes.sh; then
    echo "  ✓ migrar-volumes.sh: funções de log definidas"
else
    echo "  ✗ migrar-volumes.sh: funções de log NÃO encontradas"
    all_tests_passed=false
fi

echo ""

### ========== TESTE 7: Verificar Carregamento de Bibliotecas ==========
echo "[ TESTE 7 ] Verificando carregamento de bibliotecas..."
echo ""

lib_loading_scripts=(
    "backup-volumes.sh"
    "transfer-volumes.sh"
    "restore-volumes.sh"
)

for script in "${lib_loading_scripts[@]}"; do
    if grep -q 'source.*lib/common.sh' "$script"; then
        echo "  ✓ $script carrega lib/common.sh"
    else
        echo "  ⚠ $script NÃO carrega lib/common.sh (pode ter funções próprias)"
    fi
done

echo ""

### ========== RESULTADO FINAL ==========
echo "======================================"
if [ "$all_tests_passed" = true ]; then
    echo "✅ TODOS OS TESTES PASSARAM"
    echo ""
    echo "Os scripts de migração estão prontos para uso!"
    echo ""
    echo "Próximos passos:"
    echo "  1. Execute ./migrar-volumes.sh para migração completa"
    echo "  2. Ou use scripts individuais conforme necessário"
    echo "  3. Veja docs/MIGRACAO-VOLUMES.md para mais detalhes"
    exit 0
else
    echo "❌ ALGUNS TESTES FALHARAM"
    echo ""
    echo "Corrija os problemas acima antes de usar os scripts."
    echo "Veja os logs acima para detalhes dos erros."
    exit 1
fi
echo "======================================"
