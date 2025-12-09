#!/bin/bash
################################################################################
# Script: checklist-migracao.sh
# Propósito: Checklist interativo para processo de migração
# Uso: ./checklist-migracao.sh
################################################################################

LOG_PREFIX="[ Migration Checklist ]"
CHECKLIST_FILE="/tmp/migration-checklist-$(date +%Y%m%d_%H%M%S).txt"

log() {
    echo "$LOG_PREFIX [ $1 ] $2"
}

# Cores para interface
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          CHECKLIST INTERATIVO DE MIGRAÇÃO                  ║"
echo "║           Acompanhe cada etapa do processo                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Perguntar modo de operação
echo "Selecione o modo:"
echo "  [1] Migração completa (VPS Principal → VPS Teste)"
echo "  [2] Apenas validação pré-migração"
echo "  [3] Apenas validação pós-migração"
echo ""
read -p "$LOG_PREFIX [ INPUT ] Opção (1-3): " MODE

case $MODE in
    1)
        MODE_NAME="Migração Completa"
        ;;
    2)
        MODE_NAME="Validação Pré-Migração"
        ;;
    3)
        MODE_NAME="Validação Pós-Migração"
        ;;
    *)
        log "ERROR" "Opção inválida"
        exit 1
        ;;
esac

echo ""
log "INFO" "Modo selecionado: $MODE_NAME"
echo ""

# Inicializar checklist
cat > "$CHECKLIST_FILE" <<EOF
CHECKLIST DE MIGRAÇÃO
====================
Data: $(date)
Modo: $MODE_NAME

EOF

completed=0
total=0

mark_step() {
    local step_name="$1"
    local status="$2"  # "done", "skip", "fail"

    ((total++))

    if [ "$status" = "done" ]; then
        echo "✅ $step_name" >> "$CHECKLIST_FILE"
        echo -e "${GREEN}✅ $step_name${NC}"
        ((completed++))
    elif [ "$status" = "skip" ]; then
        echo "⏭️  $step_name (pulado)" >> "$CHECKLIST_FILE"
        echo -e "${YELLOW}⏭️  $step_name (pulado)${NC}"
    else
        echo "❌ $step_name (falhou)" >> "$CHECKLIST_FILE"
        echo -e "${RED}❌ $step_name (falhou)${NC}"
    fi
}

confirm_step() {
    local step_description="$1"
    local auto_check="$2"  # comando opcional para checagem automática

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📋 $step_description${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Se tem auto-check, executar
    if [ -n "$auto_check" ]; then
        echo ""
        log "INFO" "Verificando automaticamente..."
        if eval "$auto_check" >/dev/null 2>&1; then
            log "SUCCESS" "Verificação automática passou!"
            mark_step "$step_description" "done"
            return 0
        else
            log "WARNING" "Verificação automática falhou"
        fi
    fi

    # Perguntar ao usuário
    echo ""
    read -p "$LOG_PREFIX [ INPUT ] Concluído? (s=sim, n=não, p=pular): " answer

    case $answer in
        s|S|y|Y)
            mark_step "$step_description" "done"
            return 0
            ;;
        p|P)
            mark_step "$step_description" "skip"
            return 0
            ;;
        *)
            mark_step "$step_description" "fail"
            return 1
            ;;
    esac
}

################################################################################
# MODO 1: MIGRAÇÃO COMPLETA
################################################################################

if [ "$MODE" = "1" ]; then

    echo "════════════════════════════════════════════════════════════"
    echo "FASE 1: PREPARAÇÃO DA VPS PRINCIPAL (ORIGEM)"
    echo "════════════════════════════════════════════════════════════"

    confirm_step "VPS Guardian instalado na VPS Principal" "command -v vps-guardian"
    confirm_step "Comando 'vps-guardian' funciona no terminal" "vps-guardian --version"

    echo ""
    log "INFO" "Executar validação pré-migração..."
    read -p "$LOG_PREFIX [ INPUT ] Deseja executar agora? (s/n): " run_pre
    if [ "$run_pre" = "s" ]; then
        ./scripts-auxiliares/validar-pre-migracao.sh
        confirm_step "Validação pré-migração passou sem erros críticos" ""
    else
        confirm_step "Validação pré-migração executada manualmente" ""
    fi

    echo ""
    log "INFO" "Criar backup do Coolify..."
    read -p "$LOG_PREFIX [ INPUT ] Deseja criar backup agora? (s/n): " run_backup
    if [ "$run_backup" = "s" ]; then
        ./backup/backup-coolify.sh
        confirm_step "Backup do Coolify criado com sucesso" "ls /root/coolify-backups/*.tar.gz"
    else
        confirm_step "Backup do Coolify já existe" "ls /root/coolify-backups/*.tar.gz"
    fi

    confirm_step "Backup verificado e tem conteúdo válido (DB dump, .env, SSH keys)" ""

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "FASE 2: PREPARAÇÃO DA VPS DE TESTE (DESTINO)"
    echo "════════════════════════════════════════════════════════════"

    read -p "$LOG_PREFIX [ INPUT ] IP da VPS de teste: " TEST_VPS_IP
    echo "VPS de Teste: $TEST_VPS_IP" >> "$CHECKLIST_FILE"

    confirm_step "Acesso SSH configurado para VPS de teste" "ssh root@$TEST_VPS_IP 'exit'"
    confirm_step "Chave SSH copiada (sem pedir senha)" "ssh -o BatchMode=yes root@$TEST_VPS_IP 'exit'"
    confirm_step "Docker instalado na VPS de teste" "ssh root@$TEST_VPS_IP 'docker --version'"
    confirm_step "VPS de teste tem espaço em disco suficiente (>10GB)" ""

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "FASE 3: EXECUTAR MIGRAÇÃO"
    echo "════════════════════════════════════════════════════════════"

    echo ""
    log "WARNING" "Pronto para iniciar migração!"
    log "INFO" "Isso irá:"
    echo "  1. Instalar Coolify na VPS de teste"
    echo "  2. Transferir backup"
    echo "  3. Restaurar banco de dados"
    echo "  4. Copiar SSH keys e configurações"
    echo "  5. Reiniciar Coolify"
    echo ""

    read -p "$LOG_PREFIX [ INPUT ] Iniciar migração agora? (yes/no): " start_migration

    if [ "$start_migration" = "yes" ]; then
        ./migrar/migrar-coolify.sh
        confirm_step "Script de migração executou sem erros" ""
    else
        log "INFO" "Migração não iniciada. Execute manualmente:"
        echo "  ./migrar/migrar-coolify.sh"
        confirm_step "Migração executada manualmente" ""
    fi

    confirm_step "Coolify instalado na VPS de teste" ""
    confirm_step "Backup transferido com sucesso" ""
    confirm_step "Banco de dados restaurado" ""
    confirm_step "Containers do Coolify iniciados" ""

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "FASE 4: VALIDAÇÃO PÓS-MIGRAÇÃO"
    echo "════════════════════════════════════════════════════════════"

    echo ""
    log "INFO" "Executar validação pós-migração na VPS de teste..."
    read -p "$LOG_PREFIX [ INPUT ] Deseja executar agora? (s/n): " run_post
    if [ "$run_post" = "s" ]; then
        ./scripts-auxiliares/validar-pos-migracao.sh --remote "$TEST_VPS_IP"
        confirm_step "Validação pós-migração passou sem erros críticos" ""
    else
        confirm_step "Validação pós-migração executada manualmente" ""
    fi

    echo ""
    log "INFO" "Testar acesso à interface web..."
    echo "  URL: http://$TEST_VPS_IP:8000"
    echo ""

    confirm_step "Interface do Coolify carrega no navegador" ""
    confirm_step "Login funciona com credenciais originais" ""
    confirm_step "Dashboard mostra aplicações migradas" ""
    confirm_step "Configurações e variáveis de ambiente preservadas" ""
    confirm_step "SSH keys estão disponíveis no Coolify" ""

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "FASE 5: TESTES DE RECUPERAÇÃO"
    echo "════════════════════════════════════════════════════════════"

    confirm_step "Testado cenário de recuperação de desastre" ""
    confirm_step "Backup incremental testado e funcionando" ""

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "FASE 6: SEGURANÇA E CONFIGURAÇÕES FINAIS"
    echo "════════════════════════════════════════════════════════════"

    echo ""
    log "INFO" "Configurar firewall na VPS de teste (opcional)..."
    read -p "$LOG_PREFIX [ INPUT ] Configurar firewall agora? (s/n): " config_fw
    if [ "$config_fw" = "s" ]; then
        log "INFO" "Execute na VPS de TESTE:"
        echo "  ssh root@$TEST_VPS_IP"
        echo "  cd /opt/manutencao_backup_vps"
        echo "  ./manutencao/configurar-firewall.sh"
        echo ""
        confirm_step "Firewall configurado na VPS de teste" ""
    else
        confirm_step "Firewall não configurado (pulado)" "skip"
    fi

    confirm_step "Portas necessárias abertas (22, 80, 443, 8000)" ""
    confirm_step "SSH não foi bloqueado pelo firewall" ""

fi

################################################################################
# MODO 2: APENAS PRÉ-MIGRAÇÃO
################################################################################

if [ "$MODE" = "2" ]; then
    echo "════════════════════════════════════════════════════════════"
    echo "VALIDAÇÃO PRÉ-MIGRAÇÃO"
    echo "════════════════════════════════════════════════════════════"

    echo ""
    log "INFO" "Executando script de validação..."
    ./scripts-auxiliares/validar-pre-migracao.sh

    confirm_step "Sistema passou na validação pré-migração" ""
    confirm_step "Backup do Coolify existe e é válido" "ls /root/coolify-backups/*.tar.gz"
    confirm_step "Docker está rodando" "docker ps"
    confirm_step "Coolify está operacional" "docker ps --filter name=coolify"
    confirm_step "Banco de dados está saudável" "docker exec coolify-db pg_isready -U coolify"
fi

################################################################################
# MODO 3: APENAS PÓS-MIGRAÇÃO
################################################################################

if [ "$MODE" = "3" ]; then
    echo "════════════════════════════════════════════════════════════"
    echo "VALIDAÇÃO PÓS-MIGRAÇÃO"
    echo "════════════════════════════════════════════════════════════"

    read -p "$LOG_PREFIX [ INPUT ] Validar servidor REMOTO? (s/n): " is_remote

    if [ "$is_remote" = "s" ]; then
        read -p "$LOG_PREFIX [ INPUT ] IP do servidor: " REMOTE_IP
        ./scripts-auxiliares/validar-pos-migracao.sh --remote "$REMOTE_IP"
    else
        ./scripts-auxiliares/validar-pos-migracao.sh
    fi

    confirm_step "Validação pós-migração executada" ""
    confirm_step "Todos os containers do Coolify estão rodando" ""
    confirm_step "Banco de dados restaurado e operacional" ""
    confirm_step "Interface web acessível" ""
    confirm_step "Login funciona corretamente" ""
fi

################################################################################
# RESUMO FINAL
################################################################################

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                     RESUMO DO CHECKLIST                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

COMPLETION_RATE=$(( completed * 100 / total ))

echo "  Total de etapas: $total"
echo "  Concluídas: $completed"
echo "  Taxa de conclusão: ${COMPLETION_RATE}%"
echo ""

if [ $completed -eq $total ]; then
    echo -e "${GREEN}🎉 PARABÉNS! Todas as etapas foram concluídas!${NC}"
    echo ""
    echo "Próximos passos:"
    echo "  1. Documentar o processo"
    echo "  2. Manter VPS de teste para validação adicional"
    echo "  3. Configurar backups automáticos"
    echo "  4. Planejar migração da VPS principal"
elif [ $COMPLETION_RATE -ge 80 ]; then
    echo -e "${YELLOW}⚠️  Migração quase completa (${COMPLETION_RATE}%)${NC}"
    echo ""
    echo "Revise as etapas que faltam e complete quando possível"
else
    echo -e "${RED}❌ Migração incompleta (${COMPLETION_RATE}%)${NC}"
    echo ""
    echo "Várias etapas ainda precisam ser concluídas"
    echo "Revise o checklist e corrija os problemas"
fi

echo ""
echo "Checklist completo salvo em: $CHECKLIST_FILE"
echo ""

# Salvar resumo no arquivo
cat >> "$CHECKLIST_FILE" <<EOF

RESUMO
======
Total de etapas: $total
Concluídas: $completed
Taxa de conclusão: ${COMPLETION_RATE}%
Data de conclusão: $(date)
EOF

log "SUCCESS" "Checklist finalizado!"
