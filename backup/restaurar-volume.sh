#!/bin/bash
################################################################################
# Script: restaurar-volume.sh
# Propósito: Restaurar um volume Docker a partir de backup
# Uso: ./restaurar-volume.sh backup.tar.gz nome-do-volume
################################################################################

BACKUP_FILE="$1"
VOLUME_NAME="$2"

if [ -z "$BACKUP_FILE" ] || [ -z "$VOLUME_NAME" ]; then
    echo "Uso: $0 <arquivo-backup.tar.gz> <nome-do-volume>"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Arquivo de backup não encontrado: $BACKUP_FILE"
    exit 1
fi

# Criar volume se não existir
if ! docker volume ls --quiet | grep -q "^$VOLUME_NAME$"; then
    echo "📦 Criando volume: $VOLUME_NAME"
    docker volume create "$VOLUME_NAME"
fi

echo "🔄 Restaurando backup para o volume: $VOLUME_NAME"

docker run --rm \
  -v "$VOLUME_NAME":/volume \
  -v "$(dirname $BACKUP_FILE)":/backup \
  busybox \
  sh -c "cd /volume && tar xzf /backup/$(basename $BACKUP_FILE)"

if [ $? -eq 0 ]; then
    echo "✅ Volume restaurado com sucesso"
else
    echo "❌ Falha na restauração"
    exit 1
fi
