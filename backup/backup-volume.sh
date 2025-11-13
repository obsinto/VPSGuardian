#!/bin/bash
################################################################################
# Script: backup-volume.sh
# Propósito: Fazer backup de um volume Docker específico
# Uso: ./backup-volume.sh nome-do-volume
################################################################################

VOLUME_NAME="$1"
BACKUP_DIR="/root/volume-backups"
BACKUP_FILE="$BACKUP_DIR/${VOLUME_NAME}-$(date +%Y%m%d_%H%M%S).tar.gz"

if [ -z "$VOLUME_NAME" ]; then
    echo "Uso: $0 <nome-do-volume>"
    echo "Exemplo: $0 minha-aplicacao_data"
    exit 1
fi

# Verificar se volume existe
if ! docker volume ls --quiet | grep -q "^$VOLUME_NAME$"; then
    echo "❌ Volume '$VOLUME_NAME' não existe"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

echo "📦 Fazendo backup do volume: $VOLUME_NAME"

BACKUP_FILENAME=$(basename "$BACKUP_FILE")

docker run --rm \
  -v "$VOLUME_NAME":/volume \
  -v "$BACKUP_DIR":/backup \
  busybox \
  tar czf "/backup/$BACKUP_FILENAME" -C /volume .

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✅ Backup concluído: $BACKUP_FILE ($SIZE)"
else
    echo "❌ Falha no backup"
    exit 1
fi
