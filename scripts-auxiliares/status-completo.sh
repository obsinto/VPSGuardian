#!/bin/bash
################################################################################
# Script de Status Completo
# Propósito: Dashboard unificado mostrando status do VPS, Docker, Coolify,
#            backups e manutenção
################################################################################

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          STATUS COMPLETO DO VPS + COOLIFY                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "📅 $(date '+%A, %d de %B de %Y - %H:%M:%S')"
echo "🖥️  Hostname: $(hostname)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 DISCO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
df -h / | tail -1 | awk '{print "  Usado: "$3" de "$2" ("$5")"}'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧠 MEMÓRIA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
free -h | grep Mem | awk '{print "  Usado: "$3" de "$2" ("int($3/$2*100)"%)"}'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐳 DOCKER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker system df 2>/dev/null || echo "  Docker não disponível"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 COOLIFY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if docker ps --format '{{.Names}}' | grep -q "coolify"; then
    echo "  Status: ✅ Rodando"
    COOLIFY_VERSION=$(docker ps --filter "name=coolify" --format '{{.Image}}' | grep coollabsio/coolify | head -n1)
    echo "  Versão: $COOLIFY_VERSION"
else
    echo "  Status: ❌ Não está rodando"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 ÚLTIMA MANUTENÇÃO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /var/log/manutencao/manutencao.log ]; then
    tail -5 /var/log/manutencao/manutencao.log | sed 's/^/  /'
else
    echo "  Nenhuma manutenção registrada"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 ÚLTIMO BACKUP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d /root/coolify-backups ]; then
    ULTIMO_BACKUP=$(ls -t /root/coolify-backups/*.tar.gz 2>/dev/null | head -1)
    if [ -n "$ULTIMO_BACKUP" ]; then
        echo "  Arquivo: $(basename $ULTIMO_BACKUP)"
        echo "  Tamanho: $(du -h $ULTIMO_BACKUP | cut -f1)"
        echo "  Data: $(stat -c %y $ULTIMO_BACKUP | cut -d'.' -f1)"
        echo "  Total de backups: $(ls -1 /root/coolify-backups/*.tar.gz 2>/dev/null | wc -l)"
    else
        echo "  Nenhum backup encontrado"
    fi
else
    echo "  Diretório de backups não existe"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 UPDATES PENDENTES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")
echo "  Pacotes para atualizar: $UPDATES"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏰ PRÓXIMAS EXECUÇÕES AGENDADAS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Backup: Próximo domingo às 02:00"
echo "  Manutenção: Próxima segunda às 03:00"
echo "  Verificação: Todo dia às 09:00"
echo ""
