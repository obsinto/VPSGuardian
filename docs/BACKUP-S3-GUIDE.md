# ☁️ Guia Completo - Backup Coolify para S3

Backup automatizado e completo do Coolify com upload para S3 (AWS, Backblaze, Wasabi, MinIO).

---

## 🚀 Quick Start

```bash
# Modo interativo (primeira vez)
sudo /opt/vpsguardian/backup/backup-coolify-s3.sh

# Modo automático (após configurar)
sudo /opt/vpsguardian/backup/backup-coolify-s3.sh --auto
```

---

## 📦 O Que Este Script Faz?

### Backup Completo do Coolify:
1. ✅ **Banco de dados PostgreSQL** (dump completo em formato custom)
2. ✅ **SSH Keys do Coolify** (`/data/coolify/ssh/keys`)
3. ✅ **Arquivo .env** e `APP_KEY` extraída
4. ✅ **authorized_keys** do root
5. ✅ **Configurações do Nginx**
6. ✅ **Lista de volumes Docker**
7. ✅ **Informações do sistema**

### + Upload Automático para S3:
8. ✅ **Compacta** tudo em `.tar.gz`
9. ✅ **Criptografa** (opcional, com GPG)
10. ✅ **Envia para S3** (qualquer provedor S3-compatible)
11. ✅ **Configura lifecycle** (expira backups antigos automaticamente)
12. ✅ **Notifica** via Discord/Slack/Telegram (opcional)
13. ✅ **Limpa backups locais** antigos (>7 dias)

---

## 🌍 Provedores Suportados

### 1️⃣ AWS S3 (Amazon)

**Configuração:**
```bash
S3_PROVIDER="aws"
S3_BUCKET="meu-bucket"
S3_REGION="us-east-1"
S3_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE"
S3_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

**Como obter credenciais:**
1. Acesse AWS Console → IAM
2. Crie usuário com política `AmazonS3FullAccess`
3. Copie Access Key ID e Secret Access Key

**Custo estimado:**
- Armazenamento: ~$0.023/GB/mês (Standard)
- Transferência: Primeiros 100GB grátis/mês

---

### 2️⃣ Backblaze B2

**Configuração:**
```bash
S3_PROVIDER="backblaze"
S3_BUCKET="meu-bucket-backblaze"
S3_REGION="us-west-002"
S3_ENDPOINT="https://s3.us-west-002.backblazeb2.com"
S3_ACCESS_KEY="<keyID>"
S3_SECRET_KEY="<applicationKey>"
```

**Como obter credenciais:**
1. Acesse Backblaze → Buckets → Create Bucket
2. App Keys → Add New Application Key
3. Copie keyID e applicationKey

**Custo estimado:**
- Armazenamento: $0.005/GB/mês (4x mais barato que AWS!)
- Download: Primeiros 3x storage grátis

**⭐ Melhor custo-benefício para backups!**

---

### 3️⃣ Wasabi

**Configuração:**
```bash
S3_PROVIDER="wasabi"
S3_BUCKET="meu-bucket-wasabi"
S3_REGION="us-east-1"
S3_ACCESS_KEY="<access_key>"
S3_SECRET_KEY="<secret_key>"
```

**Como obter credenciais:**
1. Acesse Wasabi Console → Buckets → Create Bucket
2. Access Keys → Create Access Key
3. Copie Access Key e Secret Key

**Custo estimado:**
- Armazenamento: $0.0059/GB/mês
- Transferência: ILIMITADA (sem cobrança)

---

### 4️⃣ MinIO (Self-hosted)

**Configuração:**
```bash
S3_PROVIDER="minio"
S3_BUCKET="backups"
S3_REGION="us-east-1"
S3_ENDPOINT="https://minio.seudominio.com"
S3_ACCESS_KEY="<minio_access_key>"
S3_SECRET_KEY="<minio_secret_key>"
```

**Como configurar MinIO:**
```bash
# Instalar MinIO
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  -v /mnt/data:/data \
  -e "MINIO_ROOT_USER=admin" \
  -e "MINIO_ROOT_PASSWORD=senha123" \
  minio/minio server /data --console-address ":9001"

# Acessar console: http://seu-ip:9001
# Criar bucket "backups"
# Criar Access Key
```

**Vantagens:**
- ✅ Você controla onde os dados ficam
- ✅ Sem custos de cloud
- ✅ 100% compatível com S3 API

---

### 5️⃣ Outro Provedor S3-compatible

Qualquer serviço compatível com S3 API:
- DigitalOcean Spaces
- Linode Object Storage
- Cloudflare R2
- OVH Object Storage
- Scaleway Object Storage

**Configuração:**
```bash
S3_PROVIDER="custom"
S3_BUCKET="<bucket>"
S3_REGION="<region>"
S3_ENDPOINT="<endpoint-url>"
S3_ACCESS_KEY="<key>"
S3_SECRET_KEY="<secret>"
```

---

## 🔧 Configuração

### Opção 1: Modo Interativo (Primeira Vez)

```bash
sudo /opt/vpsguardian/backup/backup-coolify-s3.sh
```

O script vai perguntar:
1. **Provedor** (AWS, Backblaze, Wasabi, MinIO, Outro)
2. **Bucket** e **Região**
3. **Endpoint** (se não for AWS)
4. **Access Key** e **Secret Key**
5. **Criptografar?** (GPG opcional)
6. **Lifecycle?** (expiração automática)
7. **Salvar configuração?**

### Opção 2: Arquivo de Configuração

**Criar arquivo:**
```bash
sudo nano /etc/vpsguardian/backup-s3.conf
```

**Exemplo completo (Backblaze B2):**
```bash
# Provedor S3
S3_PROVIDER="backblaze"
S3_BUCKET="coolify-backups"
S3_PREFIX="backups/coolify"
S3_REGION="us-west-002"
S3_ENDPOINT="https://s3.us-west-002.backblazeb2.com"
S3_ACCESS_KEY="0021234567890abc"
S3_SECRET_KEY="K002abcdefghijklmnopqrstuvwxyz1234"

# Criptografia (RECOMENDADO)
ENCRYPT_BACKUP=true
GPG_RECIPIENT="seu-email@example.com"

# Lifecycle (expirar backups antigos)
CONFIGURE_LIFECYCLE=true
LIFECYCLE_DAYS=90

# Notificações (opcional)
WEBHOOK_URL="https://discord.com/api/webhooks/123/abc"
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
```

**Permissões:**
```bash
sudo chmod 600 /etc/vpsguardian/backup-s3.conf
```

**Usar configuração:**
```bash
sudo /opt/vpsguardian/backup/backup-coolify-s3.sh \
  --config=/etc/vpsguardian/backup-s3.conf
```

---

## 🔒 Criptografia com GPG

### Por que criptografar?

⚠️ **Backups contêm dados sensíveis:**
- APP_KEY do Coolify
- Chaves SSH privadas
- Credenciais de banco de dados
- Secrets de aplicações

### Configurar GPG

**1. Gerar chave GPG:**
```bash
gpg --full-generate-key

# Escolher:
# - Tipo: RSA and RSA
# - Tamanho: 4096 bits
# - Validade: 0 (não expira)
# - Nome e email
# - Senha forte
```

**2. Verificar chave:**
```bash
gpg --list-keys

# Saída exemplo:
# pub   rsa4096 2024-01-01 [SC]
#       ABCD1234...
# uid   [ultimate] Seu Nome <seu-email@example.com>
```

**3. Habilitar no backup-s3.conf:**
```bash
ENCRYPT_BACKUP=true
GPG_RECIPIENT="seu-email@example.com"
```

### Descriptografar backup:

```bash
# Download do S3
aws s3 cp s3://bucket/backups/coolify/20240315_120000.tar.gz.gpg .

# Descriptografar
gpg --decrypt --output 20240315_120000.tar.gz 20240315_120000.tar.gz.gpg

# Descompactar
tar -xzf 20240315_120000.tar.gz
```

---

## ⏰ Automatizar com Cron

### Backup Diário (2h da manhã)

```bash
sudo crontab -e
```

Adicionar:
```bash
# Backup diário do Coolify para S3 (2h da manhã)
0 2 * * * /opt/vpsguardian/backup/backup-coolify-s3.sh --config=/etc/vpsguardian/backup-s3.conf --auto >> /var/log/vpsguardian/backup-s3-cron.log 2>&1
```

### Backup Semanal (Domingo, 3h)

```bash
# Backup semanal do Coolify para S3 (domingo, 3h)
0 3 * * 0 /opt/vpsguardian/backup/backup-coolify-s3.sh --config=/etc/vpsguardian/backup-s3.conf --auto
```

### Verificar logs:

```bash
tail -f /var/log/vpsguardian/backup-coolify-s3.log
```

---

## 📊 Lifecycle (Expiração Automática)

### O Que É?

Lifecycle Policy configura o S3 para **deletar backups antigos automaticamente**, economizando espaço e custos.

### Como Funciona?

```bash
CONFIGURE_LIFECYCLE=true
LIFECYCLE_DAYS=90
```

- Backups com **>90 dias** são deletados automaticamente pelo S3
- Você não precisa fazer nada manualmente
- Reduz custos de armazenamento

### Estratégias Recomendadas:

| Cenário | Lifecycle | Motivo |
|---------|-----------|--------|
| Produção crítica | 180 dias | Compliance, auditoria |
| Produção normal | 90 dias | Balanceamento custo/segurança |
| Desenvolvimento | 30 dias | Economia |
| Testes | 7 dias | Temporário |

### Retenção 3-2-1:

**Regra de ouro de backups:**
- **3** cópias dos dados
- **2** tipos de mídia diferentes
- **1** cópia off-site

**Exemplo prático:**
```bash
# Cópia 1: Servidor de produção (dados originais)
# Cópia 2: Backup local (/var/backups - 7 dias)
# Cópia 3: S3 (off-site - 90 dias)
```

---

## 📢 Notificações

### Discord/Slack Webhook

**1. Obter Webhook URL:**

**Discord:**
- Servidor → Configurações → Integrações → Webhooks
- Copiar URL

**Slack:**
- https://api.slack.com/messaging/webhooks
- Criar Incoming Webhook

**2. Configurar:**
```bash
WEBHOOK_URL="https://discord.com/api/webhooks/123456/abcdef"
```

**3. Mensagens enviadas:**
- ✅ Backup iniciado
- ✅ Backup concluído (com tamanho, destino)
- ❌ Backup falhou (com erro)

---

### Telegram

**1. Criar bot:**
```bash
# Falar com @BotFather no Telegram
# Comandos:
/newbot
# Seguir instruções
# Copiar token: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
```

**2. Obter Chat ID:**
```bash
# Enviar mensagem para o bot
# Acessar:
https://api.telegram.org/bot<TOKEN>/getUpdates

# Copiar "chat":{"id": 123456789}
```

**3. Configurar:**
```bash
TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
TELEGRAM_CHAT_ID="123456789"
```

---

## 🔄 Como Restaurar

### 1. Download do S3

```bash
# Listar backups disponíveis
aws s3 ls s3://meu-bucket/backups/coolify/ --endpoint-url=<endpoint>

# Download do backup mais recente
aws s3 cp s3://meu-bucket/backups/coolify/20240315_120000.tar.gz.gpg . \
  --endpoint-url=<endpoint>
```

### 2. Descriptografar (se criptografado)

```bash
gpg --decrypt --output backup.tar.gz backup.tar.gz.gpg
```

### 3. Descompactar

```bash
tar -xzf backup.tar.gz
cd 20240315_120000
```

### 4. Restaurar Coolify

```bash
# Instalar Coolify no novo servidor (se necessário)
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# Parar containers (exceto banco)
docker ps --filter name=coolify --format '{{.Names}}' | \
  grep -v 'coolify-db' | xargs docker stop

# Restaurar banco de dados
cat coolify-db-*.dmp | docker exec -i coolify-db \
  pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify

# Restaurar SSH keys
cp -r ssh-keys/* /data/coolify/ssh/keys/

# Restaurar authorized_keys
cat authorized_keys >> /root/.ssh/authorized_keys

# Atualizar APP_KEY no .env
cd /data/coolify/source
APP_KEY=$(cat /caminho/backup/app-key.txt | cut -d'=' -f2)
sed -i '/^APP_PREVIOUS_KEYS=/d' .env
echo "APP_PREVIOUS_KEYS=$APP_KEY" >> .env

# Executar install script
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

---

## 💡 Casos de Uso

### Caso 1: Migração com S3 como Intermediário

**Cenário:** Migrar Coolify de VPS A para VPS B usando S3

```bash
# VPS A (origem):
sudo /opt/vpsguardian/backup/backup-coolify-s3.sh --auto

# VPS B (destino):
# 1. Instalar Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# 2. Instalar VPS Guardian
cd /opt && git clone <repo> vpsguardian
cd vpsguardian && sudo ./instalar.sh

# 3. Configurar AWS CLI com mesmas credenciais
sudo /opt/vpsguardian/backup/backup-coolify-s3.sh
# (Configurar mesmo S3)

# 4. Download do backup
aws s3 cp s3://bucket/backups/coolify/<arquivo>.tar.gz /tmp/

# 5. Restaurar (ver seção "Como Restaurar")
```

---

### Caso 2: Disaster Recovery

**Cenário:** Servidor caiu, precisa restaurar em novo servidor

```bash
# 1. Provisionar novo VPS
# 2. Instalar Coolify + VPS Guardian
# 3. Baixar backup mais recente do S3
# 4. Restaurar
# 5. Atualizar DNS (se mudou IP)
# 6. Testar aplicações
```

**Tempo estimado:** 30-45 minutos

---

### Caso 3: Backup Multi-Cloud

**Cenário:** Backup redundante em 2 provedores S3

**Estratégia:**
```bash
# Configuração 1: Backblaze (primário - barato)
/etc/vpsguardian/backup-s3-b2.conf

# Configuração 2: AWS S3 (secundário - rápido)
/etc/vpsguardian/backup-s3-aws.conf

# Cron:
0 2 * * * /opt/vpsguardian/backup/backup-coolify-s3.sh --config=/etc/vpsguardian/backup-s3-b2.conf --auto
0 3 * * * /opt/vpsguardian/backup/backup-coolify-s3.sh --config=/etc/vpsguardian/backup-s3-aws.conf --auto
```

**Vantagem:** Se Backblaze cair, você tem AWS como backup!

---

### Caso 4: Backup Apenas de Sexta

**Cenário:** Economizar custos, fazer backup apenas antes do fim de semana

```bash
# Cron (toda sexta, 23h)
0 23 * * 5 /opt/vpsguardian/backup/backup-coolify-s3.sh --auto

# Lifecycle: 30 dias (mantém ~4 backups)
```

---

## 📊 Estimativa de Custos

### Exemplo: Coolify com 20 aplicações

**Tamanho médio do backup:**
- Banco de dados: 500 MB
- SSH Keys: 5 MB
- Configs: 10 MB
- **Total compactado:** ~200 MB
- **Total criptografado:** ~205 MB

### Backblaze B2 (Recomendado)

**Backup diário, lifecycle 90 dias:**
- Armazenamento: 205 MB × 90 = 18.5 GB
- Custo mensal: 18.5 GB × $0.005 = **$0.09/mês** (R$ 0,50/mês)
- Download (em caso de restore): Primeiros 3x storage grátis

### AWS S3 Standard

**Backup diário, lifecycle 90 dias:**
- Armazenamento: 18.5 GB × $0.023 = **$0.43/mês** (R$ 2,30/mês)
- Download: $0.09/GB (primeiros 100GB grátis)

### Wasabi

**Backup diário, lifecycle 90 dias:**
- Armazenamento: 18.5 GB × $0.0059 = **$0.11/mês** (R$ 0,60/mês)
- Download: **GRÁTIS** (ilimitado)

---

## 🆘 Troubleshooting

### Erro: "AWS CLI não está instalado"

```bash
# Instalar
sudo apt update
sudo apt install awscli -y

# Verificar
aws --version
```

---

### Erro: "Falha no upload para S3"

**Verificar:**
```bash
# 1. Credenciais corretas?
cat ~/.aws/credentials

# 2. Bucket existe?
aws s3 ls s3://meu-bucket --endpoint-url=<endpoint>

# 3. Permissões corretas?
# IAM Policy deve incluir:
# - s3:PutObject
# - s3:PutObjectAcl
# - s3:GetObject
# - s3:ListBucket
```

---

### Erro: "GPG não encontrado"

```bash
# Instalar
sudo apt install gnupg -y

# Verificar chaves
gpg --list-keys
```

---

### Erro: "Lifecycle não configurado"

**Motivo:** Alguns provedores S3-compatible não suportam Lifecycle Policy

**Solução:**
```bash
# Desabilitar lifecycle
CONFIGURE_LIFECYCLE=false

# Usar script de limpeza manual:
# (criar script próprio para deletar backups >90 dias via aws s3 rm)
```

---

### Backup muito lento (upload demora horas)

**Causas:**
1. Upload da sua conexão é lento
2. Backup muito grande
3. Endpoint S3 longe geograficamente

**Soluções:**
```bash
# 1. Usar provedor mais próximo
S3_REGION="sa-east-1"  # São Paulo (AWS)

# 2. Comprimir mais agressivamente
# (modificar script para usar tar -czf com nível 9)

# 3. Excluir volumes grandes desnecessários
# (já está desabilitado por padrão)

# 4. Upload incremental (considerar rclone no futuro)
```

---

## 📚 Referências

- **AWS S3 Docs:** https://docs.aws.amazon.com/s3/
- **Backblaze B2 S3 API:** https://www.backblaze.com/b2/docs/s3_compatible_api.html
- **Wasabi Docs:** https://wasabi-support.zendesk.com/hc/en-us
- **MinIO Docs:** https://min.io/docs/minio/linux/index.html
- **AWS CLI S3 Commands:** https://docs.aws.amazon.com/cli/latest/reference/s3/
- **GPG Manual:** https://gnupg.org/documentation/

---

## 🎯 Checklist de Setup

- [ ] Escolher provedor S3 (Backblaze B2 recomendado)
- [ ] Criar bucket no provedor
- [ ] Obter Access Key e Secret Key
- [ ] Gerar chave GPG (recomendado)
- [ ] Criar `/etc/vpsguardian/backup-s3.conf`
- [ ] Testar backup manual primeiro
- [ ] Verificar se apareceu no S3
- [ ] Testar restauração (em VM de teste)
- [ ] Configurar cron job
- [ ] Configurar notificações (Discord/Telegram)
- [ ] Documentar credenciais em local seguro (1Password, Bitwarden)
- [ ] Testar disaster recovery completo (a cada 6 meses)

---

**☁️ VPS Guardian - Seus backups seguros na nuvem!**
