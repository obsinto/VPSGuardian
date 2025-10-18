
1. ✅ **Updates de segurança automáticos** - Sistema protegido contra CVEs
2. ✅ **Limpeza semanal automatizada** - Disco sempre otimizado
3. ✅ **Backup completo do Coolify** - Banco de dados, SSH keys, configurações
4. ✅ **Monitoramento contínuo** - Alertas quando algo está errado
5. ✅ **Logs detalhados** - Troubleshooting facilitado
6. ✅ **Procedimentos de recuperação** - Disaster recovery documentado
7. ✅ **Zero intervenção diária** - Apenas revisão mensal

# Comparação: Antes vs Depois

|Aspecto|Antes (sem manutenção)|Depois (sistema completo)|
|---|---|---|
|**Segurança**|Vulnerável a CVEs conhecidas|Updates automáticos diários|
|**Espaço em disco**|Acumula lixo indefinidamente|Limpeza semanal automática|
|**Backups**|❌ Nenhum|✅ Semanal + retenção 30 dias|
|**Recuperação**|Impossível sem backup|Restauração documentada|
|**Monitoramento**|Manual, quando lembra|Automático com alertas|
|**Intervenção**|Frequente e reativa|Rara e preventiva|
|**Confiança**|😰 Ansiedade constante|😎 Tranquilidade|

# Calendário de atividades

|Atividade|Automático|Manual|
|---|---|---|
|**Diário**|Updates de segurança, Verificação de disco|-|
|**Semanal**|Backup do Coolify, Limpeza de Docker/sistema|Rodar `status-completo`|
|**Mensal**|Rotação de logs|Revisar relatórios, testar aplicações|
|**Trimestral**|-|Testar restauração de backup|
|**Annual**|-|Considerar upgrade de versão|

# TL;DR - Commandos essenciais

```bash
# ========== INSTALAÇÃO COMPLETA ==========

# 1. Instalar dependências
sudo apt update && sudo apt install unattended-upgrades apt-listchanges -y

# 2. Criar estrutura de diretórios
sudo mkdir -p /opt/manutencao /var/log/manutencao /root/coolify-backups

# 3. Criar script de manutenção
sudo nano /opt/manutencao/manutencao-completa.sh
# [Cole o script de manutenção]
sudo chmod +x /opt/manutencao/manutencao-completa.sh

# 4. Criar script de backup
sudo nano /opt/manutencao/backup-coolify.sh
# [Cole o script de backup]
sudo chmod +x /opt/manutencao/backup-coolify.sh

# 5. Criar script de alerta
sudo nano /opt/manutencao/alerta-disco.sh
# [Cole o script de alerta]
sudo chmod +x /opt/manutencao/alerta-disco.sh

# 6. Criar script de status
sudo nano /usr/local/bin/status-completo
# [Cole o script de status]
sudo chmod +x /usr/local/bin/status-completo

# 7. Configurar unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
# [Configure conforme o guia]

# 8. Agendar tudo no cron
sudo crontab -e
# [Adicione as linhas do cron]

# 9. Testar tudo
sudo /opt/manutencao/backup-coolify.sh
sudo /opt/manutencao/manutencao-completa.sh
status-completo

# ========== USO DIÁRIO ==========

# Ver status geral
status-completo

# Ver logs
tail -100 /var/log/manutencao/manutencao.log
tail -100 /var/log/manutencao/backup-coolify.log

# Forçar backup manual
sudo /opt/manutencao/backup-coolify.sh

# Forçar manutenção manual
sudo /opt/manutencao/manutencao-completa.sh

# Ver backups existentes
ls -lh /root/coolify-backups/

# Restaurar backup (emergência)
cd /root/coolify-backups
tar -xzf [ultimo-backup].tar.gz
cat */backup-info.txt
# Seguir instruções
```

# Recursos para aprender mais

- [Documentação oficial do Coolify](https://coolify.io/docs)
- [Unattended Upgrades - Debian Wiki](https://wiki.debian.org/UnattendedUpgrades)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Guia de segurança Ubuntu](https://ubuntu.com/security)
- [PostgreSQL Backup & Recovery](https://www.postgresql.org/docs/current/backup.html)

# Checklist final de segurança

Antes de considerar o sistema "pronto para produção":

- [ ] ✅ Backups automáticos funcionando
- [ ] ✅ Testei restauração de backup (CRÍTICO!)
- [ ] ✅ Updates de segurança automáticos ativos
- [ ] ✅ Limpeza automática agendada
- [ ] ✅ Alertas configurados (email/webhook)
- [ ] ✅ Firewall configurado (UFW)
- [ ] ✅ Fail2ban instalado (proteção SSH)
- [ ] ✅ Backup off-site configurado (S3/remoto)
- [ ] ✅ Documentação salva em local seguro
- [ ] ✅ Runbook de emergência impresso
- [ ] ✅ Credenciais em gerenciador de senhas
- [ ] ✅ Revisão mensal agendada no calendário

# Sua jornada de manutenção

```
┌─────────────────────────────────────────────┐
│  ANTES: "Set and Forget" Perigoso          │
├─────────────────────────────────────────────┤
│  ❌ Sem updates de segurança                │
│  ❌ Disco enchendo progressivamente          │
│  ❌ Zero backups                             │
│  ❌ Recuperação impossível                   │
│  ❌ Ansiedade constante                      │
└─────────────────────────────────────────────┘
                    ⬇️
┌─────────────────────────────────────────────┐
│  AGORA: "Set and Monitor" Inteligente      │
├─────────────────────────────────────────────┤
│  ✅ Updates automáticos diários              │
│  ✅ Limpeza semanal automática               │
│  ✅ Backups semanais + retenção 30 dias      │
│  ✅ Restauração testada e documentada        │
│  ✅ Tranquilidade e confiança                │
└─────────────────────────────────────────────┘
                    ⬇️
┌─────────────────────────────────────────────┐
│  FUTURO: Evolução contínua                 │
├─────────────────────────────────────────────┤
│  🎯 Backup incremental                       │
│  🎯 Monitoramento avançado (Grafana)         │
│  🎯 Alta disponibilidade (múltiplos VPS)     │
│  🎯 CI/CD automatizado                       │
└─────────────────────────────────────────────┘
```

---

# 📚 Apêndices

## Apêndice A: Variáveis de configuração

Centralize todas as configurações editáveis:

```bash
# /opt/manutencao/config.env
# Fonte este arquivo em todos os scripts: source /opt/manutencao/config.env

# === NOTIFICAÇÕES ===
EMAIL="seu-email@exemplo.com"
WEBHOOK_DISCORD="https://discord.com/api/webhooks/..."
WEBHOOK_SLACK="https://hooks.slack.com/services/..."
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# === BACKUP ===
BACKUP_BASE_DIR="/root/coolify-backups"
BACKUP_RETENTION_DAYS=30
COMPRESS_LEVEL=6  # 1-9, quanto maior mais compactação

# === REMOTE BACKUP ===
REMOTE_ENABLED=false
REMOTE_SERVER="backup-server.exemplo.com"
REMOTE_USER="root"
REMOTE_DIR="/backups/coolify"

# === S3 BACKUP ===
S3_ENABLED=false
S3_BUCKET="s3://meu-bucket/coolify"
S3_REGION="us-east-1"

# === MANUTENÇÃO ===
DISCO_LIMITE=85  # Alerta se disco > 85%
MANTER_KERNELS=2
VOLUMES_BACKUP_ENABLED=false  # Muito espaço, ativar com cuidado

# === COOLIFY ===
COOLIFY_DATA_DIR="/data/coolify"
COOLIFY_SOURCE_DIR="$COOLIFY_DATA_DIR/source"
COOLIFY_SSH_DIR="$COOLIFY_DATA_DIR/ssh/keys"

# === HEALTHCHECKS ===
HEALTHCHECK_MANUTENCAO=""  # URL do healthchecks.io
HEALTHCHECK_BACKUP=""
```

**Como usar:**

```bash
# No início de cada script, adicione:
source /opt/manutencao/config.env
```

## Apêndice B: Logs estruturados (JSON)

Para integração com ferramentas de log analytics:

```bash
# Função para log em JSON
log_json() {
    local nivel="$1"
    local mensagem="$2"
    local extra="$3"
    
    cat >> "$LOG_FILE" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hostname": "$(hostname)",
  "level": "$nivel",
  "message": "$mensagem",
  "extra": $extra
}
EOF
}

# Uso:
log_json "INFO" "Backup iniciado" '{"tipo":"completo"}'
log_json "ERROR" "Falha no backup" '{"erro":"disk_full","disco_uso":"95%"}'
```

## Apêndice C: Métricas e dashboards

Expor métricas para Prometheus/Grafana:

```bash
#!/bin/bash
# /opt/manutencao/export-metrics.sh

METRICS_FILE="/var/www/html/metrics.txt"

cat > "$METRICS_FILE" <<EOF
# HELP vps_disk_usage_percent Disk usage percentage
# TYPE vps_disk_usage_percent gauge
vps_disk_usage_percent $(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# HELP vps_memory_usage_percent Memory usage percentage
# TYPE vps_memory_usage_percent gauge
vps_memory_usage_percent $(free | grep Mem | awk '{print int($3/$2 * 100)}')

# HELP vps_last_backup_timestamp Last successful backup timestamp
# TYPE vps_last_backup_timestamp gauge
vps_last_backup_timestamp $(stat -c %Y /root/coolify-backups/*.tar.gz 2>/dev/null | sort -n | tail -1)

# HELP vps_backup_size_bytes Last backup size in bytes
# TYPE vps_backup_size_bytes gauge
vps_backup_size_bytes $(ls -l /root/coolify-backups/*.tar.gz 2>/dev/null | tail -1 | awk '{print $5}')

# HELP docker_containers_running Number of running containers
# TYPE docker_containers_running gauge
docker_containers_running $(docker ps -q | wc -l)

# HELP coolify_status Coolify container status (1=running, 0=stopped)
# TYPE coolify_status gauge
coolify_status $(docker ps --filter name=coolify --format '{{.Names}}' | grep -q coolify && echo 1 || echo 0)
EOF

chmod 644 "$METRICS_FILE"
```

**Configurar Nginx para expor:**

```nginx
# /etc/nginx/sites-available/metrics
server {
    listen 9090;
    location /metrics {
        alias /var/www/html/metrics.txt;
    }
}
```

**Adicionar ao cron:**

```bash
# Atualizar métricas a cada minuto
* * * * * /opt/manutencao/export-metrics.sh
```

## Apêndice D: Script de migração integrado

Integre o script de migração ao sistema de backup:

```bash
#!/bin/bash
# /opt/manutencao/migrar-para-novo-servidor.sh

source /opt/manutencao/config.env

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     MIGRAÇÃO COMPLETA DO COOLIFY PARA NOVO SERVIDOR        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Solicitar informações do novo servidor
read -p "IP do novo servidor: " NEW_SERVER_IP
read -p "Usuário SSH (padrão: root): " NEW_SERVER_USER
NEW_SERVER_USER=${NEW_SERVER_USER:-root}
read -p "Porta SSH (padrão: 22): " NEW_SERVER_PORT
NEW_SERVER_PORT=${NEW_SERVER_PORT:-22}

echo ""
echo "📦 Selecionando backup para migração..."

# Listar backups disponíveis
BACKUPS=($(ls -t /root/coolify-backups/*.tar.gz))
echo ""
echo "Backups disponíveis:"
for i in "${!BACKUPS[@]}"; do
    BACKUP_FILE="${BACKUPS[$i]}"
    BACKUP_DATE=$(stat -c %y "$BACKUP_FILE" | cut -d'.' -f1)
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "  [$i] $(basename $BACKUP_FILE) - $BACKUP_DATE ($BACKUP_SIZE)"
done

echo ""
read -p "Selecione o backup (0-$((${#BACKUPS[@]}-1))): " BACKUP_INDEX
SELECTED_BACKUP="${BACKUPS[$BACKUP_INDEX]}"

echo ""
echo "✓ Backup selecionado: $(basename $SELECTED_BACKUP)"
echo ""
echo "⚠️  CONFIRMAÇÃO"
echo "Novo servidor: $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_PORT"
echo "Backup: $(basename $SELECTED_BACKUP)"
echo ""
read -p "Confirma migração? (sim/não): " CONFIRMA

if [ "$CONFIRMA" != "sim" ]; then
    echo "❌ Migração cancelada"
    exit 0
fi

echo ""
echo "🚀 Iniciando migração..."

# Extrair backup temporariamente
TEMP_DIR="/tmp/coolify-migration-$"
mkdir -p "$TEMP_DIR"
tar -xzf "$SELECTED_BACKUP" -C "$TEMP_DIR" --strip-components=1

# Usar o script de migração existente
# (ajustar variáveis automaticamente)
cat > /tmp/migrate-coolify-auto.sh <<EOF
#!/bin/bash
NEW_SERVER_IP="$NEW_SERVER_IP"
NEW_SERVER_USER="$NEW_SERVER_USER"
NEW_SERVER_PORT="$NEW_SERVER_PORT"
NEW_SERVER_AUTH_KEYS_FILE="/root/.ssh/authorized_keys"
SSH_PRIVATE_KEY_PATH="/root/.ssh/id_rsa"
LOCAL_AUTH_KEYS_FILE="/root/.ssh/authorized_keys"
BACKUP_FILE="$SELECTED_BACKUP"

# [Resto do script de migração aqui]
EOF

bash /tmp/migrate-coolify-auto.sh

# Cleanup
rm -rf "$TEMP_DIR"
rm /tmp/migrate-coolify-auto.sh

echo ""
echo "✅ Migração concluída!"
echo ""
echo "Próximos passos:"
echo "1. Atualize DNS para apontar para $NEW_SERVER_IP"
echo "2. Teste acesso: http://$NEW_SERVER_IP:8000"
echo "3. Configure scripts de backup no novo servidor"
```

## Apêndice E: Testes automatizados

Script para testar todo o sistema:

```bash
#!/bin/bash
# /opt/manutencao/test-sistema.sh

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
```

**Executar testes:**

```bash
sudo chmod +x /opt/manutencao/test-sistema.sh
sudo /opt/manutencao/test-sistema.sh
```

---

# 🎓 Lições aprendidas e boas práticas

## O que funciona bem

1. **Automatizar o chato, revisar o crítico**
	
	- Updates de segurança: 100% automático
	- Backups: 100% automático
	- Restauração: 100% manual e testado
2. **Logs são seus melhores amigos**
	
	- Cada ação deve set logada
	- Logs estruturados facilitam troubleshooting
	- Manter histórico de 60-90 dias
3. **Backups sem testes são ilusão de segurança**
	
	- Teste restauração trimestralmente
	- Documente o processo
	- Cronometre quanto tempo leva
4. **Notificações inteligentes**
	
	- Apenas para eventos críticos
	- Evite alert fatigue
	- Inclua contexto suficiente para ação
5. **Documentação como código**
	
	- Runbooks versionados
	- Procedimentos testados
	- Sempre atualizados

## O que evitar

1. ❌ **Full upgrade automático sem supervisão**
	
	- Pode quebrar aplicações
	- Apenas security updates automáticos
2. ❌ **Deletar volumes Docker sem confirmar**
	
	- Dados permanentemente perdidos
	- Sempre listar antes de remover
3. ❌ **Confiar cegamente em automação**
	
	- Murphy's Law sempre se aplica
	- Revisão mensal é obrigatória
4. ❌ **Backups apenas no mesmo servidor**
	
	- Se o servidor morrer, backup morre junto
	- Sempre ter cópia off-site
5. ❌ **Ignorar alertas de disco > 80%**
	
	- Pode causar falha em cascata
	- Investigar imediatamente

---

# 📞 Suporte e comunidade

## Onde buscar ajuda

- **Coolify Discord**: https://discord.gg/coolify
	
	- Canal #support para problemas
	- Canal #self-hosting para discussões
- **Documentação Coolify**: https://coolify.io/docs
	
	- Guias oficiais
	- API reference
- **GitHub Issues**: https://github.com/coollabsio/coolify
	
	- Reportar bugs
	- Feature requests
- **Fórum Ubuntu**: https://ubuntuforums.org
	
	- Problemas específicos do Ubuntu
	- Comunidade muito ativa

## Contribuindo de volta

Se este guia te ajudou, considere:

- ⭐ Star no repositório do Coolify
- 📝 Compartilhar melhorias deste guia
- 💬 Ajudar outros na comunidade
- 💰 Apoiar o projeto Coolify

---

# 📄 Licença e créditos

Este guia foi criado com base em:

- Tweet original de [@hyperknot](https://x.com/hyperknot) sobre manutenção de VPS
- Documentação official do Coolify
- Boas práticas da comunidade DevOps
- Experiência prática com servidores de produção

**Créditos especiais:**

- Zsolt ([@hyperknot](https://x.com/hyperknot)) - Setup minimalista original
- Coolify Team - Plataforma incrível
- Comunidade open-source

**Versão:** 2.0  
**Última atualização:** Janeiro 2025  
**Compatibilidade:**

- Ubuntu 20.04 LTS, 22.04 LTS, 24.04 LTS
- Debian 11, 12
- Coolify v4.x

---

# 📝 Changelog

## v2.0 (Janeiro 2025)

- ✅ Adicionado script completo de backup do Coolify
- ✅ Integração com script de migração original
- ✅ Backup de SSH keys e authorized_keys
- ✅ Procedimentos de disaster recovery
- ✅ Scripts de teste automatizado
- ✅ Dashboard unificado de status
- ✅ Alertas via Telegram/Discord
- ✅ Estratégia 3-2-1 de backup

## v1.0 (Janeiro 2025)

- ✅ Script de manutenção automatizada
- ✅ Configuração de unattended-upgrades
- ✅ Limpeza de Docker, kernels e logs
- ✅ Guia passo a passo completo

---

# 🚀 Próximos passos sugeridos

Depois de implementar tudo neste guia:

## Semana 1-2

- [ ] Observe os scripts rodando automaticamente
- [ ] Verifique logs diariamente
- [ ] Ajuste horários se necessário
- [ ] Teste restauração de um backup

## Mês 1-3

- [ ] Reduza frequência de verificação para semanal
- [ ] Configure backup off-site (S3 ou servidor remoto)
- [ ] Implemente criptografia de backups
- [ ] Configure firewall avançado (UFW + Fail2ban)

## Trimestre 1

- [ ] Considere atualização de kernel
- [ ] Revise e otimize retenção de backups
- [ ] Implemente monitoramento avançado (Prometheus)
- [ ] Documente lições aprendidas

## Annual

- [ ] Avalie upgrade de versão do Ubuntu
- [ ] Considere alta disponibilidade (load balancer)
- [ ] Revise estratégia de disaster recovery
- [ ] Treine equipe em procedimentos de emergência

---

**🎉 Parabéns! Seu VPS agora está preparado para rodar de forma segura, estável e confiável por anos.**

**Dúvidas? Consulte a seção de Troubleshooting ou a comunidade Coolify no Discord.**

**Boa sorte e deploy feliz! 🚀**exit 0

````

**Salve e torne executável:**

```bash
sudo chmod +x /opt/manutencao/manutencao-completa.sh
````

---

# Script de backup do Coolify

## ⚠️ Importante: Diferença entre Manutenção e Backup

O script de manutenção acima **NÃO faz backup de dados**. Ele apenas:

- Atualiza pacotes de segurança
- Limpa arquivos temporários e lixo
- Remove containers/imagens não usados

Para ter um sistema **realmente completo e seguro**, você precisa de um script adicional que faça backup dos dados do Coolify, incluindo:

|Item|O que é|Por que é crítico|
|---|---|---|
|**Banco de dados PostgreSQL**|Contém todas as configurações do Coolify|Sem isso, você perde todos os projetos e configurações|
|**SSH Keys**|Chaves para acessar servidores remotos|Sem isso, não consegue fazer deploy|
|**Arquivo.env**|Variáveis de ambiente e APP_KEY|Sem o APP_KEY correto, o Coolify não funciona|
|**Configurações do Nginx**|Reverse proxy e SSL|Perde configurações de domínios|

## Script completo de backup do Coolify

```bash
#!/bin/bash
################################################################################
# Script de Backup Completo para Coolify
# Complementa o script de manutenção
# Versão: 1.0
# Compatível com o padrão de migração do Coolify
################################################################################

# Configurações
BACKUP_BASE_DIR="/root/coolify-backups"
BACKUP_DIR="$BACKUP_BASE_DIR/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/var/log/manutencao/backup-coolify.log"
RETENTION_DAYS=30  # Manter backups por 30 dias

# Diretórios e arquivos do Coolify
COOLIFY_DATA_DIR="/data/coolify"
COOLIFY_SOURCE_DIR="$COOLIFY_DATA_DIR/source"
COOLIFY_SSH_DIR="$COOLIFY_DATA_DIR/ssh/keys"
COOLIFY_ENV_FILE="$COOLIFY_SOURCE_DIR/.env"

# Notificações (configure conforme necessário)
WEBHOOK_URL=""
EMAIL=""

################################################################################
# FUNÇÕES
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERRO] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo "[OK] $1" | tee -a "$LOG_FILE"
}

notificar() {
    local mensagem="$1"
    
    if [ -n "$EMAIL" ]; then
        echo "$mensagem" | mail -s "Backup Coolify - $(hostname)" "$EMAIL"
    fi
    
    if [ -n "$WEBHOOK_URL" ]; then
        curl -s -H "Content-Type: application/json" \
             -d "{\"content\":\"$mensagem\"}" \
             "$WEBHOOK_URL" > /dev/null 2>&1
    fi
}

check_coolify_installed() {
    if ! docker ps --format '{{.Names}}' | grep -q "coolify"; then
        log_error "Coolify não está instalado ou não está rodando"
        exit 1
    fi
    log_success "Coolify detectado e rodando"
}

################################################################################
# INÍCIO DO BACKUP
################################################################################

log "========================================"
log "INICIANDO BACKUP DO COOLIFY"
log "========================================"

# Verificar se Coolify está instalado
check_coolify_installed

# Criar diretório de backup
mkdir -p "$BACKUP_DIR"
log "Diretório de backup criado: $BACKUP_DIR"

################################################################################
# 1. BACKUP DO BANCO DE DADOS
################################################################################

log "--- 1. Backup do banco de dados PostgreSQL ---"

DB_BACKUP_FILE="$BACKUP_DIR/coolify-db-$(date +%s).dmp"

docker exec coolify-db pg_dump -U coolify -d coolify -F c -f /tmp/backup.dmp 2>/dev/null
if [ $? -eq 0 ]; then
    docker cp coolify-db:/tmp/backup.dmp "$DB_BACKUP_FILE"
    docker exec coolify-db rm /tmp/backup.dmp
    
    DB_SIZE=$(du -h "$DB_BACKUP_FILE" | cut -f1)
    log_success "Banco de dados backupeado: $DB_SIZE"
else
    log_error "Falha ao fazer backup do banco de dados"
    notificar "⚠️ Falha no backup do banco de dados Coolify em $(hostname)"
fi

################################################################################
# 2. BACKUP DAS SSH KEYS
################################################################################

log "--- 2. Backup das SSH Keys ---"

if [ -d "$COOLIFY_SSH_DIR" ]; then
    cp -r "$COOLIFY_SSH_DIR" "$BACKUP_DIR/ssh-keys"
    KEYS_COUNT=$(find "$BACKUP_DIR/ssh-keys" -type f | wc -l)
    log_success "SSH Keys backupeadas: $KEYS_COUNT arquivos"
else
    log_error "Diretório de SSH keys não encontrado: $COOLIFY_SSH_DIR"
fi

################################################################################
# 3. BACKUP DO .ENV E CONFIGURAÇÕES
################################################################################

log "--- 3. Backup das configurações ---"

if [ -f "$COOLIFY_ENV_FILE" ]; then
    cp "$COOLIFY_ENV_FILE" "$BACKUP_DIR/.env"
    
    # Extrair APP_KEY para referência
    APP_KEY=$(grep "^APP_KEY=" "$COOLIFY_ENV_FILE" | cut -d '=' -f2-)
    echo "APP_KEY=$APP_KEY" > "$BACKUP_DIR/app-key.txt"
    
    log_success "Arquivo .env e APP_KEY backupeados"
else
    log_error "Arquivo .env não encontrado: $COOLIFY_ENV_FILE"
fi

# Backup de outras configurações importantes
if [ -d "/etc/nginx" ]; then
    cp -r /etc/nginx "$BACKUP_DIR/nginx-config"
    log_success "Configurações do Nginx backupeadas"
fi

# Backup do authorized_keys (importante para acesso SSH)
if [ -f "/root/.ssh/authorized_keys" ]; then
    cp /root/.ssh/authorized_keys "$BACKUP_DIR/authorized_keys"
    log_success "Arquivo authorized_keys backupeado"
fi

################################################################################
# 4. BACKUP DE VOLUMES DOCKER (OPCIONAL)
################################################################################

log "--- 4. Listando volumes Docker ---"

# Criar arquivo com lista de volumes
docker volume ls --format '{{.Name}}' > "$BACKUP_DIR/volumes-list.txt"
VOLUMES_COUNT=$(wc -l < "$BACKUP_DIR/volumes-list.txt")
log "Total de volumes Docker: $VOLUMES_COUNT"

# Se quiser fazer backup de volumes específicos, descomente abaixo
# IMPORTANTE: Isso pode consumir MUITO espaço em disco
# 
# mkdir -p "$BACKUP_DIR/volumes"
# while IFS= read -r volume; do
#     # Pular volumes do sistema
#     if [[ "$volume" =~ ^(coolify|postgres) ]]; then
#         continue
#     fi
#     
#     log "Backupeando volume: $volume"
#     docker run --rm \
#       -v "$volume":/volume \
#       -v "$BACKUP_DIR/volumes":/backup \
#       busybox \
#       tar czf "/backup/${volume}.tar.gz" -C /volume .
# done < "$BACKUP_DIR/volumes-list.txt"

log "Backup de volumes desativado (economizar espaço). Habilite se necessário."

################################################################################
# 5. INFORMAÇÕES DO SISTEMA
################################################################################

log "--- 5. Coletando informações do sistema ---"

cat > "$BACKUP_DIR/system-info.txt" <<EOF
Sistema Operacional: $(lsb_release -d | cut -f2)
Kernel: $(uname -r)
Docker Version: $(docker --version)
Espaço em disco: $(df -h / | tail -1 | awk '{print $5 " usado de " $2}')
Memória: $(free -h | grep Mem | awk '{print $3 " usado de " $2}')
EOF

log_success "Informações do sistema coletadas"

################################################################################
# 6. CRIAR ARQUIVO DE METADADOS
################################################################################

log "--- 6. Criando arquivo de metadados ---"

COOLIFY_VERSION=$(docker ps --filter "name=coolify" --format '{{.Image}}' | grep coollabsio/coolify | head -n1)

cat > "$BACKUP_DIR/backup-info.txt" <<EOF
╔════════════════════════════════════════════════════════════╗
║              BACKUP DO COOLIFY                             ║
╚════════════════════════════════════════════════════════════╝

📅 Data: $(date '+%Y-%m-%d %H:%M:%S')
🖥️  Hostname: $(hostname)
🐳 Versão do Coolify: $COOLIFY_VERSION

📦 CONTEÚDO DO BACKUP:
  ✓ Banco de dados PostgreSQL (dump completo no formato custom)
  ✓ SSH Keys do Coolify (/data/coolify/ssh/keys)
  ✓ Arquivo .env e APP_KEY extraída
  ✓ Arquivo authorized_keys do root
  ✓ Configurações do Nginx
  ✓ Lista de volumes Docker
  ✓ Informações do sistema

💾 Tamanho total: $(du -sh "$BACKUP_DIR" | cut -f1)

🔄 COMO RESTAURAR ESTE BACKUP:

1. Instale o Coolify no novo servidor:
   curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

2. Pare os containers (exceto o banco):
   docker ps --filter name=coolify --format '{{.Names}}' | grep -v 'coolify-db' | xargs docker stop

3. Restaure o banco de dados:
   cat coolify-db-*.dmp | docker exec -i coolify-db pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify

4. Copie as SSH keys:
   cp -r ssh-keys/* /data/coolify/ssh/keys/

5. Restaure o authorized_keys:
   cat authorized_keys >> /root/.ssh/authorized_keys

6. Atualize o .env com a APP_KEY:
   cd /data/coolify/source
   sed -i '/^APP_PREVIOUS_KEYS=/d' .env
   echo 'APP_PREVIOUS_KEYS=<APP_KEY_DO_BACKUP>' >> .env

7. Execute o install script novamente:
   curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

📋 Para mais detalhes, consulte: https://coolify.io/docs

EOF

log_success "Arquivo de metadados criado"

################################################################################
# 7. COMPACTAR BACKUP
################################################################################

log "--- 7. Compactando backup ---"

cd "$BACKUP_BASE_DIR"
BACKUP_BASENAME=$(basename "$BACKUP_DIR")
tar -czf "${BACKUP_BASENAME}.tar.gz" "$BACKUP_BASENAME" 2>/dev/null

if [ $? -eq 0 ]; then
    COMPRESSED_SIZE=$(du -h "${BACKUP_BASENAME}.tar.gz" | cut -f1)
    log_success "Backup compactado: $COMPRESSED_SIZE"
    
    # Remover diretório não compactado para economizar espaço
    rm -rf "$BACKUP_DIR"
    log "Diretório descompactado removido"
else
    log_error "Falha ao compactar backup"
fi

################################################################################
# 8. LIMPEZA DE BACKUPS ANTIGOS
################################################################################

log "--- 8. Removendo backups antigos ---"

BACKUPS_REMOVIDOS=$(find "$BACKUP_BASE_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)

if [ "$BACKUPS_REMOVIDOS" -gt 0 ]; then
    log_success "$BACKUPS_REMOVIDOS backups antigos removidos (>${RETENTION_DAYS} dias)"
else
    log "Nenhum backup antigo para remover"
fi

################################################################################
# 9. RELATÓRIO FINAL
################################################################################

log "========================================"
log "BACKUP CONCLUÍDO"
log "========================================"

BACKUP_FINAL=$(ls -lht "$BACKUP_BASE_DIR"/*.tar.gz 2>/dev/null | head -1 | awk '{print $9, "("$5")"}')

RELATORIO="
📦 RELATÓRIO DE BACKUP - $(hostname)
Data: $(date '+%d/%m/%Y %H:%M')

✅ Backup criado: $BACKUP_FINAL

📊 Conteúdo:
  - Banco de dados PostgreSQL: ✓
  - SSH Keys: ✓
  - Configurações (.env, Nginx): ✓
  - authorized_keys: ✓
  - Lista de volumes: ✓

🗄️  Backups mantidos: $(ls -1 "$BACKUP_BASE_DIR"/*.tar.gz 2>/dev/null | wc -l)
🗑️  Backups removidos: $BACKUPS_REMOVIDOS

📍 Localização: $BACKUP_BASE_DIR
📋 Log completo: $LOG_FILE

⚠️  IMPORTANTE: 
  - Baixe este backup para outro local seguro
  - Teste a restauração periodicamente
  - Mantenha backups off-site (outro servidor/cloud)
"

echo "$RELATORIO" | tee -a "$LOG_FILE"

# Notificar sucesso
notificar "✅ Backup do Coolify concluído em $(hostname). Tamanho: $COMPRESSED_SIZE"

exit 0
```

**Salve e torne executável:**

```bash
sudo chmod +x /opt/manutencao/backup-coolify.sh
```

## Testar o backup manualmente

```bash
# Executar backup
sudo /opt/manutencao/backup-coolify.sh

# Verificar backups criados
ls -lh /root/coolify-backups/

# Ver conteúdo de um backup
cd /root/coolify-backups
tar -tzf 20250101_020000.tar.gz | head -20

# Ver log do backup
tail -50 /var/log/manutencao/backup-coolify.log
```

## Como restaurar um backup

```bash
# 1. Extrair backup
cd /root/coolify-backups
tar -xzf 20250101_020000.tar.gz
cd 20250101_020000

# 2. Ver instruções
cat backup-info.txt

# 3. Seguir passo a passo das instruções no arquivo
```

---

# Integração completa dos scripts

## Estrutura final do sistema

```
/opt/manutencao/
├── manutencao-completa.sh     # Manutenção preventiva
├── backup-coolify.sh           # Backup de dados
└── alerta-disco.sh             # Alertas

/var/log/manutencao/
├── manutencao.log              # Log da manutenção
├── backup-coolify.log          # Log dos backups
└── cron.log                    # Log do cron

/root/coolify-backups/
├── 20250118_020000.tar.gz      # Backup de 18/01
├── 20250125_020000.tar.gz      # Backup de 25/01
└── 20250201_020000.tar.gz      # Backup de 01/02
```

## Configuração completa do cron

```bash
sudo crontab -e
```

**Cole todas estas linhas:**

```bash
# ========== MANUTENÇÃO E BACKUP DO VPS ==========

# Backup completo do Coolify - Todo domingo às 2h
0 2 * * 0 /opt/manutencao/backup-coolify.sh >> /var/log/manutencao/cron.log 2>&1

# Manutenção preventiva - Toda segunda às 3h
0 3 * * 1 /opt/manutencao/manutencao-completa.sh >> /var/log/manutencao/cron.log 2>&1

# Alerta de disco cheio - Todo dia às 9h
0 9 * * * /opt/manutencao/alerta-disco.sh >> /var/log/manutencao/cron.log 2>&1

# Backup mensal dos logs - Dia 1 de cada mês às 4h
0 4 1 * * tar -czf /var/log/manutencao/backup-logs-$(date +\%Y\%m).tar.gz /var/log/manutencao/*.log && find /var/log/manutencao -name "*.log" -mtime +60 -delete

# ================================================
```

## Calendário de execução automática

|Dia|Horário|Script|O que faz|
|---|---|---|---|
|**Domingo**|2h|`backup-coolify.sh`|Backup completo (DB, keys, configs)|
|**Segunda**|3h|`manutencao-completa.sh`|Limpeza, updates de segurança|
|**Todo dia**|9h|`alerta-disco.sh`|Verifica espaço em disco|
|**Dia 1**|4h|Compactação de logs|Arquiva logs antigos|

## Fluxo de trabalho semanal

```
┌─────────────────────────────────────────────┐
│  DOMINGO 02:00                              │
│  ✓ Backup completo do Coolify              │
│    - Banco de dados PostgreSQL             │
│    - SSH Keys                               │
│    - Configurações (.env, Nginx)            │
│    - Lista de volumes                       │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  SEGUNDA 03:00                              │
│  ✓ Manutenção preventiva                   │
│    - Updates de segurança                   │
│    - Limpeza de Docker                      │
│    - Remoção de kernels antigos             │
│    - Limpeza de logs                        │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  SEGUNDA-DOMINGO 09:00                      │
│  ✓ Verificação de espaço                   │
│    - Alerta se disco > 80%                  │
└─────────────────────────────────────────────┘
```

## Verificar se tudo está funcionando

```bash
# Ver próximas execuções agendadas
sudo crontab -l

# Ver últimas execuções
sudo grep -E "(backup-coolify|manutencao-completa)" /var/log/syslog | tail -20

# Status dos scripts
ls -lh /opt/manutencao/

# Verificar logs
tail -50 /var/log/manutencao/manutencao.log
tail -50 /var/log/manutencao/backup-coolify.log

# Verificar backups existentes
ls -lh /root/coolify-backups/
```

## Script de status unificado

Crie um script para ver o status de tudo de uma vez:

```bash
sudo nano /usr/local/bin/status-completo
```

**Cole:**

```bash
#!/bin/bash

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
```

```bash
sudo chmod +x /usr/local/bin/status-completo

# Executar
status-completo
```

---

# Estratégia completa de backup

## 3-2-1 Rule of Backup

Para máxima segurança, siga a regra 3-2-1:

```
3 cópias dos dados
  ├─ 1 cópia original (produção no VPS)
  ├─ 1 cópia local (backup no mesmo VPS)
  └─ 1 cópia remota (off-site)

2 tipos diferentes de mídia
  ├─ Disco do VPS
  └─ Cloud storage (S3, Dropbox, etc)

1 cópia off-site
  └─ Em outro datacenter/região
```

## Opção 1: Backup para outro servidor

```bash
# Adicionar ao final do script backup-coolify.sh, antes do "exit 0":

################################################################################
# 10. SINCRONIZAR COM SERVIDOR REMOTO (OPCIONAL)
################################################################################

REMOTE_SERVER="backup-server.exemplo.com"
REMOTE_USER="root"
REMOTE_DIR="/backups/coolify"

if [ -n "$REMOTE_SERVER" ]; then
    log "--- 10. Sincronizando com servidor remoto ---"
    
    LATEST_BACKUP=$(ls -t "$BACKUP_BASE_DIR"/*.tar.gz | head -1)
    
    scp "$LATEST_BACKUP" "$REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR/" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Backup sincronizado com $REMOTE_SERVER"
    else
        log_error "Falha ao sincronizar com servidor remoto"
    fi
fi
```

## Opção 2: Backup para S3 (AWS)

```bash
# Instalar AWS CLI
sudo apt install awscli -y

# Configurar credenciais
aws configure

# Adicionar ao script:
S3_BUCKET="s3://meu-bucket-backups/coolify"

if command -v aws &> /dev/null; then
    log "--- 10. Enviando para S3 ---"
    
    LATEST_BACKUP=$(ls -t "$BACKUP_BASE_DIR"/*.tar.gz | head -1)
    
    aws s3 cp "$LATEST_BACKUP" "$S3_BUCKET/" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Backup enviado para S3"
    else
        log_error "Falha ao enviar para S3"
    fi
fi
```

## Opção 3: Backup para Dropbox/Google Drive

```bash
# Instalar rclone
curl https://rclone.org/install.sh | sudo bash

# Configurar (seguir wizard interativo)
rclone config

# Adicionar ao script:
RCLONE_REMOTE="dropbox:coolify-backups"

if command -v rclone &> /dev/null; then
    log "--- 10. Enviando para cloud storage ---"
    
    LATEST_BACKUP=$(ls -t "$BACKUP_BASE_DIR"/*.tar.gz | head -1)
    
    rclone copy "$LATEST_BACKUP" "$RCLONE_REMOTE/" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Backup enviado para cloud storage"
    else
        log_error "Falha ao enviar para cloud"
    fi
fi
```

## Testar restauração de backup

**É crítico testar se seus backups realmente funcionam!**

```bash
# 1. Em um VPS de teste (NÃO em produção), instale o Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# 2. Baixe um backup
scp seu-vps:/root/coolify-backups/20250118_020000.tar.gz .

# 3. Extraia
tar -xzf 20250118_020000.tar.gz
cd 20250118_020000

# 4. Veja as instruções
cat backup-info.txt

# 5. Siga o passo a passo de restauração
# (comandos estão no arquivo backup-info.txt)

# 6. Verifique se o Coolify funciona
# Acesse http://ip-do-servidor:8000
```

---

# Backup de volumes de aplicações

O script de backup do Coolify **não faz backup dos volumes das aplicações** por padrão (para economizar espaço). Se você precisa fazer backup de volumes específicos:

## Script para backup de volume individual

```bash
#!/bin/bash
# Script: backup-volume.sh
# Uso: ./backup-volume.sh nome-do-volume

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

docker run --rm \
  -v "$VOLUME_NAME":/volume \
  -v "$BACKUP_DIR":/backup \
  busybox \
  tar czf /backup/$(basename "$BACKUP_FILE") -C /volume .

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✅ Backup concluído: $BACKUP_FILE ($SIZE)"
else
    echo "❌ Falha no backup"
    exit 1
fi
```

**Como usar:**

```bash
# Salvar script
sudo nano /usr/local/bin/backup-volume
# Cole o script acima
sudo chmod +x /usr/local/bin/backup-volume

# Listar volumes existentes
docker volume ls

# Fazer backup de um volume específico
backup-volume minha-app_data

# Ver backups criados
ls -lh /root/volume-backups/
```

## Restaurar um volume

```bash
#!/bin/bash
# Script: restaurar-volume.sh
# Uso: ./restaurar-volume.sh backup.tar.gz nome-do-volume

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
```

**Como usar:**

```bash
# Salvar script
sudo nano /usr/local/bin/restaurar-volume
# Cole o script acima
sudo chmod +x /usr/local/bin/restaurar-volume

# Restaurar um backup
restaurar-volume /root/volume-backups/minha-app_data-20250118.tar.gz minha-app_data
```

---# Guia Completo: Manutenção e Segurança de VPS com Docker/Coolify

# 📋 Índice

1. [Por que isso importa](https://claude.ai/chat/c0b95a1d-fc88-42e0-8a99-f9dbe5262b4f#por-que-isso-importa)
2. [Entendendo os riscos](https://claude.ai/chat/c0b95a1d-fc88-42e0-8a99-f9dbe5262b4f#entendendo-os-riscos)
3. [Estratégia de manutenção](https://claude.ai/chat/c0b95a1d-fc88-42e0-8a99-f9dbe5262b4f#estrat%C3%A9gia-de-manuten%C3%A7%C3%A3o)
4. [Passo a passo completo](https://claude.ai/chat/c0b95a1d-fc88-42e0-8a99-f9dbe5262b4f#passo-a-passo-completo)
5. [Script de automação final](https://claude.ai/chat/c0b95a1d-fc88-42e0-8a99-f9dbe5262b4f#script-de-automa%C3%A7%C3%A3o-final)
6. [Script de backup do Coolify](https://claude.ai/chat/c0b95a1d-fc88-42e0-8a99-f9dbe5262b4f#script-de-backup-do-coolify)
7. [Integração completa dos scripts](https://claude.ai/chat/c0b95a1d-fc88-42e0-8a99-f9dbe5262b4f#integra%C3%A7%C3%A3o-completa-dos-scripts)
8. [Monitoramento e troubleshooting](https://claude.ai/chat/c0b95a1d-fc88-42e0-8a99-f9dbe5262b4f#monitoramento-e-troubleshooting)

---

# Por que isso importa

## A ilusão do "set and forget"

Você configurou seu VPS há 2 anos. Instalou Coolify, deployou aplicações, tudo funcionando. **O silêncio não significa segurança.**

## O que acontece em 2 anos sem manutenção

|Área|Problema|Impacto Real|
|---|---|---|
|**Segurança**|Vulnerabilidades públicas (CVEs) acumuladas|Seu servidor vira alvo fácil para bots|
|**Espaço**|Docker acumula GB de lixo (imagens, volumes, logs)|Disco cheio = aplicações caem|
|**Performance**|Kernels antigos, pacotes obsoletos|Lentidão, bugs conhecidos não corrigidos|
|**Estabilidade**|Dependências conflitantes ao tentar atualizar depois de anos|Atualização vira pesadelo|

## Exemplo real de vulnerabilidade

```
CVE-2024-3094 (xz-utils backdoor)
- Descoberta: Março 2024
- Impacto: Acesso root remoto
- Seu servidor SEM updates: VULNERÁVEL por 1+ ano
```

**Bottom line:** Manutenção preventiva é mais barata que apagar incêndios.

---

# Entendendo os riscos

## 1. **Vulnerabilidades de Segurança** 🔴

**Como funciona:**

- Pesquisadores descobrem falhas em software
- CVEs são publicadas publicamente
- Patches são lançados
- **Seu servidor sem updates = manual público de invasão**

**Alvos comuns em VPS:**

- OpenSSH (acesso remoto)
- Nginx/Apache (web server)
- Kernel Linux (sistema operacional)
- Docker Engine (containers)
- Bibliotecas SSL/TLS

**O que atacantes fazem:**

1. Scanneiam internet por servidores vulneráveis
2. Usam exploits automatizados (scripts)
3. Ganham acesso, instalam malware/cryptominers
4. Usam seu servidor para atacar outros

## 2. **Acúmulo de "lixo" no sistema** 🟡

**Docker é o maior vilão:**

```bash
# Exemplo real após 6 meses sem limpeza:
TIPO                TOTAL       ATIVO       TAMANHO     RECUPERÁVEL
Images              47          5           8.2GB       6.1GB (74%)
Containers          23          3           1.1GB       892MB (81%)
Volumes             12          2           3.4GB       2.9GB (85%)
Build Cache         156         0           4.7GB       4.7GB (100%)

# TOTAL RECUPERÁVEL: 14.5GB
```

**Outros acumuladores:**

- `/var/log`: Logs antigos (podem chegar a GBs)
- `/tmp`: Arquivos temporários esquecidos
- Kernels antigos: 200-500MB cada
- Cache do APT: Pacotes.deb baixados

## 3. **Degradação progressiva** 🟠

Sem manutenção, seu sistema:

- Fica mais lento (fragmentação, cache cheio)
- Tem mais bugs (correções não aplicadas)
- Dificulta troubleshooting (logs gigantes)
- Torna futuras atualizações arriscadas

---

# Estratégia de manutenção

## Filosofia: Automatizar o essential, revisar o crítico

```
┌─────────────────────────────────────────┐
│  AUTOMÁTICO (sem intervenção)           │
├─────────────────────────────────────────┤
│  ✓ Updates de segurança                 │
│  ✓ Limpeza de Docker                    │
│  ✓ Remoção de kernels antigos           │
│  ✓ Logs de execução                     │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  MANUAL (revisão mensal)                │
├─────────────────────────────────────────┤
│  ✓ Ler relatórios de manutenção         │
│  ✓ Verificar espaço em disco            │
│  ✓ Checar logs de erros                 │
│  ✓ Testar aplicações após updates       │
└─────────────────────────────────────────┘
```

## Princípios de segurança

1. **Atualize apenas segurança automaticamente** (não full-upgrade)
2. **Teste em horário de baixo tráfego** (madrugada)
3. **Mantenha backups** (antes de mudanças grandes)
4. **Monitore, não confie cegamente** (logs são seus amigos)

---

# Passo a passo completo

## ANTES DE COMEÇAR: Backup obrigatório

```bash
# Se usa Hostinger/Hetzner, faça snapshot pelo painel
# OU backup manual de configurações críticas:

sudo tar -czf /root/backup-configs-$(date +%Y%m%d).tar.gz \
  /etc/nginx \
  /etc/ssh \
  /root/.ssh \
  /opt/coolify \
  /var/lib/docker/volumes

# Salve em outra máquina
scp /root/backup-configs-*.tar.gz usuario@seu-pc:/backup/
```

---

## FASE 1: Diagnóstico inicial

### Passo 1.1: Informações do sistema

```bash
# Ver versão do sistema
lsb_release -a

# Kernel atual
uname -r

# Uptime
uptime

# Espaço em disco
df -h
```

**O que observar:**

- Ubuntu 20.04 ou 22.04? (suporte até 2025/2027)
- Disco > 70% cheio? (CRÍTICO)
- Uptime > 365 dias? (kernel desatualizado)

### Passo 1.2: Estado do Docker

```bash
# Visão geral
docker system df

# Detalhes completos
docker system df -v

# Containers rodando vs parados
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
```

**Interpret:**

- RECLAIMABLE > 5GB? Precisa limpeza urgente
- Containers "Exited" há meses? Lixo acumulado

### Passo 1.3: Pacotes desatualizados

```bash
# Atualizar lista de pacotes
sudo apt update

# Ver quantos updates disponíveis
apt list --upgradable | wc -l

# Ver especificamente updates de segurança
sudo apt list --upgradable 2>/dev/null | grep -i security
```

**Critérios:**

- 0-10 pacotes: OK, sistema relativamente atualizado
- 10-50 pacotes: ATENÇÃO, programe manutenção
- 50+: CRÍTICO, sistema muito desatualizado

---

## FASE 2: Configuração de updates automáticos

### Passo 2.1: Instalar unattended-upgrades

```bash
# Instalar
sudo apt install unattended-upgrades apt-listchanges -y

# Ativar
sudo dpkg-reconfigure -plow unattended-upgrades
# Selecione "Yes" quando perguntado
```

### Passo 2.2: Configurar políticas de atualização

```bash
# Backup da config original
sudo cp /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades.bak

# Editar configuração
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

**Cole esta configuração:**

```bash
// Configuração otimizada para VPS com Docker/Coolify
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
    // Descomente a linha abaixo para incluir updates regulares (mais arriscado)
    // "${distro_id}:${distro_codename}-updates";
};

// Pacotes que NUNCA devem ser atualizados automaticamente
Unattended-Upgrade::Package-Blacklist {
    // Exemplo: "docker-ce"; // Descomente para não atualizar Docker
};

// Remover dependências não usadas automaticamente
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Reiniciar automaticamente se necessário (às 3h da manhã)
Unattended-Upgrade::Automatic-Reboot "false";
// Mude para "true" se quiser reiniciar automaticamente
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Notificações por email (configure seu email)
// Unattended-Upgrade::Mail "seu-email@exemplo.com";
Unattended-Upgrade::MailReport "on-change";

// Aplicar updates em passos mínimos (mais estável)
Unattended-Upgrade::MinimalSteps "true";

// Logar detalhadamente
Unattended-Upgrade::Verbose "true";
```

**Salvar:** `Ctrl+X`, depois `Y`, depois `Enter`

### Passo 2.3: Configurar frequência

```bash
sudo nano /etc/apt/apt.conf.d/20auto-upgrades
```

**Cole:**

```bash
APT::Periodic::Update-Package-Lists "1";        // Atualiza lista diariamente
APT::Periodic::Download-Upgradeable-Packages "1"; // Baixa pacotes diariamente
APT::Periodic::AutocleanInterval "7";           // Limpa cache semanalmente
APT::Periodic::Unattended-Upgrade "1";          // Executa updates diariamente
```

### Passo 2.4: Testar configuração

```bash
# Executar em modo dry-run (simula sem aplicar)
sudo unattended-upgrade --dry-run --debug

# Ver o que seria atualizado
sudo unattended-upgrade -d
```

**Verifique os logs:**

- Sem errors? ✅ Prossiga
- Errors de configuração? Revise o Passo 2.2

---

## FASE 3: Limpeza manual inicial (primeira vez)

**⚠️ IMPORTANTE:** Faça isso em horário de baixo tráfego (madrugada/final de semana)

### Passo 3.1: Limpeza de Docker

```bash
# Ver quanto espaço vai recuperar (NÃO deleta nada)
docker system df

# CUIDADO: Isso remove TUDO não usado
# - Containers parados
# - Imagens sem containers
# - Volumes não montados
# - Build cache

# Opção 1: Interativa (pergunta antes de deletar)
docker system prune -a --volumes

# Opção 2: Automática (PERIGOSO, use apenas se souber o que está fazendo)
# docker system prune -a --volumes -f
```

**Atenção:**

- `-a`: Remove TODAS imagens não usadas (não apenas dangling)
- `--volumes`: Remove volumes órfãos (pode deletar dados!)
- Se Coolify usa volumes persistentes, else estarão montados e seguros

**Alternativa conservadora:**

```bash
# Remove apenas containers parados
docker container prune -f

# Remove apenas imagens dangling (não taggeadas)
docker image prune -f

# Remove apenas build cache
docker builder prune -a -f

# Volumes você decide manualmente depois de listar
docker volume ls
```

### Passo 3.2: Limpeza de pacotes do sistema

```bash
# Remover pacotes órfãos
sudo apt autoremove -y

# Limpar cache do APT
sudo apt autoclean -y
sudo apt clean -y

# Remover arquivos de configuração de pacotes desinstalados
sudo dpkg --list | grep "^rc" | cut -d " " -f 3 | xargs -r sudo dpkg --purge
```

### Passo 3.3: Limpeza de kernels antigos

```bash
# Listar kernels instalados
dpkg --list | grep linux-image

# Ver kernel em uso
uname -r

# Remover kernels antigos (mantém atual + 1 anterior)
sudo apt autoremove --purge -y
```

**Se não remover automaticamente:**

```bash
# Script manual (Ubuntu/Debian)
sudo apt install -y byobu curl git htop nmon
sudo purge-old-kernels --keep 2 -qy
```

### Passo 3.4: Limpeza de logs

```bash
# Ver tamanho dos logs
sudo du -sh /var/log

# Limpar logs do systemd (mantém último mês)
sudo journalctl --vacuum-time=30d

# Rotacionar logs manualmente
sudo logrotate -f /etc/logrotate.conf
```

---

## FASE 4: Automação completa

Agora vamos criar o sistema que faz tudo automaticamente.

### Passo 4.1: Script principal de manutenção

```bash
# Criar diretório para scripts
sudo mkdir -p /opt/manutencao
sudo mkdir -p /var/log/manutencao

# Criar script principal
sudo nano /opt/manutencao/manutencao-completa.sh
```

**Cole o script da seção [Script de automação final](https://claude.ai/chat/c0b95a1d-fc88-42e0-8a99-f9dbe5262b4f#script-de-automa%C3%A7%C3%A3o-final)**

### Passo 4.2: Agendar execução automática

```bash
# Editar crontab do root
sudo crontab -e
```

**Cole estas linhas:**

```bash
# Manutenção completa toda segunda-feira às 3h da manhã
0 3 * * 1 /opt/manutencao/manutencao-completa.sh >> /var/log/manutencao/cron.log 2>&1

# Backup de logs de manutenção todo dia 1º do mês
0 4 1 * * tar -czf /var/log/manutencao/backup-logs-$(date +\%Y\%m).tar.gz /var/log/manutencao/*.log && find /var/log/manutencao -name "*.log" -mtime +60 -delete
```

**Explicação:**

- `0 3 * * 1`: Segunda às 3h (ajuste conforme seu tráfego)
- `>> /var/log/manutencao/cron.log`: Salva output do cron
- Backup mensal: Compacta logs e deleta > 60 dias

### Passo 4.3: Configurar notificações (opcional)

**Opção 1: Email via Postfix (simples)**

```bash
# Instalar
sudo apt install postfix mailutils -y

# Configurar (escolha "Internet Site")
sudo dpkg-reconfigure postfix

# Testar
echo "Teste de email" | mail -s "Teste VPS" seu-email@exemplo.com
```

**Opção 2: Webhook para Discord/Slack (moderno)**

```bash
# Adicionar no script (substitua pela sua webhook URL)
WEBHOOK_URL="https://discord.com/api/webhooks/seu-webhook"

curl -H "Content-Type: application/json" \
     -d "{\"content\":\"✅ Manutenção do VPS concluída\"}" \
     $WEBHOOK_URL
```

---

## FASE 5: Monitoramento contínuo

### Passo 5.1: Dashboard de status

```bash
# Script para ver status rápido
sudo nano /usr/local/bin/status-vps
```

**Cole:**

```bash
#!/bin/bash
echo "=== STATUS DO VPS ==="
echo "Horário: $(date)"
echo ""
echo "--- Espaço em Disco ---"
df -h | grep -E "Filesystem|/dev/sd|/dev/vd"
echo ""
echo "--- Memória ---"
free -h
echo ""
echo "--- Docker ---"
docker system df 2>/dev/null || echo "Docker não disponível"
echo ""
echo "--- Última Manutenção ---"
if [ -f /var/log/manutencao/manutencao.log ]; then
    tail -5 /var/log/manutencao/manutencao.log
else
    echo "Nenhuma manutenção registrada"
fi
echo ""
echo "--- Updates Pendentes ---"
apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0"
```

```bash
# Tornar executável
sudo chmod +x /usr/local/bin/status-vps

# Executar
status-vps
```

### Passo 5.2: Alertas de disco cheio

```bash
# Adicionar ao crontab (checa todo dia às 9h)
sudo crontab -e
```

**Adicione:**

```bash
# Alerta se disco > 80%
0 9 * * * /opt/manutencao/alerta-disco.sh
```

**Criar script de alerta:**

```bash
sudo nano /opt/manutencao/alerta-disco.sh
```

**Cole:**

```bash
#!/bin/bash
LIMITE=80
USO=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ "$USO" -gt "$LIMITE" ]; then
    echo "⚠️  ALERTA: Disco em ${USO}% (limite: ${LIMITE}%)" | \
    mail -s "ALERTA: Disco cheio no VPS" seu-email@exemplo.com
fi
```

```bash
sudo chmod +x /opt/manutencao/alerta-disco.sh
```

---

# Script de automação final

Aqui está o **script completo e otimizado** que automatiza TUDO:

```bash
#!/bin/bash
################################################################################
# Script de Manutenção Automatizada para VPS com Docker/Coolify
# Autor: Baseado no setup de Zsolt (hyperknot) com melhorias
# Versão: 2.0
# Uso: Execute manualmente ou via cron
################################################################################

# Configurações
LOG_DIR="/var/log/manutencao"
LOG_FILE="$LOG_DIR/manutencao.log"
EMAIL="" # Deixe vazio para não enviar emails
WEBHOOK_URL="" # Webhook Discord/Slack (opcional)
DISCO_LIMITE=85 # Alerta se disco > 85%
MANTER_KERNELS=2 # Quantos kernels manter

# Cores para output (opcional, remova se der problema)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# FUNÇÕES AUXILIARES
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1" | tee -a "$LOG_FILE"
}

# Envia notificação (email ou webhook)
notificar() {
    local mensagem="$1"
    
    # Email
    if [ -n "$EMAIL" ]; then
        echo "$mensagem" | mail -s "Manutenção VPS - $(hostname)" "$EMAIL"
    fi
    
    # Webhook (Discord/Slack)
    if [ -n "$WEBHOOK_URL" ]; then
        curl -s -H "Content-Type: application/json" \
             -d "{\"content\":\"$mensagem\"}" \
             "$WEBHOOK_URL" > /dev/null 2>&1
    fi
}

# Calcula espaço livre
espaco_livre() {
    df -h / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Calcula tamanho legível
tamanho_humano() {
    numfmt --to=iec-i --suffix=B "$1" 2>/dev/null || echo "$1 bytes"
}

################################################################################
# INÍCIO DA MANUTENÇÃO
################################################################################

# Criar diretório de logs se não existir
mkdir -p "$LOG_DIR"

log "========================================"
log "INICIANDO MANUTENÇÃO AUTOMATIZADA"
log "========================================"

# Espaço inicial
ESPACO_INICIAL=$(espaco_livre)
log "Uso de disco inicial: ${ESPACO_INICIAL}%"

################################################################################
# 1. ATUALIZAÇÕES DE SEGURANÇA
################################################################################

log "--- 1. Verificando atualizações de segurança ---"

# Atualizar lista de pacotes
apt-get update > /dev/null 2>&1
UPDATES_DISPONIVEIS=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")

if [ "$UPDATES_DISPONIVEIS" -gt 0 ]; then
    log_warning "$UPDATES_DISPONIVEIS pacotes disponíveis para atualização"
    
    # Executar unattended-upgrades se instalado
    if command -v unattended-upgrade &> /dev/null; then
        log "Aplicando updates de segurança via unattended-upgrades..."
        unattended-upgrade -d >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            log_success "Updates de segurança aplicados"
        else
            log_error "Erro ao aplicar updates"
        fi
    else
        log_warning "unattended-upgrades não instalado, pulando updates automáticos"
    fi
else
    log_success "Sistema atualizado, sem updates disponíveis"
fi

################################################################################
# 2. LIMPEZA DE DOCKER
################################################################################

if command -v docker &> /dev/null; then
    log "--- 2. Limpeza de Docker ---"
    
    # Espaço Docker antes
    DOCKER_ANTES=$(docker system df --format "{{.Reclaimable}}" 2>/dev/null | grep -oE '[0-9.]+GB' | head -1 | sed 's/GB//')
    
    if [ -n "$DOCKER_ANTES" ]; then
        log "Espaço recuperável antes: ${DOCKER_ANTES}GB"
    fi
    
    # Remover containers parados
    CONTAINERS_PARADOS=$(docker ps -q -f status=exited 2>/dev/null | wc -l)
    if [ "$CONTAINERS_PARADOS" -gt 0 ]; then
        log "Removendo $CONTAINERS_PARADOS containers parados..."
        docker container prune -f >> "$LOG_FILE" 2>&1
    fi
    
    # Remover imagens não usadas (dangling)
    IMAGENS_DANGLING=$(docker images -q -f dangling=true 2>/dev/null | wc -l)
    if [ "$IMAGENS_DANGLING" -gt 0 ]; then
        log "Removendo $IMAGENS_DANGLING imagens dangling..."
        docker image prune -f >> "$LOG_FILE" 2>&1
    fi
    
    # Remover volumes não usados (CUIDADO!)
    VOLUMES_ORFAOS=$(docker volume ls -q -f dangling=true 2>/dev/null | wc -l)
    if [ "$VOLUMES_ORFAOS" -gt 0 ]; then
        log_warning "$VOLUMES_ORFAOS volumes órfãos encontrados"
        # DESCOMENTE a linha abaixo para remover automaticamente (PERIGOSO)
        # docker volume prune -f >> "$LOG_FILE" 2>&1
        log "Volumes não removidos automaticamente (segurança). Revise manualmente."
    fi
    
    # Remover build cache
    log "Limpando build cache..."
    docker builder prune -a -f >> "$LOG_FILE" 2>&1
    
    # Espaço Docker depois
    DOCKER_DEPOIS=$(docker system df --format "{{.Reclaimable}}" 2>/dev/null | grep -oE '[0-9.]+GB' | head -1 | sed 's/GB//')
    
    if [ -n "$DOCKER_ANTES" ] && [ -n "$DOCKER_DEPOIS" ]; then
        ECONOMIZADO=$(echo "$DOCKER_ANTES - $DOCKER_DEPOIS" | bc 2>/dev/null)
        if [ -n "$ECONOMIZADO" ] && (( $(echo "$ECONOMIZADO > 0" | bc -l) )); then
            log_success "Docker: ~${ECONOMIZADO}GB recuperados"
        fi
    fi
    
else
    log_warning "Docker não instalado, pulando limpeza de containers"
fi

################################################################################
# 3. LIMPEZA DE PACOTES DO SISTEMA
################################################################################

log "--- 3. Limpeza de pacotes do sistema ---"

# Remover pacotes órfãos
log "Removendo pacotes não usados..."
apt-get autoremove --purge -y >> "$LOG_FILE" 2>&1

# Remover configurações de pacotes desinstalados
CONFIGS_ORFAS=$(dpkg --list | grep "^rc" | wc -l)
if [ "$CONFIGS_ORFAS" -gt 0 ]; then
    log "Removendo $CONFIGS_ORFAS configurações órfãs..."
    dpkg --list | grep "^rc" | cut -d " " -f 3 | xargs -r dpkg --purge >> "$LOG_FILE" 2>&1
fi

# Limpar cache do APT
log "Limpando cache do APT..."
apt-get autoclean -y >> "$LOG_FILE" 2>&1
apt-get clean -y >> "$LOG_FILE" 2>&1

log_success "Pacotes limpos"

################################################################################
# 4. LIMPEZA DE KERNELS ANTIGOS
################################################################################

log "--- 4. Limpeza de kernels antigos ---"

KERNEL_ATUAL=$(uname -r)
KERNELS_INSTALADOS=$(dpkg --list | grep -c "^ii  linux-image")

log "Kernel em uso: $KERNEL_ATUAL"
log "Kernels instalados: $KERNELS_INSTALADOS"

if [ "$KERNELS_INSTALADOS" -gt "$MANTER_KERNELS" ]; then
    log "Removendo kernels antigos (mantendo $MANTER_KERNELS)..."
    
    # Método 1: usando apt autoremove
    apt-get autoremove --purge -y >> "$LOG_FILE" 2>&1
    
    # Método 2: purge-old-kernels (se disponível)
    if command -v purge-old-kernels &> /dev/null; then
        purge-old-kernels --keep $MANTER_KERNELS -qy >> "$LOG_FILE" 2>&1
    fi
    
    KERNELS_APOS=$(dpkg --list | grep -c "^ii  linux-image")
    REMOVIDOS=$((KERNELS_INSTALADOS - KERNELS_APOS))
    
    if [ "$REMOVIDOS" -gt 0 ]; then
        log_success "$REMOVIDOS kernels removidos"
    fi
else
    log_success "Apenas $KERNELS_INSTALADOS kernels instalados, nada a remover"
fi

################################################################################
# 5. LIMPEZA DE LOGS
################################################################################

log "--- 5. Limpeza de logs ---"

# Tamanho dos logs antes
LOGS_ANTES=$(du -sb /var/log 2>/dev/null | awk '{print $1}')

# Limpar journal (systemd)
if command -v journalctl &> /dev/null; then
    log "Limpando journalctl (mantendo 30 dias)..."
    journalctl --vacuum-time=30d >> "$LOG_FILE" 2>&1
fi

# Rotacionar logs
if [ -f /etc/logrotate.conf ]; then
    log "Forçando rotação de logs..."
    logrotate -f /etc/logrotate.conf >> "$LOG_FILE" 2>&1
fi

# Remover logs antigos de manutenção (mantém 90 dias)
find "$LOG_DIR" -name "*.log" -type f -mtime +90 -delete 2>/dev/null

# Tamanho dos logs depois
LOGS_DEPOIS=$(du -sb /var/log 2>/dev/null | awk '{print $1}')

if [ -n "$LOGS_ANTES" ] && [ -n "$LOGS_DEPOIS" ]; then
    LOGS_ECONOMIZADO=$((LOGS_ANTES - LOGS_DEPOIS))
    if [ "$LOGS_ECONOMIZADO" -gt 0 ]; then
        log_success "Logs: $(tamanho_humano $LOGS_ECONOMIZADO) recuperados"
    fi
fi

################################################################################
# 6. VERIFICAÇÕES FINAIS
################################################################################

log "--- 6. Verificações finais ---"

# Espaço final
ESPACO_FINAL=$(espaco_livre)
ECONOMIZADO_TOTAL=$((ESPACO_INICIAL - ESPACO_FINAL))

log "Uso de disco final: ${ESPACO_FINAL}%"

if [ "$ECONOMIZADO_TOTAL" -gt 0 ]; then
    log_success "Espaço recuperado: ${ECONOMIZADO_TOTAL}%"
else
    log "Nenhum espaço adicional recuperado (sistema já otimizado)"
fi

# Alerta se disco > limite
if [ "$ESPACO_FINAL" -gt "$DISCO_LIMITE" ]; then
    MENSAGEM="⚠️  ALERTA: Disco em ${ESPACO_FINAL}% no VPS $(hostname) (limite: ${DISCO_LIMITE}%)"
    log_error "$MENSAGEM"
    notificar "$MENSAGEM"
fi

# Verificar se precisa reboot
if [ -f /var/run/reboot-required ]; then
    MENSAGEM="⚠️  Reboot necessário no VPS $(hostname) após atualizações"
    log_warning "$MENSAGEM"
    notificar "$MENSAGEM"
    
    # DESCOMENTE para reboot automático (CUIDADO!)
    # log "Agendando reboot em 5 minutos..."
    # shutdown -r +5 "Reboot automático após manutenção" &
fi

################################################################################
# 7. RELATÓRIO FINAL
################################################################################

log "========================================"
log "MANUTENÇÃO CONCLUÍDA"
log "========================================"

# Gerar resumo
RESUMO="
📊 RELATÓRIO DE MANUTENÇÃO - $(hostname)
Data: $(date '+%d/%m/%Y %H:%M')

💾 Disco:
  - Antes: ${ESPACO_INICIAL}%
  - Depois: ${ESPACO_FINAL}%
  - Recuperado: ${ECONOMIZADO_TOTAL}%

📦 Pacotes:
  - Updates aplicados: Verificar logs
  - Kernels instalados: $KERNELS_INSTALADOS

🐳 Docker:
  - Containers parados removidos: $CONTAINERS_PARADOS
  - Imagens limpas: $IMAGENS_DANGLING
  - Volumes órfãos: $VOLUMES_ORFAOS (não removidos)

📋 Logs completos: $LOG_FILE
"

echo "$RESUMO" | tee -a "$LOG_FILE"

# Enviar notificação de sucesso
if [ "$ESPACO_FINAL" -le "$DISCO_LIMITE" ]; then
    notificar "✅ Manutenção concluída com sucesso no VPS $(hostname). Disco: ${ESPACO_FINAL}%"
fi

# Rotacionar log se muito grande (> 10MB)
LOG_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
if [ "$LOG_SIZE" -gt 10485760 ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
    log "Log rotacionado (arquivo anterior salvo como .old)"
fi

exit 0
```

**Salve e torne executável:**

```bash
sudo chmod +x /opt/manutencao/manutencao-completa.sh
```

---

# Monitoramento e Troubleshooting

## Verificar execução do script

```bash
# Ver últimas execuções
tail -100 /var/log/manutencao/manutencao.log

# Ver apenas erros
grep -i erro /var/log/manutencao/manutencao.log

# Ver resumos de todas execuções
grep -A 10 "RELATÓRIO DE MANUTENÇÃO" /var/log/manutencao/manutencao.log
```

## Testar o script manualmente

```bash
# Executar em modo verbose
sudo bash -x /opt/manutencao/manutencao-completa.sh

# Executar e acompanhar em tempo real
sudo /opt/manutencao/manutencao-completa.sh | tee /tmp/teste-manutencao.log
```

## Verificar se cron está funcionando

```bash
# Ver crontab ativa
sudo crontab -l

# Ver logs do cron
sudo grep CRON /var/log/syslog | tail -20

# Ver execuções da manutenção
sudo grep manutencao-completa /var/log/syslog
```

## Problemas comuns e soluções

|Problema|Causa Provável|Solução|
|---|---|---|
|Script não executa automaticamente|Cron não configurado|Verifique `sudo crontab -l`|
|"Permission denied"|Falta permissão de execução|`sudo chmod +x /opt/manutencao/*.sh`|
|Docker não limpa|Volumes em uso pelo Coolify|Normal, volumes ativos são preservados|
|Updates não aplicam|unattended-upgrades mal configurado|Rode `sudo unattended-upgrade -d` e veja errors|
|Disco continua cheio|Logs de aplicação (não do sistema)|Verifique `/var/lib/docker/volumes` e logs de apps|
|Backup falha no PostgreSQL|Container coolify-db não rodando|`docker ps` e verifique se está saudável|
|SSH keys não são copiadas|Diretório não existe|Verifique `/data/coolify/ssh/keys`|
|Restauração falha|APP_KEY incorreta|Use exatamente a APP_KEY do backup original|

## Troubleshooting de backups

```bash
# Verificar se backup foi criado
ls -lh /root/coolify-backups/

# Ver conteúdo de um backup sem extrair
tar -tzf /root/coolify-backups/20250118_020000.tar.gz | head -20

# Extrair apenas o backup-info.txt para ver detalhes
tar -xzf /root/coolify-backups/20250118_020000.tar.gz --strip-components=1 */backup-info.txt

# Verificar integridade do backup
tar -tzf /root/coolify-backups/20250118_020000.tar.gz > /dev/null
echo $? # Se retornar 0, backup está OK

# Verificar tamanho do banco de dados backup
tar -xzOf /root/coolify-backups/20250118_020000.tar.gz */coolify-db-*.dmp | wc -c

# Ver log do último backup
tail -100 /var/log/manutencao/backup-coolify.log

# Testar restauração do banco em container temporário
docker run --name test-pg -e POSTGRES_PASSWORD=test -d postgres:15-alpine
cat backup/coolify-db-*.dmp | docker exec -i test-pg pg_restore --verbose -U postgres -d postgres
docker rm -f test-pg
```

## Dashboard de monitoramento completo

Para monitorar tudo em um só lugar, você pode usar ferramentas como:

### Opção 1: Uptime Kuma (simples e visual)

```bash
# Instalar Uptime Kuma via Docker
docker run -d --restart=always \
  -p 3001:3001 \
  -v uptime-kuma:/app/data \
  --name uptime-kuma \
  louislam/uptime-kuma:1

# Acessar: http://seu-ip:3001
```

Configure monitores para:

- Status do Coolify (HTTP monitor em localhost:8000)
- Espaço em disco (via script + webhook)
- Execução dos backups (via healthchecks.io)

### Opção 2: Healthchecks.io (pings)

```bash
# Adicionar ao final de cada script antes do exit 0:

HEALTHCHECK_MANUTENCAO="https://hc-ping.com/seu-uuid-manutencao"
HEALTHCHECK_BACKUP="https://hc-ping.com/seu-uuid-backup"

# No script de manutenção:
curl -fsS --retry 3 "$HEALTHCHECK_MANUTENCAO" > /dev/null

# No script de backup:
curl -fsS --retry 3 "$HEALTHCHECK_BACKUP" > /dev/null
```

## Alertas avançados

### Alert por Telegram

```bash
# Configurar bot do Telegram
# 1. Fale com @BotFather no Telegram
# 2. Crie um bot e pegue o token
# 3. Pegue seu chat_id falando com @userinfobot

TELEGRAM_BOT_TOKEN="seu-token"
TELEGRAM_CHAT_ID="seu-chat-id"

# Função para enviar mensagem
telegram_alert() {
    local mensagem="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
         -d chat_id="${TELEGRAM_CHAT_ID}" \
         -d text="$mensagem" \
         -d parse_mode="HTML" > /dev/null
}

# Usar no script:
telegram_alert "🔧 Manutenção do VPS concluída
💾 Disco: ${ESPACO_FINAL}%
📦 Espaço recuperado: ${ECONOMIZADO_TOTAL}%"
```

### Alert por Discord

```bash
# Pegar webhook URL:
# Discord → Server Settings → Integrations → Webhooks

DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."

discord_alert() {
    local titulo="$1"
    local mensagem="$2"
    local cor="$3"  # 3066993 (verde), 15158332 (vermelho), 16776960 (amarelo)
    
    curl -H "Content-Type: application/json" \
         -d "{
           \"embeds\": [{
             \"title\": \"$titulo\",
             \"description\": \"$mensagem\",
             \"color\": $cor,
             \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
           }]
         }" \
         "$DISCORD_WEBHOOK" > /dev/null 2>&1
}

# Usar no script:
discord_alert "✅ Manutenção Concluída" "Espaço recuperado: ${ECONOMIZADO_TOTAL}%" 3066993
```

---

# Checklist de implementação completa

## ✅ Fase 1: Preparação (15 min)

- [ ] Fiz backup/snapshot do VPS
- [ ] Rodei diagnóstico inicial
- [ ] Anotei espaço atual: ____%
- [ ] Anotei versão do Coolify: _______

## ✅ Fase 2: Updates Automáticos (10 min)

- [ ] Instalei `unattended-upgrades`
- [ ] Configurei políticas de atualização
- [ ] Testei com dry-run
- [ ] Verifiquei logs

## ✅ Fase 3: Limpeza Inicial (20 min)

- [ ] Limpei Docker manualmente
- [ ] Removi pacotes órfãos
- [ ] Limpei kernels antigos
- [ ] Limpei logs antigos
- [ ] Anotei espaço recuperado: ____%

## ✅ Fase 4: Script de Manutenção (15 min)

- [ ] Criei `/opt/manutencao/manutencao-completa.sh`
- [ ] Configurei variáveis (email, webhook)
- [ ] Tornei executável
- [ ] Testei manualmente
- [ ] Verifiquei log gerado

## ✅ Fase 5: Script de Backup (20 min)

- [ ] Criei `/opt/manutencao/backup-coolify.sh`
- [ ] Configurei retenção de backups
- [ ] Configurei notificações
- [ ] Tornei executável
- [ ] Testei manualmente
- [ ] Verifiquei backup criado
- [ ] Li arquivo backup-info.txt

## ✅ Fase 6: Automação (10 min)

- [ ] Configurei cron completo
- [ ] Verifiquei horários
- [ ] Testei execução via cron (aguardei próxima execução)
- [ ] Verifiquei logs do cron

## ✅ Fase 7: Monitoramento (15 min)

- [ ] Criei script `status-completo`
- [ ] Configurei alerta de disco
- [ ] Configurei notificações (Telegram/Discord/Email)
- [ ] Testei alertas

## ✅ Fase 8: Backup Off-site (30 min) [OPCIONAL]

- [ ] Configurei servidor remoto OU
- [ ] Configurei S3/Cloud storage
- [ ] Testei envio de backup
- [ ] Verifiquei backup no destino remoto

## ✅ Fase 9: Teste de Restauração (60 min) [CRÍTICO]

- [ ] Criei VPS de teste
- [ ] Baixei um backup
- [ ] Segui procedimento de restauração
- [ ] Verifiquei se Coolify funciona
- [ ] Documentei problemas encontrados

## ✅ Fase 10: Documentação (15 min)

- [ ] Documentei configurações customizadas
- [ ] Salvei credenciais em local seguro
- [ ] Criei runbook de emergência
- [ ] Agendei revisão mensal no calendário

**Tempo total estimado: 3-4 horas**

---

# Estratégia de disaster recovery

## Cenários e procedimentos

### 🔥 Cenário 1: Servidor comprometido/hackeado

```bash
# 1. IMEDIATO: Isolar servidor
sudo ufw deny in from any

# 2. Criar novo VPS limpo
# (usar painel da Hostinger)

# 3. Baixar último backup
scp servidor-antigo:/root/coolify-backups/latest.tar.gz .

# 4. Instalar Coolify no novo servidor
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# 5. Restaurar backup
tar -xzf latest.tar.gz
cd [diretório-extraído]
# Seguir instruções em backup-info.txt

# 6. Atualizar DNS para apontar para novo IP

# 7. Investigar como foi comprometido
# (analisar logs do servidor antigo)
```

### 💥 Cenário 2: Disco cheio, Coolify parou

```bash
# 1. Verificar o que está ocupando espaço
du -h --max-depth=1 / | sort -rh | head -20

# 2. Limpeza emergencial
docker system prune -a --volumes -f
apt-get clean
journalctl --vacuum-time=1d

# 3. Se necessário, expandir disco
# (usar painel da Hostinger para resize)

# 4. Reiniciar Coolify
docker restart $(docker ps -a --filter name=coolify --format "{{.Names}}")

# 5. Verificar saúde
docker ps --filter name=coolify

# 6. Executar script de manutenção
/opt/manutencao/manutencao-completa.sh
```

### 🗄️ Cenário 3: Banco de dados corrompido

```bash
# 1. Parar Coolify (exceto DB)
docker ps --filter name=coolify --format '{{.Names}}' | \
  grep -v coolify-db | xargs docker stop

# 2. Fazer backup do estado atual (corrupto)
docker exec coolify-db pg_dump -U coolify -d coolify -F c > /tmp/corrupted-backup.dmp

# 3. Restaurar do último backup bom
cd /root/coolify-backups
tar -xzf [ultimo-backup-bom].tar.gz
cd [diretório]

cat coolify-db-*.dmp | docker exec -i coolify-db pg_restore \
  --verbose --clean --no-acl --no-owner -U coolify -d coolify

# 4. Reiniciar Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# 5. Verificar integridade
docker logs coolify
```

### ⚡ Cenário 4: Migração urgente para novo servidor

```bash
# Use o script de migração que você já tem!
# Ajuste as variáveis no topo do script:

NEW_SERVER_IP="novo-ip"
NEW_SERVER_USER="root"
NEW_SERVER_PORT="22"
BACKUP_FILE="/root/coolify-backups/latest.tar.gz"

# Execute
./migrar-coolify.sh
```

## Runbook de emergência

Imprima e mantenha em local acessível:

```
╔═══════════════════════════════════════════════════════════╗
║           RUNBOOK DE EMERGÊNCIA - COOLIFY VPS             ║
╚═══════════════════════════════════════════════════════════╝

📞 CONTATOS
  ├─ Suporte Hostinger: [seu-link]
  ├─ Discord Coolify: https://discord.gg/coolify
  └─ Documentação: https://coolify.io/docs

🔑 ACESSOS
  ├─ IP do VPS: __________________
  ├─ SSH: ssh root@__________________
  ├─ Coolify Web: http://________________:8000
  └─ Senhas em: [seu-gerenciador-de-senhas]

📦 BACKUPS
  ├─ Local: /root/coolify-backups/
  ├─ Remoto: [seu-storage]/coolify/
  └─ Último backup: [data] às [hora]

🚨 COMANDOS RÁPIDOS

Ver status geral:
  status-completo

Espaço em disco crítico:
  docker system prune -a --volumes -f
  apt-get clean
  journalctl --vacuum-time=1d

Coolify não responde:
  docker restart $(docker ps -qa --filter name=coolify)
  docker logs coolify

Banco corrompido:
  cd /root/coolify-backups
  tar -xzf [ultimo-backup].tar.gz
  # Seguir instruções em backup-info.txt

Restaurar backup completo:
  1. cd /root/coolify-backups
  2. tar -xzf [arquivo].tar.gz
  3. cat backup-info.txt
  4. Seguir instruções

Migração emergencial:
  # Usar script: /root/migrar-coolify.sh
  # Editar variáveis no topo do script
  # Executar: bash migrar-coolify.sh

🔍 LOGS
  ├─ Manutenção: /var/log/manutencao/manutencao.log
  ├─ Backup: /var/log/manutencao/backup-coolify.log
  ├─ Coolify: docker logs coolify
  └─ Sistema: /var/log/syslog

📞 QUEM CHAMAR
  ├─ Servidor offline > 15min: Suporte Hostinger
  ├─ Banco corrompido: Restaurar backup
  ├─ Disk full: Limpeza emergencial
  └─ Hacked: Isolar + novo servidor + restaurar backup
```

---

# Otimizações avançadas

## Compressão de backups com diferentes níveis

```bash
# No script backup-coolify.sh, trocar linha de compressão por:

# Compressão rápida (menos CPU, arquivo maior)
tar -czf --use-compress-program="gzip -1" "${BACKUP_BASENAME}.tar.gz" "$BACKUP_BASENAME"

# Compressão balanceada (padrão)
tar -czf "${BACKUP_BASENAME}.tar.gz" "$BACKUP_BASENAME"

# Compressão máxima (mais CPU, arquivo menor)
tar -czf --use-compress-program="gzip -9" "${BACKUP_BASENAME}.tar.gz" "$BACKUP_BASENAME"

# Compressão com pigz (paralelo, muito mais rápido)
apt install pigz -y
tar -cf - "$BACKUP_BASENAME" | pigz -p 4 > "${BACKUP_BASENAME}.tar.gz"
```

## Backup incremental (avançado)

Para economizar espaço com backups incrementais:

```bash
#!/bin/bash
# backup-incremental.sh

BACKUP_BASE="/root/coolify-backups"
FULL_BACKUP_DAY=0  # Domingo = backup completo
INCREMENTAL_DIR="$BACKUP_BASE/incrementais"

mkdir -p "$INCREMENTAL_DIR"

DIA_SEMANA=$(date +%u)  # 1-7 (segunda-domingo)

if [ "$DIA_SEMANA" -eq "$FULL_BACKUP_DAY" ]; then
    # Backup completo
    /opt/manutencao/backup-coolify.sh
else
    # Backup incremental (apenas arquivos modificados)
    ULTIMO_COMPLETO=$(ls -t $BACKUP_BASE/*.tar.gz | head -1)
    REFERENCIA=$(date -r "$ULTIMO_COMPLETO" +%Y%m%d)
    
    INCREMENTAL_FILE="$INCREMENTAL_DIR/incremental-$(date +%Y%m%d).tar.gz"
    
    # Backup apenas de arquivos modificados desde último completo
    find /data/coolify -newer "$ULTIMO_COMPLETO" -type f | \
      tar -czf "$INCREMENTAL_FILE" -T -
    
    echo "Backup incremental criado: $INCREMENTAL_FILE"
fi
```

## Criptografia de backups

```bash
# Instalar gpg
apt install gnupg -y

# Gerar chave (se não tiver)
gpg --full-generate-key

# No script backup-coolify.sh, após compactar:

GPG_RECIPIENT="seu-email@exemplo.com"

if command -v gpg &> /dev/null; then
    log "--- Criptografando backup ---"
    
    gpg --encrypt --recipient "$GPG_RECIPIENT" \
        --output "${BACKUP_BASENAME}.tar.gz.gpg" \
        "${BACKUP_BASENAME}.tar.gz"
    
    if [ $? -eq 0 ]; then
        rm "${BACKUP_BASENAME}.tar.gz"  # Remove versão não criptografada
        log_success "Backup criptografado"
    fi
fi

# Para descriptografar:
# gpg --decrypt backup.tar.gz.gpg > backup.tar.gz
```

---

---

# 🎯 Checklist de implementação

Use esta checklist para garantir que implementou tudo corretamente:

## ✅ Fase 1: Preparação

- [ ] Fiz backup/snapshot do VPS
- [ ] Rodei diagnóstico inicial (`df -h`, `docker system df`)
- [ ] Anotei espaço atual em disco: ____%

## ✅ Fase 2: Configuração de Updates

- [ ] Instalei `unattended-upgrades`
- [ ] Configurei `/etc/apt/apt.conf.d/50unattended-upgrades`
- [ ] Configurei `/etc/apt/apt.conf.d/20auto-upgrades`
- [ ] Testei com `sudo unattended-upgrade --dry-run`

## ✅ Fase 3: Limpeza Manual Inicial

- [ ] Limpei Docker (`docker system prune`)
- [ ] Removi pacotes órfãos (`apt autoremove`)
- [ ] Limpei kernels antigos
- [ ] Limpei logs (`journalctl --vacuum-time=30d`)

## ✅ Fase 4: Automação

- [ ] Criei `/opt/manutencao/manutencao-completa.sh`
- [ ] Tornei script executável (`chmod +x`)
- [ ] Testei script manualmente
- [ ] Configurei cron (`sudo crontab -e`)
- [ ] Configurei notificações (email/webhook) [opcional]

## ✅ Fase 5: Monitoramento

- [ ] Criei script `status-vps`
- [ ] Configurei alerta de disco cheio
- [ ] Agendei revisão mensal no calendário

---

# 📅 Rotina de manutenção recomendada

## Automático (sem intervenção)

- **Diário**: Updates de segurança via unattended-upgrades
- **Semanal**: Script completo de limpeza (toda segunda às 3h)
- **Mensal**: Backup de logs antigos

## Manual (revisão)

- **Semanal**: Rodar `status-vps` para ver estado geral
- **Mensal**:
	- Ler relatórios de manutenção (`tail -100 /var/log/manutencao/manutencao.log`)
	- Verificar se há alertas de disco cheio
	- Testar aplicações rapidamente
- **Trimestral**:
	- Revisar volumes Docker órfãos manualmente
	- Considerar upgrade de kernel (com reboot planejado)
	- Atualizar documentação de serviços rodando

---

# 🚨 Quando fazer manutenção manual urgente

Execute o script imediatamente SE:

1. **Disco > 85% cheio** → Risco de aplicações caírem
2. **CVE crítica publicada** → Vulnerabilidade zero-day conhecida
3. **Kernel com bug grave** → Pode causar crash do sistema
4. **Docker ocupa > 50% do disco** → Lixo acumulado demais

---

# 📝 Customizações avançadas

## Personalizar horário de execução

```bash
# Editar cron
sudo crontab -e

# Exemplos de horários alternativos:
# Domingo às 4h (menos tráfego em sites)
0 4 * * 0 /opt/manutencao/manutencao-completa.sh

# Todo dia às 2h (manutenção mais frequente)
0 2 * * * /opt/manutencao/manutencao-completa.sh

# Dia 1 e 15 de cada mês às 3h
0 3 1,15 * * /opt/manutencao/manutencao-completa.sh
```

## Adicionar mais verificações ao script

Adicione antes da seção "7. RELATÓRIO FINAL":

```bash
################################################################################
# VERIFICAÇÕES EXTRAS (CUSTOMIZAÇÃO)
################################################################################

log "--- Verificações extras ---"

# Verificar uso de memória
MEMORIA_USADA=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ "$MEMORIA_USADA" -gt 90 ]; then
    log_warning "Memória em ${MEMORIA_USADA}% de uso"
fi

# Verificar serviços críticos
SERVICOS_CRITICOS=("nginx" "docker" "ssh")
for servico in "${SERVICOS_CRITICOS[@]}"; do
    if systemctl is-active --quiet "$servico"; then
        log_success "Serviço $servico: ativo"
    else
        log_error "Serviço $servico: INATIVO!"
        notificar "⚠️  Serviço $servico está parado no VPS $(hostname)"
    fi
done

# Verificar certificados SSL (se usa Nginx)
if [ -d /etc/letsencrypt/live ]; then
    CERT_MAIS_ANTIGO=$(find /etc/letsencrypt/live -name cert.pem -exec stat -c %Y {} \; | sort -n | head -1)
    CERT_IDADE=$(( ($(date +%s) - CERT_MAIS_ANTIGO) / 86400 ))
    
    if [ "$CERT_IDADE" -gt 80 ]; then
        log_warning "Certificado SSL com $CERT_IDADE dias (renova aos 90)"
    fi
fi
```

## Integrar com ferramentas de monitoramento

### Healthchecks.io (ping quando script termina)

```bash
# No final do script, antes do exit 0:
HEALTHCHECK_URL="https://hc-ping.com/seu-uuid-aqui"

if [ "$ESPACO_FINAL" -le "$DISCO_LIMITE" ]; then
    curl -fsS --retry 3 "$HEALTHCHECK_URL" > /dev/null
else
    curl -fsS --retry 3 "$HEALTHCHECK_URL/fail" > /dev/null
fi
```

### Prometheus Node Exporter

```bash
# Instalar
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
sudo useradd -rs /bin/false node_exporter

# Criar serviço
sudo nano /etc/systemd/system/node_exporter.service
```

```ini
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```

---

# 🔒 Considerações de segurança

## O que o script FAZ

✅ Atualiza apenas pacotes de segurança oficiais  
✅ Remove containers/imagens não usados  
✅ Preserva volumes montados (dados seguros)  
✅ Mantém kernel atual + 1 anterior (rollback possível)  
✅ Loga todas ações para auditoria

## O que o script NÃO FAZ (por segurança)

❌ Não remove volumes automaticamente (pode perder dados)  
❌ Não faz reboot automático (evita downtime inesperado)  
❌ Não atualiza pacotes não-oficiais (mantém estabilidade)  
❌ Não modifica configurações de aplicações  
❌ Não toca em `/opt/coolify` ou configs customizadas

## Recomendações adicionais

1. **Firewall básico:**

```bash
# Instalar e configurar UFW
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

2. **Fail2ban contra brute force:**

```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

3. **Backups regulares:**

```bash
# Adicionar ao cron (backup semanal)
0 5 * * 0 tar -czf /root/backup-$(date +\%Y\%m\%d).tar.gz /opt/coolify /etc/nginx /var/lib/docker/volumes && find /root/backup-*.tar.gz -mtime +30 -delete
```

---

# 🎓 Aprendizados e boas práticas

## Por que essa abordagem funciona

1. **Automatização conservadora**: Atualiza apenas segurança, não quebra estabilidade
2. **Logs detalhados**: Tudo registrado para troubleshooting
3. **Segurança em camadas**: Remove lixo mas preserva dados críticos
4. **Mínima intervenção**: Roda sozinho, você só revisa mensalmente

## Errors comuns a evitar

❌ **Não fazer:** `apt full-upgrade -y` automaticamente  
✅ **Fazer:** Apenas updates de segurança automáticos

❌ **Não fazer:** `docker system prune -a --volumes -f` sem critério  
✅ **Fazer:** Remover apenas dangling, revisar volumes manualmente

❌ **Não fazer:** Ignorar alertas de disco > 80%  
✅ **Fazer:** Investigar imediatamente o que está consumindo espaço

❌ **Não fazer:** Confiar cegamente em automação  
✅ **Fazer:** Revisar logs mensalmente

## Filosofia "set and forget" realista

```
"Set and forget" NÃO significa:
  ❌ Nunca mais olhar o servidor
  ❌ Zero manutenção para sempre
  ❌ Ignorar problemas

"Set and forget" SIGNIFICA:
  ✅ Automatizar tarefas repetitivas
  ✅ Reduzir intervenções manuais
  ✅ Revisar periodicamente (não diariamente)
  ✅ Sistema se mantém saudável sozinho
```

---

# 📞 Próximos passos

Após implementar este guia:

## Semana 1

- [ ] Executar script manualmente 2-3 vezes
- [ ] Observar se aplicações continuam funcionando
- [ ] Ajustar horário de cron se necessário

## Mês 1

- [ ] Revisar logs semanalmente
- [ ] Verificar se notificações estão chegando
- [ ] Ajustar limites de disco/memória conforme seu uso

## Mês 3

- [ ] Considerar atualização de kernel (com reboot planejado)
- [ ] Revisar volumes Docker órfãos
- [ ] Atualizar documentação do que está rodando

## Annual

- [ ] Considerar upgrade de versão do Ubuntu (ex: 20.04 → 22.04)
- [ ] Revisar estratégia de backup
- [ ] Avaliar se VPS precisa upgrade de recursos

---

# 🎯 Conclusão

Você agora tem:

1. ✅ **Updates de segurança automáticos** - Sistema protegido contra CVEs
2. ✅ **Limpeza semanal automatizada** - Disco sempre otimizado
3. ✅ **Monitoramento contínuo** - Alertas quando algo está errado
4. ✅ **Logs detalhados** - Troubleshooting facilitado
5. ✅ **Zero intervenção diária** - Apenas revisão mensal

## TL;DR - Commandos essenciais

```bash
# 1. Instalar dependências
sudo apt install unattended-upgrades apt-listchanges -y

# 2. Baixar e configurar script
sudo mkdir -p /opt/manutencao /var/log/manutencao
sudo nano /opt/manutencao/manutencao-completa.sh
# [Cole o script completo acima]
sudo chmod +x /opt/manutencao/manutencao-completa.sh

# 3. Testar manualmente
sudo /opt/manutencao/manutencao-completa.sh

# 4. Agendar execução
sudo crontab -e
# Adicione: 0 3 * * 1 /opt/manutencao/manutencao-completa.sh

# 5. Verificar status
tail -100 /var/log/manutencao/manutencao.log
```

**Seu servidor agora está preparado para rodar de forma segura e estável por anos** 🚀

---

# 📚 Recursos adicionais

- [Documentação oficial do unattended-upgrades](https://wiki.debian.org/UnattendedUpgrades)
- [Melhores práticas Docker](https://docs.docker.com/develop/dev-best-practices/)
- [Guia de segurança Ubuntu](https://ubuntu.com/security)
- [Coolify Documentation](https://coolify.io/docs)

---

**Versão:** 2.0  
**Última atualização:** Outubro 2025  
**Compatibilidade:** Ubuntu 20.04, 22.04, 24.04 | Debian 11, 12