# Backup Coolify para S3

Backup automatizado do Coolify com upload para S3 (AWS, Backblaze, Wasabi, MinIO).

## Quick Start

```bash
# Configuração interativa (primeira vez)
sudo /opt/vpsguardian/backup/backup-coolify-s3.sh

# Backup automático (após configurar)
sudo /opt/vpsguardian/backup/backup-coolify-s3.sh --auto
```

## O Que Este Script Faz

1. **Backup completo:** PostgreSQL (dump custom), SSH keys, .env, APP_KEY, authorized_keys, Nginx, Docker volumes
2. **Compactação e criptografia:** tar.gz + GPG (opcional)
3. **Upload para S3:** Qualquer provedor S3-compatible
4. **Lifecycle automático:** Expira backups antigos
5. **Notificações:** Discord, Slack, Telegram (opcional)
6. **Limpeza local:** Remove backups >7 dias

## Provedores S3

| Provedor | Endpoint | Custo | Vantagem |
|----------|----------|-------|---------|
| **AWS S3** | `us-east-1` | $0.023/GB | Rápido, confiável |
| **Backblaze B2** | `s3.us-west-002.backblazeb2.com` | $0.005/GB | **Melhor custo** |
| **Wasabi** | `us-east-1` | $0.0059/GB | Download GRÁTIS |
| **MinIO** | `https://seu-dominio.com` | $0 | Self-hosted |

## Configuração

### Opção 1: Modo Interativo

```bash
sudo /opt/vpsguardian/backup/backup-coolify-s3.sh
```

Perguntas: Provedor, Bucket, Região, Endpoint (se necessário), Access Key, Secret Key, Criptografia, Lifecycle.

### Opção 2: Arquivo de Configuração

```bash
sudo nano /etc/vpsguardian/backup-s3.conf
```

**Exemplo (Backblaze B2):**

```bash
S3_PROVIDER="backblaze"
S3_BUCKET="coolify-backups"
S3_REGION="us-west-002"
S3_ENDPOINT="https://s3.us-west-002.backblazeb2.com"
S3_ACCESS_KEY="<keyID>"
S3_SECRET_KEY="<applicationKey>"

# Criptografia
ENCRYPT_BACKUP=true
GPG_RECIPIENT="seu-email@example.com"

# Expiração automática
CONFIGURE_LIFECYCLE=true
LIFECYCLE_DAYS=90

# Notificações
WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

**Permissões:**
```bash
sudo chmod 600 /etc/vpsguardian/backup-s3.conf
```

## Credenciais por Provedor

### AWS S3

1. AWS Console → IAM → Users → Create User
2. Atribuir policy `AmazonS3FullAccess`
3. Copiar **Access Key ID** e **Secret Access Key**

```bash
S3_PROVIDER="aws"
S3_BUCKET="meu-bucket"
S3_REGION="us-east-1"
S3_ACCESS_KEY="AKIA..."
S3_SECRET_KEY="..."
```

### Backblaze B2

1. Backblaze → Buckets → Create Bucket
2. App Keys → Add New Application Key
3. Copiar **keyID** e **applicationKey**

```bash
S3_PROVIDER="backblaze"
S3_BUCKET="coolify-backups"
S3_REGION="us-west-002"
S3_ENDPOINT="https://s3.us-west-002.backblazeb2.com"
S3_ACCESS_KEY="<keyID>"
S3_SECRET_KEY="<applicationKey>"
```

### Wasabi

1. Wasabi Console → Buckets → Create Bucket
2. Access Keys → Create Access Key
3. Copiar **Access Key** e **Secret Key**

```bash
S3_PROVIDER="wasabi"
S3_BUCKET="coolify-backups"
S3_REGION="us-east-1"
S3_ACCESS_KEY="<access_key>"
S3_SECRET_KEY="<secret_key>"
```

### MinIO (Self-hosted)

```bash
# Instalar
docker run -d \
  -p 9000:9000 -p 9001:9001 \
  -v /mnt/data:/data \
  -e "MINIO_ROOT_USER=admin" \
  -e "MINIO_ROOT_PASSWORD=senha123" \
  minio/minio server /data --console-address ":9001"

# Acessar console em http://seu-ip:9001
# Criar bucket "backups" e Access Key
```

Configuração:
```bash
S3_PROVIDER="minio"
S3_BUCKET="backups"
S3_ENDPOINT="https://seu-dominio.com"
S3_ACCESS_KEY="<minio_access_key>"
S3_SECRET_KEY="<minio_secret_key>"
```

### Outro Provedor S3-compatible

DigitalOcean Spaces, Linode Object Storage, Cloudflare R2, etc.

```bash
S3_PROVIDER="custom"
S3_BUCKET="<bucket>"
S3_ENDPOINT="<endpoint-url>"
S3_ACCESS_KEY="<key>"
S3_SECRET_KEY="<secret>"
```

## Criptografia GPG

**Por que?** Backups contêm APP_KEY, SSH keys, credenciais de banco de dados.

### Configurar

```bash
# Gerar chave
gpg --full-generate-key
# Escolher: RSA and RSA, 4096 bits, validade 0

# Listar chaves
gpg --list-keys

# Habilitar no backup-s3.conf
ENCRYPT_BACKUP=true
GPG_RECIPIENT="seu-email@example.com"
```

### Descriptografar backup

```bash
# Download
aws s3 cp s3://bucket/backups/coolify/20240315_120000.tar.gz.gpg . --endpoint-url=<endpoint>

# Descriptografar
gpg --decrypt --output backup.tar.gz backup.tar.gz.gpg

# Descompactar
tar -xzf backup.tar.gz
```

## Automação com Cron

```bash
sudo crontab -e
```

**Backup diário (2h da manhã):**
```bash
0 2 * * * /opt/vpsguardian/backup/backup-coolify-s3.sh --config=/etc/vpsguardian/backup-s3.conf --auto >> /var/log/vpsguardian/backup-s3-cron.log 2>&1
```

**Backup semanal (domingo, 3h):**
```bash
0 3 * * 0 /opt/vpsguardian/backup/backup-coolify-s3.sh --config=/etc/vpsguardian/backup-s3.conf --auto
```

**Verificar logs:**
```bash
tail -f /var/log/vpsguardian/backup-coolify-s3.log
```

## Lifecycle (Expiração Automática)

Delete backups antigos automaticamente para economizar custos.

```bash
CONFIGURE_LIFECYCLE=true
LIFECYCLE_DAYS=90
```

| Cenário | Dias | Motivo |
|---------|------|--------|
| Produção crítica | 180 | Compliance/auditoria |
| Produção | 90 | Balanceamento custo/segurança |
| Desenvolvimento | 30 | Economia |
| Testes | 7 | Temporário |

**Regra 3-2-1:** 3 cópias, 2 tipos de mídia, 1 off-site

## Notificações

### Discord/Slack

```bash
# Obter Webhook URL
# Discord: Servidor → Configurações → Integrações → Webhooks
# Slack: https://api.slack.com/messaging/webhooks

WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

### Telegram

```bash
# 1. Criar bot: Falar com @BotFather, /newbot
# 2. Obter Chat ID: https://api.telegram.org/bot<TOKEN>/getUpdates

TELEGRAM_BOT_TOKEN="123456789:ABC..."
TELEGRAM_CHAT_ID="123456789"
```

## Como Restaurar

```bash
# 1. Download do S3
aws s3 cp s3://bucket/backups/coolify/20240315_120000.tar.gz . --endpoint-url=<endpoint>

# 2. Descriptografar (se necessário)
gpg --decrypt --output backup.tar.gz backup.tar.gz.gpg

# 3. Descompactar
tar -xzf backup.tar.gz && cd 20240315_120000

# 4. Instalar Coolify (se novo servidor)
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# 5. Restaurar PostgreSQL
cat coolify-db-*.dmp | docker exec -i coolify-db pg_restore --clean --no-acl --no-owner -U coolify -d coolify

# 6. Restaurar SSH keys
cp -r ssh-keys/* /data/coolify/ssh/keys/

# 7. Restaurar authorized_keys
cat authorized_keys >> /root/.ssh/authorized_keys

# 8. Restaurar APP_KEY
cd /data/coolify/source
APP_KEY=$(cat /caminho/backup/app-key.txt | cut -d'=' -f2)
echo "APP_PREVIOUS_KEYS=$APP_KEY" >> .env

# 9. Executar script de instalação
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

## Casos de Uso

### Migração Coolify com S3

```bash
# VPS A (origem): Fazer backup
sudo /opt/vpsguardian/backup/backup-coolify-s3.sh --auto

# VPS B (destino):
# 1. Instalar Coolify e VPS Guardian
# 2. Configurar mesmas credenciais S3
# 3. Download do backup
# 4. Restaurar (ver seção acima)
```

### Backup Multi-Cloud

```bash
# Cron 1: Backblaze (primário, barato)
0 2 * * * /opt/vpsguardian/backup/backup-coolify-s3.sh --config=/etc/vpsguardian/backup-s3-b2.conf --auto

# Cron 2: AWS S3 (secundário, rápido)
0 3 * * * /opt/vpsguardian/backup/backup-coolify-s3.sh --config=/etc/vpsguardian/backup-s3-aws.conf --auto
```

## Estimativa de Custos

**Exemplo: Coolify com 20 apps, backup diário, lifecycle 90 dias**

- Tamanho compactado: ~200 MB/backup
- Armazenamento total: ~18.5 GB

| Provedor | Custo/mês |
|----------|-----------|
| Backblaze B2 | $0.09 (R$ 0,50) |
| AWS S3 | $0.43 (R$ 2,30) |
| Wasabi | $0.11 (R$ 0,60) + download grátis |

## Troubleshooting

### AWS CLI não instalado
```bash
sudo apt install awscli -y
aws --version
```

### Falha no upload S3
```bash
# Verificar credenciais
cat ~/.aws/credentials

# Verificar bucket
aws s3 ls s3://meu-bucket --endpoint-url=<endpoint>

# Verificar permissões IAM: s3:PutObject, s3:GetObject, s3:ListBucket
```

### GPG não encontrado
```bash
sudo apt install gnupg -y
```

### Backup muito lento
- Usar provedor mais próximo geograficamente
- Aumentar compressão (tar -czf com nível 9)
- Usar região mais próxima (ex: sa-east-1 para Brasil)

## Checklist de Setup

- [ ] Escolher provedor (Backblaze B2 recomendado)
- [ ] Criar bucket e Access Keys
- [ ] Gerar chave GPG (recomendado)
- [ ] Criar `/etc/vpsguardian/backup-s3.conf`
- [ ] Testar backup manual
- [ ] Verificar arquivo em S3
- [ ] Testar restauração (em VM de teste)
- [ ] Configurar cron job
- [ ] Configurar notificações
- [ ] Testar disaster recovery a cada 6 meses
