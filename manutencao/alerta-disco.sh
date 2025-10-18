#!/bin/bash
################################################################################
# Script de Alerta de Disco
# Propósito: Verifica espaço em disco e envia alerta se ultrapassar limite
################################################################################

LIMITE=80
USO=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ "$USO" -gt "$LIMITE" ]; then
    echo "⚠️  ALERTA: Disco em ${USO}% (limite: ${LIMITE}%)" | \
    mail -s "ALERTA: Disco cheio no VPS" seu-email@exemplo.com
fi
