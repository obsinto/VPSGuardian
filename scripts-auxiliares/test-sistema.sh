#!/bin/bash
################################################################################
# Script de Teste do Sistema
# Propósito: Testar todo o sistema de manutenção e backup
################################################################################

echo "╔════════════════════════════════════════════════════════════╗"
echo "║           TESTE COMPLETO DO SISTEMA DE MANUTENÇÃO          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

ERROS=0

# Teste 1: Scripts existem e são executáveis
echo "🔍 Teste 1: Verificando scripts..."
for script in manutencao-completa.sh backup-coolify.sh alerta-disco.sh; do
    if [ -x "/opt/manutencao/$script" ]; then
        echo "  ✓ $script OK"
    else
        echo "  ✗ $script FALTANDO ou não executável"
        ((ERROS++))
    fi
done
echo ""

# Teste 2: Diretórios existem
echo "🔍 Teste 2: Verificando diretórios..."
for dir in /opt/manutencao /var/log/manutencao /root/coolify-backups; do
    if [ -d "$dir" ]; then
        echo "  ✓ $dir OK"
    else
        echo "  ✗ $dir FALTANDO"
        ((ERROS++))
    fi
done
echo ""

# Teste 3: Cron configurado
echo "🔍 Teste 3: Verificando cron..."
if sudo crontab -l | grep -q "manutencao-completa.sh"; then
    echo "  ✓ Cron de manutenção OK"
else
    echo "  ✗ Cron de manutenção NÃO configurado"
    ((ERROS++))
fi

if sudo crontab -l | grep -q "backup-coolify.sh"; then
    echo "  ✓ Cron de backup OK"
else
    echo "  ✗ Cron de backup NÃO configurado"
    ((ERROS++))
fi
echo ""

# Teste 4: unattended-upgrades instalado
echo "🔍 Teste 4: Verificando unattended-upgrades..."
if dpkg -l | grep -q unattended-upgrades; then
    echo "  ✓ unattended-upgrades instalado"
else
    echo "  ✗ unattended-upgrades NÃO instalado"
    ((ERROS++))
fi
echo ""

# Teste 5: Coolify rodando
echo "🔍 Teste 5: Verificando Coolify..."
if docker ps --format '{{.Names}}' | grep -q "coolify"; then
    echo "  ✓ Coolify está rodando"
else
    echo "  ✗ Coolify NÃO está rodando"
    ((ERROS++))
fi
echo ""

# Teste 6: Backups existem
echo "🔍 Teste 6: Verificando backups..."
BACKUP_COUNT=$(ls -1 /root/coolify-backups/*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 0 ]; then
    echo "  ✓ $BACKUP_COUNT backups encontrados"
else
    echo "  ⚠  Nenhum backup encontrado (execute backup-coolify.sh)"
fi
echo ""

# Teste 7: Espaço em disco
echo "🔍 Teste 7: Verificando espaço em disco..."
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    echo "  ✓ Disco em ${DISK_USAGE}% (OK)"
else
    echo "  ⚠  Disco em ${DISK_USAGE}% (ALERTA)"
fi
echo ""

# Teste 8: Logs recentes
echo "🔍 Teste 8: Verificando logs..."
if [ -f /var/log/manutencao/manutencao.log ]; then
    LAST_MAINTENANCE=$(tail -1 /var/log/manutencao/manutencao.log | grep -o '\[.*\]' | head -1)
    echo "  ✓ Última manutenção: $LAST_MAINTENANCE"
else
    echo "  ⚠  Nenhuma manutenção executada ainda"
fi

if [ -f /var/log/manutencao/backup-coolify.log ]; then
    LAST_BACKUP=$(tail -1 /var/log/manutencao/backup-coolify.log | grep -o '\[.*\]' | head -1)
    echo "  ✓ Último backup: $LAST_BACKUP"
else
    echo "  ⚠  Nenhum backup executado ainda"
fi
echo ""

# Resultado final
echo "════════════════════════════════════════════════════════════"
if [ $ERROS -eq 0 ]; then
    echo "✅ TODOS OS TESTES PASSARAM!"
else
    echo "❌ $ERROS ERRO(S) ENCONTRADO(S)"
fi
echo "════════════════════════════════════════════════════════════"

exit $ERROS
