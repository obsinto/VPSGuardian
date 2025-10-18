# 📦 Guia de Uso - Sistema de Backup

Guia completo para instalação, configuração e uso do sistema de backup do Coolify.

---

## 📋 Índice

1. [Instalação](#instalação)
2. [Configuração](#configuração)
3. [Uso Diário](#uso-diário)
4. [Restauração de Backups](#restauração-de-backups)
5. [Backup Off-site](#backup-off-site)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 Instalação

### Passo 1: Criar Estrutura de Diretórios

```bash
# Criar diretórios necessários
sudo mkdir -p /opt/manutencao
sudo mkdir -p /var/log/manutencao
sudo mkdir -p /root/coolify-backups
```

### Passo 2: Copiar Scripts

```bash
# Copiar script de backup principal
sudo cp backup/backup-coolify.sh /opt/manutencao/
sudo chmod +x /opt/manutencao/backup-coolify.sh

# Copiar scripts de backup de volumes (opcional)
sudo cp backup/backup-volume.sh /usr/local/bin/backup-volume
sudo cp backup/restaurar-volume.sh /usr/local/bin/restaurar-volume
sudo chmod +x /usr/local/bin/backup-volume
sudo chmod +x /usr/local/bin/restaurar-volume
```

### Passo 3: Configurar Cron

```bash
# Editar crontab
sudo crontab -e

# Adicionar linha para backup semanal (todo domingo às 2h)
0 2 * * 0 /opt/manutencao/backup-coolify.sh >> /var/log/manutencao/cron.log 2>&1
```

### Passo 4: Testar Instalação

```bash
# Executar backup manualmente
sudo /opt/manutencao/backup-coolify.sh

# Verificar se backup foi criado
ls -lh /root/coolify-backups/

# Ver log do backup
tail -50 /var/log/manutencao/backup-coolify.log
```

---

## ⚙️ Configuração

### Configurar Notificações

Edite o arquivo `/opt/manutencao/backup-coolify.sh`:

```bash
sudo nano /opt/manutencao/backup-coolify.sh
```

**Para email:**
```bash
EMAIL="seu-email@exemplo.com"
```

**Para Discord:**
```bash
WEBHOOK_URL="https://discord.com/api/webhooks/SEU_WEBHOOK"
```

**Para Slack:**
```bash
WEBHOOK_URL="https://hooks.slack.com/services/SEU_WEBHOOK"
```

### Ajustar Retenção de Backups

Por padrão, backups são mantidos por 30 dias. Para alterar:

```bash
sudo nano /opt/manutencao/backup-coolify.sh
```

Altere a linha:
```bash
RETENTION_DAYS=30  # Alterar para quantidade desejada
```

---

## 📅 Uso Diário

### Comandos Essenciais

#### Ver backups existentes
```bash
ls -lh /root/coolify-backups/
```

#### Executar backup manual
```bash
sudo /opt/manutencao/backup-coolify.sh
```

#### Ver log de backups
```bash
tail -50 /var/log/manutencao/backup-coolify.log
```

#### Ver último backup
```bash
ls -lht /root/coolify-backups/*.tar.gz | head -1
```

#### Ver conteúdo de um backup
```bash
cd /root/coolify-backups
tar -tzf NOME_DO_BACKUP.tar.gz | less
```

### Backup de Volume Específico

Se você precisa fazer backup de um volume Docker específico:

#### Modo Simples (parâmetro)
```bash
# Listar volumes existentes
docker volume ls

# Fazer backup de um volume
sudo backup-volume nome_do_volume

# Ver backups de volumes
ls -lh /root/volume-backups/
```

#### Modo Interativo (com prompts)
```bash
# Executar script interativo
sudo backup-volume-interativo

# O script irá perguntar:
# 1. Nome do volume a fazer backup
# 2. Diretório para salvar (opcional, padrão: /root/volume-backups)

# Ver backups de volumes
ls -lh /root/volume-backups/
```

**Você também pode passar parâmetros para pular as perguntas:**
```bash
sudo backup-volume-interativo meu_volume /caminho/personalizado
```

---

## 🔄 Restauração de Backups

### Restauração Completa do Coolify

#### Em um novo servidor:

**1. Instalar Coolify**
```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

**2. Transferir backup**
```bash
# Do servidor antigo
scp /root/coolify-backups/BACKUP.tar.gz usuario@novo-servidor:/root/

# No novo servidor
cd /root
tar -xzf BACKUP.tar.gz
cd NOME_DA_PASTA_EXTRAIDA
```

**3. Ver instruções**
```bash
cat backup-info.txt
```

**4. Parar containers (exceto banco)**
```bash
docker ps --filter name=coolify --format '{{.Names}}' | grep -v 'coolify-db' | xargs docker stop
```

**5. Restaurar banco de dados**
```bash
cat coolify-db-*.dmp | docker exec -i coolify-db pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify
```

**6. Copiar SSH keys**
```bash
cp -r ssh-keys/* /data/coolify/ssh/keys/
```

**7. Restaurar authorized_keys**
```bash
cat authorized_keys >> /root/.ssh/authorized_keys
```

**8. Atualizar APP_KEY**
```bash
cd /data/coolify/source
APP_KEY=$(cat /root/NOME_DA_PASTA_EXTRAIDA/app-key.txt | cut -d'=' -f2)
sed -i '/^APP_PREVIOUS_KEYS=/d' .env
echo "APP_PREVIOUS_KEYS=$APP_KEY" >> .env
```

**9. Reiniciar Coolify**
```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

### Restauração de Volume Específico

#### Modo Simples (parâmetros)
```bash
# Restaurar volume
sudo restaurar-volume /root/volume-backups/BACKUP.tar.gz nome_do_volume
```

#### Modo Interativo (com prompts)
```bash
# Executar script interativo
sudo restaurar-volume-interativo

# O script irá:
# 1. Listar backups disponíveis
# 2. Perguntar qual backup restaurar
# 3. Sugerir nome do volume baseado no arquivo
# 4. Confirmar se deseja sobrescrever (se volume já existir)
# 5. Perguntar se deseja ver os arquivos restaurados

# Ver volumes existentes
docker volume ls
```

**Você também pode passar parâmetros para pular as perguntas:**
```bash
sudo restaurar-volume-interativo /root/volume-backups/BACKUP.tar.gz meu_volume
```

---

## ☁️ Backup Off-site

### Opção 1: Sincronizar com Servidor Remoto

**Configurar SSH sem senha:**
```bash
# Gerar chave SSH
ssh-keygen -t rsa -b 4096

# Copiar para servidor remoto
ssh-copy-id usuario@servidor-backup
```

**Adicionar ao script de backup:**

Edite `/opt/manutencao/backup-coolify.sh` e adicione antes do `exit 0`:

```bash
# Sincronizar com servidor remoto
REMOTE_SERVER="backup-server.exemplo.com"
REMOTE_USER="root"
REMOTE_DIR="/backups/coolify"

LATEST_BACKUP=$(ls -t "$BACKUP_BASE_DIR"/*.tar.gz | head -1)
scp "$LATEST_BACKUP" "$REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR/"
```

### Opção 2: Enviar para AWS S3

**Instalar AWS CLI:**
```bash
sudo apt install awscli -y
aws configure
```

**Adicionar ao script:**
```bash
# Enviar para S3
S3_BUCKET="s3://meu-bucket-backups/coolify"
LATEST_BACKUP=$(ls -t "$BACKUP_BASE_DIR"/*.tar.gz | head -1)
aws s3 cp "$LATEST_BACKUP" "$S3_BUCKET/"
```

### Opção 3: Usar rclone (Dropbox, Google Drive, etc)

**Instalar rclone:**
```bash
curl https://rclone.org/install.sh | sudo bash
rclone config
```

**Adicionar ao script:**
```bash
# Enviar para cloud storage
RCLONE_REMOTE="dropbox:coolify-backups"
LATEST_BACKUP=$(ls -t "$BACKUP_BASE_DIR"/*.tar.gz | head -1)
rclone copy "$LATEST_BACKUP" "$RCLONE_REMOTE/"
```

---

## 🔧 Troubleshooting

### Backup não está sendo criado

**Verificar se Coolify está rodando:**
```bash
docker ps | grep coolify
```

**Ver logs de erro:**
```bash
tail -100 /var/log/manutencao/backup-coolify.log
```

**Executar manualmente para ver erros:**
```bash
sudo bash -x /opt/manutencao/backup-coolify.sh
```

### Backup muito grande

**Ver tamanho de volumes Docker:**
```bash
docker system df -v
```

**Desabilitar backup de volumes:**

No script `backup-coolify.sh`, a seção de backup de volumes já está desabilitada por padrão. Se você habilitou, comente as linhas novamente.

### Erro ao restaurar banco de dados

**Verificar formato do dump:**
```bash
file coolify-db-*.dmp
```

**Tentar restaurar com mais verbosidade:**
```bash
cat coolify-db-*.dmp | docker exec -i coolify-db pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify 2>&1 | tee restore.log
```

### Espaço em disco insuficiente

**Ver uso de espaço:**
```bash
df -h
du -sh /root/coolify-backups/*
```

**Remover backups antigos manualmente:**
```bash
# Listar backups por idade
ls -lt /root/coolify-backups/

# Remover backups mais antigos que 30 dias
find /root/coolify-backups -name "*.tar.gz" -mtime +30 -delete
```

---

## ✅ Checklist de Boas Práticas

- [ ] Backup automático configurado e rodando semanalmente
- [ ] Testei a restauração de um backup (crítico!)
- [ ] Backup off-site configurado (outro servidor ou cloud)
- [ ] Notificações configuradas (email ou webhook)
- [ ] Retenção de backups ajustada conforme necessidade
- [ ] Logs de backup sendo monitorados
- [ ] Backup de volumes críticos habilitado (se necessário)
- [ ] Documentação de restauração salva em local seguro
- [ ] Teste de restauração agendado trimestralmente

---

## 📚 Recursos Adicionais

- [Documentação oficial do Coolify](https://coolify.io/docs)
- [PostgreSQL Backup & Recovery](https://www.postgresql.org/docs/current/backup.html)
- [Docker Backup Best Practices](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)

---

**Dúvidas?** Consulte o [README principal](../README.md) ou a documentação completa.
