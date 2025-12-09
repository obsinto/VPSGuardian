#!/bin/bash
################################################################################
# Script: backup-website.sh
# Propósito: Fazer backup de sites (Next.js, React, etc) em múltiplos formatos
# Uso: ./backup-website.sh [URL]
################################################################################

# Carregar bibliotecas compartilhadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

### ========== CONFIGURAÇÃO ==========
OUTPUT_DIR="${HOME}/Backups/coolify-docs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

### ========== FUNÇÕES ==========

check_dependencies() {
    local missing=()

    if ! command -v wkhtmltopdf &> /dev/null; then
        missing+=("wkhtmltopdf")
    fi

    if ! command -v node &> /dev/null; then
        missing+=("nodejs")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_warning "Dependências faltando: ${missing[*]}"
        echo ""
        read -p "Instalar dependências agora? (yes/no): " install

        if [ "$install" = "yes" ]; then
            log_info "Instalando dependências..."
            sudo apt update

            if [[ " ${missing[*]} " =~ " wkhtmltopdf " ]]; then
                sudo apt install -y wkhtmltopdf
            fi

            if [[ " ${missing[*]} " =~ " nodejs " ]]; then
                sudo apt install -y nodejs npm
            fi

            # Instalar Playwright
            if [ -f "$SCRIPT_DIR/backup-website-playwright.js" ]; then
                log_info "Instalando Playwright..."
                cd "$SCRIPT_DIR"
                npm install playwright
            fi
        else
            log_error "Dependências necessárias não instaladas"
            exit 1
        fi
    fi
}

backup_as_pdf() {
    local url="$1"
    local output_file="$2"

    log_info "Salvando como PDF: $(basename $output_file)"

    wkhtmltopdf \
        --enable-local-file-access \
        --javascript-delay 3000 \
        --no-stop-slow-scripts \
        --print-media-type \
        "$url" "$output_file" >/dev/null 2>&1

    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        local size=$(du -h "$output_file" | cut -f1)
        log_success "PDF criado: $(basename $output_file) ($size)"
        return 0
    else
        log_error "Falha ao criar PDF"
        return 1
    fi
}

backup_with_playwright() {
    log_info "Usando Playwright para backup completo..."

    if [ ! -f "$SCRIPT_DIR/backup-website-playwright.js" ]; then
        log_error "Script Playwright não encontrado"
        return 1
    fi

    cd "$SCRIPT_DIR"

    # Verificar se Playwright está instalado
    if [ ! -d "node_modules/playwright" ]; then
        log_info "Instalando Playwright..."
        npm install playwright >/dev/null 2>&1
    fi

    node backup-website-playwright.js

    if [ $? -eq 0 ]; then
        log_success "Backup Playwright concluído"
        return 0
    else
        log_error "Falha no backup Playwright"
        return 1
    fi
}

### ========== MAIN ==========
log_section "VPS Guardian - Backup de Website"

# Criar diretório de saída
mkdir -p "$OUTPUT_DIR"

# Verificar dependências
check_dependencies

echo ""
log_info "Opções de backup disponíveis:"
echo ""
echo "  [1] Backup automático (Playwright) - Recomendado"
echo "      • HTML renderizado + PDF + Screenshot"
echo "      • Funciona com Next.js/React"
echo ""
echo "  [2] PDF simples (wkhtmltopdf)"
echo "      • Apenas PDF"
echo "      • Mais rápido"
echo ""
echo "  [3] Ambos"
echo ""

read -p "Escolha uma opção (1-3): " option

case $option in
    1)
        backup_with_playwright
        ;;
    2)
        # URLs principais do Coolify
        urls=(
            "https://envix.shadowarcanist.com/coolify/tutorials/migrate-apps-different-host/"
            "https://envix.shadowarcanist.com/coolify/tutorials/aws-s3-backup-setup/"
        )

        for url in "${urls[@]}"; do
            # Extrair nome do arquivo da URL
            filename=$(echo "$url" | sed 's|https://||' | sed 's|/|-|g' | sed 's/-$//')
            output_file="$OUTPUT_DIR/${filename}-${TIMESTAMP}.pdf"

            backup_as_pdf "$url" "$output_file"
        done
        ;;
    3)
        backup_with_playwright

        echo ""
        log_info "Criando PDFs adicionais..."

        urls=(
            "https://envix.shadowarcanist.com/coolify/tutorials/migrate-apps-different-host/"
            "https://envix.shadowarcanist.com/coolify/tutorials/aws-s3-backup-setup/"
        )

        for url in "${urls[@]}"; do
            filename=$(echo "$url" | sed 's|https://||' | sed 's|/|-|g' | sed 's/-$//')
            output_file="$OUTPUT_DIR/${filename}-${TIMESTAMP}.pdf"
            backup_as_pdf "$url" "$output_file"
        done
        ;;
    *)
        log_error "Opção inválida"
        exit 1
        ;;
esac

# Resumo
echo ""
log_section "RESUMO DO BACKUP"
echo ""
echo "  📁 Diretório: $OUTPUT_DIR"
echo ""
echo "  📄 Arquivos criados:"
ls -lh "$OUTPUT_DIR" | tail -n +2 | awk '{printf "     • %s (%s)\n", $9, $5}'
echo ""

log_success "Backup de website concluído"
