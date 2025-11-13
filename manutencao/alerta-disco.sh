#!/bin/bash
################################################################################
# Script de Alerta de Disco
# Propósito: Verifica espaço em disco e envia alerta se ultrapassar limite
################################################################################

# Configuração
LIMITE=80
EMAIL_NOTIFICACAO="${EMAIL_NOTIFICACAO:-}"
HOSTNAME=$(hostname)

# Obter uso de disco da partição raiz (/) - método mais seguro
USO=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')

# Validar se obteve o valor corretamente
if [ -z "$USO" ] || ! [[ "$USO" =~ ^[0-9]+$ ]]; then
    echo "❌ Erro ao obter informações de disco"
    exit 1
fi

# Verificar limite e notificar
if [ "$USO" -gt "$LIMITE" ]; then
    MENSAGEM="⚠️  ALERTA: Disco em ${USO}% (limite: ${LIMITE}%) no servidor $HOSTNAME"
    echo "$MENSAGEM"

    # Enviar email se configurado
    if [ -n "$EMAIL_NOTIFICACAO" ] && command -v mail &> /dev/null; then
        echo "$MENSAGEM" | mail -s "ALERTA: Disco em ${USO}% - $HOSTNAME" "$EMAIL_NOTIFICACAO"
    fi

    exit 1
else
    echo "✓ Disco em ${USO}% - OK"
    exit 0
fi
