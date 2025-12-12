#!/bin/bash
################################################################################
# Script: migrar-coolify.sh
# Propósito: Migrar Coolify completo para um novo servidor usando backups existentes
# Uso: ./migrar-coolify.sh [--config=/path/to/config] [--auto]
################################################################################

# Carregar bibliotecas compartilhadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

### ========== CONFIGURAÇÃO PADRÃO ==========
# Pode ser sobrescrito por arquivo de configuração ou variáveis de ambiente

# Servidor de destino
NEW_SERVER_IP="${NEW_SERVER_IP:-}"
NEW_SERVER_USER="${NEW_SERVER_USER:-root}"
NEW_SERVER_PORT="${NEW_SERVER_PORT:-22}"
NEW_SERVER_AUTH_KEYS_FILE="${NEW_SERVER_AUTH_KEYS_FILE:-/root/.ssh/authorized_keys}"

# Autenticação SSH
SSH_PRIVATE_KEY_PATH="${SSH_PRIVATE_KEY_PATH:-/root/.ssh/id_rsa}"
LOCAL_AUTH_KEYS_FILE="${LOCAL_AUTH_KEYS_FILE:-/root/.ssh/authorized_keys}"

# Backup a ser usado (deixe vazio para usar o mais recente)
BACKUP_FILE="${BACKUP_FILE:-}"

# Modo automático (sem prompts)
AUTO_MODE=false

# Diretórios
COOLIFY_DATA_DIR="/data/coolify"
ENV_FILE="$COOLIFY_DATA_DIR/source/.env"
SSH_KEYS_DIR="$COOLIFY_DATA_DIR/ssh/keys"
BACKUP_DIR="${COOLIFY_BACKUP_DIR:-/var/backups/vpsguardian/coolify}"

### ========== PARSE ARGUMENTOS ==========
CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --config=*)
            CONFIG_FILE="${1#*=}"
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --auto)
            AUTO_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --config=FILE    Load configuration from file"
            echo "  --auto           Run in automatic mode (no prompts)"
            echo "  -h, --help       Show this help"
            echo ""
            echo "Configuration file format (bash syntax):"
            echo "  NEW_SERVER_IP=\"192.168.1.100\""
            echo "  NEW_SERVER_USER=\"root\""
            echo "  NEW_SERVER_PORT=\"22\""
            echo "  SSH_PRIVATE_KEY_PATH=\"/root/.ssh/id_rsa\""
            echo "  BACKUP_FILE=\"/var/backups/vpsguardian/coolify/backup.tar.gz\""
            echo ""
            echo "Environment variables can also be used to set configuration."
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Carregar arquivo de configuração se especificado
if [ -n "$CONFIG_FILE" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        log_info "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
fi

### ========== CONSTANTES ==========
REMOTE_BACKUP_DIR="/root/coolify-backup"
CONTROL_SOCKET="/tmp/ssh_mux_socket_$$"

# Criar diretório de logs
MIGRATION_LOG_DIR="$LOG_DIR/migration-$(date +%Y%m%d_%H%M%S)"
ensure_directory "$MIGRATION_LOG_DIR" 755
set_log_file "$MIGRATION_LOG_DIR/migration-agent.log"

DB_RESTORE_LOG="$MIGRATION_LOG_DIR/db-restore.log"
INSTALL_LOG="$MIGRATION_LOG_DIR/coolify-install.log"
FINAL_INSTALL_LOG="$MIGRATION_LOG_DIR/coolify-final-install.log"

### ========== FUNÇÕES ==========

check_success() {
    if [ $1 -eq 0 ]; then
        log_success "$2"
    else
        log_error "$2"
        cleanup_and_exit 1
    fi
}

check_and_install_dependencies() {
    local missing_deps=()

    # Verificar sshpass (útil mas não obrigatório, expect é fallback)
    if ! command -v sshpass >/dev/null 2>&1; then
        missing_deps+=("sshpass")
    fi

    # Verificar expect (fallback se não tiver sshpass)
    if ! command -v expect >/dev/null 2>&1; then
        missing_deps+=("expect")
    fi

    # Se ambos estão faltando, oferecer instalar
    if [ ${#missing_deps[@]} -eq 2 ]; then
        log_warning "Ferramentas de automação SSH não encontradas (sshpass ou expect)"

        if [ "$AUTO_MODE" = false ]; then
            echo ""
            echo "Para configurar SSH automaticamente, precisamos de uma das ferramentas:"
            echo "  - sshpass (recomendado, mais simples)"
            echo "  - expect (alternativa)"
            echo ""
            read -p "Deseja instalar sshpass agora? (S/n): " INSTALL_DEPS
            INSTALL_DEPS=${INSTALL_DEPS:-S}

            if [[ "$INSTALL_DEPS" =~ ^[Ss]$ ]]; then
                log_info "Instalando sshpass..."
                apt-get update -qq >/dev/null 2>&1
                apt-get install -y sshpass >/dev/null 2>&1

                if [ $? -eq 0 ]; then
                    log_success "sshpass instalado com sucesso!"
                else
                    log_error "Falha ao instalar sshpass. Você pode configurar SSH manualmente."
                fi
            else
                log_warning "Prosseguindo sem automação SSH. Você precisará configurar a chave manualmente."
            fi
        fi
    fi
}

cleanup_and_exit() {
    if [ $1 -eq 0 ]; then
        log_success "Migration completed successfully."
    else
        log_error "Migration failed."
    fi

    log_info "Cleaning up SSH connection and background processes..."
    kill $HEALTH_CHECK_PID 2>/dev/null || true
    ssh -S "$CONTROL_SOCKET" -O exit "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>/dev/null || true
    rm -f "$CONTROL_SOCKET"
    log_info "Cleanup complete."
    exit $1
}

trap 'cleanup_and_exit 1' SIGINT SIGTERM

### ========== VALIDAÇÃO E PROMPTS ==========
log_section "VPS Guardian - Migração Coolify"

# Validar/solicitar configurações obrigatórias
if [ -z "$NEW_SERVER_IP" ]; then
    if [ "$AUTO_MODE" = true ]; then
        log_error "NEW_SERVER_IP is required in automatic mode"
        exit 1
    fi
    read -p "Enter the NEW server IP address: " NEW_SERVER_IP
fi

if [ -z "$NEW_SERVER_IP" ]; then
    log_error "Server IP is required"
    exit 1
fi

log_info "Target server: $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_PORT"

# Selecionar ou validar backup
if [ -z "$BACKUP_FILE" ]; then
    # Usar backup mais recente se em modo automático
    if [ "$AUTO_MODE" = true ]; then
        BACKUP_FILE=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1)
        if [ -z "$BACKUP_FILE" ]; then
            log_warning "No backups found in $BACKUP_DIR"
            log_info "Creating backup automatically..."

            # Determinar caminho do script de backup
            BACKUP_SCRIPT="$SCRIPT_DIR/../backup/backup-coolify.sh"
            if [ ! -f "$BACKUP_SCRIPT" ]; then
                log_error "Backup script not found: $BACKUP_SCRIPT"
                exit 1
            fi

            # Executar backup
            if bash "$BACKUP_SCRIPT"; then
                log_success "Backup created successfully!"

                # Buscar o backup mais recente
                BACKUP_FILE=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1)
                if [ -z "$BACKUP_FILE" ]; then
                    log_error "Failed to locate created backup"
                    exit 1
                fi
                log_info "Using newly created backup: $(basename $BACKUP_FILE)"
            else
                log_error "Failed to create backup"
                exit 1
            fi
        else
            log_info "Using most recent backup: $(basename $BACKUP_FILE)"
        fi
    else
        # Modo interativo - listar backups
        BACKUP_SELECTED=false

        while [ "$BACKUP_SELECTED" = false ]; do
            log_info "Available backups:"
            echo ""

            if ls "$BACKUP_DIR"/*.tar.gz 1> /dev/null 2>&1; then
                BACKUPS=($(ls -t "$BACKUP_DIR"/*.tar.gz))
                for i in "${!BACKUPS[@]}"; do
                    BACKUP_DATE=$(stat -c %y "${BACKUPS[$i]}" | cut -d'.' -f1)
                    BACKUP_SIZE=$(du -h "${BACKUPS[$i]}" | cut -f1)
                    echo "  [$i] $(basename ${BACKUPS[$i]}) - $BACKUP_DATE ($BACKUP_SIZE)"
                done
                echo ""
                echo "  Digite 'new' para criar um novo backup agora"
                echo ""
                read -p "Select backup number (0-$((${#BACKUPS[@]}-1)), 'new', or press Enter for most recent): " BACKUP_INDEX

                # Se usuário digitou 'new', criar novo backup
                if [[ "$BACKUP_INDEX" == "new" ]] || [[ "$BACKUP_INDEX" == "NEW" ]]; then
                    echo ""
                    log_info "Criando novo backup do Coolify..."
                    echo ""

                    # Determinar caminho do script de backup
                    BACKUP_SCRIPT="$SCRIPT_DIR/../backup/backup-coolify.sh"
                    if [ ! -f "$BACKUP_SCRIPT" ]; then
                        log_error "Script de backup não encontrado: $BACKUP_SCRIPT"
                        exit 1
                    fi

                    # Executar backup
                    if bash "$BACKUP_SCRIPT"; then
                        log_success "Backup criado com sucesso!"
                        echo ""
                        log_info "Recarregando lista de backups..."
                        echo ""
                        # Loop vai continuar e mostrar a lista atualizada
                        continue
                    else
                        log_error "Falha ao criar backup"
                        exit 1
                    fi
                fi

                # Seleção normal de backup
                BACKUP_INDEX=${BACKUP_INDEX:-0}

                # Validar índice
                if [[ "$BACKUP_INDEX" =~ ^[0-9]+$ ]] && [ "$BACKUP_INDEX" -ge 0 ] && [ "$BACKUP_INDEX" -lt ${#BACKUPS[@]} ]; then
                    BACKUP_FILE="${BACKUPS[$BACKUP_INDEX]}"
                    BACKUP_SELECTED=true
                else
                    log_error "Índice inválido: $BACKUP_INDEX"
                    echo ""
                fi
            else
                # Nenhum backup encontrado - sair do loop
                break
            fi
        done

        # Se ainda não tem backup selecionado, significa que não há backups
        if [ "$BACKUP_SELECTED" = false ]; then
            log_warning "No backups found in $BACKUP_DIR"
            echo ""
            echo "Você precisa de um backup do Coolify antes de migrar."
            echo ""
            read -p "Deseja criar um backup agora? (S/n): " CREATE_BACKUP
            CREATE_BACKUP=${CREATE_BACKUP:-S}

            if [[ "$CREATE_BACKUP" =~ ^[Ss]$ ]]; then
                log_info "Criando backup do Coolify..."
                echo ""

                # Determinar caminho do script de backup
                BACKUP_SCRIPT="$SCRIPT_DIR/../backup/backup-coolify.sh"
                if [ ! -f "$BACKUP_SCRIPT" ]; then
                    log_error "Script de backup não encontrado: $BACKUP_SCRIPT"
                    exit 1
                fi

                # Executar backup
                if bash "$BACKUP_SCRIPT"; then
                    log_success "Backup criado com sucesso!"
                    echo ""

                    # Buscar o backup mais recente
                    BACKUP_FILE=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1)
                    if [ -z "$BACKUP_FILE" ]; then
                        log_error "Falha ao localizar o backup criado"
                        exit 1
                    fi
                    log_info "Usando backup recém-criado: $(basename $BACKUP_FILE)"
                else
                    log_error "Falha ao criar backup"
                    exit 1
                fi
            else
                log_info "Backup cancelado pelo usuário"
                log_info "Execute 'vps-guardian backup' ou 'backup-coolify.sh' primeiro"
                exit 1
            fi
        fi
    fi
fi

# Validar backup existe
if [ ! -f "$BACKUP_FILE" ]; then
    log_error "Backup file not found: $BACKUP_FILE"
    exit 1
fi
log_success "Selected backup: $(basename $BACKUP_FILE)"

# Extrair backup temporariamente
TEMP_EXTRACT_DIR="/tmp/coolify-migration-$$"
mkdir -p "$TEMP_EXTRACT_DIR"
log_info "Extracting backup to analyze..."

# CORRIGIDO: Removido "--strip-components=1"
# Isso garante que a pasta 'ssh-keys' seja extraída exatamente como está no backup
tar -xzf "$BACKUP_FILE" -C "$TEMP_EXTRACT_DIR" 2>/dev/null

# Obter APP_KEY do backup
if [ -f "$TEMP_EXTRACT_DIR/.env" ]; then
    APP_KEY=$(grep "^APP_KEY=" "$TEMP_EXTRACT_DIR/.env" | cut -d '=' -f2-)
elif [ -f "$ENV_FILE" ]; then
    APP_KEY=$(grep "^APP_KEY=" "$ENV_FILE" | cut -d '=' -f2-)
fi

if [ -z "$APP_KEY" ]; then
    log_error "APP_KEY not found in backup or current installation"
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 1
fi
log_success "APP_KEY retrieved from backup."

# Detectar versão do Coolify
COOLIFY_IMAGE=$(docker ps --filter "name=coolify" --format '{{.Image}}' | grep coollabsio/coolify | head -n1)
COOLIFY_VERSION="${COOLIFY_IMAGE##*:}"
if [ -z "$COOLIFY_VERSION" ] || [ "$COOLIFY_VERSION" = "coollabsio/coolify" ]; then
    COOLIFY_VERSION="latest"
fi
log_success "Detected Coolify version: $COOLIFY_VERSION"

# Confirmar migração (skip em modo auto)
if [ "$AUTO_MODE" = false ]; then
    echo ""
    log_section "MIGRATION SUMMARY"
    echo "  Source backup: $(basename $BACKUP_FILE)"
    echo "  Target server: $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_PORT"
    echo "  Coolify version: $COOLIFY_VERSION"
    echo "  Logs directory: $MIGRATION_LOG_DIR"
    echo ""
    read -p "Proceed with migration? Type 'YES' to confirm: " CONFIRM

    if [ "$CONFIRM" != "YES" ]; then
        log_info "Migration cancelled by user."
        rm -rf "$TEMP_EXTRACT_DIR"
        exit 0
    fi
fi

# Verificar dependências necessárias
check_and_install_dependencies

### ========== SSH SETUP ==========
log_section "SSH Setup"

# Verificar chave SSH
if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
    log_warning "SSH key not found at $SSH_PRIVATE_KEY_PATH"
    echo ""

    # Procurar por chaves de migração anteriores
    MIGRATION_KEYS=($(ls -t /root/.ssh/id_ed25519_migration* 2>/dev/null | grep -v "\.pub$" | head -5))

    if [ ${#MIGRATION_KEYS[@]} -gt 0 ]; then
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  ⚠️  Encontradas ${#MIGRATION_KEYS[@]} chave(s) de migração anterior(es)${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
        echo ""

        LATEST_KEY="${MIGRATION_KEYS[0]}"
        KEY_DATE=$(stat -c %y "$LATEST_KEY" 2>/dev/null | cut -d' ' -f1)

        echo "  Chave mais recente: $(basename $LATEST_KEY)"
        echo "  Data de criação: $KEY_DATE"
        echo ""

        log_warning "Gerar novas chaves a cada migração causa:"
        echo "  ❌ Acúmulo de chaves antigas no ~/.ssh/"
        echo "  ❌ authorized_keys crescendo no servidor remoto"
        echo "  ❌ Dificulta rastreamento de qual chave usar"
        echo ""
    fi

    if [ "$AUTO_MODE" = false ]; then
        echo "Opções disponíveis:"

        if [ ${#MIGRATION_KEYS[@]} -gt 0 ]; then
            echo -e "  ${GREEN}1. Reutilizar chave de migração existente (RECOMENDADO)${NC}"
            echo "  2. Criar nova chave SSH"
            echo "  3. Informar caminho de chave diferente"
        else
            echo "  1. Criar nova chave SSH automaticamente (Recomendado)"
            echo "  2. Informar caminho de chave existente"
        fi
        echo ""

        if [ ${#MIGRATION_KEYS[@]} -gt 0 ]; then
            read -p "Escolha uma opção (1-3): " SSH_OPTION
        else
            read -p "Escolha uma opção (1-2): " SSH_OPTION
        fi
        SSH_OPTION=${SSH_OPTION:-1}

        if [ "$SSH_OPTION" = "1" ]; then
            if [ ${#MIGRATION_KEYS[@]} -gt 0 ]; then
                # Reutilizar chave existente
                NEW_KEY_PATH="$LATEST_KEY"
                log_success "✅ Reutilizando chave SSH existente: $(basename $NEW_KEY_PATH)"
                log_info "Isso evita acúmulo de chaves e mantém o sistema organizado"
            else
                # Criar nova chave SSH com nome fixo (sem timestamp)
                NEW_KEY_PATH="/root/.ssh/id_ed25519_migration"
                log_info "Gerando nova chave SSH em $NEW_KEY_PATH..."

                ssh-keygen -t ed25519 -f "$NEW_KEY_PATH" -N "" -C "vpsguardian-migration" >/dev/null 2>&1
                if [ $? -ne 0 ]; then
                    log_error "Falha ao gerar chave SSH"
                    rm -rf "$TEMP_EXTRACT_DIR"
                    exit 1
                fi
                log_success "Chave SSH gerada com sucesso!"
            fi
        elif [ "$SSH_OPTION" = "2" ]; then
            if [ ${#MIGRATION_KEYS[@]} -gt 0 ]; then
                # Criar nova chave mesmo havendo uma existente
                BACKUP_DIR="/root/.ssh/migration-keys-backup"
                mkdir -p "$BACKUP_DIR"

                log_warning "Fazendo backup de chaves antigas..."
                for old_key in "${MIGRATION_KEYS[@]}"; do
                    cp "$old_key" "$BACKUP_DIR/" 2>/dev/null
                    cp "${old_key}.pub" "$BACKUP_DIR/" 2>/dev/null
                done
                log_success "Backup salvo em: $BACKUP_DIR"

                NEW_KEY_PATH="/root/.ssh/id_ed25519_migration"
                log_info "Gerando nova chave SSH em $NEW_KEY_PATH..."

                ssh-keygen -t ed25519 -f "$NEW_KEY_PATH" -N "" -C "vpsguardian-migration" >/dev/null 2>&1
                if [ $? -ne 0 ]; then
                    log_error "Falha ao gerar chave SSH"
                    rm -rf "$TEMP_EXTRACT_DIR"
                    exit 1
                fi
                log_success "Chave SSH gerada com sucesso!"
            else
                # Modo original: informar caminho
                read -p "Digite o caminho da chave SSH existente: " NEW_KEY_PATH
                if [ ! -f "$NEW_KEY_PATH" ]; then
                    log_error "Chave SSH não encontrada em: $NEW_KEY_PATH"
                    rm -rf "$TEMP_EXTRACT_DIR"
                    exit 1
                fi
            fi
        elif [ "$SSH_OPTION" = "3" ] && [ ${#MIGRATION_KEYS[@]} -gt 0 ]; then
            # Informar caminho diferente
            read -p "Digite o caminho da chave SSH existente: " NEW_KEY_PATH
            if [ ! -f "$NEW_KEY_PATH" ]; then
                log_error "Chave SSH não encontrada em: $NEW_KEY_PATH"
                rm -rf "$TEMP_EXTRACT_DIR"
                exit 1
            fi
        else
            log_error "Opção inválida"
            rm -rf "$TEMP_EXTRACT_DIR"
            exit 1
        fi

        # Se for reutilizar, verificar se precisa recopiar para o servidor
        if [ "$SSH_OPTION" = "1" ] && [ ${#MIGRATION_KEYS[@]} -gt 0 ]; then
            echo ""
            log_info "Testando se a chave já está configurada no servidor remoto..."

            ssh -o BatchMode=yes -o ConnectTimeout=5 -i "$NEW_KEY_PATH" -p "$NEW_SERVER_PORT" \
                "$NEW_SERVER_USER@$NEW_SERVER_IP" "exit" >/dev/null 2>&1

            if [ $? -eq 0 ]; then
                log_success "✅ Chave já está configurada! Pulando cópia."
                SSH_COPY_SUCCESS=true
                SSH_PRIVATE_KEY_PATH="$NEW_KEY_PATH"
            else
                log_warning "Chave não está configurada no servidor. Será necessário copiar."
            fi
        fi

        # Apenas copiar chave se não for reutilização bem-sucedida
        if [ "${SSH_COPY_SUCCESS:-false}" != "true" ]; then

            # Pedir senha do servidor remoto (com retry)
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  Configuração de Acesso SSH"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Para configurar o acesso SSH ao servidor de destino,"
            echo "precisamos copiar a chave pública para o servidor."
            echo ""
            echo "Servidor: $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_PORT"
            echo ""

            # Loop de tentativas (máximo 3 tentativas)
            MAX_ATTEMPTS=3
            ATTEMPT=1
            SSH_COPY_SUCCESS=false

            while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
                if [ $ATTEMPT -gt 1 ]; then
                    echo ""
                    log_warning "❌ Senha incorreta ou falha na conexão."
                    echo ""
                fi

                read -s -p "Digite a SENHA do servidor de destino (tentativa $ATTEMPT/$MAX_ATTEMPTS): " REMOTE_PASSWORD
                echo ""
                echo ""

                # Verificar se senha não está vazia
                if [ -z "$REMOTE_PASSWORD" ]; then
                    log_error "Senha não pode estar vazia!"
                    ATTEMPT=$((ATTEMPT + 1))
                    continue
                fi

                # Verificar se sshpass está disponível
                if command -v sshpass >/dev/null 2>&1; then
                    log_info "Copiando chave SSH para o servidor (usando sshpass)..."
                    sshpass -p "$REMOTE_PASSWORD" ssh-copy-id -i "${NEW_KEY_PATH}.pub" \
                        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                        -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" >/dev/null 2>&1
                    SSH_COPY_EXIT=$?
                else
                    # Usar expect se sshpass não estiver disponível
                    log_info "Copiando chave SSH para o servidor (usando expect)..."
                    expect << EOF >/dev/null 2>&1
set timeout 30
spawn ssh-copy-id -i ${NEW_KEY_PATH}.pub -o StrictHostKeyChecking=no -p $NEW_SERVER_PORT $NEW_SERVER_USER@$NEW_SERVER_IP
expect {
    "password:" {
        send "$REMOTE_PASSWORD\r"
        expect eof
    }
    "Password:" {
        send "$REMOTE_PASSWORD\r"
        expect eof
    }
    timeout { exit 1 }
    eof
}
EOF
                    SSH_COPY_EXIT=$?
                fi

                # Limpar senha da memória
                unset REMOTE_PASSWORD

                if [ $SSH_COPY_EXIT -eq 0 ]; then
                    log_success "✅ Chave SSH copiada com sucesso!"
                    SSH_COPY_SUCCESS=true
                    SSH_PRIVATE_KEY_PATH="$NEW_KEY_PATH"
                    break  # Sai do loop de tentativas
                fi

                ATTEMPT=$((ATTEMPT + 1))
            done

            # Verificar se conseguiu copiar a chave
            if [ "$SSH_COPY_SUCCESS" = false ]; then
                echo ""
                log_error "❌ Falha ao copiar chave SSH após $MAX_ATTEMPTS tentativas."
                echo ""
                log_info "Possíveis causas:"
                log_info "  1. Senha incorreta"
                log_info "  2. Servidor não está acessível"
                log_info "  3. Firewall bloqueando conexão SSH"
                log_info "  4. Porta SSH diferente de $NEW_SERVER_PORT"
                echo ""
                log_info "Você pode configurar manualmente:"
                log_info "  ssh-copy-id -i ${NEW_KEY_PATH}.pub -p $NEW_SERVER_PORT $NEW_SERVER_USER@$NEW_SERVER_IP"
                echo ""
                rm -rf "$TEMP_EXTRACT_DIR"
                exit 1
            fi

            # Testar conexão SSH (FORA do loop de tentativas)
            echo ""
            log_info "Testando conexão SSH..."
            sleep 2  # Aguardar servidor processar a nova chave

            ssh -i "$SSH_PRIVATE_KEY_PATH" -o BatchMode=yes -o ConnectTimeout=10 \
                -o StrictHostKeyChecking=no -p "$NEW_SERVER_PORT" \
                "$NEW_SERVER_USER@$NEW_SERVER_IP" "echo OK" >/dev/null 2>&1

            if [ $? -eq 0 ]; then
                log_success "✅ Conexão SSH configurada e testada com sucesso!"
            else
                log_error "⚠️  Conexão SSH falhou, mas a chave foi copiada."
                log_warning "Tentando novamente em 3 segundos..."
                sleep 3

                # Segunda tentativa de teste
                ssh -i "$SSH_PRIVATE_KEY_PATH" -o BatchMode=yes -o ConnectTimeout=10 \
                    -o StrictHostKeyChecking=no -p "$NEW_SERVER_PORT" \
                    "$NEW_SERVER_USER@$NEW_SERVER_IP" "echo OK" >/dev/null 2>&1

                if [ $? -eq 0 ]; then
                    log_success "✅ Conexão SSH funcionando agora!"
                else
                    log_error "❌ Conexão SSH ainda falhando."
                    echo ""
                    log_warning "A chave foi copiada, mas não conseguimos testar a conexão."
                    log_warning "Isso pode ser temporário. O script continuará, mas pode falhar nas próximas etapas."
                    echo ""
                    read -p "Deseja continuar mesmo assim? (s/N): " CONTINUE_ANYWAY
                    CONTINUE_ANYWAY=${CONTINUE_ANYWAY:-N}

                    if [[ ! "$CONTINUE_ANYWAY" =~ ^[Ss]$ ]]; then
                        log_info "Migração cancelada pelo usuário"
                        rm -rf "$TEMP_EXTRACT_DIR"
                        exit 1
                    fi
                fi
            fi
        fi  # Fim do if SSH_COPY_SUCCESS
    fi  # Fim do if AUTO_MODE = false
else
    # Modo automático sem chave SSH
    log_error "Modo automático requer chave SSH pré-configurada"
    log_info "Configure SSH_PRIVATE_KEY_PATH antes de executar em modo --auto"
    rm -rf "$TEMP_EXTRACT_DIR"
    exit 1
fi  # Fim do if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]

log_info "Starting ssh-agent..."
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$SSH_PRIVATE_KEY_PATH" >/dev/null 2>&1
check_success $? "SSH key added to agent."

log_info "Testing SSH connection..."
ssh -o BatchMode=yes -o ConnectTimeout=10 -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" "exit" >/dev/null 2>&1
check_success $? "SSH connection successful."

log_info "Establishing persistent SSH connection..."
ssh -fN -M -S "$CONTROL_SOCKET" -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>/dev/null
check_success $? "Persistent SSH connection established."

# Health check em background
(while true; do
    if ssh -S "$CONTROL_SOCKET" -O check "$NEW_SERVER_USER@$NEW_SERVER_IP" 2>&1 | grep -q "Master running"; then
        sleep 20
    else
        log_error "SSH connection lost."
        cleanup_and_exit 1
    fi
done) &
HEALTH_CHECK_PID=$!

### ========== CHECK AND REMOVE EXISTING COOLIFY ==========
log_section "Check Existing Installation"

# Verificar se há Coolify instalado no servidor de destino
log_info "Checking for existing Coolify installation on destination server..."
EXISTING_COOLIFY=$(ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "docker ps -a --filter 'name=coolify' --format '{{.Names}}' 2>/dev/null" | wc -l)

if [ "$EXISTING_COOLIFY" -gt 0 ]; then
    log_warning "Coolify installation detected on destination server!"
    echo ""

    # Listar containers encontrados
    echo "Containers encontrados:"
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "docker ps -a --filter 'name=coolify' --format '  - {{.Names}} ({{.Status}})'"
    echo ""

    REMOVE_EXISTING="n"
    if [ "$AUTO_MODE" = false ]; then
        echo "⚠️  IMPORTANTE: Para uma migração limpa, é recomendado remover a instalação anterior."
        echo ""
        echo "Isso irá:"
        echo "  • Parar todos containers do Coolify"
        echo "  • Remover containers e imagens"
        echo "  • Limpar volumes Docker (OPCIONAL)"
        echo "  • Remover diretório /data/coolify"
        echo ""
        read -p "Deseja remover a instalação anterior? (S/n): " REMOVE_EXISTING
        REMOVE_EXISTING=${REMOVE_EXISTING:-S}
    else
        # Em modo automático, sempre remove (instalação limpa)
        REMOVE_EXISTING="S"
        log_warning "Modo automático: removendo instalação anterior automaticamente"
    fi

    if [[ "$REMOVE_EXISTING" =~ ^[Ss]$ ]]; then
        log_info "Removendo instalação anterior do Coolify..."

        # 1. Parar todos containers do Coolify
        log_info "Parando containers do Coolify..."
        ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "docker stop \$(docker ps -a --filter 'name=coolify' --format '{{.Names}}') 2>/dev/null || true"

        # 2. Remover containers
        log_info "Removendo containers..."
        ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "docker rm -f \$(docker ps -a --filter 'name=coolify' --format '{{.Names}}') 2>/dev/null || true"

        # 3. Perguntar sobre volumes (dados das aplicações)
        REMOVE_VOLUMES="n"
        if [ "$AUTO_MODE" = false ]; then
            echo ""
            log_warning "Volumes Docker contêm dados das aplicações (bancos de dados, arquivos, etc)."
            read -p "Deseja também remover os volumes? (s/N): " REMOVE_VOLUMES
            REMOVE_VOLUMES=${REMOVE_VOLUMES:-n}
        fi

        if [[ "$REMOVE_VOLUMES" =~ ^[Ss]$ ]]; then
            log_info "Removendo volumes do Coolify..."
            ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
                "docker volume rm \$(docker volume ls --filter 'name=coolify' --format '{{.Name}}') 2>/dev/null || true"
            log_success "Volumes removidos"
        else
            log_info "Volumes preservados (serão sobrescritos se necessário)"
        fi

        # 4. Remover imagens do Coolify (opcional, economiza espaço)
        log_info "Removendo imagens do Coolify..."
        ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "docker rmi \$(docker images 'coollabsio/coolify*' -q) 2>/dev/null || true"

        # 5. Remover diretório /data/coolify
        log_info "Removendo diretório /data/coolify..."
        ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "rm -rf /data/coolify"

        # 6. Limpar networks órfãs
        log_info "Limpando Docker networks órfãs..."
        ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "docker network prune -f 2>/dev/null || true"

        log_success "Instalação anterior removida completamente!"
        log_info "Servidor pronto para instalação limpa do Coolify"
    else
        log_warning "Instalação anterior NÃO removida"
        log_warning "A migração pode ter conflitos com a instalação existente"
        echo ""
        read -p "Deseja continuar mesmo assim? (s/N): " CONTINUE_ANYWAY
        CONTINUE_ANYWAY=${CONTINUE_ANYWAY:-n}

        if [[ ! "$CONTINUE_ANYWAY" =~ ^[Ss]$ ]]; then
            log_info "Migração cancelada pelo usuário"
            rm -rf "$TEMP_EXTRACT_DIR"
            cleanup_and_exit 0
        fi
    fi
else
    log_success "Nenhuma instalação anterior detectada. Servidor limpo!"
fi

echo ""

### ========== INSTALL COOLIFY ==========
log_section "Install Coolify"
log_info "Installing Coolify on new server (version: $COOLIFY_VERSION)..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash -s $COOLIFY_VERSION" \
    >"$INSTALL_LOG" 2>&1

grep -q "Your instance is ready to use" "$INSTALL_LOG"
check_success $? "Coolify install script completed."

### ========== PREPARE AND TRANSFER FILES ==========
log_section "Transfer Files"

# Localizar dump do PostgreSQL
DB_DUMP=$(find "$TEMP_EXTRACT_DIR" -name "coolify-db-*.dmp" -o -name "pg-dump-*.dmp" | head -1)
if [ -z "$DB_DUMP" ]; then
    log_error "PostgreSQL dump not found in backup"
    rm -rf "$TEMP_EXTRACT_DIR"
    cleanup_and_exit 1
fi
log_success "Found database dump: $(basename $DB_DUMP)"

# Criar diretório remoto e limpar SSH keys antigas
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "mkdir -p $REMOTE_BACKUP_DIR && rm -rf /data/coolify/ssh/keys/*"
check_success $? "Remote directories prepared."

# Transferir dump do banco
log_info "Transferring database dump..."
scp -o ControlPath="$CONTROL_SOCKET" -P "$NEW_SERVER_PORT" \
    "$DB_DUMP" "$NEW_SERVER_USER@$NEW_SERVER_IP:$REMOTE_BACKUP_DIR/db-dump.dmp" >/dev/null 2>&1
check_success $? "Database dump transferred."

# ==============================================================================
# DETECÇÃO DE CHAVES SSH (salvar para usar após Final Install)
# ==============================================================================
log_section "Detecting SSH Keys"
log_info "🔍 Localizando chaves SSH para transferência posterior..."
echo ""

# DEBUG: Informações do ambiente
log_info "DEBUG: Hostname atual: $(hostname)"
log_info "DEBUG: Diretório de trabalho: $(pwd)"
log_info "DEBUG: TEMP_EXTRACT_DIR: $TEMP_EXTRACT_DIR"
echo ""

SOURCE_KEYS=""
KEYS_COUNT=0

# 1. PRIORIDADE MÁXIMA: Sistema Local (/data/coolify/ssh/keys)
log_info "🔍 Verificando sistema local: /data/coolify/ssh/keys"
if [ -d "/data/coolify/ssh/keys" ]; then
    KEYS_COUNT=$(find "/data/coolify/ssh/keys" -type f 2>/dev/null | wc -l)

    log_info "✅ Diretório existe!"
    log_info "   Arquivos encontrados: $KEYS_COUNT"

    if [ $KEYS_COUNT -gt 0 ]; then
        SOURCE_KEYS="/data/coolify/ssh/keys"
        log_success "✅ Chaves encontradas no sistema local: $SOURCE_KEYS ($KEYS_COUNT arquivos)"

        # DEBUG: Listar os arquivos encontrados
        echo ""
        log_info "DEBUG: Listagem dos arquivos:"
        find "$SOURCE_KEYS" -type f 2>/dev/null | while read key_file; do
            log_info "  - $(basename $key_file) ($(stat -c%s "$key_file") bytes)"
        done
        echo ""
    else
        log_warning "⚠️  Diretório existe mas está VAZIO!"
    fi
else
    log_warning "❌ Diretório /data/coolify/ssh/keys não encontrado no sistema local"
fi

# 2. Fallback: Procura no Backup extraído
if [ -z "$SOURCE_KEYS" ] || [ $KEYS_COUNT -eq 0 ]; then
    log_info "🔍 Procurando chaves no backup extraído: $TEMP_EXTRACT_DIR"
    echo ""

    # DEBUG: Listar estrutura do backup
    log_info "DEBUG: Estrutura do backup extraído:"
    find "$TEMP_EXTRACT_DIR" -maxdepth 3 -type d 2>/dev/null | head -20 | while read dir; do
        log_info "  DIR: ${dir#$TEMP_EXTRACT_DIR/}"
    done
    echo ""

    FOUND_IN_BACKUP=$(find "$TEMP_EXTRACT_DIR" -type d \( -name "ssh-keys" -o -path "*/ssh/keys" \) 2>/dev/null | head -n 1)

    if [ -n "$FOUND_IN_BACKUP" ]; then
        KEYS_COUNT=$(find "$FOUND_IN_BACKUP" -type f 2>/dev/null | wc -l)
        log_info "✅ Diretório de chaves encontrado no backup: $FOUND_IN_BACKUP"
        log_info "   Arquivos encontrados: $KEYS_COUNT"

        if [ $KEYS_COUNT -gt 0 ]; then
            SOURCE_KEYS="$FOUND_IN_BACKUP"
            log_success "✅ Chaves encontradas no backup: $SOURCE_KEYS ($KEYS_COUNT arquivos)"

            # DEBUG: Listar os arquivos do backup
            echo ""
            log_info "DEBUG: Listagem dos arquivos no backup:"
            find "$SOURCE_KEYS" -type f 2>/dev/null | while read key_file; do
                log_info "  - $(basename $key_file) ($(stat -c%s "$key_file") bytes)"
            done
            echo ""
        else
            log_warning "⚠️  Diretório encontrado no backup mas está VAZIO!"
        fi
    else
        log_warning "❌ Nenhum diretório de chaves SSH encontrado no backup"
    fi
fi

echo ""
# Resultado final
if [ -z "$SOURCE_KEYS" ] || [ $KEYS_COUNT -eq 0 ]; then
    log_error "❌ NENHUMA CHAVE SSH ENCONTRADA!"
    log_error "Verificado em:"
    log_error "  1. Sistema local: /data/coolify/ssh/keys"
    log_error "  2. Backup extraído: $TEMP_EXTRACT_DIR"
    echo ""
    log_warning "⚠️  IMPORTANTE: Você está executando o script no SERVIDOR DE ORIGEM?"
    log_warning "O servidor de origem deve ter chaves em: /data/coolify/ssh/keys"
    log_warning "As chaves SSH serão necessárias após o Final Install"
    echo ""
else
    log_success "✅ Total de chaves encontradas: $KEYS_COUNT arquivos"
    log_success "✅ Fonte: $SOURCE_KEYS"

    # Se as chaves estão no backup, copiar para temp local antes de limpar
    if [[ "$SOURCE_KEYS" == "$TEMP_EXTRACT_DIR"* ]]; then
        TEMP_KEYS_BACKUP="/tmp/coolify-ssh-keys-$$"
        log_info "📦 Criando backup temporário das chaves..."
        mkdir -p "$TEMP_KEYS_BACKUP"

        cp -rv "$SOURCE_KEYS"/. "$TEMP_KEYS_BACKUP/" 2>&1 | grep -v "^$"

        if [ $? -eq 0 ]; then
            SOURCE_KEYS="$TEMP_KEYS_BACKUP"
            log_success "📦 Chaves copiadas para backup temporário: $SOURCE_KEYS"

            # Verificar se a cópia funcionou
            TEMP_KEYS_COUNT=$(find "$TEMP_KEYS_BACKUP" -type f 2>/dev/null | wc -l)
            log_info "   Arquivos no backup temporário: $TEMP_KEYS_COUNT"
        else
            log_error "❌ Falha ao criar backup temporário das chaves!"
        fi
    fi
fi
echo ""
# ==============================================================================
# FIM DA DETECÇÃO DE CHAVES SSH
# ==============================================================================

# ==============================================================================
# DETECÇÃO DE CONFIGURAÇÕES DO PROXY (salvar para usar após Final Install)
# ==============================================================================
log_info "🔍 Verificando configurações do proxy..."

PROXY_SOURCE=""
PROXY_CERTS_COUNT=0
PROXY_CONFIGS_COUNT=0
PROXY_RESTORE="n"

if [ -d "$TEMP_EXTRACT_DIR/proxy-config" ]; then
    # Verificar se há arquivos realmente customizados
    PROXY_CERTS_COUNT=$(find "$TEMP_EXTRACT_DIR/proxy-config" -name "*.crt" -o -name "*.pem" -o -name "*.key" 2>/dev/null | wc -l)
    PROXY_CONFIGS_COUNT=$(find "$TEMP_EXTRACT_DIR/proxy-config" -name "*.conf" -o -name "*.toml" -o -name "*.yaml" 2>/dev/null | wc -l)

    if [ $PROXY_CERTS_COUNT -gt 0 ] || [ $PROXY_CONFIGS_COUNT -gt 0 ]; then
        echo ""
        log_warning "Configurações personalizadas de proxy detectadas!"
        echo ""
        echo "Foram encontradas:"
        echo "  - $PROXY_CERTS_COUNT certificado(s) SSL/TLS"
        echo "  - $PROXY_CONFIGS_COUNT arquivo(s) de configuração"
        echo ""
        echo "Isso pode incluir:"
        echo "  • Cloudflare Origin Certificates"
        echo "  • Certificados SSL personalizados"
        echo "  • Configurações de proxy/middleware"
        echo ""

        if [ "$AUTO_MODE" = false ]; then
            read -p "Deseja restaurar essas configurações no servidor novo? (s/N): " PROXY_RESTORE
            PROXY_RESTORE=${PROXY_RESTORE:-n}
        fi

        if [[ "$PROXY_RESTORE" =~ ^[Ss]$ ]]; then
            # Copiar para temp local antes de limpar o backup
            TEMP_PROXY_BACKUP="/tmp/coolify-proxy-$$"
            log_info "📦 Criando backup temporário das configurações do proxy..."
            mkdir -p "$TEMP_PROXY_BACKUP"
            cp -r "$TEMP_EXTRACT_DIR/proxy-config"/. "$TEMP_PROXY_BACKUP/" 2>/dev/null

            if [ $? -eq 0 ]; then
                PROXY_SOURCE="$TEMP_PROXY_BACKUP"
                log_success "✅ Configurações do proxy salvas para transferência posterior"
                log_info "   Certificados: $PROXY_CERTS_COUNT | Configs: $PROXY_CONFIGS_COUNT"
            else
                log_error "❌ Falha ao criar backup temporário do proxy"
            fi
        else
            log_info "Configurações do proxy não serão restauradas (usando padrões do Coolify)"
        fi
    else
        log_info "Nenhuma configuração personalizada de proxy detectada (usando padrões)"
    fi
else
    log_info "Nenhum diretório proxy-config encontrado no backup"
fi
echo ""
# ==============================================================================
# FIM DA DETECÇÃO DO PROXY
# ==============================================================================

# Limpar diretório temporário
rm -rf "$TEMP_EXTRACT_DIR"

### ========== STOP CONTAINERS ==========
log_section "Stop Containers"
log_info "Stopping all Coolify containers except database..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "docker ps --filter name=coolify --format '{{.Names}}' | grep -v 'coolify-db' | xargs -r docker stop" >/dev/null 2>&1
check_success $? "Containers stopped."

### ========== RESTORE DATABASE ==========
log_section "Restore Database"
log_info "Restoring Coolify database (this may take a few minutes)..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "cat $REMOTE_BACKUP_DIR/db-dump.dmp | docker exec -i coolify-db pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify" \
    >"$DB_RESTORE_LOG" 2>&1

if [ $? -eq 0 ] || grep -q "processing data for table" "$DB_RESTORE_LOG"; then
    log_success "Database restore completed."
else
    log_warning "Database restore may have encountered issues. Check $DB_RESTORE_LOG"
fi

### ========== FINAL INSTALL ==========
log_section "Final Install"
log_info "Running final Coolify install to apply all changes..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash -s $COOLIFY_VERSION" \
    >"$FINAL_INSTALL_LOG" 2>&1 &

log_info "Waiting for installation to complete (max 5 minutes)..."
for i in {1..30}; do
    sleep 10
    if grep -q "Your instance is ready to use" "$FINAL_INSTALL_LOG"; then
        log_success "Coolify installation completed successfully."
        break
    fi
done

### ========== UPDATE APP_KEY (AFTER FINAL INSTALL) ==========
log_section "Update APP_KEY"
log_info "⚠️  CRÍTICO: Configurando APP_KEY do backup no .env..."
echo ""
log_info "APP_KEY é usado para criptografar dados sensíveis:"
log_info "  • Senhas de servidores"
log_info "  • Tokens de API (GitHub, GitLab, etc.)"
log_info "  • Chaves privadas de deploy"
log_info "  • Credenciais de banco de dados"
echo ""

# Verificar se .env existe
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "test -f /data/coolify/source/.env"

if [ $? -eq 0 ]; then
    log_info "Arquivo .env encontrado. Atualizando com APP_KEY do backup..."

    # Atualizar APP_KEY no .env
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "cd /data/coolify/source && sed -i '/^APP_PREVIOUS_KEYS=/d' .env && echo \"APP_PREVIOUS_KEYS=$APP_KEY\" >> .env"

    if [ $? -eq 0 ]; then
        log_success "✅ APP_KEY configurado com sucesso!"

        # Verificar se foi aplicado
        APPLIED_KEY=$(ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "grep '^APP_PREVIOUS_KEYS=' /data/coolify/source/.env | cut -d'=' -f2-")

        if [ -n "$APPLIED_KEY" ]; then
            log_success "✅ APP_KEY verificado no .env"
            log_info "   Primeiros 20 caracteres: ${APPLIED_KEY:0:20}..."
        else
            log_error "❌ APP_KEY não encontrado após configuração!"
        fi
    else
        log_error "❌ Falha ao configurar APP_KEY!"
        log_warning "Dados criptografados podem não ser acessíveis!"
    fi
else
    log_error "❌ Arquivo .env não encontrado em /data/coolify/source/"
    log_warning "APP_KEY não pode ser configurado. O Coolify pode não funcionar corretamente."
fi
echo ""

### ========== TRANSFER SSH KEYS (AFTER FINAL INSTALL) ==========
log_section "Transfer SSH Keys"

log_info "DEBUG: Verificando variáveis de estado..."
log_info "  SOURCE_KEYS: ${SOURCE_KEYS:-<vazio>}"
log_info "  KEYS_COUNT: ${KEYS_COUNT:-0}"

if [ -n "$SOURCE_KEYS" ] && [ -d "$SOURCE_KEYS" ]; then
    log_success "✅ Chaves SSH disponíveis para transferência!"
    log_info "   Origem: $SOURCE_KEYS"
    log_info "   Total: $KEYS_COUNT arquivos"
    echo ""

    # DEBUG: Listar novamente antes de transferir
    log_info "DEBUG: Arquivos que serão transferidos:"
    find "$SOURCE_KEYS" -type f 2>/dev/null | while read key_file; do
        log_info "  - $(basename $key_file)"
    done
    echo ""

    # Criar diretório remoto (garantir que existe)
    log_info "Criando diretório remoto: /data/coolify/ssh/keys"
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "mkdir -p /data/coolify/ssh/keys" 2>/dev/null
    check_success $? "Diretório criado no servidor remoto"

    # Transferir chaves (usando /. para incluir arquivos ocultos)
    log_info "Iniciando transferência via SCP..."
    echo ""

    # Transferir com verbose para debug
    scp -o ControlPath="$CONTROL_SOCKET" -P "$NEW_SERVER_PORT" -r \
        "$SOURCE_KEYS"/. "$NEW_SERVER_USER@$NEW_SERVER_IP:/data/coolify/ssh/keys/" 2>&1

    SCP_EXIT_CODE=$?
    echo ""

    if [ $SCP_EXIT_CODE -eq 0 ]; then
        log_success "✅ Comando SCP executado com sucesso!"

        # IMEDIATAMENTE após transferir, configurar permissões corretas
        log_info "Configurando permissões imediatamente após transferência..."
        ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "chown -R 9999:9999 /data/coolify/ssh/keys && \
             chmod 700 /data/coolify/ssh/keys && \
             find /data/coolify/ssh/keys -type f -exec chmod 600 {} \;" 2>/dev/null
        check_success $? "Permissões configuradas (9999:9999, 600)"

        # Verificar quantos arquivos foram transferidos
        log_info "Verificando arquivos no servidor remoto..."
        TRANSFERRED_COUNT=$(ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "find /data/coolify/ssh/keys -type f 2>/dev/null | wc -l")

        if [ "$TRANSFERRED_COUNT" -gt 0 ]; then
            log_success "✅ Chaves SSH transferidas com sucesso!"
            log_success "   Arquivos no servidor remoto: $TRANSFERRED_COUNT"

            # Listar arquivos transferidos com permissões corretas
            echo ""
            log_info "Arquivos no servidor remoto (com permissões corretas):"
            ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
                "ls -lh /data/coolify/ssh/keys" 2>/dev/null | tail -n +2 | while read line; do
                log_info "  $line"
            done
            echo ""
        else
            log_error "❌ SCP executou mas NENHUM arquivo foi transferido!"
            log_warning "Verificando diretório remoto:"
            ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
                "ls -la /data/coolify/ssh/keys" 2>/dev/null
        fi

        # Limpar backup temporário se foi criado
        if [[ "$SOURCE_KEYS" == "/tmp/coolify-ssh-keys-"* ]]; then
            rm -rf "$SOURCE_KEYS"
            log_info "Backup temporário removido: $SOURCE_KEYS"
        fi
    else
        log_error "❌ Falha ao transferir chaves SSH (Exit code: $SCP_EXIT_CODE)"
        log_warning "As aplicações podem não conseguir se conectar via SSH aos servidores"
    fi
else
    log_warning "❌ Nenhuma chave SSH disponível para transferência"
    echo ""
    log_warning "Estado das variáveis:"
    log_warning "  SOURCE_KEYS: ${SOURCE_KEYS:-<vazio>}"
    log_warning "  KEYS_COUNT: ${KEYS_COUNT:-0}"
    log_warning "  Diretório existe? $([ -d "$SOURCE_KEYS" ] && echo 'SIM' || echo 'NÃO')"
    echo ""
    log_warning "⚠️  IMPORTANTE: Sem chaves SSH, o Coolify não conseguirá se conectar aos servidores"
    log_warning "Você precisará:"
    log_warning "  1. Verificar se está executando no SERVIDOR DE ORIGEM correto"
    log_warning "  2. Copiar manualmente: scp -r /data/coolify/ssh/keys/* root@$NEW_SERVER_IP:/data/coolify/ssh/keys/"
    log_warning "  3. Ou regenerar as chaves no Coolify (Settings > SSH Keys)"
    echo ""
fi

### ========== TRANSFER PROXY CONFIGS (AFTER FINAL INSTALL) ==========
if [ -n "$PROXY_SOURCE" ] && [ -d "$PROXY_SOURCE" ]; then
    log_section "Transfer Proxy Configurations"

    log_info "Transferindo configurações do proxy..."
    log_info "  Origem: $PROXY_SOURCE"
    log_info "  Certificados: $PROXY_CERTS_COUNT"
    log_info "  Configs: $PROXY_CONFIGS_COUNT"
    echo ""

    # Criar diretório remoto
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "mkdir -p /data/coolify/proxy" 2>/dev/null

    # Transferir configurações do proxy
    scp -o ControlPath="$CONTROL_SOCKET" -P "$NEW_SERVER_PORT" -r \
        "$PROXY_SOURCE"/. "$NEW_SERVER_USER@$NEW_SERVER_IP:/data/coolify/proxy/" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        # Configurar permissões corretas
        ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "chown -R 9999:9999 /data/coolify/proxy && chmod -R 755 /data/coolify/proxy" 2>/dev/null

        log_success "✅ Configurações do proxy transferidas!"
        log_info "   Certificados: $PROXY_CERTS_COUNT | Configs: $PROXY_CONFIGS_COUNT"

        # Verificar no servidor remoto
        PROXY_FILES_COUNT=$(ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "find /data/coolify/proxy -type f 2>/dev/null | wc -l")
        log_info "   Arquivos no servidor remoto: $PROXY_FILES_COUNT"

        # Limpar backup temporário
        rm -rf "$PROXY_SOURCE"
        log_info "Backup temporário do proxy removido"
    else
        log_error "❌ Falha ao transferir configurações do proxy"
        log_warning "Certificados SSL e configs personalizadas podem não estar disponíveis"
    fi
    echo ""
else
    if [[ "$PROXY_RESTORE" =~ ^[Ss]$ ]]; then
        log_warning "⚠️  Proxy deveria ser restaurado mas SOURCE não está disponível"
    fi
fi

### ========== TRANSFER AUTHORIZED_KEYS (AFTER FINAL INSTALL) ==========
log_section "Transfer Authorized Keys"

if [ -f "$LOCAL_AUTH_KEYS_FILE" ]; then
    log_info "Transferindo authorized_keys do servidor local para o remoto..."
    log_info "  Arquivo local: $LOCAL_AUTH_KEYS_FILE"
    log_info "  Destino remoto: $NEW_SERVER_AUTH_KEYS_FILE"
    echo ""

    # Criar diretório, arquivo e copiar chaves (tudo em um comando)
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "mkdir -p $(dirname $NEW_SERVER_AUTH_KEYS_FILE) && touch $NEW_SERVER_AUTH_KEYS_FILE && cat >> $NEW_SERVER_AUTH_KEYS_FILE" \
        < "$LOCAL_AUTH_KEYS_FILE"

    if [ $? -eq 0 ]; then
        # Configurar permissões corretas (CRÍTICO para SSH funcionar)
        ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "chmod 700 $(dirname $NEW_SERVER_AUTH_KEYS_FILE) && chmod 600 $NEW_SERVER_AUTH_KEYS_FILE" 2>/dev/null

        log_success "✅ Authorized keys transferidas com sucesso!"

        # Verificar quantas chaves foram adicionadas
        KEYS_IN_FILE=$(ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "wc -l < $NEW_SERVER_AUTH_KEYS_FILE 2>/dev/null" | tr -d ' ')
        log_info "   Total de chaves no arquivo remoto: $KEYS_IN_FILE"
    else
        log_error "❌ Falha ao transferir authorized_keys"
        log_warning "Você pode precisar configurar acesso SSH manualmente"
    fi
    echo ""
else
    log_warning "⚠️  Arquivo authorized_keys local não encontrado: $LOCAL_AUTH_KEYS_FILE"
    log_warning "Acesso SSH futuro pode precisar ser configurado manualmente"
    echo ""
fi

# Re-configurar permissões das SSH keys após o install (CRÍTICO)
log_info "Re-configuring SSH keys permissions after install..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "chown -R 9999:9999 /data/coolify/ssh/keys 2>/dev/null && \
     chmod 700 /data/coolify/ssh/keys 2>/dev/null && \
     find /data/coolify/ssh/keys -type f -exec chmod 600 {} \; 2>/dev/null"
log_success "SSH keys permissions re-configured."

# Reiniciar Coolify para forçar re-validação das chaves SSH
log_info "Restarting Coolify to reload SSH keys..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "docker restart coolify 2>/dev/null || true"
sleep 10  # Aguardar Coolify reiniciar
log_success "Coolify restarted."

# VERIFICAÇÃO CRÍTICA: Confirmar que chaves SSH ainda existem após restart
log_info "Verificando se chaves SSH persistiram após restart do Coolify..."
KEYS_AFTER_RESTART=$(ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "find /data/coolify/ssh/keys -type f 2>/dev/null | wc -l")

if [ "$KEYS_AFTER_RESTART" -gt 0 ]; then
    log_success "✅ Chaves SSH verificadas após restart: $KEYS_AFTER_RESTART arquivos"

    # Mostrar detalhes das chaves
    echo ""
    log_info "Chaves SSH finais (após restart):"
    ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
        "ls -lh /data/coolify/ssh/keys" 2>/dev/null | tail -n +2 | while read line; do
        log_info "  $line"
    done
    echo ""
else
    log_error "❌ CRÍTICO: Chaves SSH DESAPARECERAM após restart do Coolify!"
    log_error "Isso pode indicar:"
    log_error "  1. Volume Docker não está persistindo os dados"
    log_error "  2. Coolify está recriando/limpando o diretório"
    log_error "  3. Permissões incorretas impedem o acesso"
    echo ""
    log_warning "Tentando recriar as chaves..."

    # Tentar transferir novamente
    if [ -n "$SOURCE_KEYS" ] && [ -d "$SOURCE_KEYS" ]; then
        scp -o ControlPath="$CONTROL_SOCKET" -P "$NEW_SERVER_PORT" -r \
            "$SOURCE_KEYS"/. "$NEW_SERVER_USER@$NEW_SERVER_IP:/data/coolify/ssh/keys/" >/dev/null 2>&1

        ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "chown -R 9999:9999 /data/coolify/ssh/keys && \
             chmod 700 /data/coolify/ssh/keys && \
             find /data/coolify/ssh/keys -type f -exec chmod 600 {} \;" 2>/dev/null

        # Verificar novamente
        RETRY_COUNT=$(ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
            "find /data/coolify/ssh/keys -type f 2>/dev/null | wc -l")

        if [ "$RETRY_COUNT" -gt 0 ]; then
            log_success "✅ Chaves SSH restauradas com sucesso!"
        else
            log_error "❌ Falha ao restaurar chaves SSH"
        fi
    fi
fi

# Verificar status dos containers
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "docker ps --filter name=coolify --format '{{.Names}} {{.Status}}'" \
    > "$MIGRATION_LOG_DIR/docker-status.txt"

if grep -q "coolify" "$MIGRATION_LOG_DIR/docker-status.txt" && grep -q "healthy" "$MIGRATION_LOG_DIR/docker-status.txt"; then
    log_success "Coolify containers are running and healthy."
elif grep -q "coolify" "$MIGRATION_LOG_DIR/docker-status.txt"; then
    log_success "Coolify containers are running."
    cat "$MIGRATION_LOG_DIR/docker-status.txt" | while read line; do
        log_info "Container: $line"
    done
else
    log_error "Coolify containers are not running properly."
    log_info "Check logs in $MIGRATION_LOG_DIR for details."
    cleanup_and_exit 1
fi

### ========== CLEANUP ==========
log_info "Cleaning up temporary files on remote server..."
ssh -S "$CONTROL_SOCKET" "$NEW_SERVER_USER@$NEW_SERVER_IP" \
    "rm -rf $REMOTE_BACKUP_DIR" 2>/dev/null

### ========== FINAL SUMMARY ==========
echo ""
log_section "MIGRATION COMPLETE"
echo ""
echo "  🎉 Coolify has been migrated successfully!"
echo ""
echo "  📍 New server: http://$NEW_SERVER_IP:8000"
echo "  📊 Container status: See $MIGRATION_LOG_DIR/docker-status.txt"
echo "  📋 All logs: $MIGRATION_LOG_DIR/"
echo ""
echo "  ⚠️  NEXT STEPS:"
echo "  1. Update DNS records to point to $NEW_SERVER_IP"
echo "  2. Test Coolify access: http://$NEW_SERVER_IP:8000"
echo "  3. Verify all applications are running"
echo "  4. Configure backup scripts on new server"
echo ""

### ========== OFERECER MIGRAÇÃO DE VOLUMES/APPS ==========
echo ""
log_section "MIGRATE APPLICATION VOLUMES?"
echo ""
echo "  Coolify has been migrated successfully!"
echo "  Do you want to migrate your application volumes/data now?"
echo ""
echo "  This will:"
echo "    • List all Docker volumes on the current server"
echo "    • Let you select which volumes to migrate"
echo "    • Transfer and restore them on $NEW_SERVER_IP"
echo ""
read -p "  Migrate application volumes? (yes/no): " MIGRATE_VOLUMES

if [ "$MIGRATE_VOLUMES" = "yes" ] || [ "$MIGRATE_VOLUMES" = "y" ]; then
    echo ""
    log_info "Starting volume migration process..."
    echo ""

    # Verificar se o script de migração de volumes existe
    VOLUME_MIGRATION_SCRIPT="$SCRIPT_DIR/migrar-volumes.sh"

    if [ ! -f "$VOLUME_MIGRATION_SCRIPT" ]; then
        log_error "Volume migration script not found: $VOLUME_MIGRATION_SCRIPT"
        log_info "You can run it manually later from: $SCRIPT_DIR/migrar-volumes.sh"
    elif [ ! -x "$VOLUME_MIGRATION_SCRIPT" ]; then
        log_error "Volume migration script is not executable"
        log_info "Run: chmod +x $VOLUME_MIGRATION_SCRIPT"
    else
        # Exportar variáveis para o script de migração de volumes
        export NEW_SERVER_IP
        export NEW_SERVER_USER
        export NEW_SERVER_PORT
        export SSH_PRIVATE_KEY_PATH
        export CONTROL_SOCKET
        export SSH_AUTH_METHOD="key"  # Coolify sempre usa chave SSH
        export COOLIFY_MIGRATION="true"  # Flag para indicar que vem do Coolify

        # Executar script de migração de volumes
        log_info "Launching volume migration script..."
        log_info "Reusing SSH connection from Coolify migration..."
        echo ""

        # Executar em subshell para não interferir com o cleanup atual
        (
            cd "$SCRIPT_DIR"
            exec ./migrar-volumes.sh
        )

        VOLUME_MIGRATION_EXIT_CODE=$?

        echo ""
        if [ $VOLUME_MIGRATION_EXIT_CODE -eq 0 ]; then
            log_success "Volume migration completed successfully!"
        else
            log_warning "Volume migration exited with code: $VOLUME_MIGRATION_EXIT_CODE"
            log_info "Check logs for details"
        fi
    fi
else
    log_info "Volume migration skipped."
    echo ""
    echo "  You can migrate volumes later by running:"
    echo "  $SCRIPT_DIR/migrar-volumes.sh"
    echo ""
fi

cleanup_and_exit 0
