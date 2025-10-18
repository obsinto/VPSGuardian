#!/bin/bash
################################################################################
# Script: restaurar-volume-interativo.sh
# Propósito: Restaurar um volume Docker a partir de backup (versão interativa)
# Uso: ./restaurar-volume-interativo.sh [backup-file] [volume-name]
################################################################################

# === INPUT PROMPTS ===

# Se o arquivo de backup não foi passado como parâmetro, listar e perguntar
if [ -z "$1" ]; then
    echo "[ Restore Agent ] [ INFO ] Available backups in /root/volume-backups:"
    echo ""

    if ls /root/volume-backups/*.tar.gz 1> /dev/null 2>&1; then
        ls -lh /root/volume-backups/*.tar.gz | awk '{print $9, "("$5")"}'
        echo ""
    else
        echo "[ Restore Agent ] [ WARNING ] No backups found in /root/volume-backups/"
        echo ""
    fi

    read -p "[ Restore Agent ] [ INPUT ] Please enter the full path to the backup file: " BACKUP_FILE
else
    BACKUP_FILE="$1"
fi

# Informar o arquivo de backup selecionado
echo "[ Restore Agent ] [ INFO ] Backup file is set to $BACKUP_FILE"

# Validar se o arquivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "[ Restore Agent ] [ ERROR ] Backup file '$BACKUP_FILE' not found, aborting restore."
    echo "[ Restore Agent ] [ ERROR ] Restore Failed!"
    exit 1
else
    echo "[ Restore Agent ] [ INFO ] Backup file exists, continuing restore..."
fi

# Se o nome do volume não foi passado, perguntar
if [ -z "$2" ]; then
    # Tentar extrair nome do volume do arquivo
    SUGGESTED_VOLUME=$(basename "$BACKUP_FILE" | sed 's/-[0-9_]*\.tar\.gz$//')

    read -p "[ Restore Agent ] [ INPUT ] Please enter the volume name to restore to (suggested: $SUGGESTED_VOLUME): " VOLUME_NAME
    VOLUME_NAME=${VOLUME_NAME:-$SUGGESTED_VOLUME}
else
    VOLUME_NAME="$2"
fi

# Informar o volume de destino
echo "[ Restore Agent ] [ INFO ] Target volume is set to $VOLUME_NAME"

# Verificar se o volume já existe
if docker volume ls --quiet | grep -q "^$VOLUME_NAME$"; then
    echo "[ Restore Agent ] [ WARNING ] Volume '$VOLUME_NAME' already exists!"
    read -p "[ Restore Agent ] [ INPUT ] Do you want to OVERWRITE it? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo "[ Restore Agent ] [ INFO ] Restore cancelled by user."
        exit 0
    fi

    echo "[ Restore Agent ] [ WARNING ] Proceeding with overwrite..."
else
    echo "[ Restore Agent ] [ INFO ] Volume '$VOLUME_NAME' does not exist, creating it..."
    docker volume create "$VOLUME_NAME" || {
        echo "[ Restore Agent ] [ ERROR ] Failed to create volume '$VOLUME_NAME', aborting restore."
        echo "[ Restore Agent ] [ ERROR ] Restore Failed!"
        exit 1
    }
fi

# === SCRIPT START ===

# Informar início da restauração
echo "[ Restore Agent ] [ INFO ] Restoring backup to volume: $VOLUME_NAME"

# Executar container Docker para restaurar o backup
docker run --rm \
  -v "$VOLUME_NAME":/volume \
  -v "$(dirname "$BACKUP_FILE")":/backup \
  busybox \
  sh -c "cd /volume && tar xzf /backup/$(basename "$BACKUP_FILE")" || {
    echo "[ Restore Agent ] [ ERROR ] Restore process failed, aborting."
    echo "[ Restore Agent ] [ ERROR ] Restore Failed!"
    exit 1
}

# Verificar conteúdo restaurado
FILES_COUNT=$(docker run --rm -v "$VOLUME_NAME":/volume busybox find /volume -type f | wc -l)
TOTAL_SIZE=$(docker run --rm -v "$VOLUME_NAME":/volume busybox du -sh /volume | cut -f1)

# Sucesso!
echo "[ Restore Agent ] [ SUCCESS ] Restore completed!"
echo "[ Restore Agent ] [ INFO ] Volume: $VOLUME_NAME"
echo "[ Restore Agent ] [ INFO ] Files restored: $FILES_COUNT"
echo "[ Restore Agent ] [ INFO ] Total size: $TOTAL_SIZE"

# Perguntar se deseja inspecionar o volume
echo ""
read -p "[ Restore Agent ] [ INPUT ] Do you want to list the restored files? (yes/no): " SHOW_FILES

if [ "$SHOW_FILES" = "yes" ]; then
    echo ""
    echo "[ Restore Agent ] [ INFO ] Contents of volume '$VOLUME_NAME':"
    docker run --rm -v "$VOLUME_NAME":/volume busybox ls -lah /volume
fi
