## 🚀 Guia de Migração - Coolify e Volumes Docker

Guia completo para migrar Coolify e volumes Docker para um novo servidor usando os backups existentes.

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Pré-requisitos](#pré-requisitos)
3. [Migração do Coolify](#migração-do-coolify)
4. [Migração de Volumes](#migração-de-volumes)
5. [Transferência de Backups](#transferência-de-backups)
6. [Verificação Pós-Migração](#verificação-pós-migração)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

O sistema de migração permite transferir facilmente:

- ✅ **Coolify completo** - Banco de dados, SSH keys, configurações
- ✅ **Volumes Docker** - Dados de aplicações
- ✅ **Configurações** - authorized_keys, Nginx, etc
- ✅ **Backups** - Transferência simples para servidor remoto

**Vantagens:**
- Usa backups existentes (sem necessidade de criar novos)
- Migração automatizada com verificações
- Logs detalhados de todo processo
- Suporte para autenticação com chave SSH ou senha

---

## 🔧 Pré-requisitos

### No Servidor Antigo (origem):

```bash
# 1. Certifique-se de ter backups recentes
ls -lh /root/coolify-backups/
ls -lh /root/volume-backups/

# 2. Se não tiver backups, crie agora
sudo /opt/manutencao/backup-coolify.sh
sudo backup-volume-interativo  # Para cada volume importante

# 3. Chave SSH (recomendado)
ls -la ~/.ssh/id_rsa
# Se não existir, crie:
ssh-keygen -t rsa -b 4096

# 4. Copie scripts de migração
sudo cp migrar/*.sh /opt/manutencao/
sudo chmod +x /opt/manutencao/migrar-*.sh
sudo chmod +x /opt/manutencao/transferir-backups.sh
```

### No Servidor Novo (destino):

```bash
# 1. Sistema operacional compatível
# Ubuntu 20.04/22.04/24.04 ou Debian 11/12

# 2. Acesso SSH configurado
# Porta 22 aberta ou porta customizada

# 3. Usuário root ou sudo

# 4. (Opcional) Adicione chave SSH pública do servidor antigo
cat >> ~/.ssh/authorized_keys
# Cole a chave pública e pressione Ctrl+D
```

---

## 🔄 Migração do Coolify

### Método 1: Script Interativo (Recomendado)

```bash
# No servidor antigo, execute:
cd /opt/manutencao
sudo ./migrar-coolify.sh
```

**O script irá perguntar:**
1. IP do novo servidor
2. Usuário SSH (padrão: root)
3. Porta SSH (padrão: 22)
4. Qual backup usar (lista disponíveis)
5. Confirmação para prosseguir

**O que acontece:**
1. ✅ Testa conexão SSH
2. ✅ Instala Coolify no novo servidor
3. ✅ Transfere banco de dados
4. ✅ Transfere SSH keys
5. ✅ Transfere configurações
6. ✅ Restaura tudo automaticamente
7. ✅ Verifica se Coolify está rodando

**Tempo estimado:** 10-15 minutos

### Método 2: Configuração Manual

Se preferir editar configurações antes de executar:

```bash
# Editar script
sudo nano /opt/manutencao/migrar-coolify.sh

# Alterar estas linhas no início:
NEW_SERVER_IP="192.168.1.100"
NEW_SERVER_USER="root"
NEW_SERVER_PORT="22"
SSH_PRIVATE_KEY_PATH="/root/.ssh/id_rsa"
BACKUP_FILE="/root/coolify-backups/20251018_020000.tar.gz"

# Executar
sudo ./migrar-coolify.sh
```

### Logs e Verificação

```bash
# Ver logs da migração
tail -f migration-logs/migration-agent-*.log

# Ver status dos containers no novo servidor
ssh root@NOVO_IP "docker ps"

# Acessar Coolify
http://NOVO_IP:8000
```

---

## 📦 Migração de Volumes

### Quando Usar

Migre volumes quando você tem:
- Dados de aplicações em volumes Docker
- Backups de volumes criados com `backup-volume` ou `backup-volume-interativo`
- Necessidade de mover dados de aplicações específicas

### Script Interativo

```bash
cd /opt/manutencao
sudo ./migrar-volumes.sh
```

**O script permite:**
- ✅ Selecionar múltiplos volumes para migrar
- ✅ Migrar todos os volumes de uma vez
- ✅ Ver tamanho e data de cada backup
- ✅ Transferir e restaurar automaticamente

**Processo:**
1. Lista todos os backups de volumes disponíveis
2. Permite selecionar quais migrar
3. Transfere backups selecionados
4. Cria volumes no novo servidor
5. Restaura dados automaticamente
6. Verifica quantidade de arquivos restaurados

**Exemplo de uso:**

```
[ Volume Migration Agent ] [ INFO ] Available volume backups:

  [0] wordpress_data-20251018_120000.tar.gz
      Volume: wordpress_data
      Date: 2025-10-18 12:00:00
      Size: 2.3G

  [1] postgres_data-20251018_120030.tar.gz
      Volume: postgres_data
      Date: 2025-10-18 12:00:30
      Size: 850M

  [2] redis_data-20251018_120100.tar.gz
      Volume: redis_data
      Date: 2025-10-18 12:01:00
      Size: 120M

[ Volume Migration Agent ] [ INPUT ] Selection: 0 1
# Migra apenas WordPress e PostgreSQL

# Ou digite 'all' para migrar todos
```

---

## 📤 Transferência de Backups

Para apenas transferir backups sem restaurar (backup off-site):

```bash
cd /opt/manutencao
sudo ./transferir-backups.sh
```

**Funcionalidades:**
- ✅ Transfere todos os backups do Coolify
- ✅ Suporta autenticação com chave SSH ou senha
- ✅ Cria diretório no servidor remoto automaticamente
- ✅ Retries automáticos em caso de senha incorreta (3 tentativas)

**Caso de uso:**
- Manter cópia de segurança em outro servidor
- Migração manual em múltiplas etapas
- Backup off-site regular

---

## ✅ Verificação Pós-Migração

### Checklist Coolify

```bash
# No novo servidor:

# 1. Verificar containers
docker ps --filter name=coolify

# Deve mostrar containers rodando:
# - coolify
# - coolify-db
# - coolify-realtime

# 2. Acessar interface web
# http://NOVO_IP:8000

# 3. Testar login
# Use as mesmas credenciais do servidor antigo

# 4. Verificar aplicações
# Todas as aplicações devem aparecer no dashboard

# 5. Verificar SSH keys
ls -la /data/coolify/ssh/keys/

# 6. Verificar banco de dados
docker exec -it coolify-db psql -U coolify -d coolify -c "SELECT COUNT(*) FROM applications;"
```

### Checklist Volumes

```bash
# No novo servidor:

# 1. Listar volumes
docker volume ls

# 2. Verificar conteúdo de um volume
docker run --rm -v NOME_DO_VOLUME:/volume busybox ls -lah /volume

# 3. Verificar tamanho
docker system df -v | grep NOME_DO_VOLUME

# 4. Testar aplicação que usa o volume
docker-compose up -d
# Ou comandos específicos da sua aplicação
```

### Atualizar DNS

Após verificar que tudo funciona:

```bash
# 1. Atualizar registros DNS para apontar para o novo IP
# A records, CNAME, etc.

# 2. Aguardar propagação (pode levar até 48h)

# 3. Testar acesso pelos domínios
curl -I https://seu-dominio.com
```

---

## 🔧 Troubleshooting

### Migração do Coolify falha

**Problema:** SSH connection failed

```bash
# Verificar conectividade
ping NOVO_IP

# Testar SSH manualmente
ssh -v root@NOVO_IP

# Verificar porta
telnet NOVO_IP 22

# Se usar porta diferente
ssh -p PORTA root@NOVO_IP
```

**Problema:** Database restore failed

```bash
# Ver log detalhado
cat migration-logs/db-restore.log

# Verificar se Coolify DB está rodando
ssh root@NOVO_IP "docker ps | grep coolify-db"

# Tentar restaurar manualmente
ssh root@NOVO_IP
cat /root/coolify-backup/db-dump.dmp | \
  docker exec -i coolify-db pg_restore \
  --verbose --clean --no-acl --no-owner \
  -U coolify -d coolify
```

**Problema:** Coolify não inicia após migração

```bash
# Verificar logs do container
ssh root@NOVO_IP "docker logs coolify"

# Verificar .env
ssh root@NOVO_IP "cat /data/coolify/source/.env | grep APP_KEY"

# Reiniciar Coolify
ssh root@NOVO_IP "docker restart coolify"
```

### Migração de Volumes falha

**Problema:** Volume not created

```bash
# Criar manualmente
ssh root@NOVO_IP "docker volume create NOME_DO_VOLUME"

# Verificar
ssh root@NOVO_IP "docker volume ls"
```

**Problema:** Transfer failed

```bash
# Verificar espaço em disco
ssh root@NOVO_IP "df -h"

# Transferir manualmente
scp /root/volume-backups/BACKUP.tar.gz root@NOVO_IP:/root/

# Restaurar manualmente
ssh root@NOVO_IP
docker run --rm \
  -v NOME_DO_VOLUME:/volume \
  -v /root:/backup \
  busybox \
  sh -c "cd /volume && tar xzf /backup/BACKUP.tar.gz"
```

**Problema:** Permission denied

```bash
# Adicionar chave SSH ao novo servidor
ssh-copy-id -i ~/.ssh/id_rsa.pub root@NOVO_IP

# Ou copiar manualmente
cat ~/.ssh/id_rsa.pub | ssh root@NOVO_IP "cat >> ~/.ssh/authorized_keys"
```

### Transferência de Backups falha

**Problema:** expect not found

```bash
# Instalar expect (para autenticação com senha)
sudo apt install expect -y
```

**Problema:** Connection timeout

```bash
# Aumentar timeout no script
# Editar transferir-backups.sh
# Alterar: set timeout 15
# Para: set timeout 60
```

---

## 📊 Comparação de Métodos

| Aspecto | Migração Coolify | Migração Volumes | Transferência |
|---------|------------------|------------------|---------------|
| **Tempo** | 10-15 min | 5-30 min | 2-10 min |
| **Automação** | ✅ Completa | ✅ Completa | ✅ Completa |
| **Interativo** | ✅ Sim | ✅ Sim | ✅ Sim |
| **Rollback** | ❌ Manual | ✅ Fácil | N/A |
| **Logs** | ✅ Detalhados | ✅ Detalhados | ✅ Básicos |

---

## 🎯 Melhores Práticas

1. **Sempre faça backup antes de migrar**
   ```bash
   sudo /opt/manutencao/backup-coolify.sh
   sudo backup-volume-interativo
   ```

2. **Teste a conexão SSH antes**
   ```bash
   ssh root@NOVO_IP exit
   ```

3. **Mantenha o servidor antigo online**
   - Até confirmar que tudo funciona no novo
   - Mínimo 24-48h após migração

4. **Use chave SSH em vez de senha**
   - Mais seguro
   - Mais rápido
   - Evita problemas de timeout

5. **Verifique espaço em disco**
   ```bash
   # No novo servidor
   ssh root@NOVO_IP "df -h"
   ```

6. **Documente IPs e credenciais**
   - IP antigo e novo
   - Portas SSH
   - Domínios a atualizar

---

## 🆘 Suporte

Se encontrar problemas:

1. Consulte os logs em `migration-logs/` ou `volume-migration-logs/`
2. Veja seção de Troubleshooting deste guia
3. Consulte documentação oficial do Coolify
4. Mantenha backups sempre atualizados

---

**Boa migração! 🚀**
