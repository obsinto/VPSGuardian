# 🏥 Script de Verificação de Saúde Completa

## 📋 Visão Geral

O script `verificar-saude-completa.sh` é uma ferramenta abrangente que verifica **todos os aspectos** da saúde do seu servidor, incluindo:

- ✅ Sistema operacional e recursos (CPU, RAM, disco)
- ✅ Serviços essenciais (Docker, SSH, firewall)
- ✅ Cloudflare Tunnels e WARP
- ✅ Containers Docker e Coolify
- ✅ Bancos de dados (PostgreSQL, MySQL, MongoDB, Redis)
- ✅ Firewall e segurança
- ✅ Backups e tarefas agendadas
- ✅ Rede e conectividade
- ✅ Logs e erros recentes
- ✅ **Score de saúde** do servidor (0-100)

---

## 🚀 Como Usar

### Execução Básica

```bash
# Navegar até o diretório
cd ~/manutencao_backup_vps/scripts-auxiliares

# Executar o script
sudo ./verificar-saude-completa.sh
```

### Criar Alias (Recomendado)

Para facilitar o acesso de qualquer lugar:

```bash
# Adicionar ao ~/.bashrc
echo "alias saude='sudo ~/manutencao_backup_vps/scripts-auxiliares/verificar-saude-completa.sh'" >> ~/.bashrc

# Recarregar configuração
source ~/.bashrc

# Agora pode executar de qualquer lugar:
saude
```

### Salvar Relatório em Arquivo

```bash
# Salvar output em arquivo
sudo ./verificar-saude-completa.sh > relatorio-saude-$(date +%Y%m%d-%H%M%S).txt

# Ou com cores preservadas
sudo ./verificar-saude-completa.sh | tee relatorio-saude.txt
```

---

## 📊 Seções do Relatório

### 1️⃣ Sistema Operacional

```
▶ Informações Básicas
  SO: Ubuntu 22.04.3 LTS
  Versão: 22.04.3 LTS (Jammy Jellyfish)
  Kernel: 5.15.0-89-generic
  Arquitetura: x86_64
  Uptime: 15 days, 3 hours, 22 minutes
```

**O que verifica:**
- Distribuição e versão do SO
- Kernel em uso
- Tempo desde a última reinicialização

---

### 2️⃣ Recursos do Sistema

```
▶ CPU
  Modelo: Intel(R) Xeon(R) CPU E5-2650 v4
  Cores: 4
  Uso: 25%

▶ Memória RAM
  Total: 8.0G
  Usado: 3.2G (40%)

▶ Disco /
  Total: 80G
  Usado: 32G (40%)
```

**O que verifica:**
- Uso de CPU (alertas se >80%)
- Uso de memória (alertas se >90%)
- Uso de disco (alertas se >85%)
- Load average do sistema

**🚨 Alertas:**
- Verde: <70%
- Amarelo: 70-85%
- Vermelho: >85%

---

### 3️⃣ Ferramentas Instaladas

```
▶ Verificando Instalação
  ✓ Docker instalado
  ✓ Docker Compose instalado
  ✓ Cloudflared instalado
  ✓ WARP CLI instalado
  ✓ UFW (Firewall) instalado
  ✗ Fail2Ban NÃO instalado
```

**O que verifica:**
- Presença de ferramentas essenciais
- Indica o que está faltando

---

### 4️⃣ Serviços do Sistema

```
▶ Serviços Críticos
  ✓ SSH: Ativo
  ✓ Docker: Ativo
  ✓ Firewall (UFW): Ativo

▶ Cloudflare
  ✓ Cloudflared Tunnel: Ativo
  ✓ Túnel conectado à Cloudflare

▶ WARP
  ✓ WARP: Conectado
```

**O que verifica:**
- Status dos serviços com `systemctl`
- Conectividade do túnel Cloudflare
- Status da conexão WARP

---

### 5️⃣ Docker

```
▶ Informações Docker
  Versão: 24.0.7

▶ Containers
  Rodando: 12 de 15

  NAMES                     STATUS              PORTS
  coolify                   Up 5 days           0.0.0.0:8000->8000/tcp
  coolify-db                Up 5 days           5432/tcp
  coolify-redis             Up 5 days           6379/tcp
  netdata                   Up 3 days           0.0.0.0:19999->19999/tcp

▶ Uso de Recursos Docker
  TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
  Images          25        12        8.5GB     4.2GB (49%)
  Containers      15        12        2.1GB     150MB (7%)
  Local Volumes   8         8         1.2GB     0B (0%)
```

**O que verifica:**
- Versão do Docker
- Containers rodando vs parados
- Portas expostas
- Espaço ocupado por imagens/containers/volumes

---

### 6️⃣ Coolify

```
▶ Status
  ✓ Coolify está rodando
  Imagem: ghcr.io/coollabsio/coolify:latest

▶ Containers Coolify
  • coolify - Up 5 days
  • coolify-db - Up 5 days
  • coolify-redis - Up 5 days
  • coolify-proxy - Up 5 days

  ✓ Porta 8000 (UI) está escutando
```

**O que verifica:**
- Se Coolify está rodando
- Versão da imagem
- Containers relacionados
- Acessibilidade da UI (porta 8000)

---

### 7️⃣ Firewall (UFW)

```
▶ Política Padrão
  Default: deny (incoming), allow (outgoing)

▶ Regras Principais
  [1] 80/tcp         ALLOW IN    Anywhere
  [2] 443/tcp        ALLOW IN    Anywhere
  [3] Anywhere       ALLOW IN    100.64.0.0/10

▶ Proteção Docker (DOCKER-USER)
  ✓ Regras DOCKER-USER configuradas (permite WARP)
```

**O que verifica:**
- Se UFW está ativo
- Política padrão
- Portas abertas (80, 443)
- Regra WARP (100.64.0.0/10)
- Integração com Docker (DOCKER-USER chain)

---

### 8️⃣ Portas em Escuta

```
▶ Portas TCP
  SSH (22)        - sshd
  HTTP (80)       - nginx
  HTTPS (443)     - nginx
  PostgreSQL (5432) - docker-proxy
  Coolify (8000)  - docker-proxy
  Netdata (19999) - docker-proxy
```

**O que verifica:**
- Todas as portas TCP escutando
- Processo associado a cada porta
- Destaque visual para portas conhecidas

---

### 9️⃣ Cloudflare Tunnels

```
▶ Status do Serviço
  ✓ Cloudflared está rodando
  ✓ Arquivo de configuração encontrado

▶ Configuração
  tunnel: abc123-xyz-456
  credentials-file: /root/.cloudflared/abc123.json
  Hostnames públicos: 5

▶ Status da Conexão (últimos logs)
  ✓ Sem erros recentes
  Jan 19 10:30:15 Registered tunnel connection
  Jan 19 10:30:16 Connection established
```

**O que verifica:**
- Serviço cloudflared ativo
- Configuração válida
- Quantidade de hostnames públicos
- Erros recentes nos logs

---

### 🔟 Bancos de Dados

```
▶ PostgreSQL
  ✓ 3 container(s) PostgreSQL rodando
  • coolify-db - Porta: 5432
  • app-postgres-1 - Porta: 5433
  • analytics-db - Porta: 5434

▶ MySQL/MariaDB
  ℹ Nenhum MySQL/MariaDB detectado

▶ MongoDB
  ℹ Nenhum MongoDB detectado

▶ Redis
  ✓ 2 container(s) Redis rodando
```

**O que verifica:**
- Containers de bancos de dados rodando
- Portas expostas
- Tipos de bancos detectados

---

### 1️⃣1️⃣ Backups

```
▶ Diretório de Backups
  ✓ Diretório existe
  Total de backups: 12

  Último backup:
    • Arquivo: coolify-backup-20250119-020001.tar.gz
    • Tamanho: 2.3G
    • Data: 2025-01-19 02:00:15
    • Idade: Hoje

▶ Scripts de Backup
  ✓ Script backup-coolify.sh encontrado
  ✓ Script backup-databases.sh encontrado
```

**O que verifica:**
- Existência do diretório de backups
- Quantidade total de backups
- Informações do backup mais recente
- Idade do último backup (alerta se >7 dias)
- Presença dos scripts de backup

**🚨 Alertas:**
- Verde: backup de hoje ou ontem
- Amarelo: backup de 2-7 dias
- Vermelho: backup >7 dias

---

### 1️⃣2️⃣ Cron Jobs

```
▶ Cron do Root
  ✓ 3 tarefa(s) agendada(s)

  0 2 * * 0 /root/manutencao_backup_vps/backup/backup-coolify.sh
  0 3 * * 1 /root/manutencao_backup_vps/manutencao/manutencao-completa.sh
  0 9 * * * /root/manutencao_backup_vps/scripts-auxiliares/verificar-saude-completa.sh
```

**O que verifica:**
- Tarefas agendadas no crontab do root
- Lista todas as tarefas ativas

---

### 1️⃣3️⃣ Segurança

```
▶ SSH
  ✓ Root login: prohibit-password
  ✓ Autenticação por senha: Desabilitada

▶ Fail2Ban
  ✓ Fail2Ban está ativo
  IPs banidos (SSH): 3

▶ Updates de Segurança
  ✓ Sem updates de segurança pendentes

▶ Login Recentes
  Últimos logins:
    root   pts/0   192.168.1.100   Sat Jan 19 09:15
    root   pts/1   100.64.25.33    Fri Jan 18 14:30
```

**O que verifica:**
- Configuração SSH (PermitRootLogin, PasswordAuthentication)
- Status do Fail2Ban
- IPs banidos recentemente
- Updates de segurança pendentes
- Últimos logins ao sistema

---

### 1️⃣4️⃣ Rede

```
▶ Interfaces de Rede
  lo       UNKNOWN   127.0.0.1/8 ::1/128
  eth0     UP        31.97.23.42/24

▶ Conectividade
  ✓ Internet (IPv4): OK
  ℹ Internet (IPv6): Não disponível

▶ DNS
  ✓ Resolução DNS: OK
```

**O que verifica:**
- Interfaces de rede ativas
- Conectividade IPv4 (ping para 1.1.1.1)
- Conectividade IPv6 (se disponível)
- Resolução DNS

---

### 1️⃣5️⃣ Atualizações do Sistema

```
▶ Pacotes Atualizáveis
  ℹ 5 pacote(s) disponível(is) para atualização

▶ Último apt update
  Data: 2025-01-18 03:00:12
```

**O que verifica:**
- Quantidade de pacotes que podem ser atualizados
- Data do último `apt update`

---

### 1️⃣6️⃣ Logs Importantes

```
▶ Erros Críticos no Sistema (últimas 24h)
  ⚠ 3 erro(s) encontrado(s)
  Visualize com: journalctl --since '24 hours ago' -p err

▶ Logs de Autenticação SSH (últimas 10 tentativas)
  Jan 19 09:15:22 Accepted publickey for root from 192.168.1.100
  Jan 18 14:30:11 Accepted publickey for root from 100.64.25.33
```

**O que verifica:**
- Erros críticos no journalctl (últimas 24h)
- Tentativas de login SSH recentes
- Logs de autenticação

---

### 📊 Resumo Geral (SCORE)

```
  🏆 SAÚDE DO SERVIDOR: EXCELENTE
  Score: 95/100
  Problemas encontrados: 1

  Recomendações:
    • Atualizar sistema: sudo apt update && sudo apt upgrade
```

**Como o score é calculado:**

| Problema | Penalidade |
|----------|------------|
| Docker não rodando | -20 pontos |
| UFW inativo | -15 pontos |
| Cloudflared parado | -15 pontos |
| Disco >85% | -10 pontos |
| Memória >90% | -10 pontos |
| Backup >7 dias | -10 pontos |
| Security updates pendentes | -5 pontos |

**Classificação:**
- 🏆 **90-100**: Excelente (verde)
- ⚠️ **70-89**: Boa (amarelo)
- 🔥 **50-69**: Regular (laranja)
- 💀 **0-49**: Crítica (vermelho)

---

## 🎨 Legenda de Símbolos

| Símbolo | Significado |
|---------|-------------|
| ✓ (verde) | Tudo OK, funcionando corretamente |
| ✗ (vermelho) | Erro crítico, não instalado/ativo |
| ⚠ (amarelo) | Aviso, atenção necessária |
| ℹ (azul) | Informação, não é erro |

---

## 📅 Uso Recomendado

### Diário (Automático)

Configure no cron para executar todos os dias:

```bash
# Editar crontab
crontab -e

# Adicionar linha (executa às 9h da manhã)
0 9 * * * /root/manutencao_backup_vps/scripts-auxiliares/verificar-saude-completa.sh > /var/log/saude/$(date +\%Y\%m\%d).log 2>&1
```

### Manual

Execute sempre que:
- ✅ Fizer mudanças na infraestrutura
- ✅ Suspeitar de problemas de performance
- ✅ Antes de aplicar updates críticos
- ✅ Após reinicializações
- ✅ Investigar alertas de monitoramento

---

## 🔧 Personalização

### Adicionar Novas Verificações

Edite o script e adicione uma nova seção:

```bash
# Localização
nano ~/manutencao_backup_vps/scripts-auxiliares/verificar-saude-completa.sh

# Adicionar após a última seção (antes do resumo):
print_header "1️⃣7️⃣ MINHA VERIFICAÇÃO CUSTOMIZADA"

print_section "Verificar Meu Serviço"
if systemctl is-active --quiet meu-servico; then
    echo -e "  $CHECK Meu serviço está rodando"
else
    echo -e "  $CROSS Meu serviço está parado"
fi
```

### Ajustar Thresholds de Alerta

No script, localize as variáveis:

```bash
# Exemplo: Mudar alerta de disco de 85% para 90%
if [ "$DISK_PERCENT" -gt 90 ]; then  # Era 85
    HEALTH_SCORE=$((HEALTH_SCORE - 10))
fi
```

---

## 🐛 Troubleshooting

### Problema: "Permission denied"

**Solução:**
```bash
# Tornar executável
chmod +x ~/manutencao_backup_vps/scripts-auxiliares/verificar-saude-completa.sh

# Executar com sudo
sudo ./verificar-saude-completa.sh
```

### Problema: Cores não aparecem

**Causa:** Terminal não suporta cores ANSI.

**Solução:**
```bash
# Forçar output sem cores
sudo ./verificar-saude-completa.sh | cat

# Ou modificar script para desabilitar cores:
# No início do script, adicione:
NO_COLOR=1
```

### Problema: Script trava em alguma seção

**Solução:**
```bash
# Executar em modo debug
bash -x ~/manutencao_backup_vps/scripts-auxiliares/verificar-saude-completa.sh

# Ver qual comando está travando
```

---

## 📈 Integração com Monitoramento

### Enviar Alertas por Email

```bash
#!/bin/bash
# /root/scripts/alerta-saude.sh

RESULTADO=$(/root/manutencao_backup_vps/scripts-auxiliares/verificar-saude-completa.sh)
SCORE=$(echo "$RESULTADO" | grep "Score:" | grep -o '[0-9]\+')

if [ "$SCORE" -lt 70 ]; then
    echo "$RESULTADO" | mail -s "⚠️ Saúde do Servidor: $SCORE/100" seu-email@exemplo.com
fi
```

### Integrar com Telegram

```bash
#!/bin/bash
# Enviar score para Telegram

TELEGRAM_TOKEN="seu-bot-token"
TELEGRAM_CHAT="seu-chat-id"

SCORE=$(sudo /root/manutencao_backup_vps/scripts-auxiliares/verificar-saude-completa.sh | grep "Score:" | grep -o '[0-9]\+')

curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT" \
    -d text="🏥 Saúde do Servidor: $SCORE/100"
```

### Dashboard Web (Netdata)

O script complementa o Netdata, oferecendo:
- ✅ Visão consolidada em texto
- ✅ Verificações específicas de Cloudflare
- ✅ Status de backups
- ✅ Score de saúde geral

---

## 💡 Dicas de Uso

### 1. Executar Antes de Mudanças Críticas

```bash
# Tirar snapshot da saúde antes de updates
sudo ./verificar-saude-completa.sh > pre-update.txt

# Fazer update
sudo apt update && sudo apt upgrade -y

# Comparar depois
sudo ./verificar-saude-completa.sh > pos-update.txt
diff pre-update.txt pos-update.txt
```

### 2. Monitorar Tendências

```bash
# Script para salvar histórico
mkdir -p /var/log/saude-historico
sudo ./verificar-saude-completa.sh > /var/log/saude-historico/$(date +%Y%m%d-%H%M%S).log

# Ver evolução do score
grep "Score:" /var/log/saude-historico/*.log
```

### 3. Verificação Rápida (apenas score)

```bash
sudo ./verificar-saude-completa.sh | grep -A 3 "RESUMO GERAL"
```

---

## 📝 Changelog

### Versão 1.0 (2025-01-19)
- ✅ Verificação completa de sistema operacional
- ✅ Monitoramento de recursos (CPU, RAM, disco)
- ✅ Status de Docker e containers
- ✅ Verificação de Cloudflare Tunnels e WARP
- ✅ Análise de firewall (UFW + DOCKER-USER)
- ✅ Status de bancos de dados
- ✅ Verificação de backups
- ✅ Análise de segurança (SSH, Fail2Ban)
- ✅ Testes de rede e conectividade
- ✅ Score de saúde com recomendações
- ✅ Output colorido e organizado

---

## 🤝 Contribuições

Sugestões de novas verificações são bem-vindas!

Exemplos de verificações que podem ser adicionadas:
- ✨ Certificados SSL (validade)
- ✨ Espaço em volumes Docker
- ✨ Status de aplicações específicas
- ✨ Verificação de CVEs conhecidas
- ✨ Performance de disco (IOPS)

---

## 📚 Referências

- [Documentação UFW](https://help.ubuntu.com/community/UFW)
- [Docker System Commands](https://docs.docker.com/engine/reference/commandline/system/)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Systemd Service Management](https://www.freedesktop.org/software/systemd/man/systemctl.html)

---

**🏥 Mantenha seu servidor saudável com verificações regulares!**
